import SwiftUI

@main
struct AlephToolsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
        .defaultSize(width: 800, height: 560)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
