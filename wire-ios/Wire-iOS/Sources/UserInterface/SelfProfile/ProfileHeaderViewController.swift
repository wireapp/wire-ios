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

final class ProfileHeaderViewController: UIViewController {

    /// The options to customize the appearance and behavior of the view.
    private let options: Options

    /// Associated conversation, if displayed in the context of a conversation
    private let conversation: ZMConversation?

    /// The user that is displayed.
    private let user: UserType

    private var userStatus: UserStatus {
        didSet { applyUserStatus() }
    }

    private let userSession: UserSession
    private let isUserE2EICertifiedUseCase: IsUserE2EICertifiedUseCaseProtocol
    private let isSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol

    /// The user who is viewing this view
    private let viewer: UserType

    /// The current group admin status.
    var isAdminRole: Bool {
        didSet { groupRoleIndicator.isHidden = !isAdminRole }
    }

    private var stackView: CustomSpacingStackView!

    typealias AccountPageStrings = L10n.Accessibility.AccountPage
    typealias LabelColors = SemanticColors.Label

    private let nameLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(style: .h2, color: LabelColors.textDefault)
        label.accessibilityLabel = AccountPageStrings.Name.description
        label.accessibilityIdentifier = "name"

        label.accessibilityTraits.insert(.header)
        label.lineBreakMode = .byTruncatingMiddle
        label.numberOfLines = 2
        label.textAlignment = .center

