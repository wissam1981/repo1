import Testing
import Foundation
@testable import Zapper

@Test func remoteViewModelDefaultMode() {
    let container = DependencyContainer.shared
    let vm = RemoteViewModel(container: container)
    #expect(vm.activeMode == .navigation)
}

@Test func modeAutoSwitchesToMedia() {
    let container = DependencyContainer.shared
    let vm = RemoteViewModel(container: container)
    var state = TVState()
    state.playbackState = .playing
    vm.handleStateUpdate(state)
    #expect(vm.activeMode == .media)
}

@Test func modeAutoSwitchesToKeyboard() {
    let container = DependencyContainer.shared
    let vm = RemoteViewModel(container: container)
    var state = TVState()
    state.isTextInputFocused = true
    vm.handleStateUpdate(state)
    #expect(vm.activeMode == .keyboard)
}

@Test func manualModeOverride() {
    let container = DependencyContainer.shared
    let vm = RemoteViewModel(container: container)
    vm.setManualMode(.appLauncher)
    #expect(vm.activeMode == .appLauncher)
    var state = TVState()
    state.playbackState = .playing
    vm.handleStateUpdate(state)
    #expect(vm.activeMode == .appLauncher)
}
