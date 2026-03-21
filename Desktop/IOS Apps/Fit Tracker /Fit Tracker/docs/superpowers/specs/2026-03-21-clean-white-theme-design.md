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
| `success` | `#10b981` | Emerald green (darker than dark-theme mint, readable on white) |
| `error` | `#ef4444` | Standard red (darker than dark-theme rose, readable on white) |
| `info` | `#06b6d4` | Darker cyan (readable on white) |

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
    case .cleanWhite: return Color(hex: "#999999")
    default: return .white.opacity(0.5)
    }
}
```

Views that currently hardcode `.foregroundStyle(.white)` must be updated to use `ThemeColors.textPrimary`. Views using `.white.opacity(0.4)` or `.white.opacity(0.5)` for secondary text must use `ThemeColors.textSecondary`.

## Surface Effect

The current `surfaceColor = Color.white.opacity(0.1)` creates a frosted glass look on dark backgrounds. On white, this is invisible.

For the white theme, `surfaceColor` becomes `Color.white` — but views must also apply:
- Shadow: `0 1px 3px rgba(0,0,0,0.06)`
- Border: `1px solid #0ea5e9 @ 8% opacity`

Add a helper modifier or new ThemeColors properties:

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

In `MainTabView.swift`, change:
```swift
.preferredColorScheme(ThemeManager.shared.currentTheme.isLightTheme ? .light : .dark)
```

This ensures the system status bar, keyboard, and other system UI elements match the theme.

## Implementation Scope

### `Common/Theme/AppTheme.swift` (Modify)
- Add `case cleanWhite = "Clean White"` to `AppTheme` enum
- Add `isLightTheme` computed property

### `Common/Theme/ThemeColors.swift` (Modify)
- Add `case .cleanWhite:` to every existing switch statement (`primary`, `primaryDark`, `backgroundDark`, `secondary`)
- Override semantic colors (`success`, `error`, `info`) to use darker, white-readable variants for `.cleanWhite`
- Change `surfaceColor` from a fixed `let` to a computed `var` with theme switch
- Add `surfaceBorder` and `surfaceShadow` computed properties
- Add `textPrimary` and `textSecondary` computed properties

### `Navigation/MainTabView.swift` (Modify)
- Change `.preferredColorScheme(.dark)` to use `ThemeManager.shared.currentTheme.isLightTheme`

### All view files using hardcoded white text (Modify)
- Replace `.foregroundStyle(.white)` with `.foregroundStyle(ThemeColors.textPrimary)` where the text is on a themed background
- Replace `.foregroundStyle(.white.opacity(0.4))` / `.foregroundStyle(.white.opacity(0.5))` with `.foregroundStyle(ThemeColors.textSecondary)`
- Replace `.white.opacity(0.06)` borders with `ThemeColors.surfaceBorder`
- **Exception:** White text on colored/gradient fills (e.g., buttons with `ThemeColors.primary` background) should stay white — it's on a colored surface, not on the background

### Theme Picker UI in ProfileView (Modify)
- No changes needed — the picker iterates `AppTheme.allCases`, so "Clean White" automatically appears

## What Does NOT Change

- The 4 existing dark themes — zero modifications to their color values
- The `ThemeManager` singleton pattern
- The `@AppStorage("appTheme")` persistence mechanism
- The `.id(appTheme)` full-view redraw trigger in `AppRootView`
- FoodItem, NutritionEntry, or any data models

## Edge Cases

- **New users:** Default theme remains Ocean Blue (dark). Clean White is opt-in.
- **Existing users:** Their saved theme continues working. Clean White only activates if they select it.
- **Charts and graphs:** Charts using `.foregroundStyle(.white)` for labels need to switch to `textPrimary`. Chart grid lines using `.white.opacity(0.1)` should use a computed theme-aware value.
- **Images and icons:** SF Symbols using `.foregroundStyle(.white)` on themed backgrounds need `textPrimary`. Icons on colored buttons (primary background) stay white.
- **Navigation bar:** Hidden in most views (`.toolbar(.hidden)`), so no system-level nav bar color issues.
