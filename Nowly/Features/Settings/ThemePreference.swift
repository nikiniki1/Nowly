import SwiftUI

enum ThemePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "themePreference"

    var id: Self { self }

    var title: String {
        switch self {
        case .system: String(localized: "Системная")
        case .light: String(localized: "Светлая")
        case .dark: String(localized: "Тёмная")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
