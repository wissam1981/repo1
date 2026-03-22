import SwiftUI

// MARK: - Food Detail View
// Shows food details with per-100g reference, allows gram-based quantity adjustment,
// and adds entry to log. Protein is visually emphasized per PRD.

struct FoodDetailView: View {
    @State private var food: FoodItem
    let mealType: MealType
    let onAdd: (FoodItem, Double, MealType) -> Void

    @State private var quantity: Double
    @State private var selectedMeal: MealType
    @State private var quantityText: String
    
    @State private var isEditingNutrition = false

    init(food: FoodItem, mealType: MealType, onAdd: @escaping (FoodItem, Double, MealType) -> Void) {
        self._food = State(initialValue: food)
        self.mealType = mealType
        self.onAdd = onAdd
        let initial = food.servingSizeG
        self._quantity = State(initialValue: initial)
        self._selectedMeal = State(initialValue: mealType)
        self._quantityText = State(initialValue: initial == floor(initial) ? "\(Int(initial))" : String(format: "%.1f", initial))
    }

    private var macros: MacroNutrients {
        food.macros(forQuantity: quantity)
    }

    private var per100g: MacroNutrients {
        food.macros(forQuantity: 100)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Food name + source badge
                headerSection

                // Per-100g reference card
                per100gSection

                // Quantity input
                quantitySection

                // Computed macros for selected portion
                portionMacroSection

                // Meal Picker
                mealPicker

                // Add Button
                Button {
                    onAdd(food, quantity, selectedMeal)
                } label: {
                    Text(String(localized: "Add to \(selectedMeal.displayName)"))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(ThemeColors.info)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(24)
        }
        .navigationTitle("Food Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit Nutrition") {
                    isEditingNutrition = true
                }
            }
        }
        .sheet(isPresented: $isEditingNutrition) {
            CustomFoodView(initialFood: food) { editedFood in
                food = editedFood
                quantity = editedFood.servingSizeG
                quantityText = quantity == floor(quantity) ? "\(Int(quantity))" : String(format: "%.1f", quantity)
                isEditingNutrition = false
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text(food.name)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                if let brand = food.brandName, !brand.isEmpty {
                    Text(brand)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if food.source == .usda {
                    Text("USDA Verified")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.green.opacity(0.8)))
                }
            }
        }
    }

    // MARK: - Per 100g Reference

    private var per100gSection: some View {
        VStack(spacing: 8) {
            Text("Per 100g")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                miniMacro(label: "Calories", value: "\(Int(per100g.calories))", unit: "kcal", color: .cyan)
                Divider().frame(height: 32)
                miniMacro(label: "Protein", value: "\(Int(per100g.proteinG))", unit: "g", color: .orange)
                Divider().frame(height: 32)
                miniMacro(label: "Carbs", value: "\(Int(per100g.carbsG))", unit: "g", color: .green)
                Divider().frame(height: 32)
                miniMacro(label: "Fat", value: "\(Int(per100g.fatG))", unit: "g", color: .purple)
                Divider().frame(height: 32)
                miniMacro(label: "Fiber", value: "\(Int(per100g.fiberG))", unit: "g", color: .brown)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(ThemeColors.surfaceColor))
    }

    private func miniMacro(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(color)
            Text(unit)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quantity Section

    private var quantitySection: some View {
        VStack(spacing: 12) {
            Text("Portion Size (grams)")
                .font(.headline)

            HStack(spacing: 16) {
                Button { adjustQuantity(by: -10) } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                TextField("Grams", text: $quantityText)
                    .font(.title.bold().monospacedDigit())
                    .multilineTextAlignment(.center)
                    .frame(width: 100)
                    .keyboardType(.decimalPad)
                    .onChange(of: quantityText) {
                        if let val = Double(quantityText), val > 0 {
                            quantity = val
                        }
                    }

                Button { adjustQuantity(by: 10) } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.cyan)
                }
            }

            Text("g")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Quick gram presets
            HStack(spacing: 8) {
                quickGramButton(grams: 50)
                quickGramButton(grams: 100)
                quickGramButton(grams: 150)
                quickGramButton(grams: 200)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColors.surfaceColor))
    }

    private func quickGramButton(grams: Double) -> some View {
        Button {
            quantity = grams
            quantityText = "\(Int(grams))"
        } label: {
            Text("\(Int(grams))g")
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(
                        quantity == grams
                            ? ThemeColors.info
                            : ThemeColors.surfaceColor
                    )
                )
                .foregroundStyle(
                    quantity == grams ? .white : .primary
                )
        }
    }

    private func adjustQuantity(by amount: Double) {
        quantity = max(1, quantity + amount)
        quantityText = quantity == floor(quantity) ? "\(Int(quantity))" : String(format: "%.1f", quantity)
    }

    // MARK: - Portion Macro Section (computed for selected grams)

    private var portionMacroSection: some View {
        VStack(spacing: 12) {
            Text(String(localized: "Your Portion (\(Int(quantity))g)"))
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            // Calories prominent
            Text(String(localized: "\(Int(macros.calories)) kcal"))
                .font(.title.bold())
                .foregroundStyle(.cyan)

            HStack(spacing: 16) {
                // Protein emphasized larger
                macroColumn(
                    label: "Protein",
                    value: String(format: "%.1f", macros.proteinG),
                    unit: "g",
                    color: .orange,
                    emphasized: true
                )
                macroColumn(label: "Carbs", value: String(format: "%.1f", macros.carbsG), unit: "g", color: .green)
                macroColumn(label: "Fat", value: String(format: "%.1f", macros.fatG), unit: "g", color: .purple)
                macroColumn(label: "Fiber", value: String(format: "%.1f", macros.fiberG), unit: "g", color: .brown)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColors.surfaceColor))
    }

    private func macroColumn(label: String, value: String, unit: String, color: Color, emphasized: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text("\(value)\(unit)")
                .font(emphasized ? .title3.bold() : .headline)
                .foregroundStyle(color)
            Text(label)
                .font(emphasized ? .caption.bold() : .caption)
                .foregroundStyle(emphasized ? color : .secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Meal Picker

    private var mealPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meal")
                .font(.headline)

            Picker("Meal", selection: $selectedMeal) {
                ForEach(MealType.allCases, id: \.self) { meal in
                    Label(meal.displayName, systemImage: meal.icon).tag(meal)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
