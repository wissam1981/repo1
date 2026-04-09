import SwiftUI

struct DiscoveryView: View {
    @Bindable var viewModel: DiscoveryViewModel

    var body: some View {
        ZStack {
            ZapperTheme.Colors.surface.ignoresSafeArea()

            Circle()
                .fill(ZapperTheme.Colors.primaryContainer.opacity(0.05))
                .blur(radius: 120)
                .offset(x: -100, y: -200)

            Circle()
                .fill(ZapperTheme.Colors.secondaryContainer.opacity(0.05))
                .blur(radius: 100)
                .offset(x: 150, y: 300)

            ScrollView {
                VStack(spacing: 32) {
                    scanningIndicator
                        .padding(.top, 40)

                    if !viewModel.devices.isEmpty {
                        deviceList
                    }

                    manualEntryButton
                        .padding(.top, 16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 120)
            }
        }
        .onAppear { viewModel.startScanning() }
        .onDisappear { viewModel.stopScanning() }
        .sheet(isPresented: $viewModel.showManualEntry) {
            ManualEntrySheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showPairing) {
            PairingView(viewModel: viewModel)
        }
    }

    private var scanningIndicator: some View {
        VStack(spacing: 16) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(ZapperTheme.Colors.outlineVariant.opacity(0.1 * Double(3 - i)), lineWidth: 1)
                        .frame(width: CGFloat(80 + i * 32), height: CGFloat(80 + i * 32))
                }

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ZapperTheme.Colors.primary, ZapperTheme.Colors.primaryContainer],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: ZapperTheme.Colors.primaryContainer.opacity(0.3), radius: 20)
                    .overlay(
                        Image(systemName: "wifi.router")
                            .font(.title)
                            .foregroundStyle(ZapperTheme.Colors.onPrimaryContainer)
                    )
            }
            .frame(height: 160)

            Text("Searching for TVs...")
                .font(ZapperTheme.Typography.headline(24, weight: .heavy))
                .foregroundStyle(ZapperTheme.Colors.primary)

            Text("Ensure your devices are on the same Wi-Fi network.")
                .font(ZapperTheme.Typography.body(14))
                .foregroundStyle(ZapperTheme.Colors.onSurfaceVariant)
        }
    }

    private var deviceList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DISCOVERED DEVICES")
                .font(ZapperTheme.Typography.label(11, weight: .bold))
                .tracking(3)
                .foregroundStyle(ZapperTheme.Colors.outline)
                .padding(.leading, 4)

            ForEach(viewModel.devices) { device in
                DeviceCard(device: device) {
                    viewModel.selectDevice(device)
                }
            }
        }
    }

    private var manualEntryButton: some View {
        Button {
            viewModel.showManualEntry = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .foregroundStyle(ZapperTheme.Colors.primary)
                Text("Add by IP Address")
                    .font(ZapperTheme.Typography.label(14, weight: .semibold))
                    .foregroundStyle(ZapperTheme.Colors.onSurface)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(ZapperTheme.Colors.surfaceContainerHighest.opacity(0.5))
                    .overlay(
                        Capsule()
                            .stroke(ZapperTheme.Colors.outlineVariant.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .jewelButton()
    }
}

struct ManualEntrySheet: View {
    @Bindable var viewModel: DiscoveryViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                TextField("IP Address (e.g., 192.168.1.42)", text: $viewModel.manualIPAddress)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Button("Connect") {
                    viewModel.addManualDevice()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.manualIPAddress.isEmpty)

                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}
