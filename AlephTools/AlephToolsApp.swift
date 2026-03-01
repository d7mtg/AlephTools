import SwiftUI

@main
struct AlephToolsApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @Environment(\.openWindow) private var openWindow
    @FocusedValue(\.selectedTransform) private var selectedTransform
    @FocusedValue(\.inputText) private var inputText
    @FocusedValue(\.outputText) private var outputText
    @FocusedValue(\.keepPunctuation) private var keepPunctuation

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 800, height: 560)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandGroup(after: .pasteboard) {
                Divider()
                Button("Copy Output") {
                    guard let text = outputText, !text.isEmpty else { return }
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(outputText?.isEmpty ?? true)

                Button("Clear Input") {
                    inputText?.wrappedValue = ""
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(inputText?.wrappedValue.isEmpty ?? true)
            }

            CommandMenu("Transform") {
                ForEach(Array(TransformationType.allCases.enumerated()), id: \.element.id) { index, transform in
                    Button(transform.rawValue) {
                        selectedTransform?.wrappedValue = transform
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }

                Divider()

                Toggle("Keep Punctuation", isOn: Binding(
                    get: { keepPunctuation?.wrappedValue ?? false },
                    set: { keepPunctuation?.wrappedValue = $0 }
                ))
                .keyboardShortcut("p", modifiers: .command)
                .disabled(keepPunctuation == nil)
            }

            CommandGroup(replacing: .windowList) {
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
