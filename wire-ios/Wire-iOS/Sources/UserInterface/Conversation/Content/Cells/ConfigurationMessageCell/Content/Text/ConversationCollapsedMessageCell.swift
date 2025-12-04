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

import WireAccountImageUI
import WireDesign
import WireFoundation
import WireSyncEngine

final class ConversationCollapsedMessageCell: UIView, ConversationMessageCell {

    struct Configuration: Equatable {
        var message: ZMConversationMessage
        let accentColor: AccentColor
        let collapseExpandAction: () -> Void

        static func == (lhs: Configuration, rhs: Configuration) -> Bool {
            lhs.message == rhs.message &&
                lhs.accentColor == rhs.accentColor
        }
    }

    var isSelected: Bool = false

    weak var message: ZMConversationMessage? {
        didSet {
            guard let message else { return }
            let isOwnMessage = message.isSentBySelfUser
            let userColor = message.senderUser?.accentColor ?? .clear
            container?.bubbleStyle = isOwnMessage ? .ownMessage(userColor: userColor) : .otherMessage
            configureTextColor(forOwnMessage: isOwnMessage)
        }
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    enum Constants {
        static let avatarSize: CGFloat = 24.0
        static let spacingBetweenAvatarAndText: CGFloat = 12
    }

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
        view.isUserInteractionEnabled = true
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.heightAnchor
            .constraint(equalToConstant: Constants.avatarSize).isActive = true
        view.widthAnchor.constraint(equalToConstant: Constants.avatarSize).isActive = true
        return view
    }()

    private lazy var availabilityIndicatorView = {
        let view = AvailabilityIndicatorView(availability: .away)
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

    private lazy var messageTextView: LinkInteractionTextView = {
        let view = LinkInteractionTextView()

        view.isEditable = false
        view.isSelectable = false
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.textContainerInset = UIEdgeInsets.zero
        view.textContainer.lineFragmentPadding = 0
        view.isUserInteractionEnabled = false
        view.dataDetectorTypes = []
        view.accessibilityIdentifier = "Message"
        view.accessibilityElementsHidden = false
        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentCompressionResistancePriority(.required, for: .vertical)

        view.textContainer.maximumNumberOfLines = 3
        view.isScrollEnabled = false
        view.textContainer.lineBreakMode = .byTruncatingTail

        return view
    }()

    private var container: ConversationMessageContainerView?

    private lazy var typeIcon: UIImageView = {
        let view = UIImageView(image: .init(resource: .file))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.isUserInteractionEnabled = false
        view.tintColor = ColorTheme.Backgrounds.onSurfaceVariant
        return view
    }()

    private lazy var collapseButton: UIButton = {
        let button = UIButton()
        let image = UIImage(resource: .collapse)
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = false
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.tintColor = SemanticColors.Label.baseSecondaryText
        return button
    }()

    private lazy var wholeViewTapButton = UIButton()

    private var userObservation: NSObjectProtocol?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with object: Configuration, animated: Bool) {
        messageTextView.text = nil
        messageTextView.attributedText = nil
        messageTextView.textColor = SemanticColors.Label.textDefault

        let user = object.message.senderUser
        avatar.user = user
        availabilityIndicatorView.availability = user?.availability.mapToAccountImageAvailability()

        if let session = ZMUserSession.shared(), let user {
            userObservation = UserChangeInfo.add(observer: self, for: user, in: session)
        }

        let message = object.message
        if message.isText, !message.hasLinks {
            typeIcon.isHidden = true
            if let textMessageData = message.textMessageData {
                messageTextView.attributedText = NSAttributedString
                    .format(
                        message: textMessageData,
                        isObfuscated: message.isObfuscated,
                        accentColor: object.accentColor
                    )
            }
        } else {
            var text = ""
            typeIcon.isHidden = false
            if message.isImage {
                typeIcon.image = .init(resource: .image)
                text = L10n.Localizable.Content.Collapsed.Image.title
            } else if message.isVideo {
                typeIcon.image = .init(resource: .play)
                text = L10n.Localizable.Content.Collapsed.Video.title
            } else if message.isAudio {
                typeIcon.image = .init(resource: .micOn)
                text = L10n.Localizable.Content.Collapsed.Audio.title
            } else if message.isLocation {
                typeIcon.image = .init(resource: .location)
                text = L10n.Localizable.Content.Collapsed.Location.title
            } else if message.isFile {
                typeIcon.image = .init(resource: .file)
                text = L10n.Localizable.Content.Collapsed.File.title
            } else if message.hasLinks {
                typeIcon.image = .init(resource: .link)
                text = L10n.Localizable.Content.Collapsed.Link.title
            }
            messageTextView.attributedText = text.attributedString &&
                UIFont.normalLightFont.italic && SemanticColors.Label.textDefault
        }

        wholeViewTapButton.removeTarget(nil, action: nil, for: .allEvents)
        let action = UIAction { _ in
            object.collapseExpandAction()
        }
        wholeViewTapButton.addAction(action, for: .touchUpInside)

        container?.isBubble = true
        configureTextColor(forOwnMessage: message.isSentBySelfUser)
    }

