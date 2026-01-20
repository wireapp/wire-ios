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
import UniformTypeIdentifiers
import WireDataModel
import WireLogging
import WireSyncEngine
import WireSystem

private let zmLog = ZMSLog(tag: "ConversationViewController+ConversationContentViewControllerDelegate")

extension ConversationViewController: ConversationContentViewControllerDelegate {

    func didSwipeToReact(
        actionController: ConversationMessageActionController,
        popoverPresentationInfo: (sourceView: UIView, frame: CGRect)?
    ) {
        actionControllerForSelectedEmoji = actionController
        let pickerController = CompleteReactionPickerViewController(
            selectedReactions: actionController.message
                .selfUserReactions()
        )
        pickerController.delegate = self

        // Embed the pickerController in a UINavigationController
        let navigationController = UINavigationController(rootViewController: pickerController)
        navigationController.modalPresentationStyle = .popover
        navigationController.preferredContentSize = CGSize(width: 580, height: 640)

        if let popoverPresentationController = navigationController.popoverPresentationController,
           let info = popoverPresentationInfo {
            popoverPresentationController.sourceView = info.sourceView
            popoverPresentationController.sourceRect = info.frame
            popoverPresentationController.permittedArrowDirections = .any
            popoverPresentationController.delegate = self
        }
        present(navigationController, animated: true)
    }

    func didTap(onUserAvatar user: UserType, view: UIView, frame: CGRect) {
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return
        }

        let profileViewController = ProfileViewController(
            user: user,
            viewer: selfUser,
            conversation: conversation,
            userSession: userSession,
            mainCoordinator: mainCoordinator,
            selfProfileUIBuilder: selfProfileUIBuilder,
            conversationCreationRepository: conversationCreationRepository
        )
        profileViewController.preferredContentSize = CGSize.IPadPopover.preferredContentSize

        profileViewController.delegate = self

        self.view.window?.endEditing(true)

