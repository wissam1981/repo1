import SwiftUI
import Charts

// MARK: - Weekly Calorie Bar Chart Card (Stitch AI Redesign)
// Replaces the old circular ring with a modern data-driven bar chart.

struct CalorieWeeklyCard: View {
    let consumed: Int
    let target: Int
    
    // Mock weekly data to show the bar chart filling design
    // In a real app this would be injected by the HomeViewModel from the past 7 days
    private let weeklyData: [(day: String, value: Int)] = [
        ("Mon", 2100), ("Tue", 2400), ("Wed", 1950),
        ("Thu", 2600), ("Fri", 2200), ("Sat", 2800), ("Sun", 2450)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Top Section
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Activity")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.gray)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(consumed)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(ThemeColors.textPrimary)
                            .contentTransition(.numericText())
                        
                        Text("kcal")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundColor(ThemeColors.primary)
                    }
                }
                
                Spacer()
                
                // Flame Icon Button styling
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundColor(ThemeColors.primary)
                    .padding(12)
                    .background(ThemeColors.surfaceColor)
                    .clipShape(Circle())
            }
            
            // Bar Chart Section
            Chart {
                ForEach(weeklyData, id: \.day) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Calories", item.value)
                    )
                    // Highlight today (Sun) with primary color, others subdued
                    .foregroundStyle(item.day == "Sun" ? ThemeColors.primary : ThemeColors.surfaceColor)
                    .cornerRadius(4)
                }
                
                // Target Line
                RuleMark(y: .value("Target", target))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(ThemeColors.primary.opacity(0.5))
            }
            .frame(height: 120)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .foregroundStyle(.gray)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
            }
            .chartYAxis(.hidden)
        }
        .padding(20)
        .background(ThemeColors.surfaceColor)
        .cornerRadius(24)
        // Note: We use rounded corners and surface background to match Stitch UI
    }
}
