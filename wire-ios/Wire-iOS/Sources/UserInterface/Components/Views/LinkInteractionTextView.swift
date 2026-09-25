//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import UIKit
import WireDataModel

protocol TextViewInteractionDelegate: AnyObject {
    func textView(_ textView: LinkInteractionTextView, open url: URL) -> Bool
    func textViewDidLongPress(_ textView: LinkInteractionTextView)
}

final class LinkInteractionTextView: UITextView {
    weak var interactionDelegate: TextViewInteractionDelegate?

    override var selectedTextRange: UITextRange? {
        get { nil }
        set { /* no-op */ }
    }

    // URLs with these schemes should be handled by the os.
    fileprivate let dataDetectedURLSchemes = ["x-apple-data-detectors", "tel", "mailto"]

    /// Creates a text view backed by a `BlockquoteLayoutManager` so that
    /// markdown blockquotes render with a vertical accent bar on the left.
    static func withBlockquoteBars() -> LinkInteractionTextView {
        let storage = NSTextStorage()
        let layoutManager = BlockquoteLayoutManager()
        let container = NSTextContainer(size: CGSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        ))
        container.widthTracksTextView = true
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)
        return LinkInteractionTextView(frame: .zero, textContainer: container)
    }

    private var blockquoteLayoutManager: BlockquoteLayoutManager? {
        layoutManager as? BlockquoteLayoutManager
    }

    var blockquoteBarColor: UIColor? {
        get { blockquoteLayoutManager?.barColor }
        set { if let color = newValue { blockquoteLayoutManager?.barColor = color } }
    }

    var codeBackgroundColor: UIColor? {
        get { blockquoteLayoutManager?.codeBackgroundColor }
        set { if let color = newValue { blockquoteLayoutManager?.codeBackgroundColor = color } }
    }

    func applyMarkdownColors(_ baseColor: UIColor) {
        blockquoteBarColor = baseColor.withAlphaComponent(0.6)
        codeBackgroundColor = baseColor.withAlphaComponent(0.12)
    }

    override init(
        frame: CGRect,
        textContainer: NSTextContainer?
    ) {
        super.init(frame: frame, textContainer: textContainer)
        delegate = self

        textDragDelegate = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var lastLayoutWidth: CGFloat?

    // `intrinsicContentSize`'s default UITextView implementation must be recomputed whenever
    // `bounds.width` changes width, the same way UILabel recomputes from
    // `preferredMaxLayoutWidth`. Inside a chat bubble that hugs its content, Auto Layout
    // narrows this view across candidate widths while solving; without invalidating here, a
    // wrap decision made at an earlier (wider) candidate width would stick.
    override func layoutSubviews() {
        super.layoutSubviews()

        if lastLayoutWidth != bounds.width {
            lastLayoutWidth = bounds.width
            invalidateIntrinsicContentSize()
        }
    }

    // UITextView's own `sizeThatFits`/`intrinsicContentSize` under-measures paragraphs that
    // use an explicit `NSTextTab` stop (as Down's list rendering does for the "1.\t" / "•\t"
    // prefix): it can report a one-line width a few points narrower than what the text
    // actually needs, so the container ends up one line too short and the last word of a
    // single-item list silently falls off the bottom instead of wrapping (WPB-27203).
    // `NSAttributedString.boundingRect` performs the same line-breaking TextKit does when it
    // actually draws the text and measures tab stops correctly, so use it directly instead.
    override var intrinsicContentSize: CGSize {
        guard let attributedText, !attributedText.string.isEmpty else {
            return super.intrinsicContentSize
        }

        let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let unboundedSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let naturalWidth = attributedText.boundingRect(with: unboundedSize, options: options, context: nil).width

        // Once Auto Layout has actually compressed us narrower than our natural (one-line)
        // width, report the height needed to wrap at that narrower width; otherwise report
        // the one-line height.
        let measuredWidth = if bounds.width > 0, bounds.width < naturalWidth {
            bounds.width
        } else {
            naturalWidth
        }
        let height = attributedText.boundingRect(
            with: CGSize(width: measuredWidth, height: CGFloat.greatestFiniteMagnitude),
            options: options,
            context: nil
        ).height

        return CGSize(width: ceil(naturalWidth), height: ceil(height))
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let isInside = super.point(inside: point, with: event)
        guard !UIMenuController.shared.isMenuVisible else { return false }
        guard let position = characterRange(at: point), isInside else { return false }
        let index = offset(from: beginningOfDocument, to: position.start)
        return urlAttribute(at: index)
    }

    private func urlAttribute(at index: Int) -> Bool {
        guard attributedText.length > 0 else { return false }
        let attributes = attributedText.attributes(at: index, effectiveRange: nil)
        return attributes[.link] != nil
    }

    /// Returns an alert controller configured to open the given URL.
    private func confirmationAlert(for url: URL) -> UIAlertController {
        let alert = UIAlertController(
            title: L10n.Localizable.Content.Message.OpenLinkAlert.title,
            message: L10n.Localizable.Content.Message.OpenLinkAlert.message(url.absoluteString),
            preferredStyle: .alert
        )

        let okAction = UIAlertAction(title: L10n.Localizable.Content.Message.OpenLinkAlert.open, style: .default) { _ in
            _ = self.interactionDelegate?.textView(self, open: url)
        }

        alert.addAction(.cancel())
        alert.addAction(okAction)
        return alert
    }

    private func isMarkdownLink(in range: NSRange) -> Bool {
        attributedText.ranges(containing: .link, inRange: range) == [range]
    }

    /// An alert is shown (asking the user if they wish to open the url) if the
    /// link in the specified range is a markdown link.
    fileprivate func showAlertIfNeeded(for url: URL, in range: NSRange) -> Bool {
        // only show alert if the link is a markdown link
        guard isMarkdownLink(in: range) else {
            return false
        }

        confirmationAlert(for: url).presentOverAll(animated: true)
        return true
    }
}

