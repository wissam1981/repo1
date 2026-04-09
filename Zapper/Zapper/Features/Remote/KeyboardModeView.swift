import SwiftUI

struct KeyboardModeView: View {
    var viewModel: RemoteViewModel
    @State private var textInput = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TYPING INTO")
                        .font(ZapperTheme.Typography.label(9, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(ZapperTheme.Colors.outline)

                    Text(viewModel.tvState.currentApp?.name ?? "TV")
                        .font(ZapperTheme.Typography.body(13))
                        .foregroundStyle(ZapperTheme.Colors.onSurfaceVariant)
                }
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ZapperTheme.Colors.primaryContainer.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(ZapperTheme.Colors.primaryContainer.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)

            HStack {
                TextField("Type here...", text: $textInput)
                    .font(ZapperTheme.Typography.body(16, weight: .medium))
                    .foregroundStyle(ZapperTheme.Colors.onSurface)
                    .focused($isTextFieldFocused)
                    .submitLabel(.send)
                    .onSubmit { sendText() }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: 0x1F1F25, opacity: 0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(ZapperTheme.Colors.primary.opacity(0.3), lineWidth: 1.5)
                    )
                    .shadow(color: ZapperTheme.Colors.primaryContainer.opacity(0.05), radius: 12)
            )
            .padding(.horizontal, 24)

            HStack(spacing: 12) {
                Button {
                    textInput = ""
                } label: {
                    Text("Clear")
                        .font(ZapperTheme.Typography.label(13, weight: .semibold))
                        .foregroundStyle(ZapperTheme.Colors.onSurfaceVariant)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .glassPanel(cornerRadius: 14)
                }
                .jewelButton()

                Button {
                    sendText()
                } label: {
                    HStack(spacing: 6) {
                        Text("Send")
                            .font(ZapperTheme.Typography.label(13, weight: .bold))
                        Image(systemName: "return")
                            .font(.caption)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [ZapperTheme.Colors.primaryContainer, Color(hex: 0x1D4ED8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: ZapperTheme.Colors.primaryContainer.opacity(0.3), radius: 8)
                }
                .jewelButton()
                .disabled(textInput.isEmpty)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .onAppear { isTextFieldFocused = true }
    }

    private func sendText() {
        guard !textInput.isEmpty else { return }
        viewModel.sendText(textInput)
        textInput = ""
    }
}
