import SwiftUI
import Charts

// MARK: - Weekly Report Card
// Summary card on the Home dashboard linking to the full Weekly Report sheet.

struct WeeklyReportCard: View {
    let report: WeeklyReportData
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [ThemeColors.info, ThemeColors.info.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: ThemeColors.info.opacity(0.3), radius: 6, x: 0, y: 3)

                        Image(systemName: "chart.bar.doc.horizontal.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Weekly Report")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(ThemeColors.textPrimary)
                        Text(report.dateRange)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(ThemeColors.textSecondary)
                }

                // Quick stats row
                HStack(spacing: 0) {
                    quickStat(value: "\(report.avgCalories)", label: "Avg Calories", color: ThemeColors.info)
                    quickStat(value: "\(report.avgProtein)g", label: "Avg Protein", color: .orange)
                    quickStat(value: "\(report.daysLogged)/7", label: "Days Logged", color: ThemeColors.success)
                    quickStat(value: report.weightChangeText, label: "Weight", color: report.weightChange <= 0 ? ThemeColors.success : ThemeColors.error)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [ThemeColors.info.opacity(0.08), ThemeColors.surfaceColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [ThemeColors.info.opacity(0.2), ThemeColors.surfaceBorder],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func quickStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ThemeColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Weekly Report Sheet (Full Detail)

struct WeeklyReportSheet: View {
    let report: WeeklyReportData
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                ThemeColors.backgroundDark.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Period header
                        VStack(spacing: 6) {
                            Text("Weekly Summary")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(ThemeColors.textPrimary)
                            Text(report.dateRange)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(ThemeColors.textSecondary)
                        }
                        .padding(.top, 8)

                        // Score card
                        scoreCard

                        // Calorie chart
                        calorieChartCard

                        // Macro averages
                        macroAveragesCard

                        // Stats grid
                        statsGrid

                        // Weight section
                        if report.startWeight > 0 || report.endWeight > 0 {
                            weightCard
                        }

                        // Insights
                        insightsCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(ThemeColors.textSecondary)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6).delay(0.1)) {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Score Card

    private var scoreCard: some View {
        let score = report.weekScore
        let grade = score >= 80 ? "A" : score >= 60 ? "B" : score >= 40 ? "C" : "D"
        let gradeColor = score >= 80 ? ThemeColors.success : score >= 60 ? ThemeColors.primary : score >= 40 ? .orange : ThemeColors.error

        return VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(ThemeColors.surfaceBorder, lineWidth: 10)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: appeared ? Double(score) / 100.0 : 0)
                    .stroke(gradeColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8).delay(0.3), value: appeared)
                    .shadow(color: gradeColor.opacity(0.4), radius: 8)

                VStack(spacing: -2) {
                    Text(grade)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(gradeColor)
                    Text("\(score)%")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(ThemeColors.textSecondary)
                }
            }

            Text("Weekly Score")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(ThemeColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(glassCard)
    }

    // MARK: - Calorie Chart

    private var calorieChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Daily Calories")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(ThemeColors.textPrimary)

            Chart {
                ForEach(report.dailyCalories, id: \.day) { entry in
                    BarMark(
                        x: .value("Day", entry.day),
                        y: .value("Calories", entry.calories)
                    )
                    .foregroundStyle(
                        entry.calories > 0
                            ? LinearGradient(colors: [ThemeColors.primary, ThemeColors.info], startPoint: .bottom, endPoint: .top)
                            : LinearGradient(colors: [ThemeColors.surfaceColor, ThemeColors.surfaceColor], startPoint: .bottom, endPoint: .top)
                    )
                    .cornerRadius(4)
                }

                // Goal line
                RuleMark(y: .value("Goal", report.calorieGoal))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel()
                        .foregroundStyle(ThemeColors.textSecondary)
                        .font(.system(size: 10))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .foregroundStyle(ThemeColors.textSecondary)
                        .font(.system(size: 11))
                }
            }
            .frame(height: 170)
        }
        .padding(18)
        .background(glassCard)
    }

    // MARK: - Macro Averages

    private var macroAveragesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Average Macros")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(ThemeColors.textPrimary)

            HStack(spacing: 12) {
                macroColumn(name: "Protein", avg: report.avgProtein, target: report.proteinGoal, color: .orange)
                macroColumn(name: "Carbs", avg: report.avgCarbs, target: report.carbsGoal, color: ThemeColors.success)
                macroColumn(name: "Fat", avg: report.avgFat, target: report.fatGoal, color: .purple)
            }
        }
        .padding(18)
        .background(glassCard)
    }

    private func macroColumn(name: String, avg: Int, target: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(ThemeColors.surfaceBorder, lineWidth: 6)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: min(Double(avg) / max(Double(target), 1), 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.3), radius: 4)

                Text("\(avg)g")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(ThemeColors.textPrimary)
            }

            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ThemeColors.textSecondary)

            Text("of \(target)g")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ThemeColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        let stats: [(String, String, String, Color)] = [
            ("flame.fill", "\(report.totalCalories)", "Total Calories", ThemeColors.info),
            ("calendar", "\(report.daysLogged)", "Days Logged", ThemeColors.success),
            ("bolt.fill", "\(report.avgProtein)g", "Avg Protein", .orange),
            ("drop.fill", "\(report.avgWaterMl)ml", "Avg Water", .cyan),
        ]

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Array(stats.enumerated()), id: \.offset) { _, stat in
                HStack(spacing: 12) {
                    Image(systemName: stat.0)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(stat.3)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(stat.3.opacity(0.12)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stat.1)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(ThemeColors.textPrimary)
                        Text(stat.2)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }

                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(ThemeColors.surfaceColor)
                )
            }
        }
    }

    // MARK: - Weight Card

    private var weightCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Weight Progress")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(ThemeColors.textPrimary)

            HStack(spacing: 0) {
                weightStat(label: "Start", value: String(format: "%.1f kg", report.startWeight))
                weightStat(label: "End", value: String(format: "%.1f kg", report.endWeight))
                weightStat(
                    label: "Change",
                    value: report.weightChangeText,
                    color: report.weightChange <= 0 ? ThemeColors.success : ThemeColors.error
                )
            }
        }
        .padding(18)
        .background(glassCard)
    }

    private func weightStat(label: String, value: String, color: Color = .white) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(ThemeColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Insights

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.yellow)
                Text("Insights")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ThemeColors.textPrimary)
            }

            ForEach(report.insights, id: \.self) { insight in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(ThemeColors.primary)
                        .frame(width: 6, height: 6)
                        .padding(.top, 7)

                    Text(insight)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(ThemeColors.textSecondary)
                        .lineSpacing(2)
                }
            }
        }
        .padding(18)
        .background(glassCard)
    }

    // MARK: - Glass Card

    private var glassCard: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(ThemeColors.surfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(ThemeColors.surfaceBorder, lineWidth: 1)
            )
    }
}

