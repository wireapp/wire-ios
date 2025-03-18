//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireReusableUIComponents

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

final class ConversationSenderMessageDetailsCell: UIView, ConversationMessageCell {

    struct Configuration {
        let user: UserType
        let indicator: Indicator?
        let teamRoleIndicator: TeamRoleIndicator?
    }

    // MARK: - Properties

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?
    weak var actionController: ConversationMessageActionController?

    var isSelected: Bool = false

    private lazy var avatar: UserImageView = {
        let view = UserImageView()
        view.userSession = ZMUserSession.shared()
        view.initialsFont = .avatarInitial
        view.size = .small
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
        label.setContentHuggingPriority(.required, for: .vertical)
        
        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
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

        // We need to call that method here to restraint the authorLabel moving
        // outside of the view and then back to its position. For more information
        // check the ticket: https://wearezeta.atlassian.net/browse/WPB-1955
        layoutIfNeeded()
    }

    // MARK: - Configure subviews and setup constraints

    private func configureSubviews() {
        let avatarContainerView = UIView()
            .setClipsToBounds(false)
        avatarContainerView.addSubview(avatar)
        avatar.pinOptionally(
                to: avatarContainerView,
                topInset: 0,
                leadingInset: 0,
                trailingInset: 0
            )
        
        let leadingMargin = conversationHorizontalMargins.left - CGFloat(integerLiteral: avatar.size.rawValue) - 7
        let stackView = UIStackView(arrangedSubviews: [
            avatarContainerView
                .wrapInView(leadingInset: leadingMargin)
                .setClipsToBounds(false),
            authorLabel
        ]).setClipsToBounds(false)
            
        stackView.axis = .horizontal
        stackView.spacing = 7
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        avatar.constraintToSquare(sideLength: CGFloat(integerLiteral: avatar.size.rawValue))
        stackView.heightAnchor.constraint(equalTo: authorLabel.heightAnchor).isActive = true
        stackView.fitIn(view: self)
    }

    private func configureAuthorLabel(object: Configuration) {
        let textColor: UIColor = object.user.isServiceUser ? SemanticColors.Label.textDefault : object.user.accentColor
        let attributedString = NSMutableAttributedString(
            string: object.user.name ?? L10n.Localizable.Profile.Details.Title.unavailable,
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

    // MARK: - Tap gesture of avatar

    @objc
    func tappedOnAvatar() {
        guard let user = avatar.user else { return }

        SessionManager.shared?.showUserProfile(user: user)
    }
}

// MARK: - ConversationSenderMessageCellDescription

final class ConversationSenderMessageCellDescription: ConversationMessageCellDescription {

    // MARK: - Properties

    typealias View = ConversationSenderMessageDetailsCell
    typealias ConversationAnnouncement = L10n.Accessibility.ConversationAnnouncement
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var canBeCombinedWithOtherCells: Bool { true }

    var showEphemeralTimer: Bool = false
    var topMargin: CGFloat = 16

    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    var accessibilityLabel: String?

    /// Creates a cell description for the given sender and message
    /// - Parameters:
    ///   - sender: The given sender of the message
    ///   - message: The given message
    ///   - timestamp: The given timestamp of the message
    init(sender: UserType, message: ZMConversationMessage) {
        self.message = message

        let teamRoleIndicator = sender.teamRoleIndicator()
        let indicator: Indicator? = if message.isDeletion {
            .deleted
        } else if message.updatedAt != nil {
            .edited
        } else {
            .none
        }
        self.configuration = View.Configuration(
            user: sender,
            indicator: indicator,
            teamRoleIndicator: teamRoleIndicator
        )

        setupAccessibility(sender)
        self.actionController = nil
    }

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

private extension UserType {
    func teamRoleIndicator(with provider: SelfUserProvider? = SelfUser.provider) -> TeamRoleIndicator? {
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

extension ConversationSenderMessageDetailsCell: UIGestureRecognizerDelegate {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let avatarPoint = avatar.convert(point, from: self)
        
        if avatar.point(inside: avatarPoint, with: event) {
            return avatar
        }
        
        return super.hitTest(point, with: event)
    }
}
