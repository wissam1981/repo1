# AI Intelligence Layer — Phase 1 Design Spec

**Date:** 2026-03-21
**Status:** Approved

## Problem

The app's AI is limited to a chat interface and food scanning. Users must manually search, log, and track everything. The AI doesn't proactively help, suggest, or learn from user behavior.

## Solution

Add 4 AI-powered features that make the app feel intelligent: Weekly AI Digest, Auto-complete Daily Meals, Calorie Budget Advisor, and Smart Search Ranking.

---

## Feature 1: Weekly AI Digest

### User Flow
1. Every Sunday at 8pm, a local notification fires: "Your weekly report is ready"
2. Tapping the notification opens the app → navigates to AI Coach chat
3. On the Home page, a "Weekly AI Report" card appears from Sunday through Tuesday
4. Tapping the home card also opens AI Coach with the report
5. The report message is auto-generated and inserted into the AI Coach chat

### Implementation

#### `Fit Tracker/Services/AI/WeeklyDigestService.swift` (Create)
- `@MainActor final class WeeklyDigestService` — runs on MainActor since it accesses `NutritionService` and `CoreDataService` which are both `@MainActor`
- Injected dependencies: `NutritionService`, `CoreDataService`
- Gathers last 7 days of data:
  - Daily calorie totals and macro breakdown via `NutritionService.fetchLogs(from:to:)` (already exists)
  - Workout sessions via `CoreDataService.fetchWorkoutSessions(from:to:)` (already exists)
  - Weight entries via `CoreDataService.fetchProgressEntries(limit: 7)` (already exists)
  - Daily water intake from `NutritionLog.waterMl`
- Builds a data summary string (not the full logs, just aggregated stats)
- Sends to `AICoachService.generateJSON()` (actor, called via `await`) with a weekly digest system prompt
- System prompt instructs AI to return structured JSON
- Response is parsed into a `WeeklyDigest` Codable struct:
```swift
struct WeeklyDigest: Codable {
    let title: String
    let highlights: [String]
    let macroScore: Int
    let topAchievement: String
    let improvement: String
    let weightTrend: String
}
```
- JSON parsing: strip markdown code fences (```` ```json ``` ````) before decoding, handle `DecodingError` gracefully by returning nil (digest silently skipped)
- The parsed digest is formatted into a readable chat message and stored separately in UserDefaults as `weeklyDigestData` (encoded `WeeklyDigest`) alongside `lastWeeklyDigestDate`
- This stored digest is NOT part of the daily chat history — it is shown as a pinned system message at the top of AI Coach when within the Sunday-Tuesday window, surviving daily chat resets

#### `Fit Tracker/Services/Notifications/NotificationManager.swift` (Modify)
- Add `scheduleWeeklyDigestNotification()` method to schedule a repeating local notification for every Sunday at 8pm
- Use a fixed identifier `"weekly_digest_reminder"` for this notification
- Notification title: "Weekly Report Ready"
- Notification body: "See how your week went — tap to view your AI analysis"
- Handle notification tap → set `AppRouter.selectedTab = .home` and `AppState.pendingAIAction = .weeklyDigest` and `AppState.showAICoach = true`
- **Important:** The existing `scheduleDailyReminders()` calls `center.removeAllPendingNotificationRequests()` which would wipe the weekly notification. Fix: change `scheduleDailyReminders()` to remove only its own notification IDs (using identifiers like `"daily_reminder_9"`, `"daily_reminder_14"`, `"daily_reminder_20"`) instead of removing all pending requests. Then call `scheduleWeeklyDigestNotification()` as a separate method.

#### `Fit Tracker/Features/Home/HomeView.swift` (Modify)
- Add a "Weekly AI Report" card that appears Sunday through Tuesday
- Card shows: sparkle icon, "Your Weekly Report is Ready", tap to open AI Coach
- Only appears if the digest has been generated for this week (check `lastWeeklyDigestDate` in UserDefaults)
- Tapping sets `AppRouter.selectedTab = .home` and `AppState.pendingAIAction = .weeklyDigest` and `AppState.showAICoach = true` — HomeView observes `appState.showAICoach` and presents the AI Coach fullScreenCover when true
- **Card ordering:** Weekly Digest card (if visible) appears above Meal Suggestion card (if visible), both above the existing calorie ring section

