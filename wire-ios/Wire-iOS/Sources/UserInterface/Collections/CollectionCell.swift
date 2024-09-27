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
import WireCommonComponents
import WireDesign
import WireSyncEngine

// MARK: - CollectionCellDelegate

protocol CollectionCellDelegate: AnyObject {
    func collectionCell(_ cell: CollectionCell, performAction: MessageAction)
}

// MARK: - CollectionCellMessageChangeDelegate

protocol CollectionCellMessageChangeDelegate: AnyObject {
    func messageDidChange(_ cell: CollectionCell, changeInfo: MessageChangeInfo)
}

// MARK: - CollectionCell

class CollectionCell: UICollectionViewCell {
    // MARK: Lifecycle

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadContents()
    }

    // MARK: Internal

    var actionController: ConversationMessageActionController?
    var messageObserverToken: NSObjectProtocol? = .none
    weak var delegate: CollectionCellDelegate?
    // Cell forwards the message changes to the delegate
    weak var messageChangeDelegate: CollectionCellMessageChangeDelegate?

    var desiredWidth: CGFloat? = .none
    var desiredHeight: CGFloat? = .none

    // MARK: - Obfuscation

    let secureContentsView: UIView = {
        let view = UIView()
        view.backgroundColor = SemanticColors.View.backgroundCollectionCell

        return view
    }()

    lazy var obfuscationView = ObfuscationView(icon: self.obfuscationIcon)

    var message: ZMConversationMessage? = .none {
        didSet {
            messageObserverToken = nil
            if let userSession = ZMUserSession.shared(), let newMessage = message {
                messageObserverToken = MessageChangeInfo.add(
                    observer: self,
                    for: newMessage,
                    userSession: userSession
                )
            }

            actionController = message.map {
                ConversationMessageActionController(responder: self, message: $0, context: .collection, view: self)
            }

            updateForMessage(changeInfo: .none)
        }
    }

    override var intrinsicContentSize: CGSize {
        let width = desiredWidth ?? UIView.noIntrinsicMetric
        let height = desiredHeight ?? UIView.noIntrinsicMetric
        return CGSize(width: width, height: height)
    }

    var obfuscationIcon: StyleKitIcon {
        .exclamationMarkCircle
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    func flushCachedSize() {
        cachedSize = .none
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes)
        -> UICollectionViewLayoutAttributes {
        if let cachedSize {
            var newFrame = layoutAttributes.frame
            newFrame.size.width = cachedSize.width
            newFrame.size.height = cachedSize.height
            layoutAttributes.frame = newFrame
        } else {
            setNeedsLayout()
            layoutIfNeeded()
            var desiredSize = layoutAttributes.size
            if let desiredWidth {
                desiredSize.width = desiredWidth
            }
            if let desiredHeight {
                desiredSize.height = desiredHeight
            }

            let size = contentView.systemLayoutSizeFitting(desiredSize)
            var newFrame = layoutAttributes.frame
            newFrame.size.width = CGFloat(ceilf(Float(size.width)))
            newFrame.size.height = CGFloat(ceilf(Float(size.height)))

            if let desiredWidth {
                newFrame.size.width = desiredWidth
            }
            if let desiredHeight {
                newFrame.size.height = desiredHeight
            }

            layoutAttributes.frame = newFrame
            cachedSize = newFrame.size
        }

        return layoutAttributes
    }

    func loadContents() {
        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = 4

        let longPressGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(CollectionCell.onLongPress(_:))
        )

        contentView.addGestureRecognizer(longPressGestureRecognizer)

        contentView.addSubview(secureContentsView)
        contentView.addSubview(obfuscationView)

        secureContentsView.translatesAutoresizingMaskIntoConstraints = false
        obfuscationView.translatesAutoresizingMaskIntoConstraints = false

        secureContentsView.fitIn(view: contentView)
        obfuscationView.fitIn(view: contentView)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cachedSize = .none
        message = .none
    }

    @objc
    func onLongPress(_ gestureRecognizer: UILongPressGestureRecognizer!) {
        if gestureRecognizer.state == .began {
            showMenu()
        }
    }

    // MARK: - Menu

    func menuConfigurationProperties() -> MenuConfigurationProperties? {
        let properties = MenuConfigurationProperties()
        properties.targetRect = contentView.bounds
        properties.targetView = contentView

        return properties
    }

    func showMenu() {
        guard let menuConfigurationProperties = menuConfigurationProperties() else {
            return
        }

//           The reason why we are touching the window here is to workaround a bug where,
//           After dismissing the webplayer, the window would fail to become the first responder,
//           preventing us to show the menu at all.
//           We now force the window to be the key window and to be the first responder to ensure that we can
//           show the menu controller.

        prepareShowingMenu()

        let menuController = UIMenuController.shared
        menuController.menuItems = ConversationMessageActionController.allMessageActions
        menuController.showMenu(
            from: menuConfigurationProperties.targetView,
            rect: menuConfigurationProperties.targetRect
        )
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        actionController?.canPerformAction(action) == true
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        actionController
    }

    // To be implemented in the subclass
    func updateForMessage(changeInfo: MessageChangeInfo?) {
        updateMessageVisibility()
        // no-op
    }

    /// Copies the contents of the message.
    /// note: The default implementation copies using the default implementation. Override it
    /// if you want to customize the behavior of the copy (ex: only copying parts of the message).
    /// - Parameter pasteboard: The pasteboard to copy the contents to.
    func copyDisplayedContent(in pasteboard: UIPasteboard) {
        message?.copy(in: pasteboard)
    }

    // MARK: Fileprivate

    fileprivate func updateMessageVisibility() {
        let isObfuscated = message?.isObfuscated == true || message?.hasBeenDeleted == true
        secureContentsView.isHidden = isObfuscated
        obfuscationView.isHidden = !isObfuscated
        obfuscationView.backgroundColor = .accentDimmedFlat
    }

    // MARK: Private

    private var cachedSize: CGSize? = .none
}

// MARK: ZMMessageObserver

extension CollectionCell: ZMMessageObserver {
    func messageDidChange(_ changeInfo: MessageChangeInfo) {
        updateForMessage(changeInfo: changeInfo)
        messageChangeDelegate?.messageDidChange(self, changeInfo: changeInfo)
    }
}

// MARK: MessageActionResponder

extension CollectionCell: MessageActionResponder {
    func perform(action: MessageAction, for message: ZMConversationMessage, view: UIView) {
        delegate?.collectionCell(self, performAction: action)
    }
}
