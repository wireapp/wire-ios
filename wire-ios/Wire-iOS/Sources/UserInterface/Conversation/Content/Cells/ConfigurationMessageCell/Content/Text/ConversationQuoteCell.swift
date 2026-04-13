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

import Down
import UIKit
import WireCommonComponents
import WireDataModel
import WireDesign
import WireFoundation
import WireMessagingDomain
import WireSyncEngine

final class ConversationReplyContentView: UIView {
    typealias FileSharingRestrictions = L10n.Localizable.FeatureConfig.FileSharingRestrictions
    typealias MessagePreview = L10n.Localizable.Conversation.InputBar.MessagePreview
    let numberOfLinesLimit: Int = 4

    struct Configuration: Equatable {
        enum Content {
            case text(NSAttributedString)
            case imagePreview(thumbnail: PreviewableImageResource, isVideo: Bool)
            case multipart(text: NSAttributedString?, attachments: [MultipartMessageData.Attachment])
        }

        var quotedMessage: ZMConversationMessage?
        let accentColor: AccentColor
        let messageReplyAttachmentsViewModel: MessageReplyAttachmentsViewModel?
        weak var delegate: ConversationMessageCellDelegate?
        var isSentBySelfUser: Bool = false
        var senderAccentColor: WireAccentColor = .blue
        var showReplyArrow: Bool = false

        static func == (lhs: Configuration, rhs: Configuration) -> Bool {
            lhs.accentColor == rhs.accentColor &&
                lhs.quotedMessage == rhs.quotedMessage &&
                lhs.isSentBySelfUser == rhs.isSentBySelfUser
        }

        var showDetails: Bool {
            guard let message = quotedMessage,
                  message.isText
                  || message.isLocation
                  || message.isAudio
                  || message.isImage
                  || message.isVideo
                  || message.isFile else {
                return false
            }
            return true
        }

        var isEdited: Bool {
            quotedMessage?.updatedAt != nil
        }

        var senderName: String? {
            quotedMessage?.senderName
        }

        var timestamp: String? {
            quotedMessage?.formattedOriginalReceivedDate()
        }

        var showRestriction: Bool {
            guard let message = quotedMessage,
                  !message.canBeShared else {
                return false
            }
            return true
        }

        var restrictionDescription: String? {
            guard let message = quotedMessage,
                  !message.canBeShared else {
                return nil
            }

            if message.isAudio {
                return FileSharingRestrictions.audio
            } else if message.isImage {
                return FileSharingRestrictions.picture
            } else if message.isVideo {
                return FileSharingRestrictions.video
            } else if message.isFile {
                return FileSharingRestrictions.file
            } else {
                return nil
            }
        }

        var content: Content {
            setupContent()
        }

        var contentType: String {
            guard let message = quotedMessage else {
                return "quote.type.unavailable"
            }
            return "quote.type.\(message.typeString)"
        }

