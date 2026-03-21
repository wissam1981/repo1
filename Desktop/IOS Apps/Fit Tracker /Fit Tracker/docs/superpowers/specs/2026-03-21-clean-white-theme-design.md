# Clean White Theme — Design Spec

**Date:** 2026-03-21
**Status:** Approved

## Problem

The app only has 4 dark themes. Users who prefer light mode have no option. A stylish white/light theme expands the app's appeal.

## Solution

Add a 5th theme — "Clean White" — to the existing theme system. Pure white cards on a cool light-gray background, sky blue accent (matching Ocean Blue), subtle shadows, and a faint blue-tinted border on card surfaces. All 4 existing dark themes remain unchanged.

---

## Color Palette

| Token | Clean White Value | Notes |
|-------|-------------------|-------|
| `primary` | `#0ea5e9` | Sky blue, same as Ocean Blue |
| `primaryDark` | `#0284c7` | Darker sky blue, same as Ocean Blue |
| `backgroundDark` | `#F5F7FA` | Cool light gray (name stays `backgroundDark` for compatibility) |
| `secondary` | `#E8F4FD` | Light blue tint |
| `surfaceColor` | Special — see Surface Effect section | White card with shadow + border |
| `success` | `#10b981` | Emerald green (readable at bold/large sizes on white) |
| `error` | `#ef4444` | Standard red (readable at bold/large sizes on white) |
| `info` | `#06b6d4` | Darker cyan (readable at bold/large sizes on white) |

**Note on semantic colors:** The `success`, `error`, and `info` values achieve ~3-4:1 contrast on white. This is acceptable because these colors are used exclusively for bold indicators, badges, and progress rings — never for small body text. The derived `successBackground`, `errorBackground`, and `infoBackground` properties (computed via `.opacity(0.15)`) automatically inherit from the corrected base values.

**`backgroundLight` cleanup:** The existing `static let backgroundLight = Color(hex: "#f8f8f5")` in ThemeColors is unused across the entire codebase. It remains as-is — no relation to the new Clean White theme's `backgroundDark` value.

## New Text Color Tokens

Dark themes use `.white` and `.white.opacity(0.5)` for text throughout the app. These are invisible on a white background.

Add two new computed properties to `ThemeColors`:

```swift
static var textPrimary: Color {
    switch ThemeManager.shared.currentTheme {
    case .cleanWhite: return Color(hex: "#1a1a1a")
    default: return .white
    }
}

static var textSecondary: Color {
    switch ThemeManager.shared.currentTheme {
    case .cleanWhite: return Color(hex: "#767676")  // 4.5:1 contrast on white (WCAG AA)
    default: return .white.opacity(0.5)
    }
}
```

Views that currently hardcode `.foregroundStyle(.white)` must be updated to use `ThemeColors.textPrimary`. Views using `.white.opacity(0.4)` or `.white.opacity(0.5)` for secondary text must use `ThemeColors.textSecondary`.

## Surface Effect

The current `surfaceColor` is `static let surfaceColor = Color.white.opacity(0.1)` — a stored constant. This creates a frosted glass look on dark backgrounds but is invisible on white.

Change it to a computed property with a theme switch. The `default` branch preserves the existing `Color.white.opacity(0.1)` for all 4 dark themes — no behavioral change for them.

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

Views using inline `Color.white.opacity(0.04/0.06/0.08/0.1/0.12)` for card backgrounds and borders must migrate to `ThemeColors.surfaceColor` / `ThemeColors.surfaceBorder` — these inline values are invisible on white.

## GlassView / Frosted Glass Effect

`Common/Components/GlassView.swift` contains a `GlassModifier` that uses `UIBlurEffect(style: .systemThinMaterialDark)` — this is hardcoded and ignores `preferredColorScheme`. It must be made theme-aware:

```swift
let blurStyle: UIBlurEffect.Style = ThemeManager.shared.currentTheme.isLightTheme
    ? .systemThinMaterial
    : .systemThinMaterialDark
```

The border stroke in `GlassModifier` (`Color.white.opacity(0.1)`) must switch to `ThemeColors.surfaceBorder`.

**`AuraFloatingNavBar.swift`** uses `.glassStyle(cornerRadius: 32, color: .white.opacity(0.12))` — on a white background this is invisible. For Clean White, the nav bar should use a white fill with shadow instead. The nav bar's inactive tab icons (`.white.opacity(0.4)`) must use `ThemeColors.textSecondary`.

## Primary Gradient

