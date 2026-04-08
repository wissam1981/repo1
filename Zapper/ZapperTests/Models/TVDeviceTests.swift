import Testing
@testable import Zapper

@Test func tvDeviceInitialization() {
    let device = TVDevice(
        name: "Living Room TCL",
        ipAddress: "192.168.1.42",
        platform: .androidTV,
        macAddress: "AA:BB:CC:DD:EE:FF"
    )
    #expect(device.name == "Living Room TCL")
    #expect(device.ipAddress == "192.168.1.42")
    #expect(device.platform == .androidTV)
    #expect(device.macAddress == "AA:BB:CC:DD:EE:FF")
    #expect(device.pairingStatus == .unpaired)
    #expect(device.capabilities.isEmpty)
}

@Test func tvDeviceEquality() {
    let device1 = TVDevice(name: "TV", ipAddress: "192.168.1.1", platform: .androidTV)
    var device2 = TVDevice(name: "TV", ipAddress: "192.168.1.1", platform: .androidTV)
    device2.id = device1.id
    #expect(device1 == device2)
}

@Test func tvPlatformCases() {
    let platforms: [TVPlatform] = [.androidTV, .roku, .samsung, .lgWebOS, .fireTV]
    #expect(platforms.count == 5)
}

@Test func tvCapabilityCases() {
    let caps: Set<TVCapability> = [.dpad, .mediaControl, .textInput, .appLaunch, .power, .volume]
    #expect(caps.count == 6)
}
