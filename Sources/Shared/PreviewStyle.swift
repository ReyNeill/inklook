import AppKit

enum PreviewStyle {
    static let accentColor = NSColor.systemBlue
    static let secondaryTextColor = NSColor.secondaryLabelColor
    static let quoteBackgroundColor = NSColor.textBackgroundColor.withSystemEffect(.pressed)
    static let codeBackgroundColor = NSColor.controlBackgroundColor
    static let warningBackgroundColor = NSColor.systemYellow.withAlphaComponent(0.18)

    static func headerFont(level: Int) -> NSFont {
        switch level {
        case 1:
            return .systemFont(ofSize: 24, weight: .bold)
        case 2:
            return .systemFont(ofSize: 19, weight: .bold)
        case 3:
            return .systemFont(ofSize: 17, weight: .semibold)
        case 4:
            return .systemFont(ofSize: 15, weight: .semibold)
        default:
            return .systemFont(ofSize: 14, weight: .semibold)
        }
    }

    nonisolated(unsafe) static let bodyFont = NSFont.systemFont(ofSize: 14)
    nonisolated(unsafe) static let captionFont = NSFont.systemFont(ofSize: 12, weight: .medium)
    nonisolated(unsafe) static let codeFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

    static func fileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    static func makeParagraphStyle() -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3
        style.paragraphSpacing = 8
        return style
    }

    static func makeHeaderParagraphStyle(level: Int) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = max(1, CGFloat(4 - min(level, 3)))
        style.paragraphSpacing = level == 1 ? 12 : 10
        return style
    }

    static func makeListParagraphStyle(indentLevel: Int) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        let baseIndent = CGFloat(16 * max(indentLevel, 1))
        style.headIndent = baseIndent
        style.firstLineHeadIndent = 0
        style.paragraphSpacing = 7
        style.lineSpacing = 3
        return style
    }

    static func makeQuoteParagraphStyle(indentLevel: Int) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        let baseIndent = CGFloat(16 * max(indentLevel, 1))
        style.headIndent = baseIndent
        style.firstLineHeadIndent = baseIndent
        style.paragraphSpacing = 7
        style.lineSpacing = 3
        return style
    }
}
