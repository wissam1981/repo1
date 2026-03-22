# Arabic Localization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add full Arabic language support to FuelIQ with in-app language switcher, RTL layout, and Arabic AI responses across all 534+ UI strings.

**Architecture:** Xcode String Catalog (`.xcstrings`) holds all translations keyed by English source strings. A `LanguageManager` singleton (following the existing `ThemeManager` pattern) persists the user's language choice and propagates it via SwiftUI environment modifiers at the app root. AI services append a language directive to their system prompts.

**Tech Stack:** SwiftUI String Catalog, `@Observable` LanguageManager, `AppStorage`, SwiftUI `.environment(\.locale)` / `.environment(\.layoutDirection)`

**Spec:** `docs/superpowers/specs/2026-03-22-arabic-localization-design.md`

---

## File Structure

### Files to Create
| File | Responsibility |
|------|---------------|
| `Fit Tracker/Common/Localization/LanguageManager.swift` | Language state singleton — stores language preference, exposes `locale`, `layoutDirection`, `isArabic` |
| `Fit Tracker/Localizable.xcstrings` | String Catalog with `en` (source) + `ar` translations for all 534+ strings |

### Files to Modify
| File | Change |
|------|--------|
| `Fit Tracker/Fit_TrackerApp.swift` | Add locale/layoutDirection environment + `.id(language)` at root (line ~82) |
| `Fit Tracker/Features/Profile/ProfileView.swift` | Add Language selector row in settings section (line ~265) |
| ~97 feature view files | Convert interpolated strings to `String(localized:)` |
| 5 AI service files | Append language directive to system prompts |

---

## Task 1: Infrastructure — LanguageManager + String Catalog + Root Setup

**Files:**
- Create: `Fit Tracker/Common/Localization/LanguageManager.swift`
- Create: `Fit Tracker/Localizable.xcstrings`
- Modify: `Fit Tracker/Fit_TrackerApp.swift:67-85`

- [ ] **Step 1: Create LanguageManager.swift**

Follow the `ThemeManager` pattern at `Fit Tracker/Common/Theme/AppTheme.swift:26-48`.

```swift
import SwiftUI
import Observation

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

// MARK: - Language Manager

@Observable
final class LanguageManager {
    static let shared = LanguageManager()

    @ObservationIgnored
    private let defaults = UserDefaults.standard

    private let languageKey = "appLanguage"

    var currentLanguage: AppLanguage {
        get {
            let saved = defaults.string(forKey: languageKey) ?? AppLanguage.english.rawValue
            return AppLanguage(rawValue: saved) ?? .english
        }
        set {
            defaults.set(newValue.rawValue, forKey: languageKey)
        }
    }

    var locale: Locale { Locale(identifier: currentLanguage.rawValue) }

    var layoutDirection: LayoutDirection {
        currentLanguage == .arabic ? .rightToLeft : .leftToRight
    }

    var isArabic: Bool { currentLanguage == .arabic }

    private init() {}
}
```

- [ ] **Step 2: Create initial Localizable.xcstrings**

Create the String Catalog JSON file with English as the source language and Arabic as a target. Start with a small set of strings to validate the infrastructure — the remaining tasks will populate it fully.

```json
{
  "sourceLanguage" : "en",
  "strings" : {
    "AI Fit Coach" : {
      "localizations" : {
        "ar" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "مدرب اللياقة الذكي"
          }
        }
      }
    },
    "Online" : {
      "localizations" : {
        "ar" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "متصل"
          }
        }
      }
    }
  },
  "version" : "1.0"
}
```

- [ ] **Step 3: Wire up AppRootView**

In `Fit Tracker/Fit_TrackerApp.swift`, find `struct AppRootView` (line ~67). Add a language property and environment modifiers.

Add property at line ~74 (after `@AppStorage("appTheme")`):
```swift
@State private var languageManager = LanguageManager.shared
```

Add environment modifiers at line ~82 (after `.id(appTheme)`):
```swift
.environment(\.locale, languageManager.locale)
.environment(\.layoutDirection, languageManager.layoutDirection)
.id("\(appTheme)-\(languageManager.currentLanguage.rawValue)")
```

