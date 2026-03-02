import SwiftUI
import UIKit

// MARK: - Key Model

struct PaleoKey: Identifiable {
    let id: String
    let paleo: String
    let hebrew: String
}

// MARK: - Number/Symbol Key

struct SymbolKey: Identifiable {
    let id: String
    let label: String
}

// MARK: - Keyboard View

struct PaleoKeyboardView: View {
    let insertText: (String) -> Void
    let deleteBackward: () -> Void
    let nextKeyboard: () -> Void
    let showGlobe: Bool

    @State private var deleteTimer: Timer?
    @State private var showPaleo = true
    @State private var showNumbers = false
    @State private var lastSpaceTime: Date?

    private let haptic = UIImpactFeedbackGenerator(style: .light)

    // Hebrew keyboard layout positions → Paleo-Hebrew output
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

    // Numbers & symbols layout
    private let numRow1: [SymbolKey] = [
        .init(id: "1", label: "1"), .init(id: "2", label: "2"),
        .init(id: "3", label: "3"), .init(id: "4", label: "4"),
        .init(id: "5", label: "5"), .init(id: "6", label: "6"),
        .init(id: "7", label: "7"), .init(id: "8", label: "8"),
        .init(id: "9", label: "9"), .init(id: "0", label: "0"),
    ]

    private let numRow2: [SymbolKey] = [
        .init(id: "-", label: "-"), .init(id: "/", label: "/"),
        .init(id: ":", label: ":"), .init(id: ";", label: ";"),
        .init(id: "(", label: "("), .init(id: ")", label: ")"),
        .init(id: "\"", label: "\""), .init(id: "'", label: "'"),
    ]

    private let numRow3: [SymbolKey] = [
        .init(id: ".", label: "."), .init(id: ",", label: ","),
        .init(id: "?", label: "?"), .init(id: "!", label: "!"),
        .init(id: "׳", label: "׳"), .init(id: "״", label: "״"),
        .init(id: "־", label: "־"),
    ]

    var body: some View {
        VStack(spacing: 6) {
                if showNumbers {
                    symbolRow(numRow1)
                    symbolRow(numRow2)
                    HStack(spacing: 4) {
                        FunctionKey(label: "אב", width: 44) {
                            haptic.impactOccurred()
                            showNumbers = false
                        }
                        symbolRow(numRow3, extraPadding: false)
                        deleteKey
                    }
                } else {
                    letterRow(row1)
                    letterRow(row2)
                    HStack(spacing: 4) {
                        scriptToggle
                        letterRow(row3, extraPadding: false)
                        deleteKey
                    }
                }
                bottomRow
        }
        .padding(.horizontal, 3)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Letter Row

    private func letterRow(_ keys: [PaleoKey], extraPadding: Bool = true) -> some View {
        HStack(spacing: 4) {
            ForEach(keys) { key in
                LetterKey(
                    paleo: key.paleo,
                    hebrew: key.hebrew,
                    showPaleo: showPaleo
                ) {
                    haptic.impactOccurred()
                    insertText(key.paleo)
                }
            }
        }
    }

    // MARK: - Symbol Row

    private func symbolRow(_ keys: [SymbolKey], extraPadding: Bool = true) -> some View {
        HStack(spacing: 4) {
            ForEach(keys) { key in
                Button {
                    haptic.impactOccurred()
                    insertText(key.label)
                } label: {
                    Text(key.label)
                        .font(.system(size: 20))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.plain)
                .background(.regularMaterial, in: .rect(cornerRadius: 5))
            }
        }
    }

    // MARK: - Script Toggle

    private var scriptToggle: some View {
        FunctionKey(label: showPaleo ? "אב" : "𐤀𐤁", width: 44) {
            haptic.impactOccurred()
            withAnimation(.easeInOut(duration: 0.15)) {
                showPaleo.toggle()
            }
        }
    }

    // MARK: - Bottom Row

    private var bottomRow: some View {
        HStack(spacing: 4) {
            if showGlobe {
                FunctionKey(systemImage: "globe", width: 44) {
                    nextKeyboard()
                }
            }

            if !showNumbers {
                FunctionKey(label: "123", width: 44) {
                    haptic.impactOccurred()
                    showNumbers = true
                }
            }

            // Space
            Button {
                handleSpace()
            } label: {
                Text("space")
                    .font(.system(size: 15))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
            }
            .buttonStyle(.plain)
            .background(.regularMaterial, in: .rect(cornerRadius: 5))

            // Return
            Button {
                haptic.impactOccurred()
                insertText("\n")
            } label: {
                Text("return")
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 42)
            }
            .buttonStyle(.plain)
            .background(.tint, in: .rect(cornerRadius: 5))
        }
    }

    // MARK: - Delete Key

    private var deleteKey: some View {
        Image(systemName: "delete.left.fill")
            .font(.system(size: 17))
            .foregroundStyle(.primary)
            .frame(width: 44, height: 42)
            .background(.regularMaterial, in: .rect(cornerRadius: 5))
            .onTapGesture {
                haptic.impactOccurred()
                deleteBackward()
            }
            .onLongPressGesture(minimumDuration: 0.3) {
            } onPressingChanged: { pressing in
                if pressing {
                    startRepeatingDelete()
                } else {
                    stopRepeatingDelete()
                }
            }
    }

    // MARK: - Actions

    private func handleSpace() {
        haptic.impactOccurred()
        let now = Date()
        if let last = lastSpaceTime, now.timeIntervalSince(last) < 0.4 {
            // Double-tap space → period + space
            deleteBackward() // remove the first space
            insertText(". ")
            lastSpaceTime = nil
        } else {
            insertText(" ")
            lastSpaceTime = now
        }
    }

    private func startRepeatingDelete() {
        deleteBackward()
        haptic.impactOccurred()
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
    let showPaleo: Bool
    let action: () -> Void

    private var primaryText: String { showPaleo ? paleo : hebrew }
    private var secondaryText: String { showPaleo ? hebrew : paleo }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(primaryText)
                    .font(.system(size: 24))
                    .minimumScaleFactor(0.7)
                Text(secondaryText)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(.plain)
        .background(.regularMaterial, in: .rect(cornerRadius: 5))
    }
}

// MARK: - Function Key

private struct FunctionKey: View {
    var systemImage: String?
    var label: String?
    var width: CGFloat = 44
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 17))
                } else if let label {
                    Text(label)
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .frame(width: width, height: 42)
        }
        .buttonStyle(.plain)
        .background(.regularMaterial, in: .rect(cornerRadius: 5))
    }
}
