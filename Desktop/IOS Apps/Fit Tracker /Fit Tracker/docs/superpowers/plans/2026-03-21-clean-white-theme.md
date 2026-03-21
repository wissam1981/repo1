# Clean White Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a 5th "Clean White" light theme to the existing 4 dark themes, making every view legible and stylish on a white background.

**Architecture:** Add `.cleanWhite` case to `AppTheme`, extend every `ThemeColors` switch with light-mode values, add `textPrimary`/`textSecondary`/`surfaceBorder`/`surfaceShadow` tokens, then migrate ~50 view files from hardcoded `.white` text to theme-aware tokens. The existing `.id(appTheme)` redraw trigger handles re-rendering automatically.

**Tech Stack:** SwiftUI, UIKit (GlassView blur), UserDefaults (`@AppStorage`)

---

### Task 1: Theme System Core (AppTheme + ThemeColors)

**Files:**
- Modify: `Fit Tracker/Common/Theme/AppTheme.swift`
- Modify: `Fit Tracker/Common/Theme/ThemeColors.swift`

This is the foundation — **all other tasks depend on it**. Complete this entire task before starting any other task.

**Note:** Do NOT remove the existing `static let backgroundLight` property — it is unused but kept for compatibility.

- [ ] **Step 1: Add `.cleanWhite` case to AppTheme enum**

In `Fit Tracker/Common/Theme/AppTheme.swift`, add the new case and `isLightTheme` property:

```swift
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
```

- [ ] **Step 2: Add `.cleanWhite` case to every switch in ThemeColors**

In `Fit Tracker/Common/Theme/ThemeColors.swift`, add `case .cleanWhite:` to each existing switch:

**`primary`:**
```swift
case .cleanWhite: return Color(hex: "#0ea5e9")   // Sky blue (same as Ocean Blue)
```

**`backgroundDark`:**
```swift
case .cleanWhite: return Color(hex: "#F5F7FA")   // Cool light gray
```

**`primaryDark`:**
```swift
case .cleanWhite: return Color(hex: "#0284c7")   // Darker sky blue
```

**`secondary`:**
```swift
case .cleanWhite: return Color(hex: "#E8F4FD")   // Light blue tint
```

- [ ] **Step 3: Add new text color tokens to ThemeColors**

Add these new computed properties:

```swift
// MARK: - Text Colors (Theme-aware)

static var textPrimary: Color {
    switch ThemeManager.shared.currentTheme {
    case .cleanWhite: return Color(hex: "#1a1a1a")
    default: return .white
    }
}

static var textSecondary: Color {
    switch ThemeManager.shared.currentTheme {
    case .cleanWhite: return Color(hex: "#767676")  // 4.5:1 WCAG AA on white
    default: return .white.opacity(0.5)
    }
}
```

- [ ] **Step 4: Make semantic colors theme-aware**

Change `success`, `error`, `info` from `static let` to `static var` with switches. The Clean White values achieve ~3-4:1 contrast on white — acceptable because these colors are used exclusively for bold indicators, badges, and progress rings, never for small body text:

```swift
static var success: Color {
    switch ThemeManager.shared.currentTheme {
    case .cleanWhite: return Color(hex: "#10b981")  // Emerald (readable on white)
    default: return Color(hex: "#0df28a")            // Mint green (existing)
    }
}

static var error: Color {
    switch ThemeManager.shared.currentTheme {
    case .cleanWhite: return Color(hex: "#ef4444")   // Red (readable on white)
    default: return Color(hex: "#f43f5e")            // Rose 500 (existing)
    }
}

static var info: Color {
    switch ThemeManager.shared.currentTheme {
    case .cleanWhite: return Color(hex: "#06b6d4")   // Darker cyan (readable on white)
    default: return Color(hex: "#0df2d8")            // Cyan (existing)
    }
}
```

- [ ] **Step 5: Make surfaceColor a computed var and add surface helpers**

Change `surfaceColor` from `static let` to `static var`:

