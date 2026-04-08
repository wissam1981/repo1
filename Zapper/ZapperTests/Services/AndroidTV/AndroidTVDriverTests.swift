import Testing
import Foundation
@testable import Zapper

@Test func driverInitialState() async {
    let driver = AndroidTVDriver()
    let state = await driver.state
    #expect(state.connectionStatus == .disconnected)
    #expect(state.playbackState == .idle)
    #expect(state.volume == 0.5)
}

@Test func keyCodeEncodingForDpadUp() {
    let encoded = AndroidTVDriver.encodeKeyPress(keyCode: .up, action: .press)
    #expect(!encoded.isEmpty)
    #expect(encoded[0] == 0x08)
    #expect(encoded[1] == 19)
}

@Test func keyCodeEncodingForSelect() {
    let encoded = AndroidTVDriver.encodeKeyPress(keyCode: .select, action: .press)
    #expect(!encoded.isEmpty)
    #expect(encoded[0] == 0x08)
    #expect(encoded[1] == 23)
}
