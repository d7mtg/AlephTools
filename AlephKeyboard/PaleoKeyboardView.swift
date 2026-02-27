import SwiftUI

// MARK: - Key Model

struct PaleoKey: Identifiable {
    let id: String
    let paleo: String
    let hebrew: String
}

// MARK: - Keyboard View

struct PaleoKeyboardView: View {
    let insertText: (String) -> Void
    let deleteBackward: () -> Void
    let nextKeyboard: () -> Void
    let showGlobe: Bool

    @State private var deleteTimer: Timer?

    // Hebrew keyboard layout positions → Paleo-Hebrew output
    // Row 1: e(ק) r(ר) t(א) y(ט) u(ו) i(ן) o(ם) p(פ)
    private let row1: [PaleoKey] = [
        .init(id: "ק", paleo: "\u{10912}", hebrew: "ק"),
        .init(id: "ר", paleo: "\u{10913}", hebrew: "ר"),
        .init(id: "א", paleo: "\u{10900}", hebrew: "א"),
        .init(id: "ט", paleo: "\u{10908}", hebrew: "ט"),
        .init(id: "ו", paleo: "\u{10905}", hebrew: "ו"),
        .init(id: "ן", paleo: "\u{1090D}", hebrew: "ן"),
        .init(id: "ם", paleo: "\u{1090C}", hebrew: "ם"),
        .init(id: "פ", paleo: "\u{10910}", hebrew: "פ"),
    ]

    // Row 2: a(ש) s(ד) d(ג) f(כ) g(ע) h(י) j(ח) k(ל) l(ך) ;(ף)
    private let row2: [PaleoKey] = [
        .init(id: "ש", paleo: "\u{10914}", hebrew: "ש"),
        .init(id: "ד", paleo: "\u{10903}", hebrew: "ד"),
        .init(id: "ג", paleo: "\u{10902}", hebrew: "ג"),
        .init(id: "כ", paleo: "\u{1090A}", hebrew: "כ"),
        .init(id: "ע", paleo: "\u{1090F}", hebrew: "ע"),
        .init(id: "י", paleo: "\u{10909}", hebrew: "י"),
        .init(id: "ח", paleo: "\u{10907}", hebrew: "ח"),
        .init(id: "ל", paleo: "\u{1090B}", hebrew: "ל"),
        .init(id: "ך", paleo: "\u{1090A}", hebrew: "ך"),
        .init(id: "ף", paleo: "\u{10910}", hebrew: "ף"),
    ]

    // Row 3: z(ז) x(ס) c(ב) v(ה) b(נ) n(מ) m(צ) ,(ת) .(ץ)
    private let row3: [PaleoKey] = [
        .init(id: "ז", paleo: "\u{10906}", hebrew: "ז"),
        .init(id: "ס", paleo: "\u{1090E}", hebrew: "ס"),
        .init(id: "ב", paleo: "\u{10901}", hebrew: "ב"),
        .init(id: "ה", paleo: "\u{10904}", hebrew: "ה"),
        .init(id: "נ", paleo: "\u{1090D}", hebrew: "נ"),
        .init(id: "מ", paleo: "\u{1090C}", hebrew: "מ"),
        .init(id: "צ", paleo: "\u{10911}", hebrew: "צ"),
        .init(id: "ת", paleo: "\u{10915}", hebrew: "ת"),
        .init(id: "ץ", paleo: "\u{10911}", hebrew: "ץ"),
    ]

    var body: some View {
        VStack(spacing: 6) {
            letterRow(row1)
            letterRow(row2)
            letterRow(row3)
            bottomRow
        }
        .padding(.horizontal, 3)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Letter Row

    private func letterRow(_ keys: [PaleoKey]) -> some View {
        HStack(spacing: 4) {
            ForEach(keys) { key in
                LetterKey(paleo: key.paleo, hebrew: key.hebrew) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    insertText(key.paleo)
                }
            }
        }
    }

    // MARK: - Bottom Row

    private var bottomRow: some View {
        HStack(spacing: 4) {
            // Globe
            if showGlobe {
                FunctionKey(systemImage: "globe", width: 48) {
                    nextKeyboard()
                }
            }

            // Space
            Button {
                insertText(" ")
            } label: {
                Text("space")
                    .font(.system(size: 15))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
            }
            .buttonStyle(KeyPressStyle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.regularMaterial)
            )

            // Return
            Button {
                insertText("\n")
            } label: {
                Text("return")
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 42)
            }
            .buttonStyle(KeyPressStyle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor)
            )

            // Delete (with long-press repeat)
            deleteKey
        }
    }

    // MARK: - Delete Key

    private var deleteKey: some View {
        Image(systemName: "delete.left.fill")
            .font(.system(size: 17))
            .frame(width: 48, height: 42)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.thickMaterial)
            )
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                deleteBackward()
            }
            .onLongPressGesture(minimumDuration: 0.3) {
                // Long press completed — no-op, timer handles it
            } onPressingChanged: { pressing in
                if pressing {
                    startRepeatingDelete()
                } else {
                    stopRepeatingDelete()
                }
            }
    }

    private func startRepeatingDelete() {
        deleteBackward()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            deleteBackward()
        }
    }

    private func stopRepeatingDelete() {
        deleteTimer?.invalidate()
        deleteTimer = nil
    }
}

// MARK: - Letter Key

private struct LetterKey: View {
    let paleo: String
    let hebrew: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(paleo)
                    .font(.system(size: 22))
                Text(hebrew)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(KeyPressStyle())
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 0.5, y: 0.5)
        )
    }
}

// MARK: - Function Key

private struct FunctionKey: View {
    let systemImage: String
    var width: CGFloat = 44
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17))
                .frame(width: width, height: 42)
        }
        .buttonStyle(KeyPressStyle())
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.thickMaterial)
        )
    }
}

// MARK: - Key Press Button Style

private struct KeyPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : 1)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
    }
}
