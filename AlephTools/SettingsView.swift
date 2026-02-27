import SwiftUI
import Carbon
import ServiceManagement

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            ShortcutsSettingsTab()
                .tabItem {
                    Label("Shortcuts", systemImage: "command")
                }
            ServicesSettingsTab()
                .tabItem {
                    Label("Services", systemImage: "square.and.arrow.up.on.square")
                }
            AboutSettingsTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 520, height: 440)
    }
}

// MARK: - General Tab

private struct GeneralSettingsTab: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("defaultTransform") private var defaultTransform = TransformationType.hebrewKeyboard.rawValue
    @AppStorage("showInMenuBar") private var showInMenuBar = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General")
                .font(.headline)

            VStack(alignment: .leading, spacing: 16) {
                Toggle("Launch Aleph Tools at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        LaunchAtLoginManager.setEnabled(newValue)
                    }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Picker("Default transformation:", selection: $defaultTransform) {
                        ForEach(TransformationType.allCases) { t in
                            Text(t.rawValue).tag(t.rawValue)
                        }
                    }
                    .fixedSize()

                    Text("Used when opening the app and for new windows.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Show in menu bar", isOn: $showInMenuBar)

                    Text("Quick access to transformations from the menu bar. (Coming soon)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .disabled(true)
                .opacity(0.5)
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.separator, lineWidth: 0.5)
            )

            Spacer()
        }
        .padding(20)
    }
}

// MARK: - Launch at Login

enum LaunchAtLoginManager {
    static func setEnabled(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            print("Launch at login error: \(error)")
        }
    }
}

// MARK: - Shortcuts Tab

private struct ShortcutsSettingsTab: View {
    @StateObject private var manager = GlobalShortcutManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Global Shortcuts")
                .font(.headline)

            Text("Assign keyboard shortcuts to transform selected text anywhere on your Mac. The app must be running.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(TransformationType.allCases) { t in
                        ShortcutRow(transform: t, manager: manager)
                        if t != TransformationType.allCases.last {
                            Divider()
                                .padding(.leading, 36)
                        }
                    }
                }
                .padding(8)
                .background(.background, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.separator, lineWidth: 0.5)
                )
            }

            if !AXIsProcessTrusted() {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accessibility Access Required")
                            .font(.callout.weight(.medium))
                        Text("Global shortcuts need Accessibility permission to simulate copy/paste in other apps.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Open Settings") {
                        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
                        AXIsProcessTrustedWithOptions(options)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(10)
                .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Accessibility access granted. Shortcuts work system-wide.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
    }
}

// MARK: - Shortcut Row

private struct ShortcutRow: View {
    let transform: TransformationType
    @ObservedObject var manager: GlobalShortcutManager
    @State private var isRecording = false
    @State private var localMonitor: Any?

    private var shortcut: StoredShortcut? {
        manager.shortcuts[transform]
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: transform.icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 1) {
                Text(transform.rawValue)
                    .font(.body.weight(.medium))
                Text(transform.subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if isRecording {
                Text("Type shortcut\u{2026}")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.orange, in: RoundedRectangle(cornerRadius: 5))
                    .onAppear { startLocalMonitor() }
                    .onDisappear { stopLocalMonitor() }

                Button("Cancel") {
                    stopRecording()
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.secondary)
            } else if let shortcut {
                HStack(spacing: 4) {
                    Text(shortcut.displayString)
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))

                    Button {
                        manager.removeShortcut(for: transform)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .onTapGesture {
                    isRecording = true
                }
            } else {
                Button("Record Shortcut") {
                    isRecording = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }

    private func startLocalMonitor() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            // Escape cancels
            if event.keyCode == 53 {
                stopRecording()
                return nil
            }

            // Require at least one modifier (not just shift)
            guard mods.contains(.command) || mods.contains(.control) || mods.contains(.option) else {
                return event
            }

            let char = event.charactersIgnoringModifiers ?? ""
            guard !char.isEmpty else { return event }

            let recorded = StoredShortcut(
                keyCode: UInt32(event.keyCode),
                character: char,
                modifiers: mods.rawValue
            )
            manager.setShortcut(recorded, for: transform)
            stopRecording()
            return nil // consume the event
        }
    }

    private func stopRecording() {
        isRecording = false
        stopLocalMonitor()
    }

    private func stopLocalMonitor() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        localMonitor = nil
    }
}

// MARK: - Services Tab

private struct ServicesSettingsTab: View {
    @AppStorage("enabledServices") private var enabledServicesData = Data()

    private var enabledServices: Set<String> {
        get {
            (try? JSONDecoder().decode(Set<String>.self, from: enabledServicesData))
                ?? Set(TransformationType.allCases.map(\.rawValue))
        }
    }

