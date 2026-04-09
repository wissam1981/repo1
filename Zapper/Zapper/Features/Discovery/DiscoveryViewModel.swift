import Foundation

@Observable
@MainActor
final class DiscoveryViewModel {
    private(set) var devices: [TVDevice] = []
    private(set) var isScanning = false
    var showManualEntry = false
    var showPairing = false
    var selectedDevice: TVDevice?
    var manualIPAddress = ""
    var pairingPIN = ""
    var pairingError: String?

    private let discoveryService: DiscoveryService
    private let connectionManager: ConnectionManager
    private var scanTask: Task<Void, Never>?

    init(discoveryService: DiscoveryService, connectionManager: ConnectionManager) {
        self.discoveryService = discoveryService
        self.connectionManager = connectionManager
    }

    func startScanning() {
        scanTask = Task {
            await discoveryService.startScanning()
            isScanning = true
            while !Task.isCancelled {
                devices = discoveryService.discoveredDevices
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }

    func stopScanning() {
        scanTask?.cancel()
        scanTask = nil
        Task { await discoveryService.stopScanning() }
        isScanning = false
    }

    func selectDevice(_ device: TVDevice) {
        selectedDevice = device
        if device.pairingStatus == .unpaired {
            showPairing = true
        } else {
            connectToDevice(device)
        }
    }

    func addManualDevice() {
        guard !manualIPAddress.isEmpty else { return }
        let device = TVDevice(
            name: manualIPAddress,
            ipAddress: manualIPAddress,
            platform: .androidTV
        )
        selectDevice(device)
        showManualEntry = false
    }

    func submitPIN() {
        guard let device = selectedDevice else { return }
        pairingError = nil
        Task {
            do {
                try await connectionManager.connect(to: device)
                showPairing = false
            } catch {
                pairingError = error.localizedDescription
            }
        }
    }

    private func connectToDevice(_ device: TVDevice) {
        Task {
            do {
                try await connectionManager.connect(to: device)
            } catch {
                pairingError = error.localizedDescription
            }
        }
    }
}
