import SwiftUI
import Carbon
import ServiceManagement

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label(String(localized: "General"), systemImage: "gearshape")
                }
            IntegrationsSettingsTab()
                .tabItem {
                    Label(String(localized: "Shortcuts"), systemImage: "command")
                }
            AboutSettingsTab()
                .tabItem {
                    Label(String(localized: "About"), systemImage: "info.circle")
                }
        }
        .frame(width: 560, height: 580)
    }
}

// MARK: - General Tab

private struct GeneralSettingsTab: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("defaultTransform") private var defaultTransform = TransformationType.hebrewKeyboard.rawValue
    @AppStorage("showInMenuBar") private var showInMenuBar = false
    @AppStorage("appearanceOverride") private var appearanceOverride = "system"
    @AppStorage("languageOverride") private var languageOverride = "system"

    var body: some View {
        Form {
            Section {
                Toggle(String(localized: "Launch Aleph Tools at login"), isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        LaunchAtLoginManager.setEnabled(newValue)
                    }

                Picker(String(localized: "Default transformation"), selection: $defaultTransform) {
                    ForEach(TransformationType.allCases) { t in
                        Text(t.localizedName).tag(t.rawValue)
                    }
                }

                Toggle(String(localized: "Show in menu bar"), isOn: $showInMenuBar)
            } footer: {
                Text(String(localized: "Default transformation is used when opening the app."))
            }

            Section {
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
            } footer: {
                Text(String(localized: "Restart the app to fully apply language changes."))
            }

            Section(String(localized: "Appearance")) {
                AppearancePicker(selection: $appearanceOverride)
            }

            #if DEBUG
            Section("Debug") {
                Button("Show Welcome Sheet") {
                    NotificationCenter.default.post(name: .showWelcomeSheet, object: nil)
                }
            }
            #endif
        }
        .formStyle(.grouped)
    }
}

// MARK: - Launch at Login

enum LaunchAtLoginManager {
    static func setEnabled(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            print("Launch at login error: \(error)")
        }
    }
}

// MARK: - Appearance Picker

struct AppearancePicker: View {
    @Binding var selection: String

    private var options: [(id: String, label: String)] {
        [
            ("system", String(localized: "Auto")),
            ("light", String(localized: "Light")),
            ("dark", String(localized: "Dark")),
        ]
    }

