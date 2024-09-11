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
import WireFoundation

// MARK: SplitViewController reveal

extension CharacterSet {
    static var newlinesAndTabulation = CharacterSet(charactersIn: "\r\n\t")
}

extension ConversationInputBarViewController {
    func hideLeftView() {
        let currentDevice = DeviceWrapper(device: .current)
        guard self.isIPadRegularPortrait(device: currentDevice, application: UIApplication.shared) else { return }
        guard let splitViewController = wr_splitViewController,
              splitViewController.isLeftViewControllerRevealed else { return }

        splitViewController.setLeftViewControllerRevealed(false, animated: true)
    }
}

extension ConversationInputBarViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        guard let conversation = conversation as? ZMConversation else { return }

        // In case the conversation isDeleted
        if conversation.managedObjectContext == nil {
            return
        }

        conversation.setIsTyping(!textView.text.isEmpty)

        triggerMentionsIfNeeded(from: textView)
        updateRightAccessoryView()
    }

    func textView(
        _ textView: UITextView,
        shouldInteractWith textAttachment: NSTextAttachment,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        textAttachment.image == nil
    }

    var isMentionsViewKeyboardCollapsed: Bool {
        // Press tab or enter to insert mention if iPhone keyboard is collapsed
        if let isKeyboardCollapsed = mentionsView?.isKeyboardCollapsed {
            isKeyboardCollapsed
        } else {
            false
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // send only if send key pressed
        let currentDevice = DeviceWrapper(device: .current)
        if textView.returnKeyType == .send && (text == "\n") {
            if currentDevice.userInterfaceIdiom == .pad,
               canInsertMention {
                insertBestMatchMention()
            } else {
                inputBar.textView.autocorrectLastWord()
                sendText()
            }
            return false
        }

        // insert mention if return or tab key is pressed and mention view is visible
        if text.count == 1,
           text.containsCharacters(from: CharacterSet.newlinesAndTabulation),
           canInsertMention,
           currentDevice.userInterfaceIdiom == .pad || isMentionsViewKeyboardCollapsed {
            insertBestMatchMention()
            return false
        }

        // we are deleting text one by one
        if text == "", range.length == 1 {
            if let cursor = textView.selectedTextRange, let deletionStart = textView.position(
                from: cursor.start,
                offset: -1
            ) {
                if cursor.start == cursor.end, // We have only caret, no selected text
                   textView.attributedText.containsAttachments(in: range) { // Text to be deleted has text attachment
                    textView.selectedTextRange = textView
                        .textRange(
                            from: deletionStart,
                            to: cursor.start
                        ) // Select the text to be deleted and ignore the backspace
                    return false
                }
            }
        }

        inputBar.textView.respondToChange(text, inRange: range)
        return true
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        guard mode != .audioRecord else { return true }
        triggerMentionsIfNeeded(from: textView)
        return delegate?.conversationInputBarViewControllerShouldBeginEditing(self) ?? true
    }

    func textViewDidBeginEditing(_: UITextView) {
        updateAccessoryViews()
        updateNewButtonTitleLabel()
        hideLeftView()
    }

    func textViewShouldEndEditing(_: UITextView) -> Bool {
        delegate?.conversationInputBarViewControllerShouldEndEditing(self) ?? true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if !textView.text.isEmpty {
            conversation.setIsTyping(false)
        }

        guard let textView = textView as? MarkdownTextView else { preconditionFailure("Invalid textView class") }
        let draft = draftMessage(from: textView)
        delegate?.conversationInputBarViewControllerDidComposeDraft(message: draft)
    }
}
