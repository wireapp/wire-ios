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
import WireLocators
import WireMessagingDomain
import WireSyncEngine

final class ConversationTextMessageCell: UIView, ConversationMessageCell, TextViewInteractionDelegate {

    struct Configuration: Equatable {
        let attributedText: NSAttributedString
        let isObfuscated: Bool
        let userSession: UserSession?

        init(
            attributedText: NSAttributedString,
            isObfuscated: Bool,
            userSession: UserSession? = nil
        ) {
            self.attributedText = attributedText
            self.isObfuscated = isObfuscated
            self.userSession = userSession
        }

        static func == (
            lhs: ConversationTextMessageCell.Configuration,
            rhs: ConversationTextMessageCell.Configuration
        ) -> Bool {
            lhs.isObfuscated == rhs.isObfuscated &&
                lhs.attributedText.isEqual(to: rhs.attributedText)
        }
    }

    private lazy var messageTextView: LinkInteractionTextView = {
        let view = LinkInteractionTextView()

        view.isEditable = false
        view.isSelectable = true
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.textContainerInset = UIEdgeInsets.zero
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

        return view
    }()

    private var container: ConversationMessageContainerView?

    var isSelected = false

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
    private var accentColorChangeHandler: AccentColorChangeHandler?

    var selectionView: UIView? {
        messageTextView
    }

    var selectionRect: CGRect {
        messageTextView.layoutManager.usedRect(for: messageTextView.textContainer)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        messageTextView.translatesAutoresizingMaskIntoConstraints = false

        container = .init(content: messageTextView)
        if let container {
            container.translatesAutoresizingMaskIntoConstraints = false
            addSubview(container)
        }

        configureConstraints()
    }

    private func configureConstraints() {
        let insets = ConversationMessageContainerView.bubbleEdgeInsets
        messageTextView.fitIn(view: self, insets: insets)
    }

    private func configureTextColor(forOwnMessage ownMessage: Bool) {
        let ownColor = SemanticColors.ChatBubble.foregroundOwnMessage
        let otherColor = SemanticColors.ChatBubble.foregroundOtherMessage

        let textForegroundColor: UIColor = ownMessage ? ownColor : otherColor
        let linkForegroundColor: UIColor = ownMessage ? ownColor : UIColor.accent()

        let linkTextAttributes: [NSAttributedString.Key: Any] = if ownMessage {
            [
                .foregroundColor: linkForegroundColor,
                .underlineColor: linkForegroundColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        } else {
            [
                .foregroundColor: linkForegroundColor
            ]
        }

        messageTextView.textColor = textForegroundColor
        messageTextView.linkTextAttributes = linkTextAttributes
    }

    func configure(with object: Configuration, animated: Bool) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.lineSpacing = 3

        let attributes: [NSAttributedString.Key: AnyObject] = [
            .paragraphStyle: paragraphStyle
        ]

        messageTextView.attributedText = object.attributedText.addAttributes(
            attributes,
            toSubstring: object.attributedText.string
        )

        if object.isObfuscated {
            messageTextView.accessibilityIdentifier = "Obfuscated message"
        } else {
            messageTextView.accessibilityIdentifier = Locators.ActiveConversationPage.message.rawValue
        }

        container?.isBubble = true
        updateContainerStyle()
        configureTextColor(forOwnMessage: message?.isSentBySelfUser ?? false)
        addAccentColorChangeObserver(userSession: object.userSession)
        setupAccessibility(accessibilityLabel: messageTextView.attributedText.string)
    }

    private func addAccentColorChangeObserver(userSession: UserSession?) {
        guard accentColorChangeHandler == nil, let userSession else { return }
        accentColorChangeHandler = AccentColorChangeHandler
            .addObserver(userSession: userSession) { [weak self] _ in
                self?.configureTextColor(forOwnMessage: self?.message?.isSentBySelfUser ?? false)
            }
    }

    private func updateContainerStyle() {
        guard let message else { return }
        let isOwnMessage = message.isSentBySelfUser
        let userColor = message.senderUser?.accentColor ?? .clear
        container?.bubbleStyle = isOwnMessage ? .ownMessage(userColor: userColor) : .otherMessage
    }

    func textView(_ textView: LinkInteractionTextView, open url: URL) -> Bool {
        // Open mention link
        if url.isMention {
            if let message,
               let mention = message.textMessageData?.mentions.first(where: { $0.location == url.mentionLocation }) {
                return openMention(mention)
            } else {
                return false
            }
        }

        // Open the URL
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
        if !UIMenuController.shared.isMenuVisible {
            if !Settings.isClipboardEnabled {
                menuPresenter?.showSecuredMenu()
            } else {
                menuPresenter?.showMenu()
            }
        }
    }

