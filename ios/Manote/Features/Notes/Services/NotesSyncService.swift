import Foundation
import Observation

/// Sumber catatan untuk semua layar. Perubahan langsung tersimpan di perangkat. Sinkron dengan
/// server (kirim yang tertunda, terima keadaan terbaru) hanya berjalan saat diminta pengguna.
@MainActor
@Observable
final class NotesSyncService {
    static let shared = NotesSyncService()

    private(set) var notes: [Note] = []
    private(set) var isSyncing = false
    private(set) var pendingCount = 0
    private(set) var lastSyncedAt: Date?
    /// Sebab sinkron terakhir gagal; `nil` jika berhasil.
    private(set) var lastErrorMessage: String?

    private var store: NotesStore?
    private let repository: NotesRepository

    init(repository: NotesRepository = NotesRepository()) {
        self.repository = repository
    }

    var status: SyncStatus {
        SyncStatus(
            isSyncing: isSyncing, pendingCount: pendingCount,
            lastSyncedAt: lastSyncedAt, errorMessage: lastErrorMessage
        )
    }

    /// Membuka catatan milik pengguna yang login.
    func start(userId: String, directory: URL = NotesStore.defaultDirectory) {
        store = NotesStore(userId: userId, directory: directory)
        lastErrorMessage = nil
        publish()
    }

    /// Dipanggil saat logout. Catatan tetap tersimpan di perangkat untuk login berikutnya.
    func stop() {
        store = nil
        lastErrorMessage = nil
        publish()
    }

    // MARK: - Perubahan di perangkat

    func note(id: UUID) -> Note? {
        store?.note(id: id)
    }

    @discardableResult
    func save(id: UUID?, draft: NoteDraft) -> Note? {
        let note = store?.save(id: id, draft: draft)
        publish()
        return note
    }

    func setReminder(id: UUID, at date: Date?) {
        store?.setReminder(id: id, at: date)
        publish()
    }

    func delete(id: UUID) {
        store?.delete(id: id)
        publish()
    }

    // MARK: - Sinkron

    /// Perangkat yang belum pernah sinkron dimuat sekali secara otomatis, supaya pengguna tidak
    /// melihat daftar kosong setelah login. Setelah itu sinkron hanya lewat tombol.
    func syncIfNeverSynced() async {
        guard lastSyncedAt == nil else { return }
        await sync()
    }

    /// Kirim perubahan yang tertunda dan terima keadaan terbaru dari server.
    @discardableResult
    func sync() async -> Bool {
        guard let store, !isSyncing else { return false }
        isSyncing = true
        defer { isSyncing = false }

        let pending = store.pendingNotes
        let pushed = Dictionary(uniqueKeysWithValues: pending.map { ($0.id, $0.updatedAt) })
        do {
            // Gagalnya tampil di status sinkron, jadi tidak perlu toast.
            let response = try await handlingErrorsLocally {
                try await repository.sync(since: store.cursor, changes: pending)
            }
            // Pengguna bisa saja logout atau berganti akun selagi menunggu.
            guard self.store === store else { return false }
            store.apply(response, pushed: pushed)
            lastErrorMessage = nil
            publish()
            return true
        } catch {
            guard self.store === store else { return false }
            lastErrorMessage = error.localizedDescription
            return false
        }
    }

    private func publish() {
        notes = store?.visibleNotes ?? []
        pendingCount = store?.pendingNotes.count ?? 0
        lastSyncedAt = store?.lastSyncedAt
    }
}
