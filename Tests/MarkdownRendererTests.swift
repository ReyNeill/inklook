import AppKit
import XCTest

@MainActor
final class MarkdownRendererTests: XCTestCase {
    func testRendersHeaderAndBody() {
        let loaded = LoadedMarkdown(
            url: URL(fileURLWithPath: "/tmp/test.md"),
            text: "# Heading\n\n**Body**",
            byteCount: 18,
            notices: []
        )

        let rendered = MarkdownRenderer.render(loaded)
        XCTAssertTrue(rendered.attributedString.string.contains("test.md"))
        XCTAssertTrue(rendered.attributedString.string.contains("Heading"))
        XCTAssertTrue(rendered.attributedString.string.contains("Body"))
    }

    func testRenderErrorIncludesMessage() {
        let rendered = MarkdownRenderer.renderError(title: "Preview Unavailable", message: "No text")
        XCTAssertTrue(rendered.string.contains("Preview Unavailable"))
        XCTAssertTrue(rendered.string.contains("No text"))
    }

    func testRestoresParagraphBreaksBetweenBlocks() {
        let loaded = LoadedMarkdown(
            url: URL(fileURLWithPath: "/tmp/test.md"),
            text: "# Heading\n\nParagraph text\n\n## Next",
            byteCount: 34,
            notices: []
        )

        let rendered = MarkdownRenderer.render(loaded)
        XCTAssertTrue(rendered.attributedString.string.contains("Heading\n\nParagraph text\n\nNext"))
    }

    func testFormatsTaskListsWithCheckboxMarkers() {
        let loaded = LoadedMarkdown(
            url: URL(fileURLWithPath: "/tmp/test.md"),
            text: "- [ ] First task\n- [x] Done task",
            byteCount: 31,
            notices: []
        )

        let rendered = MarkdownRenderer.render(loaded)
        XCTAssertTrue(rendered.attributedString.string.contains("☐ First task\n☑ Done task"))
    }
}
