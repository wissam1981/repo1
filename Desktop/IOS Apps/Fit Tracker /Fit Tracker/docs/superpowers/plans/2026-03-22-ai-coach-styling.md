# AI Coach Styled Responses Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the AI Coach visually striking with gradient bubbles, keyword pills, entrance animations, and a robot AI icon.

**Architecture:** Modify two files — `AICoachView.swift` (bubble style, animations, icon) and `StyledCoachText.swift` (FlowLayout + keyword pills). The FlowLayout uses SwiftUI's `Layout` protocol for natural text wrapping with per-token background support.

**Tech Stack:** SwiftUI, SwiftUI Layout protocol (iOS 16+)

---

### Task 1: FlowLayout + Keyword Pills (StyledCoachText.swift)

**Files:**
- Modify: `Fit Tracker/Features/AI/StyledCoachText.swift`

This is the most complex task — build the FlowLayout and convert from Text concatenation to individual token views with pill backgrounds.

- [ ] **Step 1: Add FlowLayout struct**

Add this at the top of `StyledCoachText.swift`, after the import:

```swift
// MARK: - Flow Layout (wraps child views across lines)

struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 0
    var verticalSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private struct ArrangeResult {
        var size: CGSize
        var positions: [CGPoint]
        var sizes: [CGSize]
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> ArrangeResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)

            // Check if this is a line-break view (width >= maxWidth)
            if size.width >= maxWidth {
                // Force new line
                if x > 0 {
                    y += rowHeight + verticalSpacing
                }
                positions.append(CGPoint(x: 0, y: y))
                y += verticalSpacing
                x = 0
                rowHeight = 0
                continue
            }

            if x + size.width > maxWidth && x > 0 {
                // Wrap to next line
                y += rowHeight + verticalSpacing
                x = 0
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }

        let totalHeight = y + rowHeight
        return ArrangeResult(
            size: CGSize(width: maxWidth, height: totalHeight),
            positions: positions,
            sizes: sizes
        )
    }
}
```

- [ ] **Step 2: Replace the body and styledText() with FlowLayout**

Replace the current `body` and `styledText()` method:

```swift
var body: some View {
    FlowLayout(horizontalSpacing: 0, verticalSpacing: 6) {
        ForEach(Array(tokenize(text).enumerated()), id: \.offset) { _, token in
            tokenView(token)
        }
    }
    .font(.system(size: 17, weight: .regular))
}
```

Remove the old `styledText() -> Text` method entirely.

- [ ] **Step 3: Create the tokenView method**

Replace the old `styledToken(_ token: String) -> Text` method with a new `tokenView` that returns `some View`:

```swift
@ViewBuilder
private func tokenView(_ token: String) -> some View {
    let stripped = token.lowercased().trimmingCharacters(in: .punctuationCharacters)

    if token == " " {
        Text(" ")
    } else if token == "\n" {
        // Full-width spacer forces FlowLayout to next line
        Color.clear.frame(maxWidth: .infinity, maxHeight: 0)
    } else if token.hasPrefix("**") && token.hasSuffix("**") && token.count > 4 {
        // Markdown bold
        let inner = String(token.dropFirst(2).dropLast(2))
        Text(inner)
            .bold()
            .foregroundColor(ThemeColors.textPrimary)
    } else if isNumberWithUnit(stripped) {
        let color = colorForUnit(stripped)
        pillView(token: token, color: color)
    } else if isStandaloneNumber(stripped) {
        Text(token)
            .bold()
            .foregroundColor(ThemeColors.textPrimary)
    } else if let color = keywordColor(for: stripped) {
        pillView(token: token, color: color)
    } else {
        Text(token)
            .foregroundColor(ThemeColors.textPrimary)
    }
}
```

- [ ] **Step 4: Create pillView helper and keywordColor lookup**

Add these two helpers:

```swift
private func pillView(token: String, color: Color) -> some View {
    Text(token)
        .bold()
        .foregroundColor(color)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
}

private func keywordColor(for stripped: String) -> Color? {
    if proteinKeywords.contains(stripped) { return NutrientColor.protein }
    if carbsKeywords.contains(stripped) { return NutrientColor.carbs }
    if fatKeywords.contains(stripped) { return NutrientColor.fat }
    if calorieKeywords.contains(stripped) { return NutrientColor.calories }
    if waterKeywords.contains(stripped) { return NutrientColor.water }
    if fitnessKeywords.contains(stripped) { return NutrientColor.fitness }
    return nil
}
```

- [ ] **Step 5: Clean up keyword sets**

Remove dead multi-word entries and add individual replacements:

In `proteinKeywords`:
- Remove `"greek yogurt"` and `"cottage cheese"`
- Add `"yogurt"` and `"cottage"`

In `fitnessKeywords`:
- Remove `"personal record"`

The updated sets:

```swift
private let proteinKeywords: Set<String> = [
    "protein", "proteins", "whey", "casein", "bcaa", "amino",
    "leucine", "chicken", "turkey", "salmon", "tuna", "eggs",
    "yogurt", "cottage"
]

private let fitnessKeywords: Set<String> = [
    "workout", "exercise", "training", "rest", "recovery",
    "reps", "sets", "volume", "progressive", "overload",
    "bench", "squat", "deadlift", "push-ups", "pull-ups",
    "hiit", "cardio", "strength", "muscle", "muscles",
    "gains", "pr"
]
```

