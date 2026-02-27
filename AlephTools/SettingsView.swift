import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            ServicesSettingsTab()
                .tabItem {
                    Label("Services", systemImage: "gearshape.2")
                }
        }
        .frame(width: 480, height: 360)
    }
}

// MARK: - Services Tab

private struct ServicesSettingsTab: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Services")
                .font(.headline)

            Text("Aleph Tools registers system-wide Services that let you transform selected text in any app. Select text, then use the app menu or right-click to find them.")
                .font(.callout)
                .foregroundStyle(.secondary)

            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
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
                        }
                        .padding(.vertical, 2)
                        if t != TransformationType.allCases.last {
                            Divider()
                        }
                    }
                }
                .padding(4)
            }

            HStack(spacing: 4) {
                Text("To assign keyboard shortcuts, go to")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("System Settings \u{2192} Keyboard \u{2192} Shortcuts \u{2192} Services") {
                    openKeyboardShortcutSettings()
                }
                .buttonStyle(.link)
                .font(.callout)
            }

            Spacer()
        }
        .padding(20)
    }

    private func openKeyboardShortcutSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension")!)
    }
}
