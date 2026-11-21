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

enum Noise: String, CaseIterable { case off = "Tắt", white = "White noise", brown = "Brown noise" }

// The render callback alone owns phase and ramps. UI publishes scalar targets.
private final class Oscillator: @unchecked Sendable {
    let hz: Atomic<Int>
    let level = Atomic<Int>(0)
    let whiteLevel = Atomic<Int>(0)
    let brownLevel = Atomic<Int>(0)
    private var whiteGain = Ramp(0)
    private var brownGain = Ramp(0)
    private var seed: UInt32 = 123456789
    private var brown = 0.0
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
        let frames = Int(rate * 0.05)
        whiteGain.set(Double(whiteLevel.load(ordering: .relaxed)) / 100, frames: frames)
        brownGain.set(Double(brownLevel.load(ordering: .relaxed)) / 100, frames: frames)
        let samples = output.pointee.mBuffers.mData!.assumingMemoryBound(to: Float.self)
        let scale = 2 * Double.pi / rate
        for index in 0..<count {
            let w = whiteGain.advance(), b = brownGain.advance()
            var ambient = 0.0
            if w + b > 0 {
                seed = seed &* 1664525 &+ 1013904223
                let white = Double(seed) / Double(UInt32.max) * 2 - 1
                brown = min(1, max(-1, brown * 0.995 + white * 0.07))
                ambient = 0.10 * (white * w + brown * b)
            }
            samples[index] = Float(sin(phase) * gain.advance() * (1 - 0.5 * (w + b)) + ambient)
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

    @Published private(set) var noise = Noise.off
    @Published var noiseVolume = 25 { didSet { updateNoise() } }

    private func updateNoise() {
        voice?.whiteLevel.store(noise == .white ? noiseVolume : 0, ordering: .relaxed)
        voice?.brownLevel.store(noise == .brown ? noiseVolume : 0, ordering: .relaxed)
    }

    func selectNoise(_ next: Noise) {
        if next != .off && !ensureEngine() { return }
        noise = next
        updateNoise()
        releaseIfIdle()
    }

    private func ensureEngine() -> Bool {
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
            return true
        } catch { self.error = error.localizedDescription; return false }
    }

    func start() {
        guard ensureEngine() else { return }
        voice?.level.store(volume, ordering: .relaxed)
        updateNoise()
        playing = true
        armTimer()
    }

    func stop() {
        timer?.cancel()
        playing = false
        voice?.level.store(0, ordering: .relaxed)
        releaseIfIdle()
    }

    private func releaseIfIdle() {
        guard !playing && noise == .off else { return }
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
