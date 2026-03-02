import SwiftUI
import AppIntents

struct iOSSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultTransform") private var defaultTransformRaw = TransformationType.hebrewKeyboard.rawValue
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
                    Picker("Default Transformation", selection: $defaultTransformRaw) {
                        ForEach(TransformationType.allCases) { t in
                            Label(t.rawValue, systemImage: t.icon)
                                .tag(t.rawValue)
                        }
                    }
                } header: {
                    Text("General")
                } footer: {
                    Text("Used when opening the app.")
                }

                // MARK: - Keyboard
                Section {
                    Button {
                        showKeyboardSetup = true
                    } label: {
                        HStack {
                            Label("Paleo-Hebrew Keyboard", systemImage: "keyboard")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("Keyboard")
                } footer: {
                    Text("Set up the Paleo-Hebrew keyboard extension.")
                }

                // MARK: - About
                Section {
                    NavigationLink {
                        LearningCenterView()
                    } label: {
                        Label("Learning Center", systemImage: "book")
                    }

                    Link(destination: URL(string: "https://github.com/d7mtg/AlephTools")!) {
                        HStack {
                            Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Link(destination: URL(string: "https://github.com/d7mtg/AlephTools/issues")!) {
                        HStack {
                            Label("Report Issue", systemImage: "ladybug")
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
                        Text("Version")
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                } footer: {
                    Text("Made by D7mtg with Claude Code")
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
                    Text("Open-Source Libraries")
                } footer: {
                    Text("Hebrew diacritization model by Elazar Gershuni \u{00B7} MIT License")
                }

                // MARK: - Shortcuts
                Section {
                    ShortcutsLink()
                        .shortcutsLinkStyle(.automaticOutline)
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showKeyboardSetup) {
                KeyboardSetupView()
            }
        }
    }
}
