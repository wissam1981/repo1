import SwiftUI
import Charts

struct NutritionAnalyticsView: View {
    @Bindable var viewModel: NutritionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var logs: [NutritionLog] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if isLoading {
                        ProgressView("Loading Analytics...")
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if logs.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No Data Available")
                                .font(.headline)
                            Text("Log food for a few days to see your trends.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        calorieChart
                        macrosChart
                        waterChart
                    }
                }
                .padding()
            }
            .navigationTitle("Weekly Trends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                loadData()
            }
            // Add a glass background to scrollview
            .background(ThemeColors.backgroundDark.ignoresSafeArea())
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        Task {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)
            _ = calendar.date(byAdding: .day, value: -6, to: today)!
            
            // `fetchNutritionLogs` runs on CoreDataService. In this context, we can fetch from viewModel's dependencies.
            // However, NutritionViewModel doesn't expose `coreDataService`. Since we inject `NutritionService`, we need a method.
            // Oh, wait, I can modify `NutritionService` to expose this. Wait, let's use `fetchLogs` directly.
            // For now, I'll pass the array via a method I'll add to NutritionViewModel.
            logs = await viewModel.fetchWeeklyLogs()
            isLoading = false
        }
    }
    
    // MARK: - Charts
    
    private var calorieChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Calories")
                .font(.headline)
            
            Chart {
                ForEach(logs) { log in
                    BarMark(
                        x: .value("Day", log.date, unit: .day),
                        y: .value("Calories", log.totalCalories)
                    )
                    .foregroundStyle(ThemeColors.primary)
                    .cornerRadius(4)
                }
                
                RuleMark(y: .value("Target", viewModel.targetCalories))
                    .foregroundStyle(Color.red)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Target").font(.caption).foregroundColor(.red)
                    }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.short))
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColors.surfaceColor))
    }
    
    private var macrosChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macros Focus")
                .font(.headline)
            
            Chart {
                ForEach(logs) { log in
                    BarMark(
                        x: .value("Day", log.date, unit: .day),
                        y: .value("Protein", log.totalProteinG)
                    )
                    .foregroundStyle(.orange)
                    
                    BarMark(
                        x: .value("Day", log.date, unit: .day),
                        y: .value("Carbs", log.totalCarbsG)
                    )
                    .foregroundStyle(.green)
                    
                    BarMark(
                        x: .value("Day", log.date, unit: .day),
                        y: .value("Fat", log.totalFatG)
                    )
                    .foregroundStyle(ThemeColors.secondary)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.short))
                }
            }
            
            // Legend
            HStack {
                legendItem(color: .orange, label: "Protein")
                legendItem(color: .green, label: "Carbs")
                legendItem(color: ThemeColors.secondary, label: "Fat")
            }
            .font(.caption)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColors.surfaceColor))
    }
    
    private var waterChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hydration")
                .font(.headline)
            
            Chart {
                ForEach(logs) { log in
                    LineMark(
                        x: .value("Day", log.date, unit: .day),
                        y: .value("Water (ml)", log.waterMl)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(ThemeColors.info)
                    
                    AreaMark(
                        x: .value("Day", log.date, unit: .day),
                        y: .value("Water (ml)", log.waterMl)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [ThemeColors.info.opacity(0.3), ThemeColors.info.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    PointMark(
                        x: .value("Day", log.date, unit: .day),
                        y: .value("Water (ml)", log.waterMl)
                    )
                    .foregroundStyle(ThemeColors.info)
                }
            }
            .frame(height: 150)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.short))
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColors.surfaceColor))
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundStyle(.secondary)
        }
    }
}
