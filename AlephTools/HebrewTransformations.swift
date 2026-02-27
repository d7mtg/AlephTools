import Foundation

// MARK: - Transformation Type

enum TransformationType: String, CaseIterable, Identifiable {
    case hebrewKeyboard = "To Hebrew"
    case englishKeyboard = "To English"
    case removeNiqqud = "Strip Niqqud"
    case squareHebrew = "To Modern"
    case paleoHebrew = "To Paleo"
    case gematria = "Gematria"
    case reverse = "Reverse"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .hebrewKeyboard: "QWERTY \u{2192} \u{05E7}\u{05E8}\u{05D0}\u{05D8}\u{05D5}\u{05DF}"
        case .englishKeyboard: "\u{05E7}\u{05E8}\u{05D0}\u{05D8}\u{05D5}\u{05DF} \u{2192} QWERTY"
        case .removeNiqqud: "Strip vowel points & diacritics"
        case .squareHebrew: "\u{10900}\u{10901}\u{10902} \u{2192} \u{05D0}\u{05D1}\u{05D2}"
        case .paleoHebrew: "\u{05D0}\u{05D1}\u{05D2} \u{2192} \u{10900}\u{10901}\u{10902}"
        case .gematria: "Numerological value"
        case .reverse: "Mirror text, keep Niqqud"
        }
    }

    var icon: String {
        switch self {
        case .hebrewKeyboard: "keyboard"
        case .englishKeyboard: "globe"
        case .removeNiqqud: "eraser"
        case .squareHebrew: "character.textbox"
        case .paleoHebrew: "scroll"
        case .gematria: "number"
        case .reverse: "arrow.left.arrow.right"
        }
    }

    var supportsPunctuationToggle: Bool {
        self == .hebrewKeyboard || self == .englishKeyboard
    }
}

// MARK: - Character Maps

enum CharacterMaps {

    // MARK: Hebrew ↔ Paleo-Hebrew

    static let hebrewToPaleo: [Character: String] = [
        "א": "\u{10900}", "ב": "\u{10901}", "ג": "\u{10902}", "ד": "\u{10903}",
        "ה": "\u{10904}", "ו": "\u{10905}", "ז": "\u{10906}", "ח": "\u{10907}",
        "ט": "\u{10908}", "י": "\u{10909}", "כ": "\u{1090A}", "ל": "\u{1090B}",
        "מ": "\u{1090C}", "נ": "\u{1090D}", "ס": "\u{1090E}", "ע": "\u{1090F}",
        "פ": "\u{10910}", "צ": "\u{10911}", "ק": "\u{10912}", "ר": "\u{10913}",
        "ש": "\u{10914}", "ת": "\u{10915}",
        // Final forms map to same Paleo characters
        "ך": "\u{1090A}", "ם": "\u{1090C}", "ן": "\u{1090D}",
        "ף": "\u{10910}", "ץ": "\u{10911}",
    ]

    static let paleoToHebrew: [String: Character] = {
        // Invert, preferring regular forms over finals
        var map: [String: Character] = [:]
        // First add finals so regulars overwrite them
        for (hebrew, paleo) in hebrewToPaleo {
            map[paleo] = hebrew
        }
        // Overwrite with regular forms
        let regulars: [Character: String] = [
            "כ": "\u{1090A}", "מ": "\u{1090C}", "נ": "\u{1090D}",
            "פ": "\u{10910}", "צ": "\u{10911}",
        ]
        for (hebrew, paleo) in regulars {
            map[paleo] = hebrew
        }
        return map
    }()

    // MARK: Final ↔ Regular form normalization

    static let finalToRegular: [Character: Character] = [
        "ך": "כ", "ם": "מ", "ן": "נ", "ף": "פ", "ץ": "צ",
    ]

    // MARK: Hebrew ↔ English Keyboard