    var body: some View {
        HStack(spacing: 20) {
            ForEach(options, id: \.id) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selection = option.id
                    }
                } label: {
                    VStack(spacing: 7) {
                        AppearanceThumbnail(mode: option.id, isSelected: selection == option.id)
                            .frame(width: 80, height: 56)

                        Text(option.label)
                            .font(.system(size: 11, weight: selection == option.id ? .semibold : .regular))
                            .foregroundStyle(selection == option.id ? .primary : .secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

struct AppearanceThumbnail: View {
    let mode: String
    let isSelected: Bool

    // Concentric radii: outer - inset = inner
    private let outerRadius: CGFloat = 10
    private let inset: CGFloat = 8
    private var innerRadius: CGFloat { outerRadius - inset + 2 } // 4pt

    var body: some View {
        ZStack {
            // Desktop background
            if mode == "system" {
                HStack(spacing: 0) {
                    Color(white: 0.96)
                    Color(white: 0.15)
                }
            } else if mode == "light" {
                Color(white: 0.96)
            } else {
                Color(white: 0.15)
            }

            // Mini window(s)
            if mode == "system" {
                splitWindow
            } else {
                miniWindow(light: mode == "light")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: outerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                .strokeBorder(
                    isSelected ? Color.accentColor : Color.primary.opacity(0.12),
                    lineWidth: isSelected ? 2.5 : 0.5
                )
        )
    }

    // Auto mode: single window split light/dark with one set of traffic lights
    private var splitWindow: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Shared title bar
                HStack(spacing: 2) {
                    Circle().fill(Color(red: 1, green: 0.38, blue: 0.35)).frame(width: 4, height: 4)
                    Circle().fill(Color(red: 1, green: 0.78, blue: 0.23)).frame(width: 4, height: 4)
                    Circle().fill(Color(red: 0.15, green: 0.8, blue: 0.26)).frame(width: 4, height: 4)
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 3.5)
                .background(
                    HStack(spacing: 0) {
                        Color(white: 0.94)
                        Color(white: 0.26)
                    }
                )

                // Split content area
                HStack(spacing: 0) {
                    // Light half
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 1).fill(Color.accentColor.opacity(0.4)).frame(height: 2.5)
                        RoundedRectangle(cornerRadius: 1).fill(Color(white: 0.84)).frame(height: 2.5)
                        RoundedRectangle(cornerRadius: 1).fill(Color(white: 0.84)).frame(height: 2.5)
                            .frame(maxWidth: geo.size.width * 0.25, alignment: .leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(white: 0.98))

                    // Dark half
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 1).fill(Color.accentColor.opacity(0.5)).frame(height: 2.5)
                        RoundedRectangle(cornerRadius: 1).fill(Color(white: 0.34)).frame(height: 2.5)
                        RoundedRectangle(cornerRadius: 1).fill(Color(white: 0.34)).frame(height: 2.5)
                            .frame(maxWidth: geo.size.width * 0.25, alignment: .leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(white: 0.2))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: innerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 1.5, y: 0.5)
            .padding(inset)
        }
    }

    private func miniWindow(light: Bool) -> some View {
        let windowBg = light ? Color(white: 0.98) : Color(white: 0.2)
        let titleBar = light ? Color(white: 0.94) : Color(white: 0.26)
        let line1 = light ? Color.accentColor.opacity(0.4) : Color.accentColor.opacity(0.5)
        let line2 = light ? Color(white: 0.84) : Color(white: 0.34)

        return GeometryReader { geo in
            VStack(spacing: 0) {
                // Title bar with traffic lights
                HStack(spacing: 2) {
                    Circle().fill(Color(red: 1, green: 0.38, blue: 0.35)).frame(width: 4, height: 4)
                    Circle().fill(Color(red: 1, green: 0.78, blue: 0.23)).frame(width: 4, height: 4)
                    Circle().fill(Color(red: 0.15, green: 0.8, blue: 0.26)).frame(width: 4, height: 4)
                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 3.5)
                .background(titleBar)

                // Content lines
                VStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(line1)
                        .frame(height: 2.5)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(line2)
                        .frame(height: 2.5)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(line2)
                        .frame(maxWidth: geo.size.width * 0.5)
                        .frame(height: 2.5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .frame(maxHeight: .infinity)
                .background(windowBg)
            }
            .clipShape(RoundedRectangle(cornerRadius: innerRadius, style: .continuous))
            .shadow(color: .black.opacity(light ? 0.1 : 0.25), radius: 1.5, y: 0.5)
            .padding(inset)
        }
    }
}

// MARK: - Integrations Tab

private struct IntegrationsSettingsTab: View {
    @ObservedObject private var shortcutManager = GlobalShortcutManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Global Shortcuts"))
                .font(.headline)

            Text(String(localized: "Assign keyboard shortcuts to transform selected text anywhere on your Mac. The app must be running."))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Accessibility warning — above the list, it's a prerequisite
            if !AXIsProcessTrusted() {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Accessibility Access Required"))
                            .font(.callout.weight(.medium))
                        Text(String(localized: "Global shortcuts need Accessibility permission to work in other apps."))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(String(localized: "Open Settings")) {
                        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
                        AXIsProcessTrustedWithOptions(options)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(10)
                .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(TransformationType.allCases) { t in
                        ShortcutRow(transform: t, manager: shortcutManager)

                        if t != TransformationType.allCases.last {
                            Divider()
                                .padding(.leading, 36)
                        }
                    }
                }
                .padding(8)
                .background(.background, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.separator, lineWidth: 0.5)
                )
            }

            // Other integrations
            HStack(spacing: 6) {
                if AXIsProcessTrusted() {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(String(localized: "Accessibility access granted. Shortcuts work system-wide."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text(String(localized: "Shortcuts require Accessibility access to work."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Also available via"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.tertiary)

                HStack(spacing: 16) {
                    Label(String(localized: "Services Menu"), systemImage: "contextualmenu.and.cursorarrow")
                    Label(String(localized: "Shortcuts"), systemImage: "command")
                    Label(String(localized: "Siri"), systemImage: "siri")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(20)
    }
}

// MARK: - Shortcut Row

private struct ShortcutRow: View {
    let transform: TransformationType
    @ObservedObject var manager: GlobalShortcutManager
    @State private var isRecording = false
    @State private var localMonitor: Any?
    @State private var showRecorded = false

    private var shortcut: StoredShortcut? {
        manager.shortcuts[transform]
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: transform.icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 1) {
                Text(transform.localizedName)
                    .font(.body.weight(.medium))
                Text(transform.subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Unified shortcut field — always the same size, zero layout shift
            shortcutField
                .onAppear { if isRecording { startLocalMonitor() } }
                .onChange(of: isRecording) { _, recording in
                    if recording { startLocalMonitor() } else { stopLocalMonitor() }
                }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }

    private var shortcutField: some View {
        HStack(spacing: 0) {
            ZStack {
                if isRecording {
                    Text(String(localized: "Type shortcut…"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .transition(.blurReplace)
                } else if showRecorded {
                    Label(String(localized: "Recorded"), systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.green)
                        .transition(.blurReplace)
                } else if let shortcut {
                    Text(shortcut.displayString)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .transition(.blurReplace)
                } else {
                    Text(String(localized: "Record Shortcut"))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .transition(.blurReplace)
                }
            }
            .padding(.horizontal, 8)

            if shortcut != nil && !isRecording && !showRecorded {
                Button {
                    manager.removeShortcut(for: transform)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
                .transition(.opacity)
            }
        }
        .frame(minWidth: 120, minHeight: 24)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(isRecording ? Color.accentColor : .clear, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isRecording {
                withAnimation(.easeInOut(duration: 0.15)) { isRecording = true }
            }
        }
    }

    private func startLocalMonitor() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            if event.keyCode == 53 {
                stopRecording()
                return nil
            }

            guard mods.contains(.command) || mods.contains(.control) || mods.contains(.option) else {
                return event
            }

            let char = event.charactersIgnoringModifiers ?? ""
            guard !char.isEmpty else { return event }

            let recorded = StoredShortcut(
                keyCode: UInt32(event.keyCode),
                character: char,
                modifiers: mods.rawValue
            )
            manager.setShortcut(recorded, for: transform)
            withAnimation(.easeInOut(duration: 0.15)) {
                stopRecording()
                showRecorded = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.15)) { showRecorded = false }
            }
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        stopLocalMonitor()
    }

    private func stopLocalMonitor() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        localMonitor = nil
    }
}

// MARK: - Confetti Particle

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let letter: String
    let color: Color
    let fontSize: CGFloat
    let burstX: CGFloat
    let burstY: CGFloat
    let rotation: Double
    let gravityY: CGFloat = 180
}

private let confettiColors: [Color] = ConfettiData.colorComponents.map {
    Color(red: $0.r, green: $0.g, blue: $0.b)
}

// MARK: - Confetti Batch State

private enum ConfettiPhase {
    case idle      // at center, fully visible
    case burst     // flying outward
    case gravity   // falling + fading
}

private struct ConfettiBatch: Identifiable {
    let id = UUID()
    let particles: [ConfettiParticle]
    var phase: ConfettiPhase = .idle
}

// MARK: - Single Particle View

private struct ConfettiParticleView: View {
    let particle: ConfettiParticle
    let phase: ConfettiPhase

    var body: some View {
        Text(particle.letter)
            .font(.system(size: particle.fontSize, weight: .bold))
            .foregroundStyle(particle.color)
            .offset(x: offsetX, y: offsetY)
            .rotationEffect(.degrees(phase == .idle ? 0 : particle.rotation * 60))
            .opacity(phase == .gravity ? 0 : 1)
            .scaleEffect(phase == .gravity ? 0.3 : 1)
    }

    private var offsetX: CGFloat {
        phase == .idle ? 0 : particle.burstX
    }

    private var offsetY: CGFloat {
        switch phase {
        case .idle: return 0
        case .burst: return particle.burstY
        case .gravity: return particle.burstY + particle.gravityY
        }
    }
}

// MARK: - Click & Hold Gesture (AppKit — works reliably for press-and-hold)

private struct ClickAndHoldView: NSViewRepresentable {
    let onTap: () -> Void
    let onHoldTick: () -> Void
    let onHoldEnd: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let click = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.clicked(_:)))
        let press = NSPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.pressed(_:)))
        press.minimumPressDuration = 0.25
        view.addGestureRecognizer(click)
        view.addGestureRecognizer(press)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap, onHoldTick: onHoldTick, onHoldEnd: onHoldEnd) }

