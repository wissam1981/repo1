import SwiftUI

// MARK: - Workout Plans Slide (Workout Carousel Slide 3)
// Provides a quick overview of saved and available workout plans.

struct WorkoutPlansSlide: View {
    let activePlanName: String?
    let totalPlans: Int
    let onNavigate: () -> Void

    var body: some View {
        Button(action: onNavigate) {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Workout Library")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(ThemeColors.textPrimary)
                        Text("\(totalPlans) Active Plans")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(ThemeColors.textSecondary)
                    }
                    Spacer()

                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(ThemeColors.secondary)
                }

                Spacer(minLength: 0)

                // Current Plan Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("CURRENT PLAN")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(ThemeColors.textSecondary)

                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ThemeColors.secondary.opacity(0.15))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "target")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(ThemeColors.secondary)
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(activePlanName ?? "Decide your path")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(ThemeColors.textPrimary)
                            Text(activePlanName != nil ? "Following closely" : "Pick a plan to start")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(ThemeColors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(ThemeColors.surfaceColor)
                    .cornerRadius(14)
                }

                Spacer(minLength: 0)

                // Info Summary
                HStack(spacing: 12) {
                    planInsightTile(icon: "sparkles", label: "AI Plans", value: "3")
                    planInsightTile(icon: "person.2.fill", label: "Custom", value: "\(max(0, totalPlans - 3))")
                }

                // Bottom Button
                HStack {
                    Spacer()
                    Text("Explore Library")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(ThemeColors.textPrimary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(ThemeColors.textPrimary)
                    Spacer()
                }
                .padding(.vertical, 13)
                .background(ThemeColors.surfaceColor)
                .cornerRadius(14)
            }
            .padding(22)
            .background(
                ZStack {
                    ThemeColors.surfaceColor
                    ThemeColors.primary.opacity(0.04)
                        .blur(radius: 60)
                        .offset(y: 40)
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

    private func planInsightTile(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(ThemeColors.primary)

            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ThemeColors.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(ThemeColors.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(ThemeColors.surfaceColor)
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        ThemeColors.backgroundDark.ignoresSafeArea()
        WorkoutPlansSlide(activePlanName: "Hypertrophy Mastery", totalPlans: 5, onNavigate: {})
            .padding()
    }
}
