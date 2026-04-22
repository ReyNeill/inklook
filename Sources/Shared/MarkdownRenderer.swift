import AppKit
import Foundation

@MainActor
struct RenderedPreview {
    let attributedString: NSAttributedString
    let notices: [String]
}

@MainActor
enum MarkdownRenderer {
    private static let presentationIntentKey = NSAttributedString.Key("NSPresentationIntent")
    private static let inlinePresentationIntentKey = NSAttributedString.Key("NSInlinePresentationIntent")

    private enum ListKind {
        case unordered
        case ordered
    }

    private struct IntentContext {
        var blockIdentity: Int?
        var headerLevel: Int?
        var listItemIdentity: Int?
        var listItemOrdinal: Int?
        var listDepth = 0
        var quoteDepth = 0
        var isCodeBlock = false
        var isTable = false
        var listKind: ListKind?
    }

    private struct StyledBlock {
        let context: IntentContext
        let content: NSMutableAttributedString
    }

    static func render(_ loaded: LoadedMarkdown) -> RenderedPreview {
        let renderedBody = renderBody(from: loaded)
        let composed = NSMutableAttributedString()
        composed.append(header(for: loaded))

        if !loaded.notices.isEmpty {
            composed.append(noticeBlock(loaded.notices))
        }

        composed.append(renderedBody)
        return RenderedPreview(attributedString: composed, notices: loaded.notices)
    }

    static func renderError(title: String, message: String) -> NSAttributedString {
        let composed = NSMutableAttributedString()
        composed.append(
            NSAttributedString(
                string: "\(title)\n",
                attributes: [
                    .font: PreviewStyle.headerFont(level: 2),
                    .foregroundColor: NSColor.labelColor,
                ]
            )
        )
        composed.append(
            NSAttributedString(
                string: message,
                attributes: [
                    .font: PreviewStyle.bodyFont,
                    .foregroundColor: NSColor.secondaryLabelColor,
                    .paragraphStyle: PreviewStyle.makeParagraphStyle(),
                ]
            )
        )
        return composed
    }

    private static func header(for loaded: LoadedMarkdown) -> NSAttributedString {
        let header = NSMutableAttributedString()
        header.append(
            NSAttributedString(
                string: "\(loaded.url.lastPathComponent)\n",
                attributes: [
                    .font: PreviewStyle.headerFont(level: 2),
                    .foregroundColor: NSColor.labelColor,
                ]
            )
        )

        let subtitle = "Native Markdown preview • \(PreviewStyle.fileSize(loaded.byteCount))\n\n"
        header.append(
            NSAttributedString(
                string: subtitle,
                attributes: [
                    .font: PreviewStyle.captionFont,
                    .foregroundColor: PreviewStyle.secondaryTextColor,
                ]
            )
        )

        return header
    }

    private static func noticeBlock(_ notices: [String]) -> NSAttributedString {
        let text = notices.joined(separator: "\n")
        return NSAttributedString(
            string: "\(text)\n\n",
            attributes: [
                .font: PreviewStyle.bodyFont,
                .foregroundColor: NSColor.labelColor,
                .backgroundColor: PreviewStyle.warningBackgroundColor,
                .paragraphStyle: PreviewStyle.makeParagraphStyle(),
            ]
        )
    }

