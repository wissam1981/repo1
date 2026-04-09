import SwiftUI

struct BottomNavBar: View {
    @Binding var activeMode: RemoteMode
    var onModeSelected: (RemoteMode) -> Void

    private let tabs: [(mode: RemoteMode, icon: String)] = [
        (.navigation, "gamecontroller"),
        (.media, "play.circle"),
        (.keyboard, "keyboard"),
        (.appLauncher, "square.grid.2x2"),
    ]

    var body: some View {
        HStack {
            ForEach(tabs, id: \.mode) { tab in
                Spacer()
                Button {
                    onModeSelected(tab.mode)
                } label: {
                    Image(systemName: tab.mode == activeMode ? "\(tab.icon).fill" : tab.icon)
                        .font(.title2)
                        .foregroundStyle(
                            tab.mode == activeMode
                                ? ZapperTheme.Colors.primary
                                : Color(hex: 0x64748B)
                        )
                        .frame(width: 48, height: 48)
                        .background(
                            tab.mode == activeMode
                                ? ZapperTheme.Colors.primaryContainer.opacity(0.2)
                                : .clear
                        )
                        .clipShape(Circle())
                        .overlay(
                            tab.mode == activeMode
                                ? Circle().stroke(ZapperTheme.Colors.primary.opacity(0.3), lineWidth: 1)
                                : nil
                        )
                }
                .jewelButton()
                Spacer()
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 40)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color(hex: 0x0F172A, opacity: 0.6))
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: ZapperTheme.Dimensions.navBarCornerRadius,
                        topTrailingRadius: ZapperTheme.Dimensions.navBarCornerRadius
                    )
                )
                .shadow(color: .black.opacity(0.5), radius: 25, y: -10)
        )
    }
}
