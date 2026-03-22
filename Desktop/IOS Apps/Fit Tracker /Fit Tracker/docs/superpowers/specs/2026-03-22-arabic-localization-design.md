# Arabic Localization Design Spec

## Context

FuelIQ is currently 100% English with 534+ hardcoded UI strings across 97 feature files. No localization infrastructure exists. The goal is to add full Arabic language support with an in-app language switcher, RTL layout, and Arabic AI responses.

## Architecture

### String Catalog (.xcstrings)

Use Xcode's modern String Catalog format. A single `Localizable.xcstrings` file (JSON) holds all translations keyed by the English source string. SwiftUI `Text("...")` views automatically look up translations at runtime — no code changes needed beyond ensuring strings go through the localization system.

### LanguageManager

A singleton `@Observable` class stored via `AppStorage`:

```swift
@Observable
final class LanguageManager {
    static let shared = LanguageManager()

    @AppStorage("appLanguage") var currentLanguage: String = "en"

    var locale: Locale { Locale(identifier: currentLanguage) }
    var layoutDirection: LayoutDirection {
        currentLanguage == "ar" ? .rightToLeft : .leftToRight
    }
    var isArabic: Bool { currentLanguage == "ar" }
}
```

Applied at the root level in `AppRootView`:

```swift
.environment(\.locale, LanguageManager.shared.locale)
.environment(\.layoutDirection, LanguageManager.shared.layoutDirection)
```

### Language Selection UI

A row in the existing Settings/Profile screen:

```
Language / اللغة
[English 🇬🇧]  [العربية 🇸🇦]
```

Tapping a language updates `LanguageManager.currentLanguage`. The `.id(languageManager.currentLanguage)` modifier on `AppRootView` forces a full view rebuild (same pattern used for theme switching with `.id(appTheme)`).

### RTL Support

SwiftUI handles RTL automatically when `.environment(\.layoutDirection, .rightToLeft)` is set:
- `HStack` reverses child order
- `leading`/`trailing` alignment swaps
- Padding `.leading`/`.trailing` swaps
- `NavigationStack` back button moves to right

**Manual fixes needed for:**
- Custom shapes with hardcoded left/right positioning (e.g., `UnevenRoundedRectangle` corner radii)
- Charts/graphs with hardcoded axis positioning
- Icons that have directional meaning (e.g., `arrow.right` → `arrow.left`)
- The gradient accent directions in coach bubbles

### AI Responses in Arabic

All AI service system prompts append a language instruction based on `LanguageManager.shared.currentLanguage`:

```
"IMPORTANT: Always respond in Arabic." // when ar
```

**Affected services (5 files):**
- `AICoachService.swift` — chat responses
- `RecoveryAdvisorService.swift` — recovery assessment message
- `WeeklyDigestService.swift` — digest highlights and insights
- `MealPlanService.swift` — meal names and descriptions
- `AIFoodParserService.swift` — parsed food names

## String Categories

| Category | Count | Examples |
|----------|-------|---------|
| Labels & headings | ~150 | "Daily Intake", "Recovery Advisor", "Protein" |
| Buttons & actions | ~80 | "Accept", "Save", "Start Workout" |
| Descriptions & messages | ~120 | "Complete a workout and log some food..." |
| Units & formatting | ~40 | "kcal", "g", "kg", "min" |
| Interpolated strings | ~80 | "\(value) remaining", "\(count) exercises" |
| System/placeholder | ~64 | "Ask your coach anything...", "Search foods..." |

### Interpolated String Handling

Strings with variables use Swift's `String(localized:)` with interpolation:

```swift
// Before
Text("\(consumed) of \(target) kcal")

// After
Text(String(localized: "\(consumed) of \(target) kcal"))
```

Arabic translation in `.xcstrings`:
```
"\(consumed) من \(target) سعرة"
```

### Plural Handling

Strings with counts use `.stringsdict` or String Catalog plural rules:

```
"1 exercise" → "تمرين واحد"
"2 exercises" → "تمرينان" (dual)
"3-10 exercises" → "٣ تمارين" (few)
"11+ exercises" → "١١ تمريناً" (many)
```

Arabic has 6 plural categories (zero, one, two, few, many, other) vs English's 2 (one, other).

## Implementation Phases

### Phase 1: Infrastructure
- Create `Localizable.xcstrings` with English + Arabic
- Create `LanguageManager.swift`
- Add language selector to Settings/Profile
- Apply `.environment(\.locale)` and `.environment(\.layoutDirection)` at root
- Add `.id(languageManager.currentLanguage)` for full rebuild on switch

### Phase 2: Auth + Home + Navigation (~160 strings)
- `SplashView.swift` — "FuelIQ", "Eat Smart · Train Hard"
- `LoginView.swift` — "FUELIQ", "ELITE", login buttons
- `WelcomeView.swift` — branding text
- `OnboardingContainerView.swift` + steps — all onboarding text
- `HomeView.swift` — greeting, cards, section headers
- `AuraFloatingNavBar.swift` — tab labels
- `MainTabView.swift` — quick action sheets

### Phase 3: Nutrition + Workout (~214 strings)
- `NutritionDashboardView.swift` — macro labels, meal sections
- `FoodSearchView.swift` — search placeholder, results
- `FoodDetailView.swift` — nutrition labels
- `WorkoutDashboardView.swift` — workout cards, stats
- `ActiveWorkoutView.swift` — exercise labels, timer
- `WorkoutPlanView.swift` — plan management

### Phase 4: Remaining Screens (~160 strings)
- `AICoachView.swift` — suggestions, input placeholder
- `ProfileView.swift` — settings labels
- `ProgressDashboardView.swift` — charts, analytics
- `PaywallView.swift` — subscription text
- `FastingView.swift` — fasting labels
- `RecipeView.swift` — recipe browsing

### Phase 5: AI + RTL Polish
- Add language parameter to all 5 AI service prompts
- Fix RTL-specific layout issues (custom shapes, directional icons)
- Test full app flow in Arabic
- Fix any truncation or overflow issues with Arabic text (tends to be wider)

## Files to Create

| File | Purpose |
|------|---------|
| `Fit Tracker/Common/Localization/LanguageManager.swift` | Language state management |
| `Fit Tracker/Localizable.xcstrings` | String Catalog with en + ar |

## Files to Modify

| File | Change |
|------|--------|
| `AppRootView.swift` (or equivalent) | Add locale/layoutDirection environment |
| `ProfileView.swift` or Settings | Add language selector UI |
| 97 feature view files | Replace hardcoded strings with localized keys |
| 5 AI service files | Add language parameter to prompts |

## Verification

1. Switch to Arabic in Settings → all UI text changes to Arabic
2. Layout mirrors to RTL (navigation, alignment, padding)
3. Switch back to English → everything returns to normal
4. AI Coach responds in Arabic when Arabic is selected
5. Recovery Advisor, Weekly Digest, Meal Plans all respond in Arabic
6. No truncation or overflow in Arabic text
7. Build succeeds with zero warnings
