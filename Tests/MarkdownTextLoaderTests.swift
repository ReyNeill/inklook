import Foundation
import XCTest

final class MarkdownTextLoaderTests: XCTestCase {
    func testDecodesUtf8File() throws {
        let url = makeTempFile(named: "example.md", contents: "# Hello\n")
        let loaded = try MarkdownTextLoader.load(from: url)
        XCTAssertEqual(loaded.text, "# Hello\n")
        XCTAssertTrue(loaded.notices.isEmpty)
    }

    func testTruncatesLargeFiles() throws {
        let payload = String(repeating: "a", count: MarkdownTextLoader.hardLimitBytes + 1)
        let url = makeTempFile(named: "large.md", contents: payload)
        let loaded = try MarkdownTextLoader.load(from: url)
        XCTAssertEqual(loaded.text.count, MarkdownTextLoader.previewLimitBytes)
        XCTAssertFalse(loaded.notices.isEmpty)
    }

    private func makeTempFile(named name: String, contents: String) -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try? contents.data(using: .utf8)?.write(to: url)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return url
    }
}