    private func setEnabled(_ transform: TransformationType, enabled: Bool) {
        var current = enabledServices
        if enabled {
            current.insert(transform.rawValue)
        } else {
            current.remove(transform.rawValue)
        }
        enabledServicesData = (try? JSONEncoder().encode(current)) ?? Data()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Services Menu")
                .font(.headline)

            Text("Aleph Tools registers transformations in the system Services menu. Select text in any app, then use the app menu \u{2192} Services \u{2192} Aleph Tools.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 0) {
                ForEach(TransformationType.allCases) { t in
                    HStack(spacing: 10) {
                        Image(systemName: t.icon)
                            .frame(width: 20)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(t.rawValue)
                                .font(.body.weight(.medium))
                            Text(t.subtitle)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { enabledServices.contains(t.rawValue) },
                            set: { setEnabled(t, enabled: $0) }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)

                    if t != TransformationType.allCases.last {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .padding(8)
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.separator, lineWidth: 0.5)
            )

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Services are registered when the app launches. Restart may be needed after changes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(20)
    }
}

// MARK: - About Tab

private struct AboutSettingsTab: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            VStack(spacing: 4) {
                Text("Aleph Tools")
                    .font(.title2.weight(.semibold))

                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Text("Hebrew text transformation utility for macOS.\nConvert keyboard layouts, strip niqqud, transliterate\nbetween modern and paleo-Hebrew scripts, and more.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 16) {
                Link(destination: URL(string: "https://github.com/d7mtg/AlephTools")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                        Text("Source Code")
                    }
                }
                .buttonStyle(.link)

                Link(destination: URL(string: "https://github.com/d7mtg/AlephTools/issues")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "ladybug")
                        Text("Report Issue")
                    }
                }
                .buttonStyle(.link)
            }

            Spacer()

            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Text("Made by")
                        .foregroundStyle(.tertiary)
                    Link("D7mtg", destination: URL(string: "https://d7mtg.com")!)
                        .buttonStyle(.link)
                    Text("with")
                        .foregroundStyle(.tertiary)
                    Link("Claude Code", destination: URL(string: "https://claude.ai/claude-code")!)
                        .buttonStyle(.link)
                }
                .font(.caption)

                Text("\u{00A9} 2025 D7mtg")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
    }
}

// MARK: - Stored Shortcut

struct StoredShortcut: Codable, Equatable {
    let keyCode: UInt32
    let character: String
    let modifiers: UInt

    var displayString: String {
        var parts: [String] = []
        let mods = NSEvent.ModifierFlags(rawValue: modifiers)
        if mods.contains(.control) { parts.append("\u{2303}") }
        if mods.contains(.option) { parts.append("\u{2325}") }
        if mods.contains(.shift) { parts.append("\u{21E7}") }
        if mods.contains(.command) { parts.append("\u{2318}") }
        parts.append(character.uppercased())
        return parts.joined()
    }
}

// MARK: - Global Shortcut Manager

class GlobalShortcutManager: ObservableObject {
    static let shared = GlobalShortcutManager()

    @Published var shortcuts: [TransformationType: StoredShortcut] = [:]
    private var monitor: Any?

    private init() {
        loadShortcuts()
        startMonitoring()
    }

    func setShortcut(_ shortcut: StoredShortcut, for transform: TransformationType) {
        shortcuts[transform] = shortcut
        saveShortcuts()
        restartMonitoring()
    }

    func removeShortcut(for transform: TransformationType) {
        shortcuts.removeValue(forKey: transform)
        saveShortcuts()
        restartMonitoring()
    }

    private func saveShortcuts() {
        let data = shortcuts.map { (key: $0.key.rawValue, value: $0.value) }
        if let encoded = try? JSONEncoder().encode(Dictionary(uniqueKeysWithValues: data.map { ($0.key, $0.value) })) {
            UserDefaults.standard.set(encoded, forKey: "globalShortcuts")
        }
    }

    private func loadShortcuts() {
        guard let data = UserDefaults.standard.data(forKey: "globalShortcuts"),
              let decoded = try? JSONDecoder().decode([String: StoredShortcut].self, from: data) else { return }
        for (key, value) in decoded {
            if let transform = TransformationType.allCases.first(where: { $0.rawValue == key }) {
                shortcuts[transform] = value
            }
        }
    }

    private func restartMonitoring() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        startMonitoring()
    }

    private func startMonitoring() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleGlobalKeyEvent(event)
        }
    }

    private func handleGlobalKeyEvent(_ event: NSEvent) {
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
        let char = event.charactersIgnoringModifiers?.lowercased() ?? ""

        for (transform, shortcut) in shortcuts {
            let storedMods = NSEvent.ModifierFlags(rawValue: shortcut.modifiers)
                .intersection(.deviceIndependentFlagsMask).rawValue
            if storedMods == mods && shortcut.character.lowercased() == char {
                performSystemTransform(transform)
                return
            }
        }
    }

    private func performSystemTransform(_ transform: TransformationType) {
        DispatchQueue.main.async {
            // Copy current selection
            let copyEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0x08, keyDown: true)! // 'c'
            copyEvent.flags = .maskCommand
            copyEvent.post(tap: .cghidEventTap)
            let copyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x08, keyDown: false)!
            copyUp.flags = .maskCommand
            copyUp.post(tap: .cghidEventTap)

            // Wait for clipboard to update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard let text = NSPasteboard.general.string(forType: .string) else { return }
                let result = TransformationEngine.transform(text, mode: transform, keepPunctuation: false)

                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(result, forType: .string)

                // Paste back
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    let pasteEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: true)! // 'v'
                    pasteEvent.flags = .maskCommand
                    pasteEvent.post(tap: .cghidEventTap)
                    let pasteUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: false)!
                    pasteUp.flags = .maskCommand
                    pasteUp.post(tap: .cghidEventTap)
                }
            }
        }
    }
}
