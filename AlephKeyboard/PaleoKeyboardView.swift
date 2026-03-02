import SwiftUI
import KeyboardKit

// MARK: - App Configuration

extension KeyboardApp {
    static var alephKeyboard: KeyboardApp {
        .init(
            name: "Aleph Tools",
            locales: [.hebrew]
        )
    }
}

// MARK: - Paleo Keyboard View

struct PaleoKeyboardView: View {
    let services: Keyboard.Services

    var body: some View {
        KeyboardView(
            layout: paleoLayout,
            services: services,
            buttonContent: { params in
                paleoButtonContent(params: params)
            },
            buttonView: { params in
                params.view
            }
        )
    }

    // MARK: - Layout

    /// Hebrew keyboard rows mapped to Paleo-Hebrew (standard Israeli layout)
    private static let paleoRow1: [String] = [
        "\u{10912}", "\u{10913}", "\u{10900}", "\u{10908}",  // ק ר א ט
        "\u{10905}", "\u{1090D}", "\u{1090C}", "\u{10910}",  // ו ן ם פ
    ]
    private static let paleoRow2: [String] = [
        "\u{10914}", "\u{10903}", "\u{10902}", "\u{1090A}",  // ש ד ג כ
        "\u{1090F}", "\u{10909}", "\u{10907}", "\u{1090B}",  // ע י ח ל
        "\u{1090A}", "\u{10910}",                            // ך ף
    ]
    private static let paleoRow3: [String] = [
        "\u{10906}", "\u{1090E}", "\u{10901}", "\u{10904}",  // ז ס ב ה
        "\u{1090D}", "\u{1090C}", "\u{10911}", "\u{10915}",  // נ מ צ ת
        "\u{10911}",                                          // ץ
    ]

    private var paleoLayout: KeyboardLayout {
        // Get standard layout for system key sizing
        let context = KeyboardContext()
        let standardLayout = KeyboardLayout.standard(for: context)

        // Find system key sizes from standard layout
        let inputSize = standardLayout.itemRows.first?.first(where: {
            if case .character = $0.action { return true }
            return false
        })?.size ?? KeyboardLayout.ItemSize(
            width: .input,
            height: 42
        )
        let insets = standardLayout.itemRows.first?.first(where: {
            if case .character = $0.action { return true }
            return false
        })?.edgeInsets ?? EdgeInsets()

        // Build character rows with Paleo-Hebrew
        let rows: [[String]] = [Self.paleoRow1, Self.paleoRow2, Self.paleoRow3]
        var itemRows: KeyboardLayout.ItemRows = rows.map { row in
            row.map { char in
                KeyboardLayout.Item(
                    action: .character(char),
                    size: inputSize,
                    edgeInsets: insets
                )
            }
        }

        // Add system keys from standard layout (bottom row with space, backspace, etc.)
        // Find the row with space key
        for row in standardLayout.itemRows {
            let hasSpace = row.contains { $0.action == .space }
            if hasSpace {
                itemRows.append(row)
                break
            }
        }

        // Add shift + backspace to row 3
        if let standardRow3 = standardLayout.itemRows.last(where: { row in
            row.contains { $0.action == .backspace }
                && !row.contains { $0.action == .space }
        }) {
            // Extract shift from start and backspace from end
            var shift: KeyboardLayout.Item?
            var backspace: KeyboardLayout.Item?
            for item in standardRow3 {
                if case .shift = item.action { shift = item }
                if item.action == .backspace { backspace = item }
            }
            if let shift, let backspace {
                var row3 = [shift] + itemRows[2]
                row3.append(backspace)
                itemRows[2] = row3
            }
        }

        return KeyboardLayout(
            itemRows: itemRows,
            deviceConfiguration: standardLayout.deviceConfiguration,
            idealItemHeight: standardLayout.idealItemHeight,
            idealItemInsets: standardLayout.idealItemInsets
        )
    }

    // MARK: - Button Content

    @ViewBuilder
    private func paleoButtonContent(params: (item: KeyboardLayout.Item, view: Keyboard.ButtonContent)) -> some View {
        if case .character(let char) = params.item.action,
           let hebrew = reverseMap[char] {
            VStack(spacing: 1) {
                Text(char)
                    .font(.system(size: 22))
                    .minimumScaleFactor(0.6)
                Text(hebrew)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
        } else {
            params.view
        }
    }

    // MARK: - Character Maps

    /// Paleo-Hebrew → Hebrew square (for display)
    private let reverseMap: [String: String] = [
        "\u{10900}": "א", "\u{10901}": "ב", "\u{10902}": "ג", "\u{10903}": "ד",
        "\u{10904}": "ה", "\u{10905}": "ו", "\u{10906}": "ז", "\u{10907}": "ח",
        "\u{10908}": "ט", "\u{10909}": "י", "\u{1090A}": "כ", "\u{1090B}": "ל",
        "\u{1090C}": "מ", "\u{1090D}": "נ", "\u{1090E}": "ס", "\u{1090F}": "ע",
        "\u{10910}": "פ", "\u{10911}": "צ", "\u{10912}": "ק", "\u{10913}": "ר",
        "\u{10914}": "ש", "\u{10915}": "ת",
    ]
}
