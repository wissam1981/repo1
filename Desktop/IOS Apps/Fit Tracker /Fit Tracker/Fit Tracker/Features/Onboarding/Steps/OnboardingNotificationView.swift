import SwiftUI

// MARK: - Onboarding Notification Step

struct OnboardingNotificationView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            headerSection

            VStack(spacing: 14) {
                ForEach(ReminderFrequency.allCases, id: \.self) { frequency in
                    frequencyCard(frequency)
                }
            }

            timePickerSection
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: appeared)

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
            Image(systemName: "bell.badge.fill")
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

            Text("Meal Reminders")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("How often and when would you like to be reminded to log your meals?")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Frequency Card

    private func frequencyCard(_ frequency: ReminderFrequency) -> some View {
        let isSelected = viewModel.reminderFrequency == frequency
        let index = ReminderFrequency.allCases.firstIndex(of: frequency) ?? 0

        return Button {
            withAnimation(.spring(response: 0.3)) {
                viewModel.reminderFrequency = frequency
            }
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(frequency.displayName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(frequency.description)
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
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1), value: appeared)
    }

    // MARK: - Time Picker

    private var timePickerSection: some View {
        VStack(spacing: 16) {
            Divider().background(Color.white.opacity(0.1))
            
            HStack {
                Text("Reminder Time")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                DatePicker("", selection: $viewModel.reminderTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .colorInvert()
                    .colorMultiply(ThemeColors.primary)
            }
            .padding(.horizontal, 8)
        }
        .padding(.top, 8)
    }
}
