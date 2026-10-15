import Foundation
import Observation

@MainActor
@Observable
final class TasksViewModel {
    private let sync = TasksSyncService.shared
    private let alarms = TaskAlarmScheduler.shared

    var pendingTasks: [TaskItem] { sync.pendingTasks }

    var doneTasks: [TaskItem] { sync.doneTasks }

    var syncStatus: SyncStatus { sync.status }

    var isEmpty: Bool { pendingTasks.isEmpty && doneTasks.isEmpty }

    var isAlarmDenied: Bool { alarms.isAlarmDenied }

    /// Perangkat ini belum pernah sinkron, jadi daftar kosong belum tentu berarti tidak ada tugas.
    var isLoadingFirstSync: Bool {
        isEmpty && sync.lastSyncedAt == nil && sync.isSyncing
    }

    func syncNow() async {
        await sync.sync()
    }

    func syncIfNeverSynced() async {
        await sync.syncIfNeverSynced()
    }

    func save(id: UUID?, title: String, details: String, startAt: Date) {
        sync.save(id: id, title: title.trimmingCharacters(in: .whitespaces), details: details, startAt: startAt)
    }

    /// Mencentang tugas, atau mematikan alarmnya dari daftar: tugas selesai dan alarmnya berhenti.
    func setDone(_ task: TaskItem, _ done: Bool) {
        sync.setDone(id: task.id, done)
        if done {
            alarms.cancel(taskId: task.id)
        }
    }

    func delete(_ task: TaskItem) {
        sync.delete(id: task.id)
        alarms.cancel(taskId: task.id)
    }
}
