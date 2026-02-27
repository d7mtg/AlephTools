# Aleph Tools

A Hebrew text transformation utility for macOS, iOS, and iPadOS.

Aleph Tools is the native app companion to [aleph.d7mtg.com](https://aleph.d7mtg.com) and [d7mtg.com/aleph](https://d7mtg.com/aleph) — bringing the same Hebrew text tools to your desktop and mobile devices as a fast, offline-capable app with system-wide integration.

## Features

- **Keyboard Layout Conversion** — Switch text between QWERTY and Hebrew keyboard layouts, with optional punctuation preservation
- **Strip Niqqud** — Remove vowel points and diacritical marks from Hebrew text
- **Script Transliteration** — Convert between modern square Hebrew (אבג) and Paleo-Hebrew (𐤀𐤁𐤂)
- **Gematria** — Calculate the numerological value of Hebrew text
- **Reverse** — Mirror text while keeping niqqud correctly attached to their letters

### macOS

- Split-view interface with line-numbered input and output panels
- **System Services** — Transform text in any app via the Services menu
- **Global Keyboard Shortcuts** — Assign hotkeys to transform selected text system-wide
- Launch at login, configurable default transformation

### iOS / iPadOS

- Adaptive layout optimized for both iPhone and iPad
- **Paleo-Hebrew Keyboard** — A custom keyboard extension for typing in Paleo-Hebrew script directly

## Requirements

- macOS 14.0+ (Sonoma)
- iOS / iPadOS 16.0+
- Xcode 16.0+ (to build from source)

## Building

Open `AlephTools.xcodeproj` in Xcode and build the desired target:

| Target | Platform | Description |
|--------|----------|-------------|
| `AlephTools` | macOS | Desktop application |
| `AlephToolsiOS` | iOS / iPadOS | Mobile application |
| `AlephKeyboard` | iOS | Paleo-Hebrew keyboard extension |

No external dependencies — the project uses only Apple system frameworks.

## License

© 2025 [D7mtg](https://d7mtg.com)
