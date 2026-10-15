import Foundation
import Observation

@MainActor
@Observable
final class NoteEditorViewModel {
    enum SaveStatus {
        case idle
        case saved

        var label: String {
            switch self {
            case .idle: ""
            case .saved: "Tersimpan"
            }
        }
    }

    var title: String { didSet { scheduleSave() } }
    var content: String { didSet { scheduleSave() } }
    private(set) var status: SaveStatus = .idle
    var reminderAt: Date?

    /// `nil` selama catatan baru belum pernah disimpan.
    private(set) var noteId: UUID?
    private var saved: NoteDraft
    private var saveTask: Task<Void, Never>?
    private var isClosed = false

    private let sync = NotesSyncService.shared
    private static let autosaveDelay: Duration = .milliseconds(700)

    init(note: Note?) {
        noteId = note?.id
        reminderAt = note?.reminderAt
        title = note?.title ?? ""
        content = note?.content ?? ""
        saved = NoteDraft(title: note?.title ?? "", content: note?.content ?? "")
    }

    var isNew: Bool { noteId == nil }

    private var draft: NoteDraft { NoteDraft(title: title, content: content) }

    /// Catatan ini sebagai sasaran pengingat; `nil` selama belum tersimpan.
    var reminderTarget: ReminderTarget? {
        guard let noteId, let note = sync.note(id: noteId) else { return nil }
        return ReminderTarget(noteId: noteId, title: note.displayTitle, reminderAt: reminderAt)
    }

    /// Pastikan catatan sudah tersimpan sebelum pengingat diatur.
    func saveNow() -> ReminderTarget? {
        saveTask?.cancel()
        save()
        return reminderTarget
    }

    /// Catatan ini dipindahkan menjadi kartu di Backlog kerjaan yang dipilih: pengingatnya menjadi
    /// tenggat kartu, lalu catatannya dihapus. Semuanya di perangkat, jadi bisa tanpa server.
    /// Mengembalikan `true` jika berhasil dipindahkan.
    func assign(to board: Board) async -> Bool {
        saveTask?.cancel()
        save()
        guard let noteId, let note = sync.note(id: noteId) else {
            ToastCenter.shared.show("Tulis catatan dulu sebelum dijadikan kerjaan.")
            return false
        }
        guard KanbanSyncService.shared.addCard(
            boardId: board.id, title: note.displayTitle, description: note.content, deadlineAt: note.reminderAt
        ) != nil else { return false }

        // Editor ditutup tanpa menyimpan lagi, dan pengingat catatan dibatalkan karena sudah
        // menjadi tenggat kartu.
        isClosed = true
        self.noteId = nil
        saved = draft
        sync.delete(id: noteId)
        await ReminderScheduler.shared.cancel(noteId: noteId)
        ToastCenter.shared.show("Dipindahkan ke Backlog “\(board.name)”", kind: .success)
        return true
    }

    /// Waktu mulai yang ditawarkan saat catatan dijadikan tugas: pengingatnya jika ada dan belum
    /// lewat, kalau tidak jam bulat berikutnya.
    var suggestedTaskStart: Date {
        if let reminderAt, reminderAt > .now { return reminderAt }
        let calendar = Calendar.current
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: .now) ?? .now
        return calendar.date(bySetting: .minute, value: 0, of: nextHour) ?? nextHour
    }

    /// Catatan ini dipindahkan menjadi tugas: judulnya menjadi nama tugas, isinya menjadi
    /// keterangan, lalu catatannya dihapus. Semuanya di perangkat, jadi bisa tanpa server.
    /// Mengembalikan `true` jika berhasil dipindahkan.
    func convertToTask(startAt: Date) async -> Bool {
        saveTask?.cancel()
        save()
        guard let noteId, let note = sync.note(id: noteId) else {
            ToastCenter.shared.show("Tulis catatan dulu sebelum dijadikan tugas.")
            return false
        }
        guard TasksSyncService.shared.save(
            id: nil, title: note.displayTitle, details: note.content, startAt: startAt
        ) != nil else { return false }

        // Editor ditutup tanpa menyimpan lagi, dan pengingat catatan dibatalkan karena perannya
        // digantikan alarm tugas.
        isClosed = true
        self.noteId = nil
        saved = draft
        sync.delete(id: noteId)
        await ReminderScheduler.shared.cancel(noteId: noteId)
        ToastCenter.shared.show("Dipindahkan ke Tugas", kind: .success)
        return true
    }

    /// Simpan perubahan terakhir dan buang catatan yang kosong.
    func close() async {
        guard !isClosed else { return }
        isClosed = true
        saveTask?.cancel()
        save()
        if let id = noteId, draft.isBlank {
            sync.delete(id: id)
            await ReminderScheduler.shared.cancel(noteId: id)
            noteId = nil
            reminderAt = nil
            saved = draft
        }
    }

    /// Layar editor tampil lagi, misalnya setelah berpindah tab.
    func reopen() {
        isClosed = false
    }

    func delete() async {
        isClosed = true
        saveTask?.cancel()
        if let noteId {
            sync.delete(id: noteId)
            await ReminderScheduler.shared.cancel(noteId: noteId)
        }
    }

    private func scheduleSave() {
        guard !isClosed else { return }
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: Self.autosaveDelay)
            guard !Task.isCancelled else { return }
            save()
        }
    }

    /// Menyimpan ke perangkat; pengiriman ke server diurus oleh sinkronisasi.
    private func save() {
        let current = draft
        guard current != saved else { return }
        if noteId == nil && current.isBlank { return }

        guard let note = sync.save(id: noteId, draft: current) else { return }
        noteId = note.id
        saved = current
        status = .saved
    }
}
