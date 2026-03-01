import SwiftUI

// MARK: - Learning Center

struct LearningCenterView: View {
    var body: some View {
        List {
            ForEach(LearningTopic.all) { topic in
                NavigationLink {
                    TopicDetailView(topic: topic)
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(topic.color.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: topic.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(topic.color)
                        }

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
        .navigationTitle("Learning Center")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Topic Detail

private struct TopicDetailView: View {
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

                // Body
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
                        Text("Learn more")
                            .font(.headline)
                            .padding(.bottom, 2)

                        ForEach(topic.links, id: \.url) { link in
                            Link(destination: URL(string: link.url)!) {
                                HStack(spacing: 8) {
                                    Image(systemName: "book")
                                        .font(.caption)
                                        .foregroundStyle(.accent)
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
        .navigationBarTitleDisplayMode(.inline)
    }
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
        paleoHebrew,
        niqqud,
        gematria,
        keyboardLayouts,
        squareScript,
        atbash,
    ]

    static let hebrewAlphabet = LearningTopic(
        title: "The Hebrew Alphabet",
        subtitle: "22 letters, 3000+ years of history",
        icon: "character.textbox",
        color: .blue,
        example: "\u{05D0}\u{05D1}\u{05D2}\u{05D3}\u{05D4}\u{05D5}\u{05D6}\u{05D7}\u{05D8}\u{05D9}\u{05DB}\u{05DC}\u{05DE}\u{05E0}\u{05E1}\u{05E2}\u{05E4}\u{05E6}\u{05E7}\u{05E8}\u{05E9}\u{05EA}",
        sections: [
            Section(heading: nil, body: "The Hebrew alphabet (aleph-bet) consists of 22 consonant letters. It is an abjad \u{2014} a writing system where vowels are typically omitted or indicated with optional diacritical marks called niqqud."),
            Section(heading: "Direction", body: "Hebrew is written and read from right to left. The alphabet has been in continuous use for over 3,000 years, making it one of the oldest writing systems still in active use today."),
            Section(heading: "Final Forms", body: "Five Hebrew letters have special forms when they appear at the end of a word: Kaf (\u{05DB}\u{2192}\u{05DA}), Mem (\u{05DE}\u{2192}\u{05DD}), Nun (\u{05E0}\u{2192}\u{05DF}), Pe (\u{05E4}\u{2192}\u{05E3}), and Tsadi (\u{05E6}\u{2192}\u{05E5}). These are called sofit (final) letters."),
        ],
        links: [
            WikiLink(title: "Hebrew alphabet \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Hebrew_alphabet"),
            WikiLink(title: "Abjad writing system", url: "https://en.wikipedia.org/wiki/Abjad"),
        ]
    )

    static let paleoHebrew = LearningTopic(
        title: "Paleo-Hebrew Script",
        subtitle: "The ancient letterforms of Israel",
        icon: "scroll",
        color: .orange,
        example: "\u{10900}\u{10901}\u{10902}\u{10903}\u{10904} \u{2014} \u{05D0}\u{05D1}\u{05D2}\u{05D3}\u{05D4}",
        sections: [
            Section(heading: nil, body: "Paleo-Hebrew (also called Old Hebrew or Phoenician script) is the original script used to write Hebrew from approximately the 10th century BCE. It is closely related to the Phoenician alphabet and is the ancestor of many modern scripts including Greek, Latin, and Arabic."),
            Section(heading: "Historical Use", body: "This script was used during the First Temple period and appears on ancient inscriptions, coins, and seals. The famous Siloam Inscription (circa 701 BCE) and the Gezer Calendar (circa 10th century BCE) are written in Paleo-Hebrew."),
            Section(heading: "In Unicode", body: "Paleo-Hebrew is encoded in the Phoenician block of Unicode (U+10900\u{2013}U+1091F). While it looks very different from modern Hebrew, each letter maps directly to its modern equivalent \u{2014} Aleph (\u{10900}) is \u{05D0}, Bet (\u{10901}) is \u{05D1}, and so on."),
        ],
        links: [
            WikiLink(title: "Paleo-Hebrew alphabet \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Paleo-Hebrew_alphabet"),
            WikiLink(title: "Phoenician alphabet", url: "https://en.wikipedia.org/wiki/Phoenician_alphabet"),
            WikiLink(title: "Siloam inscription", url: "https://en.wikipedia.org/wiki/Siloam_inscription"),
        ]
    )

    static let niqqud = LearningTopic(
        title: "Niqqud (Vowel Points)",
        subtitle: "How Hebrew marks vowels",
        icon: "eraser",
        color: .purple,
        example: "\u{05E9}\u{05C1}\u{05B8}\u{05DC}\u{05D5}\u{05B9}\u{05DD} \u{2192} \u{05E9}\u{05DC}\u{05D5}\u{05DD}",
        sections: [
            Section(heading: nil, body: "Niqqud is a system of diacritical marks (dots and dashes) placed above or below Hebrew letters to indicate vowel sounds. Since the Hebrew alphabet only represents consonants, niqqud fills in the vowels that readers must otherwise infer from context."),
            Section(heading: "When It\u{2019}s Used", body: "Modern Hebrew text is almost always written without niqqud. Fluent readers infer vowels from context. Niqqud appears mainly in children\u{2019}s books, poetry, liturgical texts, language textbooks, and to disambiguate words that could be read multiple ways."),
            Section(heading: "The Marks", body: "Common niqqud marks include Patach (\u{05B7}, \"a\"), Kamatz (\u{05B8}, \"a/o\"), Tsere (\u{05B5}, \"e\"), Segol (\u{05B6}, \"e\"), Hiriq (\u{05B4}, \"i\"), Holam (\u{05B9}, \"o\"), and Shuruk/Kubutz (\u{05BB}, \"u\"). The dagesh (\u{05BC}) is a dot inside a letter that changes its pronunciation."),
            Section(heading: "Stripping Niqqud", body: "The \u{201C}Strip Niqqud\u{201D} tool removes all these diacritical marks, converting fully vocalized text into the standard unpointed form used in everyday writing."),
        ],
        links: [
            WikiLink(title: "Niqqud \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Niqqud"),
            WikiLink(title: "Tiberian vocalization", url: "https://en.wikipedia.org/wiki/Tiberian_vocalization"),
        ]
    )

    static let gematria = LearningTopic(
        title: "Gematria",
        subtitle: "The numerical value of Hebrew words",
        icon: "number",
        color: .accent,
        example: "\u{05D0}=1  \u{05D1}=2  \u{05D2}=3 \u{2026} \u{05E7}=100  \u{05E8}=200",
        sections: [
            Section(heading: nil, body: "Gematria is the practice of assigning numerical values to Hebrew letters and calculating the sum of a word or phrase. Each of the 22 Hebrew letters has a fixed value: Aleph=1, Bet=2, Gimel=3, and so on up to Tav=400."),
            Section(heading: "The Number System", body: "The first 9 letters represent 1\u{2013}9, the next 9 represent 10\u{2013}90, and the final 4 represent 100\u{2013}400. Final letter forms (sofit) typically carry the same value as their non-final counterparts."),
            Section(heading: "Historical Significance", body: "Gematria has been used for thousands of years in Jewish biblical interpretation (hermeneutics). Words or phrases with equal numerical values are considered to have a hidden connection. For example, the Hebrew word for \u{201C}life\u{201D} (\u{05D7}\u{05D9}) equals 18, which is why 18 is considered a lucky number in Jewish tradition."),
            Section(heading: "Methods", body: "The standard method (Mispar Gadol) is the most common, but there are dozens of other gematria methods including Mispar Katan (reduced value, where each letter\u{2019}s value is its ones digit) and At-Bash (letter substitution cipher)."),
        ],
        links: [
            WikiLink(title: "Gematria \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Gematria"),
            WikiLink(title: "Hebrew numerals", url: "https://en.wikipedia.org/wiki/Hebrew_numerals"),
        ]
    )

    static let keyboardLayouts = LearningTopic(
        title: "Hebrew Keyboard Layout",
        subtitle: "How QWERTY maps to Hebrew",
        icon: "keyboard",
        color: .teal,
        example: "Q\u{2192}\u{05E7}  W\u{2192}\u{05E8}  E\u{2192}\u{05D0}  R\u{2192}\u{05D8}",
        sections: [
            Section(heading: nil, body: "The standard Hebrew keyboard layout maps each key on a QWERTY keyboard to a Hebrew letter. When someone types in English while their keyboard is set to Hebrew (or vice versa), the result is gibberish that maps letter-for-letter to the other layout."),
            Section(heading: "A Common Problem", body: "This happens frequently to bilingual typists. You start typing a URL or password and realize your keyboard was set to the wrong language. The \u{201C}To Hebrew\u{201D} and \u{201C}To English\u{201D} tools reverse this mapping, recovering the intended text without retyping."),
            Section(heading: "The Layout", body: "The Hebrew layout was designed for typewriters and standardized for computers. Some mappings are intuitive (T\u{2192}\u{05D8}, since both are \u{201C}Tet/T\u{201D}), while others are arbitrary. The layout is officially known as SI 1452 and is used in Israel."),
        ],
        links: [
            WikiLink(title: "Hebrew keyboard layout \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Hebrew_keyboard"),
            WikiLink(title: "SI 1452 standard", url: "https://en.wikipedia.org/wiki/Hebrew_keyboard#702_layout_(SI_1452)"),
        ]
    )

    static let squareScript = LearningTopic(
        title: "Square Script (Ktav Ashuri)",
        subtitle: "The modern Hebrew letterforms",
        icon: "character.textbox",
        color: .indigo,
        example: "\u{10900}\u{10901}\u{10902} \u{2192} \u{05D0}\u{05D1}\u{05D2}",
        sections: [
            Section(heading: nil, body: "The \u{201C}square\u{201D} Hebrew script used today is formally known as Ktav Ashuri (\u{201C}Assyrian script\u{201D}). It replaced the older Paleo-Hebrew script after the Babylonian exile in the 6th century BCE, when Jewish scribes adopted the Aramaic square letterforms."),
            Section(heading: "Why \u{201C}Square\u{201D}?", body: "The name comes from the blocky, rectangular shape of the letters. Unlike Paleo-Hebrew\u{2019}s angular, pictographic forms, square script has consistent vertical and horizontal strokes that sit neatly on a baseline."),
            Section(heading: "Sacred Use", body: "Ktav Ashuri is the script used for Torah scrolls, mezuzot, and tefillin. Jewish law (halakha) requires these sacred texts to be written specifically in this script by a trained scribe (sofer)."),
        ],
        links: [
            WikiLink(title: "Hebrew alphabet \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Hebrew_alphabet"),
            WikiLink(title: "Aramaic alphabet", url: "https://en.wikipedia.org/wiki/Aramaic_alphabet"),
        ]
    )

    static let atbash = LearningTopic(
        title: "Text Reversal & Atbash",
        subtitle: "Mirror writing and Hebrew ciphers",
        icon: "arrow.left.arrow.right",
        color: .mint,
        example: "\u{05D0}\u{05D1}\u{05D2} \u{2194} \u{05D2}\u{05D1}\u{05D0}",
        sections: [
            Section(heading: nil, body: "The Reverse tool mirrors Hebrew text character by character while preserving niqqud (vowel marks) attached to each letter. This is useful for fixing text that was pasted in the wrong direction or for creative typography."),
            Section(heading: "Boustrophedon", body: "Some ancient inscriptions were written in \u{201C}boustrophedon\u{201D} style \u{2014} alternating between right-to-left and left-to-right on successive lines (like an ox plowing a field). Reversing text can help read these inscriptions."),
            Section(heading: "Atbash Cipher", body: "Atbash is one of the oldest known ciphers, originating in Hebrew. It substitutes each letter with its reverse-alphabet counterpart: Aleph (\u{05D0}) becomes Tav (\u{05EA}), Bet (\u{05D1}) becomes Shin (\u{05E9}), and so on. The name \u{201C}Atbash\u{201D} itself comes from A-T, B-Sh. It appears in the Book of Jeremiah, where \u{201C}Sheshakh\u{201D} is an Atbash cipher for \u{201C}Babel.\u{201D}"),
        ],
        links: [
            WikiLink(title: "Atbash \u{2014} Wikipedia", url: "https://en.wikipedia.org/wiki/Atbash"),
            WikiLink(title: "Boustrophedon", url: "https://en.wikipedia.org/wiki/Boustrophedon"),
        ]
    )
}