Note: Combine theme and language into a single `.id()` so switching either forces a full rebuild.

- [ ] **Step 4: Build and verify**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && xcodebuild -scheme "Fit Tracker" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && git add "Fit Tracker/Common/Localization/LanguageManager.swift" "Fit Tracker/Localizable.xcstrings" "Fit Tracker/Fit_TrackerApp.swift" && git commit -m "feat: add localization infrastructure — LanguageManager + String Catalog

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 2: Language Selector UI in ProfileView

**Files:**
- Modify: `Fit Tracker/Features/Profile/ProfileView.swift:253-289`

- [ ] **Step 1: Add language selector row**

In `ProfileView.swift`, find the settings section (line ~253). After the Appearance `NavigationLink` (line ~265) and its divider, add a Language row. Follow the existing `settingsRow` pattern used for Appearance/Notifications/Units.

Add a language picker row that shows the current language and lets the user tap to switch:

```swift
// Language selector — after the Appearance row divider
Button {
    withAnimation(.spring(response: 0.3)) {
        LanguageManager.shared.currentLanguage =
            LanguageManager.shared.isArabic ? .english : .arabic
    }
} label: {
    HStack(spacing: 14) {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 32, height: 32)
            Image(systemName: "globe")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
        }

        Text("Language")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(ThemeColors.textPrimary)

        Spacer()

        Text("\(LanguageManager.shared.currentLanguage.flag) \(LanguageManager.shared.currentLanguage.displayName)")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(ThemeColors.textSecondary)

        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(ThemeColors.textSecondary)
    }
}

Divider().background(ThemeColors.surfaceBorder).padding(.leading, 48)
```

- [ ] **Step 2: Build and verify**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && xcodebuild -scheme "Fit Tracker" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && git add "Fit Tracker/Features/Profile/ProfileView.swift" && git commit -m "feat: add language switcher to Profile settings

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 3: Localize Auth + Onboarding Views (~30 strings)

**Files:**
- Modify: `Fit Tracker/Features/Auth/SplashView.swift`
- Modify: `Fit Tracker/Features/Auth/LoginView.swift`
- Modify: `Fit Tracker/Features/Auth/WelcomeView.swift`
- Modify: `Fit Tracker/Features/Auth/SignUpView.swift`
- Modify: `Fit Tracker/Features/Onboarding/OnboardingContainerView.swift`
- Modify: `Fit Tracker/Features/Onboarding/Steps/*.swift` (all onboarding step files)
- Modify: `Fit Tracker/Localizable.xcstrings`

- [ ] **Step 1: Extract all strings from Auth + Onboarding views**

Read every file listed above. For each `Text("...")`, extract the English string. For interpolated strings like `Text("\(value) something")`, convert to `Text(String(localized: "\(value) something"))`.

- [ ] **Step 2: Add Arabic translations to Localizable.xcstrings**

Add every extracted string to the `.xcstrings` file with its Arabic translation. Key translations for Auth:

| English | Arabic |
|---------|--------|
| "FuelIQ" | "FuelIQ" (keep brand name) |
| "FUELIQ" | "FUELIQ" (keep brand name) |
| "ELITE" | "ELITE" (keep English) |
| "Eat Smart · Train Hard" | "كُل بذكاء · تمرّن بقوة" |
| "Sign in with Apple" | "تسجيل الدخول بحساب Apple" |
| "Sign in with Google" | "تسجيل الدخول بحساب Google" |
| "Continue with Email" | "المتابعة بالبريد الإلكتروني" |
| "Welcome" | "مرحباً" |
| "Create Account" | "إنشاء حساب" |
| "Already have an account?" | "لديك حساب بالفعل؟" |
| "Log In" | "تسجيل الدخول" |

Key translations for Onboarding:

