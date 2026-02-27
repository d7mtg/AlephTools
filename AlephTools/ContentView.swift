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
        VStack(spacing: 0) {
            header
            Divider()
            HSplitView {
                inputPanel
                outputPanel
            }
        }
        .frame(minWidth: 640, minHeight: 400)
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                copiedToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 16)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showCopiedToast)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Text("א")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(.primary)

            Text("Aleph Tools")
                .font(.headline)

            Text("v3.3")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if selectedTransform.supportsPunctuationToggle {
                Toggle("Keep Punctuation", isOn: $keepPunctuation)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                    .controlSize(.small)
            }

            Picker("Transform", selection: $selectedTransform) {
                ForEach(TransformationType.allCases) { t in
                    Label(t.rawValue, systemImage: t.icon)
                        .tag(t)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 200)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - Input Panel

    private var inputPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Input", systemImage: "text.cursor")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                if !inputText.isEmpty {
                    Button("Clear") {
                        inputText = ""
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            TextEditor(text: $inputText)
                .font(.system(size: 16, design: .default))
                .scrollContentBackground(.hidden)
                .padding(8)
        }
        .frame(minWidth: 280)
        .background(.background)
    }

    // MARK: - Output Panel

    private var outputPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label(selectedTransform.rawValue, systemImage: selectedTransform.icon)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(selectedTransform.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                if !inputText.isEmpty {
                    statsView
                }

                Button {
                    copyToClipboard()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(outputText.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            ScrollView {
                if selectedTransform == .gematria && !outputText.isEmpty {
                    gematriaOutput
                } else {
                    Text(outputText)
                        .font(.system(size: 16, design: selectedTransform == .paleoHebrew ? .serif : .default))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
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
        HStack(spacing: 8) {
            if stats.changed > 0 {
                Label("\(stats.changed)", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
            if stats.unchanged > 0 {
                Label("\(stats.unchanged)", systemImage: "equal.circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Toast

    private var copiedToast: some View {
        Text("Copied!")
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
