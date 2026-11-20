import AVFoundation
import Synchronization

struct Ramp {
    var value: Double
    private var target: Double
    private var step = 0.0
    private var remaining = 0

    init(_ value: Double) { self.value = value; self.target = value }

    mutating func set(_ next: Double, frames: Int) {
        guard next != target else { return }
        target = next
        remaining = max(1, frames)
        step = (next - value) / Double(remaining)
    }

    mutating func advance() -> Double {
        if remaining > 0 {
            remaining -= 1
            value = remaining == 0 ? target : value + step
        }
        return value
    }
}

// The render callback alone owns phase and ramps. UI publishes scalar targets.
private final class Oscillator: @unchecked Sendable {
    let hz: Atomic<Int>
    let level = Atomic<Int>(0)
    let rate: Double
    private var frequency: Ramp
    private var gain = Ramp(0)
    private var phase = 0.0

    init(rate: Double, frequency: Int) {
        self.rate = rate
        hz = Atomic(frequency)
        self.frequency = Ramp(Double(frequency))
    }

    func render(_ count: Int, _ output: UnsafeMutablePointer<AudioBufferList>) {
        frequency.set(min(Double(hz.load(ordering: .relaxed)), rate * 0.49), frames: Int(rate * 0.08))
        gain.set(Double(level.load(ordering: .relaxed)) * 0.002, frames: Int(rate * 0.05))
        let samples = output.pointee.mBuffers.mData!.assumingMemoryBound(to: Float.self)
        let scale = 2 * Double.pi / rate
        for index in 0..<count {
            samples[index] = Float(sin(phase) * gain.advance())
            phase += frequency.advance() * scale
            if phase >= 2 * .pi { phase -= 2 * .pi }
        }
    }
}

@MainActor
final class Tone: ObservableObject {
    @Published var frequency = 432 { didSet { voice?.hz.store(frequency, ordering: .relaxed) } }
    @Published var volume = 25 { didSet { if playing { voice?.level.store(volume, ordering: .relaxed) } } }
    @Published private(set) var playing = false
    @Published var error: String?
    @Published var minutes = 0 { didSet { armTimer() } }
    private var engine: AVAudioEngine?
    private var voice: Oscillator?
    private var stopTask: Task<Void, Never>?
    private var timer: Task<Void, Never>?

    func tune(_ number: Int) { frequency = min(20_000, max(16, number)) }

    func start() {
        stopTask?.cancel()
        do {
            if engine?.isRunning != true {
                let graph = AVAudioEngine()
                let rate = graph.outputNode.outputFormat(forBus: 0).sampleRate
                guard rate > 0, let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1) else {
                    throw NSError(domain: "AuraFreq", code: 1, userInfo: [NSLocalizedDescriptionKey: "Không có thiết bị âm thanh."])
                }
                let oscillator = Oscillator(rate: rate, frequency: frequency)
                let source = AVAudioSourceNode(format: format) { @Sendable _, _, frames, output in
                    oscillator.render(Int(frames), output)
                    return noErr
                }
                graph.attach(source)
                graph.connect(source, to: graph.mainMixerNode, format: format)
                try graph.start()
                engine = graph
                voice = oscillator
            }
            voice?.level.store(volume, ordering: .relaxed)
            playing = true
            armTimer()
        } catch { self.error = error.localizedDescription; playing = false }
    }

    func stop() {
        timer?.cancel()
        playing = false
        voice?.level.store(0, ordering: .relaxed)
        stopTask?.cancel()
        stopTask = Task {
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            engine?.stop()
            engine = nil
            voice = nil
        }
    }

    private func armTimer() {
        timer?.cancel()
        guard playing, minutes > 0 else { return }
        timer = Task {
            try? await Task.sleep(for: .seconds(minutes * 60))
            guard !Task.isCancelled else { return }
            stop()
            minutes = 0
        }
    }
}
