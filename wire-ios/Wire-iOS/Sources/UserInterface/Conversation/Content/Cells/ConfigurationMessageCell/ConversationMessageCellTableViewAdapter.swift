//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

// MARK: - ConversationMessageCellMenuPresenter

protocol ConversationMessageCellMenuPresenter: AnyObject {
    func showMenu()
    func showSecuredMenu()
}

extension UITableViewCell {
    @objc
    func willDisplayCell() {
        // to be overriden in subclasses
    }

    @objc
    func didEndDisplayingCell() {
        // to be overriden in subclasses
    }
}

// MARK: - ConversationMessageCellTableViewAdapter

class ConversationMessageCellTableViewAdapter<C: ConversationMessageCellDescription>: UITableViewCell, SelectableView,
    HighlightableView, ConversationMessageCellMenuPresenter {
    // MARK: Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.cellView = C.View(frame: .zero)
        cellView.translatesAutoresizingMaskIntoConstraints = false
        self.ephemeralCountdownView = EphemeralCountdownView()
        ephemeralCountdownView.translatesAutoresizingMaskIntoConstraints = false

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.focusStyle = .custom
        self.selectionStyle = .none
        self.backgroundColor = .clear
        self.isOpaque = false

        contentView.addSubview(cellView)
        contentView.addSubview(ephemeralCountdownView)

        self.leading = cellView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        self.trailing = cellView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        self.top = cellView.topAnchor.constraint(equalTo: contentView.topAnchor)
        self.bottom = cellView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        bottom.priority = UILayoutPriority(999)
        self.ephemeralTop = ephemeralCountdownView.topAnchor.constraint(equalTo: cellView.topAnchor)

        NSLayoutConstraint.activate([
            ephemeralCountdownView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            ephemeralCountdownView.trailingAnchor.constraint(equalTo: cellView.leadingAnchor),
            ephemeralTop,
            leading,
            trailing,
            top,
            bottom,
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

    // MARK: Internal

    var cellView: C.View
    var ephemeralCountdownView: EphemeralCountdownView

    var cellDescription: C? {
        didSet {
            longPressGesture.isEnabled = cellDescription?.supportsActions == true
            doubleTapGesture.isEnabled = cellDescription?.supportsActions == true
            singleTapGesture.isEnabled = cellDescription?.supportsActions == true
        }
    }

    var topMargin: Float = 0 {
        didSet {
            top.constant = CGFloat(topMargin)
        }
    }

    var isFullWidth = false {
        didSet {
            configureConstraints(fullWidth: isFullWidth)
        }
    }

    override var accessibilityIdentifier: String? {
        get {
            cellDescription?.accessibilityIdentifier
        }

        set {
            super.accessibilityIdentifier = newValue
        }
    }

    override var accessibilityLabel: String? {
        get {
            cellDescription?.accessibilityLabel
        }

        set {
            super.accessibilityLabel = newValue
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

    func configure(with object: C.View.Configuration, fullWidth: Bool, topMargin: Float) {
        cellView.configure(with: object, animated: false)
        isFullWidth = fullWidth
        self.topMargin = topMargin
        ephemeralCountdownView.isHidden = cellDescription?.showEphemeralTimer == false
        ephemeralCountdownView.message = cellDescription?.message
    }

    func configureConstraints(fullWidth: Bool) {
        let margins = conversationHorizontalMargins

        leading.constant = fullWidth ? 0 : margins.left
        trailing.constant = fullWidth ? 0 : -margins.right
        ephemeralTop.constant = cellView.ephemeralTimerTopInset
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureConstraints(fullWidth: isFullWidth)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        UIView.animate(withDuration: 0.35, animations: {
            self.cellView.isSelected = selected
            self.layoutIfNeeded()
        })
    }

    // MARK: - Menu

    func showMenu() {
        guard let controller = messageActionsMenuController(with: MessageAction.allCases) else {
            return
        }
        display(messageActionsController: controller)
    }

    func showSecuredMenu() {
        let actions = [
            MessageAction.visitLink,
            MessageAction.reply,
            MessageAction.edit,
            MessageAction.openDetails,
            MessageAction.delete,
            MessageAction.cancel,
        ]
        guard let controller = messageActionsMenuController(with: actions) else {
            return
        }
        display(messageActionsController: controller)
    }

    func display(messageActionsController: MessageActionsViewController) {
        cellView.delegate?.conversationMessageWantsToShowActionsController(
            cellView,
            actionsController: messageActionsController
        )
    }

    func messageActionsMenuController(
        with actions: [MessageAction] = MessageAction
            .allCases
    ) -> MessageActionsViewController? {
        guard let actionController = cellDescription?.actionController else {
            return nil
        }
        let actionsMenuController = MessageActionsViewController.controller(
            withActions: actions,
            actionController: actionController
        )

        if let popoverPresentationController = actionsMenuController.popoverPresentationController {
            popoverPresentationController.sourceView = cellView
        }

        return actionsMenuController
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
        else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }

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

    // MARK: Private

    private var leading: NSLayoutConstraint!
    private var top: NSLayoutConstraint!
    private var trailing: NSLayoutConstraint!
    private var bottom: NSLayoutConstraint!
    private var ephemeralTop: NSLayoutConstraint!

    private var longPressGesture: UILongPressGestureRecognizer!
    private var doubleTapGesture: UITapGestureRecognizer!
    private var singleTapGesture: UITapGestureRecognizer!

    @objc
    private func onLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            showMenu()
        }
    }

    // MARK: - Single Tap Action

    @objc
    private func onSingleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .recognized, cellDescription?.supportsActions == true {
            cellDescription?.actionController?.performSingleTapAction()
        }
    }

    // MARK: - Double Tap Action

    @objc
    private func onDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .recognized, cellDescription?.supportsActions == true {
            cellDescription?.actionController?.performDoubleTapAction()
        }
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
    )
        -> ConversationMessageCellTableViewAdapter<C> {
        let reuseIdentifier = String(describing: C.self)

        let cell = dequeueReusableCell(
            withIdentifier: reuseIdentifier,
            for: indexPath
        ) as Any as! ConversationMessageCellTableViewAdapter<C>

        cell.cellDescription = description
        cell.configure(
            with: description.configuration,
            fullWidth: description.isFullWidth,
            topMargin: description.topMargin
        )

        return cell
    }
}
