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
import WireDesign
import WireSyncEngine

final class UserCell: SeparatorCollectionViewCell, SectionListCellType {

    // MARK: - Properties

    // This property should in the long run replace the `user: UserType` property
    // provided in the `configure` method. Unfortunately, currently there is still code
    // which depends on the actual `UserType`/`ZMUser` instance, like the `BadgeUserImageView`.
    var userStatus = UserStatus() {
        didSet { updateTitleLabel() }
    }

    private var userIsSelfUser = false
    private var isSelfUserPartOfATeam = false
    private var userIsServiceUser = false

    typealias IconColors = SemanticColors.Icon
    typealias LabelColors = SemanticColors.Label

    var hidesSubtitle: Bool = false
    let avatarSpacer = UIView()
    let avatarImageView = BadgeUserImageView()
    let titleLabel = DynamicFontLabel(fontSpec: .bodyTwoSemibold,
                                      color: LabelColors.textDefault)
    let subtitleLabel = DynamicFontLabel(fontSpec: .mediumRegularFont,
                                         color: LabelColors.textCellSubtitle)
    let connectButton = IconButton()
    let accessoryIconView = UIImageView()
    let userTypeIconView = IconImageView()
    let videoIconView = IconImageView()

    lazy var connectingLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(
            fontSpec: .mediumRegularFont,
            color: LabelColors.textErrorDefault
        )

