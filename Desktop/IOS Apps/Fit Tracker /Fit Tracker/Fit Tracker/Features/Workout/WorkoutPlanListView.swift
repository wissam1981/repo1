import SwiftUI

// MARK: - Workout Day Selection Sheet
// Dark-themed premium sheet for picking which day to start, matching Iron Pulse aesthetic.

struct WorkoutDaySelectionSheet: View {
    let plan: WorkoutPlan
    let onSelectDay: (WorkoutPlan, WorkoutDay) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ThemeColors.backgroundDark.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Plan info header
                        VStack(spacing: 8) {
                            Text(plan.name.uppercased())
                                .font(.system(size: 24, weight: .black))
                                .foregroundStyle(ThemeColors.textPrimary)
                                .multilineTextAlignment(.center)
                            
                            HStack(spacing: 12) {
                                Text(String(localized: "\(plan.days.count) DAYS"))
                                Text("•")
                                Text(plan.category.displayName.uppercased())
                                Text("•")
                                Text(plan.difficulty.displayName.uppercased())
                            }
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(ThemeColors.primary)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 10)

                        VStack(spacing: 12) {
                            ForEach(plan.days) { day in
                                Button {
                                    dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        onSelectDay(plan, day)
                                    }
                                } label: {
                                    HStack(spacing: 16) {
                                        // Day number indicator
                                        ZStack {
                                            Circle()
                                                .fill(ThemeColors.primary.opacity(0.1))
                                                .frame(width: 48, height: 48)
                                            Text("\(day.dayNumber)")
                                                .font(.system(size: 18, weight: .black))
                                                .foregroundStyle(ThemeColors.primary)
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(day.label.uppercased())
                                                .font(.system(size: 16, weight: .black))
                                                .foregroundStyle(ThemeColors.textPrimary)

                                            HStack(spacing: 8) {
                                                Text(String(localized: "\(day.exercises.count) EXERCISES"))
                                                    .font(.system(size: 10, weight: .black))
                                                    .foregroundStyle(ThemeColors.textSecondary)

                                                if !day.muscleGroups.isEmpty {
                                                    Text("•")
                                                        .foregroundStyle(ThemeColors.textSecondary)
                                                    Text(day.muscleGroups.map(\.displayName).joined(separator: ", ").uppercased())
                                                        .font(.system(size: 10, weight: .black))
                                                        .foregroundStyle(ThemeColors.primary.opacity(0.6))
                                                        .lineLimit(1)
                                                }
                                            }
                                        }

                                        Spacer()

                                        Image(systemName: "play.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(ThemeColors.backgroundDark)
                                            .frame(width: 36, height: 36)
                                            .background(Circle().fill(ThemeColors.primary))
                                    }
                                    .padding(20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 24)
                                            .fill(ThemeColors.surfaceColor)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 24)
                                                    .stroke(ThemeColors.surfaceBorder, lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Text("CLOSE")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(ThemeColors.textSecondary)
                            .tracking(1)
                    }
                }
            }
        }
    }
}
