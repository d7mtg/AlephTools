import SwiftUI
import AppKit

// MARK: - AlephTextView (File Drop Support)

class AlephTextView: NSTextView {
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) {
            return .copy
        }
        return super.draggingEntered(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] {
            for url in urls {
                guard url.pathExtension == "txt" || url.pathExtension == "md" || url.pathExtension == "rtf" || url.pathExtension == "" else { continue }
                if let contents = try? String(contentsOf: url, encoding: .utf8) {
                    let range = selectedRange()
                    insertText(contents, replacementRange: range)
                    return true
                }
            }
        }
        return super.performDragOperation(sender)
    }
}

// MARK: - TextEditorCommand (Undo-aware text replacement)

class TextEditorCommand: ObservableObject {
    var replaceAll: ((String) -> Void)?

    func setText(_ newText: String) {
        replaceAll?(newText)
    }
}

// MARK: - OutputViewHandle (Print support)

class OutputViewHandle: ObservableObject {
    var printAction: (() -> Void)?
}

// MARK: - Scroll Sync

class ScrollSyncCoordinator: ObservableObject {
    private var scrollViews: [NSScrollView] = []
    private var isSyncing = false
    var activeLine: Int = 0

    func register(_ scrollView: NSScrollView) {
        guard !scrollViews.contains(where: { $0 === scrollView }) else { return }
        scrollViews.append(scrollView)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(syncScroll(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
    }

    func refreshRulers() {
        for scrollView in scrollViews {
            scrollView.verticalRulerView?.needsDisplay = true
        }
    }

    @objc private func syncScroll(_ notification: Notification) {
        guard !isSyncing,
              let sourceClipView = notification.object as? NSClipView,
              let sourceScrollView = sourceClipView.enclosingScrollView else { return }
        isSyncing = true
        let sourceY = sourceClipView.bounds.origin.y
        for scrollView in scrollViews where scrollView !== sourceScrollView {
            scrollView.contentView.bounds.origin.y = sourceY
            scrollView.reflectScrolledClipView(scrollView.contentView)
            scrollView.verticalRulerView?.needsDisplay = true
        }
        isSyncing = false
    }
}

// MARK: - Line Number Text Editor

struct LineNumberTextEditor: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont = .systemFont(ofSize: 13)
    var isEditable: Bool = true
    var command: TextEditorCommand?
    var scrollSync: ScrollSyncCoordinator?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = AlephTextView()
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.font = font
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.textContainerInset = NSSize(width: 0, height: 4)
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.delegate = context.coordinator
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true

        // Line number gutter
        let rulerView = LineNumberRulerView(scrollView: scrollView, textView: textView, font: font, scrollSync: scrollSync)
        scrollView.verticalRulerView = rulerView
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true

        scrollView.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.scrollSync = scrollSync

        textView.string = text

        scrollSync?.register(scrollView)

        // Wire up undo-aware command
        command?.replaceAll = { [weak textView] newText in
            guard let textView else { return }
            let fullRange = NSRange(location: 0, length: (textView.string as NSString).length)
            textView.insertText(newText, replacementRange: fullRange)
        }

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.textDidChange(_:)),
            name: NSText.didChangeNotification,
            object: textView
        )

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.boundsDidChange(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
        textView.font = font
        textView.isEditable = isEditable
        if let ruler = scrollView.verticalRulerView as? LineNumberRulerView {
            ruler.font = font
            ruler.needsDisplay = true
        }

        // Re-wire command in case the view was recreated
        command?.replaceAll = { [weak textView] newText in
            guard let textView else { return }
            let fullRange = NSRange(location: 0, length: (textView.string as NSString).length)
            textView.insertText(newText, replacementRange: fullRange)
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: LineNumberTextEditor
        weak var textView: NSTextView?
        weak var scrollSync: ScrollSyncCoordinator?

        init(_ parent: LineNumberTextEditor) {
            self.parent = parent
        }

        @objc func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            if parent.text != textView.string {
                parent.text = textView.string
            }
            scrollSync?.refreshRulers()
            textView.enclosingScrollView?.verticalRulerView?.needsDisplay = true
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            scrollSync?.refreshRulers()
            textView?.enclosingScrollView?.verticalRulerView?.needsDisplay = true
        }

        @objc func boundsDidChange(_ notification: Notification) {
            textView?.enclosingScrollView?.verticalRulerView?.needsDisplay = true
        }
    }
}

