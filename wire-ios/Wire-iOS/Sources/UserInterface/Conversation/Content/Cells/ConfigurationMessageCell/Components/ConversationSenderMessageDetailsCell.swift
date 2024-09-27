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
import WireSyncEngine

// MARK: - Indicator

enum Indicator {
    case deleted
    case edited
}

// MARK: - TeamRoleIndicator

enum TeamRoleIndicator {
    case guest
    case externalPartner
    case federated
    case service
}

// MARK: - ConversationSenderMessageDetailsCell

final class ConversationSenderMessageDetailsCell: UIView, ConversationMessageCell {
    // MARK: Lifecycle

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

    // MARK: Internal

    struct Configuration {
        let user: UserType
        let indicator: Indicator?
        let teamRoleIndicator: TeamRoleIndicator?
        let timestamp: String?
    }

    // MARK: - Properties

    weak var delegate: ConversationMessageCellDelegate?

    weak var message: ZMConversationMessage?

    var isSelected = false

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
        layoutIfNeeded()
    }

    // MARK: - Tap gesture of avatar

    @objc
    func tappedOnAvatar() {
        guard let user = avatar.user else { return }

        SessionManager.shared?.showUserProfile(user: user)
    }

    // MARK: - Override method

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        trailingDateLabelConstraint?.constant = -conversationHorizontalMargins.right
    }

    // MARK: Private

    private var trailingDateLabelConstraint: NSLayoutConstraint?

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

    // MARK: - Configure subviews and setup constraints

    private func configureSubviews() {
        addSubview(avatar)
        addSubview(authorLabel)
        addSubview(dateLabel)
    }

    private func configureConstraints() {
        [avatar, authorLabel, dateLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let trailingDateLabelConstraint = dateLabel.trailingAnchor.constraint(
            equalTo: trailingAnchor,
            constant: -conversationHorizontalMargins.right
        )

        self.trailingDateLabelConstraint = trailingDateLabelConstraint
        NSLayoutConstraint.activate([
            avatar.trailingAnchor.constraint(equalTo: authorLabel.leadingAnchor, constant: -12),
            authorLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: conversationHorizontalMargins.left
            ),

            dateLabel.leadingAnchor.constraint(equalTo: authorLabel.trailingAnchor, constant: 8),
            trailingDateLabelConstraint,

            dateLabel.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            authorLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            bottomAnchor.constraint(greaterThanOrEqualTo: authorLabel.bottomAnchor),
            bottomAnchor.constraint(greaterThanOrEqualTo: avatar.bottomAnchor),

            avatar.heightAnchor.constraint(equalTo: avatar.widthAnchor),
            avatar.heightAnchor.constraint(equalToConstant: CGFloat(avatar.size.rawValue)),

            avatar.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            dateLabel.firstBaselineAnchor.constraint(equalTo: authorLabel.firstBaselineAnchor),
        ])
    }

    private func configureAuthorLabel(object: Configuration) {
        let textColor: UIColor = object.user.isServiceUser ? SemanticColors.Label.textDefault : object.user.accentColor
        let attributedString = NSMutableAttributedString(
            string: object.user.name ?? L10n.Localizable.Profile.Details.Title.unavailable,
            attributes: [
                .foregroundColor: textColor,
                .font: UIFont.mediumSemiboldFont,
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

        guard let icon else { return nil }

        let iconSize = icon.size

        let iconBounds = CGRect(
            x: CGFloat(0),
            y: (UIFont.mediumSemiboldFont.capHeight - iconSize.height) / 2.0,
            width: iconSize.width,
            height: iconSize.height
        )
        attachment.bounds = iconBounds
        attachment.image = icon

        return NSAttributedString(attachment: attachment)
    }
}

// MARK: - ConversationSenderMessageCellDescription

final class ConversationSenderMessageCellDescription: ConversationMessageCellDescription {
    // MARK: Lifecycle

    /// Creates a cell description for the given sender and message
    /// - Parameters:
    ///   - sender: The given sender of the message
    ///   - message: The given message
    ///   - timestamp: The given timestamp of the message
    init(sender: UserType, message: ZMConversationMessage, timestamp: String?) {
        self.message = message

        let teamRoleIndicator = sender.teamRoleIndicator()
        var indicator: Indicator?

        if message.isDeletion {
            indicator = .deleted
        } else if message.updatedAt != nil {
            indicator = .edited
        }

        self.configuration = View.Configuration(
            user: sender,
            indicator: indicator,
            teamRoleIndicator: teamRoleIndicator,
            timestamp: timestamp
        )

        setupAccessibility(sender)
        self.actionController = nil
    }

    // MARK: Internal

    // MARK: - Properties

    typealias View = ConversationSenderMessageDetailsCell
    typealias ConversationAnnouncement = L10n.Accessibility.ConversationAnnouncement

    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer = false
    var topMargin: Float = 16

    let isFullWidth = true
    let supportsActions = false
    let containsHighlightableContent = false

    let accessibilityIdentifier: String? = nil
    var accessibilityLabel: String?

    // MARK: Private

    // MARK: - Accessibility

    private func setupAccessibility(_ sender: UserType) {
        guard let message, let senderName = sender.name else {
            accessibilityLabel = nil
            return
        }
        if message.isDeletion {
            accessibilityLabel = ConversationAnnouncement.DeletedMessage.description(senderName)
        } else if message.updatedAt != nil {
            if message.isText, let textMessageData = message.textMessageData {
                let messageText = NSAttributedString.format(
                    message: textMessageData,
                    isObfuscated: message.isObfuscated
                )
                accessibilityLabel = ConversationAnnouncement.EditedMessage.description(senderName) + messageText.string
            } else {
                accessibilityLabel = ConversationAnnouncement.EditedMessage.description(senderName)
            }
        } else {
            accessibilityLabel = nil
        }
    }
}

extension UserType {
    fileprivate func teamRoleIndicator(with provider: SelfUserProvider? = SelfUser.provider) -> TeamRoleIndicator? {
        if isServiceUser {
            .service

        } else if isExternalPartner {
            .externalPartner

        } else if isFederated {
            .federated

        } else if !isTeamMember,
                  let selfUser = provider?.providedSelfUser,
                  selfUser.isTeamMember {
            .guest
        } else {
            nil
        }
    }
}
