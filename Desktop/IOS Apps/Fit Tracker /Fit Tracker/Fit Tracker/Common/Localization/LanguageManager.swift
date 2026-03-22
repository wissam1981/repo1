import SwiftUI
import Observation
import ObjectiveC

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

// MARK: - Bundle Swizzling for In-App Language Switching

/// Overrides Bundle.main's string lookup to use the selected language's .lproj,
/// so that `String(localized:)` in ViewModels picks up the correct translation
/// without relying on SwiftUI's environment locale.
private var associatedBundleKey: UInt8 = 0

private final class LocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let path = objc_getAssociatedObject(Bundle.main, &associatedBundleKey) as? String,
              let bundle = Bundle(path: path) else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    /// Swizzle Bundle.main so all localized-string lookups route through the
    /// selected language's .lproj directory.
    static func setLanguage(_ language: String) {
        object_setClass(Bundle.main, LocalizedBundle.self)

        if let path = Bundle.main.path(forResource: language, ofType: "lproj") {
            objc_setAssociatedObject(Bundle.main, &associatedBundleKey, path, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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

    /// Stored property so @Observable can track changes and notify SwiftUI.
    var currentLanguage: AppLanguage {
        didSet {
            defaults.set(currentLanguage.rawValue, forKey: languageKey)
            Bundle.setLanguage(currentLanguage.rawValue)
        }
    }

    var locale: Locale { Locale(identifier: currentLanguage.rawValue) }

    var layoutDirection: LayoutDirection {
        currentLanguage == .arabic ? .rightToLeft : .leftToRight
    }

    var isArabic: Bool { currentLanguage == .arabic }

    private init() {
        let saved = defaults.string(forKey: languageKey) ?? AppLanguage.english.rawValue
        self.currentLanguage = AppLanguage(rawValue: saved) ?? .english
        // Apply bundle swizzle on init so the first render uses the correct language
        Bundle.setLanguage(currentLanguage.rawValue)
    }
}
