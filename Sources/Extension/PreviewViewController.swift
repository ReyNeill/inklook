import AppKit
import QuickLookUI

final class PreviewViewController: NSViewController, @preconcurrency QLPreviewingController {
    private let previewView = PreviewTextView(frame: .zero)

    override func loadView() {
        view = previewView
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        do {
            let loaded = try MarkdownTextLoader.load(from: url)
            let rendered = MarkdownRenderer.render(loaded)
            previewView.display(rendered.attributedString)
            handler(nil)
        } catch {
            let errorText = MarkdownRenderer.renderError(
                title: "Preview Unavailable",
                message: error.localizedDescription
            )
            previewView.display(errorText)
            handler(nil)
        }
    }
}
