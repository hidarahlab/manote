import SwiftUI

/// Fitur utama Manote beserta warna kertasnya.
enum AppFeature: String, CaseIterable, Identifiable {
    case notes
    case kanban
    case tasks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notes: "Catatan"
        case .kanban: "Kerjaan"
        case .tasks: "Tugas"
        }
    }

    var systemImage: String {
        switch self {
        case .notes: "note.text"
        case .kanban: "rectangle.split.3x1"
        case .tasks: "alarm"
        }
    }

    var background: Color {
        switch self {
        case .notes: Color(light: 0xFAEEDA, dark: 0x412402)
        case .kanban: Color(light: 0xE1F5EE, dark: 0x04342C)
        case .tasks: Color(light: 0xE6F1FB, dark: 0x042C53)
        }
    }

    var titleColor: Color {
        switch self {
        case .notes: Color(light: 0x633806, dark: 0xFAC775)
        case .kanban: Color(light: 0x085041, dark: 0x9FE1CB)
        case .tasks: Color(light: 0x0C447C, dark: 0xB5D4F4)
        }
    }

    var subtitleColor: Color {
        switch self {
        case .notes: Color(light: 0x854F0B, dark: 0xEF9F27)
        case .kanban: Color(light: 0x0F6E56, dark: 0x5DCAA5)
        case .tasks: Color(light: 0x185FA5, dark: 0x85B7EB)
        }
    }
}
