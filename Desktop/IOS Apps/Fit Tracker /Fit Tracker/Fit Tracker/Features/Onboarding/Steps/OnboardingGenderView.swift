import SwiftUI

// MARK: - Onboarding Gender Step

struct OnboardingGenderView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            headerSection

            genderGrid

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
            Image(systemName: "person.2.fill")
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

            Text("What's your gender?")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("This helps us calculate your daily calorie needs accurately.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Gender Cards

    private var genderGrid: some View {
        VStack(spacing: 14) {
            ForEach(Array(Gender.allCases.enumerated()), id: \.element) { index, gender in
                GenderCard(
                    gender: gender,
                    isSelected: viewModel.gender == gender
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.gender = gender
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1), value: appeared)
            }
        }
    }
}

// MARK: - Gender Card

private struct GenderCard: View {
    let gender: Gender
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.title)
                    .foregroundStyle(isSelected ? .black : .white.opacity(0.7))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle().fill(
                            isSelected
                                ? AnyShapeStyle(LinearGradient(colors: [ThemeColors.primary, ThemeColors.info], startPoint: .topLeading, endPoint: .bottomTrailing))
                                : AnyShapeStyle(Color.white.opacity(0.06))
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(gender.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(subtitleText)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? ThemeColors.primary : .white.opacity(0.2))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
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

    private var iconName: String {
        switch gender {
        case .male:   return "figure.stand"
        case .female: return "figure.stand.dress"
        case .other:  return "figure.wave"
        }
    }

    private var subtitleText: String {
        switch gender {
        case .male:   return "Higher baseline metabolism"
        case .female: return "Adjusted for female physiology"
        case .other:  return "Averaged calculation"
        }
    }
}
