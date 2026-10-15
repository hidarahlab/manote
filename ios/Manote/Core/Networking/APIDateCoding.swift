import Foundation

/// Waktu di API memakai ISO 8601 (UTC), dengan atau tanpa pecahan detik.
enum APIDateCoding {
    static func string(from date: Date) -> String {
        formatter(fractional: true).string(from: date)
    }

    static func date(from string: String) -> Date? {
        formatter(fractional: true).date(from: string) ?? formatter(fractional: false).date(from: string)
    }

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(string(from: date))
        }
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            guard let date = date(from: value) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Waktu tidak dikenali: \(value)")
            }
            return date
        }
        return decoder
    }()

    private static func formatter(fractional: Bool) -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = fractional ? [.withInternetDateTime, .withFractionalSeconds] : [.withInternetDateTime]
        return formatter
    }
}
