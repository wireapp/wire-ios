//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
    let ephemeralCountdownView: EphemeralCountdownView

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
    private var ephemeralTop: NSLayoutConstraint!

    private var longPressGesture: UILongPressGestureRecognizer!
    private var doubleTapGesture: UITapGestureRecognizer!
    private var singleTapGesture: UITapGestureRecognizer!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.cellView = C.View(frame: .zero)
        cellView.translatesAutoresizingMaskIntoConstraints = false
        self.ephemeralCountdownView = EphemeralCountdownView()
        ephemeralCountdownView.translatesAutoresizingMaskIntoConstraints = false

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        focusStyle = .custom
        selectionStyle = .none
        backgroundColor = .clear
        isOpaque = false

        contentView.addSubview(cellView)
        contentView.addSubview(ephemeralCountdownView)

        self.leading = cellView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        self.trailing = cellView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        self.top = cellView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8)
        self.bottom = contentView.bottomAnchor.constraint(equalTo: cellView.bottomAnchor, constant: 8)
        bottom.priority = UILayoutPriority(999)
        self.ephemeralTop = ephemeralCountdownView.topAnchor.constraint(
            equalTo: cellView.topAnchor,
            constant: cellView.ephemeralTimerTopInset
        )

        let countdownViewLeftInset = conversationHorizontalMargins.left
        NSLayoutConstraint.activate([
            ephemeralCountdownView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            ephemeralCountdownView.trailingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: countdownViewLeftInset
            ),
            ephemeralTop,
            leading,
            trailing,
            top,
            bottom
        ])
        ephemeralTop.constant = cellView.ephemeralTimerTopInset

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
        ephemeralTop.constant = cellView.ephemeralTimerTopInset
        ephemeralCountdownView.isHidden = cellDescription?.showEphemeralTimer == false
        ephemeralCountdownView.message = cellDescription?.message
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        ephemeralTop.constant = cellView.ephemeralTimerTopInset
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

        if let cellDescription = nestedCellDescription(
            using: gestureRecognizer.location(in:)
        ), cellDescription.supportsActions {
            cellDescription.actionController?.performSingleTapAction()
        } else if cellDescription?.supportsActions == true {
            cellDescription?.actionController?.performSingleTapAction()
        }
    }

    // MARK: - Double Tap Action

    @objc
    private func onDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.state == .recognized else { return }

        if let cellDescription = nestedCellDescription(
            using: gestureRecognizer.location(in:)
        ), cellDescription.supportsActions {
            cellDescription.actionController?.performDoubleTapAction()
        } else if cellDescription?.supportsActions == true {
            cellDescription?.actionController?.performDoubleTapAction()
        }
    }

    /// For stack cells get the cell description of the arranged subview.
    /// If no view matches, the top level cell description is returned.
    private func nestedCellDescription(
        using locationInCell: (UIView?) -> CGPoint
    ) -> AnyConversationMessageCellDescription? {
        guard
            let cellView = cellView as? ConversationStackMessageContentView,
            let cellDescription = cellDescription as? StackViewCellDescription
        else { return nil }

        for (index, cell) in cellView.conversationMessageCells.enumerated() {
            let location = locationInCell(cell)
            if cell.bounds.contains(location) {
                return cellDescription.cellDescriptions[index]
            }
        }

        return nil
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
        ephemeralCountdownView.startCountDown()
    }

    override func didEndDisplayingCell() {
        cellDescription?.didEndDisplayingCell()
        cellView.didEndDisplaying()
        ephemeralCountdownView.stopCountDown()
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == singleTapGesture
        else { return super.gestureRecognizerShouldBegin(gestureRecognizer) }

        // We fail the single tap gesture recognizer if there's no single tap action to perform, which gives
        // other gesture recognizers the opportunity to fire.
        if let cellDescription = nestedCellDescription(using: gestureRecognizer.location(in:)) {
            return cellDescription.supportsActions && cellDescription.actionController?.singleTapAction != nil
        } else {
            return cellDescription?.actionController?.singleTapAction != nil
        }
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
