import Testing
@testable import Zapper

@Test func tvStateDefaults() {
    let state = TVState()
    #expect(state.connectionStatus == .disconnected)
    #expect(state.powerState == .unknown)
    #expect(state.currentApp == nil)
    #expect(state.playbackState == .idle)
    #expect(state.mediaInfo == nil)
    #expect(state.volume == 0.5)
    #expect(state.isMuted == false)
    #expect(state.isTextInputFocused == false)
}

@Test func tvStateSuggestedMode() {
    var state = TVState()
    #expect(state.suggestedMode == .navigation)

    state.playbackState = .playing
    #expect(state.suggestedMode == .media)

    state.isTextInputFocused = true
    #expect(state.suggestedMode == .keyboard)

    state.isTextInputFocused = false
    state.playbackState = .idle
    #expect(state.suggestedMode == .navigation)
}