        label.isHidden = true
        return label
    }()

    let checkmarkIconView = UIImageView()
    let microphoneIconView = PulsingIconImageView()
    var contentStackView: UIStackView!
    var titleStackView: UIStackView!
    var iconStackView: UIStackView!
    var unconnectedStateOverlay = UIView()

    fileprivate var avatarSpacerWidthConstraint: NSLayoutConstraint?

    static let boldFont: FontSpec = .smallRegularFont
    static let lightFont: FontSpec = .smallLightFont
    static let defaultAvatarSpacing: CGFloat = 64

    /// Specify a custom avatar spacing
    var avatarSpacing: CGFloat? {
        get { avatarSpacerWidthConstraint?.constant }
        set { avatarSpacerWidthConstraint?.constant = newValue ?? UserCell.defaultAvatarSpacing }
    }

    var sectionName: String?
    var obfuscatedSectionName: String?
    var cellIdentifier: String?
    let iconColor = IconColors.foregroundDefault

    // MARK: - Override properties

    override var isSelected: Bool {
        didSet {
            if isSelected {
                checkmarkIconView.setTemplateIcon(.checkmark, size: 12)
                checkmarkIconView.tintColor = IconColors.foregroundCheckMarkSelected
                checkmarkIconView.backgroundColor = .accent()
                checkmarkIconView.layer.borderColor = UIColor.clear.cgColor
                checkmarkIconView.layer.borderWidth = 0
            } else {
                checkmarkIconView.image = nil
                checkmarkIconView.backgroundColor = IconColors.backgroundCheckMark
                checkmarkIconView.layer.borderColor = IconColors.borderCheckMark.cgColor
                checkmarkIconView.layer.borderWidth = 2
            }
            setupAccessibility()
        }
    }

    // MARK: - Methods

    override func prepareForReuse() {
        super.prepareForReuse()

        UIView.performWithoutAnimation {
            hidesSubtitle = false
            userTypeIconView.isHidden = true
            videoIconView.isHidden = true
            microphoneIconView.isHidden = true
            connectingLabel.isHidden = true
            connectButton.isHidden = true
            accessoryIconView.isHidden = true
            checkmarkIconView.image = nil
            checkmarkIconView.layer.borderColor = IconColors.borderCheckMark.cgColor
            checkmarkIconView.isHidden = true
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }

        // Border colors are not dynamically updating for Dark Mode
        // When you use adaptive colors with CALayers you’ll notice that these colors,
        // are not updating when switching appearance live in the app.
        // That's why we use the traitCollectionDidChange(_:) method.
        checkmarkIconView.layer.borderColor = IconColors.borderCheckMark.cgColor

        updateTitleLabel()
    }

    override func setUp() {
        super.setUp()

        // userTypeIconView
        userTypeIconView.translatesAutoresizingMaskIntoConstraints = false
        userTypeIconView.contentMode = .center
        userTypeIconView.accessibilityIdentifier = nil
        userTypeIconView.isHidden = true
        userTypeIconView.set(size: .tiny, color: iconColor)

        // videoIconView
        videoIconView.translatesAutoresizingMaskIntoConstraints = false
        videoIconView.contentMode = .center
        videoIconView.accessibilityIdentifier = nil
        videoIconView.isHidden = true
        videoIconView.set(size: .tiny, color: iconColor)

        // microphoneIconView
        microphoneIconView.translatesAutoresizingMaskIntoConstraints = false
        microphoneIconView.contentMode = .center
        microphoneIconView.accessibilityIdentifier = nil
        microphoneIconView.isHidden = true
        microphoneIconView.set(size: .tiny, color: iconColor)

        // connectButton
        connectButton.setIcon(.plusCircled, size: .tiny, for: .normal)
        connectButton.setIconColor(iconColor, for: .normal)
        connectButton.imageView?.contentMode = .center
        connectButton.isHidden = true

        // checkmarkIconView
        checkmarkIconView.layer.borderWidth = 2
        checkmarkIconView.contentMode = .center
        checkmarkIconView.layer.cornerRadius = 12
        checkmarkIconView.backgroundColor = IconColors.backgroundCheckMark
        checkmarkIconView.isHidden = true

        // connectingLabel
        connectingLabel.text = L10n.Localizable.Call.Status.connecting

        // accessoryIconView

        accessoryIconView.translatesAutoresizingMaskIntoConstraints = false
        accessoryIconView.contentMode = .center
        accessoryIconView.accessibilityIdentifier = nil
        accessoryIconView.isHidden = true
        accessoryIconView.image = .init(resource: .chevronRight).withRenderingMode(.alwaysTemplate)
        accessoryIconView.tintColor = IconColors.foregroundDefault

        // titleLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.accessibilityIdentifier = "user_cell.name"
        titleLabel.lineBreakMode = .byTruncatingMiddle

        // subtitleLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.accessibilityIdentifier = "user_cell.username"

        // avatar
        avatarImageView.userSession = ZMUserSession.shared()
        avatarImageView.initialsFont = .avatarInitial
        avatarImageView.size = .small
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false

        // avatarSpacer
        avatarSpacer.addSubview(avatarImageView)
        avatarSpacer.translatesAutoresizingMaskIntoConstraints = false

        // iconStackView
        iconStackView = UIStackView(
            arrangedSubviews: [
                videoIconView,
                microphoneIconView,
                userTypeIconView,
                connectButton,
                checkmarkIconView,
                accessoryIconView,
                connectingLabel
            ]
        )
        iconStackView.spacing = 16
        iconStackView.axis = .horizontal
        iconStackView.distribution = .fill
        iconStackView.alignment = .center
        iconStackView.translatesAutoresizingMaskIntoConstraints = false
        iconStackView.setContentHuggingPriority(.required, for: .horizontal)

        // titleStackView
        titleStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStackView.axis = .vertical
        titleStackView.distribution = .equalSpacing
        titleStackView.alignment = .leading
        titleStackView.translatesAutoresizingMaskIntoConstraints = false

        // contentStackView
        contentStackView = UIStackView(arrangedSubviews: [avatarSpacer, titleStackView, iconStackView])
        contentStackView.axis = .horizontal
        contentStackView.distribution = .fill
        contentStackView.alignment = .center
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        // unconnectedStateOverlay
        unconnectedStateOverlay.backgroundColor = SemanticColors.View.backgroundDefaultWhite.withAlphaComponent(0.3)
        unconnectedStateOverlay.isHidden = true
        unconnectedStateOverlay.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(contentStackView)
        contentView.addSubview(unconnectedStateOverlay)
        createConstraints()
    }

    // MARK: - Set up constraints

    private func createConstraints() {
        let avatarSpacerWidthConstraint = avatarSpacer.widthAnchor.constraint(equalToConstant: UserCell.defaultAvatarSpacing)
        self.avatarSpacerWidthConstraint = avatarSpacerWidthConstraint

        NSLayoutConstraint.activate([
            checkmarkIconView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkIconView.heightAnchor.constraint(equalToConstant: 24),
            avatarImageView.widthAnchor.constraint(equalToConstant: 28),
            avatarImageView.heightAnchor.constraint(equalToConstant: 28),
            avatarSpacerWidthConstraint,
            avatarSpacer.heightAnchor.constraint(equalTo: avatarImageView.heightAnchor),
            avatarSpacer.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            avatarSpacer.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            unconnectedStateOverlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            unconnectedStateOverlay.topAnchor.constraint(equalTo: contentView.topAnchor),
            unconnectedStateOverlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            unconnectedStateOverlay.trailingAnchor.constraint(equalTo: titleStackView.trailingAnchor)
        ])
    }

    // MARK: - setup Accessibility

    func setupAccessibility() {
        typealias ClientsList = L10n.Accessibility.ClientsList
        typealias Calling = L10n.Accessibility.Calling

        guard let title = titleLabel.text else {
            isAccessibilityElement = false
            return
        }
        isAccessibilityElement = true
        accessibilityTraits = .button

        var content = "\(title)"

        if let subtitle = subtitleLabel.text {
            content += ", " + subtitle
        }

        if let userType = userTypeIconView.accessibilityLabel,
           !userTypeIconView.isHidden {
            content += ", \(userType)"
        }

        if userStatus.isE2EICertified {
            if userIsSelfUser {
                content += ", " + L10n.Accessibility.GroupDetails.Conversation.Participants.allYourDevicesHaveValidCertificates
            } else {
                content += ", " + L10n.Accessibility.GroupDetails.Conversation.Participants.allDevicesHaveValidCertificates
            }
        }
        if userStatus.isProteusVerified {
            if userIsSelfUser {
                content += ", " + L10n.Accessibility.GroupDetails.Conversation.Participants.allYourDevicesProteusVerified
            } else {
                content += ", " + L10n.Accessibility.GroupDetails.Conversation.Participants.allDevicesProteusVerified
            }
        }

        if !microphoneIconView.isHidden {
            accessibilityTraits = .staticText
            if let microphoneStyle = microphoneIconView.style as? MicrophoneIconStyle {
                switch microphoneStyle {
                case .unmuted, .unmutedPulsing:
                    content += ", " + Calling.MicrophoneOn.description
                case .muted, .hidden:
                    content += ", " + Calling.MicrophoneOff.description
                }
            }

            if !videoIconView.isHidden {
                content += ", " + Calling.CameraOn.description
            }
        } else {
            setupAccessibilityHint()
        }

        accessibilityLabel = content
    }

    private func setupAccessibilityHint() {
        typealias ContactsList = L10n.Accessibility.ContactsList
        typealias ServicesList = L10n.Accessibility.ServicesList
        typealias ClientsList = L10n.Accessibility.ClientsList
        typealias CreateConversation = L10n.Accessibility.CreateConversation

        if !checkmarkIconView.isHidden {
            accessibilityHint = isSelected ? CreateConversation.SelectedUser.hint : CreateConversation.UnselectedUser.hint
        } else if userIsServiceUser {
            accessibilityHint = ServicesList.ServiceCell.hint
        } else {
            accessibilityHint = ContactsList.UserCell.hint
        }
    }

    // MARK: - Update and configure methods

    private func updateTitleLabel() {
        titleLabel.attributedText = userStatus.title(
            color: SemanticColors.Label.textDefault,
            includeAvailability: isSelfUserPartOfATeam,
            includeVerificationStatus: true,
            appendYouSuffix: userIsSelfUser
        )
    }
}

