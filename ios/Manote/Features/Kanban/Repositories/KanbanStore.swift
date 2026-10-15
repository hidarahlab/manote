import Foundation

/// Penyimpanan kerjaan dan kartu di perangkat, satu file per pengguna.
@MainActor
final class KanbanStore {
    private struct State: Codable {
        var boards: [Board] = []
        var cards: [Card] = []
        var cursor: String?
        var lastSyncedAt: Date?
    }

    private var state: State
    private let fileURL: URL

    init(userId: String, directory: URL = NotesStore.defaultDirectory) {
        fileURL = directory.appending(path: "kanban-\(userId).json")
        if let data = try? Data(contentsOf: fileURL), let saved = try? JSONDecoder().decode(State.self, from: data) {
            state = saved
        } else {
            state = State()
        }
    }

    // MARK: - Baca

    /// Kerjaan yang tampil, yang baru dipakai di atas.
    var visibleBoards: [Board] {
        state.boards.filter { !$0.isDeleted }.sorted { $0.updatedAt > $1.updatedAt }
    }

    /// Semua kartu yang tampil, urut per posisi.
    var visibleCards: [Card] {
        let deletedBoards = Set(state.boards.filter(\.isDeleted).map(\.id))
        return state.cards
            .filter { !$0.isDeleted && !deletedBoards.contains($0.boardId) }
            .sorted { ($0.position, $0.updatedAt) < ($1.position, $1.updatedAt) }
    }

    var unsyncedBoards: [Board] { state.boards.filter(\.isDirty) }

    var unsyncedCards: [Card] { state.cards.filter(\.isDirty) }

    var cursor: String? { state.cursor }

    var lastSyncedAt: Date? { state.lastSyncedAt }

    // MARK: - Ubah di perangkat

    @discardableResult
    func createBoard(name: String, now: Date = .now) -> Board {
        let board = Board(id: UUID(), serverId: nil, name: name, createdAt: now, updatedAt: now, isDirty: true)
        state.boards.append(board)
        persist()
        return board
    }

    /// Menandai kerjaan terhapus; kartunya ikut hilang. Barisnya dibuang setelah server diberi tahu.
    func deleteBoard(id: UUID, now: Date = .now) {
        guard let index = state.boards.firstIndex(where: { $0.id == id }) else { return }
        state.boards[index].isDeleted = true
        state.boards[index].updatedAt = now
        state.boards[index].isDirty = true
        persist()
    }

    /// Kartu baru ditaruh paling bawah kolomnya.
    @discardableResult
    func addCard(
        boardId: UUID, title: String, description: String, status: CardStatus, deadlineAt: Date?, now: Date = .now
    ) -> Card {
        let card = Card(
            id: UUID(), serverId: nil, boardId: boardId, title: title, description: description, status: status,
            position: bottomPosition(boardId: boardId, status: status), deadlineAt: deadlineAt,
            doneAt: status == .done ? now : nil, createdAt: now, updatedAt: now, isDirty: true
        )
        state.cards.append(card)
        touchBoard(boardId, now: now)
        persist()
        return card
    }

    func updateCard(id: UUID, title: String, description: String, deadlineAt: Date?, now: Date = .now) {
        changeCard(id, now: now) { card in
            card.title = title
            card.description = description
            card.deadlineAt = deadlineAt
        }
    }

    /// Memindahkan kartu ke paling bawah kolom tujuan.
    func moveCard(id: UUID, to status: CardStatus, now: Date = .now) {
        guard let card = state.cards.first(where: { $0.id == id }), card.status != status else { return }
        let position = bottomPosition(boardId: card.boardId, status: status)
        changeCard(id, now: now) { card in
            card.status = status
            card.position = position
            // Waktu selesai dicatat saat kartu masuk Done dan dihapus saat keluar lagi.
            card.doneAt = status == .done ? now : nil
        }
    }

    func deleteCard(id: UUID, now: Date = .now) {
        changeCard(id, now: now) { $0.isDeleted = true }
    }

