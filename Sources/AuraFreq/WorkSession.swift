import Foundation

struct WorkItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var goal: Int
    var completed = 0
    var resting = false
    var seconds = 25 * 60
    var end: Date?

    func remaining(at now: Date) -> Int {
        end.map { max(0, Int(ceil($0.timeIntervalSince(now)))) } ?? seconds
    }

    mutating func settle(at now: Date) {
        guard let end, end <= now else { return }
        if !resting { completed += 1 }
        setPhase(rest: !resting)
    }

    mutating func pause(at now: Date) {
        settle(at: now)
        seconds = remaining(at: now)
        end = nil
    }

    mutating func setPhase(rest: Bool) {
        resting = rest
        seconds = rest ? 300 : 1500
        end = nil
    }
}

@MainActor
final class WorkSession: ObservableObject {
    private let defaults: UserDefaults
    @Published private(set) var items: [WorkItem]
    @Published private(set) var selected: UUID?
    private var alarm: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        items = defaults.data(forKey: "work.items").flatMap { try? JSONDecoder().decode([WorkItem].self, from: $0) } ?? []
        let saved = defaults.string(forKey: "work.selected")
        selected = items.first { $0.id.uuidString == saved }?.id ?? items.first?.id
        settle()
    }

    var current: WorkItem? { items.first { $0.id == selected } }

    func add(_ name: String, goal: Int) {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let item = WorkItem(name: title, goal: goal)
        items.append(item)
        select(item.id)
    }

    func select(_ id: UUID) {
        guard items.contains(where: { $0.id == id }) else { return }
        if selected != id { change { $0.pause(at: Date()) } }
        selected = id
        save()
    }

    func change(_ edit: (inout WorkItem) -> Void) {
        guard let i = items.firstIndex(where: { $0.id == selected }) else { return }
        items[i].settle(at: Date())
        edit(&items[i])
        save()
    }

    private func settle() { change { _ in } }

    private func save() {
        defaults.set(try? JSONEncoder().encode(items), forKey: "work.items")
        defaults.set(selected?.uuidString, forKey: "work.selected")
        alarm?.cancel()
        if let end = current?.end {
            alarm = Task { [weak self] in
                try? await Task.sleep(for: .seconds(max(0, end.timeIntervalSinceNow)))
                guard !Task.isCancelled else { return }
                self?.settle()
            }
        }
    }
}
