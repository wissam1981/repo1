import SwiftUI

struct ModeIndicator: View {
    var activeMode: RemoteMode

    private let modes: [RemoteMode] = [.navigation, .media, .keyboard, .appLauncher]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(modes, id: \.self) { mode in
                if mode == activeMode {
                    Capsule()
                        .fill(ZapperTheme.Colors.primary)
                        .frame(width: 20, height: 6)
                        .shadow(color: ZapperTheme.Colors.primary.opacity(0.5), radius: 6)
                } else {
                    Circle()
                        .fill(ZapperTheme.Colors.surfaceContainerHighest.opacity(0.5))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .animation(.spring(response: 0.3), value: activeMode)
    }
}