```swift
static var surfaceColor: Color {
    switch ThemeManager.shared.currentTheme {
    case .cleanWhite: return .white
    default: return Color.white.opacity(0.1)
    }
}

static var surfaceBorder: Color {
    switch ThemeManager.shared.currentTheme {
    case .cleanWhite: return Color(hex: "#0ea5e9").opacity(0.08)
    default: return Color.white.opacity(0.06)
    }
}

static var surfaceShadow: Color {
    switch ThemeManager.shared.currentTheme {
    case .cleanWhite: return Color.black.opacity(0.06)
    default: return Color.clear
    }
}
```

- [ ] **Step 6: Update primaryGradient**

```swift
static var primaryGradient: LinearGradient {
    switch ThemeManager.shared.currentTheme {
    case .cleanWhite:
        return LinearGradient(
            colors: [Color(hex: "#0ea5e9"), Color(hex: "#0284c7")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    default:
        return LinearGradient(
            colors: [primary, Color(hex: "#2E7D32")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
```

- [ ] **Step 7: Build and verify**

```bash
xcodebuild -scheme "Fit Tracker" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: Commit**

```bash
git add "Fit Tracker/Common/Theme/AppTheme.swift" "Fit Tracker/Common/Theme/ThemeColors.swift"
git commit -m "feat: add Clean White theme to AppTheme and ThemeColors"
```

---

### Task 2: GlassView + AuraFloatingNavBar + Color Scheme

**Files:**
- Modify: `Fit Tracker/Common/Components/GlassView.swift`
- Modify: `Fit Tracker/Navigation/AuraFloatingNavBar.swift`
- Modify: `Fit Tracker/Navigation/MainTabView.swift` (preferredColorScheme only)
- Modify: `Fit Tracker/Features/Onboarding/OnboardingContainerView.swift` (preferredColorScheme only)

- [ ] **Step 1: Update GlassView blur style**

In `GlassView.swift`, find `UIBlurEffect(style: .systemThinMaterialDark)` and replace with:

```swift
let blurStyle: UIBlurEffect.Style = ThemeManager.shared.currentTheme.isLightTheme
    ? .systemThinMaterial
    : .systemThinMaterialDark
let blurView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
```

Also update the border stroke from `Color.white.opacity(0.1)` to `ThemeColors.surfaceBorder`.

- [ ] **Step 2: Update AuraFloatingNavBar**

Find the `.glassStyle(cornerRadius: 32, color: .white.opacity(0.12))` call. For Clean White, use a solid white background with shadow instead:

```swift
.glassStyle(
    cornerRadius: 32,
    color: ThemeManager.shared.currentTheme.isLightTheme
        ? Color.white.opacity(0.95)
        : Color.white.opacity(0.12)
)
```

Update inactive tab icon colors from `.white.opacity(0.4)` to `ThemeColors.textSecondary`.

Update any `.foregroundStyle(.white)` on tab labels to `ThemeColors.textPrimary`.

- [ ] **Step 3: Update preferredColorScheme in MainTabView**

In `MainTabView.swift`, find `.preferredColorScheme(.dark)` and replace with:

```swift
.preferredColorScheme(ThemeManager.shared.currentTheme.isLightTheme ? .light : .dark)
```

- [ ] **Step 4: Update preferredColorScheme in OnboardingContainerView**

In `OnboardingContainerView.swift`, find `.preferredColorScheme(.dark)` and replace with:

```swift
.preferredColorScheme(ThemeManager.shared.currentTheme.isLightTheme ? .light : .dark)
```

- [ ] **Step 5: Build and verify**

```bash
xcodebuild -scheme "Fit Tracker" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

- [ ] **Step 6: Commit**

```bash
git add "Fit Tracker/Common/Components/GlassView.swift" "Fit Tracker/Navigation/AuraFloatingNavBar.swift" "Fit Tracker/Navigation/MainTabView.swift" "Fit Tracker/Features/Onboarding/OnboardingContainerView.swift"
git commit -m "feat: update glass effect and color scheme for Clean White theme"
```

