import Testing
@testable import Zapper

@Test func dpadCommands() {
    let up = TVCommand.dpad(.up)
    let down = TVCommand.dpad(.down)
    let left = TVCommand.dpad(.left)
    let right = TVCommand.dpad(.right)
    #expect(up != down)
    #expect(left != right)
}

@Test func allCommandVariants() {
    let commands: [TVCommand] = [
        .dpad(.up), .dpad(.down), .dpad(.left), .dpad(.right),
        .select, .back, .home, .menu,
        .playPause, .play, .pause, .stop,
        .skipForward, .skipBackward,
        .seekForward(seconds: 10), .seekBackward(seconds: 10),
        .volumeUp, .volumeDown, .mute,
        .power
    ]
    #expect(commands.count == 20)
}
