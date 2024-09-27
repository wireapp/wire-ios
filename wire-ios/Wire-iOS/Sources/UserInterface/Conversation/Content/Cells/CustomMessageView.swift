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
import WireDataModel
import WireDesign

// MARK: - CustomMessageView

final class CustomMessageView: UIView {
    // MARK: Lifecycle

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        messageLabel.isAccessibilityElement = true
        messageLabel.accessibilityLabel = "Text"
        messageLabel
            .linkTextAttributes = [NSAttributedString.Key.underlineStyle: NSUnderlineStyle().rawValue as NSNumber]
        if let selfUser = ZMUser.selfUser() {
            messageLabel.linkTextAttributes[NSAttributedString.Key.foregroundColor] = selfUser.accentColor
        } else {
            assertionFailure("ZMUser.selfUser() is nil")
        }

        super.init(frame: frame)
        addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            messageLabel.topAnchor.constraint(equalTo: topAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        messageLabel.font = FontSpec(.small, .light).font
        messageLabel.textColor = SemanticColors.Label.textDefault
    }

    // MARK: Internal

    var isSelected = false

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?

    var messageLabel = WebLinkTextView()

    var messageText: String? {
        didSet {
            messageLabel.text = messageText?.applying(transform: .upper)
        }
    }
}

// MARK: UITextViewDelegate

extension CustomMessageView: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith url: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        UIApplication.shared.open(url)
        return false
    }
}
