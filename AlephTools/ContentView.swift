import SwiftUI

// MARK: - Focused Values

struct FocusedTransformValue: FocusedValueKey {
    typealias Value = Binding<TransformationType>
}

struct FocusedInputTextValue: FocusedValueKey {
    typealias Value = Binding<String>
}

struct FocusedOutputTextValue: FocusedValueKey {
    typealias Value = String
}

struct FocusedKeepPunctuationValue: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct FocusedEditorCommandValue: FocusedValueKey {
    typealias Value = TextEditorCommand
}

struct FocusedPrintValue: FocusedValueKey {
    typealias Value = OutputViewHandle
}

extension FocusedValues {
    var selectedTransform: Binding<TransformationType>? {
        get { self[FocusedTransformValue.self] }
        set { self[FocusedTransformValue.self] = newValue }
    }

    var inputText: Binding<String>? {
        get { self[FocusedInputTextValue.self] }
        set { self[FocusedInputTextValue.self] = newValue }
    }

    var outputText: String? {
        get { self[FocusedOutputTextValue.self] }
        set { self[FocusedOutputTextValue.self] = newValue }
    }

    var keepPunctuation: Binding<Bool>? {
        get { self[FocusedKeepPunctuationValue.self] }
        set { self[FocusedKeepPunctuationValue.self] = newValue }
    }

    var editorCommand: TextEditorCommand? {
        get { self[FocusedEditorCommandValue.self] }
        set { self[FocusedEditorCommandValue.self] = newValue }
    }

    var printHandle: OutputViewHandle? {
        get { self[FocusedPrintValue.self] }
        set { self[FocusedPrintValue.self] = newValue }
    }
}

struct FocusedFontSizeValue: FocusedValueKey {
    typealias Value = Binding<Double>
}

extension FocusedValues {
    var editorFontSize: Binding<Double>? {
        get { self[FocusedFontSizeValue.self] }
        set { self[FocusedFontSizeValue.self] = newValue }
    }
}

struct ContentView: View {
    @AppStorage("lastInputText") private var inputText = ""
    @AppStorage("defaultTransform") private var defaultTransformRaw = TransformationType.hebrewKeyboard.rawValue
    @State private var selectedTransform: TransformationType = .hebrewKeyboard
    @AppStorage("lastKeepPunctuation") private var keepPunctuation = false
    @AppStorage("convertFinalLetters") private var convertFinalLetters = true
    @AppStorage("cleanPunctuation") private var cleanPunctuation = false
    @AppStorage("editorFontSize") private var editorFontSize = 13.0
    @State private var showCopiedToast = false
    @State private var toastWorkItem: DispatchWorkItem?
    @StateObject private var editorCommand = TextEditorCommand()
    @StateObject private var outputHandle = OutputViewHandle()
    @StateObject private var niqqudGenerator = NiqqudGenerator()
    @StateObject private var scrollSync = ScrollSyncCoordinator()

    private var outputText: String {
        guard !inputText.isEmpty else { return "" }
        if selectedTransform == .addNiqqud {
            return niqqudGenerator.output
        }
        return TransformationEngine.transform(inputText, mode: selectedTransform, keepPunctuation: keepPunctuation, convertFinalLetters: convertFinalLetters, cleanPunctuation: cleanPunctuation)
    }

    private var stats: ChangeStats {
        ChangeStats.compute(input: inputText, output: outputText, mode: selectedTransform)
    }

    private var statsAccessibilityLabel: String {
        var parts: [String] = []
        if stats.changed > 0 { parts.append("\(stats.changed) characters changed") }
        if stats.unchanged > 0 { parts.append("\(stats.unchanged) characters kept") }
        return parts.isEmpty ? "No statistics" : parts.joined(separator: ", ")
    }