// MARK: - UserCell + configure

extension UserCell {

    /// Updates the cell with the provided information.
    /// - parameter userStatus: At the moment only the E2EI and Proteus verification statuses are considered from this value.
    func configure(
        userStatus: UserStatus,
        user: UserType, // ideally no UserType instance would be needed
        userIsSelfUser: Bool,
        isSelfUserPartOfATeam: Bool,
        subtitle overrideSubtitle: NSAttributedString? = nil,
        conversation: GroupDetailsConversationType? = nil
    ) {
        self.userStatus = userStatus
        self.userIsSelfUser = userIsSelfUser
        self.isSelfUserPartOfATeam = isSelfUserPartOfATeam
        self.userIsServiceUser = user.isServiceUser

        let subtitle: NSAttributedString?
        if overrideSubtitle == nil {
            subtitle = self.subtitle(for: user)
        } else {
            subtitle = overrideSubtitle
        }

        avatarImageView.user = user
        updateTitleLabel()

        let style = UserTypeIconStyle(
            conversation: conversation,
            user: user,
            selfUserHasTeam: isSelfUserPartOfATeam
        )
        userTypeIconView.set(style: style)

        if let subtitle, !subtitle.string.isEmpty, !hidesSubtitle {
            subtitleLabel.isHidden = false
            subtitleLabel.attributedText = subtitle
        } else {
            subtitleLabel.isHidden = true
        }
        setupAccessibility()
    }

    /// Updates the cell with the information in the user instance.
    ///
    /// - Parameters:
    ///     - user: The user with values to configure the cell.
    ///     - isE2EICertified: Use `true` when the verification status is needed.
    ///     - isSelfUserPartOfATeam: Use `true` is the user is part of any team.
    ///     - overrideSubtitle: Provide a subtitle to override defaults.
    ///     - conversation: The related conversation.
    ///
    /// - Note: Please consider to use configure(userStatus:[...]) to make refactorings easier in future.
    func configure(
        user: UserType,
        isE2EICertified: Bool = false,
        isSelfUserPartOfATeam: Bool,
        subtitle overrideSubtitle: NSAttributedString? = nil,
        conversation: GroupDetailsConversationType? = nil
    ) {
        configure(
            userStatus: .init(user: user, isE2EICertified: isE2EICertified),
            user: user,
            userIsSelfUser: user.isSelfUser,
            isSelfUserPartOfATeam: isSelfUserPartOfATeam,
            subtitle: overrideSubtitle,
            conversation: conversation
        )
    }
}

// MARK: - Subtitle

extension UserCell: UserCellSubtitleProtocol {}

extension UserCell {

    private func subtitle(for user: UserType) -> NSAttributedString? {
        if user.isServiceUser, let service = user as? SearchServiceUser {
            subtitle(forServiceUser: service)
        } else {
            subtitle(forRegularUser: user)
        }
    }

    private func subtitle(forServiceUser service: SearchServiceUser) -> NSAttributedString? {
        guard let summary = service.summary else { return nil }
        return .init(string: summary, attributes: [.font: UserCell.boldFont.font].compactMapValues { $0 })
    }
}
