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
    @AppStorage("languageOverride") private var languageOverride = "system"
    init() {
        let lang = UserDefaults.standard.string(forKey: "languageOverride") ?? "system"
        if lang != "system" {
            UserDefaults.standard.set([lang], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearanceOverride {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private var localeOverride: Locale? {
        switch languageOverride {
        case "en": return Locale(identifier: "en")
        case "he": return Locale(identifier: "he")
        case "yi": return Locale(identifier: "yi")
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            WelcomeGate {
                ContentView()
            }
            .preferredColorScheme(colorScheme)
            .optionalLocale(localeOverride)
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 800, height: 560)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandGroup(replacing: .undoRedo) {
                Button(String(localized: "Undo")) {
                    NSApp.sendAction(Selector(("undo:")), to: nil, from: nil)
                }
                .keyboardShortcut("z", modifiers: .command)

                Button(String(localized: "Redo")) {
                    NSApp.sendAction(Selector(("redo:")), to: nil, from: nil)
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
            }

            CommandGroup(replacing: .pasteboard) {
                Button(String(localized: "Cut")) {
                    NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("x", modifiers: .command)

                Button(String(localized: "Copy")) {
                    NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("c", modifiers: .command)

                Button(String(localized: "Paste")) {
                    NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("v", modifiers: .command)

                Button(String(localized: "Select All")) {
                    NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("a", modifiers: .command)

                Divider()

                Button {
                    guard let text = outputText, !text.isEmpty else { return }
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                } label: {
                    Label(String(localized: "Copy Output"), systemImage: "doc.on.doc")
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(outputText?.isEmpty ?? true)

                Button {
                    editorCommand?.setText("")
                } label: {
                    Label(String(localized: "Clear Input"), systemImage: "trash")
                }
                .keyboardShortcut(.delete, modifiers: .command)
                .disabled(inputText?.wrappedValue.isEmpty ?? true)
            }

            // Find menu
            CommandGroup(after: .textEditing) {
                Button {
                    performFindAction(tag: 1)
                } label: {
                    Label(String(localized: "Find\u{2026}"), systemImage: "magnifyingglass")
                }
                .keyboardShortcut("f", modifiers: .command)

                Button {
                    performFindAction(tag: 12)
                } label: {
                    Label(String(localized: "Find and Replace\u{2026}"), systemImage: "arrow.2.squarepath")
                }
                .keyboardShortcut("f", modifiers: [.command, .option])

                Button {
                    performFindAction(tag: 2)
                } label: {
                    Label(String(localized: "Find Next"), systemImage: "chevron.down")
                }
                .keyboardShortcut("g", modifiers: .command)

                Button {
                    performFindAction(tag: 3)
                } label: {
                    Label(String(localized: "Find Previous"), systemImage: "chevron.up")
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])

                Button {
                    performFindAction(tag: 7)
                } label: {
                    Label(String(localized: "Use Selection for Find"), systemImage: "text.cursor")
                }
                .keyboardShortcut("e", modifiers: .command)
            }

            // View menu — font size
            CommandGroup(after: .toolbar) {
                Button {
                    let current = editorFontSize?.wrappedValue ?? 13
                    editorFontSize?.wrappedValue = min(current + 1, 32)
                } label: {
                    Label(String(localized: "Bigger"), systemImage: "plus.magnifyingglass")
                }
                .keyboardShortcut("+", modifiers: .command)

                Button {
                    let current = editorFontSize?.wrappedValue ?? 13
                    editorFontSize?.wrappedValue = max(current - 1, 9)
                } label: {
                    Label(String(localized: "Smaller"), systemImage: "minus.magnifyingglass")
                }
                .keyboardShortcut("-", modifiers: .command)

                Button {
                    editorFontSize?.wrappedValue = 13
                } label: {
                    Label(String(localized: "Actual Size"), systemImage: "1.magnifyingglass")
                }
                .keyboardShortcut("0", modifiers: .command)
            }

            CommandGroup(replacing: .printItem) {
                Button {
                    printHandle?.printAction?()
                } label: {
                    Label(String(localized: "Print Output\u{2026}"), systemImage: "printer")
                }
                .keyboardShortcut("p", modifiers: .command)
                .disabled(printHandle?.printAction == nil || (outputText?.isEmpty ?? true))
            }

            CommandMenu(String(localized: "Transform")) {
                ForEach(Array(TransformationType.allCases.enumerated()), id: \.element.id) { index, transform in
                    Button {
                        selectedTransform?.wrappedValue = transform
                    } label: {
                        Label(transform.localizedName, systemImage: transform.icon)
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }

                Divider()

                Toggle(String(localized: "Keep Punctuation"), isOn: Binding(
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
                    Label(String(localized: "Learning Center"), systemImage: "book")
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
            }
        }

        Window(String(localized: "Learning Center"), id: "learning-center") {
            NavigationSplitView {
                LearningCenterView()
            } detail: {
                Text("Select a topic", comment: "Learning center placeholder")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .optionalLocale(localeOverride)
        }
        .defaultSize(width: 740, height: 580)

        Settings {
            SettingsView()
                .preferredColorScheme(colorScheme)
                .optionalLocale(localeOverride)
        }

        MenuBarExtra("Aleph Tools", image: "MenuBarIcon", isInserted: $showInMenuBar) {
            MenuBarContentView()
                .optionalLocale(localeOverride)
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

            Picker(String(localized: "Transform"), selection: $selectedTransform) {
                ForEach(TransformationType.allCases) { t in
                    Text(t.localizedName).tag(t)
                }
            }
            .labelsHidden()

            if selectedTransform.supportsPunctuationToggle {
                Toggle(String(localized: "Keep Punctuation"), isOn: $keepPunctuation)
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
            }

            TextField(String(localized: "Input text\u{2026}"), text: $inputText)
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

// MARK: - Locale Override Helper

// MARK: - Welcome Gate

struct WelcomeGate<Content: View>: View {
    @ViewBuilder let content: Content
    @AppStorage("hasSeenWelcome_2.0") private var hasSeenWelcome = false
    @State private var showWelcome = false

    var body: some View {
        ZStack {
            content
        }
        .onAppear {
            showWelcome = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showWelcomeSheet)) { _ in
            showWelcome = true
        }
        .sheet(isPresented: $showWelcome) {
            WelcomeSheet(onContinue: {
                showWelcome = false
            })
        }
    }
}

private extension View {
    @ViewBuilder
    func optionalLocale(_ locale: Locale?) -> some View {
        if let locale {
            self.environment(\.locale, locale)
                .environment(\.layoutDirection, locale.language.characterDirection == .rightToLeft ? .rightToLeft : .leftToRight)
        } else {
            self
        }
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
