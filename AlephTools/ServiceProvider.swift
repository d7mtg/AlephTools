import AppKit

class ServiceProvider: NSObject {

    private func transform(_ pboard: NSPasteboard, mode: TransformationType) {
        guard let text = pboard.string(forType: .string) else { return }
        let result = TransformationEngine.transform(text, mode: mode, keepPunctuation: false)
        pboard.clearContents()
        pboard.setString(result, forType: .string)
    }

    @objc func transformToHebrew(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        transform(pboard, mode: .hebrewKeyboard)
    }

    @objc func transformToEnglish(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        transform(pboard, mode: .englishKeyboard)
    }

    @objc func transformStripNiqqud(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        transform(pboard, mode: .removeNiqqud)
    }

    @objc func transformToPaleo(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        transform(pboard, mode: .paleoHebrew)
    }

    @objc func transformToModern(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        transform(pboard, mode: .squareHebrew)
    }

    @objc func transformGematria(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        transform(pboard, mode: .gematria)
    }

    @objc func transformReverse(_ pboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        transform(pboard, mode: .reverse)
    }
}
