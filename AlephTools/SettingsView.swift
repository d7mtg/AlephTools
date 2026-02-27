import SwiftUI
import Carbon

struct SettingsView: View {
    var body: some View {
        TabView {
            ShortcutsSettingsTab()
                .tabItem {
                    Label("Shortcuts", systemImage: "command")
                }
        }
        .frame(width: 520, height: 440)
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

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Shortcuts work system-wide when Aleph Tools is running. They copy the selected text, transform it, and paste it back.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
