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
        let mentions: [Mention]
        let detectedLinks: [NSTextCheckingResult]
        init(
            attributedText: NSAttributedString,
            isObfuscated: Bool,
            userSession: UserSession? = nil,
            mentions: [Mention],
            detectedLinks: [NSTextCheckingResult]
        ) {
            self.attributedText = attributedText
            self.isObfuscated = isObfuscated
            self.userSession = userSession
            self.mentions = mentions
            self.detectedLinks = detectedLinks
        }

        static func == (
            lhs: ConversationTextMessageCell.Configuration,
            rhs: ConversationTextMessageCell.Configuration
        ) -> Bool {
            lhs.isObfuscated == rhs.isObfuscated &&
                lhs.attributedText.description == rhs.attributedText.description &&
                lhs.mentions.elementsEqual(
                    rhs.mentions,
                    by: {
                        $0.range.location == $1.range.location && $0.range.length == $1.range.length && $0.user
                            .isEqual($1.user)
                    }
                ) &&
                lhs.detectedLinks.elementsEqual(rhs.detectedLinks, by: { $0.range == $1.range && $0.url == $1.url })
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
        view.dataDetectorTypes = []
        view.linkTextAttributes = [:]

        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.interactionDelegate = self

        view.textDragInteraction?.isEnabled = false

        return view
    }()

    private var container: ConversationMessageContainerView?
    private var currentConfiguration: Configuration?

    var isSelected = false

    weak var message: ZMConversationMessage? {
        didSet {
            guard let message else { return }
            let isOwnMessage = message.isSentBySelfUser
            let userColor = message.senderUser?.wireAccentColor ?? .default
            let ownMessageColor = ColorTheme.Base.primaryVariant(userColor)
            container?.bubbleStyle = isOwnMessage ? .ownMessage(userColor: ownMessageColor) : .otherMessage

            if let currentConfig = currentConfiguration {
                configure(with: currentConfig, animated: false)
            }
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

    func configure(with object: Configuration, animated: Bool) {
        currentConfiguration = object

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.lineSpacing = 3

        let isOwnMessage = message?.isSentBySelfUser ?? false
        let baseTextColor: UIColor = isOwnMessage ?
            SemanticColors.ChatBubble.foregroundOwnMessage :
            SemanticColors.ChatBubble.foregroundOtherMessage

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .foregroundColor: baseTextColor
        ]

        let mutableAttributedText = NSMutableAttributedString(attributedString: object.attributedText)
        mutableAttributedText.addAttributes(
            baseAttributes,
            range: NSRange(location: 0, length: mutableAttributedText.length)
        )

        let mentionForegroundColor: UIColor
        let detectedLinkForegroundColor: UIColor

        if isOwnMessage {
            mentionForegroundColor = SemanticColors.ChatBubble.foregroundOwnMessage
            detectedLinkForegroundColor = SemanticColors.ChatBubble.foregroundOwnMessage
        } else {
            mentionForegroundColor = UIColor.accent()
            detectedLinkForegroundColor = UIColor.accent()
        }

        // Create a set of mention ranges for quick lookup to avoid applying underline to mentions
        let mentionRanges: Set<NSRange> = Set(object.mentions.map(\.range))

        // Apply styling for Mentions (NO UNDERLINE)
        for mention in object.mentions {
            let mentionRange = mention.range
            guard mentionRange.location + mentionRange.length <= mutableAttributedText.length else { continue }

            let mentionURL = mention.link

            mutableAttributedText.addAttributes([
                .foregroundColor: mentionForegroundColor,
                .underlineStyle: NSUnderlineStyle(rawValue: 0).rawValue,
                .link: mentionURL
            ], range: mentionRange)
        }
        // Apply styling for other detected links (WITH UNDERLINE)
        for result in object.detectedLinks {
            let linkRange = result.range
            guard linkRange.location + linkRange.length <= mutableAttributedText.length else { continue }

            let isOverlappingMention = mentionRanges.contains { NSIntersectionRange(linkRange, $0).length > 0 }

            if let link = result.url, !isOverlappingMention {
                mutableAttributedText.addAttributes([
                    .foregroundColor: detectedLinkForegroundColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .link: link
                ], range: linkRange)
            }
        }

        mutableAttributedText.enumerateAttribute(
            .link,
            in: NSRange(location: 0, length: mutableAttributedText.length),
            options: []
        ) { value, range, _ in
            guard let link = value as? URL else {
                return
            }

            let isCoveredByMention = mentionRanges.contains { NSIntersectionRange(range, $0).length > 0 }

            guard !isCoveredByMention else {
                return
            }

            mutableAttributedText.addAttributes([
                .foregroundColor: detectedLinkForegroundColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .link: link
            ], range: range)
        }

        messageTextView.attributedText = mutableAttributedText

        if object.isObfuscated {
            messageTextView.accessibilityIdentifier = "Obfuscated message"
        } else {
            messageTextView.accessibilityIdentifier = Locators.ActiveConversationPage.message.rawValue
        }

        container?.isBubble = true
        updateContainerStyle()
        addAccentColorChangeObserver(userSession: object.userSession)
        setupAccessibility(accessibilityLabel: messageTextView.attributedText.string)
    }

    private func addAccentColorChangeObserver(userSession: UserSession?) {
        guard accentColorChangeHandler == nil, let userSession else { return }
        accentColorChangeHandler = AccentColorChangeHandler
            .addObserver(userSession: userSession) { [weak self] _ in
                if let config = self?.currentConfiguration {
                    self?.configure(with: config, animated: false)
                }
            }
    }

    private func updateContainerStyle() {
        guard let message else { return }
        let isOwnMessage = message.isSentBySelfUser
        let userColor = message.senderUser?.wireAccentColor ?? .default
        let ownMessageColor = ColorTheme.Base.primaryVariant(userColor)
        container?.bubbleStyle = isOwnMessage ? .ownMessage(userColor: ownMessageColor) : .otherMessage

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
        userSession: UserSession?,
        mentions: [Mention],
        detectedLinks: [NSTextCheckingResult]
    ) {
        self.configuration = View.Configuration(
            attributedText: attributedString,
            isObfuscated: isObfuscated,
            userSession: userSession,
            mentions: mentions,
            detectedLinks: detectedLinks
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

        var allDetectedLinks: [NSTextCheckingResult] = []

        let embeddedLinks = ConversationTextMessageCellDescription.findEmbeddedLinks(in: textMessageData)
        allDetectedLinks.append(contentsOf: embeddedLinks)

        let autoDetectedLinks = ConversationTextMessageCellDescription.findDetectedLinks(in: messageText)
        allDetectedLinks.append(contentsOf: autoDetectedLinks)

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
                userSession: userSession,
                mentions: textMessageData.mentions,
                detectedLinks: allDetectedLinks
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

    static func findDetectedLinks(in messageText: NSAttributedString) -> [NSTextCheckingResult] {
        let checkingTypes: NSTextCheckingResult.CheckingType = [.link, .phoneNumber, .address]
        guard let detector = try? NSDataDetector(types: checkingTypes.rawValue) else {
            return []
        }

        let textToScan = messageText.string
        let scanRange = NSRange(location: 0, length: textToScan.utf16.count)

        return detector.matches(
            in: textToScan,
            options: [],
            range: scanRange
        )
    }

    static func findEmbeddedLinks(in textMessageData: TextMessageData) -> [NSTextCheckingResult] {
        guard let messageTextString = textMessageData.messageText else {
            return []
        }
        guard let linkPreview = textMessageData.linkPreview,
              let originalURLString = textMessageData.linkPreview?.originalURLString,
              let url = URL(string: originalURLString),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()) else {
            return []
        }
        let expectedRange = NSRange(
            location: linkPreview.characterOffsetInText,
            length: linkPreview.textLengthInMessage
        )
        guard expectedRange.location >= 0,
              expectedRange.length >= 0,
              expectedRange.location + expectedRange.length <= messageTextString.count else {
            return []
        }

        let nsMessageText = messageTextString as NSString
        let textAtRange = nsMessageText.substring(with: expectedRange)
        guard textAtRange == originalURLString else {
            return []
        }
        let linkResult = NSTextCheckingResult.linkCheckingResult(range: expectedRange, url: url)
        return [linkResult]
    }
}

extension URL {

    // FIXME: [WPB-16311]: Remove once file previews are working in conversations.
    /// A temporary means to open the Files View from a message cell link for Beta testing.
    static let openFilesViewLink: URL = .init(string: "cells://open-files-view")!
}
