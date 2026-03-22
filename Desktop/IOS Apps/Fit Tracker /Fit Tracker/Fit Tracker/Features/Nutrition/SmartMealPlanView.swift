import SwiftUI

// MARK: - Smart Meal Plan View
// Displays the AI-generated full day meal plan and allows one-tap logging.

struct SmartMealPlanView: View {
    let meals: [GeneratedMeal]
    let onLogAll: ( [GeneratedMeal] ) -> Void
    @Environment(\.dismiss) private var dismiss

    var totalCalories: Int { meals.reduce(0) { $0 + $1.totalCalories } }
    var totalProtein: Int { meals.reduce(0) { $0 + $1.totalProtein } }
    var totalCarbs: Int { meals.reduce(0) { $0 + $1.totalCarbs } }
    var totalFat: Int { meals.reduce(0) { $0 + $1.totalFat } }

    var body: some View {
        NavigationStack {
            ZStack {
                ThemeColors.backgroundDark.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header summary
                        VStack(spacing: 16) {
                            Text("Your AI Meal Plan")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            HStack(spacing: 16) {
                                macroBadge(title: "CAL", value: "\(totalCalories)", color: ThemeColors.primary)
                                macroBadge(title: "PRO", value: "\(totalProtein)g", color: .orange)
                                macroBadge(title: "CARB", value: "\(totalCarbs)g", color: .cyan)
                                macroBadge(title: "FAT", value: "\(totalFat)g", color: .purple)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 24)

                        // Meals list
                        VStack(spacing: 20) {
                            ForEach(meals) { meal in
                                mealCard(for: meal)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Actions
                        Button {
                            onLogAll(meals)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "tray.and.arrow.down.fill")
                                Text("Log Entire Day")
                            }
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(ThemeColors.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: ThemeColors.primary.opacity(0.4), radius: 10, y: 5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.title3)
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private func mealCard(for meal: GeneratedMeal) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Meal Header
            HStack {
                Text(meal.mealType.capitalized)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text(String(localized: "\(meal.totalCalories) kcal"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(ThemeColors.primary)
            }
            .padding(.bottom, 4)
            
            Divider().background(Color.white.opacity(0.1))

            // Items
            VStack(alignment: .leading, spacing: 12) {
                ForEach(meal.items) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.9))
                            
                            Text("\(Int(item.servingSizeG))g • P:\(Int(item.proteinG)) C:\(Int(item.carbsG)) F:\(Int(item.fatG))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Spacer()
                        Text("\(Int(item.calories))")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func macroBadge(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