// MARK: - Line Number Ruler

class LineNumberRulerView: NSRulerView {
    var font: NSFont
    weak var scrollSync: ScrollSyncCoordinator?

    init(scrollView: NSScrollView, textView: NSTextView, font: NSFont, scrollSync: ScrollSyncCoordinator? = nil) {
        self.font = font
        self.scrollSync = scrollSync
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 32
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = clientView as? NSTextView,
              let layoutManager = textView.layoutManager,
              let container = textView.textContainer,
              let scrollView = scrollView else { return }

        let visibleRect = scrollView.contentView.bounds
        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: container)
        let visibleCharRange = layoutManager.characterRange(forGlyphRange: visibleGlyphRange, actualGlyphRange: nil)

        let text = textView.string as NSString
        let lineNumFont: NSFont = {
            let size = font.pointSize - 2
            let base = NSFont.systemFont(ofSize: size, weight: .regular)
            let descriptor = base.fontDescriptor.addingAttributes([
                .featureSettings: [
                    [NSFontDescriptor.FeatureKey.typeIdentifier: kNumberSpacingType,
                     NSFontDescriptor.FeatureKey.selectorIdentifier: kMonospacedNumbersSelector],
                    [NSFontDescriptor.FeatureKey.typeIdentifier: kNumberCaseType,
                     NSFontDescriptor.FeatureKey.selectorIdentifier: kLowerCaseNumbersSelector],
                ],
                .traits: [NSFontDescriptor.TraitKey.width: -0.2],
            ])
            return NSFont(descriptor: descriptor, size: size) ?? base
        }()
        let inactiveAttrs: [NSAttributedString.Key: Any] = [
            .font: lineNumFont,
            .foregroundColor: NSColor.tertiaryLabelColor,
        ]
        let activeAttrs: [NSAttributedString.Key: Any] = [
            .font: lineNumFont,
            .foregroundColor: NSColor.labelColor,
        ]

        // Find which line the cursor is on
        var activeLine = 0
        if textView.isEditable {
            let cursorLocation = min(textView.selectedRange().location, text.length)
            let substring = text.substring(to: cursorLocation)
            activeLine = 1
            for char in substring.unicodeScalars {
                if char == "\n" { activeLine += 1 }
            }
            scrollSync?.activeLine = activeLine
        } else {
            activeLine = scrollSync?.activeLine ?? 0
        }

        var lineNumber = 1

        // Count lines before visible range
        text.enumerateSubstrings(in: NSRange(location: 0, length: visibleCharRange.location), options: [.byLines, .substringNotRequired]) { _, _, _, _ in
            lineNumber += 1
        }

        // Draw visible line numbers
        text.enumerateSubstrings(in: visibleCharRange, options: [.byLines, .substringNotRequired]) { [self] _, substringRange, _, _ in
            let glyphRange = layoutManager.glyphRange(forCharacterRange: substringRange, actualCharacterRange: nil)
            var lineRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: container)
            lineRect.origin.y += textView.textContainerInset.height

            let isActive = lineNumber == activeLine
            let numStr = "\(lineNumber)" as NSString
            let drawAttrs = isActive ? activeAttrs : inactiveAttrs
            let strSize = numStr.size(withAttributes: drawAttrs)
            let drawPoint = NSPoint(
                x: self.ruleThickness - strSize.width - 6,
                y: lineRect.origin.y + (lineRect.height - strSize.height) / 2 - visibleRect.origin.y
            )
            numStr.draw(at: drawPoint, withAttributes: drawAttrs)
            lineNumber += 1
        }
    }
}

// MARK: - Read-Only Output View

struct LineNumberOutputView: NSViewRepresentable {
    let text: String
    var inputText: String = ""
    var font: NSFont = .systemFont(ofSize: 13)
    var handle: OutputViewHandle?
    var scrollSync: ScrollSyncCoordinator?

    func makeCoordinator() -> OutputCoordinator {
        OutputCoordinator()
    }

    class OutputCoordinator {
        var boundsObserver: NSObjectProtocol?

        deinit {
            if let boundsObserver {
                NotificationCenter.default.removeObserver(boundsObserver)
            }
        }
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.font = font
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 0, height: 4)
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true

        let rulerView = LineNumberRulerView(scrollView: scrollView, textView: textView, font: font, scrollSync: scrollSync)
        scrollView.verticalRulerView = rulerView
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true

