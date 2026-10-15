import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    /// Ringkasan terakhir dari server, disimpan di perangkat supaya dashboard tetap terisi
    /// saat server tidak terjangkau.
    private struct Cached: Codable {
        let summary: DashboardSummary
        let syncedAt: Date
    }

    let features = AppFeature.allCases
    private(set) var summary: DashboardSummary?
    private var ownStatus = SyncStatus()

    /// Status sinkron dashboard mencakup seluruh data aplikasi, termasuk catatan yang belum terkirim.
    var syncStatus: SyncStatus {
        var status = ownStatus
        status.pendingCount = NotesSyncService.shared.pendingCount + TasksSyncService.shared.unsyncedCount
            + KanbanSyncService.shared.unsyncedCount
        return status
    }

    private let repository = DashboardRepository()
    private let defaults = UserDefaults.standard
    private let cacheKey: String

    init(userId: String) {
        cacheKey = "dashboard.summary.\(userId)"
        if let data = defaults.data(forKey: cacheKey), let cached = try? JSONDecoder().decode(Cached.self, from: data) {
            summary = cached.summary
            ownStatus.lastSyncedAt = cached.syncedAt
        }
    }

    /// Perangkat yang belum punya ringkasan memuatnya sekali secara otomatis. Setelah itu
    /// sinkron hanya lewat tombol.
    func syncIfNeverSynced() async {
        guard summary == nil else { return }
        ownStatus.isSyncing = true
        defer { ownStatus.isSyncing = false }
        if await syncSummary() {
            ownStatus.lastSyncedAt = .now
        }
    }

    /// Sinkron seluruh data aplikasi: catatan, tugas, dan kerjaan beserta kartunya (kirim yang
    /// tersimpan di perangkat, terima yang baru), lalu ringkasan dashboard. Layar Catatan dan Kerjaan hanya menyinkronkan
    /// datanya masing-masing.
    func sync() async {
        guard !ownStatus.isSyncing else { return }
        ownStatus.isSyncing = true
        defer { ownStatus.isSyncing = false }

        // Data dikirim lebih dulu, supaya ringkasan dari server sudah menghitung yang baru dikirim.
        let notesSynced = await NotesSyncService.shared.sync()
        let tasksSynced = await TasksSyncService.shared.sync()
        let kanbanSynced = await KanbanSyncService.shared.sync()
        let summarySynced = await syncSummary()

        if notesSynced && tasksSynced && kanbanSynced && summarySynced {
            ownStatus.lastSyncedAt = .now
            ownStatus.errorMessage = nil
        } else {
            ownStatus.errorMessage = NotesSyncService.shared.lastErrorMessage
                ?? TasksSyncService.shared.lastErrorMessage
                ?? KanbanSyncService.shared.lastErrorMessage
                ?? "Sebagian data belum tersinkron."
        }
    }

    private func syncSummary() async -> Bool {
        do {
            // Gagalnya tampil di status sinkron, jadi tidak perlu toast.
            let fresh = try await handlingErrorsLocally { try await repository.summary() }
            summary = fresh
            defaults.set(try? JSONEncoder().encode(Cached(summary: fresh, syncedAt: .now)), forKey: cacheKey)
            return true
        } catch {
            return false
        }
    }

    func summaryText(for feature: AppFeature) -> String {
        guard let summary else {
            return syncStatus.isSyncing ? "Memuat..." : "Ringkasan belum tersedia"
        }
        switch feature {
        case .notes: return notesText(summary.notes)
        case .kanban: return kanbanText(summary.kanban)
        case .tasks: return tasksText(summary.tasks)
        }
    }

    func greeting(at date: Date = .now) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case 4..<11: "Selamat pagi"
        case 11..<15: "Selamat siang"
        case 15..<18: "Selamat sore"
        default: "Selamat malam"
        }
    }

    func initials(of fullName: String) -> String {
        fullName.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }

    private func notesText(_ notes: DashboardSummary.Notes) -> String {
        guard notes.total > 0 else { return "Belum ada catatan" }
        guard let latestTitle = notes.latestTitle else { return "\(notes.total) catatan" }
        return "\(notes.total) catatan · terakhir: \(latestTitle)"
    }

    private func tasksText(_ tasks: DashboardSummary.Tasks?) -> String {
        guard let tasks, tasks.pending > 0 else { return "Belum ada tugas" }
        guard let nextTitle = tasks.nextTitle else { return "\(tasks.pending) tugas" }
        return "\(tasks.pending) tugas · berikutnya: \(nextTitle)"
    }

    private func kanbanText(_ kanban: DashboardSummary.Kanban) -> String {
        guard kanban.todo + kanban.inProgress + kanban.done > 0 else { return "Belum ada kartu" }
        return "\(kanban.todo) belum · \(kanban.inProgress) dikerjakan · \(kanban.done) selesai"
    }
}
