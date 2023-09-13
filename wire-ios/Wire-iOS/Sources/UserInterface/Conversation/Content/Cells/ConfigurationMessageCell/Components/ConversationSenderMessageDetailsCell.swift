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

// MARK: - ConversationSenderMessageDetailsCell

class ConversationSenderMessageDetailsCell: UIView, ConversationMessageCell {

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

    struct Content {
        let user: UserType
        let authorName: String
        let indicator: Indicator
        let teamRoleIndicator: TeamRoleIndicator
        let timestamp: String?
    }



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

    var icon: StyleKitIcon?

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
        let fullName: String
    
        avatar.user = user

        fullName = user.name ?? ""

        configureAuthorLabel(object: object, user: user, fullName: fullName)

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

            authorLabel.topAnchor.constraint(equalTo: self.topAnchor),
            authorLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            avatar.centerYAnchor.constraint(equalTo: authorLabel.firstBaselineAnchor),
            dateLabel.firstBaselineAnchor.constraint(equalTo: authorLabel.firstBaselineAnchor)
        ])
    }

    private func configureAuthorLabel(object: Configuration, user: UserType, fullName: String) {
        let textColor: UIColor = user.isServiceUser ? SemanticColors.Label.textDefault : user.accentColor
        var attributedString = NSMutableAttributedString(string: fullName,
                                                         attributes: [
                                                            .foregroundColor: textColor,
                                                            .font: UIFont.mediumSemiboldFont])

        if object.message.isDeletion {
            attributedString.append(
                stringForAttachment(
                    named: .trash,
                    imageSize: 8
                )
            )

        } else if object.message.updatedAt != nil {
            attributedString.append(
                stringForAttachment(
                    named: .pencil,
                    imageSize: 8
                )
            )
        }

        if user.isServiceUser {
            accessibilityIdentifier = "img.serviceUser"
            attributedString.append(
                stringForAttachment(
                    named: .bot,
                    imageSize: 12
                )
            )
        } else if user.isExternalPartner {
            accessibilityIdentifier = "img.externalPartner"
            attributedString.append(
                stringForAttachment(
                    named: .externalPartner,
                    imageSize: 14

                )
            )
        } else if user.isFederated {
            accessibilityIdentifier = "img.federatedUser"
            attributedString.append(
                stringForAttachment(
                    named: .federated,
                    imageSize: 12
                )
            )
        } else if !user.isTeamMember,
                  let selfUser = SelfUser.provider?.selfUser,
                  selfUser.isTeamMember {
            accessibilityIdentifier = "img.guest"
            attributedString.append(
                stringForAttachment(
                    named: .guest,
                    imageSize: 12
                )
            )

        } else {
            accessibilityIdentifier = "img.member"
        }

        authorLabel.attributedText = attributedString
    }

    fileprivate func stringForAttachment(named imageName: StyleKitIcon, imageSize: CGFloat) -> NSAttributedString {
        let textColor: UIColor = SemanticColors.Icon.foregroundDefault
        let attachment = NSTextAttachment()
        let image = imageName.makeImage(size: StyleKitIcon.Size(floatLiteral: imageSize), color: textColor).with(insets: UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0), backgroundColor: .clear)
        attachment.image = image

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
