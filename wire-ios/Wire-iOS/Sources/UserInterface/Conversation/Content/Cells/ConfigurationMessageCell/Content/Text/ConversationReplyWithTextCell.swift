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
import WireDesign
import WireFoundation
import WireLocators
import WireMessagingDomain
import WireSyncEngine

/// A single-cell view that renders a quoted reply and the replying message text
/// as one unified bubble, avoiding any visual seam between the two parts.
final class ConversationReplyWithTextCell: UIView, ConversationMessageCell, TextViewInteractionDelegate {

    // MARK: - Configuration

    struct Configuration: Equatable {
        var quotedMessage: ZMConversationMessage?
        let accentColor: AccentColor
        let messageReplyAttachmentsViewModel: MessageReplyAttachmentsViewModel?
        let attributedText: NSAttributedString
        let isObfuscated: Bool
        let userSession: UserSession?
        var isSentBySelfUser: Bool = false
        var senderAccentColor: WireAccentColor = .default
        var quotedMessageWasDeleted: Bool = false

        static func == (lhs: Configuration, rhs: Configuration) -> Bool {
            lhs.accentColor == rhs.accentColor
                && lhs.quotedMessage == rhs.quotedMessage
                && lhs.isSentBySelfUser == rhs.isSentBySelfUser
                && lhs.isObfuscated == rhs.isObfuscated
                && lhs.quotedMessageWasDeleted == rhs.quotedMessageWasDeleted
                && lhs.attributedText.isEqual(to: rhs.attributedText)
        }
    }

    // MARK: - Subviews

    private let replyContentView = ConversationReplyContentView()

