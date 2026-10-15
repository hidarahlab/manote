import Foundation
import Observation

@MainActor
@Observable
final class ReminderViewModel {
    let target: ReminderTarget
    var date: Date
    private(set) var isSaving = false
    /// Peringatan setelah pengingat tersimpan, misalnya izin notifikasi ditolak.
    private(set) var warning: String?

    private let sync = NotesSyncService.shared
    private let scheduler = ReminderScheduler.shared

    init(target: ReminderTarget) {
        self.target = target
        date = target.reminderAt ?? Self.defaultDate()
    }

    var hasExistingReminder: Bool { target.reminderAt != nil }

    var minimumDate: Date { .now }

    /// Pengingat tersimpan di perangkat; sinkronisasi yang mengirimnya ke server.
    func save() async -> Date {
        isSaving = true
        defer { isSaving = false }

        sync.setReminder(id: target.noteId, at: date)
        let outcome = await scheduler.schedule(noteId: target.noteId, title: target.title, at: date)
        warning = Self.warning(for: outcome)
        return date
    }

    func remove() async {
        isSaving = true
        defer { isSaving = false }

        sync.setReminder(id: target.noteId, at: nil)
        await scheduler.cancel(noteId: target.noteId)
    }

    private static func warning(for outcome: ReminderScheduler.Outcome) -> String? {
        switch (outcome.notificationScheduled, outcome.calendarEventAdded) {
        case (true, true):
            nil
        case (false, true):
            "Pengingat masuk ke Kalender, tetapi notifikasi belum diizinkan. Aktifkan di Pengaturan > Manote > Notifikasi."
        case (true, false):
            "Notifikasi terjadwal, tetapi akses Kalender belum diizinkan. Aktifkan di Pengaturan > Manote > Kalender."
        case (false, false):
            "Pengingat tersimpan, tetapi notifikasi dan Kalender belum diizinkan. Aktifkan keduanya di Pengaturan > Manote."
        }
    }

    /// Jam bulat berikutnya, supaya nilai awal tidak pernah di masa lalu.
    private static func defaultDate(now: Date = .now) -> Date {
        let calendar = Calendar.current
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        return calendar.date(bySetting: .minute, value: 0, of: nextHour) ?? nextHour
    }
}
