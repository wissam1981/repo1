import SwiftUI

// MARK: - AI Coaching Card
// Stylish entry point for the AI Coaching feature on the Dashboard.

struct AICoachingCard: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(AppState.self) private var appState

    @State private var showPaywall = false
    @State private var showCoach = false

    var body: some View {
        Button {
            if subscriptionManager.isSubscribed {
                showCoach = true
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [ThemeColors.primary.opacity(0.3), ThemeColors.primary.opacity(0.05)],
                                center: .center,
                                startRadius: 2,
                                endRadius: 28
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ThemeColors.primary, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("AI Fit Coach")
                            .font(.subheadline.bold())
                            .foregroundStyle(ThemeColors.textPrimary)

                        Text("PRO")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [ThemeColors.primary, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            )
                    }

                    Text("Get personalized fitness & nutrition advice")
                        .font(.caption2)
                        .foregroundStyle(ThemeColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(ThemeColors.textSecondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [ThemeColors.primary.opacity(0.08), Color.cyan.opacity(0.04)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [ThemeColors.primary.opacity(0.25), Color.cyan.opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .fullScreenCover(isPresented: $showCoach) {
            if let user = appState.currentUser {
                AICoachView(viewModel: AICoachViewModel(user: user))
            }
        }
    }
}
