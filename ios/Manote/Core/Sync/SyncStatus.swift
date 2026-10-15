import Foundation

/// Keadaan sinkron satu layar (dashboard, catatan, atau kerjaan), untuk ditampilkan.
struct SyncStatus: Equatable {
    var isSyncing = false
    var pendingCount = 0
    var lastSyncedAt: Date?
    var errorMessage: String?

    var text: String {
        if isSyncing { return "Menyinkronkan…" }
        if pendingCount > 0 { return "\(pendingCount) perubahan belum tersinkron" }
        if errorMessage != nil { return "Belum tersinkron" }
        guard let lastSyncedAt else { return "Belum pernah sinkron" }
        return "Tersinkron \(Self.timeText(lastSyncedAt))"
    }

    var needsAttention: Bool {
        !isSyncing && (pendingCount > 0 || errorMessage != nil)
    }

    private static func timeText(_ date: Date, now: Date = .now) -> String {
        let locale = Locale(identifier: "id_ID")
        if Calendar.current.isDate(date, inSameDayAs: now) {
            return date.formatted(.dateTime.hour().minute().locale(locale))
        }
        return date.formatted(.dateTime.day().month(.abbreviated).hour().minute().locale(locale))
    }
}
