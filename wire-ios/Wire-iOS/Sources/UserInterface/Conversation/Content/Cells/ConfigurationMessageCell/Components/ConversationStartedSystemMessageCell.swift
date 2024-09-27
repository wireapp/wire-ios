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

// MARK: - ConversationStartedSystemMessageCell

final class ConversationStartedSystemMessageCell: ConversationIconBasedCell, ConversationMessageCell {
    struct Configuration {
        let title: NSAttributedString?
        let message: NSAttributedString
        let selectedUsers: [UserType]
        let icon: UIImage?
    }

    private let titleLabel = UILabel()
    private var selectedUsers: [UserType] = []

    override func configureSubviews() {
        super.configureSubviews()

        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        topContentView.addSubview(titleLabel)
    }

    override func configureConstraints() {
        super.configureConstraints()
        titleLabel.fitIn(view: topContentView)
    }

    func configure(with object: Configuration, animated: Bool) {
        titleLabel.attributedText = object.title
        attributedText = object.message
        imageView.image = object.icon
        imageView.isAccessibilityElement = false
        selectedUsers = object.selectedUsers
        accessibilityLabel = object.title?.string
    }
}

// MARK: - UITextViewDelegate

extension ConversationStartedSystemMessageCell {
    override func textView(
        _ textView: UITextView,
        shouldInteractWith url: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        delegate?.conversationMessageWantsToOpenParticipantsDetails(
            self,
            selectedUsers: selectedUsers,
            sourceView: self
        )

        return false
    }
}
