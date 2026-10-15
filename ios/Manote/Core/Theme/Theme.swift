import SwiftUI
import UIKit

extension Color {
    /// Warna yang otomatis berganti antara mode terang dan gelap.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// Tema "Meja Kerja": satu warna tinta (ungu) dan satu warna kertas per fitur.
enum Theme {
    enum Colors {
        static let primary = Color(light: 0x534AB7, dark: 0xAFA9EC)
        static let onPrimary = Color(light: 0xFFFFFF, dark: 0x26215C)
        static let primarySoft = Color(light: 0xEEEDFE, dark: 0x3C3489)
        static let onPrimarySoft = Color(light: 0x3C3489, dark: 0xCECBF6)

        static let background = Color(light: 0xFBFAF8, dark: 0x121214)
        static let surface = Color(light: 0xF1EFE8, dark: 0x232326)
        static let danger = Color(light: 0xA32D2D, dark: 0xF09595)
    }

    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
    }

    enum Radius {
        static let field: CGFloat = 14
        static let card: CGFloat = 20
    }

    enum Fonts {
        static let brand = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title = Font.system(.title2, design: .rounded).weight(.semibold)
        static let cardTitle = Font.system(.headline, design: .rounded)
    }
}
