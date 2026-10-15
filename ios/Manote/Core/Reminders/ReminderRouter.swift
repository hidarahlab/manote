import Observation
import UserNotifications

/// Menyimpan catatan yang harus dibuka setelah notifikasi pengingat diketuk.
@MainActor
@Observable
final class ReminderRouter {
    static let shared = ReminderRouter()

    var pendingNoteId: UUID?
}

/// Menampilkan notifikasi saat aplikasi sedang terbuka dan meneruskan ketukan ke `ReminderRouter`.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let noteId = ReminderScheduler.noteId(from: response.notification.request.content.userInfo)
        await MainActor.run {
            ReminderRouter.shared.pendingNoteId = noteId
        }
    }
}
