# AI Intelligence Layer — Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 4 AI-powered features (Weekly Digest, Auto-complete Meals, Calorie Budget Advisor, Smart Search Ranking) to make the Fit Tracker app feel intelligent and proactive.

**Architecture:** Each feature is a self-contained service + UI integration. Features share modifications to `HomeView.swift`, `NutritionViewModel.swift`, and `AICoachViewModel.swift`. `AppState` gains a `pendingAIAction` mechanism for cross-feature navigation. All services follow existing patterns: `@MainActor` classes/structs, CoreData via `CoreDataService`, AI via `AICoachService` actor.

**Tech Stack:** Swift, SwiftUI, CoreData, Firebase Cloud Functions (GPT-4o-mini), UserDefaults, UNUserNotifications

**Spec:** `docs/superpowers/specs/2026-03-21-ai-intelligence-layer-phase1-design.md`

---

## File Map

| File | Action | Task |
|------|--------|------|
| `App/AppState.swift` | Modify | 1 |
| `Services/Nutrition/FoodFrequencyTracker.swift` | Create | 2 |
| `Services/Nutrition/SmartSearchRanker.swift` | Create | 3 |
| `Features/Nutrition/NutritionViewModel.swift` | Modify | 2, 3, 5 |
| `Services/Nutrition/MealPatternService.swift` | Create | 4 |
| `Features/Home/HomeView.swift` | Modify | 5, 7, 8 |
| `Features/Nutrition/NutritionDashboardView.swift` | Modify | 5 |
| `Services/AI/WeeklyDigestService.swift` | Create | 6 |
| `Features/AI/AICoachViewModel.swift` | Modify | 6, 8 |
| `Services/Notifications/NotificationManager.swift` | Modify | 7 |
| `Features/Home/Components/CalorieBudgetSheet.swift` | Create | 8 |
| `Features/AI/AICoachView.swift` | Modify | 8 |
| `Fit_TrackerApp.swift` | Modify | 7 |

---

### Task 1: Add `AIAction` and `showAICoach` to AppState

Foundational change needed by multiple features. Adds the cross-feature navigation mechanism.

**Files:**
- Modify: `Fit Tracker/App/AppState.swift`

- [ ] **Step 1: Add AIAction enum and properties to AppState**

Open `Fit Tracker/App/AppState.swift`. Add the `AIAction` enum above the `AppState` class, and add two properties to the class:

```swift
// Add ABOVE the AppState class (after AuthPhase enum, around line 11):

// MARK: - AI Action

enum AIAction {
    case budgetAdvisor
    case weeklyDigest
}
```

```swift
// Add INSIDE the AppState class, after the errorMessage property (line 22):

    // MARK: - AI Navigation
    var pendingAIAction: AIAction?
    var showAICoach: Bool = false
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -scheme "Fit Tracker" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add "Fit Tracker/App/AppState.swift"
git commit -m "feat: add AIAction enum and showAICoach to AppState"
```

---

### Task 2: Create FoodFrequencyTracker

Tracks how often each food is logged. Stored in UserDefaults, capped at 200 entries.

**Files:**
- Create: `Fit Tracker/Services/Nutrition/FoodFrequencyTracker.swift`
- Modify: `Fit Tracker/Features/Nutrition/NutritionViewModel.swift` (line 141, inside `addEntry`)

- [ ] **Step 1: Create FoodFrequencyTracker.swift**

Create the file at `Fit Tracker/Services/Nutrition/FoodFrequencyTracker.swift`:

```swift
import Foundation

// MARK: - Food Frequency Tracker
/// Tracks how often each food is logged to enable smart search ranking.
/// Data stored in UserDefaults, capped at 200 entries.

struct FoodFrequency: Codable {
    var count: Int
    var lastLogged: Date
}

@MainActor
struct FoodFrequencyTracker {

    private static let storageKey = "food_frequency_map"
    private static let maxEntries = 200

    // MARK: - Read

    static func frequencyMap() -> [String: FoodFrequency] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let map = try? JSONDecoder().decode([String: FoodFrequency].self, from: data) else {
            return [:]
        }
        return map
    }

    static func isFrequent(_ name: String) -> Bool {
        let key = name.lowercased()
        guard let entry = frequencyMap()[key] else { return false }
        return entry.count >= 3
    }

    // MARK: - Write

    static func recordFood(_ name: String) {
        var map = frequencyMap()
        let key = name.lowercased()

        if var existing = map[key] {
            existing.count += 1
            existing.lastLogged = Date()
            map[key] = existing
        } else {
            map[key] = FoodFrequency(count: 1, lastLogged: Date())
        }

        // Prune if over limit — remove the least frequent entry
        if map.count > maxEntries {
            if let leastFrequent = map.min(by: { $0.value.count < $1.value.count })?.key {
                map.removeValue(forKey: leastFrequent)
            }
        }

        if let data = try? JSONEncoder().encode(map) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
```

- [ ] **Step 2: Wire into NutritionViewModel.addEntry()**

