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
import WireSystem

private let zmLog = ZMSLog(tag: "ConversationViewController+ConversationContentViewControllerDelegate")

// MARK: - ConversationViewController + ConversationContentViewControllerDelegate

extension ConversationViewController: ConversationContentViewControllerDelegate {
    func didTap(onUserAvatar user: UserType, view: UIView, frame: CGRect) {
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return
        }

        let profileViewController = ProfileViewController(
            user: user,
            viewer: selfUser,
            conversation: conversation,
            viewControllerDismisser: self,
            userSession: userSession,
            mainCoordinator: mainCoordinator
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
        conversationBarController.dismiss(bar: mediaBarViewController)
    }

    func conversationContentViewController(
        _ contentViewController: ConversationContentViewController,
        didEndDisplayingActiveMediaPlayerFor message: ZMConversationMessage
    ) {
        conversationBarController.present(bar: mediaBarViewController)
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
        let replyComposingView = contentViewController.createReplyComposingView(for: message)
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

        let groupDetailsViewController = GroupDetailsViewController(
            conversation: conversation,
            userSession: userSession,
            mainCoordinator: mainCoordinator,
            isUserE2EICertifiedUseCase: userSession.isUserE2EICertifiedUseCase
        )
        let navigationController = groupDetailsViewController.wrapInNavigationController()
        groupDetailsViewController.presentGuestOptions(animated: false)
        presentParticipantsViewController(navigationController, from: sourceView)
    }

    func conversationContentViewController(
        _ controller: ConversationContentViewController,
        presentParticipantsDetailsWithSelectedUsers selectedUsers: [UserType],
        from sourceView: UIView
    ) {
        if let groupDetailsViewController = (participantsController as? UINavigationController)?
            .topViewController as? GroupDetailsViewController {
            groupDetailsViewController.presentParticipantsDetails(
                with: conversation.sortedOtherParticipants,
                selectedUsers: selectedUsers,
                animated: false
            )
        }

        if let participantsController {
            presentParticipantsViewController(participantsController, from: sourceView)
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
