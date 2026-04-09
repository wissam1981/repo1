import Testing
import Foundation
@testable import Zapper

@Test func connectionManagerInitialState() {
    let manager = ConnectionManager()
    #expect(manager.currentDevice == nil)
    #expect(manager.connectionStatus == .disconnected)
}

@Test func connectionManagerSavesDevice() {
    let manager = ConnectionManager()
    let device = TVDevice(name: "Test TV", ipAddress: "192.168.1.1", platform: .androidTV)
    manager.addSavedDevice(device)
    #expect(manager.savedDevices.contains(where: { $0.id == device.id }))
}

@Test func connectionManagerRemovesDevice() {
    let manager = ConnectionManager()
    let device = TVDevice(name: "Test TV", ipAddress: "192.168.1.1", platform: .androidTV)
    manager.addSavedDevice(device)
    manager.removeSavedDevice(device)
    #expect(!manager.savedDevices.contains(where: { $0.id == device.id }))
}