Open `Fit Tracker/Features/Nutrition/NutritionViewModel.swift`. In the `addEntry(food:quantity:mealType:)` method, add the frequency recording call after the `refresh()` call (after line 128):

```swift
        // Record food frequency for smart search ranking
        FoodFrequencyTracker.recordFood(food.name)
```

Insert this line right after `refresh()` (line 128) and before the `// Cache USDA and Custom foods locally` comment (line 130).

- [ ] **Step 3: Build to verify**

Run: `xcodebuild build -scheme "Fit Tracker" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add "Fit Tracker/Services/Nutrition/FoodFrequencyTracker.swift" "Fit Tracker/Features/Nutrition/NutritionViewModel.swift"
git commit -m "feat: add FoodFrequencyTracker with UserDefaults storage"
```

---

### Task 3: Create SmartSearchRanker and Integrate into Search

Pure function that reorders search results based on frequency, recency, and macro needs.

**Files:**
- Create: `Fit Tracker/Services/Nutrition/SmartSearchRanker.swift`
- Modify: `Fit Tracker/Features/Nutrition/NutritionViewModel.swift` (inside `performSearch()`)

- [ ] **Step 1: Create SmartSearchRanker.swift**

Create the file at `Fit Tracker/Services/Nutrition/SmartSearchRanker.swift`:

```swift
import Foundation

// MARK: - Smart Search Ranker
/// Reorders food search results based on user habits and current macro needs.
/// Pure function — no side effects, no dependencies on ViewModels.

struct SmartSearchRanker {

    static func rank(
        _ results: [FoodItem],
        frequencyMap: [String: FoodFrequency],
        remainingCalories: Int,
        remainingProteinG: Int,
        remainingCarbsG: Int,
        remainingFatG: Int,
        query: String
    ) -> [FoodItem] {
        guard !results.isEmpty, !frequencyMap.isEmpty else { return results }

        let queryLower = query.lowercased()

        let scored = results.enumerated().map { index, food -> (food: FoodItem, score: Int, originalIndex: Int) in
            var score = 0
            let nameLower = food.name.lowercased()

            // +50 if frequently logged (3+ times)
            if let freq = frequencyMap[nameLower], freq.count >= 3 {
                score += 50
            }

            // +20 if logged in the last 3 days
            if let freq = frequencyMap[nameLower] {
                let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: .now)!
                if freq.lastLogged > threeDaysAgo {
                    score += 20
                }
            }

            // +10 if food is high in the user's most-needed macro
            let maxRemaining = max(remainingProteinG, remainingCarbsG, remainingFatG)
            if maxRemaining > 0 {
                if remainingProteinG == maxRemaining && food.proteinG > 15 {
                    score += 10
                } else if remainingCarbsG == maxRemaining && food.carbsG > 20 {
                    score += 10
                } else if remainingFatG == maxRemaining && food.fatG > 10 {
                    score += 10
                }
            }

            // +5 for exact name match with query
            if nameLower == queryLower {
                score += 5
            }

            return (food, score, index)
        }

        // Stable sort: items with equal scores keep their original order
        let sorted = scored.sorted { a, b in
            if a.score != b.score { return a.score > b.score }
            return a.originalIndex < b.originalIndex
        }

        return sorted.map(\.food)
    }
}
```

- [ ] **Step 2: Integrate into NutritionViewModel.performSearch()**

Open `Fit Tracker/Features/Nutrition/NutritionViewModel.swift`. In the `performSearch(query:)` method (line 294), replace the line that sets `searchResults` (line 306):

**Find this code (around lines 302-306):**
```swift
            let results = try await nutritionService.searchFoods(query: query)

            guard !Task.isCancelled else { return }

            searchResults = results
```

**Replace with:**
```swift
            let results = try await nutritionService.searchFoods(query: query)

            guard !Task.isCancelled else { return }

            // Smart rank results based on user habits and remaining macros
            searchResults = SmartSearchRanker.rank(
                results,
                frequencyMap: FoodFrequencyTracker.frequencyMap(),
                remainingCalories: caloriesRemaining,
                remainingProteinG: targetProteinG - Int(todayLog.totalProteinG),
                remainingCarbsG: targetCarbsG - Int(todayLog.totalCarbsG),
                remainingFatG: targetFatG - Int(todayLog.totalFatG),
                query: query
            )
```

- [ ] **Step 3: Build to verify**

Run: `xcodebuild build -scheme "Fit Tracker" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add "Fit Tracker/Services/Nutrition/SmartSearchRanker.swift" "Fit Tracker/Features/Nutrition/NutritionViewModel.swift"
git commit -m "feat: add SmartSearchRanker for personalized food search results"
```

---

### Task 4: Create MealPatternService

Analyzes the last 14 days of nutrition logs to find recurring meal patterns.

**Files:**
- Create: `Fit Tracker/Services/Nutrition/MealPatternService.swift`

**Context:**
- `NutritionService.fetchLogs(from:to:)` returns `[NutritionLog]`
- Each `NutritionLog` has `.entries: [NutritionEntry]`
- Each `NutritionEntry` has `.mealType: MealType`, `.foodName: String`, `.calories: Double`, `.proteinG`, `.carbsG`, `.fatG`, `.servingQuantity`, `.foodItemId`
- `MealType` is an enum: `.breakfast`, `.lunch`, `.dinner`, `.snack`

