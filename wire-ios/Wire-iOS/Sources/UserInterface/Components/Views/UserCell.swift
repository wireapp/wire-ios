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
import WireSyncEngine

extension UIImageView {
    func setUpIconImageView(accessibilityIdentifier: String? = nil) {
        translatesAutoresizingMaskIntoConstraints = false
        contentMode = .center
        self.accessibilityIdentifier = accessibilityIdentifier
        isHidden = true
    }
}

class UserCell: SeparatorCollectionViewCell, SectionListCellType {

    // MARK: - Properties

    typealias IconColors = SemanticColors.Icon
    typealias LabelColors = SemanticColors.Label

    var hidesSubtitle: Bool = false
    let avatarSpacer = UIView()
    let avatar = BadgeUserImageView()
    let titleLabel = DynamicFontLabel(fontSpec: .bodyTwoSemibold,
                                      color: LabelColors.textDefault)
    let subtitleLabel = DynamicFontLabel(fontSpec: .mediumRegularFont,
                                         color: LabelColors.textCellSubtitle)
    let connectButton = IconButton()
    let accessoryIconView = UIImageView()
    let userTypeIconView = IconImageView()
    let verifiedIconView = UIImageView()
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

    weak var user: UserType?

    static let boldFont: FontSpec = .smallRegularFont
    static let lightFont: FontSpec = .smallLightFont
    static let defaultAvatarSpacing: CGFloat = 64

    /// Specify a custom avatar spacing
    var avatarSpacing: CGFloat? {
        get {
            return avatarSpacerWidthConstraint?.constant
        }
        set {
            avatarSpacerWidthConstraint?.constant = newValue ?? UserCell.defaultAvatarSpacing
        }
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

    override func prepareForReuse() {
        super.prepareForReuse()

        UIView.performWithoutAnimation {
            hidesSubtitle = false
            userTypeIconView.isHidden = true
            verifiedIconView.isHidden = true
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
        //  Border colors are not dynamically updating for Dark Mode
        //  When you use adaptive colors with CALayers you’ll notice that these colors,
        // are not updating when switching appearance live in the app.
        // That's why we use the traitCollectionDidChange(_:) method.
        checkmarkIconView.layer.borderColor = IconColors.borderCheckMark.cgColor
        updateTitleLabel()
    }

    override func setUp() {
        super.setUp()

        // userTypeIconView
        userTypeIconView.setUpIconImageView()
        userTypeIconView.set(size: .tiny, color: iconColor)

        // videoIconView
        videoIconView.setUpIconImageView()
        videoIconView.set(size: .tiny, color: iconColor)

        // microphoneIconView
        microphoneIconView.setUpIconImageView()
        microphoneIconView.set(size: .tiny, color: iconColor)

        // verifiedIconView
        verifiedIconView.image = WireStyleKit.imageOfShieldverified
        verifiedIconView.setUpIconImageView(accessibilityIdentifier: "img.shield")

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
        accessoryIconView.setUpIconImageView()
        accessoryIconView.image = Asset.Images.rightChevron.image.withRenderingMode(.alwaysTemplate)
        accessoryIconView.tintColor = IconColors.foregroundDefault

        // titleLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.accessibilityIdentifier = "user_cell.name"

        // subtitleLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.accessibilityIdentifier = "user_cell.username"

        // avatar
        avatar.userSession = ZMUserSession.shared()
        avatar.initialsFont = .avatarInitial
        avatar.size = .small
        avatar.translatesAutoresizingMaskIntoConstraints = false

        // avatarSpacer
        avatarSpacer.addSubview(avatar)
        avatarSpacer.translatesAutoresizingMaskIntoConstraints = false

        // iconStackView
        iconStackView = UIStackView(
            arrangedSubviews: [videoIconView,
                               microphoneIconView,
                               userTypeIconView,
                               verifiedIconView,
                               connectButton,
                               checkmarkIconView,
                               accessoryIconView,
                               connectingLabel]
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
            avatar.widthAnchor.constraint(equalToConstant: 28),
            avatar.heightAnchor.constraint(equalToConstant: 28),
            avatarSpacerWidthConstraint,
            avatarSpacer.heightAnchor.constraint(equalTo: avatar.heightAnchor),
            avatarSpacer.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarSpacer.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
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

        if !verifiedIconView.isHidden {
            content += ", " + ClientsList.DeviceVerified.description
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
        } else if let user = user, user.isServiceUser {
            accessibilityHint = ServicesList.ServiceCell.hint
        } else {
            accessibilityHint = ContactsList.UserCell.hint
        }
    }

    // MARK: - Update and configure methods

    private func updateTitleLabel(selfUser: UserType? = nil) {
        guard let user = user,
              let selfUser = selfUser else {
            return
        }
        var attributedTitle = user.nameIncludingAvailability(
            color: SemanticColors.Label.textDefault,
            selfUser: selfUser)

        if user.isSelfUser, let title = attributedTitle {
            attributedTitle = title + "user_cell.title.you_suffix".localized
        }

        titleLabel.attributedText = attributedTitle
    }

    func configure(with user: UserType,
                   selfUser: UserType,
                   subtitle overrideSubtitle: NSAttributedString? = nil,
                   conversation: GroupDetailsConversationType? = nil) {

        let subtitle: NSAttributedString?
        if overrideSubtitle == nil {
            subtitle = self.subtitle(for: user)
        } else {
            subtitle = overrideSubtitle
        }

        self.user = user

        avatar.user = user
        updateTitleLabel(selfUser: selfUser)

        let style = UserTypeIconStyle(conversation: conversation, user: user, selfUser: selfUser)
        userTypeIconView.set(style: style)

        verifiedIconView.isHidden = !user.isVerified

        if let subtitle = subtitle, !subtitle.string.isEmpty, !hidesSubtitle {
            subtitleLabel.isHidden = false
            subtitleLabel.attributedText = subtitle
        } else {
            subtitleLabel.isHidden = true
        }
        setupAccessibility()
    }

}

// MARK: - Subtitle

extension UserCell: UserCellSubtitleProtocol {}

extension UserCell {

    func subtitle(for user: UserType) -> NSAttributedString? {
        if user.isServiceUser, let service = user as? SearchServiceUser {
            return subtitle(forServiceUser: service)
        } else {
            return subtitle(forRegularUser: user)
        }
    }

    private func subtitle(forServiceUser service: SearchServiceUser) -> NSAttributedString? {
        guard let summary = service.summary else { return nil }

        return summary && UserCell.boldFont.font!
    }

}

// MARK: - Availability

extension UserType {

    func nameIncludingAvailability(color: UIColor, selfUser: UserType) -> NSAttributedString? {
        if selfUser.isTeamMember {
            return AvailabilityStringBuilder.string(for: self, with: .list, color: color)
        } else if let name = name {
            return name && color
        } else {
            let fallbackTitle = L10n.Localizable.Profile.Details.Title.unavailable
            let fallbackColor = SemanticColors.Label.textCollectionSecondary
            return fallbackTitle && fallbackColor
        }
    }

}