| English | Arabic |
|---------|--------|
| "What's your goal?" | "ما هو هدفك؟" |
| "Lose Weight" | "إنقاص الوزن" |
| "Gain Muscle" | "بناء العضلات" |
| "Maintain" | "المحافظة على الوزن" |
| "How active are you?" | "ما مستوى نشاطك؟" |
| "Sedentary" | "قليل الحركة" |
| "Lightly Active" | "نشاط خفيف" |
| "Moderately Active" | "نشاط متوسط" |
| "Very Active" | "نشاط عالي" |
| "Next" | "التالي" |
| "Back" | "رجوع" |
| "Continue" | "متابعة" |

- [ ] **Step 3: Convert interpolated strings in the view files**

Any `Text("string with \(variable)")` must be changed to `Text(String(localized: "string with \(variable)"))` so the String Catalog can match and translate it.

- [ ] **Step 4: Build and verify**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && xcodebuild -scheme "Fit Tracker" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

- [ ] **Step 5: Commit**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && git add "Fit Tracker/Features/Auth/" "Fit Tracker/Features/Onboarding/" "Fit Tracker/Localizable.xcstrings" && git commit -m "feat: localize Auth and Onboarding views (en + ar)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 4: Localize Home + Navigation (~80 strings)

**Files:**
- Modify: `Fit Tracker/Features/Home/HomeView.swift` (~31 strings)
- Modify: `Fit Tracker/Features/Home/Components/CalorieRingView.swift` (~11 strings)
- Modify: `Fit Tracker/Features/Home/Components/WeeklyReportCard.swift` (~10 strings)
- Modify: `Fit Tracker/Features/Home/Components/InstructionsView.swift` (~21 strings)
- Modify: `Fit Tracker/Features/Home/Components/CustomHeader.swift`
- Modify: `Fit Tracker/Features/Home/Components/DailyChallengeCard.swift`
- Modify: `Fit Tracker/Navigation/MainTabView.swift`
- Modify: `Fit Tracker/Navigation/AuraFloatingNavBar.swift`
- Modify: `Fit Tracker/Localizable.xcstrings`

- [ ] **Step 1: Extract all strings from Home + Navigation views**

Read every file listed above. Extract all `Text("...")` strings. Convert interpolated strings to `String(localized:)`.

- [ ] **Step 2: Add Arabic translations to Localizable.xcstrings**

Key translations for Home:

| English | Arabic |
|---------|--------|
| "Daily Intake" | "المدخول اليومي" |
| "Remaining" | "المتبقي" |
| "Eaten" | "المستهلك" |
| "Protein" | "بروتين" |
| "Carbs" | "كربوهيدرات" |
| "Fat" | "دهون" |
| "kcal" | "سعرة" |
| "Recovery Advisor" | "مستشار الاستشفاء" |
| "Score" | "النتيجة" |
| "Weekly Habits" | "العادات الأسبوعية" |
| "Weekly Report" | "التقرير الأسبوعي" |
| "Goal Adjustment" | "تعديل الهدف" |
| "Accept" | "قبول" |
| "Good Morning" | "صباح الخير" |
| "Good Afternoon" | "مساء الخير" |
| "Good Evening" | "مساء الخير" |
| "Good Night" | "تصبح على خير" |

Key translations for Navigation:

| English | Arabic |
|---------|--------|
| "Home" | "الرئيسية" |
| "Nutrition" | "التغذية" |
| "Workout" | "التمرين" |
| "Progress" | "التقدم" |
| "Profile" | "الملف الشخصي" |

**Important:** The greeting in `HomeViewModel.swift` uses `makeGreeting(name:)` at line ~426. This function also needs localization — change to use `String(localized:)`:

```swift
private static func makeGreeting(name: String) -> String {
    let hour = Calendar.current.component(.hour, from: .now)
    let firstName = name.components(separatedBy: " ").first ?? name
    switch hour {
    case 5..<12:  return String(localized: "Good Morning, \(firstName)")
    case 12..<17: return String(localized: "Good Afternoon, \(firstName)")
    case 17..<21: return String(localized: "Good Evening, \(firstName)")
    default:      return String(localized: "Good Night, \(firstName)")
    }
}
```

- [ ] **Step 3: Build and verify**