    private func configureSubviews() {

        let margins = conversationHorizontalMargins

        addSubview(wholeViewTapButton)
        wholeViewTapButton.pin(to: self)

        avatar.addSubview(availabilityIndicatorView)
        availabilityIndicatorView.trailingAnchor.constraint(
            equalTo: avatar.trailingAnchor,
            constant: 3
        ).isActive = true
        availabilityIndicatorView.bottomAnchor.constraint(
            equalTo: avatar.bottomAnchor,
            constant: 3
        ).isActive = true

        let spacingView = UIView()
        spacingView.widthAnchor
            .constraint(
                equalToConstant: margins.left - Constants.avatarSize - Constants.spacingBetweenAvatarAndText
            ).isActive = true

        let rightStack = [typeIcon, collapseButton.wrapInView(trailingInset: margins.right)]
            .horizontalStack(spacing: 8, alignment: .center)

        let avatarContainer = avatar.wrapInViewWithFlexibleTopAndBottom()

        let container = ConversationMessageContainerView(content: messageTextView)
        self.container = container
        container.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView.horizontal(
            views: [
                spacingView,
                avatarContainer,
                container,
                rightStack.wrapInViewWithFlexibleTopAndBottom()
            ],
            spacing: 7,
            alignment: .top
        )
        stack.setCustomSpacing(0, after: spacingView)
        stack.setCustomSpacing(Constants.spacingBetweenAvatarAndText, after: avatarContainer)
        stack.setCustomSpacing(10, after: container)

        rightStack.centerYAnchor
            .constraint(
                equalTo: messageTextView.firstBaselineAnchor,
                constant: -5
            ).isActive = true

        avatar.centerYAnchor
            .constraint(
                equalTo: messageTextView.firstBaselineAnchor,
                constant: -5
            ).isActive = true

        let stackWithTopMargin = stack.wrapInView(topInset: 8)
        addSubview(stackWithTopMargin)

        stackWithTopMargin
            .pin(to: self)
            .minHeightConstraint(30)
            .setIsUserInteractionEnabled(false)

        stack
            .setTranslatesAutoresizingMaskIntoConstraints(false)
            .setIsUserInteractionEnabled(false)

        typeIcon.constraintToSquare(sideLength: 16)
    }

    private func configureTextColor(forOwnMessage ownMessage: Bool) {
        let ownColor = SemanticColors.ChatBubble.foregroundOwnMessage
        let otherColor = SemanticColors.ChatBubble.foregroundOtherMessage
        messageTextView.textColor = ownMessage ? ownColor : otherColor
    }

    // MARK: - Tap gesture of avatar

    @objc
    func tappedOnAvatar() {
        guard let user = avatar.user else { return }

        SessionManager.shared?.showUserProfile(user: user)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let avatarPoint = convert(point, to: avatar)

        // Check if the tap is inside the avatar bounds
        if avatar.bounds.contains(avatarPoint) {
            // Return avatar to make it receive the tap
            return avatar
        }

        // Otherwise, let normal hit testing occur
        return super.hitTest(point, with: event)
    }
}

final class ConversationCollapsedMessageCellDescription: ConversationMessageCellDescription {

    typealias View = ConversationCollapsedMessageCell

    var configuration: View.Configuration

    let supportsActions: Bool = true
    let containsHighlightableContent: Bool = false

    weak var message: ZMConversationMessage? {
        didSet {
            if let message {
                configuration.message = message
            }
        }
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var accessibilityIdentifier: String? {
        "CollapsedFileCell"
    }

    let accessibilityLabel: String? = nil

    init(
        message: ConversationMessage,
        accentColor: AccentColor,
        collapseExpandAction: @escaping () -> Void
    ) {
        self.configuration = View.Configuration(
            message: message,
            accentColor: accentColor,
            collapseExpandAction: collapseExpandAction
        )
    }

}

extension ConversationCollapsedMessageCell: UserObserving {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        if changeInfo.availabilityChanged {
            availabilityIndicatorView.availability = changeInfo.user.availability.mapToAccountImageAvailability()
        }
    }
}
