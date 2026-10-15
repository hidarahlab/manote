import Foundation
import Observation

/// Sumber kerjaan dan kartu untuk semua layar. Perubahan langsung tersimpan di perangkat, jadi
/// kerjaan bisa dibuat dan kartu bisa dipindah tanpa server. Sinkron dengan server (kirim yang
/// tertunda, terima keadaan terbaru) hanya berjalan saat diminta pengguna.
@MainActor
@Observable
final class KanbanSyncService {
    static let shared = KanbanSyncService()

    private(set) var boards: [Board] = []
    private(set) var cards: [Card] = []
    private(set) var isSyncing = false
    private(set) var unsyncedCount = 0
    private(set) var lastSyncedAt: Date?
    /// Sebab sinkron terakhir gagal; `nil` jika berhasil.
    private(set) var lastErrorMessage: String?

    private var store: KanbanStore?
    private let repository: KanbanRepository

    init(repository: KanbanRepository = KanbanRepository()) {
        self.repository = repository
    }

    var status: SyncStatus {
        SyncStatus(
            isSyncing: isSyncing, pendingCount: unsyncedCount,
            lastSyncedAt: lastSyncedAt, errorMessage: lastErrorMessage
        )
    }

    /// Membuka kerjaan milik pengguna yang login.
    func start(userId: String, directory: URL = NotesStore.defaultDirectory) {
        store = KanbanStore(userId: userId, directory: directory)
        lastErrorMessage = nil
        publish()
    }

    /// Dipanggil saat logout. Kerjaan tetap tersimpan di perangkat untuk login berikutnya.
    func stop() {
        store = nil
        lastErrorMessage = nil
        publish()
    }

    // MARK: - Baca

    func board(id: UUID) -> Board? {
        boards.first { $0.id == id }
    }

    func cards(in boardId: UUID, status: CardStatus? = nil) -> [Card] {
        cards.filter { $0.boardId == boardId && (status == nil || $0.status == status) }
    }

    func progressText(for board: Board) -> String {
        let boardCards = cards(in: board.id)
        guard !boardCards.isEmpty else { return "Belum ada kartu" }
        let done = boardCards.filter { $0.status == .done }.count
        return "\(done) dari \(boardCards.count) kartu selesai"
    }

    // MARK: - Perubahan di perangkat

    @discardableResult
    func createBoard(name: String) -> Board? {
        let board = store?.createBoard(name: name)
        publish()
        return board
    }

    func deleteBoard(id: UUID) {
        store?.deleteBoard(id: id)
        publish()
    }

    @discardableResult
    func addCard(
        boardId: UUID, title: String, description: String = "", status: CardStatus = .backlog, deadlineAt: Date? = nil
    ) -> Card? {
        let card = store?.addCard(
            boardId: boardId, title: title, description: description, status: status, deadlineAt: deadlineAt
        )
        publish()
        return card
    }

    func updateCard(id: UUID, title: String, description: String, deadlineAt: Date?) {
        store?.updateCard(id: id, title: title, description: description, deadlineAt: deadlineAt)
        publish()
    }

    func moveCard(id: UUID, to status: CardStatus) {
        store?.moveCard(id: id, to: status)
        publish()
    }

    func deleteCard(id: UUID) {
        store?.deleteCard(id: id)
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

        let unsyncedBoards = store.unsyncedBoards
        let unsyncedCards = store.unsyncedCards
        let pushedBoards = Dictionary(uniqueKeysWithValues: unsyncedBoards.map { ($0.id, $0.updatedAt) })
        let pushedCards = Dictionary(uniqueKeysWithValues: unsyncedCards.map { ($0.id, $0.updatedAt) })
        do {
            // Gagalnya tampil di status sinkron, jadi tidak perlu toast.
            let response = try await handlingErrorsLocally {
                try await repository.sync(since: store.cursor, boards: unsyncedBoards, cards: unsyncedCards)
            }
            // Pengguna bisa saja logout atau berganti akun selagi menunggu.
            guard self.store === store else { return false }
            store.apply(response, pushedBoards: pushedBoards, pushedCards: pushedCards)
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
        boards = store?.visibleBoards ?? []
        cards = store?.visibleCards ?? []
        unsyncedCount = (store?.unsyncedBoards.count ?? 0) + (store?.unsyncedCards.count ?? 0)
        lastSyncedAt = store?.lastSyncedAt
    }
}