- [ ] **Step 4: Commit**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && git add "Fit Tracker/Features/Home/" "Fit Tracker/Navigation/" "Fit Tracker/Localizable.xcstrings" && git commit -m "feat: localize Home and Navigation views (en + ar)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 5: Localize Nutrition Views (~100 strings)

**Files:**
- Modify: `Fit Tracker/Features/Nutrition/NutritionDashboardView.swift` (~17 strings)
- Modify: `Fit Tracker/Features/Nutrition/NutritionDetailView.swift` (~18 strings)
- Modify: `Fit Tracker/Features/Nutrition/FoodSearchView.swift` (~14 strings)
- Modify: `Fit Tracker/Features/Nutrition/FoodDetailView.swift` (~10 strings)
- Modify: `Fit Tracker/Features/Nutrition/FoodScannerView.swift` (~17 strings)
- Modify: `Fit Tracker/Features/Nutrition/AIParsedMealSheet.swift` (~17 strings)
- Modify: `Fit Tracker/Features/Nutrition/Components/*.swift` (all component files)
- Modify: `Fit Tracker/Localizable.xcstrings`

- [ ] **Step 1: Extract all strings from Nutrition views**

- [ ] **Step 2: Add Arabic translations**

Key translations:

| English | Arabic |
|---------|--------|
| "Breakfast" | "فطور" |
| "Lunch" | "غداء" |
| "Dinner" | "عشاء" |
| "Snack" | "وجبة خفيفة" |
| "Search foods..." | "ابحث عن الأطعمة..." |
| "Add Food" | "إضافة طعام" |
| "Calories" | "سعرات حرارية" |
| "Serving Size" | "حجم الحصة" |
| "per 100g" | "لكل 100 غرام" |
| "Log Food" | "تسجيل الطعام" |
| "Scan Food" | "مسح الطعام" |
| "Barcode" | "الباركود" |
| "Take Photo" | "التقط صورة" |
| "Water" | "ماء" |
| "ml" | "مل" |
| "g" | "غ" |

- [ ] **Step 3: Convert interpolated strings**

- [ ] **Step 4: Build and verify**

- [ ] **Step 5: Commit**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && git add "Fit Tracker/Features/Nutrition/" "Fit Tracker/Localizable.xcstrings" && git commit -m "feat: localize Nutrition views (en + ar)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 6: Localize Workout Views (~76 strings)

**Files:**
- Modify: `Fit Tracker/Features/Workout/WorkoutDashboardView.swift` (~35 strings)
- Modify: `Fit Tracker/Features/Workout/ActiveWorkoutView.swift`
- Modify: `Fit Tracker/Features/Workout/WorkoutPlanView.swift`
- Modify: `Fit Tracker/Features/Workout/Components/*.swift`
- Modify: `Fit Tracker/Localizable.xcstrings`

- [ ] **Step 1: Extract all strings from Workout views**

- [ ] **Step 2: Add Arabic translations**

Key translations:

| English | Arabic |
|---------|--------|
| "Workouts" | "التمارين" |
| "Start Workout" | "ابدأ التمرين" |
| "Finish Workout" | "إنهاء التمرين" |
| "Rest Timer" | "مؤقت الراحة" |
| "Sets" | "مجموعات" |
| "Reps" | "تكرارات" |
| "Weight" | "الوزن" |
| "kg" | "كغ" |
| "Total Volume" | "الحجم الكلي" |
| "Duration" | "المدة" |
| "min" | "دقيقة" |
| "Workout Plans" | "خطط التمارين" |
| "Create Plan" | "إنشاء خطة" |
| "Exercises" | "التمارين" |
| "Personal Record" | "رقم قياسي" |

- [ ] **Step 3: Convert interpolated strings**

- [ ] **Step 4: Build and verify**

- [ ] **Step 5: Commit**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && git add "Fit Tracker/Features/Workout/" "Fit Tracker/Localizable.xcstrings" && git commit -m "feat: localize Workout views (en + ar)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 7: Localize Remaining Views (~160 strings)

