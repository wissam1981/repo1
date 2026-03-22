@preconcurrency import Foundation
import FirebaseFunctions
import FirebaseAuth

// MARK: - AI Coach Service
// Proxies chat requests through Firebase Cloud Functions (no API keys in client).

actor AICoachService {

    private let functions = Functions.functions()

    init() {}

    /// Ensure Firebase Auth token is fresh before calling Cloud Functions
    private func ensureAuth() async throws {
        guard let user = Auth.auth().currentUser else {
            print("❌ [AICoach] No Firebase Auth user — user may be in guest mode")
            throw AICoachError.networkError("Sign in required to use AI Coach.")
        }
        // Force refresh the token to avoid expiration issues
        _ = try await user.getIDToken(forcingRefresh: false)
    }

    // MARK: - Send Message

    /// todaySnapshot: optional struct with today's consumed nutrition data
    func sendMessage(history: [ChatMessage], user: UserProfile, todaySnapshot: TodayNutritionSnapshot? = nil) async throws -> String {

        // 1. Construct System Prompt (extract values to avoid MainActor access)
        let age = user.ageYears
        let gender = user.gender.rawValue.capitalized
        let weight = user.weightKg
        let height = user.heightCm
        let activity = user.activityLevel.displayName
        let goal = user.goal.displayName
        let cal = user.targetCalories
        let prot = user.targetProteinG
        let carbs = user.targetCarbsG
        let fat = user.targetFatG
        let language = await MainActor.run { LanguageManager.shared.currentLanguage.rawValue }
        let systemPrompt = Self.constructSystemPrompt(age: age, gender: gender, weight: weight, height: height, activity: activity, goal: goal, calories: cal, protein: prot, carbs: carbs, fat: fat, todaySnapshot: todaySnapshot, language: language)

        let systemMsg = ChatMessage(role: .system, content: systemPrompt)
        var allMessages = [systemMsg]
        allMessages.append(contentsOf: history)

        // 2. Build messages array for the Cloud Function
        let messagesPayload = allMessages.map { ["role": $0.role.rawValue, "content": $0.content] }

        // 3. Ensure auth token is valid
        try await ensureAuth()

        // 4. Call Cloud Function
        let result = try await functions.httpsCallable("openaiChat").call([
            "messages": messagesPayload,
            "model": "gpt-4o-mini"
        ])

        guard let data = result.data as? [String: Any],
              let content = data["content"] as? String else {
            throw AICoachError.parsingError
        }

        return Self.stripMarkdown(content.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // MARK: - Strip Markdown

    nonisolated private static func stripMarkdown(_ text: String) -> String {
        var result = text
        // Remove headers (### **Title:** or ## Title)
        result = result.replacingOccurrences(of: "###\\s*", with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: "##\\s*", with: "", options: .regularExpression)
        // Remove bold markers
        result = result.replacingOccurrences(of: "**", with: "")
        // Remove code blocks
        result = result.replacingOccurrences(of: "```", with: "")
        // Remove inline code
        result = result.replacingOccurrences(of: "`", with: "")
        // Clean up multiple blank lines
        while result.contains("\n\n\n") {
            result = result.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Generate JSON (for structured output like workout plans)

    func generateJSON(systemPrompt: String, userPrompt: String) async throws -> String {
        let messagesPayload: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userPrompt]
        ]

        let result = try await functions.httpsCallable("openaiChat").call([
            "messages": messagesPayload,
            "model": "gpt-4o-mini"
        ])

        guard let data = result.data as? [String: Any],
              let content = data["content"] as? String else {
            throw AICoachError.parsingError
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Prompt Helpers

    nonisolated private static func constructSystemPrompt(age: Int, gender: String, weight: Double, height: Double, activity: String, goal: String, calories: Int, protein: Int, carbs: Int, fat: Int, todaySnapshot: TodayNutritionSnapshot?, language: String = "en") -> String {
        var prompt = """
        You are a direct, no-fluff fitness and nutrition coach inside the FuelIQ app.

        USER: \(gender), \(age)y, \(weight)kg, \(height)cm, \(activity), Goal: \(goal)
        TARGETS: \(calories)kcal | \(protein)g P | \(carbs)g C | \(fat)g F
        """

        if let snap = todaySnapshot {
            prompt += """

            TODAY: \(snap.caloriesConsumed)/\(calories)kcal | P:\(snap.proteinConsumed)/\(protein)g | C:\(snap.carbsConsumed)/\(carbs)g | F:\(snap.fatConsumed)/\(fat)g | Water:\(snap.waterMl)ml
            Meals: \(snap.mealsLogged.isEmpty ? "None" : snap.mealsLogged.joined(separator: " | "))
            """
        }

        prompt += """

        RULES:
        - Be DIRECT. No filler words, no "Great question!", no "Absolutely!". Just answer.
        - Max 3-4 sentences unless the user asks for detail.
        - Use plain text only. NO markdown (no #, no **, no ```, no ###). Use dashes (-) for bullet points.
        - Base every answer on the user's profile, today's data, and previous messages.
        - When suggesting food, account for what they already ate today and what macros remain.
        - Numbers over motivation. Give specific grams, reps, sets, calories.
        - If asked something off-topic, reply with one line: "I only help with fitness and nutrition."
        - Never repeat information the user already knows from previous messages.
        - Respond in the same language the user writes in.
        """

        if language == "ar" {
            prompt += "\nIMPORTANT: Always respond in Arabic (العربية). Use Arabic for all text."
        }

        return prompt
    }
}

// MARK: - Today Nutrition Snapshot
/// Lightweight, Sendable struct to pass today's nutrition data to the actor.

struct TodayNutritionSnapshot: Sendable {
    let caloriesConsumed: Int
    let proteinConsumed: Int
    let carbsConsumed: Int
    let fatConsumed: Int
    let waterMl: Int
    let mealsLogged: [String] // e.g. ["Breakfast: Oatmeal (350 kcal)", "Lunch: Chicken salad (480 kcal)"]

    init(from log: NutritionLog) {
        self.caloriesConsumed = Int(log.totalCalories)
        self.proteinConsumed = Int(log.totalProteinG)
        self.carbsConsumed = Int(log.totalCarbsG)
        self.fatConsumed = Int(log.totalFatG)
        self.waterMl = Int(log.waterMl)

        // Build a summary of meals logged
        var meals: [String] = []
        for type in MealType.allCases {
            let entries = log.entries.filter { $0.mealType == type }
            if !entries.isEmpty {
                let totalCal = Int(entries.reduce(0) { $0 + $1.calories })
                let names = entries.prefix(3).map { $0.foodName }.joined(separator: ", ")
                let suffix = entries.count > 3 ? " +\(entries.count - 3) more" : ""
                meals.append("\(type.displayName): \(names)\(suffix) (\(totalCal) kcal)")
            }
        }
        self.mealsLogged = meals
    }
}

// MARK: - Errors

enum AICoachError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case networkError(String)
    case apiError(String)
    case parsingError

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Developer Error: Open AI API key is not set in AICoachService."
        case .invalidURL:
            return "Invalid API Endpoint."
        case .networkError(let msg):
            return "Network Error: \(msg)"
        case .apiError(let msg):
            return "AI Error: \(msg)"
        case .parsingError:
            return "Failed to parse the AI's response."
        }
    }
}

// MARK: - OpenAI Request/Response Models

nonisolated struct OpenAIChatRequest: Encodable, Sendable {
    let model: String
    let messages: [OpenAIRequestMessage]
}

nonisolated struct OpenAIRequestMessage: Encodable, Sendable {
    let role: String
    let content: String
}

nonisolated struct OpenAIChatResponse: Decodable, Sendable {
    let choices: [OpenAIChoice]
}

nonisolated struct OpenAIChoice: Decodable, Sendable {
    let message: OpenAIResponseMessage
}

nonisolated struct OpenAIResponseMessage: Decodable, Sendable {
    let content: String
}

nonisolated struct OpenAIErrorResponse: Decodable, Sendable {
    nonisolated struct InnerError: Decodable, Sendable {
        let message: String
    }
    let error: InnerError
}
