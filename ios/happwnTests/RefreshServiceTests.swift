import XCTest
@testable import happwn

private final class SpyNotifier: SubscriptionNotifying, @unchecked Sendable {
    private(set) var calls: [(name: String, added: Int, removed: Int)] = []
    func notifyChange(subscription: SavedSubscription, added: Int, removed: Int) async {
        calls.append((subscription.name, added, removed))
    }
}

final class RefreshServiceTests: XCTestCase {
    private func result(_ uris: [String]) -> ExtractionResult {
        ExtractionResult(mode: "url", source: "https://s",
                         configs: uris.map { ConfigEntry(uri: $0) }, rawBody: nil)
    }

    func testDetectsChangeAndNotifies() async {
        var sub = SavedSubscription(name: "S", link: "https://s")
        sub.lastConfigs = ["a"]
        let spy = SpyNotifier()
        var service = RefreshService()
        service.extract = { _, _, _ in self.result(["a", "b"]) }

        let updated = await service.refreshAll([sub], userAgent: "u", hwid: "h",
                                               notificationsEnabled: true, notifier: spy)

        XCTAssertEqual(updated.first?.lastConfigs.count, 2)
        XCTAssertEqual(updated.first?.hasUnseenUpdate, true)
        XCTAssertNotNil(updated.first?.lastChangedAt)
        XCTAssertEqual(spy.calls.count, 1)
        XCTAssertEqual(spy.calls.first?.added, 1)
        XCTAssertEqual(spy.calls.first?.removed, 0)
    }

    func testNoChangeNoNotify() async {
        var sub = SavedSubscription(name: "S", link: "https://s")
        sub.lastConfigs = ["a"]
        let spy = SpyNotifier()
        var service = RefreshService()
        service.extract = { _, _, _ in self.result(["a"]) }

        let updated = await service.refreshAll([sub], userAgent: "u", hwid: "h",
                                               notificationsEnabled: true, notifier: spy)

        XCTAssertEqual(updated.first?.hasUnseenUpdate, false)
        XCTAssertTrue(spy.calls.isEmpty)
    }

    func testNotificationsDisabledStillFlagsButDoesNotNotify() async {
        let sub = SavedSubscription(name: "S", link: "https://s") // empty lastConfigs
        let spy = SpyNotifier()
        var service = RefreshService()
        service.extract = { _, _, _ in self.result(["a"]) }

        let updated = await service.refreshAll([sub], userAgent: "u", hwid: "h",
                                               notificationsEnabled: false, notifier: spy)

        XCTAssertEqual(updated.first?.hasUnseenUpdate, true)
        XCTAssertTrue(spy.calls.isEmpty)
    }

    func testFailingSubscriptionDoesNotAbortOthers() async {
        let bad = SavedSubscription(name: "bad", link: "https://b")
        let good = SavedSubscription(name: "good", link: "https://g")
        let spy = SpyNotifier()
        var service = RefreshService()
        service.extract = { link, _, _ in
            if link == "https://b" { throw SubscriptionError.empty }
            return self.result(["a"])
        }

        let updated = await service.refreshAll([bad, good], userAgent: "u", hwid: "h",
                                               notificationsEnabled: true, notifier: spy)

        XCTAssertEqual(updated.count, 2)
        XCTAssertNotNil(updated.first { $0.name == "bad" }?.lastError)
        XCTAssertNil(updated.first { $0.name == "good" }?.lastError)
    }
}
