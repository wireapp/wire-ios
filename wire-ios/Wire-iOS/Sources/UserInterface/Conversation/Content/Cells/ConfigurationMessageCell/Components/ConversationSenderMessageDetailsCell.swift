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
import WireSyncEngine

enum Indicator {
    case deleted
    case edited
}

enum TeamRoleIndicator {
    case guest
    case externalPartner
    case federated
    case service
}

// MARK: - ConversationSenderMessageDetailsCell

class ConversationSenderMessageDetailsCell: UIView, ConversationMessageCell {

    struct Configuration {
        let user: UserType
        let indicator: Indicator?
        let teamRoleIndicator: TeamRoleIndicator?
        let timestamp: String?
    }

    // MARK: - Properties

    weak var delegate: ConversationMessageCellDelegate?

    weak var message: ZMConversationMessage?

    private var trailingDateLabelConstraint: NSLayoutConstraint?

    var isSelected: Bool = false

    private lazy var avatar: UserImageView = {
        let view = UserImageView()
        view.userSession = ZMUserSession.shared()
        view.initialsFont = .avatarInitial
        view.size = .badge
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedOnAvatar)))
        view.accessibilityElementsHidden = false
        view.isAccessibilityElement = true
        view.accessibilityTraits = .button
        view.accessibilityLabel = L10n.Accessibility.Conversation.ProfileImage.description
        view.accessibilityHint = L10n.Accessibility.Conversation.ProfileImage.hint

        return view
    }()

    private lazy var authorLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "author.name"
        label.numberOfLines = 0

        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.defaultLow, for: .vertical)

        return label
    }()

    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = FontSpec.mediumRegularFont.font!
        label.textColor = SemanticColors.Label.textMessageDate
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.lineBreakMode = .byTruncatingMiddle
        label.numberOfLines = 1
        label.accessibilityIdentifier = "DateLabel"
        label.isAccessibilityElement = true

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
        let user = object.user
        avatar.user = user

        configureAuthorLabel(object: object)

        dateLabel.isHidden = object.timestamp == nil
        dateLabel.text = object.timestamp

        // We need to call that method here to restraint the authorLabel moving
        // outside of the view and then back to its position. For more information
        // check the ticket: https://wearezeta.atlassian.net/browse/WPB-1955
        self.layoutIfNeeded()
    }

    // MARK: - Configure subviews and setup constraints

    private func configureSubviews() {
        addSubview(avatar)
        addSubview(authorLabel)
        addSubview(dateLabel)
    }

    private func configureConstraints() {

        [avatar, authorLabel, dateLabel].prepareForLayout()

        let trailingDateLabelConstraint  = dateLabel.trailingAnchor.constraint(
            equalTo: self.trailingAnchor,
            constant: -conversationHorizontalMargins.right
        )

        self.trailingDateLabelConstraint = trailingDateLabelConstraint
        NSLayoutConstraint.activate([
            avatar.trailingAnchor.constraint(equalTo: authorLabel.leadingAnchor, constant: -12),
            authorLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: conversationHorizontalMargins.left),

            dateLabel.leadingAnchor.constraint(equalTo: authorLabel.trailingAnchor, constant: 8),
            trailingDateLabelConstraint,

            dateLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            authorLabel.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor),
            self.bottomAnchor.constraint(greaterThanOrEqualTo: authorLabel.bottomAnchor),
            self.bottomAnchor.constraint(greaterThanOrEqualTo: avatar.bottomAnchor),

            avatar.heightAnchor.constraint(equalTo: avatar.widthAnchor),
            avatar.heightAnchor.constraint(equalToConstant: CGFloat(avatar.size.rawValue)),

            avatar.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor),
            dateLabel.firstBaselineAnchor.constraint(equalTo: authorLabel.firstBaselineAnchor)
        ])
    }

    private func configureAuthorLabel(object: Configuration) {
        let textColor: UIColor = object.user.isServiceUser ? SemanticColors.Label.textDefault : object.user.accentColor
        let attributedString = NSMutableAttributedString(
            string: object.user.name ?? "",
            attributes: [
                .foregroundColor: textColor,
                .font: UIFont.mediumSemiboldFont
            ]
        )

        switch object.indicator {

        case .deleted:
            if let attachment = attachment(from: .trash, size: 8) {
                attributedString.append(attachment)
            }

        case .edited:
            if let attachment = attachment(from: .pencil, size: 8) {
                attributedString.append(attachment)
            }

        default:
            break
        }

        switch object.teamRoleIndicator {

        case .guest:
            accessibilityIdentifier = "img.guest"
            if let attachment = attachment(from: .guest, size: 14) {
                attributedString.append(attachment)
            }

        case .externalPartner:
            accessibilityIdentifier = "img.externalPartner"
            if let attachment = attachment(from: .externalPartner, size: 16) {
                attributedString.append(attachment)
            }
        case .federated:
            accessibilityIdentifier = "img.federatedUser"
            if let attachment = attachment(from: .federated, size: 14) {
                attributedString.append(attachment)
            }
        case .service:
            accessibilityIdentifier = "img.serviceUser"
            if let attachment = attachment(from: .bot, size: 14) {
                attributedString.append(attachment)
            }

        default:
            accessibilityIdentifier = "img.member"
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = UIFont.mediumSemiboldFont.lineHeight

        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: attributedString.wholeRange)

        authorLabel.attributedText = attributedString
    }

    private func attachment(from icon: StyleKitIcon, size: CGFloat) -> NSAttributedString? {
        let textColor: UIColor = SemanticColors.Icon.foregroundDefault
        let attachment = NSTextAttachment()

        let icon = icon.makeImage(
            size: StyleKitIcon.Size(floatLiteral: size),
            color: textColor
        ).with(insets: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0), backgroundColor: .clear)

        guard let icon = icon else { return nil }

        let iconSize = icon.size

        let iconBounds = CGRect(x: CGFloat(0),
                                y: (UIFont.mediumSemiboldFont.capHeight - iconSize.height) / 2.0,
                                width: iconSize.width,
                                height: iconSize.height)
        attachment.bounds = iconBounds
        attachment.image = icon

        return NSAttributedString(attachment: attachment)
    }

    // MARK: - Tap gesture of avatar

    @objc func tappedOnAvatar() {
        guard let user = avatar.user else { return }

        SessionManager.shared?.showUserProfile(user: user)
    }

    // MARK: - Override method

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        trailingDateLabelConstraint?.constant = -conversationHorizontalMargins.right
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

        var teamRoleIndicator: TeamRoleIndicator?
        var indicator: Indicator?

        if message.isDeletion {
            indicator = .deleted
        } else if message.updatedAt != nil {
            indicator = .edited
        }

        if sender.isServiceUser {
            teamRoleIndicator = .service

        } else if sender.isExternalPartner {
            teamRoleIndicator = .externalPartner

        } else if sender.isFederated {
            teamRoleIndicator = .federated

        } else if !sender.isTeamMember,
                  let selfUser = SelfUser.provider?.selfUser,
                  selfUser.isTeamMember {
            teamRoleIndicator = .guest
        }

        self.configuration = View.Configuration(
            user: sender,
            indicator: indicator,
            teamRoleIndicator: teamRoleIndicator,
            timestamp: timestamp
        )

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
