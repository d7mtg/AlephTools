import SwiftUI
import AppIntents

// MARK: - Settings

struct iOSSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultTransform") private var defaultTransformRaw = TransformationType.hebrewKeyboard.rawValue
    @AppStorage("languageOverride") private var languageOverride = "system"
    @State private var showKeyboardSetup = false
    @State private var isKeyboardInstalled = false

    private let keyboardBundleID = "com.alephtools.AlephToolsiOS.AlephKeyboard"

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

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showKeyboardSetup = true
                    } label: {
                        HStack {
                            Label(String(localized: "Paleo-Hebrew Keyboard"), systemImage: "keyboard")
                            Spacer()
                            if isKeyboardInstalled {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.body)
                            } else {
                                Text(String(localized: "Install"))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text("General", comment: "Settings section header")
                } footer: {
                    Text("Used when opening the app.", comment: "Default transformation footer")
                }

                // MARK: - Resources
                Section {
                    NavigationLink {
                        LearningCenterView()
                    } label: {
                        Label(String(localized: "Learning Center"), systemImage: "book")
                    }

                    NavigationLink {
                        AboutView()
                    } label: {
                        Label(String(localized: "About AlephTools"), systemImage: "info.circle")
                    }
                }

                // MARK: - Debug
                #if DEBUG
                Section {
                    Button("Show Welcome Sheet") {
                        NotificationCenter.default.post(name: .showWelcomeSheet, object: nil)
                        dismiss()
                    }
                } header: {
                    Text("Debug")
                }
                #endif

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
                    Button(String(localized: "Done")) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showKeyboardSetup) {
                KeyboardSetupView()
            }
            .onAppear { checkKeyboard() }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                checkKeyboard()
            }
        }
    }

    private func checkKeyboard() {
        let inputModes = UITextInputMode.activeInputModes
        isKeyboardInstalled = inputModes.contains { mode in
            guard let id = mode.value(forKey: "identifier") as? String else { return false }
            return id.contains(keyboardBundleID)
        }
    }
}

// MARK: - Confetti Burst (UIKit overlay — escapes all SwiftUI clipping)

private enum LetterConfetti {
    static let colors: [UIColor] = ConfettiData.colorComponents.map {
        UIColor(red: $0.r, green: $0.g, blue: $0.b, alpha: 1)
    }

    /// Spray letter confetti from a point in screen coordinates using plain UIView animation.
    static func spray(from point: CGPoint) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first?.windows.first else { return }

        let count = Int.random(in: 14...20)
        var labels: [UILabel] = []

        for _ in 0..<count {
            let letter = ConfettiData.letters.randomElement()!
            let color = colors.randomElement()!
            let fontSize = CGFloat.random(in: 22...38)

            let label = UILabel()
            label.text = letter
            label.font = .systemFont(ofSize: fontSize, weight: .bold)
            label.textColor = color
            label.sizeToFit()
            label.center = point
            label.alpha = 1
            label.transform = .identity
            window.addSubview(label)
            labels.append(label)
        }

        // Animate each label with physics-like trajectory
        for label in labels {
            let angle = CGFloat.random(in: 0 ... .pi * 2)
            let distance = CGFloat.random(in: 80...200)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance - 80 // bias upward

            let rotation = CGFloat.random(in: -3...3)

            UIView.animate(
                withDuration: 0.6,
                delay: 0,
                options: .curveEaseOut
            ) {
                label.center = CGPoint(x: point.x + dx, y: point.y + dy)
                label.transform = CGAffineTransform(rotationAngle: rotation)
            }

            // Gravity + fade phase
            UIView.animate(
                withDuration: 0.5,
                delay: 0.4,
                options: .curveEaseIn
            ) {
                label.center.y += 120 // gravity fall
                label.alpha = 0
                label.transform = label.transform.scaledBy(x: 0.3, y: 0.3)
            } completion: { _ in
                label.removeFromSuperview()
            }
        }
    }
}

// MARK: - Icon Tap Anchor (reads screen position via UIKit)

