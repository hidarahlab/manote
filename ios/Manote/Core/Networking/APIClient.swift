import Foundation

/// Bentuk semua response API, sukses maupun gagal.
private struct APIEnvelope<Payload: Decodable>: Decodable {
    let status: Bool
    let title: String
    let code: Int
    let data: Payload?
}

/// Untuk response sukses yang `data`-nya kosong, misalnya setelah menghapus.
private struct NoData: Decodable {}

struct APIClient {
    /// Batas waktu menunggu server sebelum permintaan dianggap gagal.
    static let requestTimeout: TimeInterval = 30

    private static let defaultSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = requestTimeout
        configuration.timeoutIntervalForResource = requestTimeout * 2
        return URLSession(configuration: configuration)
    }()

    var baseURL = APIConfig.baseURL
    var session: URLSession = APIClient.defaultSession
    var tokenStore = TokenStore()

    func get<Response: Decodable>(_ path: String) async throws -> Response {
        try await send(makeRequest(path, method: "GET"))
    }

    /// `authenticated: false` untuk endpoint publik seperti login, supaya token lama tidak ikut terkirim.
    func post<Body: Encodable, Response: Decodable>(
        _ path: String,
        body: Body,
        authenticated: Bool = true
    ) async throws -> Response {
        var request = makeRequest(path, method: "POST", authenticated: authenticated)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try APIDateCoding.encoder.encode(body)
        return try await send(request)
    }

    func put<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        var request = makeRequest(path, method: "PUT")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try APIDateCoding.encoder.encode(body)
        return try await send(request)
    }

    func delete(_ path: String) async throws {
        let _: APIEnvelope<NoData> = try await perform(makeRequest(path, method: "DELETE"))
    }

    private func makeRequest(_ path: String, method: String, authenticated: Bool = true) -> URLRequest {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if authenticated, let token = tokenStore.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let envelope: APIEnvelope<Response> = try await perform(request)
        guard let data = envelope.data else { throw APIError.unrecognizedResponse }
        return data
    }

    /// Mengirim permintaan dan membuka bungkus response. Melempar `APIError` untuk semua kegagalan.
    private func perform<Payload: Decodable>(_ request: URLRequest) async throws -> APIEnvelope<Payload> {
        let body: Data
        do {
            (body, _) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as URLError where error.code == .timedOut {
            // Melewati batas waktu selalu memunculkan toast, di layar mana pun.
            Self.showToast(for: .timedOut)
            throw APIError.timedOut
        } catch {
            throw report(.unreachable)
        }

        // Gagal dibaca berarti jawabannya bukan dari backend Manote, atau `data`-nya tidak sesuai.
        guard let envelope = try? APIDateCoding.decoder.decode(APIEnvelope<Payload>.self, from: body) else {
            if let failure = try? APIDateCoding.decoder.decode(APIEnvelope<NoData>.self, from: body), !failure.status {
                throw handle(APIError(code: failure.code, message: failure.title), for: request)
            }
            throw report(.unrecognizedResponse)
        }

        guard envelope.status else {
            throw handle(APIError(code: envelope.code, message: envelope.title), for: request)
        }
        return envelope
    }

    private func handle(_ error: APIError, for request: URLRequest) -> APIError {
        // Sesi tidak berlaku lagi: buang token dan kabari aplikasi supaya kembali ke login.
        // Layar login menampilkan pesannya, jadi tidak perlu toast.
        if error.isUnauthorized, request.value(forHTTPHeaderField: "Authorization") != nil {
            tokenStore.clear()
            NotificationCenter.default.post(name: .manoteSessionExpired, object: nil)
            return error
        }
        return report(error)
    }

    /// Error memunculkan toast secara bawaan, kecuali layar menampilkannya sendiri
    /// (lihat `handlingErrorsLocally`).
    private func report(_ error: APIError) -> APIError {
        if !APIErrorPolicy.isHandledLocally {
            Self.showToast(for: error)
        }
        return error
    }

    private static func showToast(for error: APIError) {
        Task { @MainActor in
            ToastCenter.shared.show(error.message)
        }
    }
}