#### `Fit Tracker/Features/AI/AICoachViewModel.swift` (Modify)
- Add `generateWeeklyDigest()` method
- Called on app launch (Sunday-Tuesday) if digest hasn't been generated this week
- Stores the digest in UserDefaults (not in daily chat history) so it survives daily chat resets
- On `loadTodayChat()`, if within Sunday-Tuesday and a digest exists, insert it as a pinned system message at the top of the chat display (not in the persisted chat array)
- Add `showWeeklyDigest()` method triggered by `pendingAIAction == .weeklyDigest`

#### Data Dependencies
- `NutritionService.fetchLogs(from:to:)` — already exists, wraps `CoreDataService.fetchNutritionLogs(from:to:)`
- `CoreDataService.fetchWorkoutSessions(from:to:)` — already exists
- `CoreDataService.fetchProgressEntries(limit:)` — already exists
- No new CoreData methods needed

---

## Feature 2: Auto-complete Daily Meals

### User Flow
1. User opens the app in the morning
2. Home page shows a card: "Your usual breakfast?" with top 2-3 foods and total calories
3. One tap → all foods are logged to Breakfast instantly
4. Alternatively, when user opens a meal section to add food, a banner at the top says "Log your usual: Oatmeal, Coffee, Banana?" with a quick-add button
5. Card/banner only shows for meals not yet logged today

### Implementation

#### `Fit Tracker/Services/Nutrition/MealPatternService.swift` (Create)
- Analyzes last 14 days of `NutritionLog` entries via `NutritionService.fetchLogs(from:to:)`
- Groups entries by `MealType` (breakfast, lunch, dinner, snack)
- Finds foods that appear 3+ times for the same meal type
- Returns `[MealType: MealPattern]` where:
```swift
struct MealPattern {
    let mealType: MealType
    let entries: [NutritionEntry]   // The frequent food entries (with full macro data and serving quantities)
    let totalCalories: Int          // Sum of their calories
    let frequency: Int              // How many of the last 14 days this pattern appeared
}
```
- Uses `[NutritionEntry]` instead of `[FoodItem]` because entries already contain all macro data (`calories`, `proteinG`, `carbsG`, `fatG`, `foodName`) and the original `servingQuantity` — no need to look up `FoodItem` from the database
- Patterns are computed on app launch and cached in memory
- Only returns patterns with frequency >= 3 out of 14 days (eaten this meal ~20%+ of the time)

#### `Fit Tracker/Features/Home/HomeView.swift` (Modify)
- Add a "Meal Suggestion" card for the current time-appropriate meal
- Reuse `NutritionViewModel.currentMealType` for time-based meal selection (consistent with existing logic):
  - 5am-11am: Breakfast
  - 11am-3pm: Lunch
  - 3pm-5pm: Snack
  - 5pm-10pm: Dinner
  - Otherwise: Snack
- Card shows: meal icon, "Your usual [meal]?", food names (from `entry.foodName`), total calories, "Log All" button
- Only shows if: pattern exists for that meal AND meal not logged today
- Tapping "Log All" calls `NutritionViewModel.logMealPattern(pattern:)`
- **Card ordering:** Appears below Weekly Digest card (if visible), above the calorie ring section

#### `Fit Tracker/Features/Nutrition/NutritionDashboardView.swift` (Modify)
- In each meal section, add a banner at the top if a pattern exists for that meal type
- Banner: "Log your usual: [food1, food2, food3]?" with a quick-add button
- Only shows if that meal has 0 entries today
- Tapping logs all pattern foods at once

#### `Fit Tracker/Features/Nutrition/NutritionViewModel.swift` (Modify)
- Add `mealPatterns: [MealType: MealPattern]` state property
- Add `loadMealPatterns()` called on init — uses `MealPatternService` to analyze logs
- Add `logMealPattern(_ pattern: MealPattern) async` method:
  - Iterates `pattern.entries`
  - For each entry, creates a new `NutritionEntry` with a fresh `id` and `loggedAt = Date()`, preserving the original `servingQuantity`, `calories`, `proteinG`, `carbsG`, `fatG`
  - Calls `nutritionService.addEntry()` for each
  - This replays the exact historical portions the user typically eats

