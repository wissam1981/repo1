import SwiftUI

// MARK: - Onboarding Goal Weight Step

struct OnboardingGoalWeightView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                headerSection
                targetWeightPicker
                targetDateSection
                motivationCard
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

            Text("Set Your Goal Weight")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text(String(localized: "How much do you want to \(viewModel.goal == .lose ? "lose" : "gain")? We'll build your plan around this."))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Target Weight Picker

    private var targetWeightPicker: some View {
        VStack(spacing: 16) {
            if viewModel.useMetric {
                metricPicker
            } else {
                imperialPicker
            }

            // Current weight context
            HStack {
                Label("Current weight", systemImage: "scalemass")
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text(viewModel.useMetric
                     ? String(format: "%.1f kg", viewModel.weightKg)
                     : String(format: "%.1f lbs", viewModel.weightLbs))
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .font(.subheadline)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
            )

            // Goal delta badge
            let delta = viewModel.weightKg - viewModel.goalWeightKg
            HStack(spacing: 8) {
                Image(systemName: delta > 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .foregroundStyle(delta > 0 ? .orange : ThemeColors.success)
                Text(viewModel.useMetric
                     ? String(format: "%.1f kg to %@", abs(delta), delta > 0 ? "lose" : "gain")
                     : String(format: "%.1f lbs to %@", abs(delta * 2.20462), delta > 0 ? "lose" : "gain"))
                    .font(.headline)
                    .foregroundStyle(delta > 0 ? .orange : ThemeColors.success)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Validation warning
            if let message = viewModel.goalWeightValidationMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(.red.opacity(0.1)))
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    private var metricPicker: some View {
        VStack(spacing: 4) {
            Text("Target Weight")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))

            HStack {
                Picker("Goal kg", selection: $viewModel.goalWeightKg) {
                    ForEach(stride(from: 30.0, through: 200.0, by: 0.5).map { $0 }, id: \.self) { val in
                        Text(String(format: "%.1f kg", val)).tag(val)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
            )
        }
    }

    private var imperialPicker: some View {
        VStack(spacing: 4) {
            Text("Target Weight (lbs)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))

            Picker("Goal lbs", selection: Binding(
                get: { viewModel.goalWeightKg * 2.20462 },
                set: { viewModel.goalWeightKg = $0 / 2.20462 }
            )) {
                ForEach(stride(from: 70.0, through: 440.0, by: 1.0).map { $0 }, id: \.self) { val in
                    Text(String(format: "%.0f lbs", val)).tag(val)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Target Date

    private var targetDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target Date (Optional)")
                .font(.headline)
                .foregroundStyle(.white)

            DatePicker(
                "By when?",
                selection: $viewModel.goalTargetDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
            )

            let weeksNeeded = estimatedWeeks
            if weeksNeeded > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(ThemeColors.primary)
                    Text(String(localized: "Estimated \(weeksNeeded) weeks at current pace"))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .opacity(appeared ? 1 : 0)
    }

    private var estimatedWeeks: Int {
        let delta = abs(viewModel.weightKg - viewModel.goalWeightKg)
        let speed = viewModel.selectedGoalSpeed.kgPerWeek
        guard speed > 0 else { return 0 }
        return Int(ceil(delta / speed))
    }

    // MARK: - Motivation Card

    private var motivationCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("You've got this!")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text("Consistent daily tracking is the #1 predictor of success.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.yellow.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.yellow.opacity(0.15), lineWidth: 0.5)
        )
        .opacity(appeared ? 1 : 0)
    }
}
