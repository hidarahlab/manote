import Foundation
import Observation

/// Sumber tugas untuk semua layar. Perubahan langsung tersimpan di perangkat. Sinkron dengan
/// server hanya berjalan saat diminta pengguna.
@MainActor
@Observable
final class TasksSyncService {
    static let shared = TasksSyncService()

    private(set) var pendingTasks: [TaskItem] = []
    private(set) var doneTasks: [TaskItem] = []
    private(set) var isSyncing = false
    private(set) var unsyncedCount = 0
    private(set) var lastSyncedAt: Date?
    /// Sebab sinkron terakhir gagal; `nil` jika berhasil.
    private(set) var lastErrorMessage: String?
    /// Naik setiap daftar tugas berubah, supaya alarm di perangkat disesuaikan.
    private(set) var revision = 0

    private var store: TasksStore?
    private let repository: TasksRepository

    init(repository: TasksRepository = TasksRepository()) {
        self.repository = repository
    }

    var status: SyncStatus {
        SyncStatus(
            isSyncing: isSyncing, pendingCount: unsyncedCount,
            lastSyncedAt: lastSyncedAt, errorMessage: lastErrorMessage
        )
    }

    var isStarted: Bool { store != nil }

    /// Membuka tugas milik pengguna yang login.
    func start(userId: String, directory: URL = NotesStore.defaultDirectory) {
        store = TasksStore(userId: userId, directory: directory)
        lastErrorMessage = nil
        publish()
    }

    /// Dipanggil saat logout. Tugas tetap tersimpan di perangkat untuk login berikutnya.
    func stop() {
        store = nil
        lastErrorMessage = nil
        publish()
    }

    // MARK: - Perubahan di perangkat

    func task(id: UUID) -> TaskItem? {
        store?.task(id: id)
    }

    @discardableResult
    func save(id: UUID?, title: String, details: String, startAt: Date) -> TaskItem? {
        let task = store?.save(id: id, title: title, details: details, startAt: startAt)
        publish()
        return task
    }

    func setDone(id: UUID, _ done: Bool) {
        store?.setDone(id: id, done)
        publish()
    }

    func delete(id: UUID) {
        store?.delete(id: id)
        publish()
    }

    // MARK: - Sinkron

    /// Perangkat yang belum pernah sinkron dimuat sekali secara otomatis. Setelah itu sinkron
    /// hanya lewat tombol.
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

        let unsynced = store.unsyncedTasks
        let pushed = Dictionary(uniqueKeysWithValues: unsynced.map { ($0.id, $0.updatedAt) })
        do {
            // Gagalnya tampil di status sinkron, jadi tidak perlu toast.
            let response = try await handlingErrorsLocally {
                try await repository.sync(since: store.cursor, changes: unsynced)
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
        pendingTasks = store?.pendingTasks ?? []
        doneTasks = store?.doneTasks ?? []
        unsyncedCount = store?.unsyncedTasks.count ?? 0
        lastSyncedAt = store?.lastSyncedAt
        revision += 1
    }
}
