import Foundation
import Network

@Observable
final class DiscoveryService: @unchecked Sendable {
    private(set) var discoveredDevices: [TVDevice] = []
    private(set) var isScanning = false

    private var browser: NWBrowser?
    private let queue = DispatchQueue(label: "com.zapper.discovery")

    func startScanning() async {
        guard !isScanning else { return }
        await MainActor.run { isScanning = true }
        await MainActor.run { discoveredDevices = [] }

        let descriptor = NWBrowser.Descriptor.bonjour(
            type: "_androidtvremote2._tcp",
            domain: nil
        )
        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        let browser = NWBrowser(for: descriptor, using: parameters)
        self.browser = browser

        browser.stateUpdateHandler = { [weak self] state in
            switch state {
            case .failed, .cancelled:
                Task { @MainActor in self?.isScanning = false }
            default:
                break
            }
        }

        browser.browseResultsChangedHandler = { [weak self] results, _ in
            guard let self else { return }
            let devices = results.compactMap { result -> TVDevice? in
                guard case .service(let name, _, _, _) = result.endpoint else {
                    return nil
                }
                return TVDevice(
                    name: name,
                    ipAddress: "",
                    platform: .androidTV
                )
            }
            Task { @MainActor in
                self.discoveredDevices = devices
            }
        }

        browser.start(queue: queue)
    }

    func stopScanning() async {
        browser?.cancel()
        browser = nil
        await MainActor.run { isScanning = false }
    }

    deinit {
        browser?.cancel()
    }
}
