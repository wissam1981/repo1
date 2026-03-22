import SwiftUI

// MARK: - Onboarding Goal Step

struct OnboardingGoalView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            headerSection

            goalCards

            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [ThemeColors.primary, ThemeColors.info],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -10)

            Text("What's your goal?")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("We'll adjust your calorie and macro targets based on this.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Goal Cards

    private var goalCards: some View {
        VStack(spacing: 14) {
            ForEach(Array(FitnessGoal.allCases.enumerated()), id: \.element) { index, goal in
                GoalCard(
                    goal: goal,
                    isSelected: viewModel.goal == goal
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.goal = goal
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1), value: appeared)
            }
        }
    }
}

// MARK: - Goal Card

private struct GoalCard: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: goal.icon)
                        .font(.title)
                        .foregroundStyle(isSelected ? cardColor : .white.opacity(0.5))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.displayName)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(goal.description)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? cardColor : .white.opacity(0.2))
                }

                // Info bar
                HStack {
                    infoChip(label: "Protein", value: proteinHint)
                    Spacer()
                    infoChip(label: "Calories", value: calorieHint)
                }
                .font(.caption2)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? cardColor.opacity(0.1) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? cardColor.opacity(0.6) : Color.white.opacity(0.06), lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }

    private var cardColor: Color {
        switch goal {
        case .lose:     return .orange
        case .maintain: return ThemeColors.info
        case .gain:     return ThemeColors.success
        }
    }

    private var proteinHint: String {
        switch goal {
        case .lose:     return "High (1.8g/kg)"
        case .maintain: return "Moderate (1.4g/kg)"
        case .gain:     return "High (2.0g/kg)"
        }
    }

    private var calorieHint: String {
        switch goal {
        case .lose:     return "Deficit"
        case .maintain: return "Maintenance"
        case .gain:     return "Surplus"
        }
    }

    private func infoChip(label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(.white.opacity(0.4))
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}
