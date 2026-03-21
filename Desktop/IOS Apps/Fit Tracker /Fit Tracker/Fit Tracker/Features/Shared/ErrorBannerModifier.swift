import SwiftUI

// MARK: - Error Banner Modifier
// Shows a dismissible error banner at the top of any view.

struct ErrorBannerModifier: ViewModifier {
    @Environment(AppState.self) private var appState

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if let error = appState.errorMessage {
                errorBanner(error)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.3), value: appState.errorMessage)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(2)
            Spacer()
            Button {
                appState.clearError()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(ThemeColors.error))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

extension View {
    func errorBanner() -> some View {
        modifier(ErrorBannerModifier())
    }
}
