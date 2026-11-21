import SwiftUI

private let ink = Color(red: 0.63, green: 0.14, blue: 0.055)
private let paper = Color(red: 0.94, green: 0.90, blue: 0.84)
private let presets = [174, 285, 396, 417, 432, 528, 639, 741, 852, 963]

private struct CustomFrequency: Codable, Identifiable {
    var id = UUID()
    var name: String
    var hz: Int

    static func decode(_ data: Data) -> [Self] {
        (try? JSONDecoder().decode([Self].self, from: data)) ?? []
    }
}

private struct CustomPresets: View {
    @ObservedObject var tone: Tone
    @AppStorage("customFrequencies") private var data = Data()
    @State private var editing = false
    @State private var name = ""
    @State private var frequency = ""

    private var entries: [CustomFrequency] {
        CustomFrequency.decode(data)
    }
    private var validHz: Int? {
        Int(frequency.trimmingCharacters(in: .whitespaces)).flatMap { (16...20_000).contains($0) ? $0 : nil }
    }
    private var title: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        Menu("Preset") {
            ForEach(entries) { entry in
                Button("\(entry.name) · \(entry.hz) Hz") { tone.tune(entry.hz) }
            }
            Button("Thêm preset…") {
                name = ""
                frequency = String(tone.frequency)
                editing = true
            }
            if !entries.isEmpty {
                Menu("Xóa preset") {
                    ForEach(entries) { entry in
                        Button("\(entry.name) · \(entry.hz) Hz") {
                            save(entries.filter { $0.id != entry.id })
                        }
                    }
                }
            }
        }
        .fixedSize()
        .popover(isPresented: $editing) {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Tên preset", text: $name)
                Menu("Gợi ý tên") {
                    ForEach(["Thư giãn", "Nghỉ khi đau đầu", "Nghỉ màn hình"], id: \.self) { label in
                        Button(label) { name = label }
                    }
                }
                TextField("Tần số (16–20.000 Hz)", text: $frequency)
                Text("Tên preset ghi mục đích cá nhân. Hiệu quả sức khỏe của các âm đơn này chưa được xác lập.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Lưu preset") {
                    guard let hz = validHz, !title.isEmpty else { return }
                    save(entries + [CustomFrequency(name: title, hz: hz)])
                    editing = false
                }.disabled(validHz == nil || title.isEmpty)
            }.padding().frame(width: 290)
        }
    }

    private func save(_ presets: [CustomFrequency]) {
        if let encoded = try? JSONEncoder().encode(presets) { data = encoded }
    }
}

@main
struct AuraFreqApp: App {
    @StateObject private var tone = Tone()
    @AppStorage("minimalMode") private var minimal = false
    var body: some Scene {
        Window("AuraFreq", id: "studio") { Studio(tone: tone) }
            .defaultSize(width: 900, height: 490)
            .windowStyle(.hiddenTitleBar)
            .commands {
                CommandGroup(after: .toolbar) {
                    Toggle("Chế độ tối giản", isOn: $minimal)
                        .keyboardShortcut("m", modifiers: [.command, .shift])
                }
            }
        MenuBarExtra("AuraFreq", systemImage: tone.playing ? "waveform.circle.fill" : "waveform.circle") {
            PlaybackMenu(tone: tone)
        }
    }
}

private struct PlaybackMenu: View {
    @AppStorage("customFrequencies") private var customData = Data()
    @ObservedObject var tone: Tone
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Text("\(tone.frequency) Hz")
        Button(tone.playing ? "Tạm dừng" : "Phát") {
            if tone.playing { tone.stop() }
            else {
                tone.start()
                if tone.error != nil { showStudio() }
            }
        }
        Menu("Tần số") {
            let personal = CustomFrequency.decode(customData)
            if !personal.isEmpty {
                Section("Preset cá nhân") {
                    ForEach(personal) { entry in
                        Button("\(entry.name) · \(entry.hz) Hz") { tone.tune(entry.hz) }
                    }
                }
                Divider()
            }
            ForEach(presets, id: \.self) { hz in
                Button { tone.tune(hz) } label: {
                    if hz == tone.frequency { Label("\(hz) Hz", systemImage: "checkmark") }
                    else { Text("\(hz) Hz") }
                }
            }
        }
        Divider()
        Button("Mở AuraFreq", action: showStudio)
        Button("Thoát AuraFreq") { NSApp.terminate(nil) }
    }

    private func showStudio() {
        openWindow(id: "studio")
        NSApp.activate()
    }
}

