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
import WireAccountImageUI
import WireCommonComponents
import WireDataModel
import WireDesign
import WireLocators
import WireReusableUIComponents
import WireSyncEngine

enum Indicator: Equatable {
    case deleted
}

enum TeamRoleIndicator {
    case guest
    case externalPartner
    case federated
    case appOrBot
}

// MARK: - ConversationSenderMessageDetailsCell

final class ConversationSenderMessageDetailsCell: UIView, ConversationMessageCell {

    struct Configuration {
        var sender: UserType
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
        view.size = .badge
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedOnAvatar)))
        view.accessibilityElementsHidden = false
        view.isAccessibilityElement = true
        view.accessibilityTraits = .button
        view.accessibilityLabel = L10n.Accessibility.Conversation.ProfileImage.description
        view.accessibilityHint = L10n.Accessibility.Conversation.ProfileImage.hint
        view.heightAnchor.constraint(equalToConstant: 24).isActive = true
        view.widthAnchor.constraint(equalToConstant: 24).isActive = true
        return view
    }()

    private lazy var availabilityIndicatorView = {
        let view = AvailabilityIndicatorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: 9).isActive = true
        view.heightAnchor.constraint(equalToConstant: 9).isActive = true

        let design = AccountImageViewDesign().availabilityIndicator
        view.availableColor = design.availableColor
        view.awayColor = design.awayColor
        view.busyColor = design.busyColor
        view.backgroundViewColor = design.backgroundViewColor

        return view
    }()

    private lazy var authorLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = Locators.ActiveConversationPage.authorName.rawValue
        label.numberOfLines = 0

        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.defaultLow, for: .vertical)

        return label
    }()

    private var userObservation: NSObjectProtocol?

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
        let user = object.sender
        avatar.user = user
        availabilityIndicatorView.availability = user.availability.mapToAccountImageAvailability()

        if let session = ZMUserSession.shared() {
            userObservation = UserChangeInfo.add(observer: self, for: user, in: session)
        }

        configureAuthorLabel(object: object)

    }

    // MARK: - Configure subviews and setup constraints

    private func configureSubviews() {
        avatar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(avatar)
        availabilityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(availabilityIndicatorView)
        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(authorLabel)
    }

    private func configureConstraints() {

        let avatarEqualToTopAnchorConstraint = avatar.topAnchor.constraint(equalTo: topAnchor)
        avatarEqualToTopAnchorConstraint.priority = .defaultLow
        let avatarGreaterThanOrEqualToTopAnchorConstraint = avatar.topAnchor.constraint(
            greaterThanOrEqualTo: topAnchor
        )

        let avatarEqualToBottomAnchorConstraint = bottomAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 3)
        avatarEqualToBottomAnchorConstraint.priority = .defaultLow
        let avatarGreaterThanOrEqualToBottomAnchorConstraint = bottomAnchor.constraint(
            greaterThanOrEqualTo: avatar.bottomAnchor,
            constant: 3
        )

        NSLayoutConstraint.activate([
            authorLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            authorLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -1.5),
            authorLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            authorLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomAnchor.constraint(greaterThanOrEqualTo: authorLabel.bottomAnchor),

            avatar.heightAnchor.constraint(equalTo: avatar.widthAnchor),
            avatar.heightAnchor.constraint(equalToConstant: CGFloat(avatar.size.rawValue)),
            avatar.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -1.5),
            avatar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20.0),

            avatarEqualToTopAnchorConstraint,
            avatarGreaterThanOrEqualToTopAnchorConstraint,
            avatarEqualToBottomAnchorConstraint,
            avatarGreaterThanOrEqualToBottomAnchorConstraint,

            availabilityIndicatorView.trailingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 3),
            availabilityIndicatorView.bottomAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 3)
        ])

    }

    private func configureAuthorLabel(object: Configuration) {
        let sender = object.sender
        let textColor: UIColor = sender.isAppOrBot ? SemanticColors.Label.textDefault : sender.accentColor
        let attributedString = NSMutableAttributedString(
            string: sender.name ?? L10n.Localizable.Profile.Details.Title.unavailable,
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

        case .appOrBot:
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
    var configuration: View.Configuration

    var message: ZMConversationMessage? {
        didSet {
            if let sender = message?.senderUser {
                configuration.sender = sender
            }
        }
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    let containsHighlightableContent: Bool = false
    let shouldAlignMessageContentForBubbles: Bool = true
    let isCellAlreadyAligned: Bool = true

    let accessibilityIdentifier: String? = nil
    var accessibilityLabel: String?

    /// Creates a cell description for the given sender and message
    /// - Parameters:
    ///   - sender: The given sender of the message
    ///   - message: The given message
    ///   - timestamp: The given timestamp of the message
    init(
        sender: UserType,
        selfUser: any UserType,
        message: ZMConversationMessage
    ) {
        self.message = message
        let teamRoleIndicator = sender.teamRoleIndicator(selfUser: selfUser)
        let indicator: Indicator? = if message.isDeletion {
            .deleted
        } else {
            .none
        }
        self.configuration = View.Configuration(
            sender: sender,
            indicator: indicator,
            teamRoleIndicator: teamRoleIndicator
        )

        setupAccessibility(sender, selfUser: selfUser)
        self.actionController = nil
    }

    // MARK: - Accessibility

    private func setupAccessibility(
        _ sender: UserType,
        selfUser: (any UserType)?
    ) {
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
                    isObfuscated: message.isObfuscated,
                    accentColor: (selfUser?.zmAccentColor ?? .default).accentColor
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

    func teamRoleIndicator(selfUser: any UserType) -> TeamRoleIndicator? {
        if isAppOrBot {
            .appOrBot

        } else if isExternalPartner {
            .externalPartner

        } else if isFederated {
            .federated

        } else if !isTeamMember, selfUser.isTeamMember {
            .guest
        } else {
            nil
        }
    }

}

extension ConversationSenderMessageDetailsCell: UserObserving {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        if changeInfo.availabilityChanged {
            availabilityIndicatorView.availability = changeInfo.user.availability.mapToAccountImageAvailability()
        }
    }
}
