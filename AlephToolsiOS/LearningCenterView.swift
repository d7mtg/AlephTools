import SwiftUI

// MARK: - Platform Fill Color

private let cardFillColor: Color = {
    #if os(iOS)
    return Color(.secondarySystemGroupedBackground)
    #else
    return Color(.controlBackgroundColor)
    #endif
}()

// MARK: - Shared Grid Cell

private struct LetterGridCell: View {
    let letter: String
    let label: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 3) {
            Text(letter)
                .font(.system(size: 26))
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : cardFillColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Learning Center

struct LearningCenterView: View {
    var body: some View {
        List {
            ForEach(LearningTopic.all) { topic in
                NavigationLink {
                    TopicDetailView(topic: topic)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: topic.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(topic.color.gradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

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
        .navigationTitle(String(localized: "Learning Center"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

// MARK: - Topic Detail

struct TopicDetailView: View {
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

                // Interactive widget FIRST (above text)
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
                    case .paleoAlphabetChart:
                        EmptyView()
                    case .reversalDemo:
                        ReversalDemoView()
                    }
                }

                // Body sections (below widget)
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

                // Links
                if !topic.links.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "Learn more"))
                            .font(.headline)
                            .padding(.bottom, 2)

                        ForEach(topic.links, id: \.url) { link in
                            Link(destination: URL(string: link.url)!) {
                                HStack(spacing: 8) {
                                    Image(systemName: "safari")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
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
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Interactive Alphabet Chart

private struct AlphabetChartView: View {
    @State private var selectedLetter: HebrewLetter?
    @State private var showPaleo = false

    private let letters = HebrewLetter.all
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        VStack(spacing: 12) {
            Picker("", selection: $showPaleo) {
                Text(String(localized: "Modern")).tag(false)
                Text(String(localized: "Paleo-Hebrew")).tag(true)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: showPaleo) { _, _ in
                withAnimation(.smooth(duration: 0.25)) {
                    selectedLetter = nil
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(letters) { letter in
                    letterButton(letter)
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
            .animation(.smooth(duration: 0.3), value: showPaleo)

            if !showPaleo {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Final Forms (Sofit)"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)

                    HStack(spacing: 8) {
                        ForEach(HebrewLetter.finals) { letter in
                            letterButton(letter)
                        }
                    }
                    .environment(\.layoutDirection, .rightToLeft)
                }
            }

            if let letter = selectedLetter {
                letterDetailCard(letter)
                    .transition(.blurReplace)
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
        .animation(.smooth(duration: 0.3), value: showPaleo)
    }

    private func letterButton(_ letter: HebrewLetter) -> some View {
        Button {
            withAnimation(.smooth(duration: 0.25)) {
                selectedLetter = selectedLetter?.id == letter.id ? nil : letter
            }
        } label: {
            LetterGridCell(
                letter: showPaleo ? (letter.paleo ?? String(letter.hebrew)) : String(letter.hebrew),
                label: letter.name,
                isSelected: selectedLetter?.id == letter.id
            )
        }
        .buttonStyle(.plain)
    }

    private func letterDetailCard(_ letter: HebrewLetter) -> some View {
        HStack(spacing: 16) {
            // Modern letter
            VStack(spacing: 4) {
                Text(String(letter.hebrew))
                    .font(.system(size: 48))
                Text(String(localized: "Modern"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(width: 64)

            if let paleo = letter.paleo {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)

                VStack(spacing: 4) {
                    Text(paleo)
                        .font(.system(size: 48))
                    Text(String(localized: "Paleo"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(width: 64)
            }

            Divider()
                .frame(height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(letter.name)
                    .font(.subheadline.weight(.semibold))
                Text(letter.pronunciation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(localized: "Position \(letter.position) \u{00B7} Value \(letter.gematriaValue)"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if let finalForm = letter.finalForm {
                    Text(String(localized: "Final: \(String(finalForm))"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                if letter.isFinal {
                    Text(String(localized: "Standard: \(String(letter.regularForm!))"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
        )
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
            Text(String(localized: "Tap a key to see its Hebrew mapping"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 5) {
                keyboardRow(qwertyRow1, indent: 0)
                keyboardRow(qwertyRow2, indent: 12)
                keyboardRow(qwertyRow3, indent: 30)
            }

            if let key = highlightedKey, let hebrew = keyMap[key] {
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text(String(localized: "English"))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(key)
                            .font(.system(size: 32, weight: .semibold, design: .rounded))
                    }

                    Image(systemName: "arrow.right")
                        .font(.title3)
                        .foregroundStyle(.tertiary)

                    VStack(spacing: 2) {
                        Text(String(localized: "Hebrew"))
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

            Text(String(localized: "The SI 1452 Hebrew keyboard layout is the standard used in Israel. Each QWERTY key maps to a specific Hebrew letter."))
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
                            .fill(highlightedKey == key ? Color.accentColor.opacity(0.15) : cardFillColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(highlightedKey == key ? Color.accentColor : .clear, lineWidth: 1.5)
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
    @State private var selectedIndex: Int?

    private struct NiqqudMark: Identifiable {
        let id: Int
        let name: String
        let mark: String
        let sound: String
        let example: String
        let examplePlain: String
        let group: String
    }

    private let marks: [NiqqudMark] = [
        NiqqudMark(id: 0, name: "Patach", mark: "\u{05B7}", sound: "a", example: "\u{05D1}\u{05B7}", examplePlain: "\u{05D1}", group: "a"),
        NiqqudMark(id: 1, name: "Kamatz", mark: "\u{05B8}", sound: "a / o", example: "\u{05D1}\u{05B8}", examplePlain: "\u{05D1}", group: "a"),
        NiqqudMark(id: 2, name: "Tsere", mark: "\u{05B5}", sound: "e", example: "\u{05D1}\u{05B5}", examplePlain: "\u{05D1}", group: "e"),
        NiqqudMark(id: 3, name: "Segol", mark: "\u{05B6}", sound: "e", example: "\u{05D1}\u{05B6}", examplePlain: "\u{05D1}", group: "e"),
        NiqqudMark(id: 4, name: "Hiriq", mark: "\u{05B4}", sound: "i", example: "\u{05D1}\u{05B4}", examplePlain: "\u{05D1}", group: "i"),
        NiqqudMark(id: 5, name: "Holam", mark: "\u{05B9}", sound: "o", example: "\u{05D1}\u{05B9}", examplePlain: "\u{05D1}", group: "o"),
        NiqqudMark(id: 6, name: "Kubutz", mark: "\u{05BB}", sound: "u", example: "\u{05D1}\u{05BB}", examplePlain: "\u{05D1}", group: "u"),
        NiqqudMark(id: 7, name: "Shuruk", mark: "\u{05D5}\u{05BC}", sound: "u", example: "\u{05D5}\u{05BC}", examplePlain: "\u{05D5}", group: "u"),
        NiqqudMark(id: 8, name: "Shva", mark: "\u{05B0}", sound: "\u{0259}", example: "\u{05D1}\u{05B0}", examplePlain: "\u{05D1}", group: "other"),
        NiqqudMark(id: 9, name: "Dagesh", mark: "\u{05BC}", sound: "\u{2022}", example: "\u{05D1}\u{05BC}", examplePlain: "\u{05D1}", group: "other"),
    ]

    private let sampleLetters = ["\u{05D1}", "\u{05DB}", "\u{05DC}", "\u{05DE}", "\u{05E9}"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        VStack(spacing: 12) {
            // Hero word
            VStack(spacing: 6) {
                Text(showWithNiqqud ? "\u{05E9}\u{05C1}\u{05B8}\u{05DC}\u{05D5}\u{05B9}\u{05DD}" : "\u{05E9}\u{05DC}\u{05D5}\u{05DD}")
                    .font(.system(size: 48))
                    .contentTransition(.interpolate)
                    .animation(.smooth, value: showWithNiqqud)
                Text(String(localized: "shalom"))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)

            Picker("", selection: $showWithNiqqud) {
                Text(String(localized: "With Niqqud")).tag(true)
                Text(String(localized: "Without")).tag(false)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            // Vowel grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(marks) { mark in
                    Button {
                        withAnimation(.smooth(duration: 0.25)) {
                            selectedIndex = selectedIndex == mark.id ? nil : mark.id
                        }
                    } label: {
                        VStack(spacing: 3) {
                            Text(showWithNiqqud ? mark.example : mark.examplePlain)
                                .font(.system(size: 26))
                                .contentTransition(.interpolate)
                            Text(mark.name)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selectedIndex == mark.id ? Color.accentColor.opacity(0.15) : cardFillColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(selectedIndex == mark.id ? Color.accentColor : .clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .animation(.smooth(duration: 0.3), value: showWithNiqqud)

            // Detail card
            if let idx = selectedIndex, let mark = marks.first(where: { $0.id == idx }) {
                niqqudDetailCard(mark)
                    .transition(.blurReplace)
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
    }

    private func niqqudDetailCard(_ mark: NiqqudMark) -> some View {
        VStack(spacing: 12) {
            // Mark info
            HStack(spacing: 16) {
                Text(mark.example)
                    .font(.system(size: 44))
                    .frame(width: 56)

                Divider()
                    .frame(height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mark.name)
                        .font(.subheadline.weight(.semibold))
                    Text(mark.sound == "\u{2022}" ? String(localized: "Hardens the letter") : String(localized: "Sound: \(mark.sound)"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            // Show on sample letters (for combining marks only)
            let isCombining = mark.mark.unicodeScalars.count == 1
            if isCombining {
                HStack(spacing: 0) {
                    ForEach(sampleLetters, id: \.self) { letter in
                        Text(showWithNiqqud ? (letter + mark.mark) : letter)
                            .font(.system(size: 28))
                            .frame(maxWidth: .infinity)
                            .contentTransition(.interpolate)
                    }
                }
                .padding(.vertical, 8)
                .background(cardFillColor, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Interactive Gematria Calculator

private struct GematriaCalculatorView: View {
    @State private var input = ""
    @State private var showGrid = false

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
            Text(String(localized: "Type Hebrew to calculate its value"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            // Input field
            TextField(String(localized: "Type Hebrew text\u{2026}"), text: $input)
                .font(.title2)
                .multilineTextAlignment(.trailing)
                .padding(14)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))

            if !input.isEmpty {
                // Result
                VStack(spacing: 4) {
                    Text("\(value)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text(String(localized: "Gematria value"))
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
                if let match = famousGematriaMatch(value) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                        Text(match)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    .transition(.blurReplace)
                }
            }

            // Collapsible value grid
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation(.smooth) { showGrid.toggle() }
                } label: {
                    HStack {
                        Text(String(localized: "Letter Values"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(showGrid ? 90 : 0))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if showGrid {
                    GematriaGridView()
                        .padding(.top, 12)
                        .transition(.blurReplace)
                }
            }
        }
        .padding(16)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
        .animation(.smooth, value: value)
    }

    private func famousGematriaMatch(_ val: Int) -> String? {
        switch val {
        case 18: return String(localized: "18 = \u{05D7}\u{05D9} (Chai, \"life\") \u{2014} considered a lucky number")
        case 26: return String(localized: "26 = \u{05D9}\u{05D4}\u{05D5}\u{05D4} (YHVH, the Tetragrammaton)")
        case 36: return String(localized: "36 = double Chai \u{2014} the 36 righteous (Lamed-Vavniks)")
        case 72: return String(localized: "72 = \u{05D7}\u{05E1}\u{05D3} (Chesed, \"kindness\")")
        case 86: return String(localized: "86 = \u{05D0}\u{05DC}\u{05D4}\u{05D9}\u{05DD} (Elohim)")
        case 91: return String(localized: "91 = \u{05D0}\u{05DE}\u{05DF} (Amen)")
        case 112: return String(localized: "112 = \u{05D9}\u{05D4}\u{05D5}\u{05D4} + \u{05D0}\u{05DC}\u{05D4}\u{05D9}\u{05DD} (26 + 86)")
        case 137: return String(localized: "137 = \u{05E7}\u{05D1}\u{05DC}\u{05D4} (Kabbalah)")
        case 248: return String(localized: "248 = the number of positive commandments")
        case 314: return String(localized: "314 = \u{05E9}\u{05D3}\u{05D9} (Shaddai, \"Almighty\")")
        case 345: return String(localized: "345 = \u{05DE}\u{05E9}\u{05D4} (Moshe / Moses)")
        case 358: return String(localized: "358 = \u{05DE}\u{05E9}\u{05D9}\u{05D7} (Mashiach / Messiah) and also \u{05E0}\u{05D7}\u{05E9} (Nachash, serpent)")
        case 365: return String(localized: "365 = the number of negative commandments")
        case 541: return String(localized: "541 = \u{05D9}\u{05E9}\u{05E8}\u{05D0}\u{05DC} (Yisrael / Israel)")
        case 613: return String(localized: "613 = total number of commandments (mitzvot)")
        default: return nil
        }
    }
}

// MARK: - Reversal Demo

private struct ReversalDemoView: View {
    @State private var showFixed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "Tap to see the fix"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            // Before/After
            VStack(spacing: 12) {
                // "Broken" app mockup
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Circle().fill(.red).frame(width: 8, height: 8)
                        Circle().fill(.orange).frame(width: 8, height: 8)
                        Circle().fill(.green).frame(width: 8, height: 8)
                        Spacer()
                        Text(showFixed ? String(localized: "After reversal") : String(localized: "Without RTL support"))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)

                    Text(showFixed ? "\u{05E9}\u{05DC}\u{05D5}\u{05DD} \u{05E2}\u{05D5}\u{05DC}\u{05DD}" : "\u{05DD}\u{05DC}\u{05D5}\u{05E2} \u{05DD}\u{05D5}\u{05DC}\u{05E9}")
                        .font(.system(size: 32, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .contentTransition(.interpolate)
                }
                .background(cardFillColor, in: RoundedRectangle(cornerRadius: 10))

                Button {
                    withAnimation(.smooth) { showFixed.toggle() }
                } label: {
                    Label(showFixed ? String(localized: "Show broken") : String(localized: "Fix with reversal"), systemImage: showFixed ? "arrow.uturn.backward" : "arrow.uturn.left")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
            }

            Text(String(localized: "Software like After Effects, DaVinci Resolve, and Premiere Pro renders Hebrew left-to-right, flipping the character order. Pre-reversing the text compensates \u{2014} when the app lays it out LTR, it looks correct."))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Gematria Grid View

private struct GematriaGridView: View {
    private let letters = HebrewLetter.all
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(letters) { letter in
                VStack(spacing: 2) {
                    Text(String(letter.hebrew))
                        .font(.system(size: 24))
                    Text("\(letter.gematriaValue)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(cardFillColor)
                )
            }
        }
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
    case paleoAlphabetChart
    case reversalDemo
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
        niqqud,
        gematria,
        keyboardLayouts,
        textReversal,
    ]

    static let hebrewAlphabet = LearningTopic(
        title: String(localized: "The Hebrew Alphabet"),
        subtitle: String(localized: "22 letters, from ancient script to modern"),
        icon: "character.textbox",
        color: .blue,
        example: "\u{05D0}\u{05D1}\u{05D2}\u{05D3}\u{05D4}\u{05D5}\u{05D6}\u{05D7}\u{05D8}\u{05D9}\u{05DB}\u{05DC}\u{05DE}\u{05E0}\u{05E1}\u{05E2}\u{05E4}\u{05E6}\u{05E7}\u{05E8}\u{05E9}\u{05EA}",
        sections: [
            Section(heading: nil, body: String(localized: "The Hebrew alphabet (aleph-bet) consists of 22 consonant letters. It is an abjad \u{2014} a writing system where vowels are typically omitted or indicated with optional diacritical marks called niqqud. Hebrew is written and read from right to left and has been in continuous use for over 3,000 years, making it one of the oldest writing systems still in active use today.")),
            Section(heading: String(localized: "Final Forms"), body: String(localized: "Five Hebrew letters have special forms when they appear at the end of a word: Kaf (\u{05DB}\u{2192}\u{05DA}), Mem (\u{05DE}\u{2192}\u{05DD}), Nun (\u{05E0}\u{2192}\u{05DF}), Pe (\u{05E4}\u{2192}\u{05E3}), and Tsadi (\u{05E6}\u{2192}\u{05E5}). These are called sofit (final) letters.")),
            Section(heading: String(localized: "Paleo-Hebrew: The Original Script"), body: String(localized: "Paleo-Hebrew (also called Old Hebrew script) is the original script used to write Hebrew from approximately the 10th century BCE. Closely related to the Phoenician alphabet, it is the ancestor of many modern writing systems including Greek, Latin, and Arabic. Each of the 22 Paleo-Hebrew letters maps directly to its modern square Hebrew equivalent. Use the Paleo-Hebrew toggle in the chart above to see the ancient letterforms.")),
            Section(heading: String(localized: "The Siloam Inscription"), body: String(localized: "Discovered in 1880 in Hezekiah\u{2019}s Tunnel in Jerusalem, the Siloam Inscription (circa 701 BCE) describes the moment two teams of tunnelers met underground. It is one of the oldest known Hebrew inscriptions and is written entirely in Paleo-Hebrew. The original is in the Istanbul Archaeology Museum.")),
            Section(heading: String(localized: "The Tel Dan Stele"), body: String(localized: "Found in 1993 in northern Israel, the Tel Dan Stele is a 9th-century BCE Aramaic inscription that contains the earliest known reference to the \u{201C}House of David\u{201D} outside the Bible. While written in Aramaic, it uses a script closely related to Paleo-Hebrew and is a landmark find for biblical archaeology.")),
            Section(heading: String(localized: "Paleo-Hebrew on Coins"), body: String(localized: "Paleo-Hebrew experienced a deliberate revival on Jewish coinage as a national symbol:\n\n\u{2022} Hasmonean coins (2nd\u{2013}1st century BCE) \u{2014} The Maccabees minted coins with Paleo-Hebrew legends like \u{201C}Yehonatan the King\u{201D} and \u{201C}Yehudah the High Priest,\u{201D} asserting continuity with ancient Israelite sovereignty.\n\n\u{2022} Bar Kokhba revolt coins (132\u{2013}136 CE) \u{2014} Simon bar Kokhba\u{2019}s rebels overstruck Roman coins with Paleo-Hebrew inscriptions reading \u{201C}For the Freedom of Jerusalem\u{201D} and \u{201C}Year One of the Redemption of Israel.\u{201D} These are among the last widespread uses of the script.")),
            Section(heading: String(localized: "Square Script (Ktav Ashuri)"), body: String(localized: "The modern Hebrew letterforms are formally known as Ktav Ashuri (\u{201C}Assyrian script\u{201D}). After the Babylonian exile in the 6th century BCE, Jewish scribes gradually adopted the Aramaic square letterforms in place of the older Paleo-Hebrew script. The name comes from the blocky, rectangular shape of the letters \u{2014} consistent vertical and horizontal strokes that sit neatly on a baseline, well-suited for scribal copying. By the Second Temple period, square script had become the standard for everyday writing.")),
            Section(heading: String(localized: "Sacred Use"), body: String(localized: "Ktav Ashuri is the script required for Torah scrolls, mezuzot, and tefillin. Jewish law (halakha) specifies that these sacred texts must be written in this script by a trained scribe (sofer). The Talmud (Sanhedrin 21b\u{2013}22a) records a debate about whether the Torah was originally given in Ktav Ashuri or Paleo-Hebrew, reflecting the historical transition between the two scripts.")),
            Section(heading: String(localized: "In Unicode"), body: String(localized: "Paleo-Hebrew is encoded in the Phoenician block of Unicode (U+10900\u{2013}U+1091F). These are Supplementary Multilingual Plane characters, so font and rendering support varies across devices. AlephTools handles the mapping internally for reliable conversion.")),
        ],
        links: [
            WikiLink(title: "Hebrew alphabet \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Hebrew_alphabet"),
            WikiLink(title: "Paleo-Hebrew alphabet \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Paleo-Hebrew_alphabet"),
            WikiLink(title: "Abjad writing system", url: "https://en.wikipedia.org/wiki/Abjad"),
            WikiLink(title: "Aramaic alphabet", url: "https://en.wikipedia.org/wiki/Aramaic_alphabet"),
            WikiLink(title: "Siloam inscription \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Siloam_inscription"),
            WikiLink(title: "Tel Dan stele \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Tel_Dan_stele"),
            WikiLink(title: "Bar Kokhba coinage \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Bar_Kokhba_revolt_coinage"),
        ],
        widget: .alphabetChart
    )

    static let niqqud = LearningTopic(
        title: String(localized: "Niqqud (Vowel Points)"),
        subtitle: String(localized: "How Hebrew marks vowels"),
        icon: "eraser",
        color: .purple,
        example: "\u{05E9}\u{05C1}\u{05B8}\u{05DC}\u{05D5}\u{05B9}\u{05DD} \u{2192} \u{05E9}\u{05DC}\u{05D5}\u{05DD}",
        sections: [
            Section(heading: nil, body: String(localized: "Niqqud is a system of diacritical marks (dots and dashes) placed above or below Hebrew letters to indicate vowel sounds. Since the Hebrew alphabet only represents consonants, niqqud fills in the vowels that readers must otherwise infer from context.")),
            Section(heading: String(localized: "When It\u{2019}s Used"), body: String(localized: "Modern Hebrew text is almost always written without niqqud. Fluent readers infer vowels from context. Niqqud appears mainly in children\u{2019}s books, poetry, liturgical texts, language textbooks, and to disambiguate words that could be read multiple ways.")),
            Section(heading: String(localized: "Stripping Niqqud"), body: String(localized: "The \u{201C}Strip Niqqud\u{201D} tool removes all these diacritical marks, converting fully vocalized text into the standard unpointed form used in everyday writing.")),
        ],
        links: [
            WikiLink(title: "Niqqud \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Niqqud"),
            WikiLink(title: "Tiberian vocalization", url: "https://en.wikipedia.org/wiki/Tiberian_vocalization"),
        ],
        widget: .niqqudChart
    )

    static let gematria = LearningTopic(
        title: String(localized: "Gematria"),
        subtitle: String(localized: "The numerical value of Hebrew words"),
        icon: "number",
        color: .indigo,
        example: "\u{05D0}=1  \u{05D1}=2  \u{05D2}=3 \u{2026} \u{05E7}=100  \u{05E8}=200",
        sections: [
            Section(heading: nil, body: String(localized: "Gematria is the practice of assigning numerical values to Hebrew letters and calculating the sum of a word or phrase. Each of the 22 Hebrew letters has a fixed value: Aleph=1, Bet=2, Gimel=3, and so on up to Tav=400.")),
            Section(heading: String(localized: "The Number System"), body: String(localized: "The first 9 letters represent 1\u{2013}9, the next 9 represent 10\u{2013}90, and the final 4 represent 100\u{2013}400. Final letter forms (sofit) typically carry the same value as their non-final counterparts.")),
            Section(heading: String(localized: "Historical Significance"), body: String(localized: "Gematria has been used for thousands of years in Jewish biblical interpretation (hermeneutics). Words or phrases with equal numerical values are considered to have a hidden connection. For example, the Hebrew word for \u{201C}life\u{201D} (\u{05D7}\u{05D9}) equals 18, which is why 18 is considered a lucky number in Jewish tradition.")),
        ],
        links: [
            WikiLink(title: "Gematria \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Gematria"),
            WikiLink(title: "Hebrew numerals", url: "https://en.wikipedia.org/wiki/Hebrew_numerals"),
        ],
        widget: .gematriaCalculator
    )

    static let keyboardLayouts: LearningTopic = {
        var sections = [
            Section(heading: nil, body: String(localized: "The standard Hebrew keyboard layout maps each key on a QWERTY keyboard to a Hebrew letter. When someone types in English while their keyboard is set to Hebrew (or vice versa), the result is gibberish that maps letter-for-letter to the other layout.")),
            Section(heading: String(localized: "A Common Problem"), body: String(localized: "This happens frequently to bilingual typists. You start typing a URL or password and realize your keyboard was set to the wrong language. The \u{201C}To Hebrew\u{201D} and \u{201C}To English\u{201D} tools reverse this mapping, recovering the intended text without retyping.")),
        ]
        #if os(iOS)
        sections.append(Section(heading: String(localized: "Adding a Hebrew Keyboard"), body: String(localized: "To install a Hebrew keyboard on iOS:\n\n1. Open Settings\n2. Go to General \u{203A} Keyboard \u{203A} Keyboards\n3. Tap Add New Keyboard\u{2026}\n4. Select Hebrew\n\nOnce added, tap the globe icon on your keyboard to switch between English and Hebrew.")))
        #else
        sections.append(Section(heading: String(localized: "Adding a Hebrew Keyboard"), body: String(localized: "To add a Hebrew keyboard on macOS:\n\n1. Open System Settings\n2. Go to Keyboard \u{203A} Input Sources\n3. Click the + button\n4. Search for and add Hebrew\n\nUse the input menu in the menu bar (or press Control+Space) to switch layouts. With the Hebrew layout active, each key press shows the Hebrew mapping \u{2014} try the interactive widget above to preview it.")))
        #endif
        return LearningTopic(
            title: String(localized: "Hebrew Keyboard Layout"),
            subtitle: String(localized: "How QWERTY maps to Hebrew"),
            icon: "keyboard",
            color: .teal,
            example: nil,
            sections: sections,
            links: [
                WikiLink(title: "Hebrew keyboard layout \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Hebrew_keyboard"),
                WikiLink(title: "SI 1452 standard", url: "https://en.wikipedia.org/wiki/Hebrew_keyboard#702_layout_(SI_1452)"),
            ],
            widget: .keyboardLayout
        )
    }()

    static let textReversal = LearningTopic(
        title: String(localized: "Text Reversal (RTL Fix)"),
        subtitle: String(localized: "Fix Hebrew in non-RTL software"),
        icon: "arrow.uturn.left",
        color: .cyan,
        example: "\u{05E9}\u{05DC}\u{05D5}\u{05DD} \u{2192} \u{05DD}\u{05D5}\u{05DC}\u{05E9}",
        sections: [
            Section(heading: nil, body: String(localized: "Hebrew is a right-to-left language, but many programs don\u{2019}t support RTL text. When you paste Hebrew into these apps, the characters appear in reverse order \u{2014} rendered left-to-right instead of right-to-left. The Reverse tool flips the character order so the text displays correctly in LTR-only software.")),
            Section(heading: String(localized: "Fixing Adobe Apps (Tomech Ivrit)"), body: String(localized: "Adobe apps can support Hebrew natively, but the Middle Eastern text engine isn\u{2019}t installed by default. To enable it:\n\n1. Open the Creative Cloud desktop app\n2. Go to Preferences \u{203A} Apps\n3. Under the \u{201C}Installing\u{201D} section, change the language/text engine to \u{201C}Tomech Ivrit\u{201D} (Hebrew support)\n4. Uninstall the Adobe apps you use (After Effects, Premiere Pro, Photoshop, Illustrator, etc.)\n5. Reinstall them from Creative Cloud\n\nThe reinstalled apps will include the Middle Eastern text engine by default, giving you proper RTL text, correct character joining, and bidirectional support without needing to pre-reverse text.")),
            Section(heading: String(localized: "Video Editors"), body: String(localized: "DaVinci Resolve is a major offender \u{2014} its text tools have limited or no RTL support even in the latest versions. Hebrew-speaking filmmakers routinely pre-reverse text before pasting it into Resolve titles and subtitles. Vegas Pro and many open-source editors (Shotcut, OpenShot) have the same problem.")),
            Section(heading: String(localized: "Other Software"), body: String(localized: "The RTL problem appears across many categories:\n\n\u{2022} Game engines \u{2014} Unity (legacy UI), older Godot, RPG Maker, GameMaker\n\u{2022} 3D software \u{2014} Cinema 4D text objects, Blender (pre-3.1), 3ds Max\n\u{2022} Subtitles \u{2014} SRT files have no directionality metadata; some players render Hebrew reversed\n\u{2022} LED signage \u{2014} Many sign controllers are LTR-only\n\u{2022} Laser/CNC engraving \u{2014} Label printers and engravers often lack BiDi")),
            Section(heading: String(localized: "Niqqud-Aware Reversal"), body: String(localized: "A simple character-level reversal would detach niqqud (vowel marks) from their letters, since niqqud are combining Unicode characters that attach to the preceding letter. Aleph Tools reverses text in groups \u{2014} each letter with its attached diacritics stays together \u{2014} so vocalized text reverses correctly.")),
        ],
        links: [
            WikiLink(title: "Bidirectional text \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Bidirectional_text"),
            WikiLink(title: "Unicode BiDi Algorithm", url: "https://en.wikipedia.org/wiki/Unicode_bidirectional_algorithm"),
        ],
        widget: .reversalDemo
    )

}
