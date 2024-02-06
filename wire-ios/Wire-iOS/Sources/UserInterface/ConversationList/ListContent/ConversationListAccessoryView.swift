//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

// MARK: - BadgeColorConfiguration

private struct BadgeColorConfiguration {
    var backgroundColor: UIColor
    var tintColor: UIColor
    var borderColor: UIColor?
    var borderWidth: CGFloat?
    var cornerRadius: CGFloat?
}

final class ConversationListAccessoryView: UIView {

    // MARK: - Properties

    typealias ViewColors = SemanticColors.View
    typealias LabelColors = SemanticColors.Label
    typealias IconColors = SemanticColors.Icon

    let mediaPlaybackManager: MediaPlaybackManager?

    let badgeView = RoundedBadge(view: UIView())
    let transparentIconView = UIImageView()
    let textLabel = UILabel()
    let iconView = UIImageView()
    var collapseWidthConstraint: NSLayoutConstraint!
    var expandWidthConstraint: NSLayoutConstraint!
    var expandTransparentIconViewWidthConstraint: NSLayoutConstraint!
    let defaultViewWidth: CGFloat = 28
    let activeCallWidth: CGFloat = 20

    let textLabelColor = LabelColors.textDefaultWhite

    var icon: ConversationStatusIcon? {
        didSet {
            if icon != oldValue {
                updateForIcon()
            }

            if icon == nil {
                accessibilityValue = nil
            }
        }
    }

    var activeMediaPlayer: MediaPlayer? {
        let mediaManager = mediaPlaybackManager ?? AppDelegate.shared.mediaPlaybackManager
        return mediaManager?.activeMediaPlayer
    }

    // MARK: - Init