---

### Task 3: MainTabView Internal Views (QuickActionsSheet + QuickWaterSheet)

**Files:**
- Modify: `Fit Tracker/Navigation/MainTabView.swift`

The `QuickActionsSheet` and `QuickWaterSheet` are private structs inside MainTabView with dense hardcoded white text.

- [ ] **Step 1: Update QuickActionsSheet**

Replace all `.foregroundStyle(.white)` with `.foregroundStyle(ThemeColors.textPrimary)`.
Replace all `.foregroundStyle(.white.opacity(0.5))` or similar with `.foregroundStyle(ThemeColors.textSecondary)`.
Replace `Color.white.opacity(0.04/0.05/0.06)` card backgrounds with `ThemeColors.surfaceColor` / `ThemeColors.surfaceBorder`.

- [ ] **Step 2: Update QuickWaterSheet**

Same pattern — replace hardcoded white text and opacity backgrounds.

- [ ] **Step 3: Build and commit**

```bash
xcodebuild -scheme "Fit Tracker" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
git add "Fit Tracker/Navigation/MainTabView.swift"
git commit -m "feat: theme-aware colors in QuickActionsSheet and QuickWaterSheet"
```

---

### Task 4: Home View + Home Components (~16 files)

**Files:**
- Modify: `Fit Tracker/Features/Home/HomeView.swift`
- Modify: `Fit Tracker/Features/Home/Components/CalorieMainCard.swift`
- Modify: `Fit Tracker/Features/Home/Components/CalorieRingView.swift`
- Modify: `Fit Tracker/Features/Home/Components/CalorieWeeklyCard.swift`
- Modify: `Fit Tracker/Features/Home/Components/CalorieDeficitCard.swift`
- Modify: `Fit Tracker/Features/Home/Components/CalorieBudgetSheet.swift`
- Modify: `Fit Tracker/Features/Home/Components/MacroBreakdownCard.swift`
- Modify: `Fit Tracker/Features/Home/Components/MacroLinearCards.swift`
- Modify: `Fit Tracker/Features/Home/Components/MacroSummaryCard.swift`
- Modify: `Fit Tracker/Features/Home/Components/MealBreakdownCard.swift`
- Modify: `Fit Tracker/Features/Home/Components/GoalProgressCard.swift`
- Modify: `Fit Tracker/Features/Home/Components/WeeklyReportCard.swift`
- Modify: `Fit Tracker/Features/Home/Components/WeeklyHabitsCard.swift`
- Modify: `Fit Tracker/Features/Home/Components/TodayWorkoutCard.swift`
- Modify: `Fit Tracker/Features/Home/Components/TodayWorkoutSlide.swift`
- Modify: `Fit Tracker/Features/Home/Components/WorkoutPlansSlide.swift`
- Modify: `Fit Tracker/Features/Home/Components/WorkoutConsistencySlide.swift`
- Modify: `Fit Tracker/Features/Home/Components/WeightSnapshotCard.swift`
- Modify: `Fit Tracker/Features/Home/Components/FastingQuickCard.swift`
- Modify: `Fit Tracker/Features/Home/Components/AICoachingCard.swift`

Apply these replacements across all files:

| Find | Replace With | When |
|------|-------------|------|
| `.foregroundStyle(.white)` | `.foregroundStyle(ThemeColors.textPrimary)` | Text on themed background |
| `.foregroundColor(.white)` | `.foregroundColor(ThemeColors.textPrimary)` | Older API, same rule |
| `.foregroundStyle(.white.opacity(0.3))` through `.opacity(0.6)` | `.foregroundStyle(ThemeColors.textSecondary)` | Secondary/tertiary text |
| `Color.white.opacity(0.04)` through `0.12` (card backgrounds) | `ThemeColors.surfaceColor` | Card/section backgrounds |
| `Color.white.opacity(0.06)` (borders) | `ThemeColors.surfaceBorder` | Card borders/strokes |