        createAndPresentParticipantsPopoverController(
            with: frame,
            from: view,
            contentViewController: profileViewController.wrapInNavigationController()
        )
    }

    func conversationContentViewController(
        _ contentViewController: ConversationContentViewController,
        willDisplayActiveMediaPlayerFor message: ZMConversationMessage?
    ) {
        /// Do not handle intentionally due to the issue described in the
        /// https://wearezeta.atlassian.net/browse/WPB-18452
    }

    func conversationContentViewController(
        _ contentViewController: ConversationContentViewController,
        didEndDisplayingActiveMediaPlayerFor message: ZMConversationMessage
    ) {
        /// Do not handle intentionally due to the issue described in the
        /// https://wearezeta.atlassian.net/browse/WPB-18452
    }

    func conversationContentViewController(
        _ contentViewController: ConversationContentViewController,
        didTriggerEditing message: ZMConversationMessage
    ) {
        guard message.textMessageData?.messageText != nil else { return }

        inputBarController.editMessage(message)
    }

    func conversationContentViewController(
        _ contentViewController: ConversationContentViewController,
        didTriggerReplyingTo message: ZMConversationMessage
    ) {
        let messageReplyAttachmentsViewModel = MessageReplyAttachmentsViewModel(
            fetchNodeUseCase: wireMessagingFactory.makeFetchNodeUseCase()
        )
        let replyComposingView = contentViewController.createReplyComposingView(
            for: message,
            messageReplyAttachmentsViewModel: messageReplyAttachmentsViewModel
        )
        inputBarController.reply(to: message, composingView: replyComposingView)
    }

    func conversationContentViewController(
        _ contentViewController: ConversationContentViewController,
        performImageSaveAnimation snapshotView: UIView?,
        sourceRect: CGRect
    ) {
        if let snapshotView {
            view.addSubview(snapshotView)
        }
        snapshotView?.frame = view.convert(sourceRect, from: contentViewController.view)

        let targetView = inputBarController.photoButton
        let targetCenter = view.convert(targetView.center, from: targetView.superview)

        UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseIn, animations: {
            snapshotView?.center = targetCenter
            snapshotView?.alpha = 0
            snapshotView?.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        }, completion: { _ in
            snapshotView?.removeFromSuperview()
            self.inputBarController.bounceCameraIcon()
        })
    }

    func conversationContentViewController(
        _ controller: ConversationContentViewController,
        presentGuestOptionsFrom sourceView: UIView
    ) {
        guard conversation.conversationType == .group else {
            zmLog.error("Illegal Operation: Trying to show guest options for non-group conversation")
            return
        }

        Task { @MainActor in
            let areLegacyBotsAvailable = (try? await conversationCreationRepository.areBotsSetUpInTheTeam()) ?? false
            let isAppsFeatureEnabled = await userSession.clientSessionComponent?.featureConfigRepository
                .isFeatureEnabled(.apps) ?? false

            let groupDetailsViewController = GroupDetailsViewController(
                conversation: conversation,
                userSession: userSession,
                mainCoordinator: mainCoordinator,
                selfProfileUIBuilder: selfProfileUIBuilder,
                conversationCreationRepository: conversationCreationRepository,
                isUserE2EICertifiedUseCase: userSession.isUserE2EICertifiedUseCase,
                areLegacyBotsAvailable: areLegacyBotsAvailable,
                isAppsFeatureEnabled: isAppsFeatureEnabled
            )
            let navigationController = UINavigationController(rootViewController: groupDetailsViewController)
            groupDetailsViewController.presentGuestOptions(animated: false)
            presentParticipantsViewController(navigationController, from: sourceView)
        }
    }

    func conversationContentViewController(
        _ controller: ConversationContentViewController,
        presentParticipantsDetailsWithSelectedUsers selectedUsers: [UserType],
        from sourceView: UIView
    ) {
        Task { @MainActor in
            if let groupDetailsViewController = (await participantsController as? UINavigationController)?
                .topViewController as? GroupDetailsViewController {
                groupDetailsViewController.presentParticipantsDetails(
                    with: conversation.sortedOtherParticipants,
                    selectedUsers: selectedUsers,
                    animated: false
                )
            }

            if let participantsController = await participantsController {
                presentParticipantsViewController(participantsController, from: sourceView)
            }
        }
    }

    func conversationContentViewController(
        _ controller: ConversationContentViewController,
        didDeleteMultipartMessage message: any ZMConversationMessage,
        withAttachments attachments: [MultipartMessageData.Attachment],
        deletionType: DeletionType
    ) {
        switch deletionType {
        case .everywhere:
            Task {
                let deleteNodesUseCase = wireMessagingFactory.makeDeleteNodesUseCase()
                do {
                    try await deleteNodesUseCase.invoke(nodeIDs: attachments.map(\.nodeID), deletePermanently: false)
                    WireLogger.conversation.info(
                        "Deleted files for message",
                        attributes: [.nonce: message.nonce?.uuidString]
                    )
                } catch {
                    WireLogger.conversation
                        .error(
                            "Unable to delete files: \(String(describing: error))",
                            attributes: [.nonce: message.nonce?.uuidString], .safePublic
                        )
                }
            }
        case .local:
            // no op, related files will still show up for self user (as aligned other clients)
            break
        }
    }

}

extension ConversationViewController {

    func presentParticipantsViewController(
        _ viewController: UIViewController,
        from sourceView: UIView
    ) {
        ConversationInputBarViewController.endEditingMessage()
        inputBarController.inputBar.textView.resignFirstResponder()

        createAndPresentParticipantsPopoverController(
            with: sourceView.bounds,
            from: sourceView,
            contentViewController: viewController
        )
    }
}

extension ConversationViewController: EmojiPickerViewControllerDelegate {

    func emojiPickerDeleteTapped() {
        actionControllerForSelectedEmoji = nil
    }

    func emojiPickerDidSelectEmoji(_ emoji: Emoji) {
        actionControllerForSelectedEmoji?.perform(action: .react(emoji.value))
        dismiss(animated: true)
        actionControllerForSelectedEmoji = nil
    }
}
