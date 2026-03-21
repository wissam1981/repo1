import SwiftUI

// MARK: - Macro Breakdown Card (Carousel Slide 2)
// High-visibility stylish breakdown of Protein, Carbs, and Fats.

struct MacroBreakdownCard: View {
    let proteinConsumed: Int
    let proteinTarget: Int

    let carbsConsumed: Int
    let carbsTarget: Int

    let fatConsumed: Int
    let fatTarget: Int

    var body: some View {
        VStack(spacing: 22) {
            HStack {
                Text("Macronutrients")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(ThemeColors.textPrimary)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(ThemeColors.primary.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ThemeColors.primary)
                }
            }

            VStack(spacing: 18) {
                macroRow(
                    label: "Protein",
                    consumed: proteinConsumed,
                    target: proteinTarget,
                    color: ThemeColors.primary,
                    icon: "bolt.fill"
                )

                macroRow(
                    label: "Carbohydrates",
                    consumed: carbsConsumed,
                    target: carbsTarget,
                    color: ThemeColors.success,
                    icon: "leaf.fill"
                )

                macroRow(
                    label: "Healthy Fats",
                    consumed: fatConsumed,
                    target: fatTarget,
                    color: ThemeColors.secondary,
                    icon: "drop.fill"
                )
            }

            Spacer()
        }
        .padding(22)
        .glassStyle(cornerRadius: 24, color: ThemeColors.surfaceColor)
    }

    private func macroRow(label: String, consumed: Int, target: Int, color: Color, icon: String) -> some View {
        let prog = target > 0 ? min(Double(consumed) / Double(target), 1.0) : 0.0
        let percentage = Int(prog * 100)

        return VStack(spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 30, height: 30)
                        Image(systemName: icon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(color)
                    }

                    Text(label)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(ThemeColors.textPrimary)
                }

                Spacer()

                Text("\(consumed)g / \(target)g")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(ThemeColors.textSecondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(ThemeColors.surfaceColor)
                        .frame(height: 12)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(4, geo.size.width * CGFloat(prog)), height: 12)
                        .shadow(color: color.opacity(prog > 0 ? 0.4 : 0), radius: 6, x: 0, y: 0)
                }
            }
            .frame(height: 12)

            HStack {
                Text("\(percentage)% of daily goal")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color.opacity(0.8))
                Spacer()
            }
        }
    }
}

#Preview {
    ZStack {
        ThemeColors.backgroundDark.ignoresSafeArea()
        MacroBreakdownCard(
            proteinConsumed: 120,
            proteinTarget: 160,
            carbsConsumed: 200,
            carbsTarget: 250,
            fatConsumed: 45,
            fatTarget: 60
        )
        .padding()
        .frame(height: 320)
    }
}
