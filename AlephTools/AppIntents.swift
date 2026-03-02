import AppIntents

// MARK: - Transformation App Enum

enum TransformationAppEnum: String, AppEnum {
    case toHebrew = "To Hebrew"
    case toEnglish = "To English"
    case stripNiqqud = "Strip Niqqud"
    case addNiqqud = "Add Niqqud"
    case toModern = "To Modern"
    case toPaleo = "To Paleo"
    case gematria = "Gematria"
    case reverse = "Reverse"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Transformation")

    static var caseDisplayRepresentations: [TransformationAppEnum: DisplayRepresentation] = [
        .toHebrew: "To Hebrew",
        .toEnglish: "To English",
        .stripNiqqud: "Strip Niqqud",
        .addNiqqud: "Add Niqqud",
        .toModern: "To Modern",
        .toPaleo: "To Paleo",
        .gematria: "Gematria",
        .reverse: "Reverse",
    ]

    var transformationType: TransformationType {
        switch self {
        case .toHebrew: .hebrewKeyboard
        case .toEnglish: .englishKeyboard
        case .stripNiqqud: .removeNiqqud
        case .addNiqqud: .addNiqqud
        case .toModern: .squareHebrew
        case .toPaleo: .paleoHebrew
        case .gematria: .gematria
        case .reverse: .reverse
        }
    }
}

// MARK: - Generic Transform Intent (kept for flexibility)

struct TransformHebrewTextIntent: AppIntent {
    static var title: LocalizedStringResource = "Transform Hebrew Text"
    static var description = IntentDescription("Transform text using Aleph Tools")

    @Parameter(title: "Text")
    var text: String

    @Parameter(title: "Transformation")
    var transformation: TransformationAppEnum

    @Parameter(title: "Keep Punctuation", default: false)
    var keepPunctuation: Bool

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        if transformation == .addNiqqud {
            let clean = NiqqudUtils.removeNiqqud(text)
            let result = try NakdimonInference.predict(clean)
            return .result(value: result)
        }
        let result = TransformationEngine.transform(
            text,
            mode: transformation.transformationType,
            keepPunctuation: keepPunctuation
        )
        return .result(value: result)
    }
}

// MARK: - Individual Intents

struct AddNiqqudIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Niqqud"
    static var description = IntentDescription("Add vowel diacritics (niqqud) to Hebrew text using the Nakdimon model")

    @Parameter(title: "Text")
    var text: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let clean = NiqqudUtils.removeNiqqud(text)
        let result = try NakdimonInference.predict(clean)
        return .result(value: result)
    }
}

struct ToHebrewIntent: AppIntent {
    static var title: LocalizedStringResource = "To Hebrew"
    static var description = IntentDescription("Convert QWERTY English text to Hebrew keyboard layout")

    @Parameter(title: "Text")
    var text: String

    @Parameter(title: "Keep Punctuation", default: false)
    var keepPunctuation: Bool

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let result = TransformationEngine.transform(text, mode: .hebrewKeyboard, keepPunctuation: keepPunctuation)
        return .result(value: result)
    }
}

struct ToEnglishIntent: AppIntent {
    static var title: LocalizedStringResource = "To English"
    static var description = IntentDescription("Convert Hebrew text to QWERTY English keyboard layout")

    @Parameter(title: "Text")
    var text: String

    @Parameter(title: "Keep Punctuation", default: false)
    var keepPunctuation: Bool

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let result = TransformationEngine.transform(text, mode: .englishKeyboard, keepPunctuation: keepPunctuation)
        return .result(value: result)
    }
}

struct StripNiqqudIntent: AppIntent {
    static var title: LocalizedStringResource = "Strip Niqqud"
    static var description = IntentDescription("Remove vowel points and diacritics from Hebrew text")

    @Parameter(title: "Text")
    var text: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let result = TransformationEngine.transform(text, mode: .removeNiqqud, keepPunctuation: false)
        return .result(value: result)
    }
}

