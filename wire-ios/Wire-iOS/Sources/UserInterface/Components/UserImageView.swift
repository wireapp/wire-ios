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

import WireSyncEngine

/// A view that displays the avatar for a remote user.
class UserImageView: AvatarImageView, UserObserving {
    // MARK: - Interface Properties

    /// The size of the avatar.
    var size: Size {
        didSet { updateUserImage() }
    }

    /// Whether the image should be desaturated, e.g. for unconnected users.
    var shouldDesaturate = true {
        didSet { updateUserImage() }
    }

    /// Whether the badge indicator is enabled.
    var indicatorEnabled = false {
        didSet { badgeIndicator.isHidden = !indicatorEnabled }
    }

    private let badgeIndicator = RoundedView()

    // MARK: - Remote User

    /// The user session to use to download images.
    var userSession: UserSession? {
        didSet { updateUser() }
    }

    /// The user to display the avatar of.
    var user: UserType? {
        didSet { updateUser() }
    }

    private var userObserverToken: NSObjectProtocol?

    // MARK: - Initialization

    override init(frame: CGRect) {
        self.size = .small
        super.init(frame: .zero)
        configureSubviews()
        configureConstraints()
    }

    init(size: Size = .small) {
        self.size = size
        super.init(frame: .zero)
        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: CGSize {
        .init(width: size.rawValue, height: size.rawValue)
    }

    private func configureSubviews() {
        accessibilityElementsHidden = true

        badgeIndicator.backgroundColor = .red
        badgeIndicator.isHidden = true
        badgeIndicator.shape = .circle
        addSubview(badgeIndicator)
    }

    private func configureConstraints() {
        badgeIndicator.translatesAutoresizingMaskIntoConstraints = false

        setContentHuggingPriority(.required, for: .vertical)
        setContentHuggingPriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            badgeIndicator.topAnchor.constraint(equalTo: topAnchor),
            badgeIndicator.trailingAnchor.constraint(equalTo: trailingAnchor),
            badgeIndicator.heightAnchor.constraint(equalTo: badgeIndicator.widthAnchor),
            badgeIndicator.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1 / 3),
        ])
    }

    // MARK: - Interface

    /// Returns the appropriate border width for the user.
    private func borderWidth(for user: UserType) -> CGFloat {
        user.isServiceUser ? 0.5 : 0
    }

    /// Returns the appropriate border color for the user.
    private func borderColor(for user: UserType) -> CGColor? {
        user.isServiceUser ? UIColor.black.withAlphaComponent(0.08).cgColor : nil
    }

    /// Returns the placeholder background color for the user.
    private func containerBackgroundColor(for user: UserType) -> UIColor {
        switch avatar {
        case .image:
            user.isServiceUser ? .white : .clear
        case .text:
            if user.isConnected || user.isSelfUser || user.isTeamMember || user.isWirelessUser {
                user.accentColor
            } else {
                .init(white: 0.8, alpha: 1)
            }
        }
    }

    /// Returns the appropriate avatar shape for the user.
    private func shape(for user: UserType) -> AvatarImageView.Shape {
        user.isServiceUser ? .relative : .circle
    }

    // MARK: - Changing the Content

    /// Sets the avatar for the user with an optional animation.
    /// - parameter avatar: The avatar of the user.
    /// - parameter user: The currently displayed user.
    /// - parameter animated: Whether to animate the change.
    func setAvatar(_ avatar: Avatar, user: UserType, animated: Bool) {
        let updateBlock = {
            self.avatar = avatar
            self.container.backgroundColor = self.containerBackgroundColor(for: user)
        }

        if animated, !ProcessInfo.processInfo.isRunningTests {
            UIView.transition(
                with: self,
                duration: 0.15,
                options: .transitionCrossDissolve,
                animations: updateBlock,
                completion: nil
            )
        } else {
            updateBlock()
        }
    }

    /// Updates the image for the user.
    fileprivate func updateUserImage() {
        guard
            let user,
            let userSession
        else {
            return
        }

        var desaturate = false
        if shouldDesaturate {
            desaturate = !user.isConnected && !user.isSelfUser && !user.isTeamMember && !user.isServiceUser
        }

        user.fetchProfileImage(
            session: userSession,
            imageCache: UIImage.defaultUserImageCache,
            sizeLimit: size.rawValue,
            isDesaturated: desaturate
        ) { [weak self] image, cacheHit in
            // Don't set image if nil or if user has changed during fetch
            guard let image, user.isEqual(self?.user) else { return }
            self?.setAvatar(.image(image), user: user, animated: !cacheHit)
        }
    }

    // MARK: - Updates

    func userDidChange(_ changeInfo: UserChangeInfo) {
        // Check for potential image changes
        if size == .big {
            if changeInfo.imageMediumDataChanged || changeInfo.connectionStateChanged {
                updateUserImage()
            }
        } else {
            if changeInfo.imageSmallProfileDataChanged || changeInfo.connectionStateChanged || changeInfo.teamsChanged {
                updateUserImage()
            }
        }

        // Change for accent color changes
        if changeInfo.accentColorValueChanged {
            updateIndicatorColor()
        }
    }

    /// Called when the user or user session changes.
    func updateUser() {
        guard let user = self.user, let initials = user.initials else {
            return
        }

        let defaultAvatar: Avatar = initials.isEmpty ? .init() : .text(initials.localizedUppercase)
        setAvatar(defaultAvatar, user: user, animated: false)
        if !ProcessInfo.processInfo.isRunningTests,
           let userSession = userSession as? ZMUserSession {
            userObserverToken = UserChangeInfo.add(observer: self, for: user, in: userSession)
        }

        updateForServiceUserIfNeeded(user)
        updateIndicatorColor()
        updateUserImage()
    }

    /// Updates the color of the badge indicator.
    private func updateIndicatorColor() {
        badgeIndicator.backgroundColor = user?.accentColor
    }

    /// Updates the interface to reflect if the user is a service user or not.
    private func updateForServiceUserIfNeeded(_ user: UserType) {
        let oldValue = shape
        shape = shape(for: user)
        if oldValue != shape {
            container.layer.borderColor = borderColor(for: user)
            container.layer.borderWidth = borderWidth(for: user)
            container.backgroundColor = containerBackgroundColor(for: user)
        }
    }

    // MARK: - Nested Types

    /// The different sizes for the avatar image.
    enum Size: Int {
        case tiny = 16
        case badge = 24
        case small = 32
        case normal = 64
        case big = 320
    }
}
