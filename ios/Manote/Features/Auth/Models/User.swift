import Foundation

struct User: Codable, Equatable {
    let userId: String
    let email: String
    let fullName: String
    let userType: String
}