- [ ] **Step 1: Create MealPatternService.swift**

Create the file at `Fit Tracker/Services/Nutrition/MealPatternService.swift`:

```swift
import Foundation

// MARK: - Meal Pattern

struct MealPattern {
    let mealType: MealType
    let entries: [NutritionEntry]    // The frequent food entries with original portions
    let totalCalories: Int           // Sum of their calories
    let frequency: Int               // How many of the last 14 days this pattern appeared
}

// MARK: - Meal Pattern Service
/// Analyzes the last 14 days of nutrition logs to find recurring meal patterns.
/// Returns patterns for meals the user eats frequently (3+ times in 14 days).

struct MealPatternService {

    /// Analyze recent logs and return patterns grouped by meal type.
    /// Only returns patterns where the user has eaten the same foods 3+ times.
    static func detectPatterns(from logs: [NutritionLog]) -> [MealType: MealPattern] {
        var result: [MealType: MealPattern] = [:]

        for mealType in MealType.allCases {
            if let pattern = findPattern(for: mealType, in: logs) {
                result[mealType] = pattern
            }
        }

        return result
    }

    /// Find the most common foods for a given meal type.
    private static func findPattern(for mealType: MealType, in logs: [NutritionLog]) -> MealPattern? {
        // Collect all entries for this meal type across all logs
        let allEntries = logs.flatMap { $0.entries.filter { $0.mealType == mealType } }

        guard !allEntries.isEmpty else { return nil }

        // Count frequency of each food (by foodItemId)
        var frequencyByFoodId: [String: Int] = [:]
        var latestEntryByFoodId: [String: NutritionEntry] = [:]

        for entry in allEntries {
            frequencyByFoodId[entry.foodItemId, default: 0] += 1
            // Keep the most recent entry for each food (has latest portion/macros)
            if let existing = latestEntryByFoodId[entry.foodItemId] {
                if entry.loggedAt > existing.loggedAt {
                    latestEntryByFoodId[entry.foodItemId] = entry
                }
            } else {
                latestEntryByFoodId[entry.foodItemId] = entry
            }
        }

        // Filter to foods eaten 3+ times
        let frequentFoodIds = frequencyByFoodId.filter { $0.value >= 3 }.map(\.key)

        guard !frequentFoodIds.isEmpty else { return nil }

        // Get the top 3 most frequent foods
        let topFoodIds = frequentFoodIds
            .sorted { frequencyByFoodId[$0]! > frequencyByFoodId[$1]! }
            .prefix(3)

        let patternEntries = topFoodIds.compactMap { latestEntryByFoodId[$0] }

        guard !patternEntries.isEmpty else { return nil }

        // Count how many unique days this meal type had ANY of these foods
        let daysWithPattern = Set(
            logs.filter { log in
                log.entries.contains { entry in
                    entry.mealType == mealType && frequentFoodIds.contains(entry.foodItemId)
                }
            }.map { Calendar.current.startOfDay(for: $0.date) }
        ).count

        let totalCalories = Int(patternEntries.reduce(0) { $0 + $1.calories })

        return MealPattern(
            mealType: mealType,
            entries: Array(patternEntries),
            totalCalories: totalCalories,
            frequency: daysWithPattern
        )
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild build -scheme "Fit Tracker" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add "Fit Tracker/Services/Nutrition/MealPatternService.swift"
git commit -m "feat: add MealPatternService for detecting recurring meal patterns"
```

---

### Task 5: Integrate Meal Patterns into NutritionViewModel, HomeView, and NutritionDashboardView

Wire up the meal pattern detection and one-tap logging into the UI.

**Files:**
- Modify: `Fit Tracker/Features/Nutrition/NutritionViewModel.swift`
- Modify: `Fit Tracker/Features/Home/HomeView.swift`
- Modify: `Fit Tracker/Features/Nutrition/NutritionDashboardView.swift`

**Context:**
- `NutritionViewModel` already has `currentMealType` (line 409-418) and `nutritionService` (line 57)
- `HomeView.dashboardContent()` starts at line 206 — cards are in a `VStack(spacing: 16)`
- `NutritionDashboardView` renders meal sections at lines 101-119 using `MealSectionView`
- `HomeView` accesses `appState`, `router`, and has `@State` variables at the top

- [ ] **Step 1: Add meal pattern state and methods to NutritionViewModel**

Open `Fit Tracker/Features/Nutrition/NutritionViewModel.swift`.

**Add these properties after the `recentFoods` property (after line 52):**

```swift
    // Meal pattern suggestions
    var mealPatterns: [MealType: MealPattern] = [:]
```

**Add this method after the `refresh()` method (after line 109):**