---

## Feature 3: Calorie Budget Advisor

### User Flow
1. In AI Coach, a suggestion chip "What should I eat?" is always visible
2. Tapping it sends a message to AI with today's remaining calories/macros automatically included
3. AI responds with 2-3 specific food suggestions that fit the remaining budget
4. On the Home page, tapping the calorie ring opens a bottom sheet showing remaining macros + "Get AI Suggestions" button
5. Tapping the button navigates to AI Coach with the question pre-filled

### Implementation

#### `Fit Tracker/Features/AI/AICoachView.swift` (Modify)
- Add a persistent suggestion chip: "What should I eat?" with a fork.knife icon
- This chip always appears (not just when `showSuggestions` is true), separate from the contextual suggestions
- Tapping it calls `viewModel.askBudgetAdvisor()`

#### `Fit Tracker/Features/AI/AICoachViewModel.swift` (Modify)
- Add `askBudgetAdvisor()` method:
  - Constructs a user message: "What should I eat? I have X kcal left, need Yg protein, Zg carbs, Wg fat"
  - Sends via normal `sendMessage()` flow — the existing system prompt already includes today's nutrition snapshot
  - AI naturally responds with suggestions because it has the context

#### `Fit Tracker/Features/Home/HomeView.swift` (Modify)
- Make the calorie ring tappable
- Tapping opens a `CalorieBudgetSheet` (bottom sheet)

#### `Fit Tracker/Features/Home/Components/CalorieBudgetSheet.swift` (Create)
- Shows remaining calories and each macro (protein, carbs, fat) with progress bars
- "Get AI Suggestions" button at the bottom
- Tapping navigates to AI Coach tab and triggers `askBudgetAdvisor()`
- Navigation mechanism (AI Coach is a `fullScreenCover` from HomeView, not a tab):
  1. Set `AppRouter.selectedTab = .home`
  2. Set `AppState.pendingAIAction = .budgetAdvisor`
  3. Set `AppState.showAICoach = true`
  4. Dismiss the sheet
- HomeView observes `appState.showAICoach` and presents the fullScreenCover when true
- AI Coach checks `pendingAIAction` on appear, triggers `askBudgetAdvisor()`, then clears it

#### `Fit Tracker/App/AppState.swift` (Modify)
- Add the `AIAction` enum directly in `AppState.swift`:
```swift
enum AIAction {
    case budgetAdvisor
    case weeklyDigest
}
```
- Add `var pendingAIAction: AIAction?` property to `AppState`
- Add `var showAICoach: Bool = false` property to `AppState` — used by HomeView to present AI Coach as a `fullScreenCover`
- AI Coach checks `pendingAIAction` on appear, triggers the appropriate action, then clears it
- HomeView binds its existing `showCoach` state to `appState.showAICoach` (or observes it in `.onChange`)

---

## Feature 4: Smart Search Ranking

### User Flow
1. User searches for food — no visible UI change
2. Results silently appear in a smarter order: frequently eaten foods first, then foods matching remaining macros, then everything else
3. Over time, search becomes personalized to the user's habits

### Implementation

#### `Fit Tracker/Services/Nutrition/FoodFrequencyTracker.swift` (Create)
- Tracks how often each food is logged
- Stored in UserDefaults as encoded dictionary, capped at 200 entries (prune least-frequent when exceeded):
```swift
struct FoodFrequency: Codable {
    var count: Int
    var lastLogged: Date
}
// Storage: [String: FoodFrequency] keyed by food name (lowercased)
```
- All methods are `@MainActor` static methods (safe since `NutritionViewModel.addEntry()` is `@MainActor`):
  - `recordFood(_ name: String)` — increment count, update date; if dictionary exceeds 200 entries, remove the entry with the lowest count
  - `frequencyMap() -> [String: FoodFrequency]` — return all tracked foods
  - `isFrequent(_ name: String) -> Bool` — count >= 3
- Called from `NutritionViewModel.addEntry()` after each successful log

