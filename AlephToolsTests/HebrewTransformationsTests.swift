import XCTest
@testable import Aleph_Tools

final class HebrewTransformationsTests: XCTestCase {

    // MARK: - Hebrew Keyboard (English → Hebrew)

    func testHebrewKeyboardBasicMapping() {
        let result = TransformationEngine.toHebrewKeyboard("kvuzv", keepPunctuation: false)
        XCTAssertEqual(result, "להוזה")
    }

    func testHebrewKeyboardFullSentence() {
        // "ard" → "שרג" (right-to-left doesn't affect character mapping)
        let result = TransformationEngine.toHebrewKeyboard("ard", keepPunctuation: false)
        XCTAssertEqual(result, "שרג")
    }

    func testHebrewKeyboardUppercaseMapsLikeLowercase() {
        let lower = TransformationEngine.toHebrewKeyboard("abc", keepPunctuation: false)
        let upper = TransformationEngine.toHebrewKeyboard("ABC", keepPunctuation: false)
        XCTAssertEqual(lower, upper)
    }

    func testHebrewKeyboardPreservesPunctuation() {
        let result = TransformationEngine.toHebrewKeyboard("hello, world.", keepPunctuation: true)
        XCTAssertTrue(result.contains(","))
        XCTAssertTrue(result.contains("."))
    }

    func testHebrewKeyboardPunctuationNotPreserved() {
        let withPunc = TransformationEngine.toHebrewKeyboard(",", keepPunctuation: true)
        let withoutPunc = TransformationEngine.toHebrewKeyboard(",", keepPunctuation: false)
        XCTAssertEqual(withPunc, ",")
        XCTAssertEqual(withoutPunc, "ת")
    }

    func testHebrewKeyboardSpacesAndNewlines() {
        let result = TransformationEngine.toHebrewKeyboard("a b\nc", keepPunctuation: false)
        XCTAssertEqual(result, "ש נ\nב")
    }

    func testHebrewKeyboardUnmappedCharactersPassThrough() {
        let result = TransformationEngine.toHebrewKeyboard("123", keepPunctuation: false)
        XCTAssertEqual(result, "123")
    }

    func testHebrewKeyboardEmptyString() {
        let result = TransformationEngine.toHebrewKeyboard("", keepPunctuation: false)
        XCTAssertEqual(result, "")
    }

    // MARK: - English Keyboard (Hebrew → English)

    func testEnglishKeyboardBasicMapping() {
        let result = TransformationEngine.toEnglishKeyboard("שלום", keepPunctuation: false)
        XCTAssertEqual(result, "akuo")
    }

    func testEnglishKeyboardStripsNiqqudFirst() {
        // שָׁלוֹם (shalom with niqqud) → same as שלום
        let withNiqqud = "שָׁלוֹם"
        let withoutNiqqud = "שלום"
        let resultWith = TransformationEngine.toEnglishKeyboard(withNiqqud, keepPunctuation: false)
        let resultWithout = TransformationEngine.toEnglishKeyboard(withoutNiqqud, keepPunctuation: false)
        XCTAssertEqual(resultWith, resultWithout)
    }

    func testEnglishKeyboardPreservesPunctuation() {
        let result = TransformationEngine.toEnglishKeyboard("שלום, עולם.", keepPunctuation: true)
        XCTAssertTrue(result.contains(","))
        XCTAssertTrue(result.contains("."))
    }

    func testEnglishKeyboardFinalLetters() {
        // ך → l, ם → o, ן → i, ף → ;, ץ → .
        let result = TransformationEngine.toEnglishKeyboard("ך", keepPunctuation: false)
        XCTAssertEqual(result, "l")
        XCTAssertEqual(TransformationEngine.toEnglishKeyboard("ם", keepPunctuation: false), "o")
        XCTAssertEqual(TransformationEngine.toEnglishKeyboard("ן", keepPunctuation: false), "i")
    }

    func testEnglishKeyboardEmptyString() {
        let result = TransformationEngine.toEnglishKeyboard("", keepPunctuation: false)
        XCTAssertEqual(result, "")
    }

    // MARK: - Round-Trip: Hebrew ↔ English Keyboard

