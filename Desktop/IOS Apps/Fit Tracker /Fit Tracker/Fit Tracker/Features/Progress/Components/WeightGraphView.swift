import SwiftUI
import Charts

// MARK: - Weight Graph View
// Swift Charts LineMark showing weight over time.

struct WeightGraphView: View {
    let entries: [ProgressEntry]
    let targetWeight: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if entries.isEmpty {
                emptyState
            } else {
                chartView
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColors.surfaceColor))
    }

    // MARK: - Chart

    private var chartView: some View {
        Chart {
            ForEach(entries) { entry in
                LineMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Weight", entry.weightKg)
                )
                .foregroundStyle(.cyan)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                PointMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Weight", entry.weightKg)
                )
                .foregroundStyle(.cyan)
                .symbolSize(30)
            }

            // Target line
            if let target = targetWeight {
                RuleMark(y: .value("Target", target))
                    .foregroundStyle(.orange.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal: \(String(format: "%.1f", target)) kg")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
            }
        }
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) {
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(maxHeight: .infinity)
    }

    private var yDomain: ClosedRange<Double> {
        let weights = entries.map(\.weightKg)
        let minW = (weights.min() ?? 60) - 2
        let maxW = (weights.max() ?? 100) + 2
        return minW...maxW
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No weight data yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Log your first weight to see your progress chart")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}
