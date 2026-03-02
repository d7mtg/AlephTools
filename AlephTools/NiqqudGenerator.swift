import Foundation
import SwiftUI
import CoreML

// MARK: - Nakdimon Character Tables

/// Port of the Nakdimon Hebrew diacritization model's character mappings.
/// See: https://github.com/elazarg/nakdimon
private enum NakdimonTables {

    static let rafe: Character = "\u{05BF}"

    // Letters table: index 0 = MASK, 1-3 = special tokens (H, O, 5), 4-15 = punctuation, 16-42 = Hebrew letters
    static let lettersChars: [Character] = [
        "\0",   // 0: MASK
        "H",    // 1: ligature placeholder
        "O",    // 2: unknown char
        "5",    // 3: digit placeholder
        " ",    // 4
        "!",    // 5
        "\"",   // 6
        "'",    // 7
        "(",    // 8
        ")",    // 9
        ",",    // 10
        "-",    // 11
        ".",    // 12
        ":",    // 13
        ";",    // 14
        "?",    // 15
        "\u{05D0}",  // 16: א
        "\u{05D1}",  // 17: ב
        "\u{05D2}",  // 18: ג
        "\u{05D3}",  // 19: ד
        "\u{05D4}",  // 20: ה
        "\u{05D5}",  // 21: ו
        "\u{05D6}",  // 22: ז
        "\u{05D7}",  // 23: ח
        "\u{05D8}",  // 24: ט
        "\u{05D9}",  // 25: י
        "\u{05DA}",  // 26: ך
        "\u{05DB}",  // 27: כ
        "\u{05DC}",  // 28: ל
        "\u{05DD}",  // 29: ם
        "\u{05DE}",  // 30: מ
        "\u{05DF}",  // 31: ן
        "\u{05E0}",  // 32: נ
        "\u{05E1}",  // 33: ס
        "\u{05E2}",  // 34: ע
        "\u{05E3}",  // 35: ף
        "\u{05E4}",  // 36: פ
        "\u{05E5}",  // 37: ץ
        "\u{05E6}",  // 38: צ
        "\u{05E7}",  // 39: ק
        "\u{05E8}",  // 40: ר
        "\u{05E9}",  // 41: ש
        "\u{05EA}",  // 42: ת
    ]

    // Reverse lookup: character -> index
    static let letterToIndex: [Character: Int32] = {
        var map: [Character: Int32] = [:]
        for (i, c) in lettersChars.enumerated() {
            if c != "\0" { map[c] = Int32(i) }
        }
        return map
    }()

    // Niqqud output table (16 entries): MASK, RAFE, then vowels
    static let niqqudChars: [Character] = [
        "\0",           // 0: MASK
        "\u{05BF}",     // 1: RAFE
        "\u{05B0}",     // 2: SHVA
        "\u{05B1}",     // 3: REDUCED_SEGOL
        "\u{05B2}",     // 4: REDUCED_PATAKH
        "\u{05B3}",     // 5: REDUCED_KAMATZ
        "\u{05B4}",     // 6: HIRIK
        "\u{05B5}",     // 7: TZEIRE
        "\u{05B6}",     // 8: SEGOL
        "\u{05B7}",     // 9: PATAKH
        "\u{05B8}",     // 10: KAMATZ
        "\u{05B9}",     // 11: HOLAM
        "\u{05BA}",     // 12: HOLAM HASER
        "\u{05BB}",     // 13: KUBUTZ
        "\u{05BC}",     // 14: SHURUK/DAGESH
        "\u{05B7}",     // 15: PATAKH (duplicate)
    ]

    // Dagesh output table (3 entries)
    static let dageshChars: [Character] = [
        "\0",           // 0: MASK
        "\u{05BF}",     // 1: RAFE
        "\u{05BC}",     // 2: DAGESH
    ]

    // Sin output table (4 entries)
    static let sinChars: [Character] = [
        "\0",           // 0: MASK
        "\u{05BF}",     // 1: RAFE
        "\u{05C1}",     // 2: SHIN DOT (right)
        "\u{05C2}",     // 3: SIN DOT (left)
    ]

    // Letters that can receive dagesh
    static let dageshLetters: Set<Character> = Set("בגדהוזטיכלמנספצקשת" + "ךף")

