import Foundation
import Combine

/// Persists the list of saved subscriptions as JSON on disk.
/// Mutated on the main thread (from views and the main-actor RefreshCoordinator).
final class SubscriptionStore: ObservableObject {
    @Published private(set) var items: [SavedSubscription] = []

    private let fileURL: URL

    /// Defaults to Application Support; tests inject a temp file.
    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        load()
    }

    // MARK: Mutations

    func add(_ sub: SavedSubscription) {
        items.append(sub)
        save()
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func remove(atOffsets offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func update(_ sub: SavedSubscription) {
        guard let i = items.firstIndex(where: { $0.id == sub.id }) else { return }
        items[i] = sub
        save()
    }

    /// Replace the whole list (used after a batch refresh).
    func replaceAll(_ updated: [SavedSubscription]) {
        items = updated
        save()
    }

    /// Clear the unseen-update badge after the user views a subscription.
    func markSeen(_ id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }), items[i].hasUnseenUpdate else { return }
        items[i].hasUnseenUpdate = false
        save()
    }

    func binding(for id: UUID) -> SavedSubscription? {
        items.first { $0.id == id }
    }

    // MARK: Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([SavedSubscription].self, from: data) {
            items = decoded
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func defaultFileURL() -> URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("subscriptions.json")
    }
}
