import SwiftUI

struct RemoteView: View {
    @Bindable var viewModel: RemoteViewModel

    var body: some View {
        ZStack {
            ZapperTheme.Colors.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                Group {
                    switch viewModel.activeMode {
                    case .navigation:
                        NavigationModeView(viewModel: viewModel)
                    case .media:
                        MediaModeView(viewModel: viewModel)
                    case .keyboard:
                        KeyboardModeView(viewModel: viewModel)
                    case .appLauncher:
                        AppLauncherView(viewModel: viewModel)
                    }
                }
                .frame(maxHeight: .infinity)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .animation(.spring(response: 0.3), value: viewModel.activeMode)

                ModeIndicator(activeMode: viewModel.activeMode)
                    .padding(.bottom, 8)
            }
            .padding(.bottom, 90)

            VStack {
                Spacer()
                BottomNavBar(activeMode: .init(
                    get: { viewModel.activeMode },
                    set: { _ in }
                )) { mode in
                    viewModel.setManualMode(mode)
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .onAppear {
            viewModel.startStatePolling()
            viewModel.loadInstalledApps()
        }
        .onDisappear {
            viewModel.stopStatePolling()
        }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "sensor.tag.radiowaves.forward")
                    .foregroundStyle(ZapperTheme.Colors.primary)

                Text(viewModel.tvState.currentApp?.name ?? "Living Room TV")
                    .font(ZapperTheme.Typography.headline(16, weight: .bold))
                    .foregroundStyle(ZapperTheme.Colors.primary)

                if viewModel.tvState.connectionStatus == .connected {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                        .shadow(color: .green.opacity(0.5), radius: 4)
                }
            }

            Spacer()

            Button {
            } label: {
                Image(systemName: "appletvremote.gen4")
                    .foregroundStyle(ZapperTheme.Colors.onSurfaceVariant)
                    .padding(8)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color(hex: 0x0F172A, opacity: 0.6))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