The existing `primaryGradient` hardcodes `Color(hex: "#2E7D32")` (forest green) as the gradient end, which is wrong for most themes. For Clean White:

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

## Preferred Color Scheme

Add a computed property to `AppTheme`:

```swift
var isLightTheme: Bool {
    switch self {
    case .cleanWhite: return true
    default: return false
    }
}
```

Apply in **both** locations:

1. `Navigation/MainTabView.swift`:
```swift
.preferredColorScheme(ThemeManager.shared.currentTheme.isLightTheme ? .light : .dark)
```

2. `Features/Onboarding/OnboardingContainerView.swift` — also has `.preferredColorScheme(.dark)`, must be updated to match.

## Implementation Scope

### `Common/Theme/AppTheme.swift` (Modify)
- Add `case cleanWhite = "Clean White"` to `AppTheme` enum
- Add `isLightTheme` computed property

### `Common/Theme/ThemeColors.swift` (Modify)
- Add `case .cleanWhite:` to every existing switch statement (`primary`, `primaryDark`, `backgroundDark`, `secondary`)
- Change semantic colors (`success`, `error`, `info`) from fixed `let` to computed `var` with theme switch — darker variants for `.cleanWhite`
- Change `surfaceColor` from `static let` to computed `static var` with theme switch
- Add `surfaceBorder` and `surfaceShadow` computed properties
- Add `textPrimary` and `textSecondary` computed properties
- Update `primaryGradient` to be theme-aware

### `Common/Components/GlassView.swift` (Modify)
- Switch `UIBlurEffect(style:)` based on `isLightTheme`
- Update border stroke to use `ThemeColors.surfaceBorder`

### `Navigation/AuraFloatingNavBar.swift` (Modify)
- Update `.glassStyle` call for Clean White (white fill with shadow instead of transparent glass)
- Update inactive tab icon color from `.white.opacity(0.4)` to `ThemeColors.textSecondary`

### `Navigation/MainTabView.swift` (Modify)
- Change `.preferredColorScheme(.dark)` to theme-aware
- Update `QuickActionsSheet` and `QuickWaterSheet` (private structs in this file) — replace hardcoded `.white` text with `ThemeColors.textPrimary`/`textSecondary`

### `Features/Onboarding/OnboardingContainerView.swift` (Modify)
- Change `.preferredColorScheme(.dark)` to theme-aware

### All view files with hardcoded white text (~46 files) (Modify)
- Replace `.foregroundStyle(.white)` with `.foregroundStyle(ThemeColors.textPrimary)` where text is on a themed background
- Replace `.foregroundStyle(.white.opacity(0.4))` / `.white.opacity(0.5)` with `.foregroundStyle(ThemeColors.textSecondary)`
- Replace inline `Color.white.opacity(0.04-0.12)` card backgrounds with `ThemeColors.surfaceColor`
- Replace inline `Color.white.opacity(0.06)` borders with `ThemeColors.surfaceBorder`
- **Exception:** White text on colored/gradient fills (e.g., buttons with `ThemeColors.primary` background) stays white — it's on a colored surface, not the background
- Charts using `.foregroundStyle(.white)` for labels need `textPrimary`

### Theme Picker UI in ProfileView
- No changes needed — the picker iterates `AppTheme.allCases`, so "Clean White" automatically appears

### Out of Scope
- **Auth views** (LoginView, SignUpView, WelcomeView, SplashView) — theme selection happens post-login, so these views are always seen in the default Ocean Blue dark theme. Not worth migrating.

## What Does NOT Change

- The 4 existing dark themes — zero modifications to their color values
- The `ThemeManager` singleton pattern
- The `@AppStorage("appTheme")` persistence mechanism
- The `.id(appTheme)` full-view redraw trigger in `AppRootView`
- FoodItem, NutritionEntry, or any data models

## Edge Cases

- **New users:** Default theme remains Ocean Blue (dark). Clean White is opt-in.
- **Existing users:** Their saved theme continues working. Clean White only activates if they select it.
- **Charts and graphs:** Charts using `.foregroundStyle(.white)` for labels need `textPrimary`. Chart grid lines using `.white.opacity(0.1)` should use a computed theme-aware value.
- **Images and icons:** SF Symbols using `.foregroundStyle(.white)` on themed backgrounds need `textPrimary`. Icons on colored buttons (primary background) stay white.
- **Navigation bar:** Hidden in most views (`.toolbar(.hidden)`), so no system-level nav bar color issues.
