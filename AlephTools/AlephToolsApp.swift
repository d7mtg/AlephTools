import SwiftUI

@main
struct AlephToolsApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
        .defaultSize(width: 800, height: 560)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .help) {
                Button("Learning Center") {
                    openWindow(id: "learning-center")
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
            }
        }

        Window("Learning Center", id: "learning-center") {
            NavigationSplitView {
                LearningCenterView()
            } detail: {
                Text("Select a topic")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .defaultSize(width: 740, height: 580)

        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let serviceProvider = ServiceProvider()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = serviceProvider
        NSUpdateDynamicServices()
    }
}
