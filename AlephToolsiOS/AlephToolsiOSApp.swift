import SwiftUI
import AppIntents

@main
struct AlephToolsiOSApp: App {
    var body: some Scene {
        WindowGroup {
            iOSContentView()
                .onAppear {
                    AlephToolsShortcuts.updateAppShortcutParameters()
                }
        }
    }
}
