import Foundation
import WidgetKit

@MainActor
enum WidgetSnapshotWriter {
    static func update(isLoggedIn: Bool = true, tasksOnly: Bool = false) {
        var snapshot = tasksOnly ? WidgetSnapshot.load() : WidgetSnapshot()
        snapshot.isLoggedIn = isLoggedIn

        if isLoggedIn {
            let tasks = TasksSyncService.shared.pendingTasks
            snapshot.nextTaskTitle = tasks.first?.title
            snapshot.nextTaskStart = tasks.first?.startAt
            snapshot.pendingTasks = tasks.count
        }
        if isLoggedIn && !tasksOnly {
            snapshot.notes = NotesSyncService.shared.notes.count

            let cards = KanbanSyncService.shared.cards
            snapshot.openCards = cards.filter { $0.status != .done }.count
            // Kartu yang sudah lewat tenggat tetap dihitung mendesak.
            snapshot.urgentCards = cards.filter { [.urgent, .overdue].contains($0.deadlineLevel()) }.count
        }

        if snapshot.save() {
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetSnapshot.widgetKind)
        }
    }
}