extension LinkInteractionTextView: UITextViewDelegate {

    func textView(
        _ textView: UITextView,
        shouldInteractWith textAttachment: NSTextAttachment,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        guard interaction == .presentActions else { return true }
        interactionDelegate?.textViewDidLongPress(self)
        return false
    }

    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        // present system context preview
        if  UIApplication.shared.canOpenURL(URL),
            interaction == .presentActions,
            !isMarkdownLink(in: characterRange),
            Settings.isClipboardEnabled {
            return true
        }

        switch interaction {
        case .invokeDefaultAction:

            guard !UIMenuController.shared.isMenuVisible else {
                return false // Don't open link/show alert if menu controller is visible
            }

            let performLinkInteraction: () -> Bool = {
                // if alert shown, link opening is handled in alert actions
                if self.showAlertIfNeeded(for: URL, in: characterRange) { return false }

                // data detector links should be handle by the system
                return self.dataDetectedURLSchemes
                    .contains(URL.scheme ?? "") || !(self.interactionDelegate?.textView(self, open: URL) ?? false)
            }

            return performLinkInteraction()

        case .presentActions,
             .preview:
            // do not allow peeking links, as it blocks showing the menu for replies
            interactionDelegate?.textViewDidLongPress(self)
            return false

        @unknown default:
            interactionDelegate?.textViewDidLongPress(self)
            return false
        }
    }
}

// MARK: - UITextDragDelegate

extension LinkInteractionTextView: UITextDragDelegate {

    func textDraggableView(
        _ textDraggableView: UIView & UITextDraggable,
        itemsForDrag dragRequest: UITextDragRequest
    ) -> [UIDragItem] {

        func isMentionLink(_ attributeTuple: (NSAttributedString.Key, Any)) -> Bool {
            attributeTuple.0 == NSAttributedString.Key.link && (attributeTuple.1 as? NSURL)?.scheme == Mention
                .mentionScheme
        }

        if let attributes = textStyling(at: dragRequest.dragRange.start, in: .forward) {
            if attributes.contains(where: isMentionLink) {
                return []
            }
        }

        return dragRequest.suggestedItems
    }

}
