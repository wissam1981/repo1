import SwiftUI

struct WelcomeView: View {
    var onGetStarted: () -> Void
    
    @State private var isAnimating = false
    @State private var bgScale: CGFloat = 1.05
    
    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            ZStack {
                // ── Background: Elite Athletic Preparation ──
                Image("WelcomeBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(bgScale)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .overlay(
                        LinearGradient(
                            colors: [Color.black.opacity(0.4), Color.black.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                VStack(spacing: 0) {
                    Spacer().frame(height: height * 0.1)
                    
                    // ── Header: Branding ──
                    VStack(spacing: -10) {
                        Text("FUELIQ")
                            .font(.system(size: 68, weight: .black))
                            .kerning(-4)
                            .foregroundStyle(.white)
                            .offset(y: isAnimating ? 0 : -30)
                            .opacity(isAnimating ? 1 : 0)
                        
                        Text("ELITE")
                            .font(.system(size: 68, weight: .black))
                            .kerning(-4)
                            .foregroundStyle(ThemeColors.primary)
                            .shadow(color: ThemeColors.primary.opacity(0.5), radius: 20)
                            .offset(y: isAnimating ? 0 : 30)
                            .opacity(isAnimating ? 1 : 0)
                    }
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: isAnimating)
                    
                    Text("AI-POWERED PERFORMANCE")
                        .font(.system(size: 14, weight: .black))
                        .kerning(8)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 20)
                        .opacity(isAnimating ? 1 : 0)
                        .animation(.easeOut(duration: 0.8).delay(0.7), value: isAnimating)
                    
                    Spacer()
                    
                    // ── Footer: Call to Action ──
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("YOUR AI COACH IS READY")
                                .font(.system(size: 11, weight: .bold))
                                .kerning(4)
                                .foregroundStyle(ThemeColors.primary.opacity(0.8))
                            
                            Text("Smart Plans · AI Coach · Real Results")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .opacity(isAnimating ? 1 : 0)
                        .animation(.easeOut(duration: 0.8).delay(1.0), value: isAnimating)
                        
                        Button(action: onGetStarted) {
                            Text("START YOUR JOURNEY")
                                .font(.system(size: 18, weight: .black))
                                .kerning(2)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 64)
                                .background(ThemeColors.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: ThemeColors.primary.opacity(0.3), radius: 15, y: 10)
                        }
                        .padding(.horizontal, 20)
                        .scaleEffect(isAnimating ? 1 : 0.9)
                        .opacity(isAnimating ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.2), value: isAnimating)
                    }
                    .padding(.bottom, 60)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.0)) {
                isAnimating = true
                bgScale = 1.0
            }
        }
    }
}

#Preview {
    WelcomeView {}
}