    static let hebrewToEnglish: [Character: Character] = [
        "/": "q", "׳": "w", "ק": "e", "ר": "r", "א": "t",
        "ט": "y", "ו": "u", "ן": "i", "ם": "o", "פ": "p",
        "ש": "a", "ד": "s", "ג": "d", "כ": "f", "ע": "g",
        "י": "h", "ח": "j", "ל": "k", "ך": "l", "ף": ";",
        "ז": "z", "ס": "x", "ב": "c", "ה": "v", "נ": "b",
        "מ": "n", "צ": "m", "ת": ",", "ץ": ".",
        ",": "<", ".": ">",
        "'": "\"", "\"": "'",
        "(": ")", ")": "(",
        " ": " ", "\n": "\n",
    ]

    static let englishToHebrew: [Character: Character] = {
        var map: [Character: Character] = [
            "q": "/", "w": "׳", "e": "ק", "r": "ר", "t": "א",
            "y": "ט", "u": "ו", "i": "ן", "o": "ם", "p": "פ",
            "a": "ש", "s": "ד", "d": "ג", "f": "כ", "g": "ע",
            "h": "י", "j": "ח", "k": "ל", "l": "ך", ";": "ף",
            "z": "ז", "x": "ס", "c": "ב", "v": "ה", "b": "נ",
            "n": "מ", "m": "צ", ",": "ת", ".": "ץ",
            "<": ",", ">": ".",
            "'": ",", "\"": "\"",
            "(": ")", ")": "(",
            " ": " ", "\n": "\n",
        ]
        // Add uppercase mappings
        for key in "abcdefghijklmnopqrstuvwxyz" {
            if let val = map[key] {
                map[Character(key.uppercased())] = val
            }
        }
        return map
    }()

    // MARK: Gematria

    static let gematriaValues: [Character: Int] = [
        "א": 1, "ב": 2, "ג": 3, "ד": 4, "ה": 5,
        "ו": 6, "ז": 7, "ח": 8, "ט": 9, "י": 10,
        "כ": 20, "ל": 30, "מ": 40, "נ": 50, "ס": 60,
        "ע": 70, "פ": 80, "צ": 90, "ק": 100, "ר": 200,
        "ש": 300, "ת": 400,
        // Finals have same values
        "ך": 20, "ם": 40, "ן": 50, "ף": 80, "ץ": 90,
    ]

    // MARK: Punctuation

    static let preservedPunctuation: Set<Character> = ["\"", "'", ",", "."]
}

// MARK: - Niqqud Utilities

enum NiqqudUtils {
    /// Unicode range U+0591 through U+05C7
    static func isNiqqud(_ scalar: Unicode.Scalar) -> Bool {
        scalar.value >= 0x0591 && scalar.value <= 0x05C7
    }

    static func isNiqqud(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first, char.unicodeScalars.count == 1 else { return false }
        return isNiqqud(scalar)
    }

    static func isHebrewLetter(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        return scalar.value >= 0x05D0 && scalar.value <= 0x05EA
    }

    static func removeNiqqud(_ text: String) -> String {
        String(text.unicodeScalars.filter { !isNiqqud($0) })
    }
}

// MARK: - Transformation Engine

enum TransformationEngine {

    static func transform(_ text: String, mode: TransformationType, keepPunctuation: Bool) -> String {
        switch mode {
        case .hebrewKeyboard: toHebrewKeyboard(text, keepPunctuation: keepPunctuation)
        case .englishKeyboard: toEnglishKeyboard(text, keepPunctuation: keepPunctuation)
        case .removeNiqqud: NiqqudUtils.removeNiqqud(text)
        case .squareHebrew: paleoToSquare(text)
        case .paleoHebrew: toPaleoHebrew(text)
        case .gematria: toGematria(text)
        case .reverse: reverseWithNiqqud(text)
        }
    }

    // MARK: Hebrew Keyboard (English → Hebrew)

    static func toHebrewKeyboard(_ text: String, keepPunctuation: Bool) -> String {
        String(text.map { ch in
            if keepPunctuation && CharacterMaps.preservedPunctuation.contains(ch) {
                return ch
            }
            return CharacterMaps.englishToHebrew[ch] ?? ch
        })
    }

