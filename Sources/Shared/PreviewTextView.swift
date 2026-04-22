import AppKit

@MainActor
final class PreviewTextView: NSView, NSTextViewDelegate {
    private let scrollView: NSScrollView
    private let textView: NSTextView
    private let layoutManager: NSLayoutManager
    private let textContainer: NSTextContainer

    override init(frame frameRect: NSRect) {
        let textStorage = NSTextStorage()
        layoutManager = NSLayoutManager()
        textContainer = NSTextContainer(size: NSSize(width: frameRect.width, height: .greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        textView = NSTextView(frame: .zero, textContainer: textContainer)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 22, height: 22)
        textView.textColor = .labelColor
        textView.linkTextAttributes = [
            .foregroundColor: PreviewStyle.accentColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        textView.usesAdaptiveColorMappingForDarkAppearance = true

        scrollView = NSScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.documentView = textView

        super.init(frame: frameRect)

        textView.delegate = self
        addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func display(_ content: NSAttributedString) {
        textView.textStorage?.setAttributedString(content)
        resizeDocumentView()
        textView.setSelectedRange(NSRange(location: 0, length: 0))
        textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
    }

    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        true
    }

    override func layout() {
        super.layout()
        resizeDocumentView()
    }

    private func resizeDocumentView() {
        let contentWidth = max(scrollView.contentSize.width, 200)
        textContainer.containerSize = NSSize(width: contentWidth, height: .greatestFiniteMagnitude)
        layoutManager.ensureLayout(for: textContainer)

        let usedRect = layoutManager.usedRect(for: textContainer)
        let targetHeight = ceil(usedRect.height + (textView.textContainerInset.height * 2))
        textView.frame = NSRect(x: 0, y: 0, width: contentWidth, height: max(targetHeight, scrollView.contentSize.height))
    }
}
