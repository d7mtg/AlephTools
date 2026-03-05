import SwiftUI
#if os(iOS)
import UIKit
#else
import ServiceManagement
#endif

// MARK: - Welcome Feature Model

struct WelcomeFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
}

// MARK: - Platform Feature Sets

enum WelcomeFeatures {
    #if os(iOS)
    static let current: [WelcomeFeature] = [
        .init(icon: "keyboard", title: "Paleo-Hebrew Keyboard", description: "Type in ancient script from any app with the system keyboard extension"),
        .init(icon: "wand.and.stars", title: "Add Niqqud", description: "On-device AI vowel diacritization powered by Nakdimon, no internet needed"),
        .init(icon: "arrow.left.arrow.right", title: "8 Transformations", description: "Hebrew / English keyboard, Paleo-Hebrew, Gematria, Reverse, and more"),
        .init(icon: "hand.raised", title: "Handoff", description: "Start on iPhone, continue on Mac. Your text follows you across devices"),
    ]
    #else
    static let current: [WelcomeFeature] = [
        .init(icon: "wand.and.stars", title: "Add Niqqud", description: "On-device AI vowel diacritization powered by Nakdimon, no internet needed"),
        .init(icon: "scroll", title: "Paleo-Hebrew", description: "Convert between modern square script and ancient Paleo-Hebrew with cleaning"),
        .init(icon: "contextualmenu.and.cursorarrow", title: "System Services", description: "Transform text from any app via the right-click Services menu"),
        .init(icon: "menubar.rectangle", title: "Menu Bar & Shortcuts", description: "Quick access from the menu bar, use \u{2318}1\u{2013}8 to switch transforms"),
    ]
    #endif

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0"
    }
}

// MARK: - Notification for debug trigger

extension Notification.Name {
    static let showWelcomeSheet = Notification.Name("showWelcomeSheet")
}

#if os(iOS)
extension Bundle {
    var icon: UIImage? {
        guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let files = primary["CFBundleIconFiles"] as? [String],
              let name = files.last else { return nil }
        return UIImage(named: name)
    }
}
#endif

// MARK: - Welcome Sheet

struct WelcomeSheet: View {
    var onContinue: () -> Void

    @State private var currentStep = 0
    private let totalSteps = 2

    #if os(iOS)
    @AppStorage("hasCompletedKeyboardSetup") private var hasCompletedSetup = false
    @State private var isKeyboardInstalled = false
    @State private var checkTimer: Timer?
    private let keyboardBundleID = "com.alephtools.AlephToolsiOS.AlephKeyboard"
    #endif

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if currentStep == 0 { welcomePage.transition(.welcomeStep) }
                if currentStep == 1 { finalPage.transition(.welcomeStep) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            #if os(iOS)
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        if value.translation.width < -50, currentStep < totalSteps - 1 { advance() }
                        else if value.translation.width > 50, currentStep > 0 { goBack() }
                    }
            )
            #endif

            bottomBar
        }
        #if os(iOS)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            checkKeyboardStatus()
            startPolling()
        }
        .onDisappear { stopPolling() }
        .onChange(of: isKeyboardInstalled) { _, installed in
            if installed { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        }
        #else
        .frame(width: 460, height: 480)
        #endif
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i == currentStep ? Color.accentColor : Color.primary.opacity(0.2))
                        .frame(width: i == currentStep ? 18 : 8, height: 8)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentStep)

            Spacer()

            #if os(iOS)
            iOSBottomButtons
            #else
            macOSBottomButton
            #endif
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
    }

    #if os(macOS)
    private var macOSBottomButton: some View {
        Button {
            if currentStep < totalSteps - 1 {
                advance()
            } else {
                onContinue()
            }
        } label: {
            Text(currentStep < totalSteps - 1 ? "Continue" : "Get Started")
                .contentTransition(.interpolate)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .keyboardShortcut(.defaultAction)
        .animation(.easeInOut(duration: 0.2), value: currentStep)
    }
    #endif

    #if os(iOS)
    @ViewBuilder
    private var iOSBottomButtons: some View {
        let onKeyboardStep = currentStep == 1 && !isKeyboardInstalled

        if onKeyboardStep {
            Button {
                hasCompletedSetup = true
                onContinue()
            } label: {
                Text("Skip")
                    .contentTransition(.interpolate)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .transition(.blurReplace)
        }

        Button {
            if currentStep == 0 {
                advance()
            } else if !isKeyboardInstalled {
                openKeyboardSettings()
            } else {
                onContinue()
            }
        } label: {
            Group {
                if currentStep == 0 {
                    Text("Continue")
                } else if !isKeyboardInstalled {
                    Label(String(localized: "Open Settings"), systemImage: "arrow.up.forward.app")
                } else {
                    Text("Get Started")
                }
            }
            .contentTransition(.interpolate)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
    #endif

    // MARK: - Step 1: Welcome + What's New

    private var welcomePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            #if os(iOS)
            Group {
                if let icon = UIImage(named: "AppIcon60x60") ?? UIImage(named: "AppIcon") ?? Bundle.main.icon {
                    Image(uiImage: icon)
                        .resizable()
                } else {
                    Image(systemName: "app.fill")
                        .resizable()
                        .foregroundStyle(.accent)
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .padding(.top, 32)
            #else
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
                .padding(.top, 32)
            #endif

            Text("Welcome to Aleph Tools")
                .font(.title.bold())
                .padding(.top, 16)

            Text("What's new in version \(WelcomeFeatures.appVersion)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
                .padding(.bottom, 24)

            VStack(alignment: .leading, spacing: 18) {
                ForEach(WelcomeFeatures.current) { feature in
                    featureRow(feature)
                }
            }

            Spacer(minLength: 16)
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Step 2

    @ViewBuilder
    private var finalPage: some View {
        #if os(iOS)
        KeyboardSetupContent(isKeyboardInstalled: isKeyboardInstalled)
        #else
        QuickSettingsPage(onFinish: onContinue)
        #endif
    }

    // MARK: - Feature Row

    private func featureRow(_ feature: WelcomeFeature) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: feature.icon)
                .font(.title3)
                .foregroundStyle(.accent)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.subheadline.weight(.semibold))
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func advance() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { currentStep += 1 }
    }

    private func goBack() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { currentStep -= 1 }
    }

    // MARK: - iOS Keyboard Helpers

    #if os(iOS)
    private func checkKeyboardStatus() {
        isKeyboardInstalled = UITextInputMode.activeInputModes.contains { mode in
            guard let id = mode.value(forKey: "identifier") as? String else { return false }
            return id.contains(keyboardBundleID)
        }
    }

    private func startPolling() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in checkKeyboardStatus() }
    }

    private func stopPolling() {
        checkTimer?.invalidate()
        checkTimer = nil
    }

    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }
    #endif
}

