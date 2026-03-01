import SwiftUI
import UIKit

struct KeyboardSetupView: View {
    @AppStorage("hasCompletedKeyboardSetup") private var hasCompletedSetup = false
    @State private var isKeyboardInstalled = false
    @State private var checkTimer: Timer?
    @State private var showSuccess = false
    @State private var stage = 0
    @Environment(\.dismiss) private var dismiss

    private let keyboardBundleID = "com.alephtools.AlephToolsiOS.AlephKeyboard"

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    preview
                    statusCard

                    if !isKeyboardInstalled && !showSuccess {
                        setupSteps
                            .transition(.blurReplace)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }

            bottomButtons
        }
        .onAppear {
            checkKeyboardStatus()
            startPolling()
            withAnimation(.smooth(duration: 0.6).delay(0.2)) { stage = 1 }
        }
        .onDisappear {
            stopPolling()
        }
        .interactiveDismissDisabled(!hasCompletedSetup)
        .onChange(of: isKeyboardInstalled) { _, installed in
            if installed {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.smooth(duration: 0.5)) {
                    showSuccess = true
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            Image("AppIcon")
                .resizable()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .accent.opacity(0.3), radius: 12, y: 6)
                .padding(.top, 36)
                .opacity(stage >= 1 ? 1 : 0)
                .scaleEffect(stage >= 1 ? 1 : 0.8)

            VStack(spacing: 6) {
                Text("Paleo-Hebrew Keyboard")
                    .font(.title2.weight(.bold))

                Text("Type in ancient Hebrew script anywhere on your device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .opacity(stage >= 1 ? 1 : 0)
            .offset(y: stage >= 1 ? 0 : 12)
        }
    }

    // MARK: - Preview

    private var preview: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(Array("\u{10900}\u{10901}\u{10902}\u{10903}\u{10904}".enumerated()), id: \.offset) { i, char in
                    Text(String(char))
                        .font(.system(size: 22))
                        .frame(width: 38, height: 42)
                        .background(.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        .opacity(stage >= 1 ? 1 : 0)
                        .scaleEffect(stage >= 1 ? 1 : 0.5)
                        .animation(.smooth(duration: 0.4).delay(0.4 + Double(i) * 0.08), value: stage)
                }
            }

            Text("Preview")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isKeyboardInstalled ? .green.opacity(0.15) : .accent.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: isKeyboardInstalled ? "checkmark.circle.fill" : "keyboard.badge.ellipsis")
                    .font(.title3)
                    .foregroundStyle(isKeyboardInstalled ? .green : .accent)
                    .contentTransition(.symbolEffect(.replace))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(isKeyboardInstalled ? "Ready to go" : "Not enabled yet")
                    .font(.callout.weight(.semibold))

                Text(isKeyboardInstalled
                     ? "Switch keyboards with the globe key while typing."
                     : "Follow the steps below to add the keyboard.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .animation(.smooth, value: isKeyboardInstalled)
    }

    // MARK: - Setup Steps

    private var setupSteps: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepRow(
                number: 1,
                title: "General \u{203A} Keyboard",
                detail: "In Settings, go to General, then tap Keyboard.",
                icon: "gearshape.fill"
            )
            stepConnector()
            stepRow(
                number: 2,
                title: "Add New Keyboard",
                detail: "Tap \"Keyboards\", then \"Add New Keyboard...\"",
                icon: "plus.rectangle.on.rectangle"
            )
            stepConnector()
            stepRow(
                number: 3,
                title: "Select Paleo-Hebrew",
                detail: "Find \"Aleph Tools\" in the list and tap it.",
                icon: "checkmark.rectangle.fill"
            )
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    private func stepRow(number: Int, title: String, detail: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(.accent.opacity(0.12))
                    .frame(width: 32, height: 32)
                Text("\(number)")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 3)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }

    private func stepConnector() -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(.accent.opacity(0.2))
            .frame(width: 2, height: 20)
            .padding(.leading, 15)
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
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
                    Label("Open Settings", systemImage: "arrow.up.forward.app")
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
                .padding(.bottom, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .animation(.smooth, value: isKeyboardInstalled)
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
