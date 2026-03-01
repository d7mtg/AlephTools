import SwiftUI
import UIKit

struct iOSContentView: View {
    @State private var inputText = ""
    @AppStorage("defaultTransform") private var defaultTransformRaw = TransformationType.hebrewKeyboard.rawValue
    @State private var selectedTransform: TransformationType = .hebrewKeyboard
    @State private var keepPunctuation = false
    @State private var showSettings = false
    @State private var showCopiedToast = false
    @AppStorage("hasCompletedKeyboardSetup") private var hasCompletedKeyboardSetup = false
    @State private var showKeyboardSetup = false
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
            .sheet(isPresented: $showSettings) {
                iOSSettingsView()
            }
            .fullScreenCover(isPresented: $showKeyboardSetup) {
                KeyboardSetupView()
            }
        }
        .onAppear {
            if let saved = TransformationType.allCases.first(where: { $0.rawValue == defaultTransformRaw }) {
                selectedTransform = saved
            }
            if !hasCompletedKeyboardSetup {
                showKeyboardSetup = true
            }
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
                VStack(alignment: .leading, spacing: 2) {
                    Text("Input")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(selectedTransform.inputLabel)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()

                Button {
                    if let clip = UIPasteboard.general.string {
                        withAnimation(.smooth) { inputText = clip }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste")
                    }
                    .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    withAnimation(.smooth) { inputText = "" }
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
        .geometryGroup()
        .animation(.smooth, value: selectedTransform.supportsPunctuationToggle)
        .glassEffect(.regular, in: .capsule)
    }

    // MARK: - Output Card

    private var outputCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Output")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(selectedTransform.outputLabel)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()

                statsLabel
                    .opacity(inputText.isEmpty ? 0 : 1)

                Button {
                    copyOutput()
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
        ToolbarItem(placement: .navigation) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "info.circle")
            }
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
