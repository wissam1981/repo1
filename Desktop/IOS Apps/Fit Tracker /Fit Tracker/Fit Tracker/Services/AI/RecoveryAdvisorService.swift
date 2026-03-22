@preconcurrency import Foundation
import FirebaseFunctions

// MARK: - Recovery Advisor Service
// Analyzes recent workout intensity against recent nutritional intake to provide a recovery recommendation.

actor RecoveryAdvisorService {

    static let shared = RecoveryAdvisorService()

    private let functions = Functions.functions()

    private init() {}

    nonisolated func assessRecovery(yesterdayWorkout: WorkoutSession?, yesterdayNutrition: NutritionLog?, todayNutrition: NutritionLog?) async throws -> RecoveryAdvice {
        
        // 1. Prepare data Context
        var contextStr = ""
        
        if let workout = yesterdayWorkout {
            let totalVolume = workout.totalVolume
            contextStr += "Yesterday's Workout: \(workout.planName), Duration: \(Int(Double(workout.durationSeconds) / 60)) min, Total Volume: \(Int(totalVolume))kg across \(workout.exerciseLogs.count) exercises.\n"
        } else {
            contextStr += "Yesterday's Workout: Rest Day.\n"
        }
        
        if let yNut = yesterdayNutrition {
            contextStr += "Yesterday's Nutrition: \(Int(yNut.totalCalories)) kcal consumed. (Protein: \(Int(yNut.totalProteinG))g, Carbs: \(Int(yNut.totalCarbsG))g, Fat: \(Int(yNut.totalFatG))g)\n"
        } else {
            contextStr += "Yesterday's Nutrition: No data logged.\n"
        }
        
        if let tNut = todayNutrition {
            contextStr += "Today's Nutrition (So Far): \(Int(tNut.totalCalories)) kcal consumed.\n"
        }
        
        // 2. Build Prompt
        let systemPrompt = """
        You are an elite sports scientist and recovery coach. Analyze the user's recent workout and nutrition data to provide a recovery recommendation for TODAY.
        
        Based on the intensity of yesterday's workout and how well they fueled (calories/protein), determine if they should:
        1. "rest" (take a complete day off)
        2. "light" (active recovery, light cardio, or mobility)
        3. "heavy" (fully recovered, ready to lift heavy)
        
        Also calculate a "readiness_score" from 0 to 100 based on this data.
        Write a short (2-3 sentence) "message" explaining your reasoning directly to the user. E.g., "You moved a lot of weight yesterday but your protein intake was low. Take it easy today so your muscles can rebuild."
        
        Return ONLY a JSON object, wrapped in ```json and ``` markers.
        Format:
        {
            "status": "heavy", // must be "rest", "light", or "heavy"
            "readiness_score": 85,
            "message": "Your reasoning here."
        }
        """

        let userPrompt = "Here is my recent data:\n\(contextStr)\nEvaluate my recovery."

        let messagesPayload: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": userPrompt]
        ]
        
        // 3. Call Cloud Function
        let result = try await functions.httpsCallable("openaiChat").call([
             "messages": messagesPayload,
             "model": "gpt-4o-mini"
         ])

        guard let data = result.data as? [String: Any],
              let content = data["content"] as? String else {
            throw RecoveryError.parsingError
        }

        // 4. Extract & Parse JSON
        let cleaned: String
        if let jsonStart = content.range(of: "```json\n") {
            let afterStart = content[jsonStart.upperBound...]
            if let jsonEnd = afterStart.range(of: "```") {
                cleaned = String(afterStart[..<jsonEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                cleaned = String(afterStart).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else {
            cleaned = content
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                 .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let planData = cleaned.data(using: .utf8) else {
            throw RecoveryError.parsingError
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let advice = try decoder.decode(RecoveryAdvice.self, from: planData)
        return advice
    }
}

// MARK: - Models

struct RecoveryAdvice: Codable, Sendable {
    let status: String
    let readinessScore: Int
    let message: String
    
    enum StatusLevel {
        case rest
        case light
        case heavy
    }
    
    var level: StatusLevel {
        switch status.lowercased() {
        case "rest": return .rest
        case "light": return .light
        case "heavy": return .heavy
        default: return .light
        }
    }
}

// MARK: - Errors

enum RecoveryError: LocalizedError {
    case networkError(String)
    case parsingError

    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return "Network error: \(msg)"
        case .parsingError: return "Could not interpret the recovery data."
        }
    }
}
