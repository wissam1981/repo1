import SwiftUI

// MARK: - Calorie Main Card (Carousel Slide 1)
// Focuses on the calorie ring and essential daily stats with a premium design.

struct CalorieMainCard: View {
    let consumed: Int
    let target: Int
    let progress: Double
    let remaining: Int
    let fitnessGoal: FitnessGoal

    private let ringSize: CGFloat = 180
    private let lineWidth: CGFloat = 18

    var body: some View {
        VStack(spacing: 18) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Intake")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(ThemeColors.textPrimary)
                    Text("\(remaining) kcal remaining")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(ThemeColors.textSecondary)
                }
                Spacer()

                // Goal Badge
                HStack(spacing: 5) {
                    Image(systemName: fitnessGoal.icon)
                        .font(.system(size: 12, weight: .semibold))
                    Text(fitnessGoal.displayName)
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(goalBadgeColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(goalBadgeColor.opacity(0.15))
                .clipShape(Capsule())
            }

            Spacer(minLength: 0)

            // Ring Section
            ZStack {
                // Background Track
                Circle()
                    .stroke(ThemeColors.surfaceBorder, lineWidth: lineWidth)
                    .frame(width: ringSize, height: ringSize)

                // Progress Ring with Glow
                Circle()
                    .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                    .stroke(
                        LinearGradient(
                            colors: [ThemeColors.info, ThemeColors.primary, ThemeColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: ringSize, height: ringSize)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: ThemeColors.primary.opacity(progress > 0 ? 0.5 : 0), radius: 12, x: 0, y: 4)

                // Center Text
                VStack(spacing: 2) {
                    Text("Calories")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(ThemeColors.textSecondary)
                        .padding(.bottom, 2)

                    Text("\(consumed)")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundColor(ThemeColors.textPrimary)
                    Text("/ \(target)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(ThemeColors.textSecondary)
                    Text("kcal")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(ThemeColors.textSecondary)
                }
            }
            .padding(.vertical, 8)

            Spacer(minLength: 0)

            // Stats Row
            HStack(spacing: 12) {
                statTile(label: "Eaten", value: "\(consumed)", color: ThemeColors.primary)
                statTile(label: "Remaining", value: "\(remaining)", color: ThemeColors.info)
            }
        }
        .padding(22)
        .glassStyle(cornerRadius: 24, color: ThemeColors.surfaceColor)
        .overlay(
            // Dynamic glow based on progress
            Circle()
                .fill(ThemeColors.primary.opacity(0.08))
                .frame(width: 200, height: 200)
                .blur(radius: 50)
                .allowsHitTesting(false)
        )
    }

    private var goalBadgeColor: Color {
        switch fitnessGoal {
        case .lose:     return ThemeColors.info
        case .maintain: return ThemeColors.primary
        case .gain:     return ThemeColors.secondary
        }
    }

    private func statTile(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .black))
                .foregroundColor(ThemeColors.textSecondary)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(ThemeColors.textPrimary)
            Text("kcal")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(color.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        ThemeColors.backgroundDark.ignoresSafeArea()
        CalorieMainCard(
            consumed: 1200,
            target: 2000,
            progress: 0.6,
            remaining: 800,
            fitnessGoal: .lose
        )
        .padding()
    }
}
