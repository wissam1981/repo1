import SwiftUI
import Observation

// MARK: - App Language

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case arabic = "ar"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .arabic: return "العربية"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .arabic: return "🇸🇦"
        }
    }
}

// MARK: - Language Manager

@Observable
final class LanguageManager {
    static let shared = LanguageManager()

    @ObservationIgnored
    private let defaults = UserDefaults.standard

    private let languageKey = "appLanguage"

    var currentLanguage: AppLanguage {
        get {
            let saved = defaults.string(forKey: languageKey) ?? AppLanguage.english.rawValue
            return AppLanguage(rawValue: saved) ?? .english
        }
        set {
            defaults.set(newValue.rawValue, forKey: languageKey)
        }
    }

    var locale: Locale { Locale(identifier: currentLanguage.rawValue) }

    var layoutDirection: LayoutDirection {
        currentLanguage == .arabic ? .rightToLeft : .leftToRight
    }

    var isArabic: Bool { currentLanguage == .arabic }

    private init() {}
}