    func testRoundTripEnglishToHebrewAndBack() {
        let original = "abcdefghvnm"
        let hebrew = TransformationEngine.toHebrewKeyboard(original, keepPunctuation: false)
        let backToEnglish = TransformationEngine.toEnglishKeyboard(hebrew, keepPunctuation: false)
        XCTAssertEqual(backToEnglish, original)
    }

    // MARK: - Paleo-Hebrew (Modern → Ancient)

    func testPaleoHebrewBasicConversion() {
        let result = TransformationEngine.toPaleoHebrew("אבג")
        XCTAssertEqual(result, "\u{10900}\u{10901}\u{10902}")
    }

    func testPaleoHebrewFullAlphabet() {
        let modern = "אבגדהוזחטיכלמנסעפצקרשת"
        let result = TransformationEngine.toPaleoHebrew(modern)
        // Each letter should map to a Paleo character in U+10900–U+10915
        for scalar in result.unicodeScalars {
            if scalar.value > 127 { // skip any ASCII
                XCTAssertTrue(
                    scalar.value >= 0x10900 && scalar.value <= 0x10915,
                    "Expected Paleo-Hebrew range, got U+\(String(scalar.value, radix: 16, uppercase: true))"
                )
            }
        }
    }

    func testPaleoHebrewFinalFormsMapCorrectly() {
        // Final forms should map to same Paleo character as regular form
        XCTAssertEqual(
            TransformationEngine.toPaleoHebrew("כ"),
            TransformationEngine.toPaleoHebrew("ך")
        )
        XCTAssertEqual(
            TransformationEngine.toPaleoHebrew("מ"),
            TransformationEngine.toPaleoHebrew("ם")
        )
        XCTAssertEqual(
            TransformationEngine.toPaleoHebrew("נ"),
            TransformationEngine.toPaleoHebrew("ן")
        )
        XCTAssertEqual(
            TransformationEngine.toPaleoHebrew("פ"),
            TransformationEngine.toPaleoHebrew("ף")
        )
        XCTAssertEqual(
            TransformationEngine.toPaleoHebrew("צ"),
            TransformationEngine.toPaleoHebrew("ץ")
        )
    }

    func testPaleoHebrewStripsNiqqud() {
        let withNiqqud = "שָׁלוֹם"
        let withoutNiqqud = "שלום"
        XCTAssertEqual(
            TransformationEngine.toPaleoHebrew(withNiqqud),
            TransformationEngine.toPaleoHebrew(withoutNiqqud)
        )
    }

    func testPaleoHebrewPreservesSpaces() {
        let result = TransformationEngine.toPaleoHebrew("אב גד")
        XCTAssertTrue(result.contains(" "))
    }

    func testPaleoHebrewNonHebrewPassesThrough() {
        let result = TransformationEngine.toPaleoHebrew("abc 123")
        XCTAssertEqual(result, "abc 123")
    }

    func testPaleoHebrewEmptyString() {
        XCTAssertEqual(TransformationEngine.toPaleoHebrew(""), "")
    }

    // MARK: - Square Hebrew (Paleo → Modern)

    func testSquareHebrewBasicConversion() {
        let paleo = "\u{10900}\u{10901}\u{10902}"
        let result = TransformationEngine.paleoToSquare(paleo)
        // Should return regular (non-final) forms
        XCTAssertEqual(result, "אבג")
    }

    func testSquareHebrewWithFinalLetters() {
        // "שלומ" — with convertFinals, the מ at end should become ם
        let paleo = TransformationEngine.toPaleoHebrew("שלומ")
        let result = TransformationEngine.paleoToSquare(paleo, convertFinals: true)
        XCTAssertTrue(result.hasSuffix("ם"), "Expected final mem at end, got: \(result)")
    }

    func testSquareHebrewFinalLettersAtWordBoundary() {
        let paleo = TransformationEngine.toPaleoHebrew("שלומ עולמ")
        let result = TransformationEngine.paleoToSquare(paleo, convertFinals: true)
        // Both words should end with final mem
        let words = result.split(separator: " ")
        XCTAssertEqual(words.count, 2)
        for word in words {
            XCTAssertTrue(word.hasSuffix("ם"), "Expected final mem, got: \(word)")
        }
    }

