import SwiftUI

// MARK: - Onboarding Activity Level Step

struct OnboardingActivityView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                headerSection

                activityList

                Spacer(minLength: 16)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run")
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

            Text("How active are you?")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Be honest — this directly affects your daily calorie target.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Activity Cards

    private var activityList: some View {
        VStack(spacing: 12) {
            ForEach(Array(ActivityLevel.allCases.enumerated()), id: \.element) { index, level in
                ActivityCard(
                    level: level,
                    isSelected: viewModel.activityLevel == level
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.activityLevel = level
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.08), value: appeared)
            }
        }
    }
}

// MARK: - Activity Card

private struct ActivityCard: View {
    let level: ActivityLevel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: level.icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .black : .white.opacity(0.6))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(
                            isSelected
                                ? AnyShapeStyle(LinearGradient(colors: [ThemeColors.primary, ThemeColors.info], startPoint: .topLeading, endPoint: .bottomTrailing))
                                : AnyShapeStyle(Color.white.opacity(0.06))
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.displayName)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                    Text(level.description)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? ThemeColors.primary : .white.opacity(0.2))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(isSelected ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected
                            ? LinearGradient(colors: [ThemeColors.primary, ThemeColors.info], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.white.opacity(0.06), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