    // Letters that can receive sin/shin dot (only shin)
    static let sinLetters: Set<Character> = Set("ש")

    // Letters that can receive niqqud vowels
    static let niqqudLetters: Set<Character> = Set("אבגדהוזחטיכלמנסעפצקרשת" + "ךן")

    /// Normalize a character to its model-input equivalent (replicates Python normalize())
    static func normalize(_ c: Character) -> Character {
        if letterToIndex[c] != nil { return c }
        // Final forms -> regular (but ך,ם,ן,ף,ץ are already in the table)
        let finals: [Character: Character] = ["ך": "כ", "ם": "מ", "ן": "נ", "ף": "פ", "ץ": "צ"]
        if let regular = finals[c] { return regular }
        if c == "\n" || c == "\t" { return " " }
        if "־‒–—―−".contains(c) { return "-" }
        if c == "[" { return "(" }
        if c == "]" { return ")" }
        if "´''".contains(c) { return "'" }
        if "\u{201C}\u{201D}״".contains(c) { return "\"" }
        if c.isNumber { return "5" }
        if c == "…" { return "," }
        if "ײװױ".contains(c) { return "H" }
        return "O"
    }
}

// MARK: - Niqqud Generator

@MainActor
class NiqqudGenerator: ObservableObject {
    @Published var output: String = ""
    @Published var isGenerating: Bool = false
    @Published var error: NiqqudGeneratorError? = nil

    enum NiqqudGeneratorError: LocalizedError {
        case modelLoadFailed
        case predictionFailed(String)

        var errorDescription: String? {
            switch self {
            case .modelLoadFailed:
                return "Failed to load the niqqud model."
            case .predictionFailed(let reason):
                return reason
            }
        }
    }

    private var currentTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?
    private let debounceDelay: UInt64 = 300_000_000 // 0.3 seconds

    nonisolated static func loadModel() throws -> MLModel {
        try NakdimonInference.loadModel()
    }

    func generate(from text: String) {
        debounceTask?.cancel()
        currentTask?.cancel()

        guard !text.isEmpty else {
            output = ""
            isGenerating = false
            error = nil
            return
        }

        let cleanText = NiqqudUtils.removeNiqqud(text) + " "

        debounceTask = Task {
            try? await Task.sleep(nanoseconds: debounceDelay)
            guard !Task.isCancelled else { return }
            runPrediction(cleanText)
        }
    }

    func cancel() {
        debounceTask?.cancel()
        currentTask?.cancel()
        isGenerating = false
    }

    private func runPrediction(_ text: String) {
        isGenerating = true
        error = nil

        currentTask = Task.detached(priority: .userInitiated) { [weak self] in
            do {
                let raw = try NakdimonInference.predict(text)
                let result = raw.trimmingCharacters(in: .whitespaces)
                await MainActor.run {
                    guard let self, !Task.isCancelled else { return }
                    self.output = result
                    self.isGenerating = false
                }
            } catch {
                await MainActor.run {
                    guard let self, !Task.isCancelled else { return }
                    self.error = .predictionFailed(error.localizedDescription)
                    self.isGenerating = false
                }
            }
        }
    }
}

// MARK: - Nakdimon Inference

enum NakdimonInference {

    private static var cachedModel: MLModel?

    static func loadModel() throws -> MLModel {
        if let model = cachedModel { return model }
        let config = MLModelConfiguration()
        config.computeUnits = .all
        let model = try Nakdimon(configuration: config).model
        cachedModel = model
        return model
    }