    func testSquareHebrewMidWordLettersNotFinalized() {
        let paleo = TransformationEngine.toPaleoHebrew("ממנ")
        let result = TransformationEngine.paleoToSquare(paleo, convertFinals: true)
        // First מ should stay regular, last נ should become ן
        XCTAssertEqual(result.first, "מ")
        XCTAssertTrue(result.hasSuffix("ן"))
    }

    func testSquareHebrewCleanPunctuationRemovesBrackets() {
        let input = "[text]"
        let result = TransformationEngine.paleoToSquare(input, cleanPunctuation: true)
        XCTAssertFalse(result.contains("["))
        XCTAssertFalse(result.contains("]"))
    }

    func testSquareHebrewCleanPunctuationRemovesLineNumbers() {
        let input = "1. hello\n13. world"
        let result = TransformationEngine.paleoToSquare(input, cleanPunctuation: true)
        XCTAssertFalse(result.contains("1."))
        XCTAssertFalse(result.contains("13."))
    }

    func testSquareHebrewCleanPunctuationRemovesDashes() {
        let input = "text---more--stuff-here"
        let result = TransformationEngine.paleoToSquare(input, cleanPunctuation: true)
        XCTAssertFalse(result.contains("-"))
    }

    func testSquareHebrewCleanPunctuationCollapsesSpaces() {
        let input = "word   word"
        let result = TransformationEngine.paleoToSquare(input, cleanPunctuation: true)
        XCTAssertFalse(result.contains("  "))
    }

    // MARK: - Round-Trip: Modern ↔ Paleo

    func testRoundTripModernToPaleoAndBack() {
        // Use only regular forms (no finals) since paleoToHebrew returns regular
        let original = "אבגדהוזחטיכלמנסעפצקרשת"
        let paleo = TransformationEngine.toPaleoHebrew(original)
        let backToModern = TransformationEngine.paleoToSquare(paleo)
        XCTAssertEqual(backToModern, original)
    }

    // MARK: - Remove Niqqud

    func testRemoveNiqqudStripsAllDiacritics() {
        let input = "שָׁלוֹם"
        let result = NiqqudUtils.removeNiqqud(input)
        // No character in result should be in niqqud range
        for scalar in result.unicodeScalars {
            XCTAssertFalse(NiqqudUtils.isNiqqud(scalar), "Found niqqud U+\(String(scalar.value, radix: 16))")
        }
    }

    func testRemoveNiqqudPreservesBaseLetters() {
        let input = "שָׁלוֹם"
        let result = NiqqudUtils.removeNiqqud(input)
        XCTAssertEqual(result, "שלום")
    }

    func testRemoveNiqqudNoOpOnCleanText() {
        let input = "שלום עולם"
        let result = NiqqudUtils.removeNiqqud(input)
        XCTAssertEqual(result, input)
    }

    func testRemoveNiqqudEmptyString() {
        XCTAssertEqual(NiqqudUtils.removeNiqqud(""), "")
    }

    func testRemoveNiqqudPreservesNonHebrew() {
        let input = "hello שָׁלוֹם world"
        let result = NiqqudUtils.removeNiqqud(input)
        XCTAssertTrue(result.hasPrefix("hello "))
        XCTAssertTrue(result.hasSuffix(" world"))
    }

    // MARK: - Niqqud Detection

    func testIsNiqqudScalarInRange() {
        // Patach U+05B7
        XCTAssertTrue(NiqqudUtils.isNiqqud(Unicode.Scalar(0x05B7)!))
        // Qamats U+05B8
        XCTAssertTrue(NiqqudUtils.isNiqqud(Unicode.Scalar(0x05B8)!))
        // Hiriq U+05B4
        XCTAssertTrue(NiqqudUtils.isNiqqud(Unicode.Scalar(0x05B4)!))
    }

    func testIsNiqqudScalarOutOfRange() {
        // Hebrew letter Aleph U+05D0
        XCTAssertFalse(NiqqudUtils.isNiqqud(Unicode.Scalar(0x05D0)!))
        // Latin A
        XCTAssertFalse(NiqqudUtils.isNiqqud(Unicode.Scalar(0x0041)!))
    }

