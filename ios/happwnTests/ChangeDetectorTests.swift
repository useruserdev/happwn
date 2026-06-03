import XCTest
@testable import happwn

final class ChangeDetectorTests: XCTestCase {
    func testNoChangeIgnoresOrder() {
        let d = ChangeDetector.diff(old: ["a", "b"], new: ["b", "a"])
        XCTAssertFalse(d.changed)
        XCTAssertEqual(d.added, 0)
        XCTAssertEqual(d.removed, 0)
    }

    func testAddedAndRemoved() {
        let d = ChangeDetector.diff(old: ["a", "b"], new: ["b", "c", "d"])
        XCTAssertEqual(d.added, 2)   // c, d
        XCTAssertEqual(d.removed, 1) // a
        XCTAssertTrue(d.changed)
    }

    func testFromEmpty() {
        let d = ChangeDetector.diff(old: [], new: ["a"])
        XCTAssertEqual(d.added, 1)
        XCTAssertEqual(d.removed, 0)
        XCTAssertTrue(d.changed)
    }

    func testToEmpty() {
        let d = ChangeDetector.diff(old: ["a", "b"], new: [])
        XCTAssertEqual(d.removed, 2)
        XCTAssertTrue(d.changed)
    }
}