**Files:**
- Modify: `Fit Tracker/Features/AI/AICoachView.swift`
- Modify: `Fit Tracker/Features/Profile/ProfileView.swift` (~30 strings)
- Modify: `Fit Tracker/Features/Profile/EditProfileView.swift` (~12 strings)
- Modify: `Fit Tracker/Features/Progress/ProgressDashboardView.swift`
- Modify: `Fit Tracker/Features/Progress/AdvancedAnalyticsView.swift` (~12 strings)
- Modify: `Fit Tracker/Features/Subscription/PaywallView.swift` (~9 strings)
- Modify: `Fit Tracker/Features/Fasting/FastingView.swift` (~9 strings)
- Modify: `Fit Tracker/Features/Recipes/RecipeDetailView.swift` (~11 strings)
- Modify: `Fit Tracker/Features/Recipes/RecipeListView.swift`
- Modify: Any other view files with remaining hardcoded strings
- Modify: `Fit Tracker/Localizable.xcstrings`

- [ ] **Step 1: Extract all strings from remaining views**

Scan ALL files in `Features/` for any `Text("...")` that hasn't been processed in Tasks 3-6. Include AI Coach, Profile, Progress, Subscription, Fasting, and Recipes.

- [ ] **Step 2: Add Arabic translations**

Key translations:

| English | Arabic |
|---------|--------|
| "Ask your coach anything..." | "اسأل مدربك أي شيء..." |
| "What should I eat?" | "ماذا يجب أن آكل؟" |
| "Settings" | "الإعدادات" |
| "Appearance" | "المظهر" |
| "Notifications" | "الإشعارات" |
| "Units" | "الوحدات" |
| "Edit Profile" | "تعديل الملف الشخصي" |
| "Premium Active" | "الاشتراك مفعّل" |
| "Start Free Trial" | "ابدأ التجربة المجانية" |
| "Subscribe" | "اشترك" |
| "Fasting" | "الصيام" |
| "Start Fast" | "ابدأ الصيام" |
| "End Fast" | "إنهاء الصيام" |
| "Recipes" | "وصفات" |
| "Analytics" | "التحليلات" |
| "Weight History" | "سجل الوزن" |
| "FuelIQ Elite" | "FuelIQ Elite" (keep brand) |
| "Save 50%" | "وفّر 50%" |

- [ ] **Step 3: Convert interpolated strings**

- [ ] **Step 4: Build and verify**

- [ ] **Step 5: Commit**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && git add "Fit Tracker/Features/" "Fit Tracker/Localizable.xcstrings" && git commit -m "feat: localize remaining views — AI Coach, Profile, Progress, Paywall, Fasting, Recipes (en + ar)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 8: Arabic AI Responses

**Files:**
- Modify: `Fit Tracker/Services/AI/AICoachService.swift:109-139`
- Modify: `Fit Tracker/Services/AI/RecoveryAdvisorService.swift:39-57`
- Modify: `Fit Tracker/Services/AI/WeeklyDigestService.swift:88-106`
- Modify: `Fit Tracker/Services/AI/MealPlanService.swift:16-43`
- Modify: `Fit Tracker/Services/AI/AIFoodParserService.swift:137-167`

- [ ] **Step 1: Add language directive to AICoachService**

In `AICoachService.swift`, find the system prompt construction at line ~109 (`constructSystemPrompt`). At line ~136 there's already `"Respond in the same language the user writes in."` — replace it with a dynamic language directive:

```swift
let languageDirective = LanguageManager.shared.isArabic
    ? "IMPORTANT: Always respond in Arabic (العربية). Use Arabic for all text."
    : "Respond in English."
```

Append `languageDirective` to the prompt string.

**Note:** Since `constructSystemPrompt` is `nonisolated static`, pass the language as a parameter instead of accessing `LanguageManager.shared` directly. Add `language: String` parameter and pass `LanguageManager.shared.currentLanguage.rawValue` from the caller.

- [ ] **Step 2: Add language directive to RecoveryAdvisorService**

In `RecoveryAdvisorService.swift`, find the system prompt at line ~39. Append after line ~48:

