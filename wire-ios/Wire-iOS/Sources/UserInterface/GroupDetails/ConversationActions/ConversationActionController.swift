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
import WireSyncEngine

final class ConversationActionController {
    // MARK: Lifecycle

    init(
        conversation: GroupDetailsConversationType,
        target: UIViewController,
        sourceView: UIView,
        userSession: UserSession
    ) {
        self.conversation = conversation
        self.target = target
        self.sourceView = sourceView
        self.userSession = userSession
    }

    // MARK: Internal

    enum Context {
        case list, details
    }

    private(set) weak var sourceView: UIView?
    var currentContext: PopoverPresentationControllerConfiguration?
    private(set) weak var alertController: UIAlertController?
    let userSession: UserSession

    func presentMenu(from sourceView: UIView, context: Context) {
        let actions: [ZMConversation.Action] = switch context {
        case .details:
            (conversation as? ZMConversation)?.detailActions ?? []
        case .list:
            (conversation as? ZMConversation)?.listActions ?? []
        }

        let title = context == .list ? conversation.displayName : nil
        let controller = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        actions.map(alertAction).forEach(controller.addAction)
        controller.addAction(.cancel())

        if controller.popoverPresentationController != nil {
            currentContext = .sourceView(
                sourceView: sourceView.superview!,
                sourceRect: sourceView.frame
            )
        }

        present(controller)

        alertController = controller
    }

    func enqueue(_ block: @escaping () -> Void) {
        userSession.enqueue(block)
    }

    func transitionToListAndEnqueue(_ block: @escaping () -> Void) {
        ZClientViewController.shared?.transitionToList(animated: true) { [self] in
            userSession.enqueue(block)
        }
    }

    func handleAction(_ action: ZMConversation.Action) {
        guard let conversation = conversation as? ZMConversation else { return }

        switch action {
        case .deleteGroup:
            guard let userSession = ZMUserSession.shared() else { return }

            requestDeleteGroupResult { result in
                self.handleDeleteGroupResult(result, conversation: conversation, in: userSession)
            }

        case let .archive(isArchived: isArchived): transitionToListAndEnqueue {
                conversation.isArchived = !isArchived
            }

        case .markRead: enqueue {
                conversation.markAsRead()
            }

        case .markUnread: enqueue {
                conversation.markAsUnread()
            }

        case .configureNotifications: requestNotificationResult(for: conversation) { result in
                self.handleNotificationResult(result, for: conversation)
            }

        case let .silence(isSilenced: isSilenced): enqueue {
                conversation.mutedMessageTypes = isSilenced ? .none : .all
            }

        case .leave:
            request(LeaveResult.self) { result in
                self.handleLeaveResult(result, for: conversation)
            }

        case .clearContent:
            requestClearContentResult(for: conversation) { result in
                self.handleClearContentResult(result, for: conversation)
            }

        case .cancelRequest:
            guard let user = conversation.connectedUser else { return }
            requestCancelConnectionRequestResult(for: user) { result in
                self.handleConnectionRequestResult(result, for: conversation)
            }

        case .block: requestBlockResult(for: conversation) { result in
                self.handleBlockResult(result, for: conversation)
            }

        case .moveToFolder:
            openMoveToFolder(for: conversation)

        case .removeFromFolder:
            enqueue {
                conversation.removeFromFolder()
            }

        case let .favorite(isFavorite: isFavorite):
            enqueue {
                conversation.isFavorite = !isFavorite
            }

        case .remove: fatalError()

        case .duplicateConversation:
            duplicateConversation()
        }
    }

    func presentError(_ error: LocalizedError) {
        target.presentLocalizedErrorAlert(error)
    }

    func present(_ controller: UIViewController) {
        _ = currentContext.map {
            controller.configurePopoverPresentationController(using: $0)
        }

        target.present(controller, animated: true)
    }

    // MARK: Private

    private let conversation: GroupDetailsConversationType
    private unowned let target: UIViewController

    private func alertAction(for action: ZMConversation.Action) -> UIAlertAction {
        action.alertAction { [weak self] in
            guard let self else { return }
            handleAction(action)
        }
    }

    private func duplicateConversation() {
        guard DeveloperFlag.debugDuplicateObjects.isOn else { return }

        guard let context = (userSession as? ZMUserSession)?.syncContext,
              let conversation = conversation as? ZMConversation else {
            return
        }
        context.performAndWait {
            guard let original = ZMConversation.existingObject(for: conversation.objectID, in: context) else {
                return
            }
            let duplicate = ZMConversation.insertNewObject(in: context)
            duplicate.remoteIdentifier = original.remoteIdentifier
            duplicate.domain = original.domain
            duplicate.nonTeamRoles = original.nonTeamRoles
            duplicate.creator = original.creator
            duplicate.conversationType = original.conversationType
            duplicate.participantRoles = original.participantRoles

            context.saveOrRollback()

            WireLogger.conversation
                .debug("duplicate conversation \(String(describing: original.qualifiedID?.safeForLoggingDescription))")
        }
    }
}
