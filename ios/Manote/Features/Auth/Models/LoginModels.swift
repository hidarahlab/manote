import Foundation

struct LoginRequest: Encodable {
    let username: String
    let password: String
}

struct LoginResponse: Decodable {
    let accessToken: String
    let expiresIn: Int
    let user: User
}