```swift
    // MARK: - Meal Patterns

    func loadMealPatterns() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: today)!
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: today)!
        let logs = nutritionService.fetchLogs(from: fourteenDaysAgo, to: endOfDay)
        mealPatterns = MealPatternService.detectPatterns(from: logs)
    }

    func logMealPattern(_ pattern: MealPattern) async {
        for entry in pattern.entries {
            var newEntry = entry
            newEntry.id = UUID().uuidString
            newEntry.loggedAt = Date()
            var log = todayLog
            await nutritionService.addEntry(newEntry, to: &log)
            todayLog = log
        }
        refresh()
        Task {
            await nutritionService.syncToFirestore(todayLog, userId: user.uid)
        }
        NotificationCenter.default.post(name: .nutritionLogDidChange, object: nil)
    }
```

**Add a call to `loadMealPatterns()` in the `init` method. After line 64 (`self.todayLog = nutritionService.fetchTodayLog()`), add:**

```swift
        loadMealPatterns()
```

- [ ] **Step 2: Add meal suggestion card to HomeView**

Open `Fit Tracker/Features/Home/HomeView.swift`. In `dashboardContent()`, add a meal suggestion card right after the `trialBanner` (after line 217) and before the DateNavigator (line 219).

**First, add a `@State` property near the other state variables (around line 204):**

```swift
    @State private var nutritionVM: NutritionViewModel?
```

**Initialize it in `initViewModelIfNeeded()` (around line 175). After the `workoutVM` initialization block (after line 199), add:**

```swift
        if nutritionVM == nil, let user = appState.currentUser {
            nutritionVM = NutritionViewModel(
                user: user,
                nutritionService: container.nutritionService
            )
        }
```

**Then add this card in the dashboardContent VStack, after `trialBanner` (line 217):**

```swift
            // Meal Suggestion Card
            if let nvm = nutritionVM,
               let pattern = nvm.mealPatterns[nvm.currentMealType],
               nvm.entries(for: nvm.currentMealType).isEmpty {
                mealSuggestionCard(pattern: pattern, nutritionVM: nvm)
                    .padding(.horizontal, 20)
            }
```

**Add the card view method at the bottom of the file (before the closing brace of HomeView):**

```swift
    // MARK: - Meal Suggestion Card

    private func mealSuggestionCard(pattern: MealPattern, nutritionVM: NutritionViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ThemeColors.primary)
                Text("Your usual \(pattern.mealType.displayName)?")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(pattern.totalCalories) kcal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Food names
            Text(pattern.entries.map(\.foodName).joined(separator: ", "))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(2)

            Button {
                Task { await nutritionVM.logMealPattern(pattern) }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15))
                    Text("Log All")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(ThemeColors.primary)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(ThemeColors.primary.opacity(0.15), lineWidth: 1)
                )
        )
    }
```

**Note:** The `mealPatternVM` needs to be initialized. Look for where `HomeView` creates its ViewModels (likely in `.onAppear` or `.task`). Create a `NutritionViewModel` instance there and assign it to `mealPatternVM`. If `HomeView` already has access to a `NutritionViewModel`, use that instead and remove the `@State` property. Check how `HomeView` gets its dependencies — it likely uses `appState.currentUser` and `DependencyContainer.shared.nutritionService`.

- [ ] **Step 3: Add meal pattern banner to NutritionDashboardView**

Open `Fit Tracker/Features/Nutrition/NutritionDashboardView.swift`. In the meal sections area (lines 101-119), add a banner above each `MealSectionView` when a pattern exists and no entries are logged for that meal.

**Find the ForEach that iterates MealType.allCases (around line 101):**
```swift
                    ForEach(MealType.allCases, id: \.self) { meal in
```

**Inside the ForEach, before the `MealSectionView(...)`, add:**

```swift
                        // Meal pattern suggestion banner
                        if let pattern = vm.mealPatterns[meal],
                           vm.entries(for: meal).isEmpty {
                            Button {
                                Task { await vm.logMealPattern(pattern) }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(ThemeColors.primary)
                                    Text("Log your usual: \(pattern.entries.map(\.foodName).joined(separator: ", "))?")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.7))
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(ThemeColors.primary)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(ThemeColors.primary.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(ThemeColors.primary.opacity(0.12), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
```

- [ ] **Step 4: Build to verify**

Run: `xcodebuild build -scheme "Fit Tracker" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED (may need to fix minor issues around HomeView VM initialization)

- [ ] **Step 5: Commit**

```bash
git add "Fit Tracker/Features/Nutrition/NutritionViewModel.swift" "Fit Tracker/Features/Home/HomeView.swift" "Fit Tracker/Features/Nutrition/NutritionDashboardView.swift"
git commit -m "feat: add auto-complete daily meals with pattern detection and one-tap logging"
```

---

### Task 6: Create WeeklyDigestService and Integrate into AICoachViewModel

Generates weekly AI-powered nutrition/fitness reports and displays them as pinned messages in AI Coach.

**Files:**
- Create: `Fit Tracker/Services/AI/WeeklyDigestService.swift`
- Modify: `Fit Tracker/Features/AI/AICoachViewModel.swift`

**Context:**
- `AICoachService` is an `actor` — call methods with `await`
- `AICoachService.generateJSON(systemPrompt:userPrompt:)` returns a `String` (raw JSON text)
- `CoreDataService.fetchNutritionLogs(from:to:)` returns `[NutritionLogEntity]` — use `NutritionService.fetchLogs(from:to:)` instead which returns `[NutritionLog]`
- `CoreDataService.fetchWorkoutSessions(from:to:)` exists — returns workout session entities
- `CoreDataService.fetchProgressEntries(limit:)` exists — returns `[ProgressEntry]`
- `NutritionLog` has: `totalCalories`, `totalProteinG`, `totalCarbsG`, `totalFatG`, `waterMl`, `entries`
- `AICoachViewModel` uses `ChatMessage(role:content:timestamp:)` for messages
- `AICoachViewModel` persists chat to UserDefaults with daily reset (lines 66-96)

- [ ] **Step 1: Create WeeklyDigestService.swift**

Create the file at `Fit Tracker/Services/AI/WeeklyDigestService.swift`:

```swift
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
/// Gathers 7 days of data and sends a summary to GPT for analysis.

