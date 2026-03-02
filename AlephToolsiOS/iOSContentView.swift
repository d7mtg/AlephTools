import SwiftUI
import UIKit

struct iOSContentView: View {
    @State private var inputText = ""
    @AppStorage("defaultTransform") private var defaultTransformRaw = TransformationType.hebrewKeyboard.rawValue
    @State private var selectedTransform: TransformationType = .hebrewKeyboard
    @State private var keepPunctuation = false
    @State private var convertFinalLetters = true
    @State private var cleanPunctuation = false
    @State private var showSettings = false
    @State private var showCopiedToast = false
    @AppStorage("hasCompletedKeyboardSetup") private var hasCompletedKeyboardSetup = false
    @State private var showKeyboardSetup = false
    @FocusState private var isInputFocused: Bool
    @Environment(\.horizontalSizeClass) private var sizeClass
    @StateObject private var niqqudGenerator = NiqqudGenerator()

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
        .onChange(of: selectedTransform) { _, newValue in
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

            if selectedTransform.supportsSquareOptions {
                Divider()
                    .frame(height: 20)

                Toggle(isOn: $convertFinalLetters) {
                    Text("Finals")
                        .font(.caption)
                }
                .toggleStyle(.button)
                .controlSize(.small)
                .tint(convertFinalLetters ? .accentColor : .secondary)

                Toggle(isOn: $cleanPunctuation) {
                    Text("Clean")
                        .font(.caption)
                }
                .toggleStyle(.button)
                .controlSize(.small)
                .tint(cleanPunctuation ? .accentColor : .secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .geometryGroup()
        .animation(.smooth, value: selectedTransform.supportsPunctuationToggle)
        .animation(.smooth, value: selectedTransform.supportsSquareOptions)
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
            } else if selectedTransform == .addNiqqud && !inputText.isEmpty {
                niqqudOutputContent
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

    private var formattedGematria: String {
        guard let number = Int(outputText) else { return outputText }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? outputText
    }

    private var gematriaDisplay: some View {
        VStack(spacing: 4) {
            Text(formattedGematria)
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.3), value: outputText)
                .foregroundStyle(.primary)
            Text("Gematria Value")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.bottom, 8)
    }

    // MARK: - Niqqud Output

    private var niqqudOutputContent: some View {
        Group {
            if niqqudGenerator.isGenerating {
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
                .frame(maxWidth: .infinity)
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
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView {
                    Text(niqqudGenerator.output.isEmpty ? " " : niqqudGenerator.output)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
        }
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
