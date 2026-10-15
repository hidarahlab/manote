import Foundation

/// Kode di field `code` response API. Kode khusus Manote memakai kode HTTP induknya
/// ditambah satu digit urut, misalnya 4011 dan 4012 adalah turunan 401.
enum APICode {
    /// Bukan dari server: permintaan tidak sampai atau jawabannya tidak dikenali.
    static let unreachable = 0
    static let ok = 200
    static let created = 201
    static let badRequest = 400
    static let validationFailed = 4001
    static let unauthenticated = 401
    static let invalidCredentials = 4011
    static let tokenInvalid = 4012
    static let forbidden = 403
    static let notFound = 404
    static let tooManyRequests = 429
    static let loginLocked = 4291
    static let internalError = 500
}

struct APIError: LocalizedError, Equatable {
    let code: Int
    let message: String

    var errorDescription: String? { message }

    /// Belum login, atau sesi sudah tidak berlaku.
    var isUnauthorized: Bool {
        code == APICode.unauthenticated || code == APICode.tokenInvalid
    }

    var isUnreachable: Bool { code == APICode.unreachable }

    static let unreachable = APIError(
        code: APICode.unreachable,
        message: "Server tidak terjangkau. Periksa koneksi Anda."
    )

    static let timedOut = APIError(
        code: APICode.unreachable,
        message: "Server terlalu lama merespons. Coba lagi."
    )

    static let unrecognizedResponse = APIError(
        code: APICode.unreachable,
        message: "Server sedang tidak bisa dihubungi. Coba lagi nanti."
    )
}

extension Notification.Name {
    /// Dikirim saat server menolak token yang tersimpan, supaya aplikasi kembali ke layar login.
    static let manoteSessionExpired = Notification.Name("manoteSessionExpired")
}
