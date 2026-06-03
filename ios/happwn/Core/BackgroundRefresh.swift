import Foundation
import BackgroundTasks

/// Registration and scheduling of the opportunistic background refresh task.
/// iOS decides when to actually run it (roughly based on app usage); this is
/// not a guaranteed fixed-interval timer.
enum BackgroundRefresh {
    static let taskID = "com.happwn.refresh"

    /// Register the task handler. Must be called before the app finishes launching.
    static func register(coordinator: @escaping () -> RefreshCoordinator,
                         minInterval: @escaping () -> TimeInterval) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: nil) { task in
            guard let task = task as? BGAppRefreshTask else { return }
            handle(task: task, coordinator: coordinator(), minInterval: minInterval())
        }
    }

    /// Ask the system to schedule the next refresh no sooner than `minInterval`.
    static func schedule(minInterval: TimeInterval) {
        let request = BGAppRefreshTaskRequest(identifier: taskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: minInterval)
        try? BGTaskScheduler.shared.submit(request)
    }

    static func cancel() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskID)
    }

    private static func handle(task: BGAppRefreshTask, coordinator: RefreshCoordinator, minInterval: TimeInterval) {
        // Always line up the next opportunity.
        schedule(minInterval: minInterval)

        let work = Task {
            await coordinator.refreshAll()
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = {
            work.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}
