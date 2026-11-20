import XCTest
@testable import AuraFreq

final class RampTests: XCTestCase {
    func testRapidRetuningContinuesFromCurrentValue() {
        var ramp = Ramp(432)
        ramp.set(832, frames: 400)
        for _ in 0..<100 { _ = ramp.advance() }
        XCTAssertEqual(ramp.value, 532)
        ramp.set(332, frames: 400)
        for _ in 0..<400 {
            ramp.set(332, frames: 400)
            let previous = ramp.value
            XCTAssertEqual(previous - ramp.advance(), 0.5)
        }
        XCTAssertEqual(ramp.advance(), 332)
    }
}
