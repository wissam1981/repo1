import SwiftUI

// MARK: - App Theme
// Defines the available color themes for the app.

enum AppTheme: String, CaseIterable, Identifiable {
    case neonGreen = "Neon Green"
    case oceanBlue = "Ocean Blue"
    case sunsetOrange = "Sunset Orange"
    case ironPulse = "Iron Pulse"
    case cleanWhite = "Clean White"

    var id: String { rawValue }

    var isLightTheme: Bool {
        switch self {
        case .cleanWhite: return true
        default: return false
        }
    }
}

// MARK: - Theme Manager
// Singleton to manage the current theme and broadcast changes.

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    // Using @ObservationIgnored because we manually sync it with UserDefaults
    @ObservationIgnored
    private let defaults = UserDefaults.standard

    // The key used to store the theme in UserDefaults (matches @AppStorage)
    private let themeKey = "appTheme"

    var currentTheme: AppTheme {
        get {
            let savedValue = defaults.string(forKey: themeKey) ?? AppTheme.oceanBlue.rawValue
            return AppTheme(rawValue: savedValue) ?? .oceanBlue
        }
        set {
            defaults.set(newValue.rawValue, forKey: themeKey)
        }
    }

    private init() {}
}