        scrollView.documentView = textView
        textView.textStorage?.setAttributedString(highlightedOutput(text: text, inputText: inputText, font: font))

        scrollSync?.register(scrollView)

        handle?.printAction = { [weak textView] in
            guard let tv = textView else { return }
            PrintHelper.printOutput(text: tv.string, from: tv)
        }

        context.coordinator.boundsObserver = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { _ in
            rulerView.needsDisplay = true
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.textStorage?.setAttributedString(highlightedOutput(text: text, inputText: inputText, font: font))
        }
        scrollView.verticalRulerView?.needsDisplay = true

        handle?.printAction = { [weak textView] in
            guard let tv = textView else { return }
            PrintHelper.printOutput(text: tv.string, from: tv)
        }
    }

    private func highlightedOutput(text: String, inputText: String, font: NSFont) -> NSAttributedString {
        guard !text.isEmpty, !inputText.isEmpty else {
            return NSAttributedString(string: text, attributes: [
                .font: font,
                .foregroundColor: NSColor.labelColor,
            ])
        }

        let outputChars = Array(text)
        let inputChars = Array(inputText)
        let result = NSMutableAttributedString()

        for (i, char) in outputChars.enumerated() {
            let changed = i >= inputChars.count || char != inputChars[i]
            let color: NSColor = changed ? .controlAccentColor : .tertiaryLabelColor
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
            ]
            result.append(NSAttributedString(string: String(char), attributes: attrs))
        }

        return result
    }
}

// MARK: - Print Helper

enum PrintHelper {
    static func printOutput(text: String, from sourceView: NSView) {
        let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
        printInfo.topMargin = 60
        printInfo.bottomMargin = 50
        printInfo.leftMargin = 50
        printInfo.rightMargin = 50
        printInfo.isVerticallyCentered = false

        // Build attributed string with header
        let result = NSMutableAttributedString()

        // Header line: icon placeholder + title
        let headerPara = NSMutableParagraphStyle()
        headerPara.paragraphSpacingBefore = 0
        headerPara.paragraphSpacing = 4

        let headerStr = NSAttributedString(string: "Aleph Tools\n", attributes: [
            .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: headerPara,
        ])
        result.append(headerStr)

        // Separator (thin line via underlined space trick — use a light rule)
        let rulePara = NSMutableParagraphStyle()
        rulePara.paragraphSpacing = 12
        let ruleStr = NSAttributedString(string: "\n", attributes: [
            .font: NSFont.systemFont(ofSize: 2),
            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            .strikethroughColor: NSColor.separatorColor,
            .paragraphStyle: rulePara,
        ])
        result.append(ruleStr)

        // Content
        let contentPara = NSMutableParagraphStyle()
        contentPara.lineSpacing = 3
        let contentStr = NSAttributedString(string: text, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: contentPara,
        ])
        result.append(contentStr)

        // Footer
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateStr = dateFormatter.string(from: Date())

        let footerPara = NSMutableParagraphStyle()
        footerPara.paragraphSpacingBefore = 16
        let footerRuleStr = NSAttributedString(string: "\n", attributes: [
            .font: NSFont.systemFont(ofSize: 2),
            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            .strikethroughColor: NSColor.separatorColor,
            .paragraphStyle: footerPara,
        ])
        result.append(footerRuleStr)

        let footerTabPara = NSMutableParagraphStyle()
        footerTabPara.paragraphSpacingBefore = 6
        let pageWidth = printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin
        footerTabPara.tabStops = [NSTextTab(textAlignment: .right, location: pageWidth)]
        let footerStr = NSAttributedString(string: "Aleph Tools v\(version)\t\(dateStr)", attributes: [
            .font: NSFont.systemFont(ofSize: 8, weight: .regular),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: footerTabPara,
        ])
        result.append(footerStr)

        // Create text view for printing
        let printableArea = NSSize(
            width: pageWidth,
            height: printInfo.paperSize.height - printInfo.topMargin - printInfo.bottomMargin
        )
        let printTV = NSTextView(frame: NSRect(origin: .zero, size: printableArea))
        printTV.isEditable = false
        printTV.backgroundColor = .white
        printTV.textStorage?.setAttributedString(result)
        printTV.sizeToFit()

        let printOp = NSPrintOperation(view: printTV, printInfo: printInfo)
        printOp.showsPrintPanel = true
        printOp.showsProgressPanel = true

        if let window = sourceView.window {
            printOp.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
        }
    }
}