    var body: some View {
        HSplitView {
            inputPanel
            outputPanel
        }
        .frame(minWidth: 640, minHeight: 400)
        .navigationTitle("Aleph Tools")
        .toolbar { toolbarContent }
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                copiedToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 16)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showCopiedToast)
        .focusedSceneValue(\.selectedTransform, $selectedTransform)
        .focusedSceneValue(\.inputText, $inputText)
        .focusedSceneValue(\.outputText, outputText)
        .focusedSceneValue(\.keepPunctuation, $keepPunctuation)
        .focusedSceneValue(\.editorCommand, editorCommand)
        .focusedSceneValue(\.printHandle, outputHandle)
        .focusedSceneValue(\.editorFontSize, $editorFontSize)
        .onAppear {
            // Restore last used transform, falling back to default
            if let lastRaw = UserDefaults.standard.string(forKey: "lastUsedTransform"),
               let last = TransformationType.allCases.first(where: { $0.rawValue == lastRaw }) {
                selectedTransform = last
            } else if let saved = TransformationType.allCases.first(where: { $0.rawValue == defaultTransformRaw }) {
                selectedTransform = saved
            }
        }
        .onChange(of: selectedTransform) { _, newValue in
            UserDefaults.standard.set(newValue.rawValue, forKey: "lastUsedTransform")
            if newValue == .addNiqqud {
                niqqudGenerator.generate(from: inputText)
            } else {
                niqqudGenerator.cancel()
            }
        }
        .onChange(of: inputText) { _, newValue in
            if selectedTransform == .addNiqqud {
                niqqudGenerator.generate(from: newValue)
            }
        }
        .userActivity(handoffActivityType) { activity in
            activity.isEligibleForHandoff = true
            activity.title = "Aleph Tools — \(selectedTransform.rawValue)"
            activity.userInfo = [
                "inputText": inputText,
                "transformationType": selectedTransform.rawValue,
                "keepPunctuation": keepPunctuation,
            ]
        }
        .onContinueUserActivity(handoffActivityType) { activity in
            guard let info = activity.userInfo else { return }
            if let text = info["inputText"] as? String {
                inputText = text
            }
            if let rawTransform = info["transformationType"] as? String,
               let transform = TransformationType.allCases.first(where: { $0.rawValue == rawTransform }) {
                selectedTransform = transform
            }
            if let punc = info["keepPunctuation"] as? Bool {
                keepPunctuation = punc
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack(spacing: 12) {
                Menu {
                    ForEach(TransformationType.allCases) { t in
                        Button {
                            selectedTransform = t
                        } label: {
                            if t == selectedTransform {
                                Label(t.rawValue, systemImage: "checkmark")
                            } else {
                                Text(t.rawValue)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: selectedTransform.icon)
                            .foregroundStyle(.secondary)
                        Text(selectedTransform.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.tertiary)
                    }
                    .font(.system(.body, weight: .medium))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .accessibilityLabel("Transformation mode")
                .accessibilityHint("Select the text transformation to apply")

                if selectedTransform.supportsPunctuationToggle {
                    Divider()
                        .frame(height: 16)

                    Toggle("Keep Punctuation", isOn: $keepPunctuation)
                        .toggleStyle(.checkbox)
                        .controlSize(.small)
                }

                if selectedTransform.supportsSquareOptions {
                    Divider()
                        .frame(height: 16)

                    Toggle("Final Letters", isOn: $convertFinalLetters)
                        .toggleStyle(.checkbox)
                        .controlSize(.small)
                        .help("Convert כמנפצ to final forms ךםןףץ at word boundaries")

                    Toggle("Clean Punctuation", isOn: $cleanPunctuation)
                        .toggleStyle(.checkbox)
                        .controlSize(.small)
                        .help("Remove brackets, line numbers, and convert dot separators to spaces")
                }
            }
        }

    }

    // MARK: - Input Panel

    private var inputPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Input")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(selectedTransform.inputLabel)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)

                Spacer()

                Button {
                    let pasteText = NSPasteboard.general.string(forType: .string) ?? ""
                    editorCommand.setText(pasteText)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste")
                    }
                    .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(NSPasteboard.general.string(forType: .string) == nil)
                .help("Paste from clipboard")
                .accessibilityLabel("Paste from clipboard")
                .accessibilityHint("Replaces input with clipboard contents")

                Button {
                    editorCommand.setText("")
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                        Text("Clear")
                    }
                    .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(inputText.isEmpty)
                .help("Clear input")
                .accessibilityLabel("Clear input")
                .accessibilityHint("Clears all input text")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            LineNumberTextEditor(text: $inputText, font: .systemFont(ofSize: CGFloat(editorFontSize)), command: editorCommand, scrollSync: scrollSync)
                .clipped()
        }
        .frame(minWidth: 280)
        .background(.background)
        .clipped()
    }

    // MARK: - Output Panel

    private var outputPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Output")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(selectedTransform.outputLabel)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 4)

                statsView
                    .opacity(inputText.isEmpty ? 0 : 1)

                Button {
                    copyToClipboard()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(outputText.isEmpty)
                .accessibilityLabel("Copy output")
                .accessibilityHint("Copies the transformed text to clipboard")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if selectedTransform == .gematria && !outputText.isEmpty {
                gematriaOutput
            } else if selectedTransform == .addNiqqud {
                niqqudOutputPanel
            } else {
                LineNumberOutputView(text: outputText, inputText: inputText, font: .systemFont(ofSize: CGFloat(editorFontSize)), handle: outputHandle, scrollSync: scrollSync)
                    .clipped()
            }
        }
        .frame(minWidth: 280)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipped()
    }

    // MARK: - Gematria Output

    private var formattedGematria: String {
        guard let number = Int(outputText) else { return outputText }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? outputText
    }

    private var gematriaOutput: some View {
        VStack(spacing: 8) {
            Spacer()
            Text(formattedGematria)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.3), value: outputText)
                .accessibilityLabel("Gematria value: \(formattedGematria)")
            Text("Gematria Value")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
    }

    // MARK: - Niqqud Output

    private var niqqudOutputPanel: some View {
        Group {
            if inputText.isEmpty {
                LineNumberOutputView(text: "", font: .systemFont(ofSize: CGFloat(editorFontSize)), handle: outputHandle, scrollSync: scrollSync)
                    .clipped()
            } else if niqqudGenerator.isGenerating {
                VStack(spacing: 12) {
                    Spacer()
                    ProgressView()
                        .controlSize(.large)
                    Text("Adding niqqud\u{2026}")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text("Nakdimon")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = niqqudGenerator.error {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text(error.localizedDescription)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        niqqudGenerator.generate(from: inputText)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                LineNumberOutputView(text: niqqudGenerator.output, inputText: inputText, font: .systemFont(ofSize: CGFloat(editorFontSize)), handle: outputHandle, scrollSync: scrollSync)
                    .clipped()
            }
        }
    }

    // MARK: - Stats

    private var statsView: some View {
        HStack(spacing: 6) {
            if stats.changed > 0 {
                Text("\(stats.changed) changed")
                    .foregroundColor(.accentColor)
            }
            if stats.unchanged > 0 {
                Text("\(stats.unchanged) kept")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .lineLimit(1)
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(statsAccessibilityLabel)
    }

    // MARK: - Toast

    private var copiedToast: some View {
        Label("Copied", systemImage: "checkmark")
            .font(.caption.weight(.medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: - Actions

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(outputText, forType: .string)
        toastWorkItem?.cancel()
        showCopiedToast = true
        let item = DispatchWorkItem { showCopiedToast = false }
        toastWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: item)
    }
}

#Preview {
    ContentView()
        .frame(width: 800, height: 500)
}
