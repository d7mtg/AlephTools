import SwiftUI

struct ContentView: View {
    @State private var inputText = ""
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

        ToolbarItem(placement: .primaryAction) {
            Button {
                copyToClipboard()
            } label: {
                Label("Copy Output", systemImage: "doc.on.doc")
            }
            .disabled(outputText.isEmpty)
            .keyboardShortcut("c", modifiers: [.command, .shift])
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
                if !inputText.isEmpty {
                    Button {
                        inputText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
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
                    .foregroundStyle(.orange)
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
