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
import WireDataModel

final class ConversationMessageActionController {
    // MARK: Lifecycle

    init(
        responder: MessageActionResponder?,
        message: ZMConversationMessage,
        context: Context,
        view: UIView
    ) {
        self.responder = responder
        self.message = message
        self.context = context
        self.view = view
    }

    // MARK: Internal

    enum Context: Int {
        case content, collection
    }

    // MARK: - UI menu

    static var allMessageActions: [UIMenuItem] {
        MessageAction.allCases.compactMap {
            guard let selector = $0.selector,
                  let title = $0.title else {
                return nil
            }
            return UIMenuItem(title: title, action: selector)
        }
    }

    let message: ZMConversationMessage
    let context: Context
    weak var responder: MessageActionResponder?
    weak var view: UIView!

    @available(
        iOS,
        introduced: 9.0,
        deprecated: 13.0,
        message: "UIViewControllerPreviewing is deprecated. Please use UIContextMenuInteraction."
    )
    var previewActionItems: [UIPreviewAction] {
        allPerformableMessageAction.compactMap { messageAction in
            guard let title = messageAction.title else {
                return nil
            }

            return UIPreviewAction(
                title: title,
                style: .default
            ) { [weak self] _, _ in
                self?.perform(action: messageAction)
            }
        }
    }

    var singleTapAction: MessageAction? {
        if message.isImage, message.imageMessageData?.isDownloaded == true {
            return .present
        } else if message.isFile, !message.isAudio, let transferState = message.fileMessageData?.transferState {
            switch transferState {
            case .uploaded:
                return .present
            default:
                return nil
            }
        }

        return nil
    }

    var doubleTapAction: MessageAction? {
        message.canAddReaction ? .react("❤️") : nil
    }

    func allMessageMenuElements() -> [UIAction] {
        weak var responder = responder
        weak var message = message
        unowned let targetView: UIView = view

        return allPerformableMessageAction.compactMap { messageAction in
            guard let title = messageAction.title else {
                return nil
            }

            let handler: UIActionHandler = { _ in
                responder?.perform(
                    action: messageAction,
                    for: message!,
                    view: targetView
                )
            }

            return UIAction(
                title: title,
                image: messageAction.systemIcon(),
                handler: handler
            )
        }
    }

    func canPerformAction(action: MessageAction) -> Bool {
        switch action {
        case .copy:
            message.canBeCopied
        case .digitallySign:
            message.canBeDigitallySigned
        case .reply:
            message.canBeQuoted
        case .openDetails:
            message.areMessageDetailsAvailable
        case .edit:
            message.canBeEdited
        case .delete:
            message.canBeDeleted
        case .save:
            message.canBeSaved
        case .cancel:
            message.canCancelDownload
        case .download:
            message.canBeDownloaded
        case .resend:
            message.canBeResent
        case .showInConversation:
            context == .collection
        case .sketchDraw,
             .sketchEmoji:
            message.isImage
        case .react:
            message.canAddReaction
        case .visitLink:
            message.canVisitLink
        case .openQuote,
             .present,
             .resetSession:
            false
        }
    }

    func canPerformAction(_ selector: Selector) -> Bool {
        guard let action = MessageAction.allCases.first(where: {
            $0.selector == selector
        }) else {
            return false
        }

        return canPerformAction(action: action)
    }

    func makeAccessibilityActions() -> [UIAccessibilityCustomAction] {
        ConversationMessageActionController.allMessageActions
            .filter { self.canPerformAction($0.action) }
            .map { menuItem in
                UIAccessibilityCustomAction(name: menuItem.title, target: self, selector: menuItem.action)
            }
    }

    // MARK: - Single Tap Action

    func performSingleTapAction() {
        guard let singleTapAction else {
            return
        }

        perform(action: singleTapAction)
    }

    // MARK: - Double Tap Action

    func performDoubleTapAction() {
        guard let doubleTapAction else {
            return
        }
        perform(action: doubleTapAction)
    }

    // MARK: - Handler

    func perform(action: MessageAction) {
        responder?.perform(
            action: action,
            for: message,
            view: view
        )
    }

    @objc
    func digitallySignMessage() {
        perform(action: .digitallySign)
    }

    @objc
    func copyMessage() {
        perform(action: .copy)
    }

    @objc
    func editMessage() {
        perform(action: .edit)
    }

    @objc
    func quoteMessage() {
        perform(action: .reply)
    }

    @objc
    func openMessageDetails() {
        perform(action: .openDetails)
    }

    @objc
    func cancelDownloadingMessage() {
        perform(action: .cancel)
    }

    @objc
    func downloadMessage() {
        perform(action: .download)
    }

    @objc
    func saveMessage() {
        perform(action: .save)
    }

    @objc
    func deleteMessage() {
        perform(action: .delete)
    }

    @objc
    func resendMessage() {
        perform(action: .resend)
    }

    @objc
    func revealMessage() {
        perform(action: .showInConversation)
    }

    @objc
    func addReaction(reaction: Emoji.ID) {
        perform(action: .react(reaction))
    }

    @objc
    func visitLink() {
        perform(action: .visitLink)
    }

    // MARK: Private

    // MARK: - List of Actions

    private var allPerformableMessageAction: [MessageAction] {
        MessageAction.allCases
            .filter(canPerformAction)
    }
}
