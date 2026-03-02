import SwiftUI

struct ShareView: View {
    let inputText: String
    let onDone: () -> Void

    @State private var selectedTransform: TransformationType = .hebrewKeyboard
    @State private var keepPunctuation = false
    @State private var convertFinalLetters = true
    @State private var cleanPunctuation = false
    @State private var showCopied = false

    private var outputText: String {
        guard !inputText.isEmpty else { return "" }
        return TransformationEngine.transform(inputText, mode: selectedTransform, keepPunctuation: keepPunctuation, convertFinalLetters: convertFinalLetters, cleanPunctuation: cleanPunctuation)
    }

    // Exclude AI-powered transforms that need CoreML model
    private var availableTransforms: [TransformationType] {
        TransformationType.allCases.filter { $0 != .addNiqqud }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Transform picker
                Picker("Transformation", selection: $selectedTransform) {
                    ForEach(availableTransforms) { t in
                        Label(t.rawValue, systemImage: t.icon)
                            .tag(t)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if selectedTransform.supportsPunctuationToggle {
                    Toggle("Keep Punctuation", isOn: $keepPunctuation)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }

                if selectedTransform.supportsSquareOptions {
                    Toggle("Convert Final Letters (ם ן ך ף ץ)", isOn: $convertFinalLetters)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                    Toggle("Clean Punctuation", isOn: $cleanPunctuation)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }

                Divider()

                // Input preview
                VStack(alignment: .leading, spacing: 4) {
                    Text("Input")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(inputText)
                        .font(.body)
                        .lineLimit(3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)

                Divider()

                // Output
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Output")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        if selectedTransform == .gematria {
                            Text(outputText)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        } else {
                            Text(outputText)
                                .font(.body)
                                .textSelection(.enabled)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                }

                Divider()

                // Copy button
                Button {
                    UIPasteboard.general.string = outputText
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        showCopied = false
                    }
                } label: {
                    HStack {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        Text(showCopied ? "Copied" : "Copy Result")
                    }
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(16)
                .disabled(outputText.isEmpty)
            }
            .navigationTitle("Aleph Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDone() }
                }
            }
        }
    }
}
