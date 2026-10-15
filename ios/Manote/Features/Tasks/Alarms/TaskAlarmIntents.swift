import AppIntents
import Foundation

/// Tombol Matikan pada alarm: alarm berhenti dan tugasnya dianggap selesai.
struct StopTaskAlarmIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Matikan alarm tugas"

    @Parameter(title: "ID tugas")
    var taskId: String

    init() {}

    init(taskId: String) {
        self.taskId = taskId
    }

    func perform() async throws -> some IntentResult {
        await TaskAlarmActions.turnOff(taskId: taskId)
        return .result()
    }
}

/// Tombol "Tunda 5 menit" pada alarm: alarm berbunyi lagi 5 menit kemudian.
struct SnoozeTaskAlarmIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Tunda alarm tugas 5 menit"

    @Parameter(title: "ID tugas")
    var taskId: String

    init() {}

    init(taskId: String) {
        self.taskId = taskId
    }

    func perform() async throws -> some IntentResult {
        await TaskAlarmActions.snooze(taskId: taskId)
        return .result()
    }
}

/// Yang dijalankan tombol alarm. Bisa terpanggil saat aplikasi tidak sedang dibuka, jadi data
/// tugas dibuka dulu dari perangkat kalau belum.
@MainActor
enum TaskAlarmActions {
    static func turnOff(taskId: String) {
        guard let id = UUID(uuidString: taskId) else { return }
        service()?.setDone(id: id, true)
        TaskAlarmScheduler.shared.cancel(taskId: id)
        // Aplikasi bisa saja tidak sedang terbuka, jadi widget diperbarui dari sini juga.
        WidgetSnapshotWriter.update(tasksOnly: true)
    }

    static func snooze(taskId: String) async {
        guard let id = UUID(uuidString: taskId), let task = service()?.task(id: id) else { return }
        await TaskAlarmScheduler.shared.snooze(taskId: id, title: task.title)
    }

    private static func service() -> TasksSyncService? {
        let service = TasksSyncService.shared
        if !service.isStarted {
            guard let userId = SessionStore.cachedUserId else { return nil }
            service.start(userId: userId)
        }
        return service
    }
}
