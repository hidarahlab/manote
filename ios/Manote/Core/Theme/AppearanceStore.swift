import Observation
import SwiftUI

/// Tema aplikasi pilihan pengguna.
enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: "Terang"
        case .dark: "Gelap"
        }
    }

    var systemImage: String {
        switch self {
        case .light: "sun.max"
        case .dark: "moon"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Menyimpan tema pilihan di perangkat. Selama belum pernah dipilih, aplikasi mengikuti tema iPhone.
@MainActor
@Observable
final class AppearanceStore {
    static let shared = AppearanceStore()

    private static let key = "settings.theme"
    private let defaults = UserDefaults.standard

    /// `nil` berarti belum pernah dipilih.
    var theme: AppTheme? {
        didSet { defaults.set(theme?.rawValue, forKey: Self.key) }
    }

    private init() {
        theme = defaults.string(forKey: Self.key).flatMap(AppTheme.init(rawValue:))
    }
}
