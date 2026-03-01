import SwiftUI

// MARK: - Learning Center

struct LearningCenterView: View {
    var body: some View {
        List {
            ForEach(LearningTopic.all) { topic in
                NavigationLink {
                    TopicDetailView(topic: topic)
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(topic.color.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: topic.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(topic.color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(topic.title)
                                .font(.body.weight(.medium))
                            Text(topic.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Learning Center")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Topic Detail

private struct TopicDetailView: View {
    let topic: LearningTopic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(topic.color.opacity(0.12))
                            .frame(width: 56, height: 56)
                        Image(systemName: topic.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(topic.color)
                    }

                    Text(topic.title)
                        .font(.title.weight(.bold))

                    if let example = topic.example {
                        Text(example)
                            .font(.title2)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                    }
                }

                // Body sections
                ForEach(topic.sections.indices, id: \.self) { i in
                    let section = topic.sections[i]
                    VStack(alignment: .leading, spacing: 8) {
                        if let heading = section.heading {
                            Text(heading)
                                .font(.headline)
                        }
                        Text(section.body)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Interactive widget
                if let widget = topic.widget {
                    switch widget {
                    case .alphabetChart:
                        AlphabetChartView()
                    case .keyboardLayout:
                        KeyboardLayoutView()
                    case .niqqudChart:
                        NiqqudChartView()
                    case .gematriaCalculator:
                        GematriaCalculatorView()
                    case .atbashExplorer:
                        AtbashExplorerView()
                    }
                }

                // Links
                if !topic.links.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Learn more")
                            .font(.headline)
                            .padding(.bottom, 2)

                        ForEach(topic.links, id: \.url) { link in
                            Link(destination: URL(string: link.url)!) {
                                HStack(spacing: 8) {
                                    Image(systemName: "book")
                                        .font(.caption)
                                        .foregroundStyle(.accent)
                                    Text(link.title)
                                        .font(.subheadline)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    .padding(16)
                    .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(20)
        }
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Interactive Alphabet Chart

private struct AlphabetChartView: View {
    @State private var selectedLetter: HebrewLetter?

    private let letters = HebrewLetter.all
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tap a letter to explore")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(letters) { letter in
                    Button {
                        withAnimation(.smooth(duration: 0.25)) {
                            selectedLetter = selectedLetter?.id == letter.id ? nil : letter
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Text(String(letter.hebrew))
                                .font(.system(size: 28))
                            Text(letter.name)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selectedLetter?.id == letter.id ? Color.accent.opacity(0.15) : Color(.tertiarySystemFill))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(selectedLetter?.id == letter.id ? Color.accent : .clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Detail card
            if let letter = selectedLetter {
                letterDetailCard(letter)
                    .transition(.blurReplace)
            }

            // Final forms section
            VStack(alignment: .leading, spacing: 10) {
                Text("Final Forms (Sofit)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    ForEach(HebrewLetter.finals) { letter in
                        Button {
                            withAnimation(.smooth(duration: 0.25)) {
                                selectedLetter = selectedLetter?.id == letter.id ? nil : letter
                            }
                        } label: {
                            VStack(spacing: 2) {
                                Text(String(letter.hebrew))
                                    .font(.system(size: 24))
                                Text(letter.name)
                                    .font(.system(size: 7, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 52, height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(selectedLetter?.id == letter.id ? Color.accent.opacity(0.15) : Color(.tertiarySystemFill))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(selectedLetter?.id == letter.id ? Color.accent : .clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
    }

    private func letterDetailCard(_ letter: HebrewLetter) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                // Large letter
                VStack(spacing: 4) {
                    Text(String(letter.hebrew))
                        .font(.system(size: 52))
                    if let paleo = letter.paleo {
                        Text(paleo)
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 80)

                // Info
                VStack(alignment: .leading, spacing: 8) {
                    infoRow("Name", letter.name)
                    infoRow("Pronunciation", letter.pronunciation)
                    infoRow("Position", "#\(letter.position)")
                    infoRow("Gematria", "\(letter.gematriaValue)")
                    if let finalForm = letter.finalForm {
                        infoRow("Final form", String(finalForm))
                    }
                    if letter.isFinal {
                        infoRow("Regular form", String(letter.regularForm!))
                    }
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.caption.weight(.medium))
        }
    }
}

// MARK: - Interactive Keyboard Layout

private struct KeyboardLayoutView: View {
    @State private var highlightedKey: String?

    private let qwertyRow1 = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
    private let qwertyRow2 = ["A", "S", "D", "F", "G", "H", "J", "K", "L", ";"]
    private let qwertyRow3 = ["Z", "X", "C", "V", "B", "N", "M", ",", "."]

    private let keyMap: [String: String] = [
        "Q": "/", "W": "\u{05F3}", "E": "\u{05E7}", "R": "\u{05E8}",
        "T": "\u{05D0}", "Y": "\u{05D8}", "U": "\u{05D5}", "I": "\u{05DF}",
        "O": "\u{05DD}", "P": "\u{05E4}",
        "A": "\u{05E9}", "S": "\u{05D3}", "D": "\u{05D2}", "F": "\u{05DB}",
        "G": "\u{05E2}", "H": "\u{05D9}", "J": "\u{05D7}", "K": "\u{05DC}",
        "L": "\u{05DA}", ";": "\u{05E3}",
        "Z": "\u{05D6}", "X": "\u{05E1}", "C": "\u{05D1}", "V": "\u{05D4}",
        "B": "\u{05E0}", "N": "\u{05DE}", "M": "\u{05E6}", ",": "\u{05EA}",
        ".": "\u{05E5}",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tap a key to see its mapping")
                .font(.headline)

            VStack(spacing: 5) {
                keyboardRow(qwertyRow1, indent: 0)
                keyboardRow(qwertyRow2, indent: 12)
                keyboardRow(qwertyRow3, indent: 30)
            }

            if let key = highlightedKey, let hebrew = keyMap[key] {
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text("English")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(key)
                            .font(.system(size: 32, weight: .semibold, design: .rounded))
                    }

                    Image(systemName: "arrow.right")
                        .font(.title3)
                        .foregroundStyle(.tertiary)

                    VStack(spacing: 2) {
                        Text("Hebrew")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(hebrew)
                            .font(.system(size: 32))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                .transition(.blurReplace)
            }

            Text("The SI 1452 Hebrew keyboard layout is the standard used in Israel. Each QWERTY key maps to a specific Hebrew letter.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
    }

    private func keyboardRow(_ keys: [String], indent: CGFloat) -> some View {
        HStack(spacing: 4) {
            if indent > 0 {
                Spacer().frame(width: indent)
            }
            ForEach(keys, id: \.self) { key in
                Button {
                    withAnimation(.smooth(duration: 0.2)) {
                        highlightedKey = highlightedKey == key ? nil : key
                    }
                } label: {
                    VStack(spacing: 1) {
                        Text(key)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.tertiary)
                        Text(keyMap[key] ?? "")
                            .font(.system(size: 16))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(highlightedKey == key ? Color.accent.opacity(0.15) : Color(.tertiarySystemFill))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(highlightedKey == key ? Color.accent : .clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
            if indent > 0 {
                Spacer().frame(width: indent)
            }
        }
    }
}

// MARK: - Niqqud Chart

private struct NiqqudChartView: View {
    @State private var showWithNiqqud = true

    private let niqqudMarks: [(name: String, mark: String, sound: String, example: String, examplePlain: String)] = [
        ("Patach", "\u{05B7}", "a (as in father)", "\u{05D1}\u{05B7}", "\u{05D1}"),
        ("Kamatz", "\u{05B8}", "a / o", "\u{05D1}\u{05B8}", "\u{05D1}"),
        ("Tsere", "\u{05B5}", "e (as in they)", "\u{05D1}\u{05B5}", "\u{05D1}"),
        ("Segol", "\u{05B6}", "e (as in bed)", "\u{05D1}\u{05B6}", "\u{05D1}"),
        ("Hiriq", "\u{05B4}", "i (as in ski)", "\u{05D1}\u{05B4}", "\u{05D1}"),
        ("Holam", "\u{05B9}", "o (as in go)", "\u{05D1}\u{05B9}", "\u{05D1}"),
        ("Kubutz", "\u{05BB}", "u (as in blue)", "\u{05D1}\u{05BB}", "\u{05D1}"),
        ("Shuruk", "\u{05D5}\u{05BC}", "u (as in blue)", "\u{05D5}\u{05BC}", "\u{05D5}"),
        ("Shva", "\u{05B0}", "brief e / silent", "\u{05D1}\u{05B0}", "\u{05D1}"),
        ("Dagesh", "\u{05BC}", "hardens letter", "\u{05D1}\u{05BC}", "\u{05D1}"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Niqqud Marks")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.smooth) { showWithNiqqud.toggle() }
                } label: {
                    Text(showWithNiqqud ? "With Niqqud" : "Without")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.accent.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            // Example word
            VStack(spacing: 4) {
                Text(showWithNiqqud ? "\u{05E9}\u{05C1}\u{05B8}\u{05DC}\u{05D5}\u{05B9}\u{05DD}" : "\u{05E9}\u{05DC}\u{05D5}\u{05DD}")
                    .font(.system(size: 44))
                    .contentTransition(.interpolate)
                Text("shalom \u{2014} peace / hello")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))

            // Marks grid
            ForEach(niqqudMarks, id: \.name) { mark in
                HStack(spacing: 12) {
                    Text(showWithNiqqud ? mark.example : mark.examplePlain)
                        .font(.system(size: 28))
                        .frame(width: 44)
                        .contentTransition(.interpolate)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(mark.name)
                            .font(.subheadline.weight(.medium))
                        Text(mark.sound)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                if mark.name != niqqudMarks.last?.name {
                    Divider()
                }
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Interactive Gematria Calculator

private struct GematriaCalculatorView: View {
    @State private var input = ""
    @FocusState private var isFocused: Bool

    private var value: Int {
        var sum = 0
        for char in input {
            if let v = CharacterMaps.gematriaValues[char] {
                sum += v
            }
        }
        return sum
    }

    private var breakdown: [(Character, Int)] {
        input.compactMap { char in
            guard let v = CharacterMaps.gematriaValues[char] else { return nil }
            return (char, v)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Try it yourself")
                .font(.headline)

            // Input field
            TextField("Type Hebrew text\u{2026}", text: $input)
                .font(.title2)
                .multilineTextAlignment(.trailing)
                .focused($isFocused)
                .padding(14)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))

            if !input.isEmpty {
                // Result
                VStack(spacing: 4) {
                    Text("\(value)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("Gematria value")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .transition(.blurReplace)

                // Breakdown
                if breakdown.count > 1 {
                    HStack(spacing: 0) {
                        ForEach(breakdown.indices, id: \.self) { i in
                            let item = breakdown[i]
                            VStack(spacing: 2) {
                                Text(String(item.0))
                                    .font(.system(size: 22))
                                Text("\(item.1)")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            if i < breakdown.count - 1 {
                                Text("+")
                                    .font(.caption)
                                    .foregroundStyle(.quaternary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                    .transition(.blurReplace)
                }

                // Well-known values
                let famous = famousGematriaMatch(value)
                if let match = famous {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.accent)
                            .font(.caption)
                        Text(match)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    .transition(.blurReplace)
                }
            }

            // Value table
            VStack(alignment: .leading, spacing: 8) {
                Text("Standard Values")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                let rows: [(String, String, String)] = [
                    ("\u{05D0}=1  \u{05D1}=2  \u{05D2}=3", "\u{05D3}=4  \u{05D4}=5  \u{05D5}=6", "\u{05D6}=7  \u{05D7}=8  \u{05D8}=9"),
                    ("\u{05D9}=10  \u{05DB}=20  \u{05DC}=30", "\u{05DE}=40  \u{05E0}=50  \u{05E1}=60", "\u{05E2}=70  \u{05E4}=80  \u{05E6}=90"),
                    ("\u{05E7}=100  \u{05E8}=200", "\u{05E9}=300  \u{05EA}=400", ""),
                ]

                ForEach(rows.indices, id: \.self) { i in
                    HStack {
                        Text(rows[i].0)
                        Spacer()
                        Text(rows[i].1)
                        if !rows[i].2.isEmpty {
                            Spacer()
                            Text(rows[i].2)
                        }
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
        .animation(.smooth, value: value)
    }

    private func famousGematriaMatch(_ val: Int) -> String? {
        switch val {
        case 18: return "18 = \u{05D7}\u{05D9} (Chai, \"life\") \u{2014} considered a lucky number"
        case 26: return "26 = \u{05D9}\u{05D4}\u{05D5}\u{05D4} (YHVH, the Tetragrammaton)"
        case 36: return "36 = double Chai \u{2014} the 36 righteous (Lamed-Vavniks)"
        case 72: return "72 = \u{05D7}\u{05E1}\u{05D3} (Chesed, \"kindness\")"
        case 86: return "86 = \u{05D0}\u{05DC}\u{05D4}\u{05D9}\u{05DD} (Elohim)"
        case 91: return "91 = \u{05D0}\u{05DE}\u{05DF} (Amen)"
        case 112: return "112 = \u{05D9}\u{05D4}\u{05D5}\u{05D4} + \u{05D0}\u{05DC}\u{05D4}\u{05D9}\u{05DD} (26 + 86)"
        case 137: return "137 = \u{05E7}\u{05D1}\u{05DC}\u{05D4} (Kabbalah)"
        case 248: return "248 = the number of positive commandments"
        case 314: return "314 = \u{05E9}\u{05D3}\u{05D9} (Shaddai, \"Almighty\")"
        case 345: return "345 = \u{05DE}\u{05E9}\u{05D4} (Moshe / Moses)"
        case 358: return "358 = \u{05DE}\u{05E9}\u{05D9}\u{05D7} (Mashiach / Messiah) and also \u{05E0}\u{05D7}\u{05E9} (Nachash, serpent)"
        case 365: return "365 = the number of negative commandments"
        case 541: return "541 = \u{05D9}\u{05E9}\u{05E8}\u{05D0}\u{05DC} (Yisrael / Israel)"
        case 613: return "613 = total number of commandments (mitzvot)"
        default: return nil
        }
    }
}

// MARK: - Atbash Explorer

private struct AtbashExplorerView: View {
    @State private var input = ""
    @FocusState private var isFocused: Bool

    private static let atbashMap: [Character: Character] = {
        let aleph: [Character] = [
            "\u{05D0}", "\u{05D1}", "\u{05D2}", "\u{05D3}", "\u{05D4}",
            "\u{05D5}", "\u{05D6}", "\u{05D7}", "\u{05D8}", "\u{05D9}",
            "\u{05DB}", "\u{05DC}", "\u{05DE}", "\u{05E0}", "\u{05E1}",
            "\u{05E2}", "\u{05E4}", "\u{05E6}", "\u{05E7}", "\u{05E8}",
            "\u{05E9}", "\u{05EA}",
        ]
        var map: [Character: Character] = [:]
        for i in 0..<aleph.count {
            map[aleph[i]] = aleph[aleph.count - 1 - i]
        }
        // Map finals to their atbash of the regular form
        let finals: [Character: Character] = [
            "\u{05DA}": "\u{05DB}", "\u{05DD}": "\u{05DE}",
            "\u{05DF}": "\u{05E0}", "\u{05E3}": "\u{05E4}",
            "\u{05E5}": "\u{05E6}",
        ]
        for (final, regular) in finals {
            if let mapped = map[regular] {
                map[final] = mapped
            }
        }
        return map
    }()

    private var output: String {
        String(input.map { Self.atbashMap[$0] ?? $0 })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Try the Atbash cipher")
                .font(.headline)

            // Input
            TextField("Type Hebrew text\u{2026}", text: $input)
                .font(.title3)
                .multilineTextAlignment(.trailing)
                .focused($isFocused)
                .padding(14)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))

            if !input.isEmpty {
                // Output
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Atbash")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text(output)
                            .font(.title2)
                            .textSelection(.enabled)
                    }
                    Spacer()
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundStyle(.accent)
                }
                .padding(14)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                .transition(.blurReplace)
            }

            // Mapping table
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Mapping")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                let topRow: [Character] = [
                    "\u{05D0}", "\u{05D1}", "\u{05D2}", "\u{05D3}", "\u{05D4}",
                    "\u{05D5}", "\u{05D6}", "\u{05D7}", "\u{05D8}", "\u{05D9}",
                    "\u{05DB}",
                ]
                let bottomRow: [Character] = [
                    "\u{05EA}", "\u{05E9}", "\u{05E8}", "\u{05E7}", "\u{05E6}",
                    "\u{05E4}", "\u{05E2}", "\u{05E1}", "\u{05E0}", "\u{05DE}",
                    "\u{05DC}",
                ]

                HStack(spacing: 0) {
                    ForEach(topRow.indices, id: \.self) { i in
                        VStack(spacing: 4) {
                            Text(String(topRow[i]))
                                .font(.system(size: 18))
                            Image(systemName: "arrow.down")
                                .font(.system(size: 8))
                                .foregroundStyle(.tertiary)
                            Text(String(bottomRow[i]))
                                .font(.system(size: 18))
                                .foregroundStyle(.accent)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 8)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
            }

            Text("\u{05D0}\u{05EA}\u{05D1}\u{05E9} = \u{05D0}-\u{05EA}, \u{05D1}-\u{05E9} \u{2014} the first letter swaps with the last, the second with the second-to-last, and so on.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
        .animation(.smooth, value: output)
    }
}

// MARK: - Hebrew Letter Data

private struct HebrewLetter: Identifiable {
    let id: String
    let hebrew: Character
    let name: String
    let pronunciation: String
    let position: Int
    let gematriaValue: Int
    let paleo: String?
    let finalForm: Character?
    let isFinal: Bool
    let regularForm: Character?

    static let all: [HebrewLetter] = [
        HebrewLetter(id: "aleph", hebrew: "\u{05D0}", name: "Aleph", pronunciation: "Silent / glottal", position: 1, gematriaValue: 1, paleo: "\u{10900}", finalForm: nil, isFinal: false, regularForm: nil),
        HebrewLetter(id: "bet", hebrew: "\u{05D1}", name: "Bet", pronunciation: "B / V", position: 2, gematriaValue: 2, paleo: "\u{10901}", finalForm: nil, isFinal: false, regularForm: nil),
        HebrewLetter(id: "gimel", hebrew: "\u{05D2}", name: "Gimel", pronunciation: "G", position: 3, gematriaValue: 3, paleo: "\u{10902}", finalForm: nil, isFinal: false, regularForm: nil),
        HebrewLetter(id: "dalet", hebrew: "\u{05D3}", name: "Dalet", pronunciation: "D", position: 4, gematriaValue: 4, paleo: "\u{10903}", finalForm: nil, isFinal: false, regularForm: nil),
        HebrewLetter(id: "he", hebrew: "\u{05D4}", name: "He", pronunciation: "H", position: 5, gematriaValue: 5, paleo: "\u{10904}", finalForm: nil, isFinal: false, regularForm: nil),
        HebrewLetter(id: "vav", hebrew: "\u{05D5}", name: "Vav", pronunciation: "V", position: 6, gematriaValue: 6, paleo: "\u{10905}", finalForm: nil, isFinal: false, regularForm: nil),
        HebrewLetter(id: "zayin", hebrew: "\u{05D6}", name: "Zayin", pronunciation: "Z", position: 7, gematriaValue: 7, paleo: "\u{10906}", finalForm: nil, isFinal: false, regularForm: nil),
        HebrewLetter(id: "chet", hebrew: "\u{05D7}", name: "Chet", pronunciation: "Ch (guttural)", position: 8, gematriaValue: 8, paleo: "\u{10907}", finalForm: nil, isFinal: false, regularForm: nil),
        HebrewLetter(id: "tet", hebrew: "\u{05D8}", name: "Tet", pronunciation: "T", position: 9, gematriaValue: 9, paleo: "\u{10908}", finalForm: nil, isFinal: false, regularForm: nil),
        HebrewLetter(id: "yod", hebrew: "\u{05D9}", name: "Yod", pronunciation: "Y", position: 10, gematriaValue: 10, paleo: "\u{10909}", finalForm: nil, isFinal: false, regularForm: nil),
        HebrewLetter(id: "kaf", hebrew: "\u{05DB}", name: "Kaf", pronunciation: "K / Kh", position: 11, gematriaValue: 20, paleo: "\u{1090A}", finalForm: "\u{05DA}", isFinal: false, regularForm: nil),
        HebrewLetter(id: "lamed", hebrew: "\u{05DC}", name: "Lamed", pronunciation: "L", position: 12, gematriaValue: 30, paleo: "\u{1090B}", finalForm: nil, isFinal: false, regularForm: nil),
        HebrewLetter(id: "mem", hebrew: "\u{05DE}", name: "Mem", pronunciation: "M", position: 13, gematriaValue: 40, paleo: "\u{1090C}", finalForm: "\u{05DD}", isFinal: false, regularForm: nil),
        HebrewLetter(id: "nun", hebrew: "\u{05E0}", name: "Nun", pronunciation: "N", position: 14, gematriaValue: 50, paleo: "\u{1090D}", finalForm: "\u{05DF}", isFinal: false, regularForm: nil),
        HebrewLetter(id: "samekh", hebrew: "\u{05E1}", name: "Samekh", pronunciation: "S", position: 15, gematriaValue: 60, paleo: "\u{1090E}", finalForm: nil, isFinal: false, regularForm: nil),
        HebrewLetter(id: "ayin", hebrew: "\u{05E2}", name: "Ayin", pronunciation: "Silent / guttural", position: 16, gematriaValue: 70, paleo: "\u{1090F}", finalForm: nil, isFinal: false, regularForm: nil),
        HebrewLetter(id: "pe", hebrew: "\u{05E4}", name: "Pe", pronunciation: "P / F", position: 17, gematriaValue: 80, paleo: "\u{10910}", finalForm: "\u{05E3}", isFinal: false, regularForm: nil),
        HebrewLetter(id: "tsadi", hebrew: "\u{05E6}", name: "Tsadi", pronunciation: "Ts", position: 18, gematriaValue: 90, paleo: "\u{10911}", finalForm: "\u{05E5}", isFinal: false, regularForm: nil),
        HebrewLetter(id: "qof", hebrew: "\u{05E7}", name: "Qof", pronunciation: "Q / K", position: 19, gematriaValue: 100, paleo: "\u{10912}", finalForm: nil, isFinal: false, regularForm: nil),
        HebrewLetter(id: "resh", hebrew: "\u{05E8}", name: "Resh", pronunciation: "R", position: 20, gematriaValue: 200, paleo: "\u{10913}", finalForm: nil, isFinal: false, regularForm: nil),
        HebrewLetter(id: "shin", hebrew: "\u{05E9}", name: "Shin", pronunciation: "Sh / S", position: 21, gematriaValue: 300, paleo: "\u{10914}", finalForm: nil, isFinal: false, regularForm: nil),
        HebrewLetter(id: "tav", hebrew: "\u{05EA}", name: "Tav", pronunciation: "T", position: 22, gematriaValue: 400, paleo: "\u{10915}", finalForm: nil, isFinal: false, regularForm: nil),
    ]

    static let finals: [HebrewLetter] = [
        HebrewLetter(id: "kaf-sofit", hebrew: "\u{05DA}", name: "Kaf Sofit", pronunciation: "Kh", position: 11, gematriaValue: 20, paleo: "\u{1090A}", finalForm: nil, isFinal: true, regularForm: "\u{05DB}"),
        HebrewLetter(id: "mem-sofit", hebrew: "\u{05DD}", name: "Mem Sofit", pronunciation: "M", position: 13, gematriaValue: 40, paleo: "\u{1090C}", finalForm: nil, isFinal: true, regularForm: "\u{05DE}"),
        HebrewLetter(id: "nun-sofit", hebrew: "\u{05DF}", name: "Nun Sofit", pronunciation: "N", position: 14, gematriaValue: 50, paleo: "\u{1090D}", finalForm: nil, isFinal: true, regularForm: "\u{05E0}"),
        HebrewLetter(id: "pe-sofit", hebrew: "\u{05E3}", name: "Pe Sofit", pronunciation: "F", position: 17, gematriaValue: 80, paleo: "\u{10910}", finalForm: nil, isFinal: true, regularForm: "\u{05E4}"),
        HebrewLetter(id: "tsadi-sofit", hebrew: "\u{05E5}", name: "Tsadi Sofit", pronunciation: "Ts", position: 18, gematriaValue: 90, paleo: "\u{10911}", finalForm: nil, isFinal: true, regularForm: "\u{05E6}"),
    ]
}

// MARK: - Widget Type

enum LearningWidget {
    case alphabetChart
    case keyboardLayout
    case niqqudChart
    case gematriaCalculator
    case atbashExplorer
}

// MARK: - Data Model

struct LearningTopic: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let example: String?
    let sections: [Section]
    let links: [WikiLink]
    let widget: LearningWidget?

    struct Section {
        let heading: String?
        let body: String
    }

    struct WikiLink {
        let title: String
        let url: String
    }
}

// MARK: - Topics

extension LearningTopic {
    static let all: [LearningTopic] = [
        hebrewAlphabet,
        paleoHebrew,
        niqqud,
        gematria,
        keyboardLayouts,
        squareScript,
        textReversal,
        atbash,
    ]

    static let hebrewAlphabet = LearningTopic(
        title: "The Hebrew Alphabet",
        subtitle: "22 letters, 3000+ years of history",
        icon: "character.textbox",
        color: .blue,
        example: "\u{05D0}\u{05D1}\u{05D2}\u{05D3}\u{05D4}\u{05D5}\u{05D6}\u{05D7}\u{05D8}\u{05D9}\u{05DB}\u{05DC}\u{05DE}\u{05E0}\u{05E1}\u{05E2}\u{05E4}\u{05E6}\u{05E7}\u{05E8}\u{05E9}\u{05EA}",
        sections: [
            Section(heading: nil, body: "The Hebrew alphabet (aleph-bet) consists of 22 consonant letters. It is an abjad \u{2014} a writing system where vowels are typically omitted or indicated with optional diacritical marks called niqqud."),
            Section(heading: "Direction", body: "Hebrew is written and read from right to left. The alphabet has been in continuous use for over 3,000 years, making it one of the oldest writing systems still in active use today."),
            Section(heading: "Final Forms", body: "Five Hebrew letters have special forms when they appear at the end of a word: Kaf (\u{05DB}\u{2192}\u{05DA}), Mem (\u{05DE}\u{2192}\u{05DD}), Nun (\u{05E0}\u{2192}\u{05DF}), Pe (\u{05E4}\u{2192}\u{05E3}), and Tsadi (\u{05E6}\u{2192}\u{05E5}). These are called sofit (final) letters."),
        ],
        links: [
            WikiLink(title: "Hebrew alphabet \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Hebrew_alphabet"),
            WikiLink(title: "Abjad writing system", url: "https://en.wikipedia.org/wiki/Abjad"),
        ],
        widget: .alphabetChart
    )

    static let paleoHebrew = LearningTopic(
        title: "Paleo-Hebrew Script",
        subtitle: "The ancient letterforms of Israel",
        icon: "scroll",
        color: .orange,
        example: "\u{10900}\u{10901}\u{10902}\u{10903}\u{10904} \u{2014} \u{05D0}\u{05D1}\u{05D2}\u{05D3}\u{05D4}",
        sections: [
            Section(heading: nil, body: "Paleo-Hebrew (also called Old Hebrew or Phoenician script) is the original script used to write Hebrew from approximately the 10th century BCE. It is closely related to the Phoenician alphabet and is the ancestor of many modern scripts including Greek, Latin, and Arabic."),
            Section(heading: "Historical Use", body: "This script was used during the First Temple period and appears on ancient inscriptions, coins, and seals. The famous Siloam Inscription (circa 701 BCE) and the Gezer Calendar (circa 10th century BCE) are written in Paleo-Hebrew."),
            Section(heading: "In Unicode", body: "Paleo-Hebrew is encoded in the Phoenician block of Unicode (U+10900\u{2013}U+1091F). While it looks very different from modern Hebrew, each letter maps directly to its modern equivalent \u{2014} Aleph (\u{10900}) is \u{05D0}, Bet (\u{10901}) is \u{05D1}, and so on."),
        ],
        links: [
            WikiLink(title: "Paleo-Hebrew alphabet \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Paleo-Hebrew_alphabet"),
            WikiLink(title: "Phoenician alphabet", url: "https://en.wikipedia.org/wiki/Phoenician_alphabet"),
            WikiLink(title: "Siloam inscription", url: "https://en.wikipedia.org/wiki/Siloam_inscription"),
        ],
        widget: nil
    )

    static let niqqud = LearningTopic(
        title: "Niqqud (Vowel Points)",
        subtitle: "How Hebrew marks vowels",
        icon: "eraser",
        color: .purple,
        example: "\u{05E9}\u{05C1}\u{05B8}\u{05DC}\u{05D5}\u{05B9}\u{05DD} \u{2192} \u{05E9}\u{05DC}\u{05D5}\u{05DD}",
        sections: [
            Section(heading: nil, body: "Niqqud is a system of diacritical marks (dots and dashes) placed above or below Hebrew letters to indicate vowel sounds. Since the Hebrew alphabet only represents consonants, niqqud fills in the vowels that readers must otherwise infer from context."),
            Section(heading: "When It\u{2019}s Used", body: "Modern Hebrew text is almost always written without niqqud. Fluent readers infer vowels from context. Niqqud appears mainly in children\u{2019}s books, poetry, liturgical texts, language textbooks, and to disambiguate words that could be read multiple ways."),
            Section(heading: "Stripping Niqqud", body: "The \u{201C}Strip Niqqud\u{201D} tool removes all these diacritical marks, converting fully vocalized text into the standard unpointed form used in everyday writing."),
        ],
        links: [
            WikiLink(title: "Niqqud \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Niqqud"),
            WikiLink(title: "Tiberian vocalization", url: "https://en.wikipedia.org/wiki/Tiberian_vocalization"),
        ],
        widget: .niqqudChart
    )

    static let gematria = LearningTopic(
        title: "Gematria",
        subtitle: "The numerical value of Hebrew words",
        icon: "number",
        color: .accent,
        example: "\u{05D0}=1  \u{05D1}=2  \u{05D2}=3 \u{2026} \u{05E7}=100  \u{05E8}=200",
        sections: [
            Section(heading: nil, body: "Gematria is the practice of assigning numerical values to Hebrew letters and calculating the sum of a word or phrase. Each of the 22 Hebrew letters has a fixed value: Aleph=1, Bet=2, Gimel=3, and so on up to Tav=400."),
            Section(heading: "The Number System", body: "The first 9 letters represent 1\u{2013}9, the next 9 represent 10\u{2013}90, and the final 4 represent 100\u{2013}400. Final letter forms (sofit) typically carry the same value as their non-final counterparts."),
            Section(heading: "Historical Significance", body: "Gematria has been used for thousands of years in Jewish biblical interpretation (hermeneutics). Words or phrases with equal numerical values are considered to have a hidden connection. For example, the Hebrew word for \u{201C}life\u{201D} (\u{05D7}\u{05D9}) equals 18, which is why 18 is considered a lucky number in Jewish tradition."),
        ],
        links: [
            WikiLink(title: "Gematria \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Gematria"),
            WikiLink(title: "Hebrew numerals", url: "https://en.wikipedia.org/wiki/Hebrew_numerals"),
        ],
        widget: .gematriaCalculator
    )

    static let keyboardLayouts = LearningTopic(
        title: "Hebrew Keyboard Layout",
        subtitle: "How QWERTY maps to Hebrew",
        icon: "keyboard",
        color: .teal,
        example: nil,
        sections: [
            Section(heading: nil, body: "The standard Hebrew keyboard layout maps each key on a QWERTY keyboard to a Hebrew letter. When someone types in English while their keyboard is set to Hebrew (or vice versa), the result is gibberish that maps letter-for-letter to the other layout."),
            Section(heading: "A Common Problem", body: "This happens frequently to bilingual typists. You start typing a URL or password and realize your keyboard was set to the wrong language. The \u{201C}To Hebrew\u{201D} and \u{201C}To English\u{201D} tools reverse this mapping, recovering the intended text without retyping."),
        ],
        links: [
            WikiLink(title: "Hebrew keyboard layout \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Hebrew_keyboard"),
            WikiLink(title: "SI 1452 standard", url: "https://en.wikipedia.org/wiki/Hebrew_keyboard#702_layout_(SI_1452)"),
        ],
        widget: .keyboardLayout
    )

    static let squareScript = LearningTopic(
        title: "Square Script (Ktav Ashuri)",
        subtitle: "The modern Hebrew letterforms",
        icon: "character.textbox",
        color: .indigo,
        example: "\u{10900}\u{10901}\u{10902} \u{2192} \u{05D0}\u{05D1}\u{05D2}",
        sections: [
            Section(heading: nil, body: "The \u{201C}square\u{201D} Hebrew script used today is formally known as Ktav Ashuri (\u{201C}Assyrian script\u{201D}). It replaced the older Paleo-Hebrew script after the Babylonian exile in the 6th century BCE, when Jewish scribes adopted the Aramaic square letterforms."),
            Section(heading: "Why \u{201C}Square\u{201D}?", body: "The name comes from the blocky, rectangular shape of the letters. Unlike Paleo-Hebrew\u{2019}s angular, pictographic forms, square script has consistent vertical and horizontal strokes that sit neatly on a baseline."),
            Section(heading: "Sacred Use", body: "Ktav Ashuri is the script used for Torah scrolls, mezuzot, and tefillin. Jewish law (halakha) requires these sacred texts to be written specifically in this script by a trained scribe (sofer)."),
        ],
        links: [
            WikiLink(title: "Hebrew alphabet \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Hebrew_alphabet"),
            WikiLink(title: "Aramaic alphabet", url: "https://en.wikipedia.org/wiki/Aramaic_alphabet"),
        ],
        widget: nil
    )

    static let textReversal = LearningTopic(
        title: "Text Reversal (RTL Fix)",
        subtitle: "Fix Hebrew in non-RTL software",
        icon: "arrow.uturn.left",
        color: .cyan,
        example: "\u{05E9}\u{05DC}\u{05D5}\u{05DD} \u{2192} \u{05DD}\u{05D5}\u{05DC}\u{05E9}",
        sections: [
            Section(heading: nil, body: "Hebrew is a right-to-left language, but many programs don\u{2019}t support RTL text. When you paste Hebrew into these apps, the characters appear in reverse order \u{2014} rendered left-to-right instead of right-to-left. The Reverse tool flips the character order so the text displays correctly in LTR-only software."),
            Section(heading: "The Problem", body: "Software that lacks RTL support ignores the Unicode Bidirectional Algorithm. It treats all text as left-to-right, so the word \u{201C}\u{05E9}\u{05DC}\u{05D5}\u{05DD}\u{201D} (shalom) appears as \u{201C}\u{05DD}\u{05D5}\u{05DC}\u{05E9}\u{201D} \u{2014} the first letter ends up on the left instead of the right. Pre-reversing the text compensates for this: when the software lays it out LTR, it looks correct."),
            Section(heading: "Adobe Creative Suite", body: "This is one of the most common use cases. Adobe apps historically lacked RTL support:\n\n\u{2022} After Effects \u{2014} No RTL until CC 2019, and many templates and plugins still ignore it. Motion designers working with Hebrew titles frequently need text reversal.\n\n\u{2022} Premiere Pro \u{2014} The title tool had no RTL support for years. Basic support arrived in CC 2019 but still has issues with mixed-direction text.\n\n\u{2022} Photoshop & Illustrator \u{2014} RTL requires manually enabling the \u{201C}Middle Eastern\u{201D} text engine in Preferences \u{203A} Type. Many users don\u{2019}t know about this setting.\n\nEven in recent versions, the ME text engine is opt-in, not the default."),
            Section(heading: "Video Editors", body: "DaVinci Resolve is a major offender \u{2014} its text tools have limited or no RTL support even in the latest versions. Hebrew-speaking filmmakers routinely pre-reverse text before pasting it into Resolve titles and subtitles. Vegas Pro and many open-source editors (Shotcut, OpenShot) have the same problem."),
            Section(heading: "Other Software", body: "The RTL problem appears across many categories:\n\n\u{2022} Game engines \u{2014} Unity (legacy UI), older Godot, RPG Maker, GameMaker\n\u{2022} 3D software \u{2014} Cinema 4D text objects, Blender (pre-3.1), 3ds Max\n\u{2022} Subtitles \u{2014} SRT files have no directionality metadata; some players render Hebrew reversed\n\u{2022} LED signage \u{2014} Many sign controllers are LTR-only\n\u{2022} Laser/CNC engraving \u{2014} Label printers and engravers often lack BiDi"),
            Section(heading: "Niqqud-Aware Reversal", body: "A simple character-level reversal would detach niqqud (vowel marks) from their letters, since niqqud are combining Unicode characters that attach to the preceding letter. Aleph Tools reverses text in groups \u{2014} each letter with its attached diacritics stays together \u{2014} so vocalized text reverses correctly."),
        ],
        links: [
            WikiLink(title: "Bidirectional text \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Bidirectional_text"),
            WikiLink(title: "Unicode BiDi Algorithm", url: "https://en.wikipedia.org/wiki/Unicode_bidirectional_algorithm"),
        ],
        widget: nil
    )

    static let atbash = LearningTopic(
        title: "Atbash Cipher",
        subtitle: "Ancient Hebrew letter substitution",
        icon: "lock.rotation",
        color: .mint,
        example: "\u{05D0}\u{2192}\u{05EA}  \u{05D1}\u{2192}\u{05E9}  \u{05D2}\u{2192}\u{05E8}",
        sections: [
            Section(heading: nil, body: "Atbash is one of the oldest known ciphers, originating in Hebrew. It substitutes each letter with its reverse-alphabet counterpart: the first letter (Aleph, \u{05D0}) becomes the last (Tav, \u{05EA}), the second (Bet, \u{05D1}) becomes the second-to-last (Shin, \u{05E9}), and so on."),
            Section(heading: "The Name", body: "The word \u{201C}Atbash\u{201D} (\u{05D0}\u{05EA}\u{05D1}\u{05E9}) itself encodes the pattern: \u{05D0}-\u{05EA} (Aleph-Tav, first swaps with last) and \u{05D1}-\u{05E9} (Bet-Shin, second swaps with second-to-last)."),
            Section(heading: "In the Bible", body: "Atbash appears in the Book of Jeremiah. The word \u{201C}Sheshakh\u{201D} (\u{05E9}\u{05E9}\u{05DA}) is an Atbash cipher for \u{201C}Babel\u{201D} (\u{05D1}\u{05D1}\u{05DC}) \u{2014} \u{05D1} (Bet) becomes \u{05E9} (Shin), and \u{05DC} (Lamed) becomes \u{05DA} (Kaf). This is one of the earliest documented uses of encryption in history."),
            Section(heading: "In Gematria", body: "Atbash is also used as a gematria method. Instead of using a letter\u{2019}s standard numerical value, you substitute it via Atbash first, then calculate the value of the resulting text. This is one of dozens of gematria methods used in traditional biblical interpretation."),
        ],
        links: [
            WikiLink(title: "Atbash \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Atbash"),
            WikiLink(title: "Hebrew cipher methods", url: "https://en.wikipedia.org/wiki/Gematria#Methods"),
        ],
        widget: .atbashExplorer
    )
}
