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

final class ConversationListAccessoryView: UIView {
    // MARK: Lifecycle

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

    // MARK: Internal

    // MARK: - Properties

    typealias ViewColors = SemanticColors.View
    typealias LabelColors = SemanticColors.Label
    typealias IconColors = SemanticColors.Icon
    typealias ConversationsListAccessibility = L10n.Accessibility.ConversationsList

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

    let iconSize: StyleKitIcon.Size = 12

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

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else {
            return
        }
        // We need to call this method here because the background, the border color
        // of the icon when switching from dark to light mode
        // or vice versa can be updated only inside traitCollectionDidChange.
        updateForIcon()
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

        guard let icon else {
            badgeView.isHidden = true
            transparentIconView.isHidden = true

            updateCollapseConstraints(isCollapsed: true)
            return
        }

        switch icon {
        case .activeCall(false):
            badgeView.isHidden = true
            transparentIconView.isHidden = false
            transparentIconView.setTemplateIcon(.phone, size: iconSize)
            transparentIconView.tintColor = IconColors.foregroundDefaultBlack

            expandTransparentIconViewWidthConstraint.constant = activeCallWidth
            expandWidthConstraint.constant = activeCallWidth

        case .activeCall(true): // "Join" button
            badgeView.backgroundColor = IconColors.backgroundJoinCall

        case .typing:
            badgeView.isHidden = true
            transparentIconView.isHidden = false
            transparentIconView.setTemplateIcon(.pencil, size: iconSize)
            transparentIconView.tintColor = IconColors.foregroundDefaultBlack

        case .mention, .unreadMessages:
            textLabel.textColor = textLabelColor
            badgeView.backgroundColor = ViewColors.backgroundDefaultBlack

        case .missedCall, .reply, .unreadPing:
            badgeView.backgroundColor = ViewColors.backgroundDefaultBlack

        default:
            transparentIconView.image = .none
        }

        updateCollapseConstraints(isCollapsed: false)

        if let view = viewForState {
            badgeView.containedView.addSubview(view)

            let parentView = badgeView.containedView
            view.translatesAutoresizingMaskIntoConstraints = false
            parentView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: parentView.topAnchor),
                view.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
                view.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 6),
                view.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -6),
            ])
        }
    }

    // MARK: Private

    // MARK: - Set up the view based on the state

    private var viewForState: UIView? {
        typealias ConversationListVoiceOver = L10n.Localizable.ConversationList.Voiceover.Status

        guard let icon else {
            return nil
        }
        badgeView.backgroundColor = ViewColors.backgroundDefaultBlack
        let iconTintColor = IconColors.foregroundDefaultWhite

        switch icon {
        case .pendingConnection:
            iconView.setTemplateIcon(.clock, size: iconSize)
            iconView.tintColor = iconTintColor
            accessibilityValue = ConversationListVoiceOver.pendingConnection
            return iconView

        case .activeCall(false):
            accessibilityValue = ConversationListVoiceOver.activeCall
            return .none

        case .activeCall(true):
            textLabel.text = L10n.Localizable.ConversationList.RightAccessory.JoinButton.title
            textLabel.textColor = textLabelColor
            badgeView.backgroundColor = IconColors.backgroundJoinCall

            badgeView.isAccessibilityElement = true
            badgeView.accessibilityTraits = .button
            badgeView.accessibilityValue = ConversationsListAccessibility.JoinButton.description
            badgeView.accessibilityHint = ConversationsListAccessibility.JoinButton.hint
            return textLabel

        case .missedCall:
            iconView.setTemplateIcon(.endCall, size: iconSize)
            iconView.tintColor = iconTintColor
            return iconView

        case .playingMedia:
            if let mediaPlayer = activeMediaPlayer, mediaPlayer.state == .playing {
                iconView.setTemplateIcon(.pause, size: iconSize)
                iconView.tintColor = iconTintColor
                accessibilityValue = ConversationListVoiceOver.pauseMedia
            } else {
                iconView.setTemplateIcon(.play, size: iconSize)
                iconView.tintColor = iconTintColor
                accessibilityValue = ConversationListVoiceOver.playMedia
            }
            return iconView

        case .silenced:
            configureSilencedNotificationsIcon()
            return iconView

        case .typing:
            return .none

        case let .unreadMessages(count):
            textLabel.text = String(count)
            textLabel.textColor = textLabelColor
            accessibilityValue = ConversationsListAccessibility.BadgeView.value(count)
            return textLabel

        case .mention:
            iconView.setTemplateIcon(.mention, size: iconSize)
            iconView.tintColor = iconTintColor
            accessibilityValue = ConversationsListAccessibility.MentionStatus.value
            return iconView

        case .reply:
            iconView.setTemplateIcon(.reply, size: iconSize)
            iconView.tintColor = iconTintColor
            accessibilityValue = ConversationsListAccessibility.ReplyStatus.value
            return iconView

        case .unreadPing:
            iconView.setTemplateIcon(.ping, size: iconSize)
            iconView.tintColor = iconTintColor
            return iconView
        }
    }

    // MARK: - Setup Constraints

    private func createConstraints() {
        transparentIconView.translatesAutoresizingMaskIntoConstraints = false
        translatesAutoresizingMaskIntoConstraints = false

        let transparentIconViewLeading = transparentIconView.leadingAnchor.constraint(equalTo: leadingAnchor)
        transparentIconViewLeading.priority = UILayoutPriority(999.0)

        let transparentIconViewTrailing = transparentIconView.trailingAnchor.constraint(equalTo: trailingAnchor)
        transparentIconViewTrailing.priority = UILayoutPriority(999.0)

        expandTransparentIconViewWidthConstraint = transparentIconView.widthAnchor
            .constraint(greaterThanOrEqualToConstant: defaultViewWidth)

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
            transparentIconView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        badgeView.fitIn(view: self)
    }

    private func configureSilencedNotificationsIcon() {
        iconView.setTemplateIcon(.bellWithStrikethrough, size: iconSize)
        iconView.tintColor = IconColors.foregroundDefaultBlack
        badgeView.backgroundColor = ViewColors.backgroundDefaultWhite
        badgeView.layer.borderColor = IconColors.borderMutedNotifications.cgColor
        badgeView.layer.borderWidth = 1
        badgeView.layer.cornerRadius = 6
        accessibilityValue = ConversationsListAccessibility.SilencedStatus.value
    }
}
