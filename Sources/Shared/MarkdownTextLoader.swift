import Foundation

struct LoadedMarkdown {
    let url: URL
    let text: String
    let byteCount: Int
    let notices: [String]
}

enum MarkdownLoadError: LocalizedError {
    case unreadableFile
    case emptyFile

    var errorDescription: String? {
        switch self {
        case .unreadableFile:
            return "InkLook could not decode this file as text."
        case .emptyFile:
            return "This file is empty."
        }
    }
}

enum MarkdownTextLoader {
    static let hardLimitBytes = 2_000_000
    static let previewLimitBytes = 250_000

    static func load(from url: URL) throws -> LoadedMarkdown {
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        guard !data.isEmpty else {
            throw MarkdownLoadError.emptyFile
        }

        var notices: [String] = []
        let textData: Data
        if data.count > hardLimitBytes {
            textData = data.prefix(previewLimitBytes)
            notices.append("Preview truncated to the first \(PreviewStyle.fileSize(previewLimitBytes)) to keep Quick Look responsive.")
        } else {
            textData = data
        }

        guard let decoded = decode(textData) else {
            throw MarkdownLoadError.unreadableFile
        }

        return LoadedMarkdown(
            url: url,
            text: decoded.replacingOccurrences(of: "\r\n", with: "\n"),
            byteCount: data.count,
            notices: notices
        )
    }

    private static func decode(_ data: Data) -> String? {
        let encodings: [String.Encoding] = [
            .utf8,
            .utf16,
            .utf16LittleEndian,
            .utf16BigEndian,
            .utf32,
            .ascii,
            .isoLatin1
        ]

        for encoding in encodings {
            if let string = String(data: data, encoding: encoding) {
                return string
            }
        }

        return nil
    }
}