        private func setupContent() -> Content {
            typealias LabelColors = SemanticColors.Label
            let iconColor: UIColor = isSentBySelfUser ? .white : LabelColors.textDefault
            let textColor: UIColor = isSentBySelfUser ? .white : LabelColors.textDefault
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.smallSemiboldFont,
                .foregroundColor: textColor
            ]
            switch quotedMessage {
            case let message? where message.isMultipart:
                let data = message.textMessageData
                var text: NSAttributedString?
                if let data, message.text?.isEmpty == false {
                    text = NSAttributedString
                        .formatForPreview(
                            message: data,
                            inputMode: false,
                            textColor: textColor,
                            accentColor: accentColor
                        )
                }
                let attachments = message.multipartMessageData?.attachments ?? []
                return .multipart(text: text, attachments: attachments)

            case let message? where message.isText:
                let data = message.textMessageData!
                return .text(
                    NSAttributedString
                        .formatForPreview(
                            message: data,
                            inputMode: false,
                            textColor: textColor,
                            accentColor: accentColor
                        )
                )

            case let message? where message.isLocation:
                let location = message.locationMessageData!
                let imageIcon = NSTextAttachment.textAttachment(for: .locationPin, with: iconColor)
                let initialString = NSAttributedString(attachment: imageIcon) + "  " +
                    (location.name ?? MessagePreview.location).localizedUppercase
                return .text(initialString && attributes)

            case let message? where message.isAudio:
                let imageIcon = NSTextAttachment.textAttachment(for: .microphone, with: iconColor)
                let initialString = NSAttributedString(attachment: imageIcon) + "  " + MessagePreview.audio
                    .localizedUppercase
                return .text(initialString && attributes)

            case let message? where message.isImage && !message.canBeShared:
                let imageIcon = NSTextAttachment.textAttachment(for: .photo, with: iconColor)
                let initialString = NSAttributedString(attachment: imageIcon) + "  " + MessagePreview.image
                    .localizedUppercase
                return .text(initialString && attributes)

            case let message? where message.isImage:
                return .imagePreview(thumbnail: message.imageMessageData!.image, isVideo: false)

            case let message? where message.isVideo && !message.canBeShared:
                let imageIcon = NSTextAttachment.textAttachment(for: .camera, with: iconColor)
                let initialString = NSAttributedString(attachment: imageIcon) + "  " + MessagePreview.video
                    .localizedUppercase
                return .text(initialString && attributes)

            case let message? where message.isVideo:
                return .imagePreview(thumbnail: message.fileMessageData!.thumbnailImage, isVideo: true)

            case let message? where message.isFile:
                let fileData = message.fileMessageData!
                let imageIcon = NSTextAttachment.textAttachment(for: .document, with: iconColor)
                let initialString = NSAttributedString(attachment: imageIcon) + "  " +
                    (fileData.filename ?? MessagePreview.file).localizedUppercase
                return .text(initialString && attributes)

            default:
                let attributes: [NSAttributedString.Key: AnyObject] = [
                    .font: UIFont.mediumFont.italic,
                    .foregroundColor: LabelColors
                        .textCollectionSecondary
                ]
                return .text(NSAttributedString(
                    string: L10n.Localizable.Content.Message.Reply.brokenMessage,
                    attributes: attributes
                ))
            }
        }
    }

    let senderComponent = SenderNameCellComponent()
    let contentTextView = UITextView()
    let timestampLabel = UILabel()
    let restrictionLabel = UILabel()
    let assetThumbnail = ImageResourceThumbnailView()
    let contentAttachmentsView = UIView()
    var messageReplyAttachmentView: MessageReplyAttachmentsView?

    let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    func onPrepareForReuse() {
        messageReplyAttachmentView?.cancelPreviewDownload()
        contentAttachmentsView.removeSubviews()
    }

    private func configureSubviews() {
        shouldGroupAccessibilityChildren = false

        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 6
        addSubview(stackView)

        senderComponent.label.accessibilityIdentifier = "original.sender"
        senderComponent.indicatorView.accessibilityIdentifier = "original.edit_icon"
        senderComponent.label.font = .mediumSemiboldFont
        senderComponent.label.textColor = SemanticColors.Label.textDefault
        stackView.addArrangedSubview(senderComponent)

        contentTextView.textContainer.lineBreakMode = .byTruncatingTail
        contentTextView.textContainer.maximumNumberOfLines = numberOfLinesLimit
        contentTextView.textContainer.lineFragmentPadding = 0
        contentTextView.isScrollEnabled = false
        contentTextView.isUserInteractionEnabled = false
        contentTextView.textContainerInset = .zero
        contentTextView.isEditable = false
        contentTextView.isSelectable = false
        contentTextView.backgroundColor = .clear
        contentTextView.textColor = SemanticColors.Label.textDefault

        contentTextView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        stackView.addArrangedSubview(contentTextView)

        restrictionLabel.accessibilityIdentifier = "original.restriction"
        restrictionLabel.font = .smallLightFont
        restrictionLabel.textColor = SemanticColors.Label.textCollectionSecondary
        stackView.addArrangedSubview(restrictionLabel)

        assetThumbnail.shape = .rounded(radius: 4)
        assetThumbnail.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.addArrangedSubview(assetThumbnail)

        timestampLabel.accessibilityIdentifier = "original.timestamp"
        timestampLabel.font = .mediumFont
        timestampLabel.textColor = SemanticColors.Label.textCollectionSecondary
        timestampLabel.numberOfLines = 1
        timestampLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        stackView.addArrangedSubview(contentAttachmentsView)
        stackView.addArrangedSubview(timestampLabel)
    }

    private func configureConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            assetThumbnail.heightAnchor.constraint(lessThanOrEqualToConstant: 140),
            contentTextView.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }

    func configure(with object: Configuration) {
        senderComponent.isHidden = !object.showDetails
        timestampLabel.isHidden = !object.showDetails
        restrictionLabel.isHidden = !object.showRestriction
        contentAttachmentsView.isHidden = true

        if object.showReplyArrow {
            // Dark accent background: content/timestamp use white; sender uses quoted sender's accent color
            let replyColor = object.isSentBySelfUser ? .white : SemanticColors.Label.textDefault
            contentTextView.textColor = replyColor
            timestampLabel.textColor = replyColor.withAlphaComponent(0.7)

            let quotedAccentColor = object.quotedMessage?.senderUser?.wireAccentColor ?? .blue
            let senderColor = ColorTheme.Base.primary(quotedAccentColor)

            
            if let name = object.senderName,
               let replyIcon = UIImage(named: "ReplyIcon")?.withTintColor(replyColor, renderingMode: .alwaysTemplate) {
                let attachment = NSTextAttachment()
                attachment.image = replyIcon
                let iconSize = CGFloat(10)
                attachment.bounds = CGRect(x: 0, y: -1, width: iconSize, height: iconSize)
                let iconAttr = NSAttributedString(attachment: attachment)
                let nameAttr = NSAttributedString(
                    string: " \(name)",
                    attributes: [.foregroundColor: senderColor, .font: UIFont.mediumSemiboldFont]
                )
                let combined = NSMutableAttributedString()
                combined.append(iconAttr)
                combined.append(nameAttr)
                senderComponent.label.attributedText = combined
            } else {
                senderComponent.senderName = object.senderName
                senderComponent.label.textColor = senderColor
            }
        } else if object.isSentBySelfUser {
            senderComponent.label.attributedText = nil
            senderComponent.label.textColor = ColorTheme.Base.ownBubbleSenderNameColor(object.senderAccentColor)
            contentTextView.textColor = SemanticColors.ChatBubble.foregroundOwnMessage
            timestampLabel.textColor = SemanticColors.ChatBubble.foregroundOwnMessage
            senderComponent.senderName = object.senderName
        } else {
            senderComponent.label.attributedText = nil
            senderComponent.label.textColor = SemanticColors.Label.textDefault
            contentTextView.textColor = SemanticColors.Label.textDefault
            timestampLabel.textColor = SemanticColors.Label.textCollectionSecondary
            senderComponent.senderName = object.senderName
        }
        senderComponent.indicatorIcon = object.isEdited ? StyleKitIcon.pencil.makeImage(
            size: 8,
            color: SemanticColors.Icon.foregroundDefault
        ) : nil
        senderComponent.indicatorLabel = object.isEdited ? L10n.Localizable.Content.Message.Reply.editedMessage : nil
        timestampLabel.text = object.timestamp
        restrictionLabel.text = object.restrictionDescription?.localizedUppercase

        switch object.content {
        case let .text(attributedContent):
            let mutableAttributedContent = NSMutableAttributedString(attributedString: attributedContent)
            // Trim the string to first four lines to prevent last line narrower spacing issue
            mutableAttributedContent.paragraphTailTruncated()
            contentTextView.attributedText = mutableAttributedContent
                .trimmedToNumberOfLines(numberOfLinesLimit: numberOfLinesLimit)
            contentTextView.isHidden = false
            contentTextView.accessibilityIdentifier = object.contentType
            contentTextView.isAccessibilityElement = true
            assetThumbnail.isHidden = true
            assetThumbnail.isAccessibilityElement = false
            contentAttachmentsView.isHidden = true
        case let .imagePreview(resource, isVideo):
            assetThumbnail.setResource(resource, isVideoPreview: isVideo)
            assetThumbnail.isHidden = false
            assetThumbnail.accessibilityIdentifier = object.contentType
            assetThumbnail.isAccessibilityElement = true
            contentTextView.isHidden = true
            contentTextView.isAccessibilityElement = false
            contentAttachmentsView.isHidden = true
        case let .multipart(text, attachments):
            contentAttachmentsView.isHidden = false
            contentTextView.isHidden = text == nil
            contentTextView.accessibilityIdentifier = object.contentType
            contentTextView.isAccessibilityElement = true
            assetThumbnail.isHidden = true
            assetThumbnail.isAccessibilityElement = false

            if let text {
                let mutableAttributedContent = NSMutableAttributedString(attributedString: text)
                // Trim the string to first four lines to prevent last line narrower spacing issue
                mutableAttributedContent.paragraphTailTruncated()
                contentTextView.attributedText = mutableAttributedContent
                    .trimmedToNumberOfLines(numberOfLinesLimit: numberOfLinesLimit)
            }

            guard let viewModel = object.messageReplyAttachmentsViewModel else {
                return
            }

            let delegate = object.delegate
            messageReplyAttachmentView = MessageReplyAttachmentsView(
                attachments: attachments,
                viewModel: viewModel,
                onSizeChange: { [weak delegate] in
                    delegate?.conversationMessageContentDidChangeSize()
                }
            )

            contentAttachmentsView.addSubview(messageReplyAttachmentView!)
            messageReplyAttachmentView!.fitIn(view: contentAttachmentsView)
        }

        // In the combined reply+text cell the box background is dark: force white on the content text
        if object.showReplyArrow,
           let existing = contentTextView.attributedText,
           !existing.string.isEmpty {
            let color = object.isSentBySelfUser ? UIColor.white : UIColor.black
            
            let mutable = NSMutableAttributedString(attributedString: existing)
            mutable.addAttribute(
                .foregroundColor,
                value: color,
                range: NSRange(location: 0, length: mutable.length)
            )
            contentTextView.attributedText = mutable
        }
    }

}

