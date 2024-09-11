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
import WireSyncEngine

extension ZMConversationMessage {
    /// Whether the `Delete for everyone` option should be allowed and shown for this message.
    private var canBeDeletedForEveryone: Bool {
        guard let sender = senderUser,
              let conversation = conversationLike else { return false }
        return sender.isSelfUser && conversation.isSelfAnActiveMember
    }

    fileprivate var deletionConfiguration: DeletionConfiguration {
        // If the message failed to send we only want to show the delete for everyone option,
        // as we can not be sure that it did not hit the backend before we expired it.
        if deliveryState == .failedToSend {
            return .delete
        }

        return canBeDeletedForEveryone ? .hideAndDelete : .hide
    }
}

protocol SelectableView {
    var selectionView: UIView! { get }
    var selectionRect: CGRect { get }
}

protocol HighlightableView {
    var highlightContainer: UIView { get }
}

extension CollectionCell: SelectableView {
    var selectionView: UIView! { self }
    var selectionRect: CGRect { frame }
}

final class DeletionDialogPresenter: NSObject {
    private weak var sourceViewController: UIViewController?

    func deleteAlert(
        message: ZMConversationMessage,
        sourceView: UIView,
        userSession: UserSession,
        completion: @escaping (_ succeeded: Bool) -> Void
    ) -> UIAlertController {
        let alert = UIAlertController.forMessageDeletion(with: message.deletionConfiguration) { action, _ in

            // Tracking needs to be called before performing the action, since the content of the message is cleared
            if case let .delete(type) = action {
                userSession.enqueue {
                    switch type {
                    case .local:
                        ZMMessage.hideMessage(message)
                    case .everywhere:
                        ZMMessage.deleteForEveryone(message)
                    }
                } completionHandler: {
                    completion(true)
                }
            } else {
                completion(false)
            }
        }

        if let popoverPresentationController = alert.popoverPresentationController {
            let sourceView = if let selectableView = sourceView as? SelectableView,
                                let selectionView = selectableView.selectionView {
                selectionView
            } else {
                sourceView
            }
            popoverPresentationController.sourceView = sourceView.superview
            popoverPresentationController.sourceRect = sourceView.frame.insetBy(dx: -4, dy: -4)
        }

        return alert
    }

    init(sourceViewController: UIViewController) {
        self.sourceViewController = sourceViewController
        super.init()
    }

    /// Presents a `UIAlertController` of type action sheet with the options to delete a message everywhere, locally
    /// or to cancel. An optional completion block can be provided to get notified when an action has been selected.
    /// The delete everywhere option is only shown if this action is allowed for the input message.
    ///
    /// - parameter message: The message for which the alert controller should be shown.
    /// - parameter source: The source view used for a potential popover presentation of the dialog.
    /// - parameter completion: A completion closure which will be invoked with `true` if a deletion occured and `false`
    /// otherwise.
    func presentDeletionAlertController(
        forMessage message: ZMConversationMessage,
        source: UIView,
        userSession: UserSession,
        completion: @escaping (_ succeeded: Bool) -> Void
    ) {
        guard !message.hasBeenDeleted else { return }

        let alert = deleteAlert(
            message: message,
            sourceView: source,
            userSession: userSession,
            completion: completion
        )
        sourceViewController?.present(alert, animated: true)
    }
}

private enum AlertAction {
    enum DeletionType {
        case local
        case everywhere
    }

    case delete(DeletionType), cancel
}

// Used to enforce only valid configurations can be shown.
// Unfortunately this can not be done with an `OptionSetType`
// as there is no way to enforce a non-empty option set.
private enum DeletionConfiguration {
    case hide, delete, hideAndDelete

    var showHide: Bool {
        switch self {
        case .hide, .hideAndDelete: true
        case .delete: false
        }
    }

    var showDelete: Bool {
        switch self {
        case .delete, .hideAndDelete: true
        case .hide: false
        }
    }
}

extension UIAlertController {
    fileprivate static func forMessageDeletion(
        with configuration: DeletionConfiguration,
        selectedAction: @escaping (AlertAction, UIAlertController) -> Void
    ) -> UIAlertController {
        let alertTitle = L10n.Localizable.Message.DeleteDialog.message
        let alert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .actionSheet)

        if configuration.showHide {
            let hideTitle = L10n.Localizable.Message.DeleteDialog.Action.hide
            let hideAction = UIAlertAction(title: hideTitle, style: .destructive) { [unowned alert] _ in selectedAction(
                .delete(.local),
                alert
            ) }
            alert.addAction(hideAction)
        }

        if configuration.showDelete {
            let deleteTitle = L10n.Localizable.Message.DeleteDialog.Action.delete
            let deleteForEveryoneAction = UIAlertAction(title: deleteTitle, style: .destructive) { [unowned alert] _ in
                selectedAction(
                    .delete(.everywhere),
                    alert
                )
            }
            alert.addAction(deleteForEveryoneAction)
        }

        let cancelTitle = L10n.Localizable.Message.DeleteDialog.Action.cancel
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { [unowned alert] _ in selectedAction(
            .cancel,
            alert
        ) }
        alert.addAction(cancelAction)

        return alert
    }
}
