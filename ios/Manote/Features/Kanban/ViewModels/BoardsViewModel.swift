import Foundation
import Observation

@MainActor
@Observable
final class BoardsViewModel {
    var newBoardName = ""

    private let sync = KanbanSyncService.shared

    /// Dibaca dari perangkat, jadi langsung tampil tanpa menunggu server.
    var boards: [Board] { sync.boards }

    var syncStatus: SyncStatus { sync.status }

    /// Daftar kosong dan belum pernah sinkron: belum tentu berarti tidak ada kerjaan.
    var isLoadingFirstSync: Bool {
        boards.isEmpty && sync.lastSyncedAt == nil && sync.isSyncing
    }

    func progressText(for board: Board) -> String {
        sync.progressText(for: board)
    }

    func cardCount(for board: Board) -> Int {
        sync.cards(in: board.id).count
    }

    func syncIfNeverSynced() async {
        await sync.syncIfNeverSynced()
    }

    /// Sinkron khusus kerjaan: kirim kerjaan dan kartu yang tertunda, terima yang baru.
    func syncNow() async {
        await sync.sync()
    }

    func create() {
        let name = newBoardName.trimmingCharacters(in: .whitespaces)
        newBoardName = ""
        guard !name.isEmpty else {
            ToastCenter.shared.show("Nama kerjaan wajib diisi.")
            return
        }
        sync.createBoard(name: name)
    }

    func delete(_ board: Board) {
        sync.deleteBoard(id: board.id)
    }
}
