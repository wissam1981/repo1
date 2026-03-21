import SwiftUI

// MARK: - Quick Action Destination

enum QuickActionDestination {
    case foodSearch
    case barcodeScan
    case mealScan
    case customFood
    case waterTracker
    case weightEntry
    case exercise
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(DependencyContainer.self) private var container
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var showQuickActions = false
    @State private var showPaywall = false
    @State private var nutritionViewModel: NutritionViewModel?
    @State private var progressViewModel: ProgressViewModel?

    // Sheet destinations triggered from quick actions
    @State private var showFoodSearch = false
    @State private var showBarcodeScanner = false
    @State private var showMealScanner = false
    @State private var showCustomFood = false
    @State private var showWaterTracker = false
    @State private var showWeightEntry = false
    @State private var showActiveWorkout = false

    /// Pending destination to navigate to after the quick actions sheet dismisses
    @State private var pendingDestination: QuickActionDestination?

    /// Show paywall once per app session for non-subscribers
    @State private var hasShownPaywallThisSession = false

    var body: some View {
        @Bindable var router = router

        ZStack(alignment: .bottom) {
            Group {
                switch router.selectedTab {
                case .home:
                    NavigationStack {
                        HomeView(sharedNutritionVM: nutritionViewModel)
                    }
                case .nutrition:
                    NavigationStack(path: $router.nutritionPath) {
                        NutritionDashboardView(sharedViewModel: nutritionViewModel)
                    }
                case .workout:
                    NavigationStack(path: $router.workoutPath) {
                        WorkoutDashboardView()
                    }
                case .profile:
                    NavigationStack(path: $router.profilePath) {
                        ProfileView()
                    }
                case .scan:
                    Color.clear // Should not be accessible directly
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // AuraFit Floating Glass Nav Bar
            AuraFloatingNavBar(selectedTab: $router.selectedTab) {
                initViewModelsIfNeeded()
                showQuickActions = true
            }
            .padding(.bottom, 16) // Detach from bottom
        }
        .preferredColorScheme(ThemeManager.shared.currentTheme.isLightTheme ? .light : .dark)
        .onChange(of: router.selectedTab) { oldTab, newTab in
            if newTab == .home || newTab == .nutrition {
                initViewModelsIfNeeded()
            }
            if newTab == .scan {
                router.selectedTab = oldTab
                initViewModelsIfNeeded()
                showQuickActions = true
            }
        }
        .onAppear {
            router.selectedTab = .home
        }
        .task {
            // Wait for subscription status to be checked, then show paywall if not subscribed
            await subscriptionManager.checkSubscriptionStatus()
            if !subscriptionManager.isSubscribed && !hasShownPaywallThisSession {
                hasShownPaywallThisSession = true
                // Small delay so the main UI loads first
                try? await Task.sleep(for: .milliseconds(800))
                showPaywall = true
            }
        }
        .sheet(isPresented: $showQuickActions, onDismiss: {
            guard let destination = pendingDestination else { return }
            pendingDestination = nil
            // Small delay to ensure sheet is fully dismissed before presenting next one
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                switch destination {
                case .foodSearch:
                    showFoodSearch = true
                case .barcodeScan:
                    showBarcodeScanner = true
                case .mealScan:
                    showMealScanner = true
                case .customFood:
                    showCustomFood = true
                case .waterTracker:
                    showWaterTracker = true
                case .weightEntry:
                    showWeightEntry = true
                case .exercise:
                    router.switchTo(tab: .workout)
                }
            }
        }) {
            QuickActionsSheet(
                onLogFood: {
                    pendingDestination = .foodSearch
                    showQuickActions = false
                },
                onBarcodeScan: {
                    pendingDestination = .barcodeScan
                    showQuickActions = false
                },
                onMealScan: {
                    pendingDestination = .mealScan
                    showQuickActions = false
                },
                onCustomFood: {
                    pendingDestination = .customFood
                    showQuickActions = false
                },
                onWater: {
                    pendingDestination = .waterTracker
                    showQuickActions = false
                },
                onWeight: {
                    pendingDestination = .weightEntry
                    showQuickActions = false
                },
                onExercise: {
                    pendingDestination = .exercise
                    showQuickActions = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
            .presentationBackground(ThemeColors.backgroundDark)
        }
        // Food Search
        .sheet(isPresented: $showFoodSearch) {
            if let vm = nutritionViewModel {
                NavigationStack {
                    FoodSearchView(viewModel: vm)
                }
            }
        }
        // Barcode Scanner
        .fullScreenCover(isPresented: $showBarcodeScanner) {
            if let vm = nutritionViewModel {
                BarcodeScannerView(
                    onDetect: { barcode in
                        showBarcodeScanner = false
                        vm.handleBarcodeScan(code: barcode, isPremium: subscriptionManager.isSubscribed)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            if vm.showBarcodeLimitPaywall {
                                showPaywall = true
                                vm.showBarcodeLimitPaywall = false
                            } else {
                                showFoodSearch = true
                            }
                        }
                    },
                    onCancel: { showBarcodeScanner = false }
                )
            }
        }
        // Meal Scanner (AI)
        .fullScreenCover(isPresented: $showMealScanner) {
            if let vm = nutritionViewModel {
                FoodScannerView(viewModel: vm)
            }
        }
        // Custom Food
        .sheet(isPresented: $showCustomFood) {
            if let vm = nutritionViewModel {
                NavigationStack {
                    CustomFoodView(initialFood: nil) { food in
                        Task { await vm.addEntry(food: food, quantity: food.servingSizeG, mealType: .snack) }
                        showCustomFood = false
                    }
                }
            }
        }
        // Water Tracker
        .sheet(isPresented: $showWaterTracker) {
            if let vm = nutritionViewModel {
                QuickWaterSheet(viewModel: vm)
                    .presentationDetents([.height(320)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(24)
                    .presentationBackground(ThemeColors.backgroundDark)
            }
        }
        // Weight Entry
        .sheet(isPresented: $showWeightEntry) {
            if let pvm = progressViewModel {
                WeightEntrySheet(viewModel: pvm)
            }
        }
        .onChange(of: progressViewModel?.showAddWeight) { _, newValue in
            if newValue == false && showWeightEntry {
                showWeightEntry = false
            }
        }
        // Paywall
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func initViewModelsIfNeeded() {
        guard let user = appState.currentUser else { return }
        if nutritionViewModel == nil {
            nutritionViewModel = NutritionViewModel(user: user, nutritionService: container.nutritionService)
        }
        if progressViewModel == nil {
            progressViewModel = container.makeProgressViewModel(user: user)
        }
    }
}

// MARK: - Quick Actions Sheet (Redesigned)

private struct QuickActionsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager

    let onLogFood: () -> Void
    let onBarcodeScan: () -> Void
    let onMealScan: () -> Void
    let onCustomFood: () -> Void
    let onWater: () -> Void
    let onWeight: () -> Void
    let onExercise: () -> Void

    @State private var appeared = false

    private var isPremium: Bool { subscriptionManager.isSubscribed }
    private var barcodeScansLeft: Int { BarcodeScanUsageTracker.scansRemaining(isPremium: isPremium) ?? 0 }
    private var mealScansLeft: Int { ScanUsageTracker.scansRemaining(isPremium: isPremium) ?? 0 }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Quick Actions")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.bottom, 2)

            // Scan Actions Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("SCAN & LOG")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(0.8)
                }

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 10) {
                    scanActionCard(
                        icon: "magnifyingglass",
                        title: "Log Food",
                        color: ThemeColors.primary,
                        scansLeft: nil,
                        action: onLogFood
                    )
                    scanActionCard(
                        icon: "barcode.viewfinder",
                        title: "Barcode",
                        color: Color(red: 1.0, green: 0.35, blue: 0.35),
                        scansLeft: isPremium ? nil : barcodeScansLeft,
                        action: onBarcodeScan
                    )
                    scanActionCard(
                        icon: "fork.knife",
                        title: "Custom",
                        color: .purple,
                        scansLeft: nil,
                        action: onCustomFood
                    )
                    scanActionCard(
                        icon: "camera.viewfinder",
                        title: "Meal Scan",
                        color: ThemeColors.info,
                        scansLeft: isPremium ? nil : mealScansLeft,
                        action: onMealScan
                    )
                }
            }

            // Trial scan info banner (only for non-premium)
            if !isPremium {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(.yellow)

                    Text("Trial: \(barcodeScansLeft) barcode · \(mealScansLeft) meal scans left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))

                    Spacer()

                    Text("Upgrade")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.yellow)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.yellow.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.yellow.opacity(0.15), lineWidth: 1)
                        )
                )
            }

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
                .padding(.vertical, 2)

            // Quick Tracking Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("QUICK TRACK")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(0.8)
                }

                HStack(spacing: 10) {
                    quickTrackButton(icon: "drop.fill", title: "Water", color: .cyan, action: onWater)
                    quickTrackButton(icon: "scalemass.fill", title: "Weight", color: .orange, action: onWeight)
                    quickTrackButton(icon: "flame.fill", title: "Exercise", color: ThemeColors.primary, action: onExercise)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                appeared = true
            }
        }
    }

    // MARK: - Scan Action Card

    private func scanActionCard(icon: String, title: String, color: Color, scansLeft: Int?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)

                // Scan limit badge
                if let remaining = scansLeft {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(remaining > 0 ? color : Color.red)
                            .frame(width: 5, height: 5)
                        Text("\(remaining) left")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(remaining > 0 ? color.opacity(0.8) : .red.opacity(0.8))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill((remaining > 0 ? color : Color.red).opacity(0.1))
                    )
                } else {
                    // Spacer to keep card height consistent
                    Color.clear.frame(height: 18)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Track Button

    private func quickTrackButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.12))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Water Sheet

private struct QuickWaterSheet: View {
    @Bindable var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss

    private let dailyTarget: Double = 2500

    var progress: Double {
        min(viewModel.todayLog.waterMl / dailyTarget, 1.0)
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Log Water")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.3))
                }
            }

            // Progress
            VStack(spacing: 8) {
                Text("\(Int(viewModel.todayLog.waterMl)) ml")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.cyan)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 8)
                        Capsule()
                            .fill(.cyan)
                            .frame(width: geo.size.width * progress, height: 8)
                            .animation(.spring(response: 0.4), value: progress)
                    }
                }
                .frame(height: 8)

                Text("of \(Int(dailyTarget)) ml")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))
            }

            // Quick add buttons
            HStack(spacing: 10) {
                waterButton(amount: 250)
                waterButton(amount: 500)
                waterButton(amount: 750)
            }
        }
        .padding(20)
    }

    private func waterButton(amount: Int) -> some View {
        Button {
            Task { await viewModel.addWater(ml: Double(amount)) }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.cyan)
                Text("+\(amount)ml")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.cyan.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.cyan.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