    func testIsNiqqudCharacter() {
        let kamatz: Character = "\u{05B8}"
        XCTAssertTrue(NiqqudUtils.isNiqqud(kamatz))
        let aleph: Character = "א"
        XCTAssertFalse(NiqqudUtils.isNiqqud(aleph))
    }

    func testIsHebrewLetter() {
        XCTAssertTrue(NiqqudUtils.isHebrewLetter("א"))
        XCTAssertTrue(NiqqudUtils.isHebrewLetter("ת"))
        XCTAssertTrue(NiqqudUtils.isHebrewLetter("ם"))
        XCTAssertFalse(NiqqudUtils.isHebrewLetter("a"))
        XCTAssertFalse(NiqqudUtils.isHebrewLetter("1"))
        XCTAssertFalse(NiqqudUtils.isHebrewLetter(" "))
    }

    func testIsHebrewLetterBoundaries() {
        // First Hebrew letter: Aleph U+05D0
        XCTAssertTrue(NiqqudUtils.isHebrewLetter("\u{05D0}"))
        // Last Hebrew letter: Tav U+05EA
        XCTAssertTrue(NiqqudUtils.isHebrewLetter("\u{05EA}"))
        // Just below range
        XCTAssertFalse(NiqqudUtils.isHebrewLetter("\u{05CF}"))
        // Just above range
        XCTAssertFalse(NiqqudUtils.isHebrewLetter("\u{05EB}"))
    }

    // MARK: - Gematria

    func testGematriaSimpleLetters() {
        XCTAssertEqual(TransformationEngine.toGematria("א"), "1")
        XCTAssertEqual(TransformationEngine.toGematria("י"), "10")
        XCTAssertEqual(TransformationEngine.toGematria("ק"), "100")
        XCTAssertEqual(TransformationEngine.toGematria("ת"), "400")
    }

    func testGematriaWord() {
        // חי = ח(8) + י(10) = 18
        XCTAssertEqual(TransformationEngine.toGematria("חי"), "18")
    }

    func testGematriaMultiWord() {
        // אב = א(1) + ב(2) = 3
        XCTAssertEqual(TransformationEngine.toGematria("אב"), "3")
    }

    func testGematriaFinalLettersHaveSameValue() {
        XCTAssertEqual(TransformationEngine.toGematria("כ"), TransformationEngine.toGematria("ך"))
        XCTAssertEqual(TransformationEngine.toGematria("מ"), TransformationEngine.toGematria("ם"))
        XCTAssertEqual(TransformationEngine.toGematria("נ"), TransformationEngine.toGematria("ן"))
        XCTAssertEqual(TransformationEngine.toGematria("פ"), TransformationEngine.toGematria("ף"))
        XCTAssertEqual(TransformationEngine.toGematria("צ"), TransformationEngine.toGematria("ץ"))
    }

    func testGematriaIgnoresNonHebrew() {
        XCTAssertEqual(TransformationEngine.toGematria("abc"), "0")
        XCTAssertEqual(TransformationEngine.toGematria("123"), "0")
    }

    func testGematriaIgnoresSpaces() {
        // Spaces don't add value: "א ב" should equal "אב"
        XCTAssertEqual(TransformationEngine.toGematria("א ב"), TransformationEngine.toGematria("אב"))
    }

    func testGematriaEmptyString() {
        XCTAssertEqual(TransformationEngine.toGematria(""), "0")
    }

    func testGematriaLargeValue() {
        // תתתת = 400 * 4 = 1600
        XCTAssertEqual(TransformationEngine.toGematria("תתתת"), "1600")
    }

    func testGematriaWithNiqqud() {
        // Niqqud should not contribute to value (they're not in gematriaValues map)
        let withNiqqud = "חַי"
        let withoutNiqqud = "חי"
        XCTAssertEqual(
            TransformationEngine.toGematria(withNiqqud),
            TransformationEngine.toGematria(withoutNiqqud)
        )
    }

    // MARK: - Reverse

    func testReverseSimple() {
        let result = TransformationEngine.reverseWithNiqqud("abc")
        XCTAssertEqual(result, "cba")
    }

