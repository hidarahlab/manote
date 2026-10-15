import Foundation

/// Penyimpanan catatan di perangkat, satu file per pengguna. Semua layar membaca dari sini,
/// jadi catatan tetap tampil dan bisa diubah tanpa server.
@MainActor
final class NotesStore {
    private struct State: Codable {
        var notes: [Note] = []
        var cursor: String?
        var lastSyncedAt: Date?
    }

    private var state: State
    private let fileURL: URL

    init(userId: String, directory: URL = NotesStore.defaultDirectory) {
        fileURL = directory.appending(path: "notes-\(userId).json")
        if let data = try? Data(contentsOf: fileURL), let saved = try? JSONDecoder().decode(State.self, from: data) {
            state = saved
        } else {
            state = State()
        }
    }

    nonisolated static var defaultDirectory: URL {
        URL.applicationSupportDirectory.appending(path: "Manote", directoryHint: .isDirectory)
    }

    // MARK: - Baca

    /// Catatan yang tampil ke pengguna, terbaru di atas.
    var visibleNotes: [Note] {
        state.notes.filter { !$0.isDeleted }.sorted { $0.updatedAt > $1.updatedAt }
    }

    /// Perubahan yang belum sampai ke server.
    var pendingNotes: [Note] { state.notes.filter(\.isDirty) }

    var cursor: String? { state.cursor }

    var lastSyncedAt: Date? { state.lastSyncedAt }

    func note(id: UUID) -> Note? {
        state.notes.first { $0.id == id && !$0.isDeleted }
    }

    // MARK: - Ubah di perangkat

    /// Membuat catatan baru (`id` kosong) atau mengubah yang ada.
    @discardableResult
    func save(id: UUID?, draft: NoteDraft, now: Date = .now) -> Note {
        if let id, let index = state.notes.firstIndex(where: { $0.id == id }) {
            state.notes[index].title = draft.title
            state.notes[index].content = draft.content
            state.notes[index].updatedAt = now
            state.notes[index].isDeleted = false
            state.notes[index].isDirty = true
            persist()
            return state.notes[index]
        }
        let note = Note(
            id: id ?? UUID(), serverId: nil, title: draft.title, content: draft.content,
            createdAt: now, updatedAt: now, reminderAt: nil, isDeleted: false, isDirty: true
        )
        state.notes.append(note)
        persist()
        return note
    }

    func setReminder(id: UUID, at date: Date?, now: Date = .now) {
        guard let index = state.notes.firstIndex(where: { $0.id == id }) else { return }
        state.notes[index].reminderAt = date
        state.notes[index].updatedAt = now
        state.notes[index].isDirty = true
        persist()
    }

    /// Menandai terhapus; barisnya baru dibuang setelah server diberi tahu.
    func delete(id: UUID, now: Date = .now) {
        guard let index = state.notes.firstIndex(where: { $0.id == id }) else { return }
        state.notes[index].isDeleted = true
        state.notes[index].reminderAt = nil
        state.notes[index].updatedAt = now
        state.notes[index].isDirty = true
        persist()
    }

    // MARK: - Terapkan hasil sinkron

    /// - Parameter pushed: catatan yang dikirim pada sinkron ini, dengan waktu ubahnya saat dikirim.
    func apply(_ response: NoteSyncResponse, pushed: [UUID: Date], now: Date = .now) {
        for serverNote in response.notes {
            let index = state.notes.firstIndex { $0.id == serverNote.clientId }

            // Diubah lagi di perangkat setelah dikirim (atau belum sempat dikirim): versi perangkat
            // dipertahankan dan dikirim pada sinkron berikutnya.
            if let index, state.notes[index].isDirty,
               state.notes[index].updatedAt > (pushed[serverNote.clientId] ?? .distantPast) {
                state.notes[index].serverId = serverNote.id
                continue
            }

            if serverNote.deleted {
                if let index { state.notes.remove(at: index) }
                continue
            }

            let note = Note(
                id: serverNote.clientId, serverId: serverNote.id, title: serverNote.title,
                content: serverNote.content, createdAt: serverNote.createdAt, updatedAt: serverNote.updatedAt,
                reminderAt: serverNote.reminderAt, isDeleted: false, isDirty: false
            )
            if let index {
                state.notes[index] = note
            } else {
                state.notes.append(note)
            }
        }

        // Tanda terhapus yang sudah dikirim tidak perlu disimpan lagi.
        state.notes.removeAll { note in
            note.isDeleted && pushed[note.id] == note.updatedAt
        }

        state.cursor = response.cursor
        state.lastSyncedAt = now
        persist()
    }

    private func persist() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(state).write(to: fileURL, options: .atomic)
        } catch {
            assertionFailure("Gagal menyimpan catatan ke perangkat: \(error)")
        }
    }
}
