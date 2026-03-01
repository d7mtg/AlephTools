import SwiftUI
import UIKit

struct KeyboardSetupView: View {
    @AppStorage("hasCompletedKeyboardSetup") private var hasCompletedSetup = false
    @State private var isKeyboardInstalled = false
    @State private var checkTimer: Timer?
    @State private var appeared = false
    @Environment(\.dismiss) private var dismiss

    private let keyboardBundleID = "com.alephtools.AlephToolsiOS.AlephKeyboard"

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // MARK: - Hero

            VStack(spacing: 24) {
                Image("AppIcon")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .accent.opacity(0.2), radius: 16, y: 8)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.85)

                VStack(spacing: 10) {
                    Text("Paleo-Hebrew\nKeyboard")
                        .font(.largeTitle.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text("Type in ancient Hebrew script\nanywhere on your device.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
            }

            Spacer()

            // MARK: - Content

            if isKeyboardInstalled {
                successView
                    .transition(.blurReplace)
            } else {
                stepsView
                    .transition(.blurReplace)
            }

            Spacer()

            // MARK: - Actions

            VStack(spacing: 14) {
                if isKeyboardInstalled {
                    Button {
                        hasCompletedSetup = true
                        dismiss()
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accent)
                } else {
                    Button {
                        openKeyboardSettings()
                    } label: {
                        Label("Open Settings", systemImage: "arrow.up.forward.app")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accent)

                    Button("Skip for now") {
                        hasCompletedSetup = true
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .animation(.smooth, value: isKeyboardInstalled)
        }
        .background(Color(.systemBackground))
        .onAppear {
            checkKeyboardStatus()
            startPolling()
            withAnimation(.smooth(duration: 0.6).delay(0.1)) {
                appeared = true
            }
        }
        .onDisappear {
            stopPolling()
        }
        .onChange(of: isKeyboardInstalled) { _, installed in
            if installed {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: isKeyboardInstalled)

            Text("Ready to go")
                .font(.title3.weight(.semibold))

            Text("Switch keyboards with the\nglobe key while typing.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Steps

    private var stepsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepRow(
                number: 1,
                title: "Open Keyboard Settings",
                detail: "Go to Settings \u{203A} General \u{203A} Keyboard"
            )
            stepConnector()
            stepRow(
                number: 2,
                title: "Add New Keyboard",
                detail: "Tap Keyboards, then Add New Keyboard..."
            )
            stepConnector()
            stepRow(
                number: 3,
                title: "Choose Paleo-Hebrew",
                detail: "Find Aleph Tools in the list and tap it"
            )
        }
        .padding(.horizontal, 32)
    }

    private func stepRow(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(.accent)
                    .frame(width: 32, height: 32)
                Text("\(number)")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }

    private func stepConnector() -> some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(.accent.opacity(0.25))
            .frame(width: 2.5, height: 24)
            .padding(.leading, 14.75)
    }

    // MARK: - Detection

    private func checkKeyboardStatus() {
        let inputModes = UITextInputMode.activeInputModes
        isKeyboardInstalled = inputModes.contains { mode in
            guard let id = mode.value(forKey: "identifier") as? String else { return false }
            return id.contains(keyboardBundleID)
        }
    }

    private func startPolling() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            checkKeyboardStatus()
        }
    }

    private func stopPolling() {
        checkTimer?.invalidate()
        checkTimer = nil
    }

    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