    func testReverseHebrew() {
        let result = TransformationEngine.reverseWithNiqqud("שלום")
        XCTAssertEqual(result, "םולש")
    }

    func testReversePreservesNiqqudAttachment() {
        // שָׁלוֹם — niqqud should stay attached to their base letters when reversed
        let input = "שָׁלוֹם"
        let result = TransformationEngine.reverseWithNiqqud(input)
        // The reversed text should have the same niqqud count
        let inputNiqqud = input.unicodeScalars.filter { NiqqudUtils.isNiqqud($0) }.count
        let resultNiqqud = result.unicodeScalars.filter { NiqqudUtils.isNiqqud($0) }.count
        XCTAssertEqual(inputNiqqud, resultNiqqud)
    }

    func testReversePreservesLineBreaks() {
        let result = TransformationEngine.reverseWithNiqqud("abc\ndef")
        XCTAssertEqual(result, "cba\nfed")
    }

    func testReverseEmptyString() {
        XCTAssertEqual(TransformationEngine.reverseWithNiqqud(""), "")
    }

    func testReverseSingleCharacter() {
        XCTAssertEqual(TransformationEngine.reverseWithNiqqud("א"), "א")
    }

    func testReverseDoubleReverseIsIdentity() {
        let original = "שלום עולם"
        let reversed = TransformationEngine.reverseWithNiqqud(original)
        let doubleReversed = TransformationEngine.reverseWithNiqqud(reversed)
        XCTAssertEqual(doubleReversed, original)
    }

    func testReverseDoubleReverseWithNiqqudIsIdentity() {
        let original = "שָׁלוֹם"
        let reversed = TransformationEngine.reverseWithNiqqud(original)
        let doubleReversed = TransformationEngine.reverseWithNiqqud(reversed)
        XCTAssertEqual(doubleReversed, original)
    }

    // MARK: - TransformationEngine.transform() Dispatch

    func testTransformDispatchesHebrewKeyboard() {
        let direct = TransformationEngine.toHebrewKeyboard("hello", keepPunctuation: false)
        let dispatched = TransformationEngine.transform("hello", mode: .hebrewKeyboard, keepPunctuation: false)
        XCTAssertEqual(direct, dispatched)
    }

    func testTransformDispatchesEnglishKeyboard() {
        let direct = TransformationEngine.toEnglishKeyboard("שלום", keepPunctuation: false)
        let dispatched = TransformationEngine.transform("שלום", mode: .englishKeyboard, keepPunctuation: false)
        XCTAssertEqual(direct, dispatched)
    }

    func testTransformDispatchesPaleoHebrew() {
        let direct = TransformationEngine.toPaleoHebrew("אבג")
        let dispatched = TransformationEngine.transform("אבג", mode: .paleoHebrew, keepPunctuation: false)
        XCTAssertEqual(direct, dispatched)
    }

    func testTransformDispatchesRemoveNiqqud() {
        let input = "שָׁלוֹם"
        let direct = NiqqudUtils.removeNiqqud(input)
        let dispatched = TransformationEngine.transform(input, mode: .removeNiqqud, keepPunctuation: false)
        XCTAssertEqual(direct, dispatched)
    }

    func testTransformDispatchesGematria() {
        let direct = TransformationEngine.toGematria("חי")
        let dispatched = TransformationEngine.transform("חי", mode: .gematria, keepPunctuation: false)
        XCTAssertEqual(direct, dispatched)
    }

    func testTransformDispatchesReverse() {
        let direct = TransformationEngine.reverseWithNiqqud("שלום")
        let dispatched = TransformationEngine.transform("שלום", mode: .reverse, keepPunctuation: false)
        XCTAssertEqual(direct, dispatched)
    }

    func testTransformAddNiqqudReturnsInputUnchanged() {
        // addNiqqud is async, so transform() just returns the input
        let input = "שלום"
        let result = TransformationEngine.transform(input, mode: .addNiqqud, keepPunctuation: false)
        XCTAssertEqual(result, input)
    }

    // MARK: - Character Maps Integrity

