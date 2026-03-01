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
                VStack(spacing: 20) {
                    header
                    preview

                    if isKeyboardInstalled || showSuccess {
                        successCard
                            .transition(.blurReplace)
                    } else {
                        setupSteps
                            .transition(.blurReplace)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }

            bottomButtons
        }
        .onAppear {
            checkKeyboardStatus()
            startPolling()
            withAnimation(.smooth(duration: 0.5).delay(0.15)) { stage = 1 }
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
        HStack(spacing: 14) {
            Image("AppIcon")
                .resizable()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .shadow(color: .accent.opacity(0.25), radius: 8, y: 4)
                .opacity(stage >= 1 ? 1 : 0)
                .scaleEffect(stage >= 1 ? 1 : 0.8)

            VStack(alignment: .leading, spacing: 3) {
                Text("Paleo-Hebrew Keyboard")
                    .font(.headline)

                Text("Type in ancient script anywhere.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .opacity(stage >= 1 ? 1 : 0)
            .offset(x: stage >= 1 ? 0 : -8)

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Preview

    private var preview: some View {
        HStack(spacing: 5) {
            ForEach(Array("\u{10900}\u{10901}\u{10902}\u{10903}\u{10904}\u{10905}\u{10906}".enumerated()), id: \.offset) { i, char in
                Text(String(char))
                    .font(.system(size: 20))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
                    .opacity(stage >= 1 ? 1 : 0)
                    .scaleEffect(stage >= 1 ? 1 : 0.6)
                    .animation(.smooth(duration: 0.35).delay(0.3 + Double(i) * 0.05), value: stage)
            }
        }
    }

    // MARK: - Success Card

    private var successCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
                .contentTransition(.symbolEffect(.replace))

            VStack(alignment: .leading, spacing: 2) {
                Text("Ready to go")
                    .font(.callout.weight(.semibold))
                Text("Switch keyboards with the globe key while typing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    // MARK: - Setup Steps

    private var setupSteps: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepRow(
                number: 1,
                title: "General \u{203A} Keyboard",
                detail: "In Settings, go to General, then Keyboard."
            )
            stepConnector()
            stepRow(
                number: 2,
                title: "Add New Keyboard",
                detail: "Tap \"Keyboards\", then \"Add New Keyboard...\""
            )
            stepConnector()
            stepRow(
                number: 3,
                title: "Select Paleo-Hebrew",
                detail: "Find \"Aleph Tools\" and tap it."
            )
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
    }

    private func stepRow(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(.accent.opacity(0.12))
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundStyle(.accent)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 2)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private func stepConnector() -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(.accent.opacity(0.2))
            .frame(width: 2, height: 14)
            .padding(.leading, 13)
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: 10) {
            if isKeyboardInstalled {
                Button {
                    hasCompletedSetup = true
                    dismiss()
                } label: {
                    Text("Get Started")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accent)
            } else {
                Button {
                    openKeyboardSettings()
                } label: {
                    Label("Open Settings", systemImage: "arrow.up.forward.app")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accent)

                Button("Skip for now") {
                    hasCompletedSetup = true
                    dismiss()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
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
