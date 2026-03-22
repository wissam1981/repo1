import Foundation

// MARK: - Weekly Digest Model

struct WeeklyDigest: Codable {
    let title: String
    let highlights: [String]
    let macroScore: Int
    let topAchievement: String
    let improvement: String
    let weightTrend: String
}

// MARK: - Weekly Digest Service
/// Generates AI-powered weekly nutrition and fitness reports.

@MainActor
final class WeeklyDigestService {

    private let nutritionService: NutritionService
    private let coreDataService: CoreDataService
    private let aiService = AICoachService()

    private static let digestDataKey = "weekly_digest_data"
    private static let digestDateKey = "weekly_digest_date"

    init(nutritionService: NutritionService, coreDataService: CoreDataService) {
        self.nutritionService = nutritionService
        self.coreDataService = coreDataService
    }

    static var isDigestWindow: Bool {
        let weekday = Calendar.current.component(.weekday, from: .now)
        return weekday == 1 || weekday == 2 || weekday == 3
    }

    static var hasDigestThisWeek: Bool {
        guard let savedDate = UserDefaults.standard.object(forKey: digestDateKey) as? Date else {
            return false
        }
        return Calendar.current.isDate(savedDate, equalTo: .now, toGranularity: .weekOfYear)
    }

    static func loadSavedDigest() -> WeeklyDigest? {
        guard hasDigestThisWeek,
              let data = UserDefaults.standard.data(forKey: digestDataKey),
              let digest = try? JSONDecoder().decode(WeeklyDigest.self, from: data) else {
            return nil
        }
        return digest
    }

    func generateDigest(user: UserProfile) async -> WeeklyDigest? {
        guard !Self.hasDigestThisWeek else {
            return Self.loadSavedDigest()
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!

        let logs = nutritionService.fetchLogs(from: sevenDaysAgo, to: today)
        let progressEntries = coreDataService.fetchProgressEntries(limit: 7)
        let workoutSessions = coreDataService.fetchWorkoutSessions(from: sevenDaysAgo, to: today)

        var summary = "User: \(user.displayName), Goal: \(user.goal.rawValue)\n"
        summary += "Daily targets: \(user.targetCalories) kcal, \(user.targetProteinG)g protein, \(user.targetCarbsG)g carbs, \(user.targetFatG)g fat\n\n"

        summary += "LAST 7 DAYS NUTRITION:\n"
        for log in logs {
            let dayName = log.date.formatted(.dateTime.weekday(.wide))
            summary += "- \(dayName): \(Int(log.totalCalories)) kcal, P:\(Int(log.totalProteinG))g, C:\(Int(log.totalCarbsG))g, F:\(Int(log.totalFatG))g, Water: \(Int(log.waterMl))ml\n"
        }
        if logs.isEmpty { summary += "- No nutrition data logged\n" }

        summary += "\nWORKOUTS:\n"
        summary += "- \(workoutSessions.count) workout sessions completed\n"

        summary += "\nWEIGHT:\n"
        if let latest = progressEntries.first, let oldest = progressEntries.last {
            summary += "- Latest: \(String(format: "%.1f", latest.weightKg))kg, Oldest this period: \(String(format: "%.1f", oldest.weightKg))kg\n"
            let change = latest.weightKg - oldest.weightKg
            summary += "- Change: \(String(format: "%+.1f", change))kg\n"
        } else {
            summary += "- No weight data\n"
        }

        let systemPrompt = """
        You are a fitness coach analyzing a user's weekly data. Respond with ONLY valid JSON, no markdown, no code fences.

        The JSON must match this exact structure:
        {
          "title": "Week in Review",
          "highlights": ["2-3 short achievements or observations"],
          "macroScore": 0-100,
          "topAchievement": "One standout positive from the week",
          "improvement": "One specific, actionable suggestion",
          "weightTrend": "Brief weight trend description or 'No data'"
        }

        Rules:
        1. macroScore: 0-100 based on how close daily averages were to targets
        2. highlights: 2-3 items max, short phrases
        3. improvement: Be specific and actionable
        4. Be encouraging but honest
        """

        let languageDirective = LanguageManager.shared.isArabic
            ? "\nIMPORTANT: Write ALL text fields in Arabic (العربية)."
            : ""

        let userPrompt = "Analyze this week's data and generate a weekly report:\n\n\(summary)"

        do {
            let rawResponse = try await aiService.generateJSON(
                systemPrompt: systemPrompt + languageDirective,
                userPrompt: userPrompt
            )

            let cleaned = rawResponse
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let jsonData = cleaned.data(using: .utf8) else { return nil }

            let digest = try JSONDecoder().decode(WeeklyDigest.self, from: jsonData)

            if let encoded = try? JSONEncoder().encode(digest) {
                UserDefaults.standard.set(encoded, forKey: Self.digestDataKey)
                UserDefaults.standard.set(Date(), forKey: Self.digestDateKey)
            }

            return digest
        } catch {
            print("[WeeklyDigest] Generation failed: \(error.localizedDescription)")
            return nil
        }
    }

    static func formatAsMessage(_ digest: WeeklyDigest) -> String {
        var msg = "📊 \(digest.title)\n\n"
        msg += "Highlights:\n"
        for highlight in digest.highlights {
            msg += "- \(highlight)\n"
        }
        msg += "\nMacro Score: \(digest.macroScore)/100\n"
        msg += "\n🏆 \(digest.topAchievement)\n"
        msg += "\n💡 \(digest.improvement)\n"
        if !digest.weightTrend.isEmpty {
            msg += "\n⚖️ \(digest.weightTrend)"
        }
        return msg
    }
}
