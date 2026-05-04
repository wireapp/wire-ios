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

extension UITableViewCell {

    @objc
    func willDisplayCell() {
        // to be overridden in subclasses
    }

    @objc
    func didEndDisplayingCell() {
        // to be overridden in subclasses
    }

}

final class ConversationMessageCellTableViewAdapter<
    C: ConversationMessageCellDescription
>: UITableViewCell, SelectableView, HighlightableView {

    let cellView: C.View

    var cellDescription: C? {
        didSet {
            longPressGesture.isEnabled = cellDescription?.supportsActions == true
            doubleTapGesture.isEnabled = cellDescription?.supportsActions == true
            singleTapGesture.isEnabled = cellDescription?.supportsActions == true
        }
    }

    private var leading: NSLayoutConstraint!
    private var top: NSLayoutConstraint!
    private var trailing: NSLayoutConstraint!
    private var bottom: NSLayoutConstraint!

    private var existingHorizontalConstraints: [NSLayoutConstraint] = []
    private var ownMessagesHorizontalConstraints: [NSLayoutConstraint] = []
    private var othersMessagesHorizontalConstraints: [NSLayoutConstraint] = []

    private var longPressGesture: UILongPressGestureRecognizer!
    private var doubleTapGesture: UITapGestureRecognizer!
    private var singleTapGesture: UITapGestureRecognizer!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.cellView = C.View(frame: .zero)
        cellView.translatesAutoresizingMaskIntoConstraints = false

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        focusStyle = .custom
        selectionStyle = .none
        backgroundColor = .clear
        isOpaque = false

        contentView.addSubview(cellView)

        self.leading = cellView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        self.trailing = cellView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        self.top = cellView.topAnchor.constraint(equalTo: contentView.topAnchor)
        self.bottom = contentView.bottomAnchor.constraint(equalTo: cellView.bottomAnchor)
        bottom.priority = UILayoutPriority(999)

        self.existingHorizontalConstraints = [leading, trailing]

        NSLayoutConstraint.activate([
            top,
            bottom
        ])

        self.longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress))
        contentView.addGestureRecognizer(longPressGesture)

        self.doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTapGesture)

        self.singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onSingleTap))
        cellView.addGestureRecognizer(singleTapGesture)
        singleTapGesture.require(toFail: doubleTapGesture)
        singleTapGesture.delegate = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with object: C.View.Configuration) {
        cellView.configure(with: object, animated: false)
        cellView.accessibilityLabel = cellDescription?.accessibilityLabel
        cellView.accessibilityIdentifier = cellDescription?.accessibilityIdentifier
        top.constant = cellDescription?.topMargin ?? 0
        bottom.constant = cellDescription?.bottomMargin ?? 0
        configureChatBubbleConstraints()
    }

    private func configureChatBubbleConstraints() {
        // Deactivate all horizontal constraints before applying new ones.
        NSLayoutConstraint.deactivate(
            ownMessagesHorizontalConstraints +
                othersMessagesHorizontalConstraints
        )
        let othersMessagesLeadingConstraint = cellView.leadingAnchor.constraint(
            equalTo: contentView.leadingAnchor,
            constant: isCellAlreadyAligned() ? 0 : conversationHorizontalMargins.left
        )

        if isBubbleHasMaximumWidth() {
            ownMessagesHorizontalConstraints = [
                cellView.leadingAnchor
                    .constraint(
                        equalTo: contentView.leadingAnchor,
                        constant: conversationHorizontalMargins.chatBubbleMinimumLeading
                    ),
                cellView.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -conversationHorizontalMargins.right
                )
            ]

            othersMessagesHorizontalConstraints = [
                othersMessagesLeadingConstraint,
                cellView.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -conversationHorizontalMargins.chatBubbleMinimumTrailing
                )
            ]

        } else {
            ownMessagesHorizontalConstraints = [
                cellView.leadingAnchor
                    .constraint(
                        greaterThanOrEqualTo: contentView.leadingAnchor,
                        constant: conversationHorizontalMargins.chatBubbleMinimumLeading
                    ),
                cellView.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -conversationHorizontalMargins.right
                )
            ]

            othersMessagesHorizontalConstraints = [
                othersMessagesLeadingConstraint,
                cellView.trailingAnchor.constraint(
                    lessThanOrEqualTo: contentView.trailingAnchor,
                    constant: -conversationHorizontalMargins.chatBubbleMinimumTrailing
                )
            ]
        }

        if cellDescription?.shouldAlignMessageContentForBubbles == true {
            if cellDescription?.message?.isSentBySelfUser == true {
                // Right-align the bubble content
                NSLayoutConstraint.activate(ownMessagesHorizontalConstraints)
            } else {
                // Left-align the bubble content
                NSLayoutConstraint.activate(othersMessagesHorizontalConstraints)
            }
        } else {
            setupExistingLayout()
        }
        setNeedsLayout()
    }

    private func isCellAlreadyAligned() -> Bool {
        guard let cellDescription else { return false }
        return cellDescription.isCellAlreadyAligned
    }

    private func isBubbleHasMaximumWidth() -> Bool {
        guard let cellDescription else { return false }
        return cellDescription.isBubbleHasMaximumWidth
    }

    private func setupExistingLayout() {
        NSLayoutConstraint.activate(existingHorizontalConstraints)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        UIView.animate(withDuration: 0.35) {
            self.cellView.isSelected = selected
            self.layoutIfNeeded()
        }
    }

    // MARK: - Menu

    @objc
    private func onLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            cellView.menuPresenter?.showMenu()
        }
    }

    // MARK: - Single Tap Action

    @objc
    private func onSingleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.state == .recognized else { return }

        if cellDescription?.supportsActions == true {
            cellDescription?.actionController?.performSingleTapAction()
        }
    }

    // MARK: - Double Tap Action

    @objc
    private func onDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.state == .recognized else { return }

        if cellDescription?.supportsActions == true {
            cellDescription?.actionController?.performDoubleTapAction()
        }
    }

    // MARK: - SelectableView

    var selectionView: UIView! {
        cellView.selectionView ?? self
    }

    var selectionRect: CGRect {
        if cellView.selectionView != nil {
            cellView.selectionRect
        } else {
            bounds
        }
    }

    var highlightContainer: UIView {
        self
    }

    override func willDisplayCell() {
        cellDescription?.willDisplayCell()
        cellView.willDisplay()
    }

    override func didEndDisplayingCell() {
        cellDescription?.didEndDisplayingCell()
        cellView.didEndDisplaying()
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == singleTapGesture
        else { return super.gestureRecognizerShouldBegin(gestureRecognizer) }

        // We fail the single tap gesture recognizer if there's no single tap action to perform, which gives
        // other gesture recognizers the opportunity to fire.
        return cellDescription?.actionController?.singleTapAction != nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cellView.prepareForReuse()
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        _ = cellView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: horizontalFittingPriority,
            verticalFittingPriority: verticalFittingPriority
        )
        return super.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: horizontalFittingPriority,
            verticalFittingPriority: verticalFittingPriority
        )
    }
}

extension UITableView {

    func register<C: ConversationMessageCellDescription>(cell: C.Type) {
        let reuseIdentifier = String(describing: C.self)
        register(ConversationMessageCellTableViewAdapter<C>.self, forCellReuseIdentifier: reuseIdentifier)
    }

    func dequeueConversationCell<C: ConversationMessageCellDescription>(
        with description: C,
        for indexPath: IndexPath
    ) -> ConversationMessageCellTableViewAdapter<C> {
        let reuseIdentifier = String(describing: C.self)

        let cell = dequeueReusableCell(
            withIdentifier: reuseIdentifier,
            for: indexPath
        ) as Any as! ConversationMessageCellTableViewAdapter<C>

        cell.cellDescription = description
        cell.configure(with: description.configuration)

        return cell
    }

}
