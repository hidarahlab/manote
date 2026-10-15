import Observation
import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    private let appearance = AppearanceStore.shared

    /// Tema yang ditandai terpilih: pilihan pengguna, atau tema iPhone jika belum pernah memilih.
    func selectedTheme(system: ColorScheme) -> AppTheme {
        appearance.theme ?? (system == .dark ? .dark : .light)
    }

    func select(_ theme: AppTheme) {
        appearance.theme = theme
    }
}
