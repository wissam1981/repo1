import SwiftUI

// MARK: - Weight Entry Sheet
// Premium bottom sheet for quickly logging today's weight.

struct WeightEntrySheet: View {
    @Bindable var viewModel: ProgressViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    @State private var pulseRing = false
    @State private var animateGradient = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // MARK: Header
                    VStack(spacing: 12) {
                        // Animated icon with layered glass background
                        ZStack {
                            Circle()
                                .fill(ThemeColors.primary.opacity(0.12))
                                .frame(width: 64, height: 64)
                                .blur(radius: 8)
                            
                            Circle()
                                .strokeBorder(
                                    LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 1
                                )
                                .background(Circle().fill(ThemeColors.surfaceColor))
                                .frame(width: 56, height: 56)

                            Image(systemName: "scalemass.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [ThemeColors.primary, ThemeColors.info],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: ThemeColors.primary.opacity(0.5), radius: 8)
                        }
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.5)

                        VStack(spacing: 4) {
                            Text("Log Your Weight")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(ThemeColors.textPrimary)

                            Text("Track your progress accurately")
                                .font(.subheadline)
                                .foregroundStyle(ThemeColors.textSecondary)
                        }
                    }
                    .padding(.top, 24)

                    Spacer(minLength: 28)

                    // MARK: Glowing Weight Display
                    ZStack {
                        // Multi-layered pulsing glow
                        Circle()
                            .fill(ThemeColors.primary.opacity(0.1))
                            .frame(width: 280, height: 280)
                            .blur(radius: 40)
                            .scaleEffect(pulseRing ? 1.1 : 0.9)
                        
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [ThemeColors.primary.opacity(0.2), .clear],
                                    center: .center,
                                    startRadius: 80,
                                    endRadius: 130
                                )
                            )
                            .frame(width: 260, height: 260)
                            .scaleEffect(pulseRing ? 1.05 : 0.95)

                        // Outer glass border
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        ThemeColors.primary,
                                        ThemeColors.info,
                                        ThemeColors.primary.opacity(0.2),
                                        ThemeColors.info.opacity(0.5),
                                        ThemeColors.primary
                                    ],
                                    center: .center,
                                    angle: .degrees(animateGradient ? 0 : 360)
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 220, height: 220)
                            .shadow(color: ThemeColors.primary.opacity(0.5), radius: 15)

                        // Main display background
                        Circle()
                            .fill(Color(hex: "0A0D12").opacity(0.8))
                            .frame(width: 210, height: 210)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 10)

                        // Inner glowing ring
                        Circle()
                            .stroke(ThemeColors.primary.opacity(0.1), lineWidth: 4)
                            .frame(width: 180, height: 180)
                            .blur(radius: 2)

                        // Value
                        VStack(spacing: -2) {
                            Text(String(format: "%.1f", viewModel.newWeightKg))
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundStyle(ThemeColors.textPrimary)
                                .contentTransition(.numericText())
                                .shadow(color: ThemeColors.primary.opacity(0.6), radius: 12)

                            Text("kg")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(ThemeColors.primary.opacity(0.8))
                                .offset(y: -4)
                        }
                    }
                    .padding(.vertical, 10)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.newWeightKg)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.9)

                    Spacer(minLength: 24)

                    // MARK: Ruler Picker
                    VStack(spacing: 20) {
                        WeightRulerView(weight: $viewModel.newWeightKg)
                            .frame(height: 80)
                            .padding(.horizontal, 8)
                        
                        // MARK: Fine-tune Buttons
                        HStack(spacing: 12) {
                            adjustButton(label: "-1", amount: -1, isDecrease: true)
                            adjustButton(label: "-0.1", amount: -0.1, isDecrease: true)
                            adjustButton(label: "+0.1", amount: 0.1, isDecrease: false)
                            adjustButton(label: "+1", amount: 1, isDecrease: false)
                        }
                        .padding(.horizontal, 20)
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)

                    // MARK: Save Button
                    Button {
                        Task {
                            await viewModel.addWeight()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                            Text("Save Weight")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [ThemeColors.primary, ThemeColors.info],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: ThemeColors.primary.opacity(0.3), radius: 12, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 40)
                    .opacity(appeared ? 1 : 0)
                }
            }
            .background(
                ZStack {
                    ThemeColors.backgroundDark

                    // Subtle ambient glow
                    RadialGradient(
                        colors: [ThemeColors.primary.opacity(0.05), .clear],
                        center: .top,
                        startRadius: 50,
                        endRadius: 350
                    )
                }
                .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.subheadline)
                            .foregroundStyle(ThemeColors.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(ThemeColors.surfaceColor))
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                animateGradient = true
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseRing = true
            }
        }
    }

    // MARK: - Adjust Button

    private func adjustButton(label: String, amount: Double, isDecrease: Bool) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                viewModel.newWeightKg = max(30, min(250, viewModel.newWeightKg + amount))
            }
        } label: {
            Text(label)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(isDecrease ? ThemeColors.textSecondary : ThemeColors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(ThemeColors.surfaceColor)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(isDecrease ? 0.05 : 0.15), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
    }
}

