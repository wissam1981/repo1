import SwiftUI

// MARK: - Food Search View
// Search for food items from local database + USDA API, then select quantity and add to log.

struct FoodSearchView: View {
    @Bindable var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var searchMode: SearchMode = .database
    
    enum SearchMode: String, CaseIterable {
        case database = "Database"
        case recipes = "My Recipes"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Mode Picker
                Picker("Mode", selection: $searchMode) {
                    ForEach(SearchMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                if searchMode == .database {
                    // Search bar
                    searchBar

                    // AI Parse chip (floating)
                    aiParseChip

                    // Results
                    List {
                        if viewModel.isSearching {
                            loadingState
                        } else if let error = viewModel.searchError {
                            errorState(error)
                        } else if viewModel.searchResults.isEmpty && viewModel.searchQuery.isEmpty {
                            recentFoodsSection
                        } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                            emptyState
                        } else {
                            ForEach(viewModel.searchResults) { food in
                                NavigationLink(value: food) {
                                    FoodSearchRow(food: food) {
                                        Task {
                                            await viewModel.addEntry(food: food, quantity: food.servingSizeG, mealType: viewModel.selectedMealType)
                                            dismiss()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                } else {
                    RecipeListView(viewModel: viewModel)
                }
            }
            .navigationTitle("Add \(viewModel.selectedMealType.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        Button {
                            viewModel.showBarcodeScanner = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                                .foregroundStyle(ThemeColors.primary)
                        }
                        
                        Button {
                            viewModel.showFoodScanner = true
                        } label: {
                            Image(systemName: "camera.viewfinder")
                                .foregroundStyle(.secondary)
                        }
                        
                        Button {
                            viewModel.showCustomFood = true
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                    }
                }
            }
            .navigationDestination(for: FoodItem.self) { food in
                FoodDetailView(
                    food: food,
                    mealType: viewModel.selectedMealType
                ) { food, quantity, meal in
                    Task {
                        await viewModel.addEntry(food: food, quantity: quantity, mealType: meal)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCustomFood) {
                CustomFoodView { food in
                    Task {
                        await viewModel.addEntry(food: food, quantity: food.servingSizeG, mealType: viewModel.selectedMealType)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showFoodScanner) {
                FoodScannerView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showBarcodeScanner) {
                BarcodeScannerView(
                    onDetect: { code in
                        viewModel.handleBarcodeScan(code: code, isPremium: subscriptionManager.isSubscribed)
                    },
                    onCancel: {
                        viewModel.showBarcodeScanner = false
                    }
                )
                .edgesIgnoringSafeArea(.all)
                .presentationDetents([.large])
            }
            .sheet(isPresented: $viewModel.showBarcodeLimitPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $viewModel.showParsedMealSheet) {
                AIParsedMealSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showAIParseLimitPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search foods (e.g. chicken breast)...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onSubmit {
                    viewModel.retrySearch()
                }

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                    viewModel.searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(ThemeColors.surfaceColor))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - AI Parse Chip

    @ViewBuilder
    private var aiParseChip: some View {
        let query = viewModel.searchQuery
        let words = query.split(separator: " ").count
        let showChip = (viewModel.searchResults.isEmpty && query.count >= 3) || words >= 3

        if showChip && !viewModel.isSearching {
            if viewModel.isAIParsing {
                // Loading state
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(ThemeColors.primary)
                    Text("Analyzing your meal...")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ThemeColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(ThemeColors.primary.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeColors.primary.opacity(0.2), lineWidth: 1))
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            } else {
                Button {
                    viewModel.parseWithAI(isPremium: subscriptionManager.isSubscribed)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundStyle(ThemeColors.primary)
                        Text("Let AI parse this meal")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ThemeColors.textSecondary)

                        if let remaining = AIFoodParserUsageTracker.parsesRemaining(isPremium: subscriptionManager.isSubscribed) {
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(remaining > 0 ? Color.green : Color.red)
                                    .frame(width: 6, height: 6)
                                Text("\(remaining) left")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(ThemeColors.textSecondary)
                            }
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(ThemeColors.primary.opacity(0.06))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(ThemeColors.primary.opacity(0.15), lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
        }

        // AI Parse error banner
        if let error = viewModel.aiParseError {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Button {
                    viewModel.aiParseError = nil
                    viewModel.parseWithAI(isPremium: subscriptionManager.isSubscribed)
                } label: {
                    Text("Retry")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(ThemeColors.primary)
                }
                Button {
                    viewModel.aiParseError = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(ThemeColors.textSecondary)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.1)))
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        HStack(spacing: 12) {
            Spacer()
            ProgressView()
            Text("Searching offline database...")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 24)
        .listRowSeparator(.hidden)
    }

    // MARK: - Error State

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                viewModel.retrySearch()
            }
            .buttonStyle(.borderedProminent)
            .tint(ThemeColors.info)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowSeparator(.hidden)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No results found")
                .font(.headline)
                .foregroundStyle(.secondary)
            Button("Create Custom Food") {
                viewModel.showCustomFood = true
            }
            .buttonStyle(.borderedProminent)
            .tint(ThemeColors.primary)
            .foregroundStyle(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowSeparator(.hidden)
    }

    // MARK: - Recent Foods State

    @ViewBuilder
    private var recentFoodsSection: some View {
        if !viewModel.recentFoods.isEmpty {
            Section("Recent & Frequent") {
                ForEach(viewModel.recentFoods) { food in
                    NavigationLink(value: food) {
                        FoodSearchRow(food: food) {
                            Task {
                                await viewModel.addEntry(food: food, quantity: food.servingSizeG, mealType: viewModel.selectedMealType)
                                dismiss()
                            }
                        }
                    }
                }
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Search to log food")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Or create a custom food")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .listRowSeparator(.hidden)
        }
    }
}

// MARK: - Food Search Row

private struct FoodSearchRow: View {
    let food: FoodItem
    let onQuickAdd: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(food.name)
                            .font(.subheadline.bold())
                            .lineLimit(2)
                        
                        // Display Arabic Translation if present
                        if let arName = food.nameAr, !arName.isEmpty {
                            Text(arName)
                                .font(.caption.bold())
                                .foregroundStyle(ThemeColors.primary)
                                .environment(\.layoutDirection, .rightToLeft)
                        }
                    }

                    if food.source == .usda {
                        Text("USDA")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(ThemeColors.primary.opacity(0.8)))
                    }
                }

                HStack(spacing: 8) {
                    if let brand = food.brandName, !brand.isEmpty {
                        Text(brand)
                            .foregroundStyle(.tertiary)
                    }

                    Text("\(Int(food.calories)) kcal")

                    // Protein emphasized
                    Text("P: \(Int(food.proteinG))g")
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)

                    Text("C: \(Int(food.carbsG))g")
                    Text("F: \(Int(food.fatG))g")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text("per \(formattedServing(food))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
            
            Spacer()
            
            Button {
                onQuickAdd()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(ThemeColors.primary)
                    .padding(8)
            }
            .buttonStyle(.borderless)
        }
    }

    private func formattedServing(_ food: FoodItem) -> String {
        let size = food.servingSizeG
        if size == floor(size) {
            return "\(Int(size))\(food.servingUnit)"
        }
        return String(format: "%.1f%@", size, food.servingUnit)
    }
}