#### `Fit Tracker/Services/Nutrition/SmartSearchRanker.swift` (Create)
- Pure function with explicit inputs — no dependency on ViewModel:
```swift
static func rank(
    _ results: [FoodItem],
    frequencyMap: [String: FoodFrequency],
    remainingCalories: Int,
    remainingProteinG: Int,
    remainingCarbsG: Int,
    remainingFatG: Int,
    query: String
) -> [FoodItem]
```
- Assigns a score to each result:
  - +50 points if food name matches a frequent food (count >= 3)
  - +20 points if food was logged in the last 3 days
  - +10 points if food is high in the user's most-needed macro (e.g., high protein when protein remaining is highest % gap)
  - +5 points for exact name match with search query
- Sorts results by score (descending), stable sort so ties keep original order
- Returns reordered `[FoodItem]`

#### `Fit Tracker/Features/Nutrition/NutritionViewModel.swift` (Modify)
- In `performSearch()`, after getting results from `nutritionService.searchFoods()`, pass through `SmartSearchRanker.rank()` before setting `searchResults`:
```swift
let ranked = SmartSearchRanker.rank(
    results,
    frequencyMap: FoodFrequencyTracker.frequencyMap(),
    remainingCalories: caloriesRemaining,
    remainingProteinG: targetProteinG - Int(todayLog.totalProtein),
    remainingCarbsG: targetCarbsG - Int(todayLog.totalCarbs),
    remainingFatG: targetFatG - Int(todayLog.totalFat),
    query: query
)
searchResults = ranked
```
- In `addEntry()`, call `FoodFrequencyTracker.recordFood(food.name)` after successful log

---

## HomeView Card Ordering

When multiple feature cards are visible simultaneously, they appear in this order (top to bottom):
1. **Weekly Digest card** (Feature 1) — visible Sunday through Tuesday if digest generated
2. **Meal Suggestion card** (Feature 2) — visible during meal-appropriate times if pattern exists
3. **Existing content** (calorie ring, meal sections, etc.)

All cards are in a `VStack` within the existing `ScrollView`.

---

## File Map Summary

| File | Action | Feature |
|------|--------|---------|
| `Services/AI/WeeklyDigestService.swift` | Create | #1 Weekly Digest |
| `Services/Nutrition/MealPatternService.swift` | Create | #2 Auto-complete Meals |
| `Services/Nutrition/FoodFrequencyTracker.swift` | Create | #4 Smart Search |
| `Services/Nutrition/SmartSearchRanker.swift` | Create | #4 Smart Search |
| `Features/Home/Components/CalorieBudgetSheet.swift` | Create | #3 Budget Advisor |
| `Services/Notifications/NotificationManager.swift` | Modify | #1 Weekly Digest |
| `Features/Home/HomeView.swift` | Modify | #1, #2, #3 |
| `Features/AI/AICoachView.swift` | Modify | #3 Budget Advisor |
| `Features/AI/AICoachViewModel.swift` | Modify | #1, #3 |
| `Features/Nutrition/NutritionDashboardView.swift` | Modify | #2 Auto-complete |
| `Features/Nutrition/NutritionViewModel.swift` | Modify | #2, #4 |
| `App/AppState.swift` | Modify | #3 Budget Advisor |

## Error Handling

- **Weekly digest generation fails:** Silently skip — no card shown, try again next app launch. `DecodingError` from malformed AI JSON is caught and returns nil.
- **No meal patterns found:** Don't show the suggestion card/banner — graceful absence
- **Budget advisor AI fails:** Standard AI Coach error handling (already exists)
- **Search ranking with empty frequency data:** Return results in original order (no-op for new users)
- **Notification conflict:** Weekly digest notification uses a fixed identifier and is scheduled separately from daily reminders, avoiding the `removeAllPendingNotificationRequests()` conflict

## Success Criteria

- Weekly digest appears in AI Coach every Sunday with personalized insights, persists through Tuesday even across daily chat resets
- Notification fires on Sunday and tapping it opens the report
- Meal suggestion card appears at appropriate times and one-tap logs all foods with original portions
- "What should I eat?" chip in AI Coach gives macro-aware food suggestions
- Tapping calorie ring shows remaining budget with AI suggestion option
- Search results feel personalized after 1-2 weeks of usage
- All features degrade gracefully for new users with no history
- FoodFrequencyTracker stays bounded at 200 entries maximum