**Exception:** Do NOT replace `.foregroundStyle(.white)` when it's on a colored fill (e.g., text on a `ThemeColors.primary` button). White on a blue button is correct in both themes.

- [ ] **Step 1: Update HomeView.swift** — replace ~21 white foreground + ~8 opacity references
- [ ] **Step 2: Update all CalorieXxx cards** (CalorieMainCard, CalorieRingView, CalorieWeeklyCard, CalorieDeficitCard, CalorieBudgetSheet)
- [ ] **Step 3: Update all MacroXxx cards** (MacroBreakdownCard, MacroLinearCards, MacroSummaryCard)
- [ ] **Step 4: Update remaining Home components** (MealBreakdownCard, GoalProgressCard, WeeklyReportCard, WeeklyHabitsCard, TodayWorkoutCard, TodayWorkoutSlide, WorkoutPlansSlide, WorkoutConsistencySlide, WeightSnapshotCard, FastingQuickCard, AICoachingCard)
- [ ] **Step 5: Build and verify**
- [ ] **Step 6: Commit**

```bash
git add "Fit Tracker/Features/Home/"
git commit -m "feat: theme-aware colors for Home view and all Home components"
```

---

### Task 5: Nutrition Views (~8 files)

**Files:**
- Modify: `Fit Tracker/Features/Nutrition/NutritionDashboardView.swift`
- Modify: `Fit Tracker/Features/Nutrition/NutritionDetailView.swift`
- Modify: `Fit Tracker/Features/Nutrition/AIParsedMealSheet.swift`
- Modify: `Fit Tracker/Features/Nutrition/FoodSearchView.swift`
- Modify: `Fit Tracker/Features/Nutrition/FoodDetailView.swift`
- Modify: `Fit Tracker/Features/Nutrition/FoodScannerView.swift`
- Modify: `Fit Tracker/Features/Nutrition/Components/RecipeListView.swift`
- Modify: `Fit Tracker/Features/Nutrition/Components/RecipeBuilderView.swift`
- Modify: `Fit Tracker/Features/Nutrition/Components/NutritionAnalyticsView.swift`
- Modify: `Fit Tracker/Features/Nutrition/Components/WaterTrackerView.swift`

Same replacement rules as Task 4.

- [ ] **Step 1: Update NutritionDashboardView and NutritionDetailView**
- [ ] **Step 2: Update AIParsedMealSheet and FoodScannerView** (9-10 occurrences each)
- [ ] **Step 3: Update FoodSearchView, FoodDetailView, and Nutrition Components**
- [ ] **Step 4: Build and verify**
- [ ] **Step 5: Commit**

```bash
git add "Fit Tracker/Features/Nutrition/"
git commit -m "feat: theme-aware colors for Nutrition views"
```

---

### Task 6: AI Coach + Workout Views (~10 files)

**Files:**
- Modify: `Fit Tracker/Features/AI/AICoachView.swift`
- Modify: `Fit Tracker/Features/Workout/WorkoutDashboardView.swift`
- Modify: `Fit Tracker/Features/Workout/CreateWorkoutView.swift`
- Modify: `Fit Tracker/Features/Workout/ActiveWorkoutView.swift`
- Modify: `Fit Tracker/Features/Workout/WorkoutPlanListView.swift`
- Modify: `Fit Tracker/Features/Workout/ExerciseSelectionView.swift`
- Modify: `Fit Tracker/Features/Workout/Components/WorkoutImageCard.swift`
- Modify: `Fit Tracker/Features/Workout/Components/ExerciseGifViewer.swift`
- Modify: `Fit Tracker/Features/Workout/EquipmentGuideView.swift`

`WorkoutDashboardView` is the heaviest file (~48 combined occurrences). `AICoachView` has ~20.