    init(mediaPlaybackManager: MediaPlaybackManager? = nil) {
        self.mediaPlaybackManager = mediaPlaybackManager
        super.init(frame: .zero)

        badgeView.accessibilityIdentifier = "action_button"
        badgeView.isAccessibilityElement = false

        textLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        textLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .vertical)
        textLabel.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
        textLabel.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .vertical)
        textLabel.textAlignment = .center
        textLabel.font = FontSpec.mediumSemiboldFont.font!
        textLabel.textColor = LabelColors.textDefault
        textLabel.isAccessibilityElement = false
        transparentIconView.contentMode = .center
        transparentIconView.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
        transparentIconView.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .vertical)
        transparentIconView.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        transparentIconView.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .vertical)

        iconView.contentMode = .center
        iconView.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
        iconView.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .vertical)
        iconView.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        iconView.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .vertical)

        [badgeView, transparentIconView].forEach(addSubview)

        createConstraints()
        updateForIcon()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup Constraints

    private func createConstraints() {
        transparentIconView.translatesAutoresizingMaskIntoConstraints = false
        translatesAutoresizingMaskIntoConstraints = false

        let transparentIconViewLeading = transparentIconView.leadingAnchor.constraint(equalTo: leadingAnchor)
        transparentIconViewLeading.priority = UILayoutPriority(999.0)

        let transparentIconViewTrailing = transparentIconView.trailingAnchor.constraint(equalTo: trailingAnchor)
        transparentIconViewTrailing.priority = UILayoutPriority(999.0)

        expandTransparentIconViewWidthConstraint = transparentIconView.widthAnchor.constraint(greaterThanOrEqualToConstant: defaultViewWidth)

        expandWidthConstraint = widthAnchor.constraint(greaterThanOrEqualToConstant: defaultViewWidth)

        // collapseWidthConstraint is inactive when init, it is toggled in updateCollapseConstraints()
        collapseWidthConstraint = widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            badgeView.heightAnchor.constraint(equalToConstant: 20),
            transparentIconViewLeading,
            transparentIconViewTrailing,
            expandTransparentIconViewWidthConstraint,
            expandWidthConstraint,
            transparentIconView.topAnchor.constraint(equalTo: topAnchor),
            transparentIconView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        )
        badgeView.fitIn(view: self)
    }

    // MARK: - Color Configuration & Appearance

    /// Determines the color configuration for a specific `ConversationStatusIcon`.
    ///
    /// This method selects appropriate color settings (including background, tint, border, and corner radius) based on the icon's state.
    /// Default clear colors are used when no specific styling is needed. The method handles various states such as active calls, silenced status, and standard message notifications.
    ///
    /// - Parameter icon: An optional `ConversationStatusIcon` to determine the color scheme for. If `nil`, a default clear configuration is returned.
    /// - Returns: A `BadgeColorConfiguration` object representing the visual styling for the given icon.
    private func colorConfiguration(for icon: ConversationStatusIcon?) -> BadgeColorConfiguration {
        guard let icon = icon else {
            return BadgeColorConfiguration(backgroundColor: .clear, tintColor: .clear)
        }

        switch icon {
        case .pendingConnection, .missedCall, .playingMedia, .mention, .reply, .unreadPing, .unreadMessages:
            return BadgeColorConfiguration(
                backgroundColor: ViewColors.backgroundDefaultBlack,
                tintColor: IconColors.foregroundDefaultWhite
            )
        case .activeCall(true):
            return BadgeColorConfiguration(
                backgroundColor: IconColors.backgroundJoinCall,
                tintColor: .clear
            )
        case .silenced:
            return BadgeColorConfiguration(
                backgroundColor: ViewColors.backgroundDefaultWhite,
                tintColor: IconColors.foregroundDefaultBlack,
                borderColor: ViewColors.borderConversationListTableViewCellBadgeReverted,
                borderWidth: 1,
                cornerRadius: 6
            )
        case .activeCall(false), .typing:
            return BadgeColorConfiguration(
                backgroundColor: .clear,
                tintColor: .clear
            )

        }
    }

    /// Applies visual styling to the badge view based on the provided configuration.
    /// Sets background color, tint, border color, border width, and corner radius as specified in the `BadgeColorConfiguration`.
    ///
    /// - Parameter config: A `BadgeColorConfiguration` object containing the desired appearance settings for the badge view.
    private func applyBadgeViewAppearance(with config: BadgeColorConfiguration) {
        badgeView.backgroundColor = config.backgroundColor
        badgeView.tintColor = config.tintColor
        badgeView.layer.borderColor = config.borderColor?.cgColor
        badgeView.layer.borderWidth = config.borderWidth ?? 0
        badgeView.layer.cornerRadius = config.cornerRadius ?? 0
    }

    /// Updates the badge view's appearance based on the current icon.
    ///
    /// Retrieves the color configuration for the current `icon` and applies it to the badge view.
    /// This updates visual elements like background color, tint, border, and corner radius to reflect the icon's status.
    ///
    /// Note: Ensure the `icon` property is set before calling this method to reflect the correct appearance.
    private func updateColorConfiguration() {
        let colorConfig = colorConfiguration(for: icon)
        applyBadgeViewAppearance(with: colorConfig)
    }

    // MARK: - traitCollectionDidChange

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        updateColorConfiguration()
    }

    /// Set up the view based on the state
    private var viewForState: UIView? {
        guard let icon = self.icon else { return nil }

        let iconSize: StyleKitIcon.Size = 12

        // Configure the view based on the icon type
        switch icon {
        case .pendingConnection:
            iconView.setTemplateIcon(.clock, size: iconSize)
            return iconView
        case .activeCall(false):
            iconView.setTemplateIcon(.endCall, size: iconSize)
            return iconView
        case .activeCall(true):
            textLabel.text = L10n.Localizable.ConversationList.RightAccessory.JoinButton.title
            textLabel.textColor = textLabelColor
            return textLabel
        case .missedCall:
            iconView.setTemplateIcon(.endCall, size: iconSize)
            return iconView
        case .playingMedia:
            let isPlaying = activeMediaPlayer?.state == .playing
            iconView.setTemplateIcon(isPlaying ? .pause : .play, size: iconSize)
            return iconView
        case .silenced:
            iconView.setTemplateIcon(.bellWithStrikethrough, size: iconSize)
            return iconView
        case .typing:
            return nil
        case .unreadMessages(let count):
            textLabel.text = String(count)
            textLabel.textColor = textLabelColor
            return textLabel
        case .mention:
            iconView.setTemplateIcon(.mention, size: iconSize)
            return iconView
        case .reply:
            iconView.setTemplateIcon(.reply, size: iconSize)
            return iconView
        case .unreadPing:
            iconView.setTemplateIcon(.ping, size: iconSize)
            return iconView
        }
    }

    func updateCollapseConstraints(isCollapsed: Bool) {
        if isCollapsed {
            badgeView.updateCollapseConstraints(isCollapsed: isCollapsed)
            expandWidthConstraint.isActive = false
            expandTransparentIconViewWidthConstraint.isActive = false
            collapseWidthConstraint.isActive = true
        } else {
            collapseWidthConstraint.isActive = false
            expandWidthConstraint.isActive = true
            expandTransparentIconViewWidthConstraint.isActive = true
            badgeView.updateCollapseConstraints(isCollapsed: isCollapsed)
        }
    }

    func updateForIcon() {
        badgeView.containedView.subviews.forEach { $0.removeFromSuperview() }

        badgeView.isHidden = false
        transparentIconView.isHidden = true
        expandTransparentIconViewWidthConstraint.constant = defaultViewWidth
        expandWidthConstraint.constant = defaultViewWidth

        guard let icon = icon else {
            badgeView.isHidden = true
            transparentIconView.isHidden = true
            updateCollapseConstraints(isCollapsed: true)
            configureAccessibility(for: nil)
            return
        }

        let colorConfig = colorConfiguration(for: icon)
        applyBadgeViewAppearance(with: colorConfig)

        configureAccessibility(for: icon)

        if let view = viewForState {
            badgeView.containedView.addSubview(view)
            setupContainedViewConstraints(for: view)
        }

        switch icon {
        case .activeCall(false):
            configureForInactiveCall()
        case .typing:
            configureForTyping()
        default:
            transparentIconView.image = .none
        }

        updateCollapseConstraints(isCollapsed: false)
    }

    private func configureForInactiveCall() {
        badgeView.isHidden = true
        transparentIconView.isHidden = false
        transparentIconView.setIcon(.phone, size: 18, color: IconColors.foregroundDefaultBlack)
        expandTransparentIconViewWidthConstraint.constant = activeCallWidth
        expandWidthConstraint.constant = activeCallWidth
    }

    private func configureForTyping() {
        badgeView.isHidden = true
        transparentIconView.isHidden = false
        transparentIconView.setIcon(.pencil, size: 12, color: IconColors.foregroundDefaultBlack)
        transparentIconView.tintColor = IconColors.foregroundDefaultBlack
    }

    private func setupContainedViewConstraints(for view: UIView) {
        let parentView = badgeView.containedView
        view.translatesAutoresizingMaskIntoConstraints = false
        parentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: parentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 6),
            view.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -6)
        ])
    }

    /// Configures accessibility settings for the badge view based on the current icon.
    /// Sets appropriate accessibility values, hints, and traits depending on the icon type to enhance accessibility support.
    ///
    /// - Parameter icon: An optional `ConversationStatusIcon` used to determine the accessibility configuration.
    private func configureAccessibility(for icon: ConversationStatusIcon?) {

        typealias ConversationsListAccessibility = L10n.Accessibility.ConversationsList
        typealias ConversationListVoiceOver = L10n.Localizable.ConversationList.Voiceover.Status

        switch icon {
        case .pendingConnection:
            accessibilityValue = ConversationListVoiceOver.pendingConnection
        case .activeCall(false):
            accessibilityValue = ConversationListVoiceOver.activeCall
        case .activeCall(true):
            badgeView.accessibilityTraits = .button
            badgeView.accessibilityValue = ConversationsListAccessibility.JoinButton.description
            badgeView.accessibilityHint = ConversationsListAccessibility.JoinButton.hint
        case .playingMedia:
            if let mediaPlayer = activeMediaPlayer, mediaPlayer.state == .playing {
                accessibilityValue = ConversationListVoiceOver.pauseMedia
            } else {
                accessibilityValue = ConversationListVoiceOver.playMedia
            }
        case .silenced:
            accessibilityValue = ConversationsListAccessibility.SilencedStatus.value
        case .unreadMessages(let count):
            accessibilityValue = ConversationsListAccessibility.BadgeView.value(count)
        case .mention:
            accessibilityValue = ConversationsListAccessibility.MentionStatus.value
        case .reply:
            accessibilityValue = ConversationsListAccessibility.ReplyStatus.value
        case .none, .typing, .unreadPing:
            accessibilityValue = nil
        case .some(.missedCall):
            accessibilityValue = nil
        }
    }

}
