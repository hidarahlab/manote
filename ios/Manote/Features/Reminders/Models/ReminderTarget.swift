import Foundation

/// Catatan yang sedang diatur pengingatnya.
struct ReminderTarget: Identifiable, Equatable {
    let noteId: UUID
    let title: String
    var reminderAt: Date?

    var id: UUID { noteId }
}
