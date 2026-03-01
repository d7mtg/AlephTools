import SwiftUI

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

                // MARK: - Learn
                Section {
                    NavigationLink {
                        LearningCenterView()
                    } label: {
                        Label("Learning Center", systemImage: "book")
                    }
                } header: {
                    Text("Learn")
                } footer: {
                    Text("History and background on Hebrew scripts, niqqud, gematria, and more.")
                }

                // MARK: - About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundStyle(.secondary)
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
                } header: {
                    Text("About")
                } footer: {
                    Text("Made by D7mtg with Claude Code")
                }
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
