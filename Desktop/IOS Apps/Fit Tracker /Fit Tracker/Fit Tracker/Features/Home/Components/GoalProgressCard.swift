import SwiftUI

// MARK: - Goal Progress Card
// Displays the user's weight goal progress on the Dashboard with an animated progress bar,
// kg remaining, estimated weeks, and optional days countdown.
// When no goal weight has been set, shows a friendly CTA prompt instead.

struct GoalProgressCard: View {
    let currentWeightKg: Double
    let startWeightKg: Double
    let goalWeightKg: Double?       // nil = user hasn't set a goal yet
    let goalTargetDate: Date?
    let goalSpeedKgPerWeek: Double
    let fitnessGoal: FitnessGoal

    var onEditTarget: (() -> Void)? = nil

    @State private var animatedProgress: Double = 0

    // MARK: - Computed

    private var isLosing: Bool { fitnessGoal == .lose }
    private var accentColor: Color { isLosing ? .orange : .green }

    private var kgRemaining: Double {
        guard let goal = goalWeightKg else { return 0 }
        if isLosing {
            return max(0, currentWeightKg - goal)
        } else {
            return max(0, goal - currentWeightKg)
        }
    }

    private var isGoalReached: Bool {
        guard let goal = goalWeightKg else { return false }
        if isLosing {
            return currentWeightKg <= goal
        } else {
            return currentWeightKg >= goal
        }
    }

    private var progress: Double {
        guard let goal = goalWeightKg else { return 0 }
        if isGoalReached { return 1.0 }
        let total = abs(startWeightKg - goal)
        guard total > 0 else { return 1.0 }
        let done = abs(startWeightKg - currentWeightKg)
        return min(done / total, 1.0)
    }

    private var weeksRemaining: Int {
        guard goalSpeedKgPerWeek > 0 else { return 0 }
        return Int(ceil(kgRemaining / goalSpeedKgPerWeek))
    }

    private var daysToTarget: Int? {
        guard let target = goalTargetDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: .now, to: target).day ?? 0
        return days > 0 ? days : nil
    }

    var body: some View {
        if let goal = goalWeightKg {
            progressContent(goal: goal)
        } else {
            noGoalPrompt
        }
    }

    // MARK: - No Goal Prompt

    private var noGoalPrompt: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ThemeColors.primary, ThemeColors.primary.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .shadow(color: ThemeColors.primary.opacity(0.3), radius: 6, x: 0, y: 3)

                Image(systemName: "target")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Set Your Goal Weight")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
                Text("Track your progress toward a target weight")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(ThemeColors.textSecondary)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ThemeColors.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(ThemeColors.primary.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Progress Content

    private func progressContent(goal: Double) -> some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: isLosing ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(accentColor)
                    Text("Goal Progress")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(ThemeColors.textPrimary)
                }
                Spacer()
                if let onEditTarget {
                    Button(action: onEditTarget) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundStyle(ThemeColors.textSecondary)
                            .font(.system(size: 22))
                    }
                    .padding(.trailing, 4)
                }
                percentageBadge
            }

            // Weight row
            HStack {
                weightColumn(label: "Start", value: startWeightKg)
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundStyle(ThemeColors.textSecondary)
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                weightColumn(label: "Current", value: currentWeightKg, highlight: true)
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundStyle(accentColor.opacity(0.5))
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                weightColumn(label: "Goal", value: goal, accentColor: accentColor)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(accentColor.opacity(0.15))
                        .frame(height: 12)
                    RoundedRectangle(cornerRadius: 7)
                        .fill(
                            LinearGradient(colors: [accentColor.opacity(0.7), accentColor], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geo.size.width * animatedProgress, height: 12)
                        .shadow(color: accentColor.opacity(0.4), radius: 6)
                        .animation(.easeOut(duration: 1.0), value: animatedProgress)
                }
            }
            .frame(height: 12)

            // Stats row
            HStack(spacing: 0) {
                statPill(
                    icon: "scalemass.fill",
                    label: "Remaining",
                    value: String(format: "%.1f kg", kgRemaining),
                    color: accentColor
                )

                Spacer()

                if weeksRemaining > 0 {
                    statPill(
                        icon: "clock.fill",
                        label: "Est. Time",
                        value: "\(weeksRemaining) wks",
                        color: .cyan
                    )
                }

                if let days = daysToTarget {
                    Spacer()
                    statPill(
                        icon: "calendar",
                        label: "Deadline",
                        value: "\(days) days",
                        color: .purple
                    )
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ThemeColors.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animatedProgress = progress
            }
        }
        .onChange(of: currentWeightKg) { _, _ in
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
    }

    // MARK: - Sub-views

    private var percentageBadge: some View {
        Text(isGoalReached ? "Goal Reached" : "\(Int(progress * 100))%")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(isGoalReached ? .white : accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isGoalReached ? ThemeColors.success : accentColor.opacity(0.12))
            )
    }

    private func weightColumn(label: String, value: Double, highlight: Bool = false, accentColor: Color = .primary) -> some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ThemeColors.textSecondary)
            Text(String(format: "%.1f", value))
                .font(.system(size: highlight ? 20 : 17, weight: .bold, design: .rounded))
                .foregroundStyle(highlight ? ThemeColors.textPrimary : accentColor)
            Text("kg")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ThemeColors.textSecondary)
        }
    }

    private func statPill(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
            }
        }
    }
}