struct GematriaIntent: AppIntent {
    static var title: LocalizedStringResource = "Gematria"
    static var description = IntentDescription("Calculate the gematria numerical value of Hebrew text")

    @Parameter(title: "Text")
    var text: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let result = TransformationEngine.transform(text, mode: .gematria, keepPunctuation: false)
        return .result(value: result)
    }
}

struct ToPaleoIntent: AppIntent {
    static var title: LocalizedStringResource = "To Paleo-Hebrew"
    static var description = IntentDescription("Convert modern square Hebrew to Paleo-Hebrew script")

    @Parameter(title: "Text")
    var text: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let result = TransformationEngine.transform(text, mode: .paleoHebrew, keepPunctuation: false)
        return .result(value: result)
    }
}

struct ToModernIntent: AppIntent {
    static var title: LocalizedStringResource = "To Modern Hebrew"
    static var description = IntentDescription("Convert Paleo-Hebrew to modern square Hebrew script")

    @Parameter(title: "Text")
    var text: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let result = TransformationEngine.transform(text, mode: .squareHebrew, keepPunctuation: false)
        return .result(value: result)
    }
}

struct ReverseHebrewIntent: AppIntent {
    static var title: LocalizedStringResource = "Reverse Hebrew Text"
    static var description = IntentDescription("Reverse text while preserving niqqud attachment to letters")

    @Parameter(title: "Text")
    var text: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let result = TransformationEngine.transform(text, mode: .reverse, keepPunctuation: false)
        return .result(value: result)
    }
}

// MARK: - Shortcuts Provider

struct AlephToolsShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .red

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddNiqqudIntent(),
            phrases: [
                "Add niqqud with \(.applicationName)",
                "Add vowels with \(.applicationName)",
                "Vowelize Hebrew with \(.applicationName)",
            ],
            shortTitle: "Add Niqqud",
            systemImageName: "wand.and.stars"
        )

        AppShortcut(
            intent: ToHebrewIntent(),
            phrases: [
                "Convert to Hebrew with \(.applicationName)",
                "Type Hebrew with \(.applicationName)",
            ],
            shortTitle: "To Hebrew",
            systemImageName: "keyboard"
        )

        AppShortcut(
            intent: ToEnglishIntent(),
            phrases: [
                "Convert to English with \(.applicationName)",
                "Hebrew to English with \(.applicationName)",
            ],
            shortTitle: "To English",
            systemImageName: "globe"
        )

        AppShortcut(
            intent: StripNiqqudIntent(),
            phrases: [
                "Strip niqqud with \(.applicationName)",
                "Remove niqqud with \(.applicationName)",
                "Remove vowels with \(.applicationName)",
            ],
            shortTitle: "Strip Niqqud",
            systemImageName: "eraser"
        )

        AppShortcut(
            intent: GematriaIntent(),
            phrases: [
                "Calculate gematria with \(.applicationName)",
                "Gematria with \(.applicationName)",
            ],
            shortTitle: "Gematria",
            systemImageName: "number"
        )

        AppShortcut(
            intent: ToPaleoIntent(),
            phrases: [
                "Convert to Paleo-Hebrew with \(.applicationName)",
                "Paleo-Hebrew with \(.applicationName)",
            ],
            shortTitle: "To Paleo-Hebrew",
            systemImageName: "scroll"
        )

        AppShortcut(
            intent: ToModernIntent(),
            phrases: [
                "Convert to modern Hebrew with \(.applicationName)",
            ],
            shortTitle: "To Modern Hebrew",
            systemImageName: "textformat"
        )

        AppShortcut(
            intent: ReverseHebrewIntent(),
            phrases: [
                "Reverse Hebrew text with \(.applicationName)",
            ],
            shortTitle: "Reverse Text",
            systemImageName: "arrow.left.arrow.right"
        )
    }
}
