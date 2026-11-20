import SwiftUI

private let ink = Color(red: 0.63, green: 0.14, blue: 0.055)
private let paper = Color(red: 0.94, green: 0.90, blue: 0.84)
private let presets = [174, 285, 396, 417, 432, 528, 639, 741, 852, 963]

@main
struct AuraFreqApp: App {
    var body: some Scene {
        Window("AuraFreq", id: "studio") { Studio() }
            .defaultSize(width: 900, height: 490)
            .windowStyle(.hiddenTitleBar)
    }
}

private struct Studio: View {
    @StateObject private var tone = Tone()
    @State private var editing = false
    @State private var input = ""
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack(spacing: 8) {
                Circle().fill(ink).frame(width: 11, height: 11)
                Text("AuraFreq").font(.system(size: 23, design: .serif))
            }.padding(.trailing, 28).padding(.top, 12)
            HStack(spacing: 0) {
                Dial(paper: paper, hz: tone.frequency, tune: tone.tune)
                VStack(spacing: 24) {
                    Button {
                        input = String(tone.frequency)
                        editing = true
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(String(tone.frequency))
                                .font(.system(size: 60, weight: .light, design: .serif))
                                .monospacedDigit()
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            Text("Hz").italic().font(.system(size: 34, design: .serif))
                        }.lineLimit(1).frame(width: 245, height: 108)
                    }.buttonStyle(.plain).foregroundStyle(ink).accessibilityLabel("Nhập tần số, \(tone.frequency) Hz")
                    .popover(isPresented: $editing) {
                        VStack(alignment: .leading) {
                            Text("Tần số · 16–20.000 Hz")
                            TextField("Hz", text: $input).onSubmit { applyInput() }
                            Button("Áp dụng") { applyInput() }.disabled(validInput == nil)
                        }.padding().frame(width: 220)
                    }
                    Button { tone.playing ? tone.stop() : tone.start() } label: {
                        Image(systemName: tone.playing ? "pause.fill" : "play.fill")
                            .foregroundStyle(.white).frame(width: 58,height: 58).background(ink,in: Circle())
                    }.buttonStyle(.plain).accessibilityLabel(tone.playing ? "Tạm dừng" : "Phát")
                    HStack {
                        Image(systemName: "speaker.wave.2")
                        Slider(value: Binding(get: { Double(tone.volume) }, set: { tone.volume = Int($0) }), in: 0...100, step: 1).accessibilityLabel("Âm lượng")
                        Text("\(tone.volume)%").monospacedDigit()
                    }
                    Divider()
                    Picker("Hẹn giờ", selection: $tone.minutes) {
                        Text("Tắt").tag(0)
                        ForEach([5,15,30,60], id: \.self) { Text("\($0) phút").tag($0) }
                    }
                }.frame(width: 245).padding(.horizontal, 20)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(presets, id: \.self) { hz in
                        Button { tone.tune(hz) } label: {
                            Text("\(String(hz)) Hz").frame(width: 65).padding(.vertical, 3)
                                .foregroundStyle(tone.frequency == hz ? Color.white : Color.primary)
                                .background(tone.frequency == hz ? ink : .clear, in: Capsule())
                        }.buttonStyle(.plain)
                    }
                }.font(.system(size: 14, design: .serif)).padding(.trailing, 20)
            }
        }.frame(minWidth: 730,minHeight: 430).background(paper).preferredColorScheme(.light).tint(ink)
        .onDisappear { tone.stop() }
        .alert("Không thể phát âm thanh", isPresented: Binding(get: { tone.error != nil }, set: { if !$0 { tone.error = nil } })) {
            Button("Đóng") { tone.error = nil }
        } message: { Text(tone.error ?? "") }
    }
    private var validInput: Int? { Int(input).flatMap { (16...20000).contains($0) ? $0 : nil } }
    private func applyInput() {
        guard let hz = validInput else { return }
        tone.tune(hz)
        editing = false
    }
}
