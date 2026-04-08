import SwiftUI

@main
struct ZapperApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Zapper")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.07, green: 0.07, blue: 0.09))
        }
    }
}
