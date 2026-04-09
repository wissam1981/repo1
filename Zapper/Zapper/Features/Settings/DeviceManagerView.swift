import SwiftUI

struct DeviceManagerView: View {
    @State private var container = DependencyContainer.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Connected") {
                    if let device = container.connectionManager.currentDevice {
                        DeviceRow(device: device, isConnected: true)
                    } else {
                        Text("No device connected")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Saved Devices") {
                    ForEach(container.connectionManager.savedDevices) { device in
                        DeviceRow(
                            device: device,
                            isConnected: device.id == container.connectionManager.currentDevice?.id
                        )
                        .onTapGesture {
                            Task { try? await container.connectionManager.connect(to: device) }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let device = container.connectionManager.savedDevices[index]
                            container.connectionManager.removeSavedDevice(device)
                        }
                    }
                }
            }
            .navigationTitle("Devices")
        }
    }
}

struct DeviceRow: View {
    let device: TVDevice
    var isConnected: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tv")
                .foregroundStyle(ZapperTheme.Colors.secondary)
                .frame(width: 40, height: 40)
                .background(ZapperTheme.Colors.surfaceContainerHighest)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(ZapperTheme.Typography.headline(15, weight: .bold))
                Text(device.ipAddress.isEmpty ? "mDNS device" : device.ipAddress)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isConnected {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
            }
        }
    }
}
