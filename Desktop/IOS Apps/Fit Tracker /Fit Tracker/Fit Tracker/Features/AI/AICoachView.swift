import SwiftUI

// MARK: - AI Coach View
// Full-screen dark-themed chat interface for the AI Fit Coach.

struct AICoachView: View {
    @State var viewModel: AICoachViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            // Custom top bar
            coachTopBar

            // Error banner
            if let error = viewModel.errorMessage {
                coachErrorBanner(error)
            }

            // Chat messages
            chatArea

            // Persistent "What should I eat?" chip
            if !viewModel.isTyping {
                Button {
                    viewModel.askBudgetAdvisor()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ThemeColors.primary)
                        Text("What should I eat?")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ThemeColors.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(
                        Capsule()
                            .fill(ThemeColors.primary.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(ThemeColors.primary.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }

            // Suggestion chips (always visible, hidden only while AI is typing)
            if !viewModel.isTyping {
                suggestionsRow
            }

            // Input bar
            coachInputBar
        }
        .background(ThemeColors.backgroundDark.ignoresSafeArea())
        .onAppear {
            if let action = appState.pendingAIAction {
                appState.pendingAIAction = nil
                viewModel.handlePendingAction(action)
            }
        }
    }

    // MARK: - Top Bar

    private var coachTopBar: some View {
        HStack {
            Button { dismiss() } label: {
                ZStack {
                    Circle()
                        .fill(ThemeColors.surfaceColor)
                        .frame(width: 36, height: 36)
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(ThemeColors.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ThemeColors.primary, ThemeColors.primary.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: ThemeColors.primary.opacity(0.4), radius: 8, x: 0, y: 2)

                    Image(systemName: "cpu.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("AI Fit Coach")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(ThemeColors.textPrimary)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text("Online")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.green.opacity(0.8))
                    }
                }
            }

            Spacer()

            // Balance spacer
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(ThemeColors.surfaceColor)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        )
    }

    // MARK: - Error Banner

    private func coachErrorBanner(_ error: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.yellow)

            Text(error)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(ThemeColors.textSecondary)
                .lineLimit(2)

            Spacer()

            Button("Retry") { viewModel.retryLastMessage() }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(ThemeColors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(ThemeColors.surfaceColor))

            Button { viewModel.clearError() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(ThemeColors.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.red.opacity(0.15))
    }

    // MARK: - Chat Area

    private var chatArea: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Pinned weekly digest message
                    if let digestMsg = viewModel.weeklyDigestMessage {
                        CoachBubble(message: digestMsg)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }

                    ForEach(viewModel.messages) { message in
                        if message.role != .system {
                            CoachBubble(message: message)
                                .transition(.asymmetric(
                                    insertion: .move(edge: message.role == .user ? .trailing : .leading)
                                        .combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }

                    if viewModel.isTyping {
                        typingIndicator
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("chat_bottom")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.messages.count)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollDown(proxy)
            }
            .onChange(of: viewModel.isTyping) { _, typing in
                if typing { scrollDown(proxy) }
            }
        }
    }

    private var typingIndicator: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ThemeColors.primary, ThemeColors.primary.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                Image(systemName: "cpu.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 6) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(ThemeColors.primary.opacity(0.6))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(ThemeColors.surfaceColor)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            Spacer()
        }
    }

    private func scrollDown(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            proxy.scrollTo("chat_bottom", anchor: .bottom)
        }
    }

    // MARK: - Suggestions Row

    private var suggestionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(AICoachViewModel.suggestedPrompts.enumerated()), id: \.offset) { _, prompt in
                    Button {
                        viewModel.sendSuggestion(prompt.text)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: prompt.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(ThemeColors.primary)
                            Text(prompt.text)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(ThemeColors.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(
                            Capsule()
                                .fill(ThemeColors.surfaceColor)
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                colors: [ThemeColors.primary.opacity(0.3), ThemeColors.surfaceBorder],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.white.opacity(0.02))
    }

    // MARK: - Input Bar

    private var coachInputBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(ThemeColors.surfaceBorder)
                .frame(height: 1)

            HStack(alignment: .bottom, spacing: 12) {
                TextField("Ask your coach anything...", text: $viewModel.inputText, axis: .vertical)
                    .lineLimit(1...5)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(ThemeColors.surfaceColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(ThemeColors.surfaceBorder, lineWidth: 1)
                            )
                    )
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(ThemeColors.textPrimary)
                    .disabled(viewModel.isTyping)

                coachSendButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(ThemeColors.surfaceColor)
    }

    private var coachSendButton: some View {
        let canSend = !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isTyping

        return Button {
            viewModel.sendMessage()
        } label: {
            ZStack {
                Circle()
                    .fill(
                        canSend
                        ? LinearGradient(colors: [ThemeColors.primary, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [ThemeColors.surfaceColor], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 46, height: 46)
                    .shadow(color: canSend ? ThemeColors.primary.opacity(0.4) : .clear, radius: 8, x: 0, y: 2)

                if viewModel.isTyping {
                    ProgressView()
                        .tint(.white.opacity(0.5))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(canSend ? .white : .white.opacity(0.2))
                }
            }
        }
        .disabled(!canSend)
    }
}

// MARK: - Message Bubble (Redesigned with Styled Text)

private struct CoachBubble: View {
    let message: ChatMessage
    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if isUser { Spacer(minLength: 50) }

            // Coach avatar
            if !isUser {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [ThemeColors.primary, ThemeColors.primary.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                        .shadow(color: ThemeColors.primary.opacity(0.3), radius: 6, x: 0, y: 2)

                    Image(systemName: "cpu.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 2)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                // Message content — no more HStack with accent bar
                Group {
                    if isUser {
                        Text(message.content)
                            .font(.system(size: 17, weight: .regular))
                            .lineSpacing(6)
                            .foregroundStyle(.white)
                    } else {
                        StyledCoachText(text: message.content)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background {
                    if isUser {
                        LinearGradient(
                            colors: [ThemeColors.primary, .cyan.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        let isLight = ThemeManager.shared.currentTheme.isLightTheme
                        LinearGradient(
                            colors: [
                                ThemeColors.primary.opacity(isLight ? 0.18 : 0.15),
                                Color.cyan.opacity(isLight ? 0.10 : 0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: isUser ? 22 : 4,
                        bottomLeadingRadius: 22,
                        bottomTrailingRadius: isUser ? 4 : 22,
                        topTrailingRadius: 22
                    )
                )
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: isUser ? 22 : 4,
                        bottomLeadingRadius: 22,
                        bottomTrailingRadius: isUser ? 4 : 22,
                        topTrailingRadius: 22
                    )
                    .stroke(
                        LinearGradient(
                            colors: [ThemeColors.primary.opacity(0.4), ThemeColors.primary.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isUser ? 0 : 1
                    )
                )
                .shadow(color: ThemeColors.primary.opacity(0.15), radius: 12, x: 0, y: 4)

                Text(message.timestamp, style: .time)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(ThemeColors.textSecondary)
                    .padding(.horizontal, 6)
            }

            if !isUser { Spacer(minLength: 50) }
        }
    }
}