extension AnyTransition {
    static var welcomeStep: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}

// MARK: - iOS: Keyboard Setup Content (no buttons — bottom bar handles actions)

#if os(iOS)
private struct KeyboardSetupContent: View {
    let isKeyboardInstalled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Enable Keyboard")
                    .font(.title.bold())
                Text("Set up Paleo-Hebrew typing")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 28)
            .padding(.top, 32)

            Spacer()

            if isKeyboardInstalled {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.green)
                        .symbolEffect(.bounce, value: isKeyboardInstalled)
                    Text("Ready to go")
                        .font(.headline)
                    Text("Switch keyboards with the\nglobe key while typing.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .transition(.blurReplace)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    stepRow(number: 1, title: String(localized: "Open Keyboard Settings"), detail: String(localized: "Settings \u{203A} General \u{203A} Keyboard"))
                    stepConnector()
                    stepRow(number: 2, title: String(localized: "Add New Keyboard"), detail: String(localized: "Tap Keyboards, then Add New Keyboard..."))
                    stepConnector()
                    stepRow(number: 3, title: String(localized: "Choose Paleo-Hebrew"), detail: String(localized: "Find Aleph Tools in the list"))
                }
                .padding(.horizontal, 28)
                .transition(.blurReplace)
            }

            Spacer()
        }
    }

    private func stepRow(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(.accent).frame(width: 28, height: 28)
                Text("\(number)")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.top, 3)
        }
        .padding(.vertical, 5)
    }

    private func stepConnector() -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(.accent.opacity(0.2))
            .frame(width: 2, height: 16)
            .padding(.leading, 13)
    }
}
#endif

// MARK: - macOS: Quick Settings Page

#if os(macOS)
private struct QuickSettingsPage: View {
    var onFinish: () -> Void

    @AppStorage("appearanceOverride") private var appearanceOverride = "system"
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInMenuBar") private var showInMenuBar = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick Settings")
                    .font(.title.bold())
                Text("You can always change these later")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 32)

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Appearance")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    AppearancePicker(selection: $appearanceOverride)
                        .fixedSize()
                }

                VStack(alignment: .leading, spacing: 14) {
                    Toggle(String(localized: "Launch Aleph Tools at login"), isOn: $launchAtLogin)
                        .onChange(of: launchAtLogin) { _, newValue in
                            LaunchAtLoginManager.setEnabled(newValue)
                        }
                    Toggle(String(localized: "Show in menu bar"), isOn: $showInMenuBar)
                }
                .toggleStyle(.switch)
            }
            .padding(.top, 28)

            Spacer(minLength: 16)
        }
        .padding(.horizontal, 28)
    }
}
#endif

#Preview {
    WelcomeSheet(onContinue: {})
}
