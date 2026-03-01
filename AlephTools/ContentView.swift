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
}

struct ContentView: View {
    @State private var inputText = ""
    @AppStorage("defaultTransform") private var defaultTransformRaw = TransformationType.hebrewKeyboard.rawValue
    @State private var selectedTransform: TransformationType = .hebrewKeyboard
    @State private var keepPunctuation = false
    @State private var showCopiedToast = false

    private var outputText: String {
        guard !inputText.isEmpty else { return "" }
        return TransformationEngine.transform(inputText, mode: selectedTransform, keepPunctuation: keepPunctuation)
    }

    private var stats: ChangeStats {
        ChangeStats.compute(input: inputText, output: outputText, mode: selectedTransform)
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
        .onAppear {
            if let saved = TransformationType.allCases.first(where: { $0.rawValue == defaultTransformRaw }) {
                selectedTransform = saved
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

                if selectedTransform.supportsPunctuationToggle {
                    Divider()
                        .frame(height: 16)

                    Toggle("Keep Punctuation", isOn: $keepPunctuation)
                        .toggleStyle(.checkbox)
                        .controlSize(.small)
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
                Spacer()

                Button {
                    inputText = NSPasteboard.general.string(forType: .string) ?? ""
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste")
                    }
                    .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Paste from clipboard")

                Button {
                    inputText = ""
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
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            LineNumberTextEditor(text: $inputText)
        }
        .frame(minWidth: 280)
        .background(.background)
    }

    // MARK: - Output Panel

    private var outputPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Output")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(selectedTransform.subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)

                Spacer()

                if !inputText.isEmpty {
                    statsView
                }

                if !outputText.isEmpty {
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
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if selectedTransform == .gematria && !outputText.isEmpty {
                gematriaOutput
            } else {
                LineNumberOutputView(text: outputText)
            }
        }
        .frame(minWidth: 280)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }

    // MARK: - Gematria Output

    private var gematriaOutput: some View {
        VStack(spacing: 8) {
            Spacer()
            Text(outputText)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
            Text("Gematria Value")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
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
        showCopiedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopiedToast = false
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 800, height: 500)
}
