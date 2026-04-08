import Testing
import Foundation
@testable import Zapper

@Test func parseVolumeMessage() {
    let handler = AndroidTVMessageHandler()
    let data = Data([0x08, 0x0F, 0x10, 0x0F, 0x18, 0x00])
    let update = handler.parseMessage(type: .volumeInfo, data: data)
    if case .volume(let level, let isMuted) = update {
        #expect(level == 1.0)
        #expect(isMuted == false)
    } else {
        Issue.record("Expected volume update")
    }
}

@Test func commandToKeyCodeMapping() {
    #expect(TVCommand.dpad(.up).androidKeyCode == .up)
    #expect(TVCommand.dpad(.down).androidKeyCode == .down)
    #expect(TVCommand.select.androidKeyCode == .select)
    #expect(TVCommand.back.androidKeyCode == .back)
    #expect(TVCommand.home.androidKeyCode == .home)
    #expect(TVCommand.power.androidKeyCode == .power)
    #expect(TVCommand.playPause.androidKeyCode == .playPause)
    #expect(TVCommand.volumeUp.androidKeyCode == .volumeUp)
    #expect(TVCommand.seekForward(seconds: 10).androidKeyCode == nil)
}
