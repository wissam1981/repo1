import SwiftUI

// MARK: - Onboarding Age Step

struct OnboardingAgeView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var appeared = false

    private let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let minDate = calendar.date(byAdding: .year, value: -100, to: .now) ?? .distantPast
        let maxDate = calendar.date(byAdding: .year, value: -13, to: .now) ?? .now
        return minDate...maxDate
    }()

    var body: some View {
        VStack(spacing: 32) {
            headerSection

            ageDisplay

            datePicker

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
            Image(systemName: "calendar.circle.fill")
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

            Text("When were you born?")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Age affects your metabolism and daily calorie requirements.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Age Display

    private var ageDisplay: some View {
        VStack(spacing: 4) {
            Text("\(viewModel.ageYears)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [ThemeColors.primary, ThemeColors.info],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .contentTransition(.numericText())
                .shadow(color: ThemeColors.primary.opacity(0.3), radius: 8, y: 0)

            Text("years old")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.vertical, 8)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.8)
        .animation(.spring(response: 0.3), value: viewModel.ageYears)
    }

    // MARK: - Date Picker

    private var datePicker: some View {
        DatePicker(
            "Date of Birth",
            selection: $viewModel.dateOfBirth,
            in: dateRange,
            displayedComponents: .date
        )
        .datePickerStyle(.wheel)
        .labelsHidden()
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
        .offset(y: appeared ? 0 : 20)
    }
}
