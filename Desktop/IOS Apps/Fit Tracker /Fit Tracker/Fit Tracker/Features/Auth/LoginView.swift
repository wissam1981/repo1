import SwiftUI
import AuthenticationServices

// MARK: - Login View (FuelIQ Redesign)

struct LoginView: View {
    var viewModel: AuthViewModel

    @State private var isAnimating = false
    @State private var glowOpacity = 0.6
    @State private var bgScale: CGFloat = 1.1

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            ZStack {
                // ── Background: High-Quality Athletic Image with Scale Animation ──
                Image("LoginBackground 1")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(bgScale)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .overlay(
                        LinearGradient(
                            colors: [Color.black.opacity(0.3), Color.black.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                VStack {
                    Spacer().frame(height: height * 0.12)
                    
                    // ── Header: FuelIQ Elite Branding with Staggered Entrance ──
                    VStack(spacing: -10) {
                        Text("FUELIQ")
                            .font(.system(size: 68, weight: .black, design: .default))
                            .kerning(-4)
                            .foregroundStyle(.white)
                            .offset(y: isAnimating ? 0 : -50)
                            .opacity(isAnimating ? 1 : 0)
                        
                        Text("ELITE")
                            .font(.system(size: 68, weight: .black, design: .default))
                            .kerning(-4)
                            .foregroundStyle(ThemeColors.primary)
                            .shadow(color: ThemeColors.primary.opacity(glowOpacity), radius: 25)
                            .offset(y: isAnimating ? 0 : 50)
                            .opacity(isAnimating ? 1 : 0)
                    }
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: isAnimating)
                    
                    Text("AI COACH · SMART PLANS · ELITE RESULTS")
                        .font(.system(size: 11, weight: .bold))
                        .kerning(6)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.top, 16)
                        .opacity(isAnimating ? 1 : 0)
                        .animation(.easeOut(duration: 0.8).delay(0.6), value: isAnimating)
                    
                    Spacer()
                    
                    // ── Action Card: Glassmorphism with Bouncy Entrance ──
                    VStack(spacing: 32) {
                        // Headline
                        VStack(spacing: 8) {
                            Text("SIGN IN")
                                .font(.system(size: 11, weight: .black))
                                .kerning(5)
                                .foregroundStyle(.white.opacity(0.4))
                            
                            Text("Unlock Your AI-Powered Fitness Coach")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        // Error Box
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.red)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 12).fill(.red.opacity(0.1)))
                        }

                        // ── Primary Actions ──
                        VStack(spacing: 16) {
                            // Apple Sign In
                            SignInWithAppleButton(.continue) { request in
                                request.requestedScopes = [.fullName, .email]
                                request.nonce = viewModel.prepareAppleSignInRequest()
                            } onCompletion: { result in
                                Task {
                                    await viewModel.handleAppleSignIn(result)
                                }
                            }
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 58)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.15), lineWidth: 1)
                            )
                            .offset(x: isAnimating ? 0 : 40)
                            .opacity(isAnimating ? 1 : 0)
                            .animation(.spring().delay(1.0), value: isAnimating)
                            
                            // Google Sign In
                            Button(action: {
                                Task { await viewModel.signInWithGoogle() }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "g.circle.fill")
                                        .resizable()
                                        .frame(width: 22, height: 22)
                                        .foregroundStyle(.black)
                                    
                                    Text("Continue with Google")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundStyle(.black)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .offset(x: isAnimating ? 0 : 40)
                            .opacity(isAnimating ? 1 : 0)
                            .animation(.spring().delay(1.2), value: isAnimating)
                        }
                        
                        Text("FUELIQ™ ELITE")
                            .font(.system(size: 10, weight: .black))
                            .kerning(2)
                            .foregroundStyle(.white.opacity(0.2))
                            .padding(.top, 8)
                    }
                    .padding(32)
                    .glassStyle(cornerRadius: 32, color: ThemeColors.backgroundDark.opacity(0.6))
                    .offset(y: isAnimating ? 0 : 100)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(.spring(response: 0.9, dampingFraction: 0.75).delay(0.8), value: isAnimating)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 60)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                isAnimating = true
                bgScale = 1.0
            }
            
            // Continuous pulsing glow
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowOpacity = 0.9
            }
        }
    }
}
