# AI Coach Styled Responses — Design Spec

**Date:** 2026-03-22
**Status:** Approved

## Problem

The AI Coach responses are functional but visually flat. Keywords like "protein", "carbs", and "calories" are colored but don't pop. The coach bubble uses a simple accent bar that doesn't feel premium. The coach avatar uses a brain icon that doesn't convey "AI assistant."

## Solution

Three enhancements to make the AI Coach visually striking:

1. **Bold Gradient Bubble** — Coach messages get a gradient background with glow border and shadow
2. **Keyword Pills** — Colored keywords wrapped in tinted capsule backgrounds instead of just colored text
3. **Message Entrance Animations** — Spring-based slide+fade transitions for messages

Plus: Change the coach avatar icon from `brain.head.profile.fill` to a robot/AI icon.

---

## 1. Bold Gradient Bubble

### Current State

Coach messages use `ThemeColors.surfaceColor` background with a left gradient accent bar (3px wide, protein→carbs→calories gradient). The bubble shape has `topLeadingRadius: 4` (flat top-left corner).

### New Design

Replace the accent bar + surface color with a gradient-filled bubble:

**Coach bubble:**
```swift
// Background
LinearGradient(
    colors: [
        ThemeColors.primary.opacity(isLightTheme ? 0.12 : 0.15),
        Color.cyan.opacity(isLightTheme ? 0.06 : 0.10)
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// Border
LinearGradient(
    colors: [ThemeColors.primary.opacity(0.4), ThemeColors.primary.opacity(0.15)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
// lineWidth: 1

// Shadow
.shadow(color: ThemeColors.primary.opacity(0.15), radius: 12, x: 0, y: 4)

// Corner radius
.rect(
    topLeadingRadius: 4,
    bottomLeadingRadius: 20,
    bottomTrailingRadius: 20,
    topTrailingRadius: 20
)
```

**Remove:** The 3px left gradient accent bar (`RoundedRectangle(cornerRadius: 2).fill(LinearGradient(...))`).

**User bubbles:** No changes — keep the existing `ThemeColors.primary` → `.cyan.opacity(0.7)` gradient.

**Theme-aware:** The `isLightTheme` check uses `ThemeManager.shared.currentTheme.isLightTheme`. On Clean White, slightly stronger opacity so the gradient shows against the white background.

## 2. Keyword Pills

### Current State

`StyledCoachText` colors keywords with `foregroundColor` only. Keywords appear as colored text inline with regular text. This is subtle and easy to miss.

### New Design

Wrap each keyword in a tinted capsule background. The pill has:
- **Text color:** Same as current (NutrientColor.protein, .carbs, etc.)
- **Background:** Same color at 15% opacity
- **Shape:** Capsule (fully rounded)
- **Padding:** 4px horizontal, 2px vertical
- **Font:** Same size (17pt), bold weight (same as current)

**Color mapping:**

| Category | Text Color | Pill Background |
|----------|-----------|-----------------|
| Protein | `NutrientColor.protein` (#34d399) | Same at 0.15 opacity |
| Carbs | `NutrientColor.carbs` (#22d3ee) | Same at 0.15 opacity |
| Fat | `NutrientColor.fat` (#fb923c) | Same at 0.15 opacity |
| Calories | `NutrientColor.calories` (#f87171) | Same at 0.15 opacity |
| Water | `NutrientColor.water` (#38bdf8) | Same at 0.15 opacity |
| Fitness | `NutrientColor.fitness` (#a78bfa) | Same at 0.15 opacity |
| Numbers with units | Color based on unit suffix | Same at 0.15 opacity |

### Implementation Approach

SwiftUI `Text` concatenation (`Text("a") + Text("b")`) does not support per-word background colors. The current `StyledCoachText` uses this concatenation approach.

**Solution:** Switch from `Text` concatenation to a wrapping layout (`FlowLayout` or manual `HStack`/`VStack` line-breaking). Each token becomes its own `Text` view wrapped in a container that can have a `.background(Capsule().fill(...))`.

Create a new `FlowLayout` helper (or use SwiftUI's built-in layout protocol) that wraps tokens naturally across lines, preserving the text flow appearance.

**Fallback:** If `FlowLayout` proves too complex, use SwiftUI's `AttributedString` with custom attributes for background rendering. However, `AttributedString` background support in SwiftUI `Text` is limited — the `FlowLayout` approach is more reliable.

### What Stays the Same

- Keyword sets (proteinKeywords, carbsKeywords, etc.) — unchanged
- Number detection regex — unchanged
- Markdown bold handling — unchanged
- Default text color (`ThemeColors.textPrimary`) — unchanged

## 3. Message Entrance Animations

### Current State

Messages appear instantly with no animation.

### New Design

**Coach messages** slide in from the leading edge with fade:
```swift
.transition(.asymmetric(
    insertion: .move(edge: .leading).combined(with: .opacity),
    removal: .opacity
))
```

**User messages** slide in from the trailing edge with fade:
```swift
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .opacity
))
```

**Animation curve:** Spring with `response: 0.4, dampingFraction: 0.8`

Apply by wrapping the `ForEach` content in the messages `ScrollView` with:
```swift
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.messages.count)
```

## 4. Coach Avatar Icon Change

### Current State

The coach avatar uses `brain.head.profile.fill` SF Symbol — appears in 3 places:
1. `coachTopBar` (top navigation)
2. `CoachBubble` (next to each coach message)
3. `typingIndicator` (typing dots)

### New Design

Replace `brain.head.profile.fill` with a robot/AI icon. Options in order of preference:
1. `cpu.fill` — processor chip, reads as "AI/tech"
2. `sparkles` — already associated with AI features across iOS
3. `desktopcomputer` — less ideal but robotic

**Recommended:** `cpu.fill` — clean, tech-forward, distinctly "AI" without being a literal brain.

Replace in all 3 locations consistently.

## Implementation Scope

### `Fit Tracker/Features/AI/AICoachView.swift` (Modify)
- Update `CoachBubble` background from accent-bar to gradient bubble
- Remove the left gradient `RoundedRectangle(cornerRadius: 2)` accent bar
- Add shadow to coach bubble
- Update border to gradient stroke
- Add `.transition()` to `CoachBubble` in `ForEach`
- Add `.animation(.spring(...), value: viewModel.messages.count)` to `ScrollView` content
- Replace `brain.head.profile.fill` with `cpu.fill` in 3 locations (topBar, bubble, typing)

### `Fit Tracker/Features/AI/StyledCoachText.swift` (Modify)
- Create `FlowLayout` for wrapping token views
- Change `styledText()` from `Text` concatenation to `FlowLayout` of individual token views
- Add capsule background to keyword/number tokens
- Keep all keyword sets and detection logic unchanged

## What Does NOT Change

- `NutrientColor` struct — colors stay the same
- Keyword detection logic — same sets, same regex
- User message bubble style — stays gradient
- Suggestion chips — unchanged
- Input bar — unchanged
- Typing indicator dots — unchanged (just icon swap)
- `AICoachViewModel` — no changes

## Edge Cases

- **Long keywords:** Pills may wrap mid-word if the token is very long. The FlowLayout handles this by moving the entire pill to the next line if it doesn't fit.
- **Consecutive keywords:** "protein and carbs" → [protein pill] [plain "and"] [carbs pill] — looks natural.
- **Empty messages:** No change needed — already handled.
- **Theme switching:** `.id(appTheme)` recreates all views, so gradient opacities update automatically.
- **Clean White theme:** Gradient opacities are slightly adjusted (0.12/0.06 instead of 0.15/0.10) so the bubble is visible but not overpowering on white.