    class Coordinator: NSObject {
        let onTap: () -> Void
        let onHoldTick: () -> Void
        let onHoldEnd: () -> Void
        private var timer: Timer?
        private var interval: TimeInterval = 0.15

        init(onTap: @escaping () -> Void, onHoldTick: @escaping () -> Void, onHoldEnd: @escaping () -> Void) {
            self.onTap = onTap
            self.onHoldTick = onHoldTick
            self.onHoldEnd = onHoldEnd
        }

        @objc func clicked(_ g: NSClickGestureRecognizer) {
            onTap()
        }

        @objc func pressed(_ g: NSPressGestureRecognizer) {
            switch g.state {
            case .began:
                interval = 0.15
                onHoldTick()
                startTimer()
            case .ended, .cancelled, .failed:
                stopTimer()
                onHoldEnd()
            default: break
            }
        }

        private func startTimer() {
            stopTimer()
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
                guard let self else { return }
                self.onHoldTick()
                self.interval = max(0.04, self.interval * 0.85)
                self.startTimer()
            }
        }

        private func stopTimer() {
            timer?.invalidate()
            timer = nil
        }
    }
}

// MARK: - About Tab

private struct AboutSettingsTab: View {
    @Environment(\.openWindow) private var openWindow
    @State private var iconScale = 1.0
    @State private var iconAngle = 0.0
    @State private var batches: [ConfettiBatch] = []

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 0) {
            // App identity
            VStack(spacing: 12) {
                Image("AboutIcon")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .primary.opacity(0.15), radius: 12, y: 6)
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(iconAngle))
                    .overlay {
                        ZStack {
                            ForEach(batches) { batch in
                                ForEach(batch.particles) { p in
                                    ConfettiParticleView(particle: p, phase: batch.phase)
                                }
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .overlay {
                        ClickAndHoldView(
                            onTap: { fireConfetti(withHaptics: true) },
                            onHoldTick: { fireConfetti(withHaptics: true) },
                            onHoldEnd: {}
                        )
                    }

                VStack(spacing: 2) {
                    Text(String(localized: "Aleph Tools"))
                        .font(.title2.weight(.semibold))

                    Text(String(localized: "Version \(appVersion) (\(buildNumber))"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 20)

            // Description
            Text(String(localized: "Hebrew text transformation utility for macOS. Convert keyboard layouts, strip niqqud, transliterate between modern and paleo-Hebrew scripts, and more."))
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
                .padding(.bottom, 20)

            // Links
            VStack(spacing: 0) {
                aboutRow(icon: "book", label: String(localized: "Learning Center")) {
                    openWindow(id: "learning-center")
                }

                Divider().padding(.leading, 36)

                aboutLinkRow(icon: "chevron.left.forwardslash.chevron.right", label: String(localized: "Source Code"), url: "https://github.com/d7mtg/AlephTools")

                Divider().padding(.leading, 36)

                aboutLinkRow(icon: "ladybug", label: String(localized: "Report an Issue"), url: "https://github.com/d7mtg/AlephTools/issues")

                Divider().padding(.leading, 36)

                aboutLinkRow(icon: "globe", label: String(localized: "Website"), url: "https://d7mtg.com")
            }
            .padding(.vertical, 4)
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.separator, lineWidth: 0.5)
            )
            .padding(.horizontal, 20)

            // Open-source credits
            VStack(alignment: .leading, spacing: 0) {
                Text(String(localized: "Open-Source Libraries"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, 6)

                Divider().padding(.leading, 12)

                Link(destination: URL(string: "https://github.com/elazarg/nakdimon")!) {
                    HStack(spacing: 10) {
                        Image(systemName: "wand.and.stars")
                            .frame(width: 20)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Nakdimon")
                                .foregroundStyle(.primary)
                            Text(String(localized: "Hebrew diacritization model by Elazar Gershuni · MIT License"))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.quaternary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.separator, lineWidth: 0.5)
            )
            .padding(.horizontal, 20)
            .padding(.top, 16)

            Spacer()

            // Footer
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(String(localized: "Made by"))
                    Link("D7mtg", destination: URL(string: "https://d7mtg.com")!)
                    Text(String(localized: "with"))
                    Link("Claude Code", destination: URL(string: "https://claude.ai/claude-code")!)
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
                .tint(.secondary)

                Text("© 2025 D7mtg")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
    }

    private func fireConfetti(withHaptics: Bool) {
        let count = Int.random(in: 20...30)
        let particles = (0..<count).map { _ in
            let angle = CGFloat.random(in: 0 ... .pi * 2)
            let distance = CGFloat.random(in: 100...280)
            return ConfettiParticle(
                letter: ConfettiData.letters.randomElement()!,
                color: confettiColors.randomElement()!,
                fontSize: CGFloat.random(in: 14...28),
                burstX: cos(angle) * distance,
                burstY: sin(angle) * distance - 100,
                rotation: Double.random(in: -3...3)
            )
        }
        let batch = ConfettiBatch(particles: particles)
        let batchID = batch.id
        batches.append(batch)

        // Phase 1: burst outward
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.6)) {
                if let i = batches.firstIndex(where: { $0.id == batchID }) {
                    batches[i].phase = .burst
                }
            }
        }

        // Phase 2: gravity fall + fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeIn(duration: 0.5)) {
                if let i = batches.firstIndex(where: { $0.id == batchID }) {
                    batches[i].phase = .gravity
                }
            }
        }

        // Clean up
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            batches.removeAll { $0.id == batchID }
        }

        // Icon squish + bounce
        iconScale = 0.75
        iconAngle = Double.random(in: -8...8)
        withAnimation(.spring(duration: 0.5, bounce: 0.6)) {
            iconScale = 1.0
            iconAngle = 0
        }

        // Trackpad haptics — varied intensity like iOS
        if withHaptics {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            }
        }
    }


    private func aboutRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .frame(width: 20)
                    .foregroundStyle(.secondary)
                Text(label)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.quaternary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func aboutLinkRow(icon: String, label: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .frame(width: 20)
                    .foregroundStyle(.secondary)
                Text(label)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.quaternary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stored Shortcut

struct StoredShortcut: Codable, Equatable {
    let keyCode: UInt32
    let character: String
    let modifiers: UInt

    var displayString: String {
        var parts: [String] = []
        let mods = NSEvent.ModifierFlags(rawValue: modifiers)
        if mods.contains(.control) { parts.append("\u{2303}") }
        if mods.contains(.option) { parts.append("\u{2325}") }
        if mods.contains(.shift) { parts.append("\u{21E7}") }
        if mods.contains(.command) { parts.append("\u{2318}") }
        parts.append(character.uppercased())
        return parts.joined()
    }
}

// MARK: - Global Shortcut Manager

class GlobalShortcutManager: ObservableObject {
    static let shared = GlobalShortcutManager()

    @Published var shortcuts: [TransformationType: StoredShortcut] = [:]
    private var monitor: Any?

    private init() {
        loadShortcuts()
        startMonitoring()
    }

    func setShortcut(_ shortcut: StoredShortcut, for transform: TransformationType) {
        shortcuts[transform] = shortcut
        saveShortcuts()
        restartMonitoring()
    }

    func removeShortcut(for transform: TransformationType) {
        shortcuts.removeValue(forKey: transform)
        saveShortcuts()
        restartMonitoring()
    }

    private func saveShortcuts() {
        let data = shortcuts.map { (key: $0.key.rawValue, value: $0.value) }
        if let encoded = try? JSONEncoder().encode(Dictionary(uniqueKeysWithValues: data.map { ($0.key, $0.value) })) {
            UserDefaults.standard.set(encoded, forKey: "globalShortcuts")
        }
    }

    private func loadShortcuts() {
        guard let data = UserDefaults.standard.data(forKey: "globalShortcuts"),
              let decoded = try? JSONDecoder().decode([String: StoredShortcut].self, from: data) else { return }
        for (key, value) in decoded {
            if let transform = TransformationType.allCases.first(where: { $0.rawValue == key }) {
                shortcuts[transform] = value
            }
        }
    }

    private func restartMonitoring() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        startMonitoring()
    }

    private func startMonitoring() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleGlobalKeyEvent(event)
        }
    }

    private func handleGlobalKeyEvent(_ event: NSEvent) {
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
        let char = event.charactersIgnoringModifiers?.lowercased() ?? ""

        for (transform, shortcut) in shortcuts {
            let storedMods = NSEvent.ModifierFlags(rawValue: shortcut.modifiers)
                .intersection(.deviceIndependentFlagsMask).rawValue
            if storedMods == mods && shortcut.character.lowercased() == char {
                performSystemTransform(transform)
                return
            }
        }
    }

    private func performSystemTransform(_ transform: TransformationType) {
        DispatchQueue.main.async {
            // Copy current selection
            let copyEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0x08, keyDown: true)! // 'c'
            copyEvent.flags = .maskCommand
            copyEvent.post(tap: .cghidEventTap)
            let copyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x08, keyDown: false)!
            copyUp.flags = .maskCommand
            copyUp.post(tap: .cghidEventTap)

            // Wait for clipboard to update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard let text = NSPasteboard.general.string(forType: .string) else { return }
                let result = TransformationEngine.transform(text, mode: transform, keepPunctuation: false)

                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(result, forType: .string)

                // Paste back
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    let pasteEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: true)! // 'v'
                    pasteEvent.flags = .maskCommand
                    pasteEvent.post(tap: .cghidEventTap)
                    let pasteUp = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: false)!
                    pasteUp.flags = .maskCommand
                    pasteUp.post(tap: .cghidEventTap)
                }
            }
        }
    }
}
