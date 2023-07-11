//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

// MARK: - ConversationSenderMessageDetailsCell

class ConversationSenderMessageDetailsCell: UIView, ConversationMessageCell {

    // MARK: - Message configuration

    struct Configuration {
        let user: UserType
        let message: ZMConversationMessage
        let timestamp: String?
        let indicatorIcon: UIImage?
    }

    // MARK: - Properties

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?

    var isSelected: Bool = false

    private let senderView = SenderCellComponent()
    private let indicatorImageView = UIImageView()

    private var indicatorImageViewTrailing: NSLayoutConstraint!

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = FontSpec.mediumRegularFont.font!
        label.textColor = SemanticColors.Label.textMessageDate
        label.lineBreakMode = .byTruncatingMiddle
        label.numberOfLines = 1
        label.accessibilityIdentifier = "DateLabel"
        label.isAccessibilityElement = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    // MARK: - configure

    func configure(with object: Configuration, animated: Bool) {
        senderView.configure(with: object.user)
        indicatorImageView.isHidden = object.indicatorIcon == nil
        indicatorImageView.image = object.indicatorIcon
        dateLabel.isHidden = object.timestamp == nil
        dateLabel.text = object.timestamp
    }

    // MARK: - Configure subviews and setup constraints

    private func configureSubviews() {
        addSubview(senderView)
        addSubview(indicatorImageView)
        addSubview(dateLabel)
    }

    private func configureConstraints() {
        senderView.translatesAutoresizingMaskIntoConstraints = false
        indicatorImageView.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        indicatorImageViewTrailing = indicatorImageView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor,
                                                                                  constant: -conversationHorizontalMargins.right)
        NSLayoutConstraint.activate([
            // indicatorImageView
            indicatorImageViewTrailing,
            indicatorImageView.centerYAnchor.constraint(equalTo: centerYAnchor),

            // senderView
            senderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            senderView.topAnchor.constraint(equalTo: topAnchor),
            senderView.trailingAnchor.constraint(equalTo: indicatorImageView.leadingAnchor, constant: -8),
            senderView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // dateLabel
            dateLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -conversationHorizontalMargins.right),
            dateLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            dateLabel.topAnchor.constraint(equalTo: topAnchor)
        ])
    }

    // MARK: - Override method

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        indicatorImageViewTrailing.constant = -conversationHorizontalMargins.right
    }

}

// MARK: - ConversationSenderMessageCellDescription

class ConversationSenderMessageCellDescription: ConversationMessageCellDescription {

    // MARK: - Properties

    typealias View = ConversationSenderMessageDetailsCell
    typealias ConversationAnnouncement = L10n.Accessibility.ConversationAnnouncement
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 16

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    var accessibilityLabel: String?

    /// Creates a cell description for the given sender and message
    /// - Parameters:
    ///   - sender: The given sender of the message
    ///   - message: The given message
    ///   - timestamp: The given timestamp of the message
    init(sender: UserType, message: ZMConversationMessage, timestamp: String?) {
        self.message = message

        var icon: UIImage?
        let iconColor = SemanticColors.Icon.foregroundDefault

        if message.isDeletion {
            icon = StyleKitIcon.trash.makeImage(size: 8, color: iconColor)
        } else if message.updatedAt != nil {
            icon = StyleKitIcon.pencil.makeImage(size: 8, color: iconColor)
        }

        self.configuration = View.Configuration(user: sender, message: message, timestamp: timestamp, indicatorIcon: icon)
        setupAccessibility(sender)
        actionController = nil
    }

    // MARK: - Accessibility

    private func setupAccessibility(_ sender: UserType) {
        guard let message = message, let senderName = sender.name else {
            accessibilityLabel = nil
            return
        }
        if message.isDeletion {
            accessibilityLabel = ConversationAnnouncement.DeletedMessage.description(senderName)
        } else if message.updatedAt != nil {
            if message.isText, let textMessageData = message.textMessageData {
                let messageText = NSAttributedString.format(message: textMessageData, isObfuscated: message.isObfuscated)
                accessibilityLabel = ConversationAnnouncement.EditedMessage.description(senderName) + messageText.string
            } else {
                accessibilityLabel = ConversationAnnouncement.EditedMessage.description(senderName)
            }
        } else {
            accessibilityLabel = nil
        }
    }

}