    private func setupAccessibility(accessibilityLabel: String) {
        typealias Conversation = L10n.Accessibility.Conversation

        isAccessibilityElement = false
        container?.isAccessibilityElement = true
        container?.accessibilityLabel = accessibilityLabel
        container?.accessibilityHint = "\(Conversation.MessageInfo.hint), \(Conversation.MessageOptions.hint)"
    }
}

// MARK: - Description

final class ConversationTextMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationTextMessageCell

    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    let supportsActions: Bool = true
    let containsHighlightableContent: Bool = true

    let shouldAlignMessageContentForBubbles: Bool = true

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init(
        attributedString: NSAttributedString,
        isObfuscated: Bool,
        userSession: UserSession?
    ) {
        self.configuration = View.Configuration(
            attributedText: attributedString,
            isObfuscated: isObfuscated,
            userSession: userSession,
        )
    }
}

// MARK: - Factory

extension ConversationTextMessageCellDescription {

    static func cells(
        for message: ZMConversationMessage,
        searchQueries: [String],
        selfUser: any UserType,
        userSession: UserSession,
        wireMessagingFactory: any WireMessagingFactoryProtocol
    ) -> [AnyConversationMessageCellDescription] {
        guard let textMessageData = message.textMessageData else {
            preconditionFailure("Invalid text message")
        }

        return cells(
            textMessageData: textMessageData,
            message: message,
            searchQueries: searchQueries,
            selfUser: selfUser,
            userSession: userSession,
            wireMessagingFactory: wireMessagingFactory
        )
    }

    static func cells(
        textMessageData: TextMessageData,
        message: ZMConversationMessage,
        searchQueries: [String],
        selfUser: any UserType,
        userSession: UserSession,
        wireMessagingFactory: any WireMessagingFactoryProtocol
    ) -> [AnyConversationMessageCellDescription] {

        var cells: [AnyConversationMessageCellDescription] = []

        // Refetch the link attachments if needed
        if !Settings.disableLinkPreviews, let id = (message as? ZMMessage)?.objectID {
            userSession.enqueue {
                let message = ZMMessage.existingObject(
                    with: id,
                    inUserSession: userSession.contextProvider
                )
                message?.refetchLinkAttachmentsIfNeeded()
            }
        }

        // Text parsing
        let attachments = message.linkAttachments ?? []
        var messageText = NSAttributedString.format(
            message: textMessageData,
            isObfuscated: message.isObfuscated,
            accentColor: (selfUser.zmAccentColor ?? .default).accentColor
        )

        // Search queries
        if !searchQueries.isEmpty {
            let highlightStyle: [NSAttributedString.Key: AnyObject] = [.backgroundColor: UIColor.accentDarken]
            messageText = messageText.highlightingAppearances(
                of: searchQueries,
                with: highlightStyle,
                upToWidth: 0,
                totalMatches: nil
            )
        }

        // Quote
        if let quotedMessage = textMessageData.quoteMessage {
            let viewModel = MessageReplyAttachmentsViewModel(
                fetchCachedNodeUseCase: wireMessagingFactory.makeFetchCachedNodeUseCase(),
                fetchNodeUseCase: wireMessagingFactory.makeFetchNodeUseCase()
            )

            let quoteCell = ConversationReplyCellDescription(
                quotedMessage: quotedMessage,
                accentColor: (selfUser.zmAccentColor ?? .default).accentColor,
                messageReplyAttachmentsViewModel: viewModel
            )
            cells.append(AnyConversationMessageCellDescription(quoteCell))
        }

        // Text
        if !messageText.string.isEmpty {
            let textCell = ConversationTextMessageCellDescription(
                attributedString: messageText,
                isObfuscated: message.isObfuscated,
                userSession: userSession
            )
            cells.append(AnyConversationMessageCellDescription(textCell))
        }

        guard !message.isObfuscated else { return cells }

        // Links
        if let attachment = attachments.first {
            // Link Attachment
            let attachmentCell = ConversationLinkAttachmentCellDescription(
                attachment: attachment,
                thumbnailResource: message.linkAttachmentImage
            )
            cells.append(AnyConversationMessageCellDescription(attachmentCell))
        } else if textMessageData.linkPreview != nil {
            // Link Preview
            let linkPreviewCell = ConversationLinkPreviewArticleCellDescription(
                message: message,
                data: textMessageData
            )
            cells.append(AnyConversationMessageCellDescription(linkPreviewCell))
        }

        return cells
    }

}

extension URL {

    // FIXME: [WPB-16311]: Remove once file previews are working in conversations.
    /// A temporary means to open the Files View from a message cell link for Beta testing.
    static let openFilesViewLink: URL = .init(string: "cells://open-files-view")!
}
