import SwiftUI

// MARK: - Onboarding Goal Speed Step

struct OnboardingGoalSpeedView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            headerSection

            speedCards

            projectionNote

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
            Image(systemName: "speedometer")
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

            Text("How fast?")
                .font(.title.bold())
                .foregroundStyle(.white)

            if !headerSubtitle.isEmpty {
                Text(headerSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var headerSubtitle: String {
        switch viewModel.goal {
        case .lose:
            return "A moderate pace helps preserve muscle while losing fat."
        case .gain:
            return "A moderate pace minimizes unwanted fat gain."
        case .maintain:
            return ""
        }
    }

    // MARK: - Speed Cards

    private var speedCards: some View {
        VStack(spacing: 12) {
            ForEach(Array(GoalSpeed.options.enumerated()), id: \.element.id) { index, speed in
                SpeedCard(
                    speed: speed,
                    goal: viewModel.goal,
                    isSelected: viewModel.selectedGoalSpeed.id == speed.id
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.selectedGoalSpeed = speed
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.08), value: appeared)
            }
        }
    }

    // MARK: - Projection

    private var projectionNote: some View {
        Group {
            let weeklyCal = Int(viewModel.selectedGoalSpeed.kgPerWeek * 7700 / 7)
            let prefix = viewModel.goal == .lose ? "deficit" : "surplus"

            VStack(spacing: 8) {
                Text(String(localized: "This is approximately \(weeklyCal) kcal/day \(prefix)"))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)

                if viewModel.selectedGoalSpeed.isAggressive {
                    Label("Aggressive goals may impact energy and performance", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange.opacity(0.1))
                        )
                }
            }
        }
    }
}

// MARK: - Speed Card

private struct SpeedCard: View {
    let speed: GoalSpeed
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(speed.label)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(speedDescription)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Text(speed.description)
                    .font(.subheadline.bold())
                    .foregroundStyle(isSelected ? ThemeColors.primary : .white.opacity(0.6))

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? ThemeColors.primary : .white.opacity(0.2))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(isSelected ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected
                            ? LinearGradient(colors: [ThemeColors.primary, ThemeColors.info], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.06)], startPoint: .leading, endPoint: .trailing),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }

    private var speedDescription: String {
        let verb = goal == .lose ? "Lose" : "Gain"
        return "\(verb) \(speed.description)"
    }
}