        return label
    }()

    private let qrCodeButton = {
        let button = IconButton()
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true

        let boldConfig = UIImage.SymbolConfiguration(weight: .black)
        let boldImage = UIImage(systemName: "qrcode", withConfiguration: boldConfig)
        button.setImage(boldImage, for: .normal)

        button.accessibilityIdentifier = "QR code button"
        button.accessibilityLabel = L10n.Accessibility.Profile.ShareProfileButton.description

        return button
    }()

    private let handleLabel = DynamicFontLabel(style: .subline1, color: LabelColors.textDefault)
    private let teamNameLabel = DynamicFontLabel(style: .h4, color: LabelColors.textDefault)
    private let remainingTimeLabel = DynamicFontLabel(style: .h5, color: LabelColors.textDefault)
    let imageView = UserImageView(size: .big)
    private let userStatusViewController: UserStatusViewController

    private let guestIndicatorStack = UIStackView()
    private let groupRoleIndicator = LabelIndicator(context: .groupRole)

    private let guestIndicator = LabelIndicator(context: .guest)
    private let externalIndicator = LabelIndicator(context: .external)
    private let federatedIndicator = LabelIndicator(context: .federated)
    private let warningView = WarningLabelView()

    private var userObserver: NSObjectProtocol?
    private var teamObserver: NSObjectProtocol?

    /// Creates a profile view for the specified user and options.
    /// - parameter user: The user to display the profile of.
    /// - parameter conversation: The conversation.
    /// - parameter options: The options for the appearance and behavior of the view.
    /// - parameter userSession: The user session.
    /// - parameter isUserE2EICertifiedUseCase: Use case for getting the user's MLS verification status.
    /// - parameter isSelfUserE2EICertifiedUseCase: Use case for getting the self user's MLS verification status, if `user.isSelfUser` is `true`.
    /// Note: You can change the options later through the `options` property.
    init(
        user: UserType,
        viewer: UserType,
        conversation: ZMConversation?,
        options: Options,
        userSession: UserSession,
        isUserE2EICertifiedUseCase: IsUserE2EICertifiedUseCaseProtocol,
        isSelfUserE2EICertifiedUseCase: IsSelfUserE2EICertifiedUseCaseProtocol
    ) {
        userStatus = .init(user: user, isE2EICertified: false)
        self.user = user
        self.userSession = userSession
        self.isUserE2EICertifiedUseCase = isUserE2EICertifiedUseCase
        self.isSelfUserE2EICertifiedUseCase = isSelfUserE2EICertifiedUseCase
        isAdminRole = conversation.map(self.user.isGroupAdmin) ?? false
        self.viewer = viewer
        self.conversation = conversation
        self.options = options
        userStatusViewController = .init(
            options: options.contains(.allowEditingAvailability) ? [.allowSettingStatus] : [.hideActionHint],
            settings: .shared
        )
        super.init(nibName: nil, bundle: nil)
        userStatusViewController.delegate = self
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        imageView.isAccessibilityElement = true
        imageView.accessibilityElementsHidden = false
        imageView.accessibilityIdentifier = "user image"
        imageView.setImageConstraint(resistance: 249, hugging: 750)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        imageView.initialsFont = .systemFont(ofSize: 55, weight: .semibold).monospaced()
        imageView.userSession = userSession
        imageView.user = user

        if !ProcessInfo.processInfo.isRunningTests, let session = userSession as? ZMUserSession {
            userObserver = UserChangeInfo.add(observer: self, for: user, in: session)
        }

        handleLabel.accessibilityLabel = AccountPageStrings.Handle.description
        handleLabel.accessibilityIdentifier = "username"
        handleLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        handleLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)

        let nameHandleStack = UIStackView(arrangedSubviews: [nameLabel, handleLabel])
        nameHandleStack.axis = .vertical
        nameHandleStack.alignment = .center
        nameHandleStack.spacing = 8

        teamNameLabel.accessibilityLabel = AccountPageStrings.TeamName.description
        teamNameLabel.numberOfLines = 0
        teamNameLabel.textAlignment = .center
        teamNameLabel.accessibilityIdentifier = "team name"
        teamNameLabel.setContentHuggingPriority(UILayoutPriority.required, for: .vertical)
        teamNameLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)

        let remainingTimeString = user.expirationDisplayString
        remainingTimeLabel.text = remainingTimeString
        remainingTimeLabel.isHidden = remainingTimeString == nil

        guestIndicatorStack.addArrangedSubview(guestIndicator)
        guestIndicatorStack.addArrangedSubview(remainingTimeLabel)
        guestIndicatorStack.spacing = 12
        guestIndicatorStack.axis = .vertical
        guestIndicatorStack.alignment = .center

        updateGuestIndicator()
        updateExternalIndicator()
        updateFederatedIndicator()
        updateGroupRoleIndicator()
        updateHandleLabel()
        updateTeamLabel()
        updateQRCodeButton()

        addChild(userStatusViewController)

        stackView = CustomSpacingStackView(
            customSpacedArrangedSubviews: [
                nameHandleStack,
                teamNameLabel,
                imageView,
                userStatusViewController.view,
                guestIndicatorStack,
                externalIndicator,
                federatedIndicator,
                groupRoleIndicator,
                warningView
            ]
        )

        stackView.alignment = .center
        stackView.axis = .vertical

        stackView.wr_addCustomSpacing(32, after: nameHandleStack)
        stackView.wr_addCustomSpacing(32, after: teamNameLabel)
        stackView.wr_addCustomSpacing(24, after: imageView)
        stackView.wr_addCustomSpacing(20, after: guestIndicatorStack)
        stackView.wr_addCustomSpacing(20, after: externalIndicator)
        stackView.wr_addCustomSpacing(20, after: federatedIndicator)

        view.addSubview(stackView)
        view.addSubview(qrCodeButton)

        guestIndicator.tintColor = SemanticColors.Icon.foregroundDefault
        view.backgroundColor = UIColor.clear

        configureConstraints()
        applyUserStatus()
        applyOptions()

        userStatusViewController.didMove(toParent: self)

        if let team = user.membership?.team {
            teamObserver = TeamChangeInfo.add(observer: self, for: team)
        }
        view.backgroundColor = .clear
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateE2EICertifiedStatus()
    }

    private func configureConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        qrCodeButton.translatesAutoresizingMaskIntoConstraints = false

        let leadingSpaceConstraint = stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 56)
        let topSpaceConstraint = stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20)
        let trailingSpaceConstraint = stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -56)
        let bottomSpaceConstraint = stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)

        let widthImageConstraint = imageView.widthAnchor.constraint(lessThanOrEqualToConstant: 164)
        NSLayoutConstraint.activate([
            // stackView
            widthImageConstraint, leadingSpaceConstraint, topSpaceConstraint, trailingSpaceConstraint, bottomSpaceConstraint,
            qrCodeButton.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            qrCodeButton.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            qrCodeButton.heightAnchor.constraint(equalToConstant: 32),
            qrCodeButton.widthAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func applyUserStatus() {
        nameLabel.attributedText = combineUserNameWithIcons()
        userStatusViewController.userStatus = userStatus
    }

    private func combineUserNameWithIcons() -> NSAttributedString {
        var userNameWithIcons: [NSAttributedString] = []

        let userName = NSAttributedString(string: userStatus.name)
        userNameWithIcons.append(userName)

        if userStatus.isProteusVerified {
            let verifiedShieldAttachment = NSTextAttachment()
            verifiedShieldAttachment.image = UIImage.init(resource: .verifiedShield)
            let verifiedShieldIconString = NSAttributedString(attachment: verifiedShieldAttachment)

            userNameWithIcons.append(verifiedShieldIconString)
        }

        if userStatus.isE2EICertified {
            let certificateValidAttachment = NSTextAttachment()
            certificateValidAttachment.image = UIImage.init(resource: .certificateValid)
            let certificateValidIconString = NSAttributedString(attachment: certificateValidAttachment)

            userNameWithIcons.append(certificateValidIconString)
        }

        return userNameWithIcons.joined(separator: NSAttributedString(string: " "))
    }

    private func updateGuestIndicator() {
        if let conversation {
            guestIndicatorStack.isHidden = !user.isGuest(in: conversation)
        } else {
            guestIndicatorStack.isHidden = !viewer.isTeamMember || viewer.canAccessCompanyInformation(of: user)
        }
    }

    private func updateExternalIndicator() {
        externalIndicator.isHidden = !user.isExternalPartner
    }

    private func updateFederatedIndicator() {
        federatedIndicator.isHidden = !user.isFederated
    }

    private func updateGroupRoleIndicator() {
        let groupRoleIndicatorHidden: Bool
        switch conversation?.conversationType {
        case .group?:
            groupRoleIndicatorHidden = !(conversation.map(user.isGroupAdmin) ?? false)
        default:
            groupRoleIndicatorHidden = true
        }
        groupRoleIndicator.isHidden = groupRoleIndicatorHidden

    }

    private func applyOptions() {
        updateHandleLabel()
        updateTeamLabel()
        updateImageButton()
        updateAvailabilityVisibility()
        warningView.update(withUser: user)
    }

    private func updateHandleLabel() {
        if let handle = user.handle, !handle.isEmpty {
            handleLabel.text = "@" + handle
            handleLabel.accessibilityValue = handleLabel.text
        } else {
            handleLabel.isHidden = true
        }
    }

    private func updateTeamLabel() {
        if let teamName = user.teamName, !options.contains(.hideTeamName) {
            teamNameLabel.text = teamName
            teamNameLabel.accessibilityValue = teamNameLabel.text
            teamNameLabel.isHidden = false
        } else {
            teamNameLabel.isHidden = true
        }
    }

    private func updateAvailabilityVisibility() {
        let isHidden = options.contains(.hideAvailability) || !options.contains(.allowEditingAvailability) && user.availability == .none
        userStatusViewController.view?.isHidden = isHidden
    }

    private func updateImageButton() {
        if options.contains(.allowEditingProfilePicture) {
            imageView.accessibilityLabel = AccountPageStrings.ProfilePicture.description
            imageView.accessibilityHint = AccountPageStrings.ProfilePicture.hint
            imageView.accessibilityTraits = .button
            imageView.isUserInteractionEnabled = true
        } else {
            imageView.accessibilityLabel = AccountPageStrings.ProfilePicture.description
            imageView.accessibilityTraits = [.image]
            imageView.isUserInteractionEnabled = false
        }
    }

    private func updateE2EICertifiedStatus() {
        guard let user = user as? ZMUser else { return }

        Task { @MainActor [conversation] in
            do {
                userStatus.isE2EICertified = if let conversation {
                    try await isUserE2EICertifiedUseCase.invoke(conversation: conversation, user: user)
                } else if user.isSelfUser {
                    try await isSelfUserE2EICertifiedUseCase.invoke()
                } else {
                    false
                }
            } catch {
                WireLogger.e2ei.error("failed to get E2EI certification status: \(error)")
            }
        }
    }

    private func updateQRCodeButton() {
        let qrCodeAction = UIAction { _ in }
        qrCodeButton.addAction(qrCodeAction, for: .touchUpInside)
        qrCodeButton.isHidden = !user.isSelfUser
        updateColors()
    }

    private func updateColors() {
        qrCodeButton.setBorderColor(ColorTheme.Strokes.outline, for: .normal)
        qrCodeButton.setBackgroundImageColor(ColorTheme.Backgrounds.surfaceVariant, for: .normal)
        qrCodeButton.setIconColor(ColorTheme.Buttons.Secondary.onEnabled, for: .normal)

        qrCodeButton.setBorderColor(ColorTheme.Strokes.outline, for: .highlighted)
        qrCodeButton.setBackgroundImageColor(ColorTheme.Backgrounds.background, for: .highlighted)
    }

    // MARK: -

    /// The options to customize the appearance and behavior of the view.
    struct Options: OptionSet {

        let rawValue: Int

        /// Whether to hide the availability status of the user.
        static let hideAvailability = Options(rawValue: 1 << 2)

        /// Whether to hide the team name of the user.
        static let hideTeamName = Options(rawValue: 1 << 3)

        /// Whether to allow the user to change their availability.
        static let allowEditingAvailability = Options(rawValue: 1 << 4)

        /// Whether to allow the user to change their availability.
        static let allowEditingProfilePicture = Options(rawValue: 1 << 5)

    }
}

// MARK: - UserStatusViewControllerDelegate

extension ProfileHeaderViewController: UserStatusViewControllerDelegate {

    func userStatusViewController(_ viewController: UserStatusViewController, didSelect availability: Availability) {
        guard viewController === userStatusViewController else { return }

        userSession.perform { [weak self] in
            self?.user.availability = availability
        }
    }
}

// MARK: - ZMUserObserving

extension ProfileHeaderViewController: UserObserving {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        if changeInfo.nameChanged {
            userStatus.name = changeInfo.user.name ?? ""
        }
        if changeInfo.handleChanged {
            updateHandleLabel()
        }
        if changeInfo.availabilityChanged {
            updateAvailabilityVisibility()
            userStatus.availability = changeInfo.user.availability
        }
        if changeInfo.trustLevelChanged {
            userStatus.isProteusVerified = changeInfo.user.isVerified
            updateE2EICertifiedStatus()
        }
    }
}

// MARK: - TeamObserver

extension ProfileHeaderViewController: TeamObserver {

    func teamDidChange(_ changeInfo: TeamChangeInfo) {
        if changeInfo.nameChanged {
            updateTeamLabel()
        }
    }
}

// MARK: - TraitCollectionDidChange

extension ProfileHeaderViewController {

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        updateColors()
    }

}