    static func predict(_ text: String, maxlen: Int = 10000) throws -> String {
        let model = try loadModel()

        // Step 1: Tokenize into (letter, normalizedIndex) pairs
        let chars = Array(text)
        let segments = splitByLength(chars, maxlen: maxlen)
        var resultParts: [String] = []

        for segment in segments {
            if Task.isCancelled { return "" }

            var letters: [Character] = []
            var indices: [Int32] = []

            for ch in segment {
                let normalized = NakdimonTables.normalize(ch)
                let idx = NakdimonTables.letterToIndex[normalized] ?? 2 // 2 = 'O' (unknown)
                letters.append(ch)
                indices.append(idx)
            }

            // Pad to maxlen
            let seqLen = indices.count
            while indices.count < maxlen {
                indices.append(0)
            }

            // Step 2: Create MLMultiArray input
            let inputArray = try MLMultiArray(shape: [1, NSNumber(value: maxlen)], dataType: .int32)
            for i in 0..<maxlen {
                inputArray[[0, NSNumber(value: i)] as [NSNumber]] = NSNumber(value: indices[i])
            }

            // Step 3: Run model
            let inputFeatures = try MLDictionaryFeatureProvider(dictionary: ["input": inputArray])
            let prediction = try model.prediction(from: inputFeatures)

            guard let niqqudOut = prediction.featureValue(for: "niqqud")?.multiArrayValue,
                  let dageshOut = prediction.featureValue(for: "dagesh")?.multiArrayValue,
                  let sinOut = prediction.featureValue(for: "sin")?.multiArrayValue else {
                throw NiqqudGenerator.NiqqudGeneratorError.predictionFailed("Model output missing.")
            }

            // Step 4: Merge predictions back onto letters
            let merged = merge(
                letters: letters,
                normalizedIndices: Array(indices.prefix(seqLen)),
                niqqud: niqqudOut,
                dagesh: dageshOut,
                sin: sinOut,
                seqLen: seqLen
            )
            resultParts.append(merged)
        }

        return resultParts.joined(separator: " ")
            .replacingOccurrences(of: "  ", with: " ")
    }

    /// Argmax over the last dimension of a 3D MLMultiArray at [0, pos, :]
    private static func argmax(_ array: MLMultiArray, pos: Int, classes: Int) -> Int {
        var bestIdx = 0
        var bestVal: Float = -Float.infinity
        for c in 0..<classes {
            let val = array[[0, NSNumber(value: pos), NSNumber(value: c)] as [NSNumber]].floatValue
            if val > bestVal {
                bestVal = val
                bestIdx = c
            }
        }
        return bestIdx
    }

    private static func merge(
        letters: [Character],
        normalizedIndices: [Int32],
        niqqud: MLMultiArray,
        dagesh: MLMultiArray,
        sin: MLMultiArray,
        seqLen: Int
    ) -> String {
        let niqqudClasses = NakdimonTables.niqqudChars.count
        let dageshClasses = NakdimonTables.dageshChars.count
        let sinClasses = NakdimonTables.sinChars.count

        var result = ""
        result.reserveCapacity(seqLen * 4)

        for i in 0..<seqLen {
            if normalizedIndices[i] == 0 { break }

            let letter = letters[i]
            result.append(letter)

            // Append dagesh only if the letter can receive it and prediction isn't MASK/RAFE
            if NakdimonTables.dageshLetters.contains(letter) {
                let dIdx = argmax(dagesh, pos: i, classes: dageshClasses)
                if dIdx >= 2 { // Skip 0=MASK, 1=RAFE
                    result.append(NakdimonTables.dageshChars[dIdx])
                }
            }

            // Append shin/sin dot only for shin, skip MASK/RAFE
            if NakdimonTables.sinLetters.contains(letter) {
                let sIdx = argmax(sin, pos: i, classes: sinClasses)
                if sIdx >= 2 {
                    result.append(NakdimonTables.sinChars[sIdx])
                }
            }

            // Append niqqud vowel only if applicable, skip MASK/RAFE
            if NakdimonTables.niqqudLetters.contains(letter) {
                let nIdx = argmax(niqqud, pos: i, classes: niqqudClasses)
                if nIdx >= 2 {
                    result.append(NakdimonTables.niqqudChars[nIdx])
                }
            }
        }

        return result
    }

    /// Split text into chunks at word boundaries, respecting maxlen
    private static func splitByLength(_ chars: [Character], maxlen: Int) -> [[Character]] {
        guard maxlen > 1 else { return [chars] }
        var segments: [[Character]] = []
        var current: [Character] = []
        var lastSpace = maxlen

        for c in chars {
            if c == " " {
                lastSpace = current.count
            }
            current.append(c)
            if current.count == maxlen - 1 {
                let cutoff = min(lastSpace + 1, current.count)
                segments.append(Array(current.prefix(cutoff)))
                current = Array(current.suffix(from: cutoff))
                lastSpace = maxlen
            }
        }
        if !current.isEmpty {
            segments.append(current)
        }
        return segments
    }
}