private struct IconTapView: UIViewRepresentable {
    let onTap: (CGPoint) -> Void
    let onHoldTick: (CGPoint) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.tapped(_:)))
        let hold = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.held(_:)))
        hold.minimumPressDuration = 0.25
        view.addGestureRecognizer(tap)
        view.addGestureRecognizer(hold)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap, onHoldTick: onHoldTick) }

    class Coordinator: NSObject {
        let onTap: (CGPoint) -> Void
        let onHoldTick: (CGPoint) -> Void
        private var timer: Timer?
        private var interval: TimeInterval = 0.15

        init(onTap: @escaping (CGPoint) -> Void, onHoldTick: @escaping (CGPoint) -> Void) {
            self.onTap = onTap
            self.onHoldTick = onHoldTick
        }

        private func screenCenter(of view: UIView) -> CGPoint {
            guard let window = view.window else { return .zero }
            return view.convert(CGPoint(x: view.bounds.midX, y: view.bounds.midY), to: window)
        }

        @objc func tapped(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view else { return }
            onTap(screenCenter(of: view))
        }

        @objc func held(_ gesture: UILongPressGestureRecognizer) {
            guard let view = gesture.view else { return }

            switch gesture.state {
            case .began:
                interval = 0.15
                onHoldTick(screenCenter(of: view))
                startTimer(view: view)
            case .ended, .cancelled, .failed:
                stopTimer()
            default:
                break
            }
        }

        private func startTimer(view: UIView) {
            stopTimer()
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self, weak view] _ in
                guard let self, let view else { return }
                self.onHoldTick(self.screenCenter(of: view))

                // Accelerate: get faster the longer you hold
                self.interval = max(0.04, self.interval * 0.85)

                // Random haptic on each tick
                let styles: [UIImpactFeedbackGenerator.FeedbackStyle] = [.light, .medium, .heavy, .rigid, .soft]
                UIImpactFeedbackGenerator(style: styles.randomElement()!).impactOccurred(intensity: CGFloat.random(in: 0.4...1.0))

                self.startTimer(view: view)
            }
        }

        private func stopTimer() {
            timer?.invalidate()
            timer = nil
        }
    }
}

// MARK: - About Page

struct AboutView: View {
    @State private var iconScale = 1.0
    @State private var iconAngle = 0.0

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        List {
            // MARK: - Hero
            Section {
                VStack(spacing: 16) {
                    Image("AboutIcon")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .primary.opacity(0.15), radius: 12, y: 6)
                        .scaleEffect(iconScale)
                        .rotationEffect(.degrees(iconAngle))
                        .overlay {
                            IconTapView(
                                onTap: { pt in fireConfetti(from: pt, withHaptics: true) },
                                onHoldTick: { pt in fireConfetti(from: pt, withHaptics: false) }
                            )
                        }
                        .accessibilityLabel(String(localized: "App icon"))

                    VStack(spacing: 4) {
                        Text("Aleph Tools")
                            .font(.title2.weight(.bold))
                        Text(String(localized: "Version \(appVersion) (\(buildNumber))"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .listRowBackground(Color.clear)
            }

            // MARK: - Links
            Section {
                ExternalLinkRow(
                    title: String(localized: "Source Code"),
                    icon: "chevron.left.forwardslash.chevron.right",
                    url: "https://github.com/d7mtg/AlephTools"
                )
                ExternalLinkRow(
                    title: String(localized: "Report Issue"),
                    icon: "ladybug",
                    url: "https://github.com/d7mtg/AlephTools/issues"
                )
                ExternalLinkRow(
                    title: "D7mtg",
                    icon: "person",
                    url: "https://d7mtg.com"
                )
            }

            // MARK: - Open-Source
            Section {
                ExternalLinkRow(
                    title: "Nakdimon",
                    icon: "wand.and.stars",
                    url: "https://github.com/elazarg/nakdimon"
                )
            } header: {
                Text("Open-Source Libraries", comment: "Settings section header")
            } footer: {
                Text("Hebrew diacritization model by Elazar Gershuni \u{00B7} MIT License", comment: "Nakdimon library description")
            }
        }
        .navigationTitle(String(localized: "About"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func fireConfetti(from screenPoint: CGPoint, withHaptics: Bool) {
        LetterConfetti.spray(from: screenPoint)

        // Icon squish + bounce
        iconScale = 0.75
        iconAngle = Double.random(in: -8...8)
        withAnimation(.spring(duration: 0.5, bounce: 0.6)) {
            iconScale = 1.0
            iconAngle = 0
        }

        if withHaptics {
            let heavy = UIImpactFeedbackGenerator(style: .heavy)
            heavy.prepare()
            heavy.impactOccurred(intensity: 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.7)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.4)
            }
        }
    }
}

// MARK: - External Link Row

private struct ExternalLinkRow: View {
    let title: String
    let icon: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Label(title, systemImage: icon)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
