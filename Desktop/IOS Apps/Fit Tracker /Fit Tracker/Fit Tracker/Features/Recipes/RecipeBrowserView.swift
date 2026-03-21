import SwiftUI

// MARK: - Recipe Browser View
// Full-featured recipe search with diet filters, cuisine chips, favorites, and offline fallback.

struct RecipeBrowserView: View {

    @State private var vm = RecipeBrowserViewModel()
    @State private var selectedMeal: MealDetail?

    var body: some View {
        NavigationStack {
            ZStack {
                ThemeColors.backgroundDark
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    // Diet type filter chips (prominent)
                    dietFilterChips
                        .padding(.bottom, 6)

                    // Cuisine chips
                    if !vm.cuisines.isEmpty {
                        cuisineChips
                            .padding(.bottom, 10)
                    }

                    // Content
                    ScrollView {
                        LazyVStack(spacing: 20, pinnedViews: .sectionHeaders) {
                            // Featured section (when idle)
                            if vm.searchQuery.isEmpty && vm.selectedDiet == nil && vm.selectedCuisine == nil {
                                featuredSection
                            }

                            // Favorites section
                            if vm.searchQuery.isEmpty && vm.selectedDiet == nil && !vm.favorites.isEmpty {
                                Section {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 14) {
                                            ForEach(vm.favorites) { meal in
                                                RecipeCardView(meal: meal) {
                                                    vm.toggleFavorite(meal)
                                                }
                                                .frame(width: 170)
                                                .onTapGesture { selectedMeal = meal }
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                } header: {
                                    sectionHeader("My Favorites", icon: "heart.fill", iconColor: .red)
                                }
                            }

                            // Results grid
                            if !vm.recipes.isEmpty {
                                Section {
                                    LazyVGrid(
                                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                                        spacing: 14
                                    ) {
                                        ForEach(vm.recipes) { meal in
                                            RecipeCardView(meal: meal) {
                                                vm.toggleFavorite(meal)
                                            }
                                            .onTapGesture { selectedMeal = meal }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                } header: {
                                    sectionHeader(resultsTitle, icon: "fork.knife", iconColor: ThemeColors.primary)
                                }
                            } else if !vm.isLoading {
                                emptyState
                            }

                            // Offline banner
                            if vm.isOffline {
                                offlineBadge
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .refreshable { await vm.search() }
                }
            }
            .navigationTitle("Recipes")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .top) {
                if vm.isLoading {
                    ProgressView()
                        .tint(ThemeColors.primary)
                        .padding(.top, 60)
                }
            }
            .navigationDestination(item: $selectedMeal) { meal in
                RecipeDetailView(meal: meal)
            }
        }
    }

    // MARK: - Results Title

    private var resultsTitle: String {
        var parts: [String] = []
        if let diet = vm.selectedDiet { parts.append(diet.displayName) }
        if let cuisine = vm.selectedCuisine { parts.append(cuisine) }
        if parts.isEmpty {
            return "Results"
        }
        return parts.joined(separator: " ") + " Recipes"
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(ThemeColors.primary)
            TextField("Search recipes...", text: $vm.searchQuery)
                .autocorrectionDisabled()
                .onSubmit { Task { await vm.search() } }
                .submitLabel(.search)
            if !vm.searchQuery.isEmpty {
                Button { vm.searchQuery = ""; vm.recipes = [] } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(ThemeColors.surfaceColor, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(ThemeColors.surfaceBorder, lineWidth: 1)
        )
        .onChange(of: vm.searchQuery) { _, newVal in
            guard !newVal.isEmpty else { vm.recipes = []; return }
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                if vm.searchQuery == newVal { await vm.search() }
            }
        }
    }

    // MARK: - Diet Filter Chips

    private var dietFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DietCategory.allCases) { diet in
                    dietChip(diet, isSelected: vm.selectedDiet == diet) {
                        vm.selectDiet(diet)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func dietChip(_ diet: DietCategory, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: diet.icon)
                    .font(.system(size: 13))
                Text(diet.displayName)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(isSelected ? .black : diet.iconColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isSelected ? diet.iconColor : diet.iconColor.opacity(0.12))
            )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // MARK: - Cuisine Chips

    private var cuisineChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                cuisineChip("All", isSelected: vm.selectedCuisine == nil) {
                    vm.selectCuisine(nil)
                }
                ForEach(vm.cuisines, id: \.self) { cuisine in
                    cuisineChip(cuisine, isSelected: vm.selectedCuisine == cuisine) {
                        vm.selectCuisine(cuisine)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func cuisineChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? .black : ThemeColors.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(isSelected ? ThemeColors.primary : ThemeColors.primary.opacity(0.12))
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // MARK: - Featured Section

    @ViewBuilder
    private var featuredSection: some View {
        if !vm.popularRecipes.isEmpty {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(vm.popularRecipes) { meal in
                            RecipeCardView(meal: meal) {
                                vm.toggleFavorite(meal)
                            }
                            .frame(width: 170)
                            .onTapGesture { selectedMeal = meal }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            } header: {
                sectionHeader("Featured", icon: "star.fill", iconColor: .yellow)
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, icon: String? = nil, iconColor: Color = .primary) -> some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(iconColor)
            }
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(ThemeColors.backgroundDark)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        Group {
            if let diet = vm.selectedDiet {
                VStack(spacing: 14) {
                    Image(systemName: diet.icon)
                        .font(.system(size: 48))
                        .foregroundStyle(diet.iconColor.opacity(0.5))
                    Text("No \(diet.displayName) recipes found")
                        .font(.headline)
                    Text("Try searching for a specific dish or selecting a different cuisine.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.top, 60)
            } else if !vm.searchQuery.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(ThemeColors.primary.opacity(0.5))
                    Text("No recipes found")
                        .font(.headline)
                    Text("Try a different keyword or cuisine")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)
            }
        }
    }

    // MARK: - Offline Badge

    private var offlineBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text("Offline — showing cached recipes")
                .font(.caption)
        }
        .foregroundStyle(.orange)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(.orange.opacity(0.1)))
    }
}