// MARK: - Horizontal Ruler Picker

private struct WeightRulerView: View {
    @Binding var weight: Double

    private let step: Double = 0.5
    private let totalSteps = 441 // 30...250 in 0.5 steps
    private let tickSpacing: CGFloat = 18

    @State private var dragOffset: CGFloat = 0
    @State private var lastWeight: Double = 0

    private var currentIndex: Int {
        let idx = Int((weight - 30) / step)
        return max(0, min(totalSteps - 1, idx))
    }

    var body: some View {
        GeometryReader { geo in
            let center = geo.size.width / 2

            ZStack(alignment: .center) {
                // Scroll-driven ticks
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(0..<totalSteps, id: \.self) { i in
                            let value = 30.0 + Double(i) * step
                            let isMajor = i % 2 == 0
                            let isCurrent = abs(value - weight) < step / 2

                            VStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(
                                        isCurrent
                                            ? AnyShapeStyle(LinearGradient(colors: [ThemeColors.primary, ThemeColors.info], startPoint: .top, endPoint: .bottom))
                                            : isMajor
                                                ? AnyShapeStyle(ThemeColors.textSecondary)
                                                : AnyShapeStyle(ThemeColors.surfaceBorder)
                                    )
                                    .frame(width: isCurrent ? 3 : 1.5,
                                           height: isMajor ? 32 : 18)
                                    .shadow(color: isCurrent ? ThemeColors.primary.opacity(0.4) : .clear, radius: 4)

                                if isMajor && Int(value) % 5 == 0 {
                                    Text("\(Int(value))")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(isCurrent ? ThemeColors.textPrimary : ThemeColors.textSecondary)
                                        .scaleEffect(isCurrent ? 1.1 : 1.0)
                                }
                            }
                            .frame(width: tickSpacing)
                            .frame(maxHeight: .infinity, alignment: .top)
                            .animation(.spring(response: 0.2), value: isCurrent)
                        }
                    }
                    .padding(.horizontal, center)
                    .frame(height: 72)
                }
                .content.offset(x: -CGFloat(currentIndex) * tickSpacing)
                .disabled(true)

                // Center indicator with glow
                VStack(spacing: 0) {
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(ThemeColors.primary)
                        .rotationEffect(.degrees(180))
                        .offset(y: -2)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [ThemeColors.primary, ThemeColors.info],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3, height: 60)
                        .shadow(color: ThemeColors.primary.opacity(0.5), radius: 10)
                }
                .offset(y: -4)

                // Transparent drag layer
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if dragOffset == 0 { lastWeight = weight }
                                dragOffset = value.translation.width
                                let delta = -dragOffset / tickSpacing * step
                                weight = max(30, min(250, lastWeight + delta))
                            }
                            .onEnded { _ in
                                weight = (weight * 10).rounded() / 10
                                dragOffset = 0
                            }
                    )
            }
        }
        .clipShape(Rectangle())
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.15),
                    .init(color: .black, location: 0.85),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}
