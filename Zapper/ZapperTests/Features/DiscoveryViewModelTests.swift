import Testing
import Foundation
@testable import Zapper

@Test func discoveryViewModelInitialState() {
    let vm = DiscoveryViewModel(
        discoveryService: DiscoveryService(),
        connectionManager: ConnectionManager()
    )
    #expect(vm.isScanning == false)
    #expect(vm.devices.isEmpty)
    #expect(vm.showManualEntry == false)
    #expect(vm.showPairing == false)
}