final class ConversationReplyCell: UIView, ConversationMessageCell {

    typealias Configuration = ConversationReplyContentView.Configuration

    var isSelected: Bool = false

    let contentView: ConversationReplyContentView
    var container: ReplyRoundCornersView

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?
    weak var actionController: ConversationMessageActionController?

    override init(frame: CGRect) {
        self.contentView = ConversationReplyContentView()
        self.container = ReplyRoundCornersView(containedView: contentView)
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubviews() {
        container.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
    }

    private func configureConstraints() {
        container.fitIn(view: self, insets: .zero)
    }

    func configure(with object: Configuration, animated: Bool) {
        container.updateStyle(isSentBySelfUser: object.isSentBySelfUser, accentColor: object.senderAccentColor)
        contentView.configure(with: object)
    }

    func prepareForReuse() {
        contentView.onPrepareForReuse()
    }

    @objc
    func onTap() {
        delegate?.perform(action: .openQuote, for: message!, view: self)
    }

}

final class ConversationReplyCellDescription: ConversationMessageCellDescription {

    typealias View = ConversationReplyCell

    var configuration: View.Configuration

    var topMargin: CGFloat = 8
    var bottomMargin: CGFloat = 0

    let supportsActions = false
    let containsHighlightableContent: Bool = true
    let shouldAlignMessageContentForBubbles: Bool = true

