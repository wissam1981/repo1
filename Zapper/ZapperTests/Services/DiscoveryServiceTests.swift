import Testing
import Foundation
@testable import Zapper

@Test func discoveryServiceInitialState() {
    let service = DiscoveryService()
    #expect(service.discoveredDevices.isEmpty)
    #expect(service.isScanning == false)
}

@Test func discoveryServiceStartStop() async {
    let service = DiscoveryService()
    await service.startScanning()
    #expect(service.isScanning == true)
    await service.stopScanning()
    #expect(service.isScanning == false)
}
