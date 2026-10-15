import Foundation
import SwiftUI
import UserNotifications
#if canImport(AlarmKit)
import AlarmKit
#endif

/// Menyamakan alarm di perangkat dengan daftar tugas: tiap tugas yang belum selesai dan waktu
/// mulainya belum lewat punya satu alarm (AlarmKit, iOS 26 ke atas) dan satu notifikasi.
/// Di iOS yang lebih lama hanya notifikasinya yang ada.
@MainActor
final class TaskAlarmScheduler {
    static let shared = TaskAlarmScheduler()

    /// Lama penundaan saat tombol "Tunda 5 menit" pada alarm ditekan.
    static let snoozeInterval: TimeInterval = 5 * 60

    /// `false` jika pengguna menolak izin alarm; layar Tugas menampilkan petunjuknya.
    private(set) var isAlarmDenied = false

    private let notificationCenter = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard
    private var isReconciling = false
    private var pendingReconcile: [TaskItem]?

    /// Dipanggil setiap daftar tugas berubah.
    func reconcile(pending tasks: [TaskItem]) async {
        // Perubahan beruntun cukup diproses dengan daftar yang paling akhir.
        guard !isReconciling else {
            pendingReconcile = tasks
            return
        }
        isReconciling = true
        var current: [TaskItem]? = tasks
        while let tasks = current {
            pendingReconcile = nil
            await apply(tasks)
            current = pendingReconcile
        }
        isReconciling = false
    }

    /// Tombol "Tunda 5 menit" pada alarm: bunyikan lagi 5 menit kemudian.
    func snooze(taskId: UUID, title: String) async {
        let date = Date.now.addingTimeInterval(Self.snoozeInterval)
        await scheduleAlarm(taskId: taskId, title: title, at: date)
        await scheduleNotification(taskId: taskId, title: title, at: date)
    }

    /// Alarm tugas dimatikan atau tugasnya selesai/dihapus.
    func cancel(taskId: UUID) {
        cancelAlarm(taskId: taskId)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [Self.notificationId(taskId)])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [Self.notificationId(taskId)])
        scheduled[taskId.uuidString] = nil
    }

    private func apply(_ tasks: [TaskItem]) async {
        let now = Date.now
        let pendingIds = Set(tasks.map(\.id))

        // Alarm dan notifikasi milik tugas yang sudah selesai atau dihapus dibatalkan.
        for key in scheduled.keys {
            guard let id = UUID(uuidString: key), !pendingIds.contains(id) else { continue }
            cancel(taskId: id)
        }

        for task in tasks where task.startAt > now {
            // Sudah terjadwal dengan waktu dan judul yang sama: biarkan.
            let signature = "\(task.startAt.timeIntervalSince1970)|\(task.title)"
            if scheduled[task.id.uuidString] == signature { continue }
            await scheduleAlarm(taskId: task.id, title: task.title, at: task.startAt)
            await scheduleNotification(taskId: task.id, title: task.title, at: task.startAt)
            scheduled[task.id.uuidString] = signature
        }
    }

    /// Waktu dan judul yang sudah dijadwalkan per tugas, supaya tidak dijadwalkan ulang tanpa perlu.
    private var scheduled: [String: String] {
        get { defaults.dictionary(forKey: "tasks.alarms.scheduled.v2") as? [String: String] ?? [:] }
        set { defaults.set(newValue, forKey: "tasks.alarms.scheduled.v2") }
    }

    // MARK: - Alarm (AlarmKit)

    private func scheduleAlarm(taskId: UUID, title: String, at date: Date) async {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return }
        do {
            guard try await AlarmManager.shared.requestAuthorization() == .authorized else {
                isAlarmDenied = true
                return
            }
            isAlarmDenied = false
            // ID alarm sama dengan ID tugas, jadi alarm lama untuk tugas ini diganti.
            try? AlarmManager.shared.cancel(id: taskId)
            _ = try await AlarmManager.shared.schedule(
                id: taskId,
                configuration: TaskAlarmConfiguration.make(taskId: taskId, title: title, date: date)
            )
        } catch {
            ToastCenter.shared.show("Alarm untuk “\(title)” tidak bisa dipasang.")
        }
        #endif
    }

    private func cancelAlarm(taskId: UUID) {
        #if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return }
        // `stop` untuk alarm yang sedang berbunyi, `cancel` untuk yang belum.
        try? AlarmManager.shared.stop(id: taskId)
        try? AlarmManager.shared.cancel(id: taskId)
        #endif
    }

    // MARK: - Notifikasi

    private func scheduleNotification(taskId: UUID, title: String, at date: Date) async {
        guard (try? await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])) == true else {
            return
        }
        let content = UNMutableNotificationContent()
        // Isi notifikasi: judul tugas dan tanggal mulainya.
        content.title = title
        content.body = TaskItem.startText(for: date)
        content.sound = .default
        content.userInfo = [Self.taskIdKey: taskId.uuidString]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let request = UNNotificationRequest(
            identifier: Self.notificationId(taskId),
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
        try? await notificationCenter.add(request)
    }

    nonisolated static let taskIdKey = "taskId"

    private static func notificationId(_ taskId: UUID) -> String {
        "task-\(taskId.uuidString)"
    }
}

#if canImport(AlarmKit)
@available(iOS 26.0, *)
struct TaskAlarmMetadata: AlarmMetadata {}

@available(iOS 26.0, *)
enum TaskAlarmConfiguration {
    /// Alarm layar penuh berjudul nama tugas, dengan tombol Matikan dan "Tunda 5 menit".
    static func make(taskId: UUID, title: String, date: Date) -> AlarmManager.AlarmConfiguration<TaskAlarmMetadata> {
        let snoozeButton = AlarmButton(text: "Tunda 5 menit", textColor: .white, systemImageName: "clock.arrow.circlepath")
        let alertTitle = LocalizedStringResource(stringLiteral: title)

        let alert: AlarmPresentation.Alert
        if #available(iOS 26.1, *) {
            alert = AlarmPresentation.Alert(title: alertTitle, secondaryButton: snoozeButton, secondaryButtonBehavior: .custom)
        } else {
            alert = AlarmPresentation.Alert(
                title: alertTitle,
                stopButton: AlarmButton(text: "Matikan", textColor: .white, systemImageName: "stop.circle"),
                secondaryButton: snoozeButton,
                secondaryButtonBehavior: .custom
            )
        }
        let attributes = AlarmAttributes<TaskAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            tintColor: Color(light: 0x534AB7, dark: 0xAFA9EC)
        )
        return .alarm(
            schedule: .fixed(date),
            attributes: attributes,
            stopIntent: StopTaskAlarmIntent(taskId: taskId.uuidString),
            secondaryIntent: SnoozeTaskAlarmIntent(taskId: taskId.uuidString)
        )
    }
}
#endif
