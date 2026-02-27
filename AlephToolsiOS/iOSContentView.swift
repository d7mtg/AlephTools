import SwiftUI
import UIKit

struct iOSContentView: View {
    @State private var inputText = ""
    @State private var selectedTransform: TransformationType = .hebrewKeyboard
    @State private var keepPunctuation = false
    @State private var showCopiedToast = false
    @FocusState private var isInputFocused: Bool
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var outputText: String {
        guard !inputText.isEmpty else { return "" }
        return TransformationEngine.transform(inputText, mode: selectedTransform, keepPunctuation: keepPunctuation)
    }

    private var stats: ChangeStats {
        ChangeStats.compute(input: inputText, output: outputText, mode: selectedTransform)
    }

    var body: some View {
        NavigationStack {
            Group {
                if sizeClass == .regular {
                    iPadBody
                } else {
                    iPhoneBody
                }
            }
            .navigationTitle("Aleph Tools")
            .toolbarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
        }
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                toast
                    .transition(.blurReplace)
                    .padding(.bottom, 40)
            }
        }
        .animation(.smooth(duration: 0.3), value: showCopiedToast)
    }

    // MARK: - iPhone

    private var iPhoneBody: some View {
        VStack(spacing: 0) {
            inputCard
                .frame(maxHeight: .infinity)
            transformPill
                .padding(.vertical, 10)
            outputCard
                .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - iPad

    private var iPadBody: some View {
        VStack(spacing: 12) {
            transformPill
            HStack(spacing: 16) {
                inputCard
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                outputCard
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(20)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Input Card

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Input")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if !inputText.isEmpty {
                    Button {
                        withAnimation(.smooth) { inputText = "" }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 4)

            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("Type or paste text\u{2026}")
                        .foregroundStyle(.tertiary)
                        .font(.body)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                TextEditor(text: $inputText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .focused($isInputFocused)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    // MARK: - Transform Pill

    private var transformPill: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(TransformationType.allCases) { t in
                    Button {
                        withAnimation(.smooth) { selectedTransform = t }
                    } label: {
                        Label(t.rawValue, systemImage: t.icon)
                    }
                    .disabled(t == selectedTransform)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedTransform.icon)
                        .foregroundStyle(.tint)
                    Text(selectedTransform.rawValue)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .font(.subheadline)
                .contentTransition(.interpolate)
            }
            .buttonStyle(.plain)

            if selectedTransform.supportsPunctuationToggle {
                Divider()
                    .frame(height: 20)

                Toggle(isOn: $keepPunctuation) {
                    Text("Keep Punc.")
                        .font(.caption)
                }
                .toggleStyle(.button)
                .controlSize(.small)
                .tint(keepPunctuation ? .accentColor : .secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .animation(.smooth, value: selectedTransform.supportsPunctuationToggle)
        .glassEffect(.regular, in: .capsule)
    }

    // MARK: - Output Card

    private var outputCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Output")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(selectedTransform.subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                if !inputText.isEmpty {
                    statsLabel
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

            if selectedTransform == .gematria && !outputText.isEmpty {
                gematriaDisplay
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    Text(outputText.isEmpty ? " " : outputText)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .animation(.smooth, value: selectedTransform)
    }

    // MARK: - Gematria

    private var gematriaDisplay: some View {
        VStack(spacing: 4) {
            Text(outputText)
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .foregroundStyle(.primary)
            Text("Gematria Value")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.bottom, 8)
    }

    // MARK: - Stats

    private var statsLabel: some View {
        HStack(spacing: 8) {
            if stats.changed > 0 {
                Label("\(stats.changed)", systemImage: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.orange)
            }
            if stats.unchanged > 0 {
                Label("\(stats.unchanged)", systemImage: "equal.circle")
                    .foregroundStyle(.tertiary)
            }
        }
        .font(.caption2)
    }

    // MARK: - Toast

    private var toast: some View {
        Label("Copied", systemImage: "checkmark")
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: .capsule)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                copyOutput()
            } label: {
                Label("Copy Output", systemImage: "doc.on.doc")
            }
            .disabled(outputText.isEmpty)
        }
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button {
                isInputFocused = false
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
            }
        }
    }

    // MARK: - Actions

    private func copyOutput() {
        UIPasteboard.general.string = outputText
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showCopiedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopiedToast = false
        }
    }
}

#Preview {
    iOSContentView()
}