    private static func renderBody(from loaded: LoadedMarkdown) -> NSAttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .full,
            failurePolicy: .returnPartiallyParsedIfPossible
        )

        do {
            let parsed = try NSAttributedString(
                markdown: Data(loaded.text.utf8),
                options: options,
                baseURL: loaded.url.deletingLastPathComponent()
            )

            if parsed.length == 0 {
                return plainTextFallback(loaded.text)
            }

            return styledString(from: parsed)
        } catch {
            let fallback = NSMutableAttributedString()
            fallback.append(
                noticeBlock(["Markdown parsing failed, so InkLook is showing plain text instead."])
            )
            fallback.append(plainTextFallback(loaded.text))
            return fallback
        }
    }

    private static func plainTextFallback(_ text: String) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                .font: PreviewStyle.codeFont,
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: PreviewStyle.makeParagraphStyle(),
            ]
        )
    }

    private static func styledString(from parsed: NSAttributedString) -> NSAttributedString {
        let rebuilt = NSMutableAttributedString()
        let fullRange = NSRange(location: 0, length: parsed.length)
        var currentBlock: StyledBlock?

        parsed.enumerateAttributes(in: fullRange) { attributes, range, _ in
            let intent = attributes[presentationIntentKey] as? PresentationIntent
            let inlineValue = (attributes[inlinePresentationIntentKey] as? NSNumber)
                .map { InlinePresentationIntent(rawValue: $0.uintValue) } ?? []

            let context = intent.map(intentContext) ?? IntentContext()
            let runText = (parsed.string as NSString).substring(with: range)

            if currentBlock?.context.blockIdentity != context.blockIdentity {
                if let block = currentBlock {
                    rebuilt.append(block.content)
                }

                if let previousContext = currentBlock?.context {
                    rebuilt.append(separatorAfterBlock(previousContext, next: context))
                }

                currentBlock = StyledBlock(
                    context: context,
                    content: NSMutableAttributedString()
                )
            }

            let displayText = normalizedRunText(
                runText,
                isFirstRunInBlock: currentBlock?.content.length == 0,
                context: context
            )

            guard !displayText.isEmpty else {
                return
            }

            currentBlock?.content.append(
                NSAttributedString(
                    string: displayText,
                    attributes: themedAttributes(for: intent, inlineIntent: inlineValue, existing: attributes)
                )
            )
        }

        if let block = currentBlock {
            rebuilt.append(block.content)
        }

        return rebuilt
    }

    private static func themedAttributes(
        for intent: PresentationIntent?,
        inlineIntent: InlinePresentationIntent,
        existing: [NSAttributedString.Key: Any]
    ) -> [NSAttributedString.Key: Any] {
        var font = PreviewStyle.bodyFont
        var color = NSColor.labelColor
        var paragraphStyle = PreviewStyle.makeParagraphStyle()
        var extra: [NSAttributedString.Key: Any] = [:]
        let context = intent.map(intentContext) ?? IntentContext()

        if let headerLevel = context.headerLevel {
            font = PreviewStyle.headerFont(level: max(1, headerLevel))
            paragraphStyle = PreviewStyle.makeHeaderParagraphStyle(level: headerLevel)
        } else if context.isCodeBlock {
            font = PreviewStyle.codeFont
            paragraphStyle = PreviewStyle.makeQuoteParagraphStyle(indentLevel: 1)
            extra[.backgroundColor] = PreviewStyle.codeBackgroundColor
        } else if context.quoteDepth > 0 {
            color = PreviewStyle.secondaryTextColor
            paragraphStyle = PreviewStyle.makeQuoteParagraphStyle(indentLevel: context.quoteDepth)
            extra[.backgroundColor] = PreviewStyle.quoteBackgroundColor
        } else if context.listDepth > 0 {
            paragraphStyle = PreviewStyle.makeListParagraphStyle(indentLevel: context.listDepth)
        } else if context.isTable {
            font = PreviewStyle.codeFont
        }

        if inlineIntent.contains(.code) {
            font = PreviewStyle.codeFont
            extra[.backgroundColor] = PreviewStyle.codeBackgroundColor
        }

        font = adjustedFont(from: font, inlineIntent: inlineIntent)

        if inlineIntent.contains(.strikethrough) {
            extra[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }

        if existing[.link] != nil {
            color = PreviewStyle.accentColor
            extra[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }

        extra[.font] = font
        extra[.foregroundColor] = color
        extra[.paragraphStyle] = paragraphStyle
        return extra
    }

    private static func intentContext(_ intent: PresentationIntent) -> IntentContext {
        var context = IntentContext()

        for component in intent.components {
            switch component.kind {
            case .paragraph:
                context.blockIdentity = component.identity
                break
            case .header(let level):
                context.blockIdentity = component.identity
                context.headerLevel = level
            case .orderedList:
                context.listDepth += 1
                context.listKind = .ordered
            case .unorderedList:
                context.listDepth += 1
                context.listKind = .unordered
            case .listItem(let ordinal):
                context.listItemIdentity = component.identity
                context.listItemOrdinal = ordinal
            case .codeBlock:
                context.blockIdentity = component.identity
                context.isCodeBlock = true
            case .blockQuote:
                context.quoteDepth += 1
            case .thematicBreak:
                break
            case .table:
                context.blockIdentity = component.identity
                context.isTable = true
            case .tableHeaderRow:
                context.blockIdentity = component.identity
                context.isTable = true
            case .tableRow:
                context.blockIdentity = component.identity
                context.isTable = true
            case .tableCell:
                context.blockIdentity = component.identity
                context.isTable = true
            @unknown default:
                break
            }
        }

        return context
    }

    private static func adjustedFont(from base: NSFont, inlineIntent: InlinePresentationIntent) -> NSFont {
        var descriptor = base.fontDescriptor
        var symbolicTraits = descriptor.symbolicTraits

        if inlineIntent.contains(.stronglyEmphasized) {
            symbolicTraits.insert(.bold)
        }

        if inlineIntent.contains(.emphasized) {
            symbolicTraits.insert(.italic)
        }

        descriptor = descriptor.withSymbolicTraits(symbolicTraits)
        return NSFont(descriptor: descriptor, size: base.pointSize) ?? base
    }

    private static func separatorAfterBlock(_ previous: IntentContext, next: IntentContext) -> NSAttributedString {
        let separator: String
        if previous.listItemIdentity != nil && next.listItemIdentity != nil {
            separator = "\n"
        } else if previous.listItemIdentity == next.listItemIdentity && previous.listItemIdentity != nil {
            separator = "\n"
        } else {
            separator = "\n\n"
        }

        let attributes = themedAttributes(for: nil, inlineIntent: [], existing: [:])
        return NSAttributedString(string: separator, attributes: attributes)
    }

    private static func normalizedRunText(
        _ text: String,
        isFirstRunInBlock: Bool,
        context: IntentContext
    ) -> String {
        guard isFirstRunInBlock, context.listItemIdentity != nil else {
            return text
        }

        if text.hasPrefix("[ ] ") {
            return "☐ " + String(text.dropFirst(4))
        }

        if text.hasPrefix("[x] ") || text.hasPrefix("[X] ") {
            return "☑ " + String(text.dropFirst(4))
        }

        let prefix: String
        switch context.listKind {
        case .ordered:
            prefix = "\(context.listItemOrdinal ?? 1). "
        case .unordered, .none:
            prefix = "• "
        }

        return prefix + text
    }
}
