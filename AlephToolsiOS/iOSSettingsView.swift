import SwiftUI
import AppIntents

struct iOSSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultTransform") private var defaultTransformRaw = TransformationType.hebrewKeyboard.rawValue
    @AppStorage("languageOverride") private var languageOverride = "system"
    @State private var showKeyboardSetup = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - General
                Section {
                    Picker(String(localized: "Default Transformation"), selection: $defaultTransformRaw) {
                        ForEach(TransformationType.allCases) { t in
                            Label(t.localizedName, systemImage: t.icon)
                                .tag(t.rawValue)
                        }
                    }
                    Picker(String(localized: "Language"), selection: $languageOverride) {
                        Text(String(localized: "System")).tag("system")
                        Text("English").tag("en")
                        Text("עברית").tag("he")
                        Text("אידיש").tag("yi")
                    }
                    .onChange(of: languageOverride) { _, newValue in
                        if newValue == "system" {
                            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
                        } else {
                            UserDefaults.standard.set([newValue], forKey: "AppleLanguages")
                        }
                    }
                } header: {
                    Text("General", comment: "Settings section header")
                } footer: {
                    Text("Used when opening the app.", comment: "Default transformation footer")
                }

                // MARK: - Keyboard
                Section {
                    Button {
                        showKeyboardSetup = true
                    } label: {
                        HStack {
                            Label(String(localized: "Paleo-Hebrew Keyboard"), systemImage: "keyboard")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("Keyboard", comment: "Settings section header")
                } footer: {
                    Text("Set up the Paleo-Hebrew keyboard extension.", comment: "Keyboard section footer")
                }

                // MARK: - About
                Section {
                    NavigationLink {
                        LearningCenterView()
                    } label: {
                        Label(String(localized: "Learning Center"), systemImage: "book")
                    }

                    Link(destination: URL(string: "https://github.com/d7mtg/AlephTools")!) {
                        HStack {
                            Label(String(localized: "Source Code"), systemImage: "chevron.left.forwardslash.chevron.right")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Link(destination: URL(string: "https://github.com/d7mtg/AlephTools/issues")!) {
                        HStack {
                            Label(String(localized: "Report Issue"), systemImage: "ladybug")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Link(destination: URL(string: "https://d7mtg.com")!) {
                        HStack {
                            Label("D7mtg", systemImage: "person")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    HStack {
                        Text("Version", comment: "Settings version label")
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About", comment: "Settings section header")
                } footer: {
                    Text("Made by D7mtg with Claude Code", comment: "Settings footer attribution")
                }

                // MARK: - Open-Source Libraries
                Section {
                    Link(destination: URL(string: "https://github.com/elazarg/nakdimon")!) {
                        HStack {
                            Label("Nakdimon", systemImage: "wand.and.stars")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("Open-Source Libraries", comment: "Settings section header")
                } footer: {
                    Text("Hebrew diacritization model by Elazar Gershuni \u{00B7} MIT License", comment: "Nakdimon library description")
                }

                // MARK: - Shortcuts
                Section {
                    ShortcutsLink()
                        .shortcutsLinkStyle(.automaticOutline)
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle(String(localized: "Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Done")) { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showKeyboardSetup) {
                KeyboardSetupView()
            }
        }
    }
}
