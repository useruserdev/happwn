import XCTest
@testable import happwn

@MainActor
final class SubscriptionStoreTests: XCTestCase {
    private func tempURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
    }

    func testAddPersistsAndReloads() {
        let url = tempURL()
        let store = SubscriptionStore(fileURL: url)
        store.add(SavedSubscription(name: "X", link: "happ://x"))
        XCTAssertEqual(store.items.count, 1)

        let reloaded = SubscriptionStore(fileURL: url)
        XCTAssertEqual(reloaded.items.count, 1)
        XCTAssertEqual(reloaded.items.first?.name, "X")
        XCTAssertEqual(reloaded.items.first?.link, "happ://x")
    }

    func testRemoveByID() {
        let store = SubscriptionStore(fileURL: tempURL())
        let sub = SavedSubscription(name: "X", link: "happ://x")
        store.add(sub)
        store.remove(sub.id)
        XCTAssertTrue(store.items.isEmpty)
    }

    func testUpdate() {
        let store = SubscriptionStore(fileURL: tempURL())
        var sub = SavedSubscription(name: "X", link: "happ://x")
        store.add(sub)
        sub.name = "Y"
        store.update(sub)
        XCTAssertEqual(store.items.first?.name, "Y")
    }

    func testMarkSeenClearsBadge() {
        let store = SubscriptionStore(fileURL: tempURL())
        var sub = SavedSubscription(name: "X", link: "happ://x")
        sub.hasUnseenUpdate = true
        store.add(sub)
        store.markSeen(sub.id)
        XCTAssertEqual(store.items.first?.hasUnseenUpdate, false)
    }

    func testReplaceAll() {
        let store = SubscriptionStore(fileURL: tempURL())
        store.add(SavedSubscription(name: "A", link: "happ://a"))
        var updated = store.items
        updated[0].lastConfigs = ["vless://x"]
        store.replaceAll(updated)
        XCTAssertEqual(store.items.first?.lastConfigs, ["vless://x"])
    }
}