    func testHebrewToPaleoCoversAllRegularLetters() {
        let allHebrew: [Character] = Array("אבגדהוזחטיכלמנסעפצקרשת")
        for letter in allHebrew {
            XCTAssertNotNil(
                CharacterMaps.hebrewToPaleo[letter],
                "Missing Paleo mapping for \(letter)"
            )
        }
    }

    func testHebrewToPaleoCoversAllFinalLetters() {
        let finals: [Character] = ["ך", "ם", "ן", "ף", "ץ"]
        for letter in finals {
            XCTAssertNotNil(
                CharacterMaps.hebrewToPaleo[letter],
                "Missing Paleo mapping for final \(letter)"
            )
        }
    }

    func testPaleoToHebrewReturnsRegularForms() {
        // paleoToHebrew should prefer regular forms over finals
        let kaf = CharacterMaps.paleoToHebrew["\u{1090A}"]
        XCTAssertEqual(kaf, "כ", "Expected regular כ, not final ך")

        let mem = CharacterMaps.paleoToHebrew["\u{1090C}"]
        XCTAssertEqual(mem, "מ", "Expected regular מ, not final ם")
    }

    func testGematriaValuesCompleteness() {
        let allHebrew: [Character] = Array("אבגדהוזחטיכלמנסעפצקרשת")
        for letter in allHebrew {
            XCTAssertNotNil(
                CharacterMaps.gematriaValues[letter],
                "Missing gematria value for \(letter)"
            )
        }
    }

    func testGematriaValuesArePositive() {
        for (letter, value) in CharacterMaps.gematriaValues {
            XCTAssertGreaterThan(value, 0, "Gematria value for \(letter) should be positive")
        }
    }

    func testEnglishToHebrewCoversFullQWERTYRow() {
        let qwerty = "qwertyuiopasdfghjklzxcvbnm"
        for key in qwerty {
            XCTAssertNotNil(
                CharacterMaps.englishToHebrew[key],
                "Missing Hebrew mapping for '\(key)'"
            )
        }
    }

    func testFinalToRegularCompleteness() {
        let expectedFinals: [Character] = ["ך", "ם", "ן", "ף", "ץ"]
        let expectedRegulars: [Character] = ["כ", "מ", "נ", "פ", "צ"]
        for (final, regular) in zip(expectedFinals, expectedRegulars) {
            XCTAssertEqual(
                CharacterMaps.finalToRegular[final], regular,
                "Expected \(final) → \(regular)"
            )
        }
    }

    // MARK: - ChangeStats

    func testChangeStatsDefaultMode() {
        let input = "abc"
        let output = "axc"
        let stats = ChangeStats.compute(input: input, output: output, mode: .hebrewKeyboard)
        XCTAssertEqual(stats.changed, 1)
        XCTAssertEqual(stats.unchanged, 2)
    }

    func testChangeStatsIdenticalText() {
        let text = "hello"
        let stats = ChangeStats.compute(input: text, output: text, mode: .hebrewKeyboard)
        XCTAssertEqual(stats.changed, 0)
        XCTAssertEqual(stats.unchanged, 5)
    }

    func testChangeStatsCompletelyDifferent() {
        let stats = ChangeStats.compute(input: "abc", output: "xyz", mode: .hebrewKeyboard)
        XCTAssertEqual(stats.changed, 3)
        XCTAssertEqual(stats.unchanged, 0)
    }

    func testChangeStatsDifferentLengths() {
        let stats = ChangeStats.compute(input: "ab", output: "abcd", mode: .hebrewKeyboard)
        // 2 unchanged + 2 extra = 2 changed
        XCTAssertEqual(stats.unchanged, 2)
        XCTAssertEqual(stats.changed, 2)
    }

    func testChangeStatsIgnoresSpaces() {
        let stats = ChangeStats.compute(input: "a b", output: "a c", mode: .hebrewKeyboard)
        // Spaces removed: "ab" vs "ac" → 1 unchanged, 1 changed
        XCTAssertEqual(stats.unchanged, 1)
        XCTAssertEqual(stats.changed, 1)
    }