```swift
let languageNote = LanguageManager.shared.isArabic
    ? "\nIMPORTANT: Write the \"message\" field in Arabic."
    : ""
```

Append `languageNote` to `systemPrompt`.

- [ ] **Step 3: Add language directive to WeeklyDigestService**

In `WeeklyDigestService.swift`, find the system prompt at line ~88. Append after line ~105:

```swift
let languageNote = LanguageManager.shared.isArabic
    ? "\n5. Write ALL text fields (title, highlights, top_achievement, improvement, weight_trend) in Arabic."
    : ""
```

- [ ] **Step 4: Add language directive to MealPlanService**

In `MealPlanService.swift`, find the system prompt at line ~16. Append after line ~42:

```swift
let languageNote = LanguageManager.shared.isArabic
    ? "\nIMPORTANT: Write all meal and food names in Arabic."
    : ""
```

- [ ] **Step 5: Add language directive to AIFoodParserService**

In `AIFoodParserService.swift`, find the system prompt at line ~137. This service already handles Arabic at lines ~165-166. Enhance it to respond fully in Arabic when the app language is Arabic.

- [ ] **Step 6: Build and verify**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && xcodebuild -scheme "Fit Tracker" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

- [ ] **Step 7: Commit**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && git add "Fit Tracker/Services/AI/" && git commit -m "feat: add Arabic language directives to all 5 AI service prompts

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Task 9: RTL Fixes + Final Verification

**Files:**
- Modify: `Fit Tracker/Features/AI/AICoachView.swift` (UnevenRoundedRectangle corners)
- Modify: Any files with directional icons (`arrow.right`, `chevron.right`)
- Modify: `Fit Tracker/Localizable.xcstrings` (any missing strings)

- [ ] **Step 1: Fix UnevenRoundedRectangle in CoachBubble**

In `AICoachView.swift`, the `CoachBubble` uses `UnevenRoundedRectangle` with asymmetric corners (line ~420). In RTL mode, the bubble tail should flip. Wrap corner radii with a helper that checks `LanguageManager.shared.isArabic`:

```swift
let isRTL = LanguageManager.shared.isArabic
// Swap leading/trailing corners for RTL
UnevenRoundedRectangle(
    topLeadingRadius: isUser ? (isRTL ? 4 : 22) : (isRTL ? 22 : 4),
    bottomLeadingRadius: 22,
    bottomTrailingRadius: isUser ? (isRTL ? 22 : 4) : 22,
    topTrailingRadius: isUser ? (isRTL ? 22 : 4) : 22
)
```

- [ ] **Step 2: Fix directional icons**

Search for `arrow.right`, `arrow.left`, `chevron.right`, `chevron.left` across all view files. Any directional icon that indicates navigation should use the locale-aware SF Symbol variant or be swapped in RTL:

```swift
Image(systemName: LanguageManager.shared.isArabic ? "chevron.left" : "chevron.right")
```

- [ ] **Step 3: Verify all strings are translated**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && grep -r 'Text("' "Fit Tracker/Features/" --include="*.swift" | grep -v '//' | wc -l
```

Cross-reference with the number of entries in `Localizable.xcstrings` to ensure coverage.

- [ ] **Step 4: Build final verification**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && xcodebuild -scheme "Fit Tracker" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

- [ ] **Step 5: Commit**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && git add "Fit Tracker/" && git commit -m "fix: RTL layout fixes and final localization polish

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Verification Checklist

After all tasks are complete:

1. [ ] Switch to Arabic in Settings → all UI text is Arabic
2. [ ] Layout mirrors to RTL (navigation, alignment, padding)
3. [ ] Switch back to English → everything returns to English LTR
4. [ ] AI Coach responds in Arabic when Arabic is selected
5. [ ] Recovery Advisor message is in Arabic
6. [ ] Weekly Digest content is in Arabic
7. [ ] Meal Plans have Arabic food names
8. [ ] No text truncation or overflow in Arabic
9. [ ] Build succeeds with zero errors
10. [ ] Coach bubble tail flips correctly in RTL
