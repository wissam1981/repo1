import SwiftUI

struct RecipeListView: View {
    @Bindable var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var recipes: [Recipe] = []
    @State private var showBuilder = false
    
    var body: some View {
        VStack {
            if recipes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle.portrait")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No Saved Recipes")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Group ingredients into a single meal for easy logging.")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Create Recipe") {
                        showBuilder = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ThemeColors.primary)
                    .foregroundStyle(.black)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(recipes) { recipe in
                        RecipeRow(recipe: recipe) {
                            Task {
                                await logRecipe(recipe)
                                dismiss()
                            }
                        }
                    }
                    .onDelete(perform: deleteRecipe)
                }
                .listStyle(.plain)
                
                Button {
                    showBuilder = true
                } label: {
                    Text("Create New Recipe")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(ThemeColors.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding()
                }
            }
        }
        .onAppear {
            loadRecipes()
        }
        .sheet(isPresented: $showBuilder) {
            RecipeBuilderView(viewModel: viewModel) { newRecipe in
                Task {
                    await RecipeService.shared.saveRecipe(newRecipe)
                    loadRecipes()
                }
            }
        }
    }
    
    private func loadRecipes() {
        Task {
            recipes = await RecipeService.shared.getRecipes()
        }
    }
    
    private func deleteRecipe(at offsets: IndexSet) {
        offsets.forEach { index in
            let recipe = recipes[index]
            Task {
                await RecipeService.shared.deleteRecipe(id: recipe.id)
                loadRecipes()
            }
        }
    }
    
    private func logRecipe(_ recipe: Recipe) async {
        await viewModel.logRecipe(recipe, mealType: viewModel.selectedMealType)
    }
}

private struct RecipeRow: View {
    let recipe: Recipe
    let onLog: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                
                Text("\(recipe.ingredients.count) ingredients")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    Text("\(Int(recipe.totalCalories)) kcal")
                    Text("P: \(Int(recipe.totalProteinG))g").foregroundStyle(.orange)
                    Text("C: \(Int(recipe.totalCarbsG))g")
                    Text("F: \(Int(recipe.totalFatG))g")
                }
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            }
            
            Spacer()
            
            Button {
                onLog()
            } label: {
                Text("Log")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ThemeColors.primary.opacity(0.15))
                    .foregroundStyle(ThemeColors.primary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
}