private struct Studio: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("minimalMode") private var minimal = false
    @ObservedObject var tone: Tone
    @StateObject private var work = WorkSession()
    @State private var workOpen = false
    @State private var editing = false
    @State private var input = ""
    @State private var studioSize: CGSize?
    private enum Layout { case studio, zen, work }
    private var layout: Layout { minimal ? .zen : workOpen ? .work : .studio }

    var body: some View {
        HStack(spacing: 0) {
            if minimal {
                zen
            } else {
                GeometryReader { geometry in
                    let panelWidth: CGFloat = workOpen ? 351 : 0
                    HStack(spacing: 0) {
                        studio.frame(width: max(700, geometry.size.width - panelWidth))
                        if workOpen {
                            Divider()
                            WorkPane(session: work, tone: tone) { workOpen = false }
                                .frame(width: 350)
                                .transition(.opacity)
                        }
                    }
                    .frame(width: geometry.size.width, alignment: .leading)
                    .clipped()
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: workOpen)
                }
            }
        }.frame(minWidth: minimal ? 440 : 730, minHeight: minimal ? 310 : 430)
        .background(paper).preferredColorScheme(.light).tint(ink)
        .onChange(of: layout, initial: true) { previous, next in
            resizeWindow(from: previous, to: next)
        }
        .alert("Không thể phát âm thanh", isPresented: Binding(get: { tone.error != nil }, set: { if !$0 { tone.error = nil } })) {
            Button("Đóng") { tone.error = nil }
        } message: { Text(tone.error ?? "") }
    }
    private func resizeWindow(from previous: Layout, to next: Layout) {
        guard let window = NSApp.keyWindow ?? NSApp.windows.first(where: { $0.canBecomeKey }),
              !window.styleMask.contains(.fullScreen), let screen = window.screen else { return }
        if previous == .studio { studioSize = window.frame.size }
        let base = studioSize ?? CGSize(width: 900, height: 490)
        let size: CGSize
        switch next {
        case .zen: size = CGSize(width: 460, height: 360)
        case .work: size = CGSize(width: base.width + 351, height: max(560, base.height))
        case .studio: size = base
        }
        guard previous != next || next == .zen else { return }
        let bounds = screen.visibleFrame
        let width = min(size.width, bounds.width), height = min(size.height, bounds.height)
        let x = max(bounds.minX, min(window.frame.minX, bounds.maxX - width))
        let y = max(bounds.minY, min(window.frame.maxY - height, bounds.maxY - height))
        window.setFrame(NSRect(x: x, y: y, width: width, height: height), display: false)
    }

    private var zen: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 26) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(String(tone.frequency))
                        .font(.system(size: 112, weight: .light, design: .serif))
                        .monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
                    Text("Hz").font(.system(size: 32, design: .serif)).italic()
                }
                .foregroundStyle(ink)
                .accessibilityElement(children: .combine)

                Button { tone.playing ? tone.stop() : tone.start() } label: {
                    Image(systemName: tone.playing ? "pause.fill" : "play.fill")
                        .frame(width: 46, height: 46)
                        .foregroundStyle(.white).background(ink, in: Circle())
                }
                .buttonStyle(.plain).keyboardShortcut(.space, modifiers: [])
                .accessibilityLabel(tone.playing ? "Tạm dừng" : "Phát")

                HStack(spacing: 14) {
                    ForEach([174, 432, 528, 963], id: \.self) { hz in
                        Button { tone.tune(hz) } label: {
                            Text(String(hz)).monospacedDigit().padding(8)
                                .overlay(alignment: .bottom) {
                                    if tone.frequency == hz {
                                        Capsule().fill(ink).frame(width: 18, height: 2)
                                    }
                                }
                        }.buttonStyle(.plain).accessibilityLabel("\(hz) Hz")
                        .accessibilityAddTraits(tone.frequency == hz ? .isSelected : [])
                    }
                    Divider().frame(height: 18)
                    Menu {
                        ForEach(presets, id: \.self) { hz in
                            Button("\(hz) Hz") { tone.tune(hz) }
                        }
                    } label: { Image(systemName: "ellipsis.circle") }
                    .menuStyle(.borderlessButton).fixedSize().accessibilityLabel("Tất cả tần số")
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
            Button { minimal = false } label: {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
                    .padding(10)
            }.buttonStyle(.plain).keyboardShortcut(.cancelAction)
            .accessibilityLabel("Trở về mặt đĩa").help("Trở về mặt đĩa (Esc)").padding(12)
        }
    }

    private var studio: some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack(spacing: 8) {
                CustomPresets(tone: tone)
                Button("Tối giản", systemImage: "rectangle.compress.vertical") { minimal = true }
                    .buttonStyle(.borderless)
                Button("Làm việc", systemImage: "timer") { workOpen.toggle() }
                    .buttonStyle(.borderless).padding(.trailing, 12)
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
        }
    }

    private var validInput: Int? { Int(input).flatMap { (16...20000).contains($0) ? $0 : nil } }
    private func applyInput() {
        guard let hz = validInput else { return }
        tone.tune(hz)
        editing = false
    }
}