    func testChangeStatsGematriaMode() {
        let input = "שלום"
        let output = "376" // whatever the gematria result is
        let stats = ChangeStats.compute(input: input, output: output, mode: .gematria)
        XCTAssertEqual(stats.changed, 4) // all 4 Hebrew letters counted
        XCTAssertEqual(stats.unchanged, 0)
    }

    func testChangeStatsRemoveNiqqudMode() {
        let input = "שָׁלוֹם"
        let output = NiqqudUtils.removeNiqqud(input)
        let stats = ChangeStats.compute(input: input, output: output, mode: .removeNiqqud)
        XCTAssertGreaterThan(stats.changed, 0, "Should count removed niqqud")
        XCTAssertGreaterThan(stats.unchanged, 0, "Should count non-niqqud characters")
    }

    func testChangeStatsEmptyInput() {
        let stats = ChangeStats.compute(input: "", output: "", mode: .hebrewKeyboard)
        XCTAssertEqual(stats.changed, 0)
        XCTAssertEqual(stats.unchanged, 0)
    }

    // MARK: - TransformationType Properties

    func testAllTransformationTypesHaveIcon() {
        for type in TransformationType.allCases {
            XCTAssertFalse(type.icon.isEmpty, "\(type.rawValue) missing icon")
        }
    }

    func testAllTransformationTypesHaveLabels() {
        for type in TransformationType.allCases {
            XCTAssertFalse(type.inputLabel.isEmpty, "\(type.rawValue) missing inputLabel")
            XCTAssertFalse(type.outputLabel.isEmpty, "\(type.rawValue) missing outputLabel")
        }
    }

    func testPunctuationToggleSupportedTypes() {
        XCTAssertTrue(TransformationType.hebrewKeyboard.supportsPunctuationToggle)
        XCTAssertTrue(TransformationType.englishKeyboard.supportsPunctuationToggle)
        XCTAssertFalse(TransformationType.gematria.supportsPunctuationToggle)
        XCTAssertFalse(TransformationType.reverse.supportsPunctuationToggle)
    }

    func testSquareOptionsOnlyForSquareHebrew() {
        XCTAssertTrue(TransformationType.squareHebrew.supportsSquareOptions)
        for type in TransformationType.allCases where type != .squareHebrew {
            XCTAssertFalse(type.supportsSquareOptions, "\(type.rawValue) should not support square options")
        }
    }

    func testOnlyAddNiqqudIsAITransform() {
        XCTAssertTrue(TransformationType.addNiqqud.isAITransform)
        for type in TransformationType.allCases where type != .addNiqqud {
            XCTAssertFalse(type.isAITransform, "\(type.rawValue) should not be AI transform")
        }
    }

    // MARK: - Edge Cases

    func testUnicodeScalarBoundaryPaleoHebrew() {
        // Paleo-Hebrew chars are in SMP (above U+FFFF)
        // Verify they survive round-trip through String operations
        let paleo = "\u{10900}\u{10901}\u{10902}"
        let square = TransformationEngine.paleoToSquare(paleo)
        let backToPaleo = TransformationEngine.toPaleoHebrew(square)
        XCTAssertEqual(backToPaleo, paleo)
    }

    func testMixedScriptInput() {
        // Input with Hebrew, English, numbers, and Paleo-Hebrew
        let mixed = "אב abc 123 \u{10900}"
        // Should not crash on any transformation
        for mode in TransformationType.allCases where mode != .addNiqqud {
            let _ = TransformationEngine.transform(mixed, mode: mode, keepPunctuation: false)
        }
    }

    func testVeryLongInput() {
        let long = String(repeating: "שלום ", count: 1000)
        let result = TransformationEngine.toPaleoHebrew(long)
        XCTAssertFalse(result.isEmpty)
    }

    func testNewlineOnlyInput() {
        let result = TransformationEngine.reverseWithNiqqud("\n\n\n")
        XCTAssertEqual(result, "\n\n\n")
    }

    func testNiqqudOnlyInput() {
        // String of only niqqud marks
        let niqqudOnly = "\u{05B0}\u{05B1}\u{05B2}\u{05B3}"
        let stripped = NiqqudUtils.removeNiqqud(niqqudOnly)
        XCTAssertEqual(stripped, "")
    }
}
