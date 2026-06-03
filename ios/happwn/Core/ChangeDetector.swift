import Foundation

/// Pure diff of two config-URI snapshots. No I/O, fully testable.
enum ChangeDetector {
    struct Diff: Equatable {
        let added: Int
        let removed: Int
        var changed: Bool { added > 0 || removed > 0 }
    }

    static func diff(old: [String], new: [String]) -> Diff {
        let oldSet = Set(old)
        let newSet = Set(new)
        return Diff(
            added: newSet.subtracting(oldSet).count,
            removed: oldSet.subtracting(newSet).count
        )
    }
}
