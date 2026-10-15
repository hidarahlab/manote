import Foundation

/// Ringkasan data Manote untuk widget layar utama. Aplikasi menulisnya setiap data berubah,
/// dan widget membacanya, lewat penyimpanan bersama (App Group).
struct WidgetSnapshot: Codable, Equatable {
    static let appGroup = "group.com.hidarahlab.manote"
    static let widgetKind = "ManoteWidget"
    private static let storageKey = "widget.snapshot"

    /// Tugas belum selesai dengan waktu mulai paling awal.
    var nextTaskTitle: String?
    var nextTaskStart: Date?
    var pendingTasks = 0
    var notes = 0
    /// Kartu kerjaan yang belum sampai Done.
    var openCards = 0
    /// Kartu kerjaan yang tenggatnya tinggal 1 hari atau sudah lewat.
    var urgentCards = 0
    /// `false` berarti belum ada pengguna yang login di perangkat ini.
    var isLoggedIn = false

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    static func load() -> WidgetSnapshot {
        guard let data = defaults?.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return WidgetSnapshot()
        }
        return snapshot
    }

    /// Mengembalikan `false` jika tidak ada yang berubah, supaya widget tidak dimuat ulang sia-sia.
    @discardableResult
    func save() -> Bool {
        guard self != Self.load(), let data = try? JSONEncoder().encode(self) else { return false }
        Self.defaults?.set(data, forKey: Self.storageKey)
        return true
    }
}
