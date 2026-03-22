import SwiftUI

// MARK: - Splash View
// Shows app branding while FirebaseAuthService's auth listener initializes.
// The listener calls appState.handleAuthStateChange() which transitions
// away from .splash automatically.

struct SplashView: View {
    @Environment(AppState.self) private var appState

    // Animation states
    @State private var flameScale: CGFloat = 0.3
    @State private var flameOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var ring2Scale: CGFloat = 0.4
    @State private var ring2Opacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0
    @State private var particlesVisible: Bool = false
    @State private var loaderOpacity: Double = 0

    // Gradient colors
    private let flameGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.4, blue: 0.0),   // Orange
            Color(red: 1.0, green: 0.2, blue: 0.1),   // Red-orange
            Color(red: 0.9, green: 0.1, blue: 0.2)    // Deep red
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let bgGradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.05, blue: 0.12),
            Color(red: 0.02, green: 0.02, blue: 0.08),
            Color.black
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        ZStack {
            // Background
            bgGradient.ignoresSafeArea()

            // Ambient glow behind icon
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.orange.opacity(0.3),
                            Color.orange.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 160
                    )
                )
                .frame(width: 320, height: 320)
                .scaleEffect(pulseScale)
                .opacity(glowOpacity)
                .offset(y: -60)

            VStack(spacing: 0) {
                Spacer()

                // MARK: - Icon Area
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.4),
                                    Color.red.opacity(0.2),
                                    Color.orange.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // Inner ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.6),
                                    Color.red.opacity(0.3)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(ring2Scale)
                        .opacity(ring2Opacity)

                    // Flame icon
                    Image(systemName: "flame.fill")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundStyle(flameGradient)
                        .shadow(color: .orange.opacity(0.6), radius: 20, y: 4)
                        .shadow(color: .red.opacity(0.3), radius: 40, y: 8)
                        .scaleEffect(flameScale)
                        .opacity(flameOpacity)
                        .scaleEffect(pulseScale)

                    // Floating particles
                    if particlesVisible {
                        ForEach(0..<6, id: \.self) { i in
                            FloatingParticle(index: i)
                        }
                    }
                }
                .frame(height: 180)

                Spacer().frame(height: 32)

                // MARK: - Title
                ZStack {
                    // Shimmer layer
                    Text("FuelIQ")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.0),
                                    .white.opacity(0.8),
                                    .white.opacity(0.0)
                                ],
                                startPoint: UnitPoint(x: shimmerOffset / 400, y: 0.5),
                                endPoint: UnitPoint(x: (shimmerOffset + 200) / 400, y: 0.5)
                            )
                        )

                    // Main title
                    Text("FuelIQ")
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .shadow(color: .orange.opacity(0.3), radius: 10, y: 2)
                .offset(y: titleOffset)
                .opacity(titleOpacity)

                Spacer().frame(height: 10)

                // MARK: - Subtitle
                Text("Eat Smart · Train Hard")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.orange.opacity(0.7),
                                Color.white.opacity(0.5)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .tracking(3)
                    .opacity(subtitleOpacity)

                Spacer()

                // MARK: - Loader
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        LoadingDot(index: i)
                    }
                }
                .opacity(loaderOpacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimations()
        }
        .task {
            // Instantly transition out of splash screen if Firebase hasn't taken over
            if appState.authPhase == .splash {
                appState.authPhase = .unauthenticated
            }
        }
    }

    // MARK: - Animation Sequence

    private func startAnimations() {
        // 1. Flame icon appears with spring
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.1)) {
            flameScale = 1.0
            flameOpacity = 1.0
        }

        // 2. Rings expand outward
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            ringScale = 1.0
            ringOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.7).delay(0.4)) {
            ring2Scale = 1.0
            ring2Opacity = 1.0
        }

        // 3. Glow appears
        withAnimation(.easeIn(duration: 0.8).delay(0.4)) {
            glowOpacity = 1.0
        }

        // 4. Particles start
        withAnimation(.easeIn(duration: 0.3).delay(0.6)) {
            particlesVisible = true
        }

        // 5. Title slides up
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6)) {
            titleOffset = 0
            titleOpacity = 1.0
        }

        // 6. Subtitle fades in
        withAnimation(.easeIn(duration: 0.5).delay(0.9)) {
            subtitleOpacity = 1.0
        }

        // 7. Shimmer across title
        withAnimation(.easeInOut(duration: 1.2).delay(1.0)) {
            shimmerOffset = 400
        }

        // 8. Loader appears
        withAnimation(.easeIn(duration: 0.4).delay(1.1)) {
            loaderOpacity = 1.0
        }

        // 9. Continuous pulse on flame
        withAnimation(
            .easeInOut(duration: 1.8)
            .repeatForever(autoreverses: true)
            .delay(1.0)
        ) {
            pulseScale = 1.08
        }
    }
}

// MARK: - Floating Particle

private struct FloatingParticle: View {
    let index: Int
    @State private var yOffset: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var xOffset: CGFloat = 0

    private var particleSize: CGFloat {
        CGFloat([3, 4, 2.5, 3.5, 2, 4.5][index % 6])
    }

    private var startX: CGFloat {
        CGFloat([-30, 25, -15, 35, -40, 20][index % 6])
    }

    private var delay: Double {
        Double([0.0, 0.3, 0.6, 0.9, 0.2, 0.7][index % 6])
    }

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.orange, .yellow.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: particleSize, height: particleSize)
            .shadow(color: .orange.opacity(0.5), radius: 3)
            .offset(x: startX + xOffset, y: yOffset)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeOut(duration: 2.0)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    yOffset = -100
                    opacity = 0
                    xOffset = CGFloat.random(in: -15...15)
                }
                // Initial fade in
                withAnimation(.easeIn(duration: 0.3).delay(delay)) {
                    opacity = 0.8
                }
            }
    }
}

// MARK: - Loading Dot

private struct LoadingDot: View {
    let index: Int
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.3

    var body: some View {
        Circle()
            .fill(Color.orange.opacity(0.8))
            .frame(width: 8, height: 8)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.2)
                ) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
    }
}