- [ ] **Step 1: Update AICoachView** — 7 foreground + 13 opacity
- [ ] **Step 2: Update WorkoutDashboardView** — 26 foreground + 22 opacity (largest file)
- [ ] **Step 3: Update remaining Workout views** (CreateWorkoutView, ActiveWorkoutView, WorkoutPlanListView, ExerciseSelectionView, components)
- [ ] **Step 4: Build and verify**
- [ ] **Step 5: Commit**

```bash
git add "Fit Tracker/Features/AI/" "Fit Tracker/Features/Workout/"
git commit -m "feat: theme-aware colors for AI Coach and Workout views"
```

---

### Task 7: Profile, Progress, Recipes, Fasting, Subscription (~10 files)

**Files:**
- Modify: `Fit Tracker/Features/Profile/ProfileView.swift`
- Modify: `Fit Tracker/Features/Progress/AdvancedAnalyticsView.swift`
- Modify: `Fit Tracker/Features/Progress/ProgressDashboardView.swift`
- Modify: `Fit Tracker/Features/Progress/Components/WeightEntrySheet.swift`
- Modify: `Fit Tracker/Features/Progress/Components/WeightGraphView.swift`
- Modify: `Fit Tracker/Features/Recipes/RecipeDetailView.swift`
- Modify: `Fit Tracker/Features/Recipes/RecipeBrowserView.swift`
- Modify: `Fit Tracker/Features/Recipes/Components/RecipeCardView.swift`
- Modify: `Fit Tracker/Features/Fasting/FastingView.swift`
- Modify: `Fit Tracker/Features/Fasting/FastingWidgetView.swift`
- Modify: `Fit Tracker/Features/Subscription/PaywallView.swift`
- Modify: `Fit Tracker/Features/Shared/ErrorBannerModifier.swift`
- Modify: `Fit Tracker/Features/Challenge/DailyChallengeWidget.swift`

- [ ] **Step 1: Update ProfileView** — 18 foreground + 9 opacity (heavy file)
- [ ] **Step 2: Update Progress views** (AdvancedAnalyticsView is heaviest — 18 surfaceColor + 18 opacity + 6 foreground)
- [ ] **Step 3: Update Recipes views**
- [ ] **Step 4: Update Fasting, Subscription, Shared, Challenge views**
- [ ] **Step 5: Build and verify**
- [ ] **Step 6: Commit**

```bash
git add "Fit Tracker/Features/Profile/" "Fit Tracker/Features/Progress/" "Fit Tracker/Features/Recipes/" "Fit Tracker/Features/Fasting/" "Fit Tracker/Features/Subscription/" "Fit Tracker/Features/Shared/" "Fit Tracker/Features/Challenge/"
git commit -m "feat: theme-aware colors for Profile, Progress, Recipes, Fasting, and remaining views"
```

---

### Task 8: Final Verification + Theme Picker Polish

**Files:**
- Possibly modify: `Fit Tracker/Features/Profile/ProfileView.swift` (theme picker section)

- [ ] **Step 1: Full build verification**

```bash
xcodebuild -scheme "Fit Tracker" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

- [ ] **Step 2: Grep for remaining hardcoded white issues**

Search for any remaining `.foregroundStyle(.white)` or `Color.white.opacity(` that were missed (excluding auth/onboarding out-of-scope files):

```bash
grep -rn "\.foregroundStyle(\.white)" "Fit Tracker/Features/" --include="*.swift" | grep -v "Auth/" | grep -v "Onboarding/"
grep -rn "Color\.white\.opacity(" "Fit Tracker/Features/" --include="*.swift" | grep -v "Auth/" | grep -v "Onboarding/"
```

Fix any remaining occurrences. Some may be intentional (white text on colored buttons) — verify each one.

- [ ] **Step 3: Optionally enhance theme picker with preview colors**

The theme picker in ProfileView (`AppearanceSettingsView`) currently shows just text labels. Consider adding a small color dot next to each theme name showing the primary color, so "Clean White" has a visual identity in the list. This is optional polish.

- [ ] **Step 4: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: remaining white theme color fixes from final audit"
```
