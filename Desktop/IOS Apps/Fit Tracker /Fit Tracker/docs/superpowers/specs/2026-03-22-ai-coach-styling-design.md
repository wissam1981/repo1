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
let isLight = ThemeManager.shared.currentTheme.isLightTheme

// Background
LinearGradient(
    colors: [
        ThemeColors.primary.opacity(isLight ? 0.18 : 0.15),
        Color.cyan.opacity(isLight ? 0.10 : 0.10)
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// Border — must use the SAME asymmetric shape as the clip
let bubbleShape = UnevenRoundedRectangle(
    topLeadingRadius: 4,
    bottomLeadingRadius: 22,
    bottomTrailingRadius: 22,
    topTrailingRadius: 22
)

// Border stroke uses the same shape
bubbleShape.stroke(
    LinearGradient(
        colors: [ThemeColors.primary.opacity(0.4), ThemeColors.primary.opacity(0.15)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    ),
    lineWidth: 1
)

// Shadow
.shadow(color: ThemeColors.primary.opacity(0.15), radius: 12, x: 0, y: 4)

// Clip shape
.clipShape(bubbleShape)
```

**Accessing `isLightTheme`:** Use `ThemeManager.shared.currentTheme.isLightTheme` directly inside `CoachBubble`. This is the same pattern used throughout the codebase (e.g., `GlassView.swift`). The value is read at render time, and `.id(appTheme)` on `AppRootView` forces a full view hierarchy rebuild on theme change, so the value is always current.

**Remove:** The 3px left gradient accent bar (`RoundedRectangle(cornerRadius: 2).fill(LinearGradient(...))`). Remove the entire `HStack(spacing: 0)` that contains the accent bar + message content. The message content goes directly in the bubble.

**User bubbles:** No changes — keep the existing `ThemeColors.primary` → `.cyan.opacity(0.7)` gradient.

**Theme-aware:** On Clean White, the light-theme opacities are *slightly higher* (0.18/0.10 vs 0.15/0.10) so the gradient remains visible against the white background.

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

**Solution:** Use SwiftUI's `Layout` protocol (iOS 16+) to create a `FlowLayout` that wraps token views across lines.

**FlowLayout specification:**

```swift
struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 0  // No extra spacing — whitespace tokens handle gaps
    var verticalSpacing: CGFloat = 6    // Matches current lineSpacing(6)

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ())
}
```

**Token handling rules:**
- **Regular words:** `Text` view, no background
- **Keywords:** `Text` view with `.background(Capsule().fill(color.opacity(0.15)))` and `.padding(.horizontal, 4).padding(.vertical, 2)`
- **Whitespace `" "` tokens:** Render as `Text(" ")` — the FlowLayout places them with `horizontalSpacing: 0`, so the space character itself provides inter-word gaps
- **Newline `"\n"` tokens:** Render as a full-width `Color.clear.frame(height: 0)` view that forces the FlowLayout to start a new row
- **Vertical row spacing:** `verticalSpacing: 6` on the FlowLayout matches the current `lineSpacing(6)`

**Performance:** Typical AI responses are 50-150 tokens. At this scale, a `Layout` protocol implementation is performant — no lazy rendering needed. The Layout protocol measures all subviews in a single pass.

### Keyword Set Cleanup

Remove dead multi-word entries that the tokenizer can never match (it splits on spaces, producing single-word tokens):
- Remove `"greek yogurt"` from `proteinKeywords`
- Remove `"cottage cheese"` from `proteinKeywords`
- Remove `"personal record"` from `fitnessKeywords`

These have never matched. Add the individual words where useful:
- Add `"yogurt"` to `proteinKeywords`
- Add `"cottage"` to `proteinKeywords`

### What Stays the Same

- Keyword color values (NutrientColor struct) — unchanged
- Number detection regex — unchanged
- Markdown bold handling — unchanged
- Default text color (`ThemeColors.textPrimary`) — unchanged

### Ambiguous keyword note

The `"trans"` entry in `fatKeywords` could false-positive in non-fat contexts. This is a pre-existing issue. The pill background will make false positives more visible. Consider removing it, but this is optional — leave as-is for now since "trans" in a fitness AI context almost always means "trans fat."

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

Replace `brain.head.profile.fill` with `cpu.fill` — processor chip icon, reads as "AI/tech", clean and modern.

Replace in all 3 locations consistently.

## Implementation Scope

### `Fit Tracker/Features/AI/AICoachView.swift` (Modify)
- Update `CoachBubble` background from accent-bar to gradient bubble
- Remove the left gradient `RoundedRectangle(cornerRadius: 2)` accent bar and its containing `HStack(spacing: 0)`
- Add gradient background, gradient border stroke (using `UnevenRoundedRectangle` matching clip shape), and shadow to coach bubble
- Access `ThemeManager.shared.currentTheme.isLightTheme` directly for opacity values
- Add `.transition()` to `CoachBubble` based on message role (leading for coach, trailing for user)
- Add `.animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.messages.count)` to messages `LazyVStack`
- Replace `brain.head.profile.fill` with `cpu.fill` in 3 locations (topBar, bubble, typing)

### `Fit Tracker/Features/AI/StyledCoachText.swift` (Modify)
- Add `FlowLayout` struct using SwiftUI `Layout` protocol with `horizontalSpacing: 0`, `verticalSpacing: 6`
- Change body from `Text` concatenation to `FlowLayout` of individual token views
- Handle whitespace tokens as `Text(" ")` views, newline tokens as full-width zero-height spacers
- Add capsule background to keyword/number tokens with color at 0.15 opacity
- Remove dead multi-word keywords (`"greek yogurt"`, `"cottage cheese"`, `"personal record"`), add `"yogurt"` and `"cottage"` individually
- Keep all other keyword sets, regex, and detection logic unchanged

## What Does NOT Change

- `NutrientColor` struct — colors stay the same
- User message bubble style — stays gradient
- Suggestion chips — unchanged
- Input bar — unchanged
- Typing indicator dots — unchanged (just icon swap)
- `AICoachViewModel` — no changes
- `AppRootView` `.id(appTheme)` — already handles theme reactivity by rebuilding all views

## Edge Cases

- **Long keywords:** Pills wrap as a whole unit to the next line if they don't fit on the current line.
- **Consecutive keywords:** "protein and carbs" → [protein pill] [plain "and"] [carbs pill] — looks natural.
- **Empty messages:** No change needed — already handled.
- **Theme switching:** `.id(appTheme)` on `AppRootView` recreates the entire view hierarchy, so `ThemeManager.shared.currentTheme.isLightTheme` is re-evaluated and gradient opacities update automatically.
- **Clean White theme:** Light-theme gradient opacities are slightly higher (0.18 vs 0.15) so the bubble is visible against the white background.
- **Accessibility:** Keyword pills are purely decorative — VoiceOver reads the text content normally, no special announcements needed.
