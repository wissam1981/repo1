import SwiftUI

// MARK: - Instructions View
// Educational page explaining calorie deficit, total burned, total consumed,
// and how they relate to weight loss goals.

struct InstructionsView: View {
    @Environment(\.dismiss) private var dismiss

    // Sample / illustrative values for the gauge
    private let sampleDeficit: Int = 200
    private let sampleBurned: Int = 450
    private let sampleBurnedTarget: Int = 1600
    private let sampleConsumed: Int = 250
    private let sampleConsumedTarget: Int = 1200

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                gaugeCard
                explanationSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(Color(white: 0.98))
        .navigationTitle("Instructions")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    // MARK: - Gauge Card

    private var gaugeCard: some View {
        VStack(spacing: 16) {
            CalorieDeficitGauge(value: sampleDeficit)
                .frame(height: 160)
                .padding(.top, 8)

            // Burned & Consumed Row
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total burned")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("\(sampleBurned)")
                                .font(.title3.bold())
                            Text("/\(sampleBurnedTarget) kcal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.title3)
                        .foregroundStyle(.cyan)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total consumed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("\(sampleConsumed)")
                                .font(.title3.bold())
                            Text("/\(sampleConsumedTarget) kcal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)

            formulaRow

            Text("By exercising more and managing your diet, the burned calories will be more than the total consumed. If you can keep your calorie deficit within the goal range, you'll be able to lose weight.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .padding(.horizontal, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }

    // MARK: - Formula Row

    private var formulaRow: some View {
        HStack(spacing: 6) {
            // Active + Resting group
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    VStack(spacing: 3) {
                        Image(systemName: "figure.run")
                            .font(.callout)
                            .foregroundStyle(.orange)
                        Text("Active")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    Text("+")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    VStack(spacing: 3) {
                        Image(systemName: "figure.stand")
                            .font(.callout)
                            .foregroundStyle(.orange)
                        Text("Resting")
                            .font(.system(size: 9, weight: .semibold))
                    }
                }
                Text("Total burned")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.12))
            )

            Text("−")
                .font(.headline)
                .foregroundStyle(.secondary)

            // Diet log
            VStack(spacing: 4) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.callout)
                    .foregroundStyle(.cyan)
                Text("Diet log")
                    .font(.system(size: 9, weight: .semibold))
                Text("Total con-\nsumed")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cyan.opacity(0.12))
            )

            Text("=")
                .font(.headline)
                .foregroundStyle(.secondary)

            // Calorie deficit
            VStack(spacing: 4) {
                Image(systemName: "gauge.with.needle.fill")
                    .font(.callout)
                    .foregroundStyle(.green)
                Text("Calorie")
                    .font(.system(size: 9, weight: .semibold))
                Text("deficit")
                    .font(.system(size: 9, weight: .semibold))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
        }
    }

    // MARK: - Explanation Section

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            bulletSection(
                title: "Calorie deficit",
                body: "The difference between the total number of calories consumed and burned. In order to lose weight, the number of calories burned needs to be greater than the amount consumed.",
                subTitle: "Target calorie deficit",
                subBody: "This is based on your current weight and how fast you want to reach your weight goal. A shorter time period and larger difference between your current and target weight generally require a larger calorie deficit."
            )

            bulletSection(
                title: "Total burned",
                titleSuffix: " = **Resting** + **Active**",
                body: ", this is the total calories burned that day.",
                subTitle: "Resting",
                subBody: "Calories burned to maintain basic body functionality while resting. This includes basal metabolism, brain activity, digestion, and other vital functions. This varies depending on activity, but is usually 20% higher than your basal metabolism.",
                subTitle2: "Active",
                subBody2: "Calories burned through activity, such as workouts, house chores, and other exercise."
            )

