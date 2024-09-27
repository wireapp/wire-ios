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

// MARK: - ConversationCannotDecryptSystemMessageCell

final class ConversationCannotDecryptSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {
    struct Configuration {
        let icon: UIImage?
        let attributedText: NSAttributedString?
        let showLine: Bool
    }

    var lastConfiguration: Configuration?

    // MARK: - Configuration

    func configure(with object: Configuration, animated: Bool) {
        lastConfiguration = object
        lineView.isHidden = !object.showLine
        imageView.image = object.icon
        attributedText = object.attributedText
        textLabel.linkTextAttributes = [:]
    }
}

// MARK: - UITextViewDelegate

extension ConversationCannotDecryptSystemMessageCell {
    override func textView(
        _ textView: UITextView,
        shouldInteractWith url: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        delegate?.perform(action: .resetSession, for: message!, view: self)

        return false
    }
}
