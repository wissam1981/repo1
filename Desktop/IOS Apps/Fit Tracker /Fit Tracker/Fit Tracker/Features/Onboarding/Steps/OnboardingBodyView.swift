import SwiftUI

// MARK: - Onboarding Body Metrics Step (Height + Weight)

struct OnboardingBodyView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerSection

                unitToggle

                heightSection

                weightSection

                bmiIndicator

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
            Image(systemName: "figure.arms.open")
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

            Text("Your Body Metrics")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("We use these to calculate your BMR and daily calorie needs.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Unit Toggle

    private var unitToggle: some View {
        Picker("Units", selection: $viewModel.useMetric) {
            Text("Metric (kg/cm)").tag(true)
            Text("Imperial (lbs/ft)").tag(false)
        }
        .pickerStyle(.segmented)
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Height

    private var heightSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "ruler")
                    .foregroundStyle(ThemeColors.primary)
                Text("Height")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(heightDisplayText)
                    .font(.headline)
                    .foregroundStyle(ThemeColors.primary)
            }

            if viewModel.useMetric {
                Picker("Height cm", selection: $viewModel.heightCm) {
                    ForEach(Array(stride(from: 120.0, through: 230.0, by: 1.0)), id: \.self) { val in
                        Text("\(Int(val)) cm").tag(val)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
            } else {
                HStack(spacing: 0) {
                    Picker("Feet", selection: $viewModel.heightFeet) {
                        ForEach(4...7, id: \.self) { ft in
                            Text("\(ft) ft").tag(ft)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Picker("Inches", selection: $viewModel.heightInches) {
                        ForEach(0...11, id: \.self) { inch in
                            Text("\(inch) in").tag(inch)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 120)
            }
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
        .offset(y: appeared ? 0 : 20)
    }

    private var heightDisplayText: String {
        if viewModel.useMetric {
            return "\(Int(viewModel.heightCm)) cm"
        } else {
            let (ft, inches) = FitnessCalculator.cmToFeetInches(viewModel.heightCm)
            return "\(ft)' \(inches)\""
        }
    }

    // MARK: - Weight

    private var weightSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "scalemass")
                    .foregroundStyle(ThemeColors.primary)
                Text("Weight")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(weightDisplayText)
                    .font(.headline)
                    .foregroundStyle(ThemeColors.primary)
            }

            if viewModel.useMetric {
                Picker("Weight kg", selection: $viewModel.weightKg) {
                    ForEach(Array(stride(from: 30.0, through: 250.0, by: 0.5)), id: \.self) { val in
                        Text(String(format: "%.1f kg", val)).tag(val)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
            } else {
                Picker("Weight lbs", selection: $viewModel.weightLbs) {
                    ForEach(Array(stride(from: 66.0, through: 550.0, by: 1.0)), id: \.self) { val in
                        Text("\(Int(val)) lbs").tag(val)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
            }
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
        .offset(y: appeared ? 0 : 20)
    }

    private var weightDisplayText: String {
        if viewModel.useMetric {
            return String(format: "%.1f kg", viewModel.weightKg)
        } else {
            return String(format: "%.0f lbs", viewModel.weightLbs)
        }
    }

    // MARK: - BMI Indicator

    private var bmiIndicator: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(bmiColor)
                Text("BMI")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Text(String(format: "%.1f", viewModel.bmi))
                .font(.headline.bold())
                .foregroundStyle(.white)
            Text(String(localized: "(\(viewModel.bmiCategory))"))
                .font(.subheadline.bold())
                .foregroundStyle(bmiColor)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(bmiColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(bmiColor.opacity(0.2), lineWidth: 0.5)
        )
        .opacity(appeared ? 1 : 0)
    }

    private var bmiColor: Color {
        switch viewModel.bmiCategory {
        case "Normal":      return ThemeColors.success
        case "Underweight": return .orange
        case "Overweight":  return .orange
        default:            return ThemeColors.error
        }
    }
}
