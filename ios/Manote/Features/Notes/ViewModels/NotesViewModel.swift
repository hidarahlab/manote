import Foundation
import Observation

@MainActor
@Observable
final class NotesViewModel {
    private let sync = NotesSyncService.shared

    /// Dibaca dari perangkat, jadi langsung tampil tanpa menunggu server.
    var notes: [Note] { sync.notes }

    var syncStatus: SyncStatus { sync.status }

    /// Perangkat ini belum pernah sinkron, jadi daftar kosong belum tentu berarti tidak ada catatan.
    var isLoadingFirstSync: Bool {
        sync.notes.isEmpty && sync.lastSyncedAt == nil && sync.isSyncing
    }

    func syncNow() async {
        await sync.sync()
    }

    func syncIfNeverSynced() async {
        await sync.syncIfNeverSynced()
    }

    func delete(_ note: Note) async {
        sync.delete(id: note.id)
        await ReminderScheduler.shared.cancel(noteId: note.id)
    }
}
