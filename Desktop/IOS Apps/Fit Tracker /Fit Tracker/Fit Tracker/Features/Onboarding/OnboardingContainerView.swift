import SwiftUI

// MARK: - Onboarding Container View
// Coordinates the 7-step onboarding wizard with animated transitions.
// Dark theme with gradient accents matching BiteBrain's premium feel.

struct OnboardingContainerView: View {
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(DependencyContainer.self) private var container
    @State private var viewModel = OnboardingViewModel()
    @State private var animateGradient = false
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 0) {
            topBar
            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            bottomButton
        }
        .background(
            ZStack {
                ThemeColors.backgroundDark
                RadialGradient(
                    colors: [ThemeColors.primary.opacity(0.06), .clear],
                    center: .top,
                    startRadius: 50,
                    endRadius: 400
                )
            }
            .ignoresSafeArea()
        )
        .preferredColorScheme(ThemeManager.shared.currentTheme.isLightTheme ? .light : .dark)
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
        .sheet(isPresented: $showPaywall, onDismiss: {
            viewModel.goNext()
        }) {
            PaywallView()
                .environment(subscriptionManager)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: 14) {
            HStack {
                if viewModel.canGoBack {
                    Button {
                        viewModel.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                } else {
                    Color.clear.frame(width: 40, height: 40)
                }

                Spacer()

                Text(String(localized: "Step \(viewModel.currentStep.rawValue + 1) of \(OnboardingStep.allCases.count)"))
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.06)))

                Spacer()

                Color.clear.frame(width: 40, height: 40)
            }

            // Gradient progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 4)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [ThemeColors.primary, ThemeColors.info],
                                startPoint: animateGradient ? .leading : .trailing,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * viewModel.currentStep.progress, height: 4)
                        .shadow(color: ThemeColors.primary.opacity(0.4), radius: 4, y: 0)
                        .animation(.spring(response: 0.5), value: viewModel.currentStep)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .gender:
            OnboardingGenderView(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        case .age:
            OnboardingAgeView(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        case .body:
            OnboardingBodyView(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        case .activity:
            OnboardingActivityView(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        case .goal:
            OnboardingGoalView(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        case .goalSpeed:
            OnboardingGoalSpeedView(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        case .goalWeight:
            OnboardingGoalWeightView(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        case .notifications:
            OnboardingNotificationView(viewModel: viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        case .subscribe:
            VStack(spacing: 20) {
                ProgressView()
                    .controlSize(.large)
                    .tint(ThemeColors.primary)
                
                Text("Analyzing your results…")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .onAppear {
                if !subscriptionManager.isSubscribed {
                    showPaywall = true
                } else {
                    viewModel.goNext()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        case .results:
            OnboardingResultsView(viewModel: viewModel)
        }
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        Group {
            if viewModel.currentStep != .subscribe {
                Button {
                    if viewModel.isLastStep {
                Task {
                    await viewModel.completeOnboarding(
                        appState: appState,
                        coreDataService: container.coreDataService,
                        firestoreService: container.firestoreService
                    )
                }
            } else {
                viewModel.goNext()
            }
        } label: {
            Group {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.black)
                } else {
                    HStack(spacing: 8) {
                        Text(viewModel.isLastStep ? "Start Your Journey" : "Continue")
                            .fontWeight(.bold)

                        Image(systemName: viewModel.isLastStep ? "sparkles" : "arrow.right")
                            .font(.subheadline.bold())
                    }
                }
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
        .disabled(viewModel.isSaving || (viewModel.currentStep == .goalWeight && !viewModel.isGoalWeightValid))
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
            }
        }
    }
}
