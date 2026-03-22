import SwiftUI

struct WaterTrackerView: View {
    @Bindable var viewModel: NutritionViewModel

    var dailyTargetMl: Double { Double(viewModel.targetWaterMl) }

    @State private var isExpanded = false
    @State private var waveOffset: Angle = .zero

    var progress: Double {
        min(viewModel.todayLog.waterMl / dailyTargetMl, 1.0)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Compact header — always visible
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "drop.fill")
                        .font(.title3)
                        .foregroundStyle(progress >= 1.0 ? ThemeColors.success : ThemeColors.info)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Water")
                            .font(.subheadline.bold())
                        Text(String(localized: "\(Int(viewModel.todayLog.waterMl)) / \(Int(dailyTargetMl)) ml"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Inline progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(ThemeColors.info.opacity(0.15))
                            Capsule()
                                .fill(progress >= 1.0 ? ThemeColors.success : ThemeColors.info)
                                .frame(width: geo.size.width * CGFloat(progress))
                                .animation(.spring(response: 0.5), value: progress)
                        }
                    }
                    .frame(width: 60, height: 6)

                    // Quick +250ml button (always available)
                    Button {
                        Task {
                            await viewModel.addWater(ml: 250)
                            triggerHaptic(.medium)
                        }
                    } label: {
                        Text("+250")
                            .font(.caption2.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(ThemeColors.info.opacity(0.15), in: Capsule())
                            .foregroundStyle(ThemeColors.info)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption2.bold())
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.spring(response: 0.3), value: isExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Expanded quick-add buttons
            if isExpanded {
                Divider()
                    .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        waterAddButton(amount: 250, icon: "cup.and.saucer.fill")
                        waterAddButton(amount: 500, icon: "drop.fill")
                        waterAddButton(amount: 750, icon: "bottle.fill")
                        // Subtract
                        Button {
                            Task { await viewModel.addWater(ml: -250) }
                            triggerHaptic(.light)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "minus.circle.fill")
                                Text("250ml")
                            }
                            .font(.caption.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(ThemeColors.surfaceColor, in: Capsule())
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(ThemeColors.surfaceColor))
    }

    private func waterAddButton(amount: Double, icon: String) -> some View {
        Button {
            Task {
                await viewModel.addWater(ml: amount)
                triggerHaptic(.medium)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text("+\(Int(amount))ml")
            }
            .font(.caption.bold())
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(ThemeColors.info.opacity(0.15), in: Capsule())
            .foregroundStyle(ThemeColors.info)
        }
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