    weak var message: ZMConversationMessage? {
        didSet {
            if let quoteMessage = message?.textMessageData?.quoteMessage {
                configuration.quotedMessage = quoteMessage
            }
            configuration.isSentBySelfUser = message?.isSentBySelfUser ?? false
            configuration.senderAccentColor = message?.senderUser?.wireAccentColor ?? .blue
        }
    }

    weak var delegate: ConversationMessageCellDelegate? {
        didSet {
            configuration.delegate = delegate
        }
    }

    weak var actionController: ConversationMessageActionController?

    let accessibilityLabel: String? = L10n.Localizable.Content.Message.originalLabel
    let accessibilityIdentifier: String? = "ReplyCell"

    init(
        quotedMessage: ZMConversationMessage?,
        accentColor: AccentColor,
        isSentBySelfUser: Bool = false,
        senderAccentColor: WireAccentColor = .blue,
        messageReplyAttachmentsViewModel: MessageReplyAttachmentsViewModel? = nil
    ) {
        self.configuration = View
            .Configuration(
                quotedMessage: quotedMessage,
                accentColor: accentColor,
                messageReplyAttachmentsViewModel: messageReplyAttachmentsViewModel,
                isSentBySelfUser: isSentBySelfUser,
                senderAccentColor: senderAccentColor
            )
    }
}

private extension ZMConversationMessage {
    var typeString: String {
        if isText {
            "text"
        } else if isLocation {
            "location"
        } else if isAudio {
            "audio"
        } else if isImage {
            "image"
        } else if isVideo {
            "video"
        } else if isFile {
            "file"
        } else {
            "unavailable"
        }
    }
}
