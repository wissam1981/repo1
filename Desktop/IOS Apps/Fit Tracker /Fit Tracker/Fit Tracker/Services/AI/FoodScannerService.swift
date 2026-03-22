@preconcurrency import Foundation
import UIKit
import FirebaseFunctions

// MARK: - Food Scanner Service
// Proxies food photo analysis through Firebase Cloud Functions (no API keys in client).

actor FoodScannerService {

    static let shared = FoodScannerService()

    private let functions = Functions.functions()

    private init() {}

    // MARK: - Analyze Food Photo

    func analyzePhoto(_ image: UIImage) async throws -> [ScannedFoodItem] {
        guard let jpegData = image.jpegData(compressionQuality: 0.6) else {
            throw FoodScannerError.invalidImage
        }

        let base64 = jpegData.base64EncodedString()

        let systemPrompt = """
        You are a precise, professional food nutrition analyzer.
        First, analyze the image step-by-step. Identify the scale of the plate or bowl, observe the textures, and estimate the actual gram weight of each distinct visible food based on realistic portion sizes.
        
        CRITICAL: If the image contains a mixed plate (e.g., chicken, rice, AND broccoli), you MUST return them as separate objects in the JSON array, NOT as a single combined meal. Break down every distinct ingredient/food item you see.

        After your brief analysis, you MUST provide the final nutritional estimates in a JSON block wrapped in ```json and ``` markers.
        The JSON must be an array of objects. Each object must have these exact keys:
        [
          {
            "name": "Distinct Food Name",
            "serving_size_g": 150,
            "calories": 250,
            "protein_g": 20,
            "carbs_g": 30,
            "fat_g": 8,
            "fiber_g": 3
          }
        ]

        Take note: be realistic. If you see a slice of pizza, estimate the weight of that specific slice. If there's a side of rice, estimate the cup size. Your output must end with the JSON array.
        """

        let userPrompt = "Identify all the foods in this photo and estimate their nutritional values."

        let result = try await functions.httpsCallable("openaiVision").call([
            "imageBase64": base64,
            "systemPrompt": systemPrompt,
            "userPrompt": userPrompt
        ])

        guard let data = result.data as? [String: Any],
              let content = data["content"] as? String else {
            throw FoodScannerError.parsingError
        }

        // Extract the JSON block if the model provided reasoning before it
        let cleaned: String
        if let jsonStart = content.range(of: "```json\n") {
            let afterStart = content[jsonStart.upperBound...]
            if let jsonEnd = afterStart.range(of: "```") {
                cleaned = String(afterStart[..<jsonEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                cleaned = String(afterStart).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else if let arrayStart = content.firstIndex(of: "["), let arrayEnd = content.lastIndex(of: "]") {
            cleaned = String(content[arrayStart...arrayEnd])
        } else {
            cleaned = content
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let foodData = cleaned.data(using: .utf8) else {
            throw FoodScannerError.parsingError
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let scannedFoods = try decoder.decode([ScannedFoodItem].self, from: foodData)
        return scannedFoods
    }
}

// MARK: - Scanned Food Item

struct ScannedFoodItem: Codable, Identifiable, Sendable {
    var id: String { name + String(calories) }
    let name: String
    let servingSizeG: Double
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let fiberG: Double?

    /// Convert to the app's standard FoodItem model
    func toFoodItem() -> FoodItem {
        FoodItem(
            id: "scan_\(UUID().uuidString.prefix(8))",
            name: name,
            brandName: "AI Scan",
            barcode: nil,
            fdcId: nil,
            servingSizeG: servingSizeG,
            servingUnit: "g",
            calories: calories,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            fiberG: fiberG ?? 0,
            sugarG: nil,
            sodiumMg: nil,
            isVerified: false,
            isCustom: true,
            source: .custom
        )
    }
}

// MARK: - Scan Usage Tracker
/// Tracks daily AI scan usage in UserDefaults. Resets at midnight.

struct ScanUsageTracker {

    static let freeDailyLimit = 3

    private static let countKey = "ai_scan_count"
    private static let dateKey  = "ai_scan_date"

    // MARK: - Public API

    /// Whether the user can perform another scan.
    static func canScan(isPremium: Bool) -> Bool {
        if isPremium { return true }
        resetIfNewDay()
        return currentCount() < freeDailyLimit
    }

    /// Number of scans remaining today (for display). Returns `nil` for premium users.
    static func scansRemaining(isPremium: Bool) -> Int? {
        if isPremium { return nil }
        resetIfNewDay()
        return max(0, freeDailyLimit - currentCount())
    }

    /// Record a completed scan.
    static func recordScan() {
        resetIfNewDay()
        UserDefaults.standard.set(currentCount() + 1, forKey: countKey)
    }

    // MARK: - Internals

    private static func currentCount() -> Int {
        UserDefaults.standard.integer(forKey: countKey)
    }

    private static func resetIfNewDay() {
        let today = Calendar.current.startOfDay(for: .now)
        let stored = UserDefaults.standard.object(forKey: dateKey) as? Date ?? .distantPast
        if !Calendar.current.isDate(stored, inSameDayAs: today) {
            UserDefaults.standard.set(0, forKey: countKey)
            UserDefaults.standard.set(today, forKey: dateKey)
        }
    }
}

// MARK: - Barcode Scan Usage Tracker
/// Tracks barcode scan usage during the 7-day trial. Trial users get 3 total barcode scans.

struct BarcodeScanUsageTracker {

    static let trialLimit = 3

    private static let countKey = "barcode_scan_count"

    // MARK: - Public API

    /// Whether the user can perform another barcode scan.
    static func canScan(isPremium: Bool) -> Bool {
        if isPremium { return true }
        return currentCount() < trialLimit
    }

    /// Number of barcode scans remaining (for display). Returns `nil` for premium users.
    static func scansRemaining(isPremium: Bool) -> Int? {
        if isPremium { return nil }
        return max(0, trialLimit - currentCount())
    }

    /// Record a completed barcode scan.
    static func recordScan() {
        UserDefaults.standard.set(currentCount() + 1, forKey: countKey)
    }

    // MARK: - Internals

    private static func currentCount() -> Int {
        UserDefaults.standard.integer(forKey: countKey)
    }
}

// MARK: - Errors

enum FoodScannerError: LocalizedError {
    case invalidImage
    case networkError(String)
    case parsingError
    case scanLimitReached

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Could not process the image."
        case .networkError(let msg): return "Network error: \(msg)"
        case .parsingError: return "Could not understand the AI response."
        case .scanLimitReached: return "Daily scan limit reached. Upgrade to Premium for unlimited scans."
        }
    }
}
