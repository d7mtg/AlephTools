import SwiftUI

@main
struct AlephToolsApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @Environment(\.openWindow) private var openWindow
    @FocusedValue(\.selectedTransform) private var selectedTransform
    @FocusedValue(\.inputText) private var inputText
    @FocusedValue(\.outputText) private var outputText
    @FocusedValue(\.keepPunctuation) private var keepPunctuation
    @FocusedValue(\.editorCommand) private var editorCommand
    @FocusedValue(\.printHandle) private var printHandle
    @FocusedValue(\.editorFontSize) private var editorFontSize
    @AppStorage("appearanceOverride") private var appearanceOverride = "system"
    @AppStorage("showInMenuBar") private var showInMenuBar = false

    private var colorScheme: ColorScheme? {
        switch appearanceOverride {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme)
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 800, height: 560)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandGroup(replacing: .undoRedo) {
                Button("Undo") {
                    NSApp.sendAction(Selector(("undo:")), to: nil, from: nil)
                }
                .keyboardShortcut("z", modifiers: .command)

                Button("Redo") {
                    NSApp.sendAction(Selector(("redo:")), to: nil, from: nil)
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
            }

            CommandGroup(replacing: .pasteboard) {
                Button("Cut") {
                    NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("x", modifiers: .command)

                Button("Copy") {
                    NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("c", modifiers: .command)

                Button("Paste") {
                    NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("v", modifiers: .command)

                Button("Select All") {
                    NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("a", modifiers: .command)

                Divider()

                Button {
                    guard let text = outputText, !text.isEmpty else { return }
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                } label: {
                    Label("Copy Output", systemImage: "doc.on.doc")
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(outputText?.isEmpty ?? true)

                Button {
                    editorCommand?.setText("")
                } label: {
                    Label("Clear Input", systemImage: "trash")
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(inputText?.wrappedValue.isEmpty ?? true)
            }

            // Find menu
            CommandGroup(after: .textEditing) {
                Button {
                    performFindAction(tag: 1)
                } label: {
                    Label("Find\u{2026}", systemImage: "magnifyingglass")
                }
                .keyboardShortcut("f", modifiers: .command)

                Button {
                    performFindAction(tag: 12)
                } label: {
                    Label("Find and Replace\u{2026}", systemImage: "arrow.2.squarepath")
                }
                .keyboardShortcut("f", modifiers: [.command, .option])

                Button {
                    performFindAction(tag: 2)
                } label: {
                    Label("Find Next", systemImage: "chevron.down")
                }
                .keyboardShortcut("g", modifiers: .command)

                Button {
                    performFindAction(tag: 3)
                } label: {
                    Label("Find Previous", systemImage: "chevron.up")
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])

                Button {
                    performFindAction(tag: 7)
                } label: {
                    Label("Use Selection for Find", systemImage: "text.cursor")
                }
                .keyboardShortcut("e", modifiers: .command)
            }

            // View menu — font size
            CommandGroup(after: .toolbar) {
                Button {
                    let current = editorFontSize?.wrappedValue ?? 13
                    editorFontSize?.wrappedValue = min(current + 1, 32)
                } label: {
                    Label("Bigger", systemImage: "plus.magnifyingglass")
                }
                .keyboardShortcut("+", modifiers: .command)

                Button {
                    let current = editorFontSize?.wrappedValue ?? 13
                    editorFontSize?.wrappedValue = max(current - 1, 9)
                } label: {
                    Label("Smaller", systemImage: "minus.magnifyingglass")
                }
                .keyboardShortcut("-", modifiers: .command)

                Button {
                    editorFontSize?.wrappedValue = 13
                } label: {
                    Label("Actual Size", systemImage: "1.magnifyingglass")
                }
                .keyboardShortcut("0", modifiers: .command)
            }

            CommandGroup(replacing: .printItem) {
                Button {
                    printHandle?.printAction?()
                } label: {
                    Label("Print Output\u{2026}", systemImage: "printer")
                }
                .keyboardShortcut("p", modifiers: .command)
                .disabled(printHandle?.printAction == nil || (outputText?.isEmpty ?? true))
            }

            CommandMenu("Transform") {
                ForEach(Array(TransformationType.allCases.enumerated()), id: \.element.id) { index, transform in
                    Button {
                        selectedTransform?.wrappedValue = transform
                    } label: {
                        Label(transform.rawValue, systemImage: transform.icon)
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }

                Divider()

                Toggle("Keep Punctuation", isOn: Binding(
                    get: { keepPunctuation?.wrappedValue ?? false },
                    set: { keepPunctuation?.wrappedValue = $0 }
                ))
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(keepPunctuation == nil)
            }

            CommandGroup(replacing: .windowList) {
                Button {
                    openWindow(id: "learning-center")
                } label: {
                    Label("Learning Center", systemImage: "book")
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
                .preferredColorScheme(colorScheme)
        }

        MenuBarExtra("Aleph Tools", image: "MenuBarIcon", isInserted: $showInMenuBar) {
            MenuBarContentView()
        }
        .menuBarExtraStyle(.window)
    }

    private func performFindAction(tag: Int) {
        // Create a menu item with the correct tag for performFindPanelAction
        guard let responder = NSApp.keyWindow?.firstResponder else { return }
        let item = NSMenuItem()
        item.tag = tag
        if responder.responds(to: #selector(NSTextView.performFindPanelAction(_:))) {
            responder.perform(#selector(NSTextView.performFindPanelAction(_:)), with: item)
        }
    }
}

// MARK: - Menu Bar Content

struct MenuBarContentView: View {
    @State private var inputText = ""
    @State private var selectedTransform: TransformationType = .hebrewKeyboard
    @State private var keepPunctuation = false
    @State private var showCopied = false

    private var outputText: String {
        guard !inputText.isEmpty else { return "" }
        return TransformationEngine.transform(inputText, mode: selectedTransform, keepPunctuation: keepPunctuation)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Aleph Tools")
                    .font(.headline)
                Spacer()
            }

            Picker("Transform", selection: $selectedTransform) {
                ForEach(TransformationType.allCases) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .labelsHidden()

            if selectedTransform.supportsPunctuationToggle {
                Toggle("Keep Punctuation", isOn: $keepPunctuation)
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
            }

            TextField("Input text\u{2026}", text: $inputText)
                .textFieldStyle(.roundedBorder)

            if !outputText.isEmpty {
                GroupBox {
                    HStack {
                        Text(outputText)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(outputText, forType: .string)
                            showCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                showCopied = false
                            }
                        } label: {
                            Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 280)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let serviceProvider = ServiceProvider()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = serviceProvider
        NSUpdateDynamicServices()

        // Register App Shortcuts with the system
        AlephToolsShortcuts.updateAppShortcutParameters()
    }
}