All other keyword sets stay unchanged.

- [ ] **Step 6: Build and verify**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && xcodebuild -scheme "Fit Tracker" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: Commit**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && git add "Fit Tracker/Features/AI/StyledCoachText.swift" && git commit -m "feat: add FlowLayout and keyword pills to AI Coach text"
```

---

### Task 2: Bold Gradient Bubble + Icon + Animations (AICoachView.swift)

**Files:**
- Modify: `Fit Tracker/Features/AI/AICoachView.swift`

- [ ] **Step 1: Replace brain icon with cpu.fill in all 3 locations**

Find and replace all 3 occurrences of `"brain.head.profile.fill"` with `"cpu.fill"`:
- Line ~100 (coachTopBar)
- Line ~221 (typingIndicator)
- Line ~380 (CoachBubble avatar)

- [ ] **Step 2: Rewrite CoachBubble background — remove accent bar, add gradient**

In the `CoachBubble` struct's `body`, replace the entire `VStack(alignment:)` content. The current code has an `HStack(spacing: 0)` containing the accent bar and message content. Replace it with:

```swift
VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
    // Message content — no more HStack with accent bar
    Group {
        if isUser {
            Text(message.content)
                .font(.system(size: 17, weight: .regular))
                .lineSpacing(6)
                .foregroundStyle(.white)
        } else {
            StyledCoachText(text: message.content)
        }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background {
        if isUser {
            LinearGradient(
                colors: [ThemeColors.primary, .cyan.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            let isLight = ThemeManager.shared.currentTheme.isLightTheme
            LinearGradient(
                colors: [
                    ThemeColors.primary.opacity(isLight ? 0.18 : 0.15),
                    Color.cyan.opacity(isLight ? 0.10 : 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    .clipShape(
        UnevenRoundedRectangle(
            topLeadingRadius: isUser ? 22 : 4,
            bottomLeadingRadius: 22,
            bottomTrailingRadius: isUser ? 4 : 22,
            topTrailingRadius: 22
        )
    )
    .overlay(
        UnevenRoundedRectangle(
            topLeadingRadius: isUser ? 22 : 4,
            bottomLeadingRadius: 22,
            bottomTrailingRadius: isUser ? 4 : 22,
            topTrailingRadius: 22
        )
        .stroke(
            LinearGradient(
                colors: [ThemeColors.primary.opacity(0.4), ThemeColors.primary.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            lineWidth: isUser ? 0 : 1
        )
    )
    .shadow(color: ThemeColors.primary.opacity(0.15), radius: 12, x: 0, y: 4)

    Text(message.timestamp, style: .time)
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(ThemeColors.textSecondary)
        .padding(.horizontal, 6)
}
```

Key differences from old code:
- No `HStack(spacing: 0)` wrapping accent bar + content
- No accent bar `RoundedRectangle(cornerRadius: 2)`
- Background uses `if/else` builder instead of `AnyShapeStyle` ternary
- Clip shape uses `UnevenRoundedRectangle` (not `.rect(...)`)
- Border overlay uses matching `UnevenRoundedRectangle` (not `RoundedRectangle(cornerRadius: 16)`)
- Shadow applies to both user and coach bubbles (was only user before)

- [ ] **Step 3: Add message entrance transitions**

In the `messagesScrollView` (around line 182), find the `ForEach(viewModel.messages)` block and add transitions:

```swift
ForEach(viewModel.messages) { message in
    if message.role != .system {
        CoachBubble(message: message)
            .transition(.asymmetric(
                insertion: .move(edge: message.role == .user ? .trailing : .leading)
                    .combined(with: .opacity),
                removal: .opacity
            ))
    }
}
```

Then wrap the parent `LazyVStack` (or `VStack`) with the animation modifier:

```swift
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.messages.count)
```

- [ ] **Step 4: Build and verify**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && xcodebuild -scheme "Fit Tracker" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && git add "Fit Tracker/Features/AI/AICoachView.swift" && git commit -m "feat: bold gradient bubble, entrance animations, and AI icon for Coach"
```

---

### Task 3: Final Verification

- [ ] **Step 1: Full build**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && xcodebuild -scheme "Fit Tracker" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

- [ ] **Step 2: Verify no remaining brain icons**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && grep -rn "brain.head.profile.fill" "Fit Tracker/Features/AI/" --include="*.swift"
```

Expected: No output (all replaced with `cpu.fill`).

- [ ] **Step 3: Verify keyword pill implementation**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && grep -n "Capsule" "Fit Tracker/Features/AI/StyledCoachText.swift"
```

Expected: Should find `Capsule().fill(color.opacity(0.15))` in `pillView`.

- [ ] **Step 4: Commit if any fixes needed**

```bash
cd "/Users/wissam/Desktop/IOS Apps/Fit Tracker /Fit Tracker" && git add -A && git commit -m "fix: AI Coach styling final fixes"
```
