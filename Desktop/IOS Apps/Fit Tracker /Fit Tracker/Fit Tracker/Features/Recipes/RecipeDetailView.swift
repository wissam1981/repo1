import SwiftUI

// MARK: - Recipe Detail View
// Full recipe page with hero image, nutrition card, ingredient list, and cooking instructions.

struct RecipeDetailView: View {

    private let meal: MealDetail
    @State private var vm: RecipeDetailViewModel?
    @State private var showInstructions = false
    @State private var showingLogConfirm = false
    
    @Environment(AppState.self) private var appState
    @Environment(DependencyContainer.self) private var container
    @Environment(\.dismiss) private var dismiss

    init(meal: MealDetail) {
        self.meal = meal
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ThemeColors.backgroundDark.ignoresSafeArea()

            if let vm = vm {
                ScrollView {
                    VStack(spacing: 0) {
                        // ── Hero Image ──────────────────────────────────────
                        heroImage(vm)

                        VStack(spacing: 20) {
                            // ── Name + badges ───────────────────────────────
                            titleSection(vm)

                            // ── Nutrition card ──────────────────────────────
                            nutritionSection(vm)

                            // ── Ingredients ─────────────────────────────────
                            ingredientsSection(vm)

                            // ── Instructions ────────────────────────────────
                            instructionsSection(vm)

                            // ── Bottom padding for the Log button ───────────
                            Color.clear.frame(height: 80)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
                .ignoresSafeArea(edges: .top)

                // ── Log Recipe Button ───────────────────────────────────────
                logButton(vm)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            } else {
                ProgressView()
                    .tint(ThemeColors.primary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let vm = vm {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { vm.toggleFavorite() } label: {
                        Image(systemName: vm.meal.isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(vm.meal.isFavorite ? .red : .white)
                    }
                }
                if let ytURL = vm.meal.youtubeURL {
                    ToolbarItem(placement: .topBarTrailing) {
                        Link(destination: ytURL) {
                            Image(systemName: "play.rectangle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .onAppear {
            initViewModelIfNeeded()
        }
        .task { 
            while vm == nil {
                try? await Task.sleep(nanoseconds: 100 * 1024 * 1024)
            }
            await vm?.loadNutrition() 
        }
        .alert("Recipe Logged! 🎉", isPresented: $showingLogConfirm) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("One serving of \(meal.name) has been added to today's nutrition log.")
        }
    }

    private func initViewModelIfNeeded() {
        guard let user = appState.currentUser else { return }
        if vm == nil {
            vm = RecipeDetailViewModel(
                meal: meal,
                nutritionService: container.nutritionService,
                user: user
            )
        }
    }

    // MARK: - Hero

    private func heroImage(_ vm: RecipeDetailViewModel) -> some View {
        ZStack(alignment: .bottomLeading) {
            AsyncRecipeImage(url: vm.meal.imageURL)
                .frame(height: 280)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.6)],
                        startPoint: .center, endPoint: .bottom
                    )
                )
        }
    }

    // MARK: - Title

    private func titleSection(_ vm: RecipeDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(vm.meal.name)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                if let category = vm.meal.category {
                    badge(category, icon: "tag.fill",  color: .orange)
                }
                if let area = vm.meal.area {
                    badge(area, icon: "globe", color: ThemeColors.primary)
                }
                if let mins = vm.meal.readyInMinutes {
                    badge("\(mins) min", icon: "clock.fill", color: .secondary)
                }
            }

            // Diet classification badges
            let matchingDiets = DietCategory.allCases.filter {
                $0.matches(meal: vm.meal)
            }
            if !matchingDiets.isEmpty {
                HStack(spacing: 6) {
                    ForEach(matchingDiets) { diet in
                        badge(diet.displayName, icon: diet.icon, color: diet.iconColor)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Nutrition

    private func nutritionSection(_ vm: RecipeDetailViewModel) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Nutrition")
                    .font(.headline)
                Spacer()

                // Servings stepper
                HStack(spacing: 10) {
                    Button { vm.updateServings(vm.servings - 1) } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(ThemeColors.primary.opacity(0.7))
                    }
                    Text("\(vm.servings) serving\(vm.servings == 1 ? "" : "s")")
                        .font(.caption.bold())
                    Button { vm.updateServings(vm.servings + 1) } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(ThemeColors.primary)
                    }
                }
            }

            if vm.isCalculating {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(ThemeColors.primary)
                    Text("Calculating from USDA data…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(ThemeColors.surfaceColor, in: RoundedRectangle(cornerRadius: 14))
            } else if vm.nutrition != nil {
                HStack(spacing: 0) {
                    macroCell(label: "Calories", value: Int(vm.perServingCalories), unit: "kcal", color: .orange)
                    Divider().frame(height: 40)
                    macroCell(label: "Protein",  value: Int(vm.perServingProtein),  unit: "g", color: .cyan)
                    Divider().frame(height: 40)
                    macroCell(label: "Carbs",    value: Int(vm.perServingCarbs),    unit: "g", color: .yellow)
                    Divider().frame(height: 40)
                    macroCell(label: "Fat",      value: Int(vm.perServingFat),      unit: "g", color: ThemeColors.primary)
                }
                .padding(.vertical, 12)
                .background(ThemeColors.surfaceColor, in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(ThemeColors.surfaceBorder, lineWidth: 1)
                )
            } else {
                Text("USDA nutrition data unavailable for some ingredients")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Ingredients

    private func ingredientsSection(_ vm: RecipeDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients (\(vm.meal.ingredients.count))")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(vm.meal.ingredients.enumerated()), id: \.offset) { idx, ing in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(ThemeColors.primary.opacity(0.15))
                            .frame(width: 8, height: 8)
                        Text(ing.name.capitalized)
                            .font(.subheadline)
                        Spacer()
                        Text(ing.measurement)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)

                    if idx < vm.meal.ingredients.count - 1 {
                        Divider().padding(.leading, 34)
                    }
                }
            }
            .background(ThemeColors.surfaceColor, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(ThemeColors.surfaceBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Instructions

    private func instructionsSection(_ vm: RecipeDetailViewModel) -> some View {
        Group {
            if let instructions = vm.meal.instructions, !instructions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showInstructions.toggle()
                        }
                    } label: {
                        HStack {
                            Text("Cooking Instructions")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: showInstructions ? "chevron.up" : "chevron.down")
                                .foregroundStyle(ThemeColors.primary)
                                .font(.caption.bold())
                        }
                    }

                    if showInstructions {
                        let steps = instructions
                            .components(separatedBy: "\r\n")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }

                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(idx + 1)")
                                        .font(.caption.bold())
                                        .foregroundStyle(ThemeColors.primary)
                                        .frame(width: 22, height: 22)
                                        .background(Circle().fill(ThemeColors.primary.opacity(0.15)))
                                    Text(step)
                                        .font(.subheadline)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(16)
                .background(ThemeColors.surfaceColor, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - Log Button

    private func logButton(_ vm: RecipeDetailViewModel) -> some View {
        Button {
            Task {
                let success = await vm.logServing(mealType: vm.currentMealType)
                if success {
                    showingLogConfirm = true
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                Text("Log 1 Serving to Today")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(Int(vm.perServingCalories)) kcal")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.15)))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(colors: [ThemeColors.primary.opacity(0.85), ThemeColors.primary],
                               startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .shadow(color: ThemeColors.primary.opacity(0.4), radius: 10, x: 0, y: 4)
        }
        .disabled(vm.nutrition == nil)
        .opacity(vm.nutrition == nil ? 0.5 : 1)
    }

    // MARK: - Helpers

    private func macroCell(label: String, value: Int, unit: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(unit)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func badge(_ text: String, icon: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.caption.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}
