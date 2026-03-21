# Shared NutritionViewModel for Floating Button — Design Spec

**Date:** 2026-03-21
**Status:** Approved

## Problem

MainTabView and NutritionDashboardView each create their own `NutritionViewModel` instance. When the user navigates to a past date (e.g., March 18) in the Nutrition tab and then taps the floating "+" button on the nav bar to log food, the floating button's VM has `selectedDate = .now` (today). The food gets logged to today instead of March 18.

## Solution

Share a single `NutritionViewModel` instance between MainTabView and NutritionDashboardView. When the user changes the date in the Nutrition tab, the floating button respects that date.

## Implementation

### `Navigation/MainTabView.swift` (Modify)

Already has `@State private var nutritionViewModel: NutritionViewModel?` (line 25) and creates it in `initViewModelsIfNeeded()` (line 232).

**Change 1:** Call `initViewModelsIfNeeded()` when the Nutrition tab is selected, so the shared VM is ready before the user taps "+":

```swift
.onChange(of: router.selectedTab) { oldTab, newTab in
    if newTab == .nutrition {
        initViewModelsIfNeeded()
    }
    if newTab == .scan {
        router.selectedTab = oldTab
        initViewModelsIfNeeded()
        showQuickActions = true
    }
}
```

**Change 2:** Pass the shared VM to NutritionDashboardView:

```swift
case .nutrition:
    NavigationStack(path: $router.nutritionPath) {
        NutritionDashboardView(sharedViewModel: nutritionViewModel)
    }
```

### `Features/Nutrition/NutritionDashboardView.swift` (Modify)

Currently creates its own `@State private var viewModel: NutritionViewModel?` and initializes it in `initViewModelIfNeeded()`.

Add a plain `let` parameter for the shared VM (reference type, no `@State` needed):

```swift
let sharedViewModel: NutritionViewModel?
```

In `initViewModelIfNeeded()`, prefer the shared VM:

```swift
private func initViewModelIfNeeded() {
    guard viewModel == nil else { return }
    if let shared = sharedViewModel {
        viewModel = shared
        return
    }
    guard let user = appState.currentUser else { return }
    viewModel = NutritionViewModel(user: user, nutritionService: container.nutritionService)
}
```

This preserves backward compatibility — if `NutritionDashboardView` is used without a shared VM (standalone), it creates its own as before.

### Scope: Food Logging Only

The shared `selectedDate` applies only to **food logging** via the floating "+" button's "Log Food", "Barcode", "Meal Scan", and "Custom Food" actions.

**Water and weight always log to today.** The QuickWaterSheet and WeightEntrySheet use their own logic that writes to today's date, independent of `selectedDate`. No changes needed for these flows.

## Behavior

- User on Nutrition tab, navigates to March 18 → `selectedDate` is March 18
- User taps floating "+" → Log Food → opens FoodSearchView with the **same** VM → `selectedDate` is March 18
- Food gets logged to March 18's `NutritionLog`
- If user never visits Nutrition tab, floating "+" creates a VM with `selectedDate = .now` — unchanged behavior
- Water and weight logging always target today regardless of `selectedDate`

## Edge Cases

- **User on Home tab, never opened Nutrition:** MainTabView's VM starts at today. Floating "+" logs to today. No change.
- **User changes date in Nutrition tab, switches to Home, then uses "+":** The shared VM still has the past date selected. Food logs to that past date. This is correct — the user explicitly chose that date.
- **App restart:** VM is recreated fresh with `selectedDate = .now`. No stale dates persist.

## Files Changed

| File | Action |
|------|--------|
| `Navigation/MainTabView.swift` | Modify — init VM on nutrition tab selection, pass `nutritionViewModel` to `NutritionDashboardView` |
| `Features/Nutrition/NutritionDashboardView.swift` | Modify — accept `let sharedViewModel: NutritionViewModel?` parameter |