    /// Wraps the reply content view and the left-side accent bar.
    /// Keeps its own corner radius and border so it looks like an inset nested element.
    private lazy var replyContainer: ReplyRoundCornersView = {
        let view = ReplyRoundCornersView(containedView: replyContentView)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var messageTextView: LinkInteractionTextView = {
        let view = LinkInteractionTextView.withBlockquoteBars()
        view.isEditable = false
        view.isSelectable = true
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.isUserInteractionEnabled = true
        view.accessibilityIdentifier = "Message"
        view.accessibilityElementsHidden = false
        view.dataDetectorTypes = [.link, .address, .phoneNumber]
        view.linkTextAttributes = [.foregroundColor: UIColor.accent()]
        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.interactionDelegate = self
        view.textDragInteraction?.isEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Properties

    var isSelected = false

    weak var message: ZMConversationMessage? {
        didSet {
            guard let message else { return }
            let isOwn = message.isSentBySelfUser
            let accentColor = message.senderUser?.wireAccentColor ?? .default
            applyStyle(isSentBySelfUser: isOwn, accentColor: accentColor)
            configureTextColor(forOwnMessage: isOwn)
        }
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?
    private var accentColorChangeHandler: AccentColorChangeHandler?

    var selectionView: UIView? { self }

    var selectionRect: CGRect {
        messageTextView.layoutManager.usedRect(for: messageTextView.textContainer)
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        layer.cornerRadius = ConversationMessageContainerView.bubbleCornerRadius
        layer.masksToBounds = true

        replyContainer.addTarget(self, action: #selector(onReplyTap), for: .touchUpInside)

        addSubview(replyContainer)
        addSubview(messageTextView)

        setupConstraints()
    }

    private func setupConstraints() {
        let insets = ConversationMessageContainerView.bubbleEdgeInsets
        let replyInset: CGFloat = 8

        NSLayoutConstraint.activate([
            // Reply container is inset from the outer bubble edges
            replyContainer.topAnchor.constraint(equalTo: topAnchor, constant: replyInset),
            replyContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: replyInset),
            replyContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -replyInset),

            // Text view sits below the reply container
            messageTextView.topAnchor.constraint(equalTo: replyContainer.bottomAnchor, constant: insets.top),
            messageTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            messageTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            messageTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
        ])
    }

    // MARK: - ConversationMessageCell

    func configure(with object: Configuration, animated: Bool) {
        var replyConfig = ConversationReplyContentView.Configuration(
            quotedMessage: object.quotedMessage,
            accentColor: object.accentColor,
            messageReplyAttachmentsViewModel: object.messageReplyAttachmentsViewModel,
            isSentBySelfUser: object.isSentBySelfUser,
            senderAccentColor: object.senderAccentColor,
            quotedMessageWasDeleted: object.quotedMessageWasDeleted
        )
        replyConfig.delegate = delegate
        replyContentView.configure(with: replyConfig)
        applyEmbeddedSenderStyle(object: object)

        let mutableText = NSMutableAttributedString(attributedString: object.attributedText)
        mutableText.mergeLineSpacing(3)
        messageTextView.attributedText = mutableText

        messageTextView.accessibilityIdentifier = object.isObfuscated
            ? "Obfuscated message"
            : Locators.ActiveConversationPage.message.rawValue

        applyStyle(isSentBySelfUser: object.isSentBySelfUser, accentColor: object.senderAccentColor)
        configureTextColor(forOwnMessage: object.isSentBySelfUser)
        addAccentColorChangeObserver(userSession: object.userSession)
        setupAccessibility(accessibilityLabel: messageTextView.attributedText.string)
    }

    // MARK: - Styling

    private func applyStyle(isSentBySelfUser: Bool, accentColor: WireAccentColor) {

        backgroundColor = isSentBySelfUser
            ? ColorTheme.OwnChatBubbles.primary(accentColor)
            : ColorTheme.OthersChatBubbles.primary
        replyContainer.backgroundColor = isSentBySelfUser
            ? ColorTheme.OwnChatBubbles.secondary(accentColor)
            : ColorTheme.OthersChatBubbles.secondary
        replyContainer.layer.borderWidth = 0
        replyContainer.layer.maskedCorners = [
            .layerMinXMinYCorner, .layerMaxXMinYCorner,
            .layerMinXMaxYCorner, .layerMaxXMaxYCorner
        ]
        replyContainer.setAccentBarHidden(true)
    }

    /// Applies the embedded-cell-specific styling to the reply content view after it has been configured:
    /// - Adds a reply-arrow icon next to the quoted sender's name, colored with the quoted sender's accent color.
    /// - Dims the timestamp slightly.
    private func applyEmbeddedSenderStyle(object: Configuration) {

        let iconColor: UIColor = object.isSentBySelfUser ? ColorTheme.OwnChatBubbles.onPrimary : ColorTheme
            .OthersChatBubbles.onPrimary
        let quotedAccentColor = object.quotedMessage?.senderUser?.wireAccentColor ?? .default
        let senderColor = object.isSentBySelfUser ? ColorTheme.OwnChatBubbles
            .primaryOnSecondary(quotedAccentColor) : ColorTheme.OthersChatBubbles.primaryOnSecondary(quotedAccentColor)

        if let name = object.quotedMessage?.senderName {
            let replyIcon = UIImage(named: "ReplyIcon")!.withTintColor(iconColor, renderingMode: .alwaysTemplate)
            let attachment = NSTextAttachment()
            attachment.image = replyIcon
            attachment.bounds = CGRect(x: 0, y: -1, width: 10, height: 10)
            let combined = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
            combined.append(NSAttributedString(
                string: " \(name)",
                attributes: [.foregroundColor: senderColor, .font: UIFont.mediumSemiboldFont]
            ))
            replyContentView.senderComponent.label.attributedText = combined
        } else {
            replyContentView.senderComponent.senderName = object.quotedMessage?.senderName
            replyContentView.senderComponent.label.textColor = senderColor
        }

        replyContentView.timestampLabel.textColor = iconColor
    }

    private func configureTextColor(forOwnMessage ownMessage: Bool) {
        let ownColor = ColorTheme.OwnChatBubbles.onPrimary
        let otherColor = ColorTheme.OthersChatBubbles.onPrimary

        let textColor: UIColor = ownMessage ? ownColor : otherColor
        let linkColor: UIColor = ownMessage ? ownColor : otherColor

        let linkAttributes: [NSAttributedString.Key: Any] = ownMessage
            ? [
                .foregroundColor: linkColor,
                .underlineColor: linkColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
            : [.foregroundColor: linkColor]

        messageTextView.textColor = textColor
        messageTextView.linkTextAttributes = linkAttributes
        messageTextView.applyMarkdownColors(textColor)
    }

    private func addAccentColorChangeObserver(userSession: UserSession?) {
        guard accentColorChangeHandler == nil, let userSession else { return }
        accentColorChangeHandler = AccentColorChangeHandler
            .addObserver(userSession: userSession) { [weak self] _ in
                guard let self, let message else { return }
                let isOwn = message.isSentBySelfUser
                let accentColor = message.senderUser?.wireAccentColor ?? .default
                applyStyle(isSentBySelfUser: isOwn, accentColor: accentColor)
                configureTextColor(forOwnMessage: isOwn)
            }
    }

    private func setupAccessibility(accessibilityLabel: String) {
        typealias Conversation = L10n.Accessibility.Conversation
        isAccessibilityElement = false
        self.accessibilityLabel = accessibilityLabel
        accessibilityHint = "\(Conversation.MessageInfo.hint), \(Conversation.MessageOptions.hint)"
    }

    // MARK: - Reply tap

    @objc
    private func onReplyTap() {
        guard let message else { return }
        delegate?.perform(action: .openQuote, for: message, view: self)
    }

    // MARK: - TextViewInteractionDelegate

    func textView(_ textView: LinkInteractionTextView, open url: URL) -> Bool {
        if url.isMention {
            guard let message,
                  let mention = message.textMessageData?.mentions.first(where: { $0.location == url.mentionLocation })
            else { return false }
            return openMention(mention)
        }
        return url.open()
    }

    func openMention(_ mention: Mention) -> Bool {
        delegate?.conversationMessageWantsToOpenUserDetails(
            self,
            user: mention.user,
            sourceView: messageTextView,
            frame: selectionRect
        )
        return true
    }

    func textViewDidLongPress(_ textView: LinkInteractionTextView) {
        guard !UIMenuController.shared.isMenuVisible else { return }
        if !Settings.isClipboardEnabled {
            menuPresenter?.showSecuredMenu()
        } else {
            menuPresenter?.showMenu()
        }
    }
}

// MARK: - Description

final class ConversationReplyWithTextCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationReplyWithTextCell

    var configuration: View.Configuration

    var topMargin: CGFloat = 8

    let supportsActions: Bool = true
    let containsHighlightableContent: Bool = true
    let shouldAlignMessageContentForBubbles: Bool = true

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    weak var message: ZMConversationMessage? {
        didSet {
            configuration.isSentBySelfUser = message?.isSentBySelfUser ?? false
            configuration.senderAccentColor = message?.senderUser?.wireAccentColor ?? .default
            if let quotedMessage = message?.textMessageData?.quoteMessage {
                configuration.quotedMessage = quotedMessage
            }
        }
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    init(
        quotedMessage: ZMConversationMessage?,
        accentColor: AccentColor,
        messageReplyAttachmentsViewModel: MessageReplyAttachmentsViewModel?,
        attributedText: NSAttributedString,
        isObfuscated: Bool,
        userSession: UserSession?,
        isSentBySelfUser: Bool = false,
        senderAccentColor: WireAccentColor = .blue,
        quotedMessageWasDeleted: Bool = false
    ) {
        self.configuration = View.Configuration(
            quotedMessage: quotedMessage,
            accentColor: accentColor,
            messageReplyAttachmentsViewModel: messageReplyAttachmentsViewModel,
            attributedText: attributedText,
            isObfuscated: isObfuscated,
            userSession: userSession,
            isSentBySelfUser: isSentBySelfUser,
            senderAccentColor: senderAccentColor,
            quotedMessageWasDeleted: quotedMessageWasDeleted
        )
    }
}
