import SwiftUI
import AppIntents

@main
struct AlephToolsiOSApp: App {
    @AppStorage("languageOverride") private var languageOverride = "system"

    init() {
        let lang = UserDefaults.standard.string(forKey: "languageOverride") ?? "system"
        if lang != "system" {
            UserDefaults.standard.set([lang], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
    }

    private var localeOverride: Locale? {
        switch languageOverride {
        case "en": return Locale(identifier: "en")
        case "he": return Locale(identifier: "he")
        case "yi": return Locale(identifier: "yi")
        default: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            iOSContentView()
                .optionalLocale(localeOverride)
                .onAppear {
                    AlephToolsShortcuts.updateAppShortcutParameters()
                }
        }
    }
}

private extension View {
    @ViewBuilder
    func optionalLocale(_ locale: Locale?) -> some View {
        if let locale {
            self.environment(\.locale, locale)
                .environment(\.layoutDirection, locale.language.characterDirection == .rightToLeft ? .rightToLeft : .leftToRight)
        } else {
            self
        }
    }
}
