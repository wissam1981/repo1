import SwiftUI

// MARK: - Today Workout Slide (Workout Carousel Slide 1)
// Displays current or next planned session with a premium focus and quick start.

struct TodayWorkoutSlide: View {
    let hasWorkout: Bool
    let workoutName: String?
    let duration: Int
    let calories: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Session")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(ThemeColors.textPrimary)
                        Text(hasWorkout ? "Ready for a sweat?" : "Rest day or new plan?")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(ThemeColors.textSecondary)
                    }
                    Spacer()

                    // Session Status Badge
                    HStack(spacing: 5) {
                        Circle()
                            .fill(hasWorkout ? ThemeColors.primary : .gray)
                            .frame(width: 8, height: 8)
                        Text(hasWorkout ? "PLANNED" : "NO PLAN")
                            .font(.system(size: 11, weight: .black))
                    }
                    .foregroundColor(hasWorkout ? ThemeColors.primary : .gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background((hasWorkout ? ThemeColors.primary : Color.gray).opacity(0.12))
                    .clipShape(Capsule())
                }

                Spacer(minLength: 0)

                // Main Content Area
                HStack(spacing: 20) {
                    // Visual Icon
                    ZStack {
                        Circle()
                            .fill(ThemeColors.primary.opacity(0.12))
                            .frame(width: 100, height: 100)

                        Image(systemName: hasWorkout ? "figure.highintensity.intervaltraining" : "dumbbell.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [ThemeColors.primary, ThemeColors.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: ThemeColors.primary.opacity(0.3), radius: 10)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(workoutName ?? "No Workout Planned")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(ThemeColors.textPrimary)
                            .lineLimit(2)

                        if hasWorkout {
                            HStack(spacing: 12) {
                                statMini(icon: "clock", text: "\(duration) min")
                                statMini(icon: "flame.fill", text: "\(calories) kcal")
                            }
                        } else {
                            Text("Consistency is key to results")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(ThemeColors.textSecondary)
                        }
                    }
                }

                Spacer(minLength: 0)

                // Bottom Button
                HStack {
                    Spacer()
                    Text(hasWorkout ? "Start Session" : "View Plans")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(ThemeColors.textPrimary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(ThemeColors.textPrimary)
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(ThemeColors.primary.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(ThemeColors.primary.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .padding(22)
            .background(
                ZStack {
                    ThemeColors.surfaceColor
                    Circle()
                        .fill(ThemeColors.primary.opacity(0.08))
                        .frame(width: 150, height: 150)
                        .blur(radius: 40)
                        .offset(x: -50, y: 30)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [ThemeColors.surfaceBorder, ThemeColors.surfaceBorder], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func statMini(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
        }
        .foregroundColor(ThemeColors.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(ThemeColors.surfaceColor)
        .cornerRadius(8)
    }
}

#Preview {
    ZStack {
        ThemeColors.backgroundDark.ignoresSafeArea()
        TodayWorkoutSlide(
            hasWorkout: true,
            workoutName: "Full Body Power",
            duration: 45,
            calories: 320,
            onTap: {}
        )
        .padding()
    }
}