            bulletSection(
                title: "Total consumed",
                body: "The actual amount of calories you consume or need to consume. Actual amount of calories consumed needs to be entered manually. The amount you need to consume is calculated based on your basal metabolism, weight goal, and goal progress."
            )
        }
    }

    private func bulletSection(
        title: String,
        titleSuffix: String? = nil,
        body: String,
        subTitle: String? = nil,
        subBody: String? = nil,
        subTitle2: String? = nil,
        subBody2: String? = nil
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\u{2022}")
                .font(.title3.bold())
            VStack(alignment: .leading, spacing: 8) {
                if let suffix = titleSuffix {
                    Text(try! AttributedString(markdown: "**\(title)**\(suffix)\(body)"))
                        .font(.subheadline)
                } else {
                    Text(try! AttributedString(markdown: "**\(title)**: \(body)"))
                        .font(.subheadline)
                }

                if let subTitle, let subBody {
                    Text(try! AttributedString(markdown: "**\(subTitle)**: \(subBody)"))
                        .font(.subheadline)
                }

                if let subTitle2, let subBody2 {
                    Text(try! AttributedString(markdown: "**\(subTitle2)**: \(subBody2)"))
                        .font(.subheadline)
                }
            }
        }
    }
}

// MARK: - Calorie Deficit Gauge (Speedometer Style)

private struct CalorieDeficitGauge: View {
    let value: Int

    private let minValue: Double = -800
    private let maxValue: Double = 800

    private var normalizedValue: Double {
        let clamped = min(max(Double(value), minValue), maxValue)
        return (clamped - minValue) / (maxValue - minValue)
    }

    private let gaugeSize: CGFloat = 220

    var body: some View {
        ZStack {
            // Colored arc segments
            arcSegments
            // Tick labels around the arc
            tickLabels
            // "Goal" label inside the green zone
            goalLabel
            // Needle pointing to value
            needle
            // Center text
            centerText
        }
        .frame(width: gaugeSize + 40, height: (gaugeSize / 2) + 40)
    }

    private var centerText: some View {
        VStack(spacing: 0) {
            Text("Calorie deficit")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
        }
        .offset(y: 16)
    }

    // MARK: - Arc

    private var arcSegments: some View {
        // Arc from 180° to 360° (left to right semicircle)
        let segments: [(Double, Double, Color)] = [
            (0.0, 0.3125, .red),       // -800 to -300
            (0.3125, 0.5, .orange),     // -300 to 0
            (0.5, 0.5625, .yellow),     // 0 to 100
            (0.5625, 0.75, .green),     // 100 to 400 (goal zone)
            (0.75, 0.875, .yellow),     // 400 to 600
            (0.875, 1.0, .orange),      // 600 to 800
        ]

        return ZStack {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                Circle()
                    .trim(from: seg.0 / 2, to: seg.1 / 2)
                    .stroke(seg.2, style: StrokeStyle(lineWidth: 20, lineCap: .butt))
                    .frame(width: gaugeSize, height: gaugeSize)
                    .rotationEffect(.degrees(180))
            }
        }
    }

    // MARK: - Tick Labels

    private var tickLabels: some View {
        let labels: [(String, Double)] = [
            ("-800", 0.0), ("-600", 0.125), ("-400", 0.25), ("-200", 0.375),
            ("0", 0.5), ("200", 0.625), ("400", 0.75), ("600", 0.875), ("800", 1.0)
        ]
        let radius = gaugeSize / 2 + 16

        return ZStack {
            ForEach(labels, id: \.0) { label, position in
                let angle = Angle.degrees(180 + position * 180)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .offset(
                        x: cos(angle.radians) * radius,
                        y: sin(angle.radians) * radius
                    )
            }
        }
    }

    // MARK: - Goal Label

    private var goalLabel: some View {
        let position = 0.6875 // midpoint of green zone
        let angle = Angle.degrees(180 + position * 180)
        let radius = gaugeSize / 2 - 24

        return Text("Goal")
            .font(.system(size: 10, weight: .bold))
            .italic()
            .foregroundStyle(.green)
            .rotationEffect(Angle.degrees(position * 180 - 90))
            .offset(
                x: cos(angle.radians) * radius,
                y: sin(angle.radians) * radius
            )
    }

    // MARK: - Needle

    private var needle: some View {
        let needleAngle = 180 + normalizedValue * 180
        let needleLength: CGFloat = gaugeSize / 2 - 30

        return ZStack {
            Rectangle()
                .fill(Color(white: 0.3))
                .frame(width: 2, height: needleLength)
                .offset(y: -needleLength / 2)
                .rotationEffect(.degrees(needleAngle - 90))

            Circle()
                .fill(Color(white: 0.3))
                .frame(width: 8, height: 8)
        }
    }
}

#Preview {
    NavigationStack {
        InstructionsView()
    }
}