// MARK: - Data Model

struct WeeklyReportData {
    let dateRange: String
    let dailyCalories: [DayCalorie]
    let avgCalories: Int
    let totalCalories: Int
    let calorieGoal: Int
    let avgProtein: Int
    let avgCarbs: Int
    let avgFat: Int
    let proteinGoal: Int
    let carbsGoal: Int
    let fatGoal: Int
    let daysLogged: Int
    let avgWaterMl: Int
    let startWeight: Double
    let endWeight: Double
    let weightChange: Double
    let insights: [String]

    var weightChangeText: String {
        if weightChange == 0 && startWeight == 0 { return "–" }
        let sign = weightChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", weightChange)) kg"
    }

    /// Score 0-100 based on consistency and goal adherence
    var weekScore: Int {
        let logScore = Double(daysLogged) / 7.0 * 40 // 40 pts for logging
        let calScore = calorieGoal > 0 ? min(Double(avgCalories) / Double(calorieGoal), 1.2) : 0
        let calPoints = calScore > 1.1 ? 20 : calScore * 30 // 30 pts for hitting cal goal
        let proteinScore = proteinGoal > 0 ? min(Double(avgProtein) / Double(proteinGoal), 1.0) * 30 : 0 // 30 pts for protein
        return min(100, Int(logScore + calPoints + proteinScore))
    }

    struct DayCalorie: Identifiable {
        let id = UUID()
        let day: String
        let calories: Int
    }
}