@MainActor
final class WeeklyDigestService {

    private let nutritionService: NutritionService
    private let coreDataService: CoreDataService
    private let aiService = AICoachService()

    // UserDefaults keys
    private static let digestDataKey = "weekly_digest_data"
    private static let digestDateKey = "weekly_digest_date"

    init(nutritionService: NutritionService, coreDataService: CoreDataService) {
        self.nutritionService = nutritionService
        self.coreDataService = coreDataService
    }

    // MARK: - Public API

    /// Returns true if today is Sunday, Monday, or Tuesday.
    static var isDigestWindow: Bool {
        let weekday = Calendar.current.component(.weekday, from: .now)
        return weekday == 1 || weekday == 2 || weekday == 3 // Sun=1, Mon=2, Tue=3
    }

    /// Returns true if a digest has already been generated for this week.
    static var hasDigestThisWeek: Bool {
        guard let savedDate = UserDefaults.standard.object(forKey: digestDateKey) as? Date else {
            return false
        }
        // Check if the saved digest was generated this calendar week
        let calendar = Calendar.current
        return calendar.isDate(savedDate, equalTo: .now, toGranularity: .weekOfYear)
    }

    /// Load the saved digest from UserDefaults.
    static func loadSavedDigest() -> WeeklyDigest? {
        guard hasDigestThisWeek,
              let data = UserDefaults.standard.data(forKey: digestDataKey),
              let digest = try? JSONDecoder().decode(WeeklyDigest.self, from: data) else {
            return nil
        }
        return digest
    }

