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
import WireDesign

extension ConversationInputBarViewController {

    func configureMarkdownButton() {

        markdownButton.addTarget(self, action: #selector(markdownButtonTapped), for: .touchUpInside)
        markdownButton.setIcon(.markdownToggle, size: .tiny, for: .normal)

        markdownButton.setIconColor(SemanticColors.Button.textInputBarItemEnabled, for: .normal)
    }

    func updateMarkdownButton() {
        typealias Conversation = L10n.Accessibility.Conversation

        let color: UIColor
        let backgroundColor: UIColor
        let borderColor: UIColor
        markdownButton.isHidden = inputBar.isEditing

        if inputBar.isMarkingDown {
            color = SemanticColors.Button.textInputBarItemHighlighted
                .resolvedColor(with: traitCollection)
            backgroundColor = SemanticColors.Button.backgroundInputBarItemHighlighted
                .resolvedColor(with: traitCollection)
            borderColor = SemanticColors.Button.borderInputBarItemHighlighted
                .resolvedColor(with: traitCollection)
        } else {
            color = SemanticColors.Button.textInputBarItemEnabled
                .resolvedColor(with: traitCollection)
            backgroundColor = SemanticColors.Button.backgroundInputBarItemEnabled
                .resolvedColor(with: traitCollection)
            borderColor = SemanticColors.Button.borderInputBarItemEnabled
                .resolvedColor(with: traitCollection)
        }

        markdownButton.setIconColor(color, for: .normal)
        markdownButton.setBorderColor(borderColor, for: .normal)
        markdownButton.setBackgroundImageColor(backgroundColor, for: .normal)

        markdownButton.setIconColor(
            SemanticColors.Button.textInputBarItemHighlighted.resolvedColor(with: traitCollection),
            for: .highlighted
        )
        markdownButton.setBorderColor(
            SemanticColors.Button.borderInputBarItemHighlighted.resolvedColor(with: traitCollection),
            for: .highlighted
        )
        markdownButton.setBackgroundImageColor(
            SemanticColors.Button.backgroundInputBarItemHighlighted.resolvedColor(with: traitCollection),
            for: .highlighted
        )

        markdownButton.isEnabled = !inputBar.isEditing
        markdownButton.accessibilityLabel = inputBar.isMarkingDown
            ? Conversation.HideFormattingButton.description
            : Conversation.OpenFormattingButton.description
    }

    @objc
    private func markdownButtonTapped(_ sender: IconButton) {

        if !inputBar.isMarkingDown {
            inputBar.textView.becomeFirstResponder()
            inputBar.setInputBarState(.markingDown(ephemeral: ephemeralState), animated: true)
        } else {
            inputBar.setInputBarState(.writing(ephemeral: ephemeralState), animated: true)
        }

        updateMarkdownButton()
        updateButtonStates()
        inputBar.markdownView.updateAccessibilityElements(isAccessible: inputBar.isMarkingDown)
    }
}
