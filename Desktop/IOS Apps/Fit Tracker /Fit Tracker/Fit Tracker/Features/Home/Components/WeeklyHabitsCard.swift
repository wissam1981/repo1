import SwiftUI

// MARK: - Weekly Habits Card
// Tracks weekly habit streaks for protein goal, calorie goal, and logging consistency.

struct WeeklyHabitsCard: View {
    let weekData: [WeeklyHabitDay]
    let habits: [HabitTracker]

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ThemeColors.success, ThemeColors.success.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: ThemeColors.success.opacity(0.3), radius: 6, x: 0, y: 3)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text("Weekly Habits")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(ThemeColors.textPrimary)

                        Text("BETA")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(ThemeColors.textSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .strokeBorder(ThemeColors.surfaceBorder, lineWidth: 1)
                            )
                    }

                    Text("Build consistency, see results")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(ThemeColors.textSecondary)
                }

                Spacer()
            }

            // Habit rows
            ForEach(Array(habits.enumerated()), id: \.element.id) { index, habit in
                habitRow(habit)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1), value: appeared)
            }

            // Week day circles
            weekDayRow
                .opacity(appeared ? 1 : 0)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(ThemeColors.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [ThemeColors.surfaceBorder, ThemeColors.surfaceBorder],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                appeared = true
            }
        }
    }

    // MARK: - Habit Row

    private func habitRow(_ habit: HabitTracker) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: habit.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(habit.color)

                Text(habit.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)

                Spacer()

                Text("\(habit.completedDays)/\(habit.targetDays) days")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(habit.completedDays >= habit.targetDays ? ThemeColors.success : ThemeColors.textSecondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(ThemeColors.surfaceColor)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                colors: [habit.color, habit.color.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * habit.progress, height: 8)
                        .shadow(color: habit.color.opacity(0.4), radius: 4)
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(habit.color.opacity(0.05))
        )
    }

    // MARK: - Week Day Row

    private var weekDayRow: some View {
        HStack(spacing: 0) {
            ForEach(weekData) { day in
                VStack(spacing: 6) {
                    Text(day.shortName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ThemeColors.textSecondary)

                    ZStack {
                        if day.isToday {
                            Circle()
                                .stroke(ThemeColors.primary, lineWidth: 2.5)
                                .frame(width: 34, height: 34)
                        }

                        if day.allHabitsComplete {
                            Circle()
                                .fill(ThemeColors.success)
                                .frame(width: 30, height: 30)
                                .shadow(color: ThemeColors.success.opacity(0.3), radius: 4)

                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.black)
                        } else if day.someHabitsComplete {
                            Circle()
                                .fill(ThemeColors.success.opacity(0.2))
                                .frame(width: 30, height: 30)

                            Circle()
                                .trim(from: 0, to: day.completionRatio)
                                .stroke(ThemeColors.success, lineWidth: 3)
                                .frame(width: 30, height: 30)
                                .rotationEffect(.degrees(-90))
                        } else if day.isPast {
                            Circle()
                                .fill(ThemeColors.surfaceColor)
                                .frame(width: 30, height: 30)

                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(ThemeColors.textSecondary)
                        } else {
                            Circle()
                                .fill(ThemeColors.surfaceColor)
                                .frame(width: 30, height: 30)

                            Text("\(day.dayNumber)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(ThemeColors.textSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 6)
    }
}

// MARK: - Data Models

struct WeeklyHabitDay: Identifiable {
    let id = UUID()
    let shortName: String
    let dayNumber: Int
    let isToday: Bool
    let isPast: Bool
    let allHabitsComplete: Bool
    let someHabitsComplete: Bool
    let completionRatio: Double
}

struct HabitTracker: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let completedDays: Int
    let targetDays: Int

    var progress: Double {
        guard targetDays > 0 else { return 0 }
        return min(Double(completedDays) / Double(targetDays), 1.0)
    }
}
