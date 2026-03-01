import SwiftUI
import UIKit

struct KeyboardSetupView: View {
    @AppStorage("hasCompletedKeyboardSetup") private var hasCompletedSetup = false
    @State private var isKeyboardInstalled = false
    @State private var checkTimer: Timer?
    @Environment(\.dismiss) private var dismiss

    private let keyboardBundleID = "com.alephtools.AlephToolsiOS.AlephKeyboard"

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Text("\u{10900}")
                            .font(.system(size: 72))
                            .padding(.top, 40)

                        Text("Paleo-Hebrew Keyboard")
                            .font(.title.weight(.bold))

                        Text("Type in ancient Hebrew script anywhere on your device.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // Status
                    statusCard

                    // Steps
                    if !isKeyboardInstalled {
                        setupSteps
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }

            // Bottom button
            VStack(spacing: 12) {
                if isKeyboardInstalled {
                    Button {
                        hasCompletedSetup = true
                        dismiss()
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accent)
                } else {
                    Button {
                        openKeyboardSettings()
                    } label: {
                        Text("Open Settings")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
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
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .onAppear {
            checkKeyboardStatus()
            startPolling()
        }
        .onDisappear {
            stopPolling()
        }
        .interactiveDismissDisabled(!hasCompletedSetup)
    }

    // MARK: - Status Card

    private var statusCard: some View {
        HStack(spacing: 12) {
            Image(systemName: isKeyboardInstalled ? "checkmark.circle.fill" : "keyboard.badge.ellipsis")
                .font(.title2)
                .foregroundStyle(isKeyboardInstalled ? .green : .accent)
                .contentTransition(.symbolEffect(.replace))

            VStack(alignment: .leading, spacing: 2) {
                Text(isKeyboardInstalled ? "Keyboard installed" : "Keyboard not installed")
                    .font(.callout.weight(.semibold))

                Text(isKeyboardInstalled
                     ? "Switch to Paleo-Hebrew using the globe key."
                     : "Follow the steps below to enable the keyboard.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .animation(.smooth, value: isKeyboardInstalled)
    }

    // MARK: - Setup Steps

    private var setupSteps: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepRow(number: 1, title: "Open Settings", detail: "Tap the button below or go to Settings manually.", icon: "gearshape.fill")
            stepDivider()
            stepRow(number: 2, title: "General \u{203A} Keyboard", detail: "Navigate to General, then Keyboard.", icon: "keyboard.fill")
            stepDivider()
            stepRow(number: 3, title: "Keyboards \u{203A} Add New Keyboard", detail: "Tap \"Keyboards\", then \"Add New Keyboard...\"", icon: "plus.rectangle.on.rectangle")
            stepDivider()
            stepRow(number: 4, title: "Select Paleo-Hebrew", detail: "Find \"Aleph Tools\" and tap \"Paleo-Hebrew\".", icon: "checkmark.rectangle.fill")
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func stepRow(number: Int, title: String, detail: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(.accent.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }

    private func stepDivider() -> some View {
        Rectangle()
            .fill(.separator)
            .frame(width: 1, height: 16)
            .padding(.leading, 18)
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