    private func changeCard(_ id: UUID, now: Date, _ change: (inout Card) -> Void) {
        guard let index = state.cards.firstIndex(where: { $0.id == id }) else { return }
        change(&state.cards[index])
        state.cards[index].updatedAt = now
        state.cards[index].isDirty = true
        touchBoard(state.cards[index].boardId, now: now)
        persist()
    }

    /// Kerjaan yang baru dipakai naik ke atas daftar.
    private func touchBoard(_ id: UUID, now: Date) {
        guard let index = state.boards.firstIndex(where: { $0.id == id }) else { return }
        state.boards[index].updatedAt = now
        state.boards[index].isDirty = true
    }

    private func bottomPosition(boardId: UUID, status: CardStatus) -> Int {
        let positions = state.cards
            .filter { $0.boardId == boardId && $0.status == status && !$0.isDeleted }
            .map(\.position)
        return (positions.max() ?? -1) + 1
    }

    // MARK: - Terapkan hasil sinkron

    /// - Parameters:
    ///   - pushedBoards: kerjaan yang dikirim pada sinkron ini, dengan waktu ubahnya saat dikirim.
    ///   - pushedCards: kartu yang dikirim pada sinkron ini, dengan waktu ubahnya saat dikirim.
    func apply(_ response: KanbanSyncResponse, pushedBoards: [UUID: Date], pushedCards: [UUID: Date], now: Date = .now) {
        for serverBoard in response.boards {
            let index = state.boards.firstIndex { $0.id == serverBoard.clientId }
            // Diubah lagi di perangkat setelah dikirim: versi perangkat dipertahankan.
            if let index, state.boards[index].isDirty,
               state.boards[index].updatedAt > (pushedBoards[serverBoard.clientId] ?? .distantPast) {
                state.boards[index].serverId = serverBoard.id
                continue
            }
            if serverBoard.deleted {
                if let index { state.boards.remove(at: index) }
                state.cards.removeAll { $0.boardId == serverBoard.clientId }
                continue
            }
            let board = Board(
                id: serverBoard.clientId, serverId: serverBoard.id, name: serverBoard.name,
                createdAt: serverBoard.createdAt, updatedAt: serverBoard.updatedAt
            )
            if let index {
                state.boards[index] = board
            } else {
                state.boards.append(board)
            }
        }

        for serverCard in response.cards {
            let index = state.cards.firstIndex { $0.id == serverCard.clientId }
            if let index, state.cards[index].isDirty,
               state.cards[index].updatedAt > (pushedCards[serverCard.clientId] ?? .distantPast) {
                state.cards[index].serverId = serverCard.id
                continue
            }
            if serverCard.deleted {
                if let index { state.cards.remove(at: index) }
                continue
            }
            let card = Card(
                id: serverCard.clientId, serverId: serverCard.id, boardId: serverCard.boardClientId,
                title: serverCard.title, description: serverCard.description, status: serverCard.status,
                position: serverCard.position, deadlineAt: serverCard.deadlineAt, doneAt: serverCard.doneAt,
                createdAt: serverCard.createdAt, updatedAt: serverCard.updatedAt
            )
            if let index {
                state.cards[index] = card
            } else {
                state.cards.append(card)
            }
        }

        // Tanda terhapus yang sudah dikirim tidak perlu disimpan lagi, begitu juga kartu milik
        // kerjaan yang sudah tidak ada.
        let removedBoards = Set(state.boards.filter { $0.isDeleted && pushedBoards[$0.id] == $0.updatedAt }.map(\.id))
        state.boards.removeAll { removedBoards.contains($0.id) }
        let boardIds = Set(state.boards.map(\.id))
        state.cards.removeAll { card in
            !boardIds.contains(card.boardId) || (card.isDeleted && pushedCards[card.id] == card.updatedAt)
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
            assertionFailure("Gagal menyimpan kerjaan ke perangkat: \(error)")
        }
    }
}
