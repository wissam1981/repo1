import SwiftUI
struct AppLauncherView: View {
    var viewModel: RemoteViewModel
    var body: some View {
        Text("App Launcher")
            .foregroundStyle(ZapperTheme.Colors.onSurface)
    }
}
