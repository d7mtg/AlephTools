# CLAUDE.md — AlephTools

## Project Overview

AlephTools is a Hebrew text transformation utility for macOS and iOS. It converts between keyboard layouts (QWERTY ↔ Hebrew), transliterates between modern square Hebrew and Paleo-Hebrew script, strips diacritical marks (niqqud), calculates gematria values, and reverses text while preserving diacritics.

## Repository Structure

```
AlephTools/
├── AlephTools.xcodeproj/          # Xcode project configuration
├── AlephTools/                    # macOS app target
│   ├── AlephToolsApp.swift        # App entry point (@main, AppDelegate)
│   ├── ContentView.swift          # Main split-view UI
│   ├── SettingsView.swift         # Settings window (4 tabs)
│   ├── LineNumberTextEditor.swift # NSViewRepresentable text editor
│   ├── ServiceProvider.swift      # macOS Services provider
│   ├── HebrewTransformations.swift# Core transformation logic (shared)
│   ├── Info.plist                 # Services configuration
│   ├── AlephTools.entitlements    # App entitlements
│   └── Assets.xcassets/           # Icons and colors
├── AlephToolsiOS/                 # iOS/iPadOS app target
│   ├── AlephToolsiOSApp.swift     # iOS app entry point
│   └── iOSContentView.swift       # Adaptive layout (iPhone/iPad)
└── AlephKeyboard/                 # iOS keyboard extension
    ├── KeyboardViewController.swift
    ├── PaleoKeyboardView.swift
    └── Info.plist
```

## Build & Run

**Requirements:** Xcode 16.0+, macOS 14.0+ (Sonoma), iOS/iPadOS 16.0+

**Build targets:**
- `AlephTools` — macOS app
- `AlephToolsiOS` — iOS/iPadOS app
- `AlephKeyboard` — iOS Paleo-Hebrew keyboard extension (embedded in AlephToolsiOS)

Build with Xcode (`xcodebuild`) or open `AlephTools.xcodeproj` directly. There are no external dependencies — the project uses only Apple system frameworks.

**No test suite exists.** There are no XCTest targets, no linting tools (SwiftLint, SwiftFormat), and no CI/CD pipeline configured.

## Language & Frameworks

- **Swift** — sole programming language (~1950 lines total)
- **SwiftUI** — primary UI framework for both platforms
- **AppKit** — macOS-specific: NSTextView, NSServices, NSPasteboard, NSEvent monitoring, CGEvent
- **UIKit** — keyboard extension only (KeyboardViewController)

## Architecture & Conventions

### Code Organization
- **`// MARK: -` sections** used extensively to organize code within files
- **Enums as namespaces** for static utility: `CharacterMaps`, `NiqqudUtils`, `TransformationEngine`
- **Shared core logic** in `HebrewTransformations.swift` — included in both macOS and iOS targets
- Platform-specific UI in separate target directories

### Patterns
- **MVVM-like** with `@State`, `@Published`, `@AppStorage` for state management
- **NSViewRepresentable** for bridging AppKit components into SwiftUI (LineNumberTextEditor)
- **Coordinator pattern** for NSTextView delegate callbacks
- **Singleton** for `GlobalShortcutManager.shared`

### Naming
- **Files:** PascalCase matching the primary type (`ContentView.swift`, `ServiceProvider.swift`)
- **Types:** PascalCase (`TransformationType`, `ChangeStats`)
- **Functions/variables:** camelCase (`toHebrewKeyboard`, `keepPunctuation`)
- **Enum cases:** camelCase (`hebrewKeyboard`, `removeNiqqud`)

### Commit Style
- Present tense imperative ("Add", "Fix", "Use")
- Descriptive but concise, technical details included
- Example: `Add General, Services, and About settings tabs`

## Key Domain Concepts

### Transformation Types
| Type | Description |
|------|-------------|
| `hebrewKeyboard` | QWERTY English → Hebrew keyboard mapping |
| `englishKeyboard` | Hebrew → QWERTY English keyboard mapping |
| `removeNiqqud` | Strip vowel points and diacritical marks (U+0591–U+05C7) |
| `squareHebrew` | Paleo-Hebrew → Modern square script |
| `paleoHebrew` | Modern square → Paleo-Hebrew (U+10900–U+10915) |
| `gematria` | Sum of Hebrew letter numerical values |
| `reverse` | Mirror text while preserving niqqud attachment to letters |

### Unicode Handling
- Modern Hebrew: U+05D0–U+05EA
- Paleo-Hebrew: U+10900–U+10915 (Supplementary Multilingual Plane — requires `unicodeScalars` iteration)
- Niqqud/diacritics: U+0591–U+05C7
- Final letter forms (ך ם ן ף ץ) are mapped and normalized as needed

## Important Notes for AI Assistants

- The app sandbox is **disabled** (`AlephTools.entitlements`: `app-sandbox = false`) because it needs Accessibility API access for global keyboard shortcuts
- `HebrewTransformations.swift` is shared across targets — changes affect macOS, iOS, and the keyboard extension
- Paleo-Hebrew characters are in the SMP (above U+FFFF) — always use `unicodeScalars` for iteration, not `Character`-level indexing
- The macOS app registers system-wide Services via `Info.plist` and `NSApp.servicesProvider`
- No package manager (SPM, CocoaPods, Carthage) is used — zero external dependencies
