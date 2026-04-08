import Foundation

protocol TVProtocol: AnyObject, Sendable {
    var state: TVState { get async }

    func connect(to device: TVDevice) async throws
    func disconnect() async
    func sendCommand(_ command: TVCommand) async throws
    func sendText(_ text: String) async throws
    func getInstalledApps() async throws -> [TVApp]
    func launchApp(_ app: TVApp) async throws
}