    // MARK: English Keyboard (Hebrew → English)

    static func toEnglishKeyboard(_ text: String, keepPunctuation: Bool) -> String {
        let stripped = NiqqudUtils.removeNiqqud(text)
        return String(stripped.map { ch in
            if keepPunctuation && CharacterMaps.preservedPunctuation.contains(ch) {
                return ch
            }
            return CharacterMaps.hebrewToEnglish[ch] ?? ch
        })
    }

    // MARK: Paleo-Hebrew (Modern → Ancient)

    static func toPaleoHebrew(_ text: String) -> String {
        let stripped = NiqqudUtils.removeNiqqud(text)
        return stripped.map { ch in
            CharacterMaps.hebrewToPaleo[ch] ?? String(ch)
        }.joined()
    }

    // MARK: Square Hebrew (Paleo → Modern)

    static func paleoToSquare(_ text: String) -> String {
        // Use unicodeScalars for proper SMP character handling
        var result = ""
        var iterator = text.unicodeScalars.makeIterator()
        var buffer: [Unicode.Scalar] = []

        while let scalar = iterator.next() {
            buffer.append(scalar)
            // Check if we have a complete character
            let str = String(String.UnicodeScalarView(buffer))
            if let char = str.first, str.count == 1 {
                buffer.removeAll()
                let paleoStr = String(char)
                if let hebrewChar = CharacterMaps.paleoToHebrew[paleoStr] {
                    // Normalize final forms to regular
                    let normalized = CharacterMaps.finalToRegular[hebrewChar] ?? hebrewChar
                    result.append(normalized)
                } else {
                    result.append(char)
                }
            }
        }
        return result
    }

    // MARK: Gematria

    static func toGematria(_ text: String) -> String {
        var sum = 0
        for char in text {
            if let value = CharacterMaps.gematriaValues[char] {
                sum += value
            }
        }
        return String(sum)
    }

    // MARK: Reverse (Niqqud-aware)

    static func reverseWithNiqqud(_ text: String) -> String {
        text.split(separator: "\n", omittingEmptySubsequences: false)
            .map { reverseLinePreservingNiqqud(String($0)) }
            .joined(separator: "\n")
    }

    private static func reverseLinePreservingNiqqud(_ line: String) -> String {
        var groups: [String] = []
        var currentGroup = ""

        for char in line {
            if NiqqudUtils.isNiqqud(char) {
                currentGroup.append(char)
            } else {
                if !currentGroup.isEmpty {
                    groups.append(currentGroup)
                }
                currentGroup = String(char)
            }
        }
        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }

        return groups.reversed().joined()
    }
}

// MARK: - Change Stats

struct ChangeStats {
    let changed: Int
    let unchanged: Int

    static func compute(input: String, output: String, mode: TransformationType) -> ChangeStats {
        switch mode {
        case .gematria:
            let hebrewCount = input.filter { NiqqudUtils.isHebrewLetter($0) }.count
            return ChangeStats(changed: hebrewCount, unchanged: 0)

        case .removeNiqqud:
            let niqqudCount = input.unicodeScalars.filter { NiqqudUtils.isNiqqud($0) }.count
            let nonSpaceCount = input.filter { $0 != " " }.count
            return ChangeStats(changed: niqqudCount, unchanged: nonSpaceCount - niqqudCount)

        default:
            let inputChars = Array(input.filter { $0 != " " })
            let outputChars = Array(output.filter { $0 != " " })
            var changed = 0
            var unchanged = 0
            let minLen = min(inputChars.count, outputChars.count)

            for i in 0..<minLen {
                if inputChars[i] == outputChars[i] {
                    unchanged += 1
                } else {
                    changed += 1
                }
            }
            changed += abs(inputChars.count - outputChars.count)
            return ChangeStats(changed: changed, unchanged: unchanged)
        }
    }
}
