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

extension ConversationInputBarViewController {
    @discardableResult
    func createEphemeralKeyboardViewController() -> EphemeralKeyboardViewController {
        let ephemeralKeyboardViewController =
            EphemeralKeyboardViewController(conversation: conversation as? ZMConversation)
        ephemeralKeyboardViewController.delegate = self

        self.ephemeralKeyboardViewController = ephemeralKeyboardViewController
        return ephemeralKeyboardViewController
    }

    func configureEphemeralKeyboardButton(_ button: IconButton) {
        button.addTarget(self, action: #selector(ephemeralKeyboardButtonTapped), for: .touchUpInside)
    }

    @objc
    func ephemeralKeyboardButtonTapped(_: IconButton) {
        toggleEphemeralKeyboardVisibility()
    }

    private func toggleEphemeralKeyboardVisibility() {
        let isEphemeralControllerPresented = ephemeralKeyboardViewController != nil
        let isEphemeralKeyboardPresented = mode == .timeoutConfguration

        if !isEphemeralControllerPresented || !isEphemeralKeyboardPresented {
            presentEphemeralController()
        } else {
            dismissEphemeralController()
        }
    }

    private func presentEphemeralController() {
        let shouldShowPopover = traitCollection.horizontalSizeClass == .regular

        if shouldShowPopover {
            presentEphemeralControllerAsPopover()
        } else {
            // we only want to change the mode when we present a custom keyboard
            mode = .timeoutConfguration
            inputBar.textView.becomeFirstResponder()
        }
    }

    private func dismissEphemeralController() {
        let isPopoverPresented = ephemeralKeyboardViewController?.modalPresentationStyle == .popover

        if isPopoverPresented {
            ephemeralKeyboardViewController?.dismiss(animated: true, completion: nil)
            ephemeralKeyboardViewController = nil
        } else {
            mode = .textInput
        }
    }

    private func presentEphemeralControllerAsPopover() {
        createEphemeralKeyboardViewController()
        ephemeralKeyboardViewController?.modalPresentationStyle = .popover
        ephemeralKeyboardViewController?.preferredContentSize = CGSize.IPadPopover.pickerSize
        let pointToView = ephemeralIndicatorButton.isHidden ? hourglassButton : ephemeralIndicatorButton

        if let popover = ephemeralKeyboardViewController?.popoverPresentationController,
           let backgroundColor = ephemeralKeyboardViewController?.view.backgroundColor {
            popover.sourceView = pointToView.superview!
            popover.sourceRect = pointToView.frame.insetBy(dx: -4, dy: -4)
            popover.backgroundColor = backgroundColor
            popover.permittedArrowDirections = .down
        }

        guard let controller = ephemeralKeyboardViewController else { return }
        parent?.present(controller, animated: true)
    }

    func updateEphemeralIndicatorButtonTitle(_ button: ButtonWithLargerHitArea) {
        let title = conversation.activeMessageDestructionTimeoutValue?.shortDisplayString
        button.setTitle(title, for: .normal)
        setupAccessibility(button)
    }

    private func setupAccessibility(_ button: ButtonWithLargerHitArea) {
        button.accessibilityLabel = L10n.Accessibility.Conversation.EmphemeralButton.description
        if let value = conversation.activeMessageDestructionTimeoutValue?.accessibilityValue {
            button.accessibilityValue = value
        }
    }
}

extension MessageDestructionTimeoutValue {
    fileprivate var accessibilityValue: String? {
        typealias Conversation = L10n.Accessibility.Conversation

        guard
            self != .none,
            let timeoutValue = shortDisplayString
        else {
            return nil
        }
        switch self {
        case .tenSeconds:
            return Conversation.TimerForSelfDeletingMessagesSeconds.value(timeoutValue)
        case .fiveMinutes:
            return Conversation.TimerForSelfDeletingMessagesMinutes.value(timeoutValue)
        case .oneHour:
            return Conversation.TimerForSelfDeletingMessagesHour.value(timeoutValue)
        case .oneDay:
            return Conversation.TimerForSelfDeletingMessagesDay.value(timeoutValue)
        case .oneWeek:
            return Conversation.TimerForSelfDeletingMessagesWeek.value(timeoutValue)
        case .fourWeeks:
            return Conversation.TimerForSelfDeletingMessagesWeeks.value(timeoutValue)
        default:
            return nil
        }
    }
}

extension ConversationInputBarViewController: EphemeralKeyboardViewControllerDelegate {
    func ephemeralKeyboardWantsToBeDismissed(_: EphemeralKeyboardViewController) {
        toggleEphemeralKeyboardVisibility()
    }

    func ephemeralKeyboard(_ keyboard: EphemeralKeyboardViewController, didSelectMessageTimeout timeout: TimeInterval) {
        guard let conversation = conversation as? ZMConversation else { return }

        inputBar.setInputBarState(.writing(ephemeral: timeout != 0 ? .message : .none), animated: true)
        updateMarkdownButton()

        userSession.enqueue {
            conversation.setMessageDestructionTimeoutValue(.init(rawValue: timeout), for: .selfUser)
            self.updateRightAccessoryView()
        }
    }
}

extension ConversationInputBarViewController {
    var ephemeralState: EphemeralState {
        var state = EphemeralState.none

        if !sendButtonState.ephemeral {
            state = .none
        } else if conversation.hasSyncedMessageDestructionTimeout {
            state = .conversation
        } else {
            state = .message
        }

        return state
    }

    func updateViewsForSelfDeletingMessageChanges() {
        updateAccessoryViews()
        updateInputBarButtons()
        inputBar.changeEphemeralState(to: ephemeralState)

        if conversation.hasSyncedMessageDestructionTimeout {
            dismissEphemeralController()
        }
    }
}
