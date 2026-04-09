import SwiftUI

struct NavigationModeView: View {
    var viewModel: RemoteViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Power & signal row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SIGNAL STRENGTH")
                        .font(ZapperTheme.Typography.label(9, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(ZapperTheme.Colors.outline)

                    HStack(spacing: 2) {
                        ForEach(0..<4, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(i < 3 ? ZapperTheme.Colors.primary : ZapperTheme.Colors.surfaceContainerHighest)
                                .frame(width: 4, height: 12)
                        }
                    }
                }

                Spacer()

                Button {
                    viewModel.sendCommand(.power)
                } label: {
                    Image(systemName: "power")
                        .font(.title2)
                        .foregroundStyle(ZapperTheme.Colors.error)
                        .frame(width: 64, height: 64)
                        .background(
                            Circle()
                                .fill(ZapperTheme.Colors.errorContainer.opacity(0.2))
                                .overlay(
                                    Circle()
                                        .stroke(ZapperTheme.Colors.error.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .shadow(color: ZapperTheme.Colors.error.opacity(0.15), radius: 15)
                }
                .jewelButton()
            }
            .padding(.horizontal, 16)

            // Touchpad
            TouchpadView(
                onSwipe: { direction in
                    viewModel.sendCommand(.dpad(direction))
                },
                onTap: {
                    viewModel.sendCommand(.select)
                }
            )
            .frame(maxWidth: 340)

            // Back / Home / Menu buttons
            HStack(spacing: 24) {
                navButton(icon: "arrow.backward", label: "Back") {
                    viewModel.sendCommand(.back)
                }
                navButton(icon: "house", label: "Home") {
                    viewModel.sendCommand(.home)
                }
                navButton(icon: "line.3.horizontal", label: "Menu") {
                    viewModel.sendCommand(.menu)
                }
            }

            // Volume bar
            HStack(spacing: 12) {
                Button { viewModel.sendCommand(.volumeDown) } label: {
                    Image(systemName: "speaker.fill")
                        .foregroundStyle(ZapperTheme.Colors.onSurfaceVariant)
                        .frame(width: 44, height: 44)
                }
                .jewelButton()

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(ZapperTheme.Colors.surfaceContainerHigh)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [ZapperTheme.Colors.primaryContainer, ZapperTheme.Colors.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(viewModel.tvState.volume))
                    }
                    .frame(height: 4)
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                .frame(height: 44)

                Button { viewModel.sendCommand(.volumeUp) } label: {
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundStyle(ZapperTheme.Colors.onSurfaceVariant)
                        .frame(width: 44, height: 44)
                }
                .jewelButton()
            }
            .padding(.horizontal, 16)
            .glassPanel(cornerRadius: 22)
            .frame(height: 56)
            .padding(.horizontal, 16)
        }
        .padding(.horizontal, 8)
    }

    private func navButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(ZapperTheme.Colors.onSurfaceVariant)
                    .frame(width: 56, height: 56)
                    .glassPanel(cornerRadius: 16)

                Text(label.uppercased())
                    .font(ZapperTheme.Typography.label(9, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(ZapperTheme.Colors.outline)
            }
        }
        .jewelButton()
    }
}
