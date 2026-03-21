import SwiftUI

struct RecipeBuilderView: View {
    @Bindable var viewModel: NutritionViewModel
    let onSave: (Recipe) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var recipeName = ""
    @State private var ingredients: [NutritionEntry] = []
    
    // For search overlay inside builder
    @State private var showSearch = false
    
    var totalCalories: Double { ingredients.reduce(0) { $0 + $1.calories } }
    var totalProteinG: Double { ingredients.reduce(0) { $0 + $1.proteinG } }
    var totalCarbsG: Double { ingredients.reduce(0) { $0 + $1.carbsG } }
    var totalFatG: Double { ingredients.reduce(0) { $0 + $1.fatG } }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header (Name & Macros)
                VStack(spacing: 16) {
                    TextField("Recipe Name", text: $recipeName)
                        .font(.title2.bold())
                        .padding()
                        .background(ThemeColors.surfaceColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    
                    // Total Macros Banner
                    HStack(spacing: 16) {
                        macroStat(label: "Calories", value: "\(Int(totalCalories))", color: .primary)
                        macroStat(label: "Protein", value: "\(Int(totalProteinG))g", color: .orange)
                        macroStat(label: "Carbs", value: "\(Int(totalCarbsG))g", color: .green)
                        macroStat(label: "Fat", value: "\(Int(totalFatG))g", color: ThemeColors.secondary)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
                .background(ThemeColors.surfaceColor.opacity(0.3))
                
                // Ingredients List
                List {
                    Section {
                        if ingredients.isEmpty {
                            Text("No ingredients added yet.")
                                .foregroundStyle(.secondary)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(ingredients) { entry in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(entry.foodName)
                                            .font(.subheadline.bold())
                                        Text("\(Int(entry.servingQuantity)) \(entry.servingUnit) • \(Int(entry.calories)) kcal")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                            .onDelete(perform: removeIngredient)
                        }
                    } header: {
                        HStack {
                            Text("Ingredients")
                            Spacer()
                            Button("Add Ingredient") {
                                showSearch = true
                            }
                            .font(.caption.bold())
                            .foregroundStyle(ThemeColors.primary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                Button {
                    let recipe = Recipe(name: recipeName.isEmpty ? "My Recipe" : recipeName, ingredients: ingredients)
                    onSave(recipe)
                    dismiss()
                } label: {
                    Text("Save Recipe")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(ThemeColors.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding()
                }
                .disabled(ingredients.isEmpty)
            }
            .navigationTitle("New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showSearch) {
                // Reuse existing FoodSearchView, but hijack the action to add to ingredients instead of daily log!
                // We'll create a dedicated mini search for recipes if needed, but for now we can present food search
                // Wait, FoodSearchView directly calls viewModel.addEntry. To hijack it we need a custom search view or flag.
                BuilderIngredientSearchView(viewModel: viewModel) { food, quantity in
                    let entry = NutritionEntry(from: food, quantity: quantity, mealType: .snack)
                    ingredients.append(entry)
                }
            }
        }
    }
    
    private func removeIngredient(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }
    
    private func macroStat(label: String, value: String, color: Color) -> some View {
        VStack {
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(ThemeColors.surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// Custom mini search to add ingredients without affecting today's log directly.
struct BuilderIngredientSearchView: View {
    @Bindable var viewModel: NutritionViewModel
    let onAdd: (FoodItem, Double) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search ingredient...", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)
                        .onSubmit { viewModel.retrySearch() }
                    if !viewModel.searchQuery.isEmpty {
                        Button {
                            viewModel.searchQuery = ""
                            viewModel.searchResults = []
                        } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(ThemeColors.surfaceColor))
                .padding()
                
                List {
                    if viewModel.isSearching {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        ForEach(viewModel.searchResults) { food in
                            NavigationLink(destination: FoodDetailView(food: food, mealType: .snack) { food, quantity, _ in
                                onAdd(food, quantity)
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(food.name).font(.subheadline.bold())
                                        Text("\(Int(food.calories)) kcal per \(Int(food.servingSizeG))\(food.servingUnit)")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
