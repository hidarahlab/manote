import Foundation
import Observation

@MainActor
@Observable
final class BoardViewModel {
    let boardId: UUID

    private let sync = KanbanSyncService.shared

    init(board: Board) {
        boardId = board.id
    }

    var name: String? { sync.board(id: boardId)?.name }

    var syncStatus: SyncStatus { sync.status }

    func cards(in status: CardStatus) -> [Card] {
        sync.cards(in: boardId, status: status)
    }

    /// Sinkron khusus kerjaan: kirim kerjaan dan kartu yang tertunda, terima yang baru.
    func syncNow() async {
        await sync.sync()
    }

    // Semua perubahan langsung tersimpan di perangkat dan terkirim saat sinkron berikutnya.

    @discardableResult
    func addCard(title: String, to status: CardStatus) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        return sync.addCard(boardId: boardId, title: trimmed, status: status) != nil
    }

    func update(_ card: Card, title: String, description: String, deadlineAt: Date?) {
        sync.updateCard(id: card.id, title: title, description: description, deadlineAt: deadlineAt)
    }

    /// Memindahkan kartu ke paling bawah kolom tujuan.
    func move(_ card: Card, to status: CardStatus) {
        sync.moveCard(id: card.id, to: status)
    }

    func delete(_ card: Card) {
        sync.deleteCard(id: card.id)
    }
}
