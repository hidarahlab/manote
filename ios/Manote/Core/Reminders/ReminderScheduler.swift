import EventKit
import Foundation
import UserNotifications

/// Menjadwalkan pengingat catatan sebagai notifikasi lokal dan acara kalender di perangkat ini.
@MainActor
final class ReminderScheduler {
    struct Outcome {
        var notificationScheduled = false
        var calendarEventAdded = false
    }

    static let shared = ReminderScheduler()
    nonisolated static let noteIdKey = "noteId"

    private let notificationCenter = UNUserNotificationCenter.current()
    private let eventStore = EKEventStore()
    private let defaults = UserDefaults.standard
    private static let eventDuration: TimeInterval = 30 * 60

    func schedule(noteId: UUID, title: String, at date: Date) async -> Outcome {
        await cancel(noteId: noteId)
        return Outcome(
            notificationScheduled: await scheduleNotification(noteId: noteId, title: title, at: date),
            calendarEventAdded: await addCalendarEvent(noteId: noteId, title: title, at: date)
        )
    }

    func cancel(noteId: UUID) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [Self.notificationId(noteId)])
        removeCalendarEvent(noteId: noteId)
    }

    /// Batalkan pengingat di perangkat yang catatannya sudah dihapus atau pengingatnya dicabut di tempat lain.
    func cancelAll(except noteIdsWithReminder: Set<UUID>) async {
        let pending = await notificationCenter.pendingNotificationRequests()
        for request in pending {
            guard let noteId = Self.noteId(from: request.content.userInfo),
                  !noteIdsWithReminder.contains(noteId) else { continue }
            await cancel(noteId: noteId)
        }
    }

    // MARK: - Notifikasi

    private func scheduleNotification(noteId: UUID, title: String, at date: Date) async -> Bool {
        guard (try? await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])) == true else {
            return false
        }

        let content = UNMutableNotificationContent()
        content.title = "Pengingat catatan"
        content.body = title
        content.sound = .default
        content.userInfo = [Self.noteIdKey: noteId.uuidString]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let request = UNNotificationRequest(
            identifier: Self.notificationId(noteId),
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
        return (try? await notificationCenter.add(request)) != nil
    }

    private static func notificationId(_ noteId: UUID) -> String {
        "note-\(noteId.uuidString)"
    }

    nonisolated static func noteId(from userInfo: [AnyHashable: Any]) -> UUID? {
        (userInfo[noteIdKey] as? String).flatMap(UUID.init(uuidString:))
    }

    // MARK: - Kalender

    private func addCalendarEvent(noteId: UUID, title: String, at date: Date) async -> Bool {
        guard (try? await eventStore.requestFullAccessToEvents()) == true,
              let calendar = eventStore.defaultCalendarForNewEvents else {
            return false
        }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = title
        event.startDate = date
        event.endDate = date.addingTimeInterval(Self.eventDuration)
        event.notes = "Pengingat dari Manote"
        event.addAlarm(EKAlarm(relativeOffset: 0))

        do {
            try eventStore.save(event, span: .thisEvent)
            defaults.set(event.eventIdentifier, forKey: Self.eventKey(noteId))
            return true
        } catch {
            return false
        }
    }

    private func removeCalendarEvent(noteId: UUID) {
        let key = Self.eventKey(noteId)
        guard let identifier = defaults.string(forKey: key) else { return }
        defaults.removeObject(forKey: key)
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess,
              let event = eventStore.event(withIdentifier: identifier) else { return }
        try? eventStore.remove(event, span: .thisEvent)
    }

    private static func eventKey(_ noteId: UUID) -> String {
        "reminder.calendarEvent.\(noteId.uuidString)"
    }
}
