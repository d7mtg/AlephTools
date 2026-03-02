import Cocoa

class AlephTransformCommand: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let text = directParameter as? String else {
            scriptErrorNumber = errOSACantAssign
            scriptErrorString = "Expected text as direct parameter"
            return nil
        }

        let modeCode = evaluatedArguments?["Mode"] as? String ?? "hebrew"
        let keepPunctuation = evaluatedArguments?["KeepPunctuation"] as? Bool ?? false

        let mode: TransformationType
        switch modeCode {
        case "hebrew", "hebr":
            mode = .hebrewKeyboard
        case "english", "engl":
            mode = .englishKeyboard
        case "strip", "strp":
            mode = .removeNiqqud
        case "addniqqud", "aniq":
            mode = .addNiqqud
        case "modern", "square", "modn":
            mode = .squareHebrew
        case "paleo", "pleo":
            mode = .paleoHebrew
        case "gematria", "gema":
            mode = .gematria
        case "reverse", "rvrs":
            mode = .reverse
        default:
            mode = .hebrewKeyboard
        }

        if mode == .addNiqqud {
            do {
                let clean = NiqqudUtils.removeNiqqud(text)
                return try NakdimonInference.predict(clean)
            } catch {
                scriptErrorNumber = errOSACantAssign
                scriptErrorString = "Niqqud model error: \(error.localizedDescription)"
                return nil
            }
        }

        return TransformationEngine.transform(text, mode: mode, keepPunctuation: keepPunctuation)
    }
}
