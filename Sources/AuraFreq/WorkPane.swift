import SwiftUI

struct WorkPane: View {
    @ObservedObject var session: WorkSession
    @ObservedObject var tone: Tone
    let close: () -> Void
    @State private var adding = false
    @State private var title = ""
    @State private var goal = 1
    @AppStorage("work.quiet") private var quiet = false
    @State private var videoOpen = false
    @State private var link = ""
    @State private var video: String?
    @State private var invalidLink = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Làm việc").font(.system(size: 27, design: .serif))
                    Spacer()
                    Button(action: close) { Image(systemName: "xmark") }
                        .buttonStyle(.plain).accessibilityLabel("Đóng ngăn Làm việc")
                }
                if let item = session.current {
                    HStack {
                        if quiet { Text(item.name).font(.headline) }
                        else {
                            Picker("Công việc", selection: Binding(get: { item.id }, set: session.select)) {
                                ForEach(session.items) { Text($0.name).tag($0.id) }
                            }.labelsHidden()
                        }
                        Spacer()
                        if !quiet { addButton }
                    }
                    VStack(spacing: 10) {
                        TimelineView(.periodic(from: .now, by: item.end == nil ? 3600 : 1)) { tick in
                            let seconds = item.remaining(at: tick.date)
                            Text(String(format: "%02d:%02d", seconds / 60, seconds % 60))
                                .font(.system(size: 54, weight: .light, design: .serif)).monospacedDigit()
                        }
                        Text("\(item.resting ? "Nghỉ" : "Làm việc") · Đã xong \(item.completed)/\(item.goal) phiên")
                            .font(.caption).foregroundStyle(.secondary)
                        Button(item.end == nil ? "Bắt đầu" : "Tạm dừng phiên") {
                            session.change {
                                if $0.end == nil { $0.end = Date().addingTimeInterval(Double($0.seconds)) }
                                else { $0.pause(at: Date()) }
                            }
                        }.buttonStyle(.borderedProminent)
                    }.frame(maxWidth: .infinity)
                    if !quiet {
                        Picker("Loại phiên", selection: Binding(get: { item.resting }, set: { rest in
                            session.change { $0.setPhase(rest: rest) }
                        })) {
                            Text("Làm việc").tag(false)
                            Text("Nghỉ").tag(true)
                        }.pickerStyle(.segmented)
                    }
                } else { addButton }
                Divider()
                Toggle("Giảm kích thích", isOn: $quiet).toggleStyle(.switch)
                    .onChange(of: quiet) { _, on in if on { video = nil; videoOpen = false } }
                if !quiet {
                    Picker("Âm nền", selection: Binding(get: { tone.noise }, set: tone.selectNoise)) {
                        ForEach(Noise.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    if tone.noise != .off {
                        Slider(value: Binding(get: { Double(tone.noiseVolume) }, set: { tone.noiseVolume = Int($0) }), in: 0...100, step: 1) {
                            Image(systemName: "speaker.wave.2")
                        }.accessibilityLabel("Âm lượng nền")
                    }
                    Divider()
                    DisclosureGroup("YouTube", isExpanded: $videoOpen) {
                        VStack(alignment: .leading) {
                            HStack {
                                TextField("Dán liên kết YouTube", text: $link).onSubmit(loadVideo)
                                Button("Phát video", action: loadVideo)
                            }
                            Menu("Nhạc piano gợi ý") {
                                Button("Debussy · Clair de lune") { playSuggested("WNcsUNKlAKw") }
                                Button("Satie · Gymnopédie số 1") { playSuggested("2WfaotSK3mI") }
                            }.fixedSize()
                            if invalidLink { Text("Hãy nhập liên kết đến một video YouTube.").font(.caption) }
                            if let video {
                                YouTubePlayer(id: video).id(video).frame(height: 204)
                            }
                        }.padding(.top, 8)
                    }.onChange(of: videoOpen) { _, open in if !open { video = nil } }
                }
            }.padding(18)
        }.frame(minWidth: 310, idealWidth: 350, maxWidth: 420)
    }

    private var addButton: some View {
        Button("Thêm task", systemImage: "plus") { adding = true }
            .popover(isPresented: $adding) {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Tên công việc", text: $title).onSubmit(add)
                    Stepper("Mục tiêu: \(goal) phiên", value: $goal, in: 1...99)
                    Button("Thêm", action: add).disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }.padding().frame(width: 240)
            }
    }

    private func add() {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        session.add(title, goal: goal)
        title = ""
        goal = 1
        adding = false
    }

    private func playSuggested(_ id: String) {
        link = "https://youtu.be/" + id
        loadVideo()
    }

    private func loadVideo() {
        guard let id = youtubeID(link) else { invalidLink = true; return }
        invalidLink = false
        video = id
    }
}
