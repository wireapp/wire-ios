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
import WireDataModel

extension ConversationInputBarViewController: ReplyComposingViewDelegate {

    func reply(to message: ZMConversationMessage, composingView: ReplyComposingView) {
        if replyComposingView != nil {
            removeReplyComposingView()
        }

        addReplyComposingView(composingView)

        // Draft restoration uses addReplyComposingView directly and must not move reading focus.
        guard UIAccessibility.isVoiceOverRunning, inputBar.textView.window != nil else { return }
        pendingReplyAccessibilityFocus = composingView
        mode = .textInput
        inputBar.textView.becomeFirstResponder()
        scheduleReplyAccessibilityFocus()
    }

    func configureReplyAccessibilityFocus() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(replyKeyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(replyKeyboardDidChangeFrame),
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil
        )
    }

    @objc
    private func replyKeyboardWillChangeFrame(_ notification: Notification) {
        isReplyKeyboardTransitioning = true
    }

    @objc
    private func replyKeyboardDidChangeFrame(_ notification: Notification) {
        isReplyKeyboardTransitioning = false
        scheduleReplyAccessibilityFocus()
    }

    private func scheduleReplyAccessibilityFocus() {
        guard pendingReplyAccessibilityFocus != nil else { return }

        // Let the initiating action and keyboard callbacks finish before changing VoiceOver focus.
        // An already open keyboard (or hardware keyboard) needs no new frame notification.
        DispatchQueue.main.async { [weak self] in
            guard let self, !isReplyKeyboardTransitioning else { return }
            guard let composingView = pendingReplyAccessibilityFocus else { return }
            pendingReplyAccessibilityFocus = nil

            let textView = inputBar.textView
            guard replyComposingView === composingView,
                  UIAccessibility.isVoiceOverRunning,
                  textView.isFirstResponder,
                  let window = textView.window else { return }

            window.layoutIfNeeded()
            UIAccessibility.post(notification: .screenChanged, argument: textView)
        }
    }

    func addReplyComposingView(_ composingView: ReplyComposingView) {
        quotedMessage = composingView.message
        replyComposingView = composingView
        composingView.delegate = self
    }

    func removeReplyComposingView() {
        pendingReplyAccessibilityFocus = nil
        quotedMessage = nil
        replyComposingView?.removeFromSuperview()
        replyComposingView = nil

        if let draft = conversation.draftMessage {
            let modifiedDraft = DraftMessage(text: draft.text, mentions: draft.mentions, quote: nil)
            delegate?.conversationInputBarViewControllerDidComposeDraft(message: modifiedDraft)
        }
    }

    func composingViewDidCancel(composingView: ReplyComposingView) {
        removeReplyComposingView()
    }

    func composingViewWantsToShowMessage(composingView: ReplyComposingView, message: ZMConversationMessage) {
        delegate?.conversationInputBarViewControllerWants(toShow: message)
    }

    var isReplyingToMessage: Bool {
        quotedMessage != nil
    }

    var isEditingMessage: Bool {
        editingMessage != nil
    }
}
