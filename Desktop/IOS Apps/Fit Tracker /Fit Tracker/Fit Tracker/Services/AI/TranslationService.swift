@preconcurrency import Foundation
import FirebaseFunctions

// MARK: - Translation Service
// Proxies translation requests through Firebase Cloud Functions (no API keys in client).

actor TranslationService {

    private let functions = Functions.functions()

    init() {}

    // MARK: - Core Translation

    /// Translates a single search query from Arabic to an English keyword (or vice versa if needed)
    func translate(query: String, to language: String) async throws -> String {
        let result = try await functions.httpsCallable("openaiTranslate").call([
            "query": query,
            "targetLanguage": language
        ])

        guard let data = result.data as? [String: Any],
              let content = data["content"] as? String else {
            throw TranslationError.parsingError
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // A quick check to see if a string contains Arabic characters
    static func containsArabic(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if CharacterSet(charactersIn: "\u{0600}"..."\u{06FF}").contains(scalar) {
                return true
            }
        }
        return false
    }
}

// MARK: - Errors

enum TranslationError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case networkError
    case parsingError
}
