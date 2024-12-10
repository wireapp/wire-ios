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

// MARK: - Update left navigator bar item when size class changes

extension ConversationViewController {

    typealias IconColors = SemanticColors.Icon
    typealias ButtonColors = SemanticColors.Button
    typealias CallActions = L10n.Localizable.Call.Actions

    func addCallStateObserver() -> Any? {
        conversation.voiceChannel?.addCallStateObserver(self)
    }

    private var audioCallButton: UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(resource: .audioCall), for: .normal)
        button.tintColor = IconColors.foregroundDefault

        button.accessibilityIdentifier = "audioCallBarButton"
        button.accessibilityTraits.insert(.startsMediaSession)
        button.accessibilityLabel = CallActions.Label.makeAudioCall

        let audioCallAction = UIAction { [weak self] _ in
            self?.voiceCallItemTapped()
        }
        button.addAction(audioCallAction, for: .touchUpInside)

        button.backgroundColor = ButtonColors.backgroundBarItem
        button.layer.borderWidth = 1
        button.layer.borderColor = ButtonColors.borderBarItem.cgColor
        button.layer.cornerRadius = 12
        button.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]

        // Enable large content viewer
        button.showsLargeContentViewer = true
        button.largeContentTitle = CallActions.Label.makeAudioCall
        button.largeContentImage = UIImage(resource: .audioCall)

        button.bounds.size = button.systemLayoutSizeFitting(CGSize(width: .max, height: 32))

        return button
    }

    private var videoCallButton: UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(resource: .videoCall), for: .normal)
        button.tintColor = IconColors.foregroundDefault

        button.accessibilityIdentifier = "videoCallBarButton"
        button.accessibilityTraits.insert(.startsMediaSession)
        button.accessibilityLabel = CallActions.Label.makeVideoCall

        let videoCallAction = UIAction { [weak self] _ in
            self?.videoCallItemTapped()
        }
        button.addAction(videoCallAction, for: .touchUpInside)

        button.backgroundColor = ButtonColors.backgroundBarItem
        button.layer.borderWidth = 1
        button.layer.borderColor = ButtonColors.borderBarItem.cgColor
        button.layer.cornerRadius = 12
        button.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]

        // Enable large content viewer
        button.showsLargeContentViewer = true
        button.largeContentTitle = CallActions.Label.makeVideoCall
        button.largeContentImage = UIImage(resource: .videoCall)

        button.bounds.size = button.systemLayoutSizeFitting(CGSize(width: .max, height: 32))

        return button
    }

    private var audioAndVideoCallButtons: UIView {
        let buttonStack = UIStackView(frame: CGRect(x: 0, y: 0, width: 80, height: 32))
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 0
        buttonStack.axis = .horizontal

        buttonStack.addArrangedSubview(videoCallButton)
        buttonStack.addArrangedSubview(audioCallButton)

        let buttonsView = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 32))
        buttonsView.addSubview(buttonStack)

        return buttonsView
    }

    var joinCallButton: UIBarButtonItem {
        typealias Conversation = L10n.Accessibility.ConversationsList

        let button = UIButton(type: .system)
        button.setTitle(L10n.Localizable.ConversationList.RightAccessory.JoinButton.title, for: .normal)
        button.titleLabel?.font = .font(for: .body2)
        button.setTitleColor(SemanticColors.Label.textWhite, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.titleLabel?.adjustsFontForContentSizeCategory = false

        button.accessibilityLabel = Conversation.JoinButton.description
        button.accessibilityHint = Conversation.JoinButton.hint
        button.accessibilityTraits.insert(.startsMediaSession)

        button.backgroundColor = SemanticColors.Icon.backgroundJoinCall

        let joinAction = UIAction { [weak self] _ in
            self?.joinCallButtonTapped()
        }

        button.addAction(joinAction, for: .touchUpInside)

        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)
        button.bounds.size = button.systemLayoutSizeFitting(CGSize(width: .max, height: 32))
        button.layer.cornerRadius = button.bounds.height / 2

        // Enable large content viewer
        button.showsLargeContentViewer = true
        button.largeContentTitle = Conversation.JoinButton.description

        return UIBarButtonItem(customView: button)
    }

    func createBackButton(hasUnread: Bool) -> UIBarButtonItem {
        typealias UnreadMessages = L10n.Localizable.ConversationList.Voiceover.UnreadMessages

        let icon = backButtonIcon(hasUnreadInOtherConversations: hasUnread)
        let action = #selector(ConversationViewController.onBackButtonPressed(_:))

        let button = UIBarButtonItem(image: icon, style: .plain, target: self, action: action)
        button.accessibilityIdentifier = "ConversationBackButton"
        button.accessibilityLabel = L10n.Accessibility.Conversation.BackButton.description
        button.tintColor = hasUnread ? UIColor.accent() : nil
        button.accessibilityValue = hasUnread ? UnreadMessages.hint : nil

        // Enable swipe-to-go-back gesture
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        return button
    }

    private func backButtonIcon(hasUnreadInOtherConversations: Bool) -> UIImage {
        if view.isRightToLeft {
            if hasUnreadInOtherConversations {
                UIImage(resource: .unreadForwardArrow)
            } else {
                UIImage(resource: .forwardArrow)
            }
        } else {
            if hasUnreadInOtherConversations {
                UIImage(resource: .unreadBackArrow)
            } else {
                UIImage(resource: .backArrow)
            }
        }
    }

    var shouldShowCollectionsButton: Bool {
        guard
            SecurityFlags.forceEncryptionAtRest.isEnabled == false,
            userSession.encryptMessagesAtRest == false
        else {
            return false
        }

        switch conversation.conversationType {
        case .group: return true
        case .oneOnOne:
            if let connection = conversation.oneOnOneUser?.connection,
               connection.status != .pending, connection.status != .sent {
                return true
            } else {
                return conversation.teamRemoteIdentifier != nil
            }
        default: return false
        }
    }

    func rightNavigationItems(forConversation conversation: ZMConversation) -> [UIBarButtonItem] {
        guard !conversation.isReadOnly, !conversation.localParticipants.isEmpty else { return [] }

        if conversation.canJoinCall {
            return [joinCallButton]
        } else if conversation.isCallOngoing {
            return []
        } else if conversation.canStartVideoCall {
            let barButtonItems = UIBarButtonItem(customView: audioAndVideoCallButtons)
            return [barButtonItems]
        } else {
            let barButtonItem = UIBarButtonItem(customView: audioCallButton)
            return [barButtonItem]
        }
    }

    func leftNavigationItems(hasUnread: Bool) -> [UIBarButtonItem] {
        var items: [UIBarButtonItem] = []

        if traitCollection.horizontalSizeClass != .regular {
            items.append(createBackButton(hasUnread: hasUnread))
        }

        if shouldShowCollectionsButton {
            items.append(searchBarButtonItem)
        }

        return items
    }

    func updateRightNavigationItemsButtons() {
        navigationItem.rightBarButtonItems = rightNavigationItems(forConversation: conversation)
    }

    /// Update left navigation bar items
    func updateLeftNavigationBarItems() {
        updateLeftNavigationBarItemsTask?.cancel()
        updateLeftNavigationBarItemsTask = Task {
            if Task.isCancelled { return }

            let hasUnread = self.conversation.hasUnreadMessagesInOtherConversations
            if Task.isCancelled { return }

            await MainActor.run {
                navigationItem.leftBarButtonItems = leftNavigationItems(hasUnread: hasUnread)
            }
        }
    }

    func voiceCallItemTapped() {
        view.window?.endEditing(true)
        let checker = PrivacyWarningChecker(conversation: conversation, alertType: .outgoingCall) { [self] in
            startCallController.startAudioCall(started: ConversationInputBarViewController.endEditingMessage)
        }

        checker.performAction()
    }

    func videoCallItemTapped() {
        let checker = PrivacyWarningChecker(conversation: conversation, alertType: .outgoingCall) { [self] in
            view.window?.endEditing(true)
            startCallController.startVideoCall(started: ConversationInputBarViewController.endEditingMessage)
        }

        checker.performAction()
    }

    private dynamic func joinCallButtonTapped() {
        startCallController.joinCall()
    }

    @objc
    func dismissCollectionIfNecessary() {
        if let collectionController {
            collectionController.dismiss(animated: false)
        }
    }
}