    /// Generate and save the weekly digest. Returns nil if generation fails.
    func generateDigest(user: UserProfile) async -> WeeklyDigest? {
        // Don't regenerate if already done this week
        guard !Self.hasDigestThisWeek else {
            return Self.loadSavedDigest()
        }

        // 1. Gather 7 days of data
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!

        let logs = nutritionService.fetchLogs(from: sevenDaysAgo, to: today)
        let progressEntries = coreDataService.fetchProgressEntries(limit: 7)
        let workoutSessions = coreDataService.fetchWorkoutSessions(from: sevenDaysAgo, to: today)

        // 2. Build summary string
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

        // 3. Send to AI
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

        let userPrompt = "Analyze this week's data and generate a weekly report:\n\n\(summary)"

        do {
            let rawResponse = try await aiService.generateJSON(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt
            )

            // 4. Parse JSON (strip markdown fences if present)
            let cleaned = rawResponse
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let jsonData = cleaned.data(using: .utf8) else { return nil }

            let digest = try JSONDecoder().decode(WeeklyDigest.self, from: jsonData)

            // 5. Save to UserDefaults
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

    /// Format a digest into a readable chat message string.
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
```

- [ ] **Step 2: Integrate into AICoachViewModel**

Open `Fit Tracker/Features/AI/AICoachViewModel.swift`.

**Add a property for the weekly digest (after `streamingMessageId` on line 19):**

```swift
    /// Weekly digest pinned message (survives daily chat resets)
    var weeklyDigestMessage: ChatMessage?
```

**Add digest loading in `init()`. After the existing messages initialization (after line 61), add:**

```swift
        // Load weekly digest if within the Sunday-Tuesday window
        if WeeklyDigestService.isDigestWindow,
           let digest = WeeklyDigestService.loadSavedDigest() {
            weeklyDigestMessage = ChatMessage(
                role: .assistant,
                content: WeeklyDigestService.formatAsMessage(digest)
            )
        }
```

**Add a method to generate the weekly digest (after `retryLastMessage()` at line 238):**

```swift
    // MARK: - Weekly Digest

    func generateWeeklyDigest() {
        guard WeeklyDigestService.isDigestWindow, !WeeklyDigestService.hasDigestThisWeek else { return }

        let deps = DependencyContainer.shared
        let service = WeeklyDigestService(
            nutritionService: deps.nutritionService,
            coreDataService: deps.coreDataService
        )
        let userCopy = user

        Task { @MainActor in
            if let digest = await service.generateDigest(user: userCopy) {
                let formatted = WeeklyDigestService.formatAsMessage(digest)
                weeklyDigestMessage = ChatMessage(
                    role: .assistant,
                    content: formatted
                )
            }
        }
    }

    func showWeeklyDigest() {
        // Scroll to top or highlight the pinned digest message
        // The digest is shown as weeklyDigestMessage in the view
    }
```

**The AICoachView will need to show `weeklyDigestMessage` at the top of the chat. This will be handled when modifying AICoachView in Task 8.**

- [ ] **Step 3: Build to verify**

Run: `xcodebuild build -scheme "Fit Tracker" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add "Fit Tracker/Services/AI/WeeklyDigestService.swift" "Fit Tracker/Features/AI/AICoachViewModel.swift"
git commit -m "feat: add WeeklyDigestService with AI-powered weekly reports"
```

---

### Task 7: Modify NotificationManager and Add Weekly Digest Card to HomeView

Fix the notification conflict and schedule the weekly digest notification. Add the digest card to HomeView.

**Files:**
- Modify: `Fit Tracker/Services/Notifications/NotificationManager.swift`
- Modify: `Fit Tracker/Features/Home/HomeView.swift`

**Context:**
- `NotificationManager` is a `Sendable` singleton (line 5-9)
- `scheduleDailyReminders()` currently calls `center.removeAllPendingNotificationRequests()` on line 26 — this wipes ALL notifications
- Daily reminder IDs are: `"morning_reminder"`, `"afternoon_reminder"`, `"evening_reminder"`
- The private helper `scheduleReminder(id:title:body:hour:minute:)` creates repeating calendar triggers
- `HomeView` uses `appState` and `router` environment objects

- [ ] **Step 1: Fix notification conflict in NotificationManager**

Open `Fit Tracker/Services/Notifications/NotificationManager.swift`.

**Replace line 26:**
```swift
        center.removeAllPendingNotificationRequests()
```

**With:**
```swift
        // Remove only daily reminder notifications (not weekly digest or other notifications)
        center.removePendingNotificationRequests(withIdentifiers: [
            "morning_reminder", "afternoon_reminder", "evening_reminder"
        ])
```

- [ ] **Step 2: Add weekly digest notification method**

In the same file, add this method after `scheduleWeightReminders()` (after line 131):

```swift
    /// Schedules a repeating local notification for every Sunday at 8pm.
    func scheduleWeeklyDigestNotification() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        // Remove existing to avoid duplicates
        center.removePendingNotificationRequests(withIdentifiers: ["weekly_digest_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Weekly Report Ready 📊"
        content.body = "See how your week went — tap to view your AI analysis"
        content.sound = .default

        // Every Sunday at 8pm
        var dateComponents = DateComponents()
        dateComponents.weekday = 1  // Sunday
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_digest_reminder", content: content, trigger: trigger)

        try? await center.add(request)
    }
```

- [ ] **Step 3: Wire `scheduleWeeklyDigestNotification()` into app startup**

Open `Fit Tracker/Fit_TrackerApp.swift`. In the `.task` modifier (line 66-78), add the weekly digest notification scheduling right after `scheduleDailyReminders()` (after line 70):

```swift
                    await NotificationManager.shared.scheduleWeeklyDigestNotification()
```

The full block should now look like:
```swift
            .task {
                let granted = try? await NotificationManager.shared.requestAuthorization()
                if granted == true {
                    await NotificationManager.shared.scheduleDailyReminders()
                    await NotificationManager.shared.scheduleWeeklyDigestNotification()
                }
                // ... rest unchanged
            }
```

- [ ] **Step 4: Add weekly digest card to HomeView**

Open `Fit Tracker/Features/Home/HomeView.swift`. In `dashboardContent()`, add a weekly digest card in the VStack. Insert it right after the `// Trial banner` line (after line 217), BEFORE the meal suggestion card added in Task 5:

```swift
            // Weekly AI Digest Card (Sunday through Tuesday)
            if WeeklyDigestService.isDigestWindow, WeeklyDigestService.hasDigestThisWeek {
                Button {
                    appState.pendingAIAction = .weeklyDigest
                    appState.showAICoach = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [ThemeColors.primary, ThemeColors.primary.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Your Weekly Report is Ready")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Tap to see your AI analysis")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(ThemeColors.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }
```

- [ ] **Step 5: Wire `showAICoach` to the fullScreenCover**

In `HomeView.swift`, the existing AI Coach fullScreenCover is at line 401:
```swift
        .fullScreenCover(isPresented: $showCoach) {
```

We need to also trigger it when `appState.showAICoach` is set. Add an `.onChange` modifier on the HomeView body (near the other modifiers). Find a suitable place and add:

```swift
        .onChange(of: appState.showAICoach) { _, newValue in
            if newValue {
                showCoach = true
                appState.showAICoach = false
            }
        }
```

- [ ] **Step 6: Build to verify**

Run: `xcodebuild build -scheme "Fit Tracker" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 7: Commit**

```bash
git add "Fit Tracker/Services/Notifications/NotificationManager.swift" "Fit Tracker/Features/Home/HomeView.swift" "Fit Tracker/Fit_TrackerApp.swift"
git commit -m "feat: add weekly digest notification and home card"
```

---

### Task 8: Create CalorieBudgetSheet and Add Budget Advisor to AICoachView

Adds the calorie ring tap → budget sheet → AI suggestions flow, and the persistent "What should I eat?" chip in AI Coach.

**Files:**
- Create: `Fit Tracker/Features/Home/Components/CalorieBudgetSheet.swift`
- Modify: `Fit Tracker/Features/AI/AICoachView.swift`
- Modify: `Fit Tracker/Features/AI/AICoachViewModel.swift`
- Modify: `Fit Tracker/Features/Home/HomeView.swift`

**Context:**
- `AICoachView` has a `suggestionsRow` (line 207) with horizontal scroll chips
- `AICoachViewModel` has `sendSuggestion(_ text:)` method (line 222)
- `HomeView` has nutrition carousel starting at line 230 — the calorie ring is inside `CalorieMainCard`
- `AppState` now has `pendingAIAction` and `showAICoach` (from Task 1)
- `AICoachViewModel.init(user:coreDataService:)` creates the VM — the coach needs macro data

- [ ] **Step 1: Add `askBudgetAdvisor()` to AICoachViewModel**

Open `Fit Tracker/Features/AI/AICoachViewModel.swift`. Add this method after `sendSuggestion()` (after line 225):

```swift
    // MARK: - Budget Advisor

    func askBudgetAdvisor() {
        let todayLog = coreDataService.fetchNutritionLogDomain(for: .now) ?? NutritionLog(date: .now)
        let remaining = max(0, user.targetCalories - Int(todayLog.totalCalories))
        let proteinLeft = max(0, user.targetProteinG - Int(todayLog.totalProteinG))
        let carbsLeft = max(0, user.targetCarbsG - Int(todayLog.totalCarbsG))
        let fatLeft = max(0, user.targetFatG - Int(todayLog.totalFatG))

        let question = "What should I eat? I have \(remaining) kcal left, need \(proteinLeft)g protein, \(carbsLeft)g carbs, \(fatLeft)g fat"
        inputText = question
        sendMessage()
    }

    /// Handle pending AI actions from other parts of the app
    func handlePendingAction(_ action: AIAction) {
        switch action {
        case .budgetAdvisor:
            askBudgetAdvisor()
        case .weeklyDigest:
            showWeeklyDigest()
        }
    }
```

- [ ] **Step 2: Add persistent "What should I eat?" chip to AICoachView**

Open `Fit Tracker/Features/AI/AICoachView.swift`. The `suggestionsRow` is at line 207. Add a persistent budget advisor chip ABOVE the existing suggestions row. Find where `suggestionsRow` is used in the body (likely around lines 244-247 area where it appears in the VStack).

Add this view right before the `suggestionsRow`:

```swift
            // Persistent "What should I eat?" chip — always visible
            if !viewModel.isTyping {
                Button {
                    viewModel.askBudgetAdvisor()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ThemeColors.primary)
                        Text("What should I eat?")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(
                        Capsule()
                            .fill(ThemeColors.primary.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(ThemeColors.primary.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
```

**Also add the weekly digest pinned message at the top of the chat area.** In the chat ScrollView (around line 135), before the `ForEach(viewModel.messages)`, add:

```swift
                        // Pinned weekly digest message
                        if let digestMsg = viewModel.weeklyDigestMessage {
                            CoachBubble(message: digestMsg, isStreaming: false)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                        }
```

- [ ] **Step 3: Handle pendingAIAction in AICoachView**

In `AICoachView`, add an `.onAppear` modifier (or modify existing one) to check for pending actions:

```swift
        .onAppear {
            if let action = appState.pendingAIAction {
                appState.pendingAIAction = nil
                viewModel.handlePendingAction(action)
            }
        }
```

**Important:** `AICoachView` does not currently have access to `appState`. Add this property at the top of `AICoachView` (after the existing `@Bindable var viewModel` line):

```swift
    @Environment(AppState.self) private var appState
```

This works because `AppState` is injected into the environment in `Fit_TrackerApp.swift` (line 61: `.environment(appState)`).

- [ ] **Step 4: Create CalorieBudgetSheet.swift**

Create the file at `Fit Tracker/Features/Home/Components/CalorieBudgetSheet.swift`:

```swift
import SwiftUI

// MARK: - Calorie Budget Sheet
/// Bottom sheet showing remaining calories and macros with an AI suggestion button.

struct CalorieBudgetSheet: View {
    let consumed: Int
    let target: Int
    let proteinConsumed: Int
    let proteinTarget: Int
    let carbsConsumed: Int
    let carbsTarget: Int
    let fatConsumed: Int
    let fatTarget: Int

    let onGetAISuggestions: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var remaining: Int { max(0, target - consumed) }
    private var proteinRemaining: Int { max(0, proteinTarget - proteinConsumed) }
    private var carbsRemaining: Int { max(0, carbsTarget - carbsConsumed) }
    private var fatRemaining: Int { max(0, fatTarget - fatConsumed) }

    var body: some View {
        VStack(spacing: 24) {
            // Handle bar
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            // Title
            Text("Today's Budget")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            // Remaining calories (big number)
            VStack(spacing: 4) {
                Text("\(remaining)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(ThemeColors.primary)
                Text("kcal remaining")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Macro progress bars
            VStack(spacing: 16) {
                macroRow("Protein", consumed: proteinConsumed, target: proteinTarget, remaining: proteinRemaining, color: .blue)
                macroRow("Carbs", consumed: carbsConsumed, target: carbsTarget, remaining: carbsRemaining, color: .orange)
                macroRow("Fat", consumed: fatConsumed, target: fatTarget, remaining: fatRemaining, color: .red)
            }
            .padding(.horizontal, 20)

            // AI Suggestion button
            Button {
                dismiss()
                onGetAISuggestions()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                    Text("Get AI Suggestions")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(ThemeColors.primary)
                        .shadow(color: ThemeColors.primary.opacity(0.3), radius: 10, y: 5)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.top, 8)
        .background(ThemeColors.backgroundDark.ignoresSafeArea())
    }

    private func macroRow(_ label: String, consumed: Int, target: Int, remaining: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(consumed)g / \(target)g")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                Text("(\(remaining)g left)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * min(1.0, target > 0 ? Double(consumed) / Double(target) : 0), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}
```

- [ ] **Step 5: Make calorie ring tappable in HomeView and present CalorieBudgetSheet**

Open `Fit Tracker/Features/Home/HomeView.swift`. Add a `@State` variable for the budget sheet:

```swift
    @State private var showBudgetSheet = false
```

The calorie card is rendered as `CalorieMainCard` at line 232. We need to make it tappable. Wrap the `CalorieMainCard` in the TabView (line 232-240) with a tap gesture or Button:

```swift
                // Slide 1: Main Calorie Progress
                CalorieMainCard(
                    consumed: vm.caloriesConsumed,
                    target: vm.targetCalories,
                    progress: vm.targetCalories > 0 ? Double(vm.caloriesConsumed) / Double(vm.targetCalories) : 0,
                    remaining: max(0, vm.targetCalories - vm.caloriesConsumed),
                    fitnessGoal: vm.fitnessGoal
                )
                .padding(.horizontal, 20)
                .tag(0)
                .onTapGesture { showBudgetSheet = true }
```

Then add the sheet modifier somewhere on the view (near other `.sheet` modifiers):

```swift
        .sheet(isPresented: $showBudgetSheet) {
            if let vm = viewModel {
                CalorieBudgetSheet(
                    consumed: vm.caloriesConsumed,
                    target: vm.targetCalories,
                    proteinConsumed: vm.proteinConsumed,
                    proteinTarget: vm.targetProteinG,
                    carbsConsumed: vm.carbsConsumed,
                    carbsTarget: vm.targetCarbsG,
                    fatConsumed: vm.fatConsumed,
                    fatTarget: vm.targetFatG,
                    onGetAISuggestions: {
                        appState.pendingAIAction = .budgetAdvisor
                        appState.showAICoach = true
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
            }
        }
```

**Note:** `HomeView` stores the `HomeViewModel` as `@State private var viewModel: HomeViewModel?` (line 23). The `dashboardContent(_ vm:)` method receives it as a parameter, but for the sheet modifier we reference the stored property directly via `viewModel`.

- [ ] **Step 6: Build to verify**

Run: `xcodebuild build -scheme "Fit Tracker" -destination "platform=iOS Simulator,name=iPhone 16" -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 7: Commit**

```bash
git add "Fit Tracker/Features/Home/Components/CalorieBudgetSheet.swift" "Fit Tracker/Features/AI/AICoachView.swift" "Fit Tracker/Features/AI/AICoachViewModel.swift" "Fit Tracker/Features/Home/HomeView.swift"
git commit -m "feat: add Calorie Budget Advisor with sheet and AI Coach chip"
```

---

## Integration Notes

### How features interact in HomeView (card ordering, top to bottom):
1. Custom Header
2. Trial Banner
3. **Weekly Digest Card** (Task 7) — visible Sunday-Tuesday if generated
4. **Meal Suggestion Card** (Task 5) — visible during meal-appropriate times
5. Date Navigator
6. Nutrition Carousel (with tappable calorie ring → Budget Sheet, Task 8)
7. ... rest of existing content

### AppState flow for cross-feature navigation:
1. User taps a card/button → sets `appState.pendingAIAction` and `appState.showAICoach = true`
2. HomeView's `.onChange(of: appState.showAICoach)` sets `showCoach = true`
3. `fullScreenCover` presents `AICoachView`
4. AICoachView's `.onAppear` checks `appState.pendingAIAction`, triggers the action, then clears it

### Build order matters:
- Task 1 (AppState) must be first — other tasks depend on `AIAction` and `showAICoach`
- Tasks 2-4 are independent of each other
- Task 5 depends on Task 4 (MealPatternService)
- Task 6 is independent
- Tasks 7-8 depend on Task 1 (AppState) and Task 6 (WeeklyDigestService)
