import Foundation
import Observation

struct Toast: Identifiable, Equatable {
    enum Kind {
        case error
        case success
    }

    let id = UUID()
    let message: String
    let kind: Kind
}

/// Satu tempat untuk memunculkan toast error dari mana pun di aplikasi.
@MainActor
@Observable
final class ToastCenter {
    static let shared = ToastCenter()

    private(set) var current: Toast?
    private var dismissTask: Task<Void, Never>?
    private static let duration: Duration = .seconds(4)

    func show(_ message: String, kind: Toast.Kind = .error) {
        // Pesan yang sama sedang tampil: cukup perpanjang waktunya, jangan menumpuk.
        if current?.message != message || current?.kind != kind {
            current = Toast(message: message, kind: kind)
        }
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(for: Self.duration)
            guard !Task.isCancelled else { return }
            current = nil
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        current = nil
    }
}

/// Aturan toast untuk error dari server: muncul secara bawaan, kecuali layar menyatakan
/// menampilkan error-nya sendiri.
enum APIErrorPolicy {
    @TaskLocal static var isHandledLocally = false
}

/// Jalankan permintaan yang error-nya ditampilkan sendiri oleh layar (pesan di form, keadaan
/// kosong dengan tombol "Coba lagi", indikator simpan), sehingga tidak perlu toast.
/// Permintaan yang melewati batas waktu tetap memunculkan toast.
func handlingErrorsLocally<Result>(_ operation: () async throws -> Result) async rethrows -> Result {
    try await APIErrorPolicy.$isHandledLocally.withValue(true, operation: operation)
}
