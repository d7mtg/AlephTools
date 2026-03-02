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

    private var paleoLayout: KeyboardLayout {
        let context = KeyboardContext()
        context.locale = Locale(identifier: "he")
        var layout = KeyboardLayout.standard(for: context)

        // Replace input keys with Paleo-Hebrew characters
        for rowIndex in layout.itemRows.indices {
            for itemIndex in layout.itemRows[rowIndex].indices {
                let item = layout.itemRows[rowIndex][itemIndex]
                if case .character(let char) = item.action {
                    if let paleo = paleoMap[char] {
                        layout.itemRows[rowIndex][itemIndex] = item.copy(
                            withAction: .character(paleo)
                        )
                    }
                }
            }
        }

        return layout
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

    /// Hebrew square → Paleo-Hebrew
    private let paleoMap: [String: String] = [
        "ק": "\u{10912}", "ר": "\u{10913}", "א": "\u{10900}", "ט": "\u{10908}",
        "ו": "\u{10905}", "ן": "\u{1090D}", "ם": "\u{1090C}", "פ": "\u{10910}",
        "ש": "\u{10914}", "ד": "\u{10903}", "ג": "\u{10902}", "כ": "\u{1090A}",
        "ע": "\u{1090F}", "י": "\u{10909}", "ח": "\u{10907}", "ל": "\u{1090B}",
        "ך": "\u{1090A}", "ף": "\u{10910}",
        "ז": "\u{10906}", "ס": "\u{1090E}", "ב": "\u{10901}", "ה": "\u{10904}",
        "נ": "\u{1090D}", "מ": "\u{1090C}", "צ": "\u{10911}", "ת": "\u{10915}",
        "ץ": "\u{10911}",
    ]

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