extension ConversationViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        navigationController?.viewControllers.count ?? 0 > 1
    }
}

extension ConversationViewController: CollectionsViewControllerDelegate {

    func collectionsViewController(
        _ viewController: CollectionsViewController,
        performAction action: MessageAction,
        onMessage message: ZMConversationMessage
    ) {

        switch action {

        case .showInConversation:
            viewController.dismissIfNeeded(animated: true) {
                self.contentViewController.scroll(to: message) { _ in
                    self.contentViewController.highlight(message)
                }
            }

        case .reply:
            viewController.dismissIfNeeded(animated: true) {
                self.contentViewController.scroll(to: message) { cell in
                    self.contentViewController.perform(action: .reply, for: message, view: cell)
                }
            }

        default:
            contentViewController.perform(action: action, for: message, view: view)
        }
    }
}

extension ConversationViewController: WireCallCenterCallStateObserver {

    func callCenterDidChange(
        callState: CallState,
        conversation: ZMConversation,
        caller: UserType,
        timestamp: Date?,
        previousCallState: CallState?
    ) {
        updateRightNavigationItemsButtons()
    }

}

extension ZMConversation {

    /// Whether there is an incoming or inactive incoming call that can be joined.
    var canJoinCall: Bool {
        voiceChannel?.state.canJoinCall ?? false
    }

    var canStartVideoCall: Bool {
        !isCallOngoing
    }

    var isCallOngoing: Bool {
        voiceChannel?.state.isCallOngoing ?? true
    }
}

extension CallState {

    var canJoinCall: Bool {
        switch self {
        case .incoming: true
        default: false
        }
    }

    var isCallOngoing: Bool {
        switch self {
        case .none, .incoming: false
        default: true
        }
    }
}
