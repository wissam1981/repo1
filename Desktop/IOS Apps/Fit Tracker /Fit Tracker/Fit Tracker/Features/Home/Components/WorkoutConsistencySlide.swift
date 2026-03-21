import SwiftUI

// MARK: - Workout Consistency Slide (Workout Carousel Slide 2)
// Visualizes the workout streak and weekly consistency.

struct WorkoutConsistencySlide: View {
    let weekDays: [String] = ["M", "T", "W", "T", "F", "S", "S"]
    let completedDays: Set<Int>
    let currentStreak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Consistency")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(ThemeColors.textPrimary)
                    Text("Don't break the chain")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(ThemeColors.textSecondary)
                }
                Spacer()

                // Streak Badge
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("\(currentStreak) DAY STREAK")
                        .font(.system(size: 11, weight: .black))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.orange.opacity(0.12))
                .clipShape(Capsule())
            }

            Spacer(minLength: 0)

            // Weekly Tracker
            HStack(spacing: 0) {
                ForEach(0..<7) { index in
                    let isCompleted = completedDays.contains(index)
                    VStack(spacing: 10) {
                        Text(weekDays[index])
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(isCompleted ? ThemeColors.textPrimary : ThemeColors.textSecondary)

                        ZStack {
                            Circle()
                                .stroke(isCompleted ? ThemeColors.primary.opacity(0.3) : ThemeColors.surfaceBorder, lineWidth: 2.5)
                                .frame(width: 40, height: 40)

                            if isCompleted {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [ThemeColors.primary, ThemeColors.secondary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 32, height: 32)
                                    .shadow(color: ThemeColors.primary.opacity(0.4), radius: 4)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ThemeColors.surfaceColor)
                    .padding(.horizontal, -10)
            )

            Spacer(minLength: 0)

            // Encouragement Text
            HStack(spacing: 8) {
                Circle()
                    .fill(ThemeColors.primary)
                    .frame(width: 7, height: 7)
                Text(encouragementMessage)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(ThemeColors.textSecondary)
                Spacer()
            }
        }
        .padding(22)
        .background(
            ZStack {
                ThemeColors.surfaceColor
                ThemeColors.secondary.opacity(0.05)
                    .blur(radius: 50)
                    .offset(x: 80, y: -40)
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

    private var encouragementMessage: String {
        let count = completedDays.count
        if count == 0 { return "Start your week strong today!" }
        if count < 3 { return "Great start! Keep pushing." }
        if count < 5 { return "You're on a roll!" }
        return "Elite consistency this week!"
    }
}

#Preview {
    ZStack {
        ThemeColors.backgroundDark.ignoresSafeArea()
        WorkoutConsistencySlide(completedDays: [0, 1, 3], currentStreak: 5)
            .padding()
    }
}
