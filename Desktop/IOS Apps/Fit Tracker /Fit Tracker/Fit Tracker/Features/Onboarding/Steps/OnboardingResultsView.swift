import SwiftUI

// MARK: - Onboarding Results Step (BMR/TDEE/Macro Summary)

struct OnboardingResultsView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var appeared = false
    @State private var showCalories = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                headerSection

                calorieCard

                macroBreakdown

                detailCards

                if viewModel.saveError != nil {
                    errorBanner
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4)) {
                showCalories = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ThemeColors.primary.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ThemeColors.primary, ThemeColors.info],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.5)

            Text("Your Personalized Plan")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Based on your body metrics and goals, here's your daily targets.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Calorie Card

    private var calorieCard: some View {
        let result = viewModel.calculationResult

        return VStack(spacing: 8) {
            Text("Daily Calories")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))

            Text("\(result.targetCalories)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [ThemeColors.primary, ThemeColors.info],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: ThemeColors.primary.opacity(0.3), radius: 8, y: 0)
                .scaleEffect(showCalories ? 1 : 0.5)
                .opacity(showCalories ? 1 : 0)

            Text("kcal / day")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.4))

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)
                .padding(.vertical, 4)

            HStack(spacing: 24) {
                metricPill(label: "BMR", value: "\(Int(result.bmr))")
                metricPill(label: "TDEE", value: "\(Int(result.tdee))")
                metricPill(label: "Target", value: "\(result.targetCalories)")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [ThemeColors.primary.opacity(0.3), ThemeColors.info.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    // MARK: - Macro Breakdown

    private var macroBreakdown: some View {
        let result = viewModel.calculationResult

        return VStack(spacing: 12) {
            Text("Daily Macro Targets")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                macroCard(name: "Protein", grams: result.targetProteinG, color: .orange, icon: "flame.fill")
                macroCard(name: "Carbs", grams: result.targetCarbsG, color: ThemeColors.success, icon: "leaf.fill")
                macroCard(name: "Fat", grams: result.targetFatG, color: .purple, icon: "drop.fill")
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    private func macroCard(name: String, grams: Int, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(String(localized: "\(grams)g"))
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(name)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Detail Cards

    private var detailCards: some View {
        VStack(spacing: 8) {
            detailRow(icon: "person.fill", label: "Gender", value: viewModel.gender.displayName)
            detailRow(icon: "calendar", label: "Age", value: "\(viewModel.ageYears) years")
            detailRow(icon: "ruler", label: "Height", value: "\(Int(viewModel.heightCm)) cm")
            detailRow(icon: "scalemass", label: "Weight", value: String(format: "%.1f kg", viewModel.weightKg))
            detailRow(icon: "figure.run", label: "Activity", value: viewModel.activityLevel.displayName)
            detailRow(icon: "target", label: "Goal", value: viewModel.goal.displayName)
            if viewModel.goal != .maintain {
                detailRow(icon: "scalemass.fill", label: "Goal Weight",
                         value: viewModel.useMetric
                            ? String(format: "%.1f kg", viewModel.goalWeightKg)
                            : String(format: "%.1f lbs", viewModel.goalWeightKg * 2.20462))
                let delta = abs(viewModel.weightKg - viewModel.goalWeightKg)
                let speed = viewModel.selectedGoalSpeed.kgPerWeek
                let weeks = speed > 0 ? Int(ceil(delta / speed)) : 0
                if weeks > 0 {
                    detailRow(icon: "clock.fill", label: "Est. Time", value: "~\(weeks) weeks")
                }
                detailRow(icon: "calendar", label: "Target Date",
                         value: viewModel.goalTargetDate.formatted(date: .abbreviated, time: .omitted))
            }
            if viewModel.goal != .maintain {
                detailRow(icon: "speedometer", label: "Pace", value: viewModel.selectedGoalSpeed.description)
            }
            detailRow(icon: "chart.bar.fill", label: "BMI", value: String(format: "%.1f (%@)", viewModel.bmi, viewModel.bmiCategory))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
        )
        .opacity(appeared ? 1 : 0)
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(ThemeColors.primary)
            Text(label)
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .font(.subheadline)
    }

    // MARK: - Metric Pill

    private func metricPill(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    // MARK: - Error Banner

    private var errorBanner: some View {
        Text(viewModel.saveError ?? "")
            .font(.caption)
            .foregroundStyle(ThemeColors.error)
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(ThemeColors.errorBackground)
            )
    }
}
