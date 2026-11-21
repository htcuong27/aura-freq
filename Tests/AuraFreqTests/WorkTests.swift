import XCTest
@testable import AuraFreq

final class WorkTests: XCTestCase {
    func testPauseAndExpiry() {
        let now = Date()
        var item = WorkItem(name: "Test", goal: 2)
        item.end = now.addingTimeInterval(60)
        item.pause(at: now)
        XCTAssertEqual(item.seconds, 60)
        item.end = now
        item.settle(at: now)
        item.settle(at: now)
        XCTAssertEqual(item.completed, 1)
        XCTAssertTrue(item.resting)
        XCTAssertEqual(item.seconds, 300)
        item.end = now
        item.settle(at: now)
        XCTAssertEqual(item.completed, 1)
        XCTAssertEqual(item.seconds, 1500)
    }

    @MainActor func testSwitchAndRestore() {
        let key = UUID().uuidString
        let defaults = UserDefaults(suiteName: key)!
        defer { defaults.removePersistentDomain(forName: key) }
        let session = WorkSession(defaults: defaults)
        session.add("A", goal: 2)
        let first = session.selected!
        session.change { $0.end = Date().addingTimeInterval(40) }
        session.add("B", goal: 1)
        session.select(first)
        let restored = WorkSession(defaults: defaults)
        XCTAssertEqual(restored.current?.seconds, 40)
        XCTAssertNil(restored.current?.end)
        XCTAssertEqual(restored.items.count, 2)
    }

    func testVideoLinks() {
        for url in ["youtu.be/jfKfPfyJRdk?t=3", "https://www.youtube.com/watch?v=jfKfPfyJRdk", "https://youtube.com/live/jfKfPfyJRdk"] {
            XCTAssertEqual(youtubeID(url), "jfKfPfyJRdk")
        }
        XCTAssertNil(youtubeID("https://youtube.com.example/watch?v=jfKfPfyJRdk"))
        XCTAssertNil(youtubeID("https://youtu.be/invalid"))
    }
}
