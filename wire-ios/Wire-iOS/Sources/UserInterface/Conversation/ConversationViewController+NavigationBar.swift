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
import WireCommonComponents
import WireDesign
import WireLocators
import WireSyncEngine

// MARK: - Update left navigator bar item when size class changes

extension ConversationViewController {

    typealias IconColors = SemanticColors.Icon
    typealias ButtonColors = SemanticColors.Button
    typealias CallActions = L10n.Localizable.Call.Actions

    func addCallStateObserver() -> Any? {
        conversation.voiceChannel?.addCallStateObserver(self)
    }

    private var videoCallButton: UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(resource: .videoCall), for: .normal)
        button.tintColor = IconColors.foregroundDefault.resolvedColor(with: traitCollection)

        button.accessibilityIdentifier = Locators.ActiveConversationPage.videoCallBarButton.rawValue
        button.accessibilityTraits.insert(.startsMediaSession)
        button.accessibilityLabel = CallActions.Label.makeAudioCall

        let videoCallAction = UIAction { [weak self] _ in
            self?.callItemTapped()
        }
        button.addAction(videoCallAction, for: .touchUpInside)

        button.backgroundColor = ButtonColors.backgroundBarItem.resolvedColor(with: traitCollection)
        button.layer.borderWidth = 1
        button.layer.borderColor = ButtonColors.borderBarItem.resolvedColor(with: traitCollection).cgColor
        button.layer.cornerRadius = 12

        // Enable large content viewer
        button.showsLargeContentViewer = true
        button.largeContentTitle = CallActions.Label.makeAudioCall
        button.largeContentImage = UIImage(resource: .videoCall)

        button.bounds.size = button.systemLayoutSizeFitting(CGSize(width: .max, height: 32))

        return button
    }

    private var callButtonContainerView: UIView {
        let view = videoCallButton.wrapInView()
        view.constraintToSize(CGSize(width: 40, height: 32))
        return view
    }

    var joinCallButton: UIBarButtonItem {
        typealias Conversation = L10n.Accessibility.ConversationsList

        let button = UIButton(type: .system)
        button.setTitle(L10n.Localizable.ConversationList.RightAccessory.JoinButton.title, for: .normal)
        button.titleLabel?.font = .font(for: .body2)
        button.setTitleColor(SemanticColors.Label.textDefaultWhite, for: .normal)
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

    /// Configures the navigation bar's system back button so the conversation screen matches the
    /// back button used on the Settings screen. It uses the same mechanism Settings does — a
    /// `UINavigationBarAppearance` with a custom back-indicator image — so the chevron is sized and
    /// aligned identically. When there are unread messages in other conversations, the indicator
    /// switches to the unread variant tinted with the accent color.
    func configureBackButton(hasUnread: Bool) {
        // Enable swipe-to-go-back gesture
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        guard let navigationBar = navigationController?.navigationBar else { return }

        let icon = backButtonIcon(hasUnreadInOtherConversations: hasUnread)
        // The unread variant has a fixed (non-template) color, so tint it explicitly with the
        // accent color and render it as-is. The default variant is a template image and inherits
        // the navigation bar's tint color, exactly like the system back button on other screens.
        let backIndicator = hasUnread
            ? icon.withTintColor(.accent(), renderingMode: .alwaysOriginal)
            : icon

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = ColorTheme.Backgrounds.surface
        // The conversation navigation bar has no hairline separator, unlike Settings.
        appearance.shadowColor = .clear
        appearance.setBackIndicatorImage(backIndicator, transitionMaskImage: backIndicator)

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance

        // The back button shown on the conversation is derived from the previous item in the stack
        // (the conversation list). Configure its display mode (chevron only, no title) and provide
        // an empty bar button item that carries the accessibility identifier/label so UI tests and
        // VoiceOver can locate it. The chevron itself comes from the back-indicator image above.
        if let backItem = navigationController?.viewControllers.dropLast().last?.navigationItem {
            typealias UnreadMessages = L10n.Localizable.ConversationList.Voiceover.UnreadMessages

            backItem.backButtonDisplayMode = .minimal

            let backButton = UIBarButtonItem()
            backButton.accessibilityLabel = L10n.Accessibility.Conversation.BackButton.description
            backButton.accessibilityValue = hasUnread ? UnreadMessages.hint : nil
            backItem.backBarButtonItem = backButton
        }
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
            guard let connection = conversation.oneOnOneUser?.connection else {
                return true
            }
            return connection.status != .pending && connection.status != .sent
        default: return false
        }
    }

    func rightNavigationItems(forConversation conversation: ZMConversation) -> [UIBarButtonItem] {
        guard !conversation.isReadOnly, !conversation.localParticipants.isEmpty else { return [] }

        if conversation.canJoinCall {
            return [joinCallButton]
        } else if conversation.isCallOngoing {
            return []
        } else {
            let barButtonItem = UIBarButtonItem(customView: callButtonContainerView)
            return [barButtonItem]
        }
    }

    func updateRightNavigationItemsButtons() {
        let items = rightNavigationItems(forConversation: conversation)
        navigationItem.rightBarButtonItems = items
        parent?.navigationItem.rightBarButtonItems = items
    }

    /// Refresh the back button so it reflects the current unread state.
    func updateLeftNavigationBarItems() {
        updateLeftNavigationBarItemsTask?.cancel()
        updateLeftNavigationBarItemsTask = Task {
            if Task.isCancelled { return }

            let hasUnread = self.conversation.hasUnreadMessagesInOtherConversations
            if Task.isCancelled { return }

            await MainActor.run {
                configureBackButton(hasUnread: hasUnread)
            }
        }
    }

    func callItemTapped() {
        view.window?.endEditing(true)
        let checker = PrivacyWarningChecker(conversation: conversation, alertType: .outgoingCall) { [self] in
            startCallController.startAudioCall(started: ConversationInputBarViewController.endEditingMessage)
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
                self.contentViewController?.scroll(to: message) { _ in
                    self.contentViewController?.highlight(message)
                }
            }

        case .reply:
            viewController.dismissIfNeeded(animated: true) {
                self.contentViewController?.scroll(to: message) { cell in
                    self.contentViewController?.perform(action: .reply, for: message, view: cell)
                }
            }

        default:
            contentViewController?.perform(action: action, for: message, view: view)
        }
    }

    func collectionsViewControllerDidRequestOpenSearchFiles(
        _ viewController: CollectionsViewController
    ) {
        onSharedDriveButtonPressed(nil)
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
