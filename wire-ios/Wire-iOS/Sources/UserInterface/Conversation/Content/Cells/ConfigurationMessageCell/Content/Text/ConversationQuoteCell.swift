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

import Down
import UIKit
import WireCommonComponents
import WireDataModel
import WireDesign

// MARK: - ConversationReplyContentView

final class ConversationReplyContentView: UIView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    // MARK: Internal

    typealias FileSharingRestrictions = L10n.Localizable.FeatureConfig.FileSharingRestrictions
    typealias MessagePreview = L10n.Localizable.Conversation.InputBar.MessagePreview
    struct Configuration {
        // MARK: Internal

        enum Content {
            case text(NSAttributedString)
            case imagePreview(thumbnail: PreviewableImageResource, isVideo: Bool)
        }

        var quotedMessage: ZMConversationMessage?

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

        // MARK: Private

        private func setupContent() -> Content {
            typealias LabelColors = SemanticColors.Label
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.smallSemiboldFont,
                .foregroundColor: LabelColors.textDefault,
            ]
            switch quotedMessage {
            case let message? where message.isText:
                let data = message.textMessageData!
                return .text(NSAttributedString.formatForPreview(message: data, inputMode: false))

            case let message? where message.isLocation:
                let location = message.locationMessageData!
                let imageIcon = NSTextAttachment.textAttachment(for: .locationPin, with: LabelColors.textDefault)
                let initialString = NSAttributedString(attachment: imageIcon) + "  " +
                    (location.name ?? MessagePreview.location).localizedUppercase
                return .text(initialString && attributes)

            case let message? where message.isAudio:
                let imageIcon = NSTextAttachment.textAttachment(for: .microphone, with: LabelColors.textDefault)
                let initialString = NSAttributedString(attachment: imageIcon) + "  " + MessagePreview.audio
                    .localizedUppercase
                return .text(initialString && attributes)

            case let message? where message.isImage && !message.canBeShared:
                let imageIcon = NSTextAttachment.textAttachment(for: .photo, with: LabelColors.textDefault)
                let initialString = NSAttributedString(attachment: imageIcon) + "  " + MessagePreview.image
                    .localizedUppercase
                return .text(initialString && attributes)

            case let message? where message.isImage:
                return .imagePreview(thumbnail: message.imageMessageData!.image, isVideo: false)

            case let message? where message.isVideo && !message.canBeShared:
                let imageIcon = NSTextAttachment.textAttachment(for: .camera, with: LabelColors.textDefault)
                let initialString = NSAttributedString(attachment: imageIcon) + "  " + MessagePreview.video
                    .localizedUppercase
                return .text(initialString && attributes)

            case let message? where message.isVideo:
                return .imagePreview(thumbnail: message.fileMessageData!.thumbnailImage, isVideo: true)

            case let message? where message.isFile:
                let fileData = message.fileMessageData!
                let imageIcon = NSTextAttachment.textAttachment(for: .document, with: LabelColors.textDefault)
                let initialString = NSAttributedString(attachment: imageIcon) + "  " +
                    (fileData.filename ?? MessagePreview.file).localizedUppercase
                return .text(initialString && attributes)

            default:
                let attributes: [NSAttributedString.Key: AnyObject] = [
                    .font: UIFont.mediumFont.italic,
                    .foregroundColor: LabelColors
                        .textCollectionSecondary,
                ]
                return .text(NSAttributedString(
                    string: L10n.Localizable.Content.Message.Reply.brokenMessage,
                    attributes: attributes
                ))
            }
        }
    }

    let numberOfLinesLimit = 4

    let senderComponent = SenderNameCellComponent()
    let contentTextView = UITextView()
    let timestampLabel = UILabel()
    let restrictionLabel = UILabel()
    let assetThumbnail = ImageResourceThumbnailView()

    let stackView = UIStackView()

    func configure(with object: Configuration) {
        senderComponent.isHidden = !object.showDetails
        timestampLabel.isHidden = !object.showDetails
        restrictionLabel.isHidden = !object.showRestriction

        senderComponent.senderName = object.senderName
        senderComponent.indicatorIcon = object.isEdited ? StyleKitIcon.pencil.makeImage(
            size: 8,
            color: SemanticColors.Icon
                .foregroundDefault
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

        case let .imagePreview(resource, isVideo):
            assetThumbnail.setResource(resource, isVideoPreview: isVideo)
            assetThumbnail.isHidden = false
            assetThumbnail.accessibilityIdentifier = object.contentType
            assetThumbnail.isAccessibilityElement = true
            contentTextView.isHidden = true
            contentTextView.isAccessibilityElement = false
        }
    }

    // MARK: Private

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
            contentTextView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
    }
}

// MARK: - ConversationReplyCell

final class ConversationReplyCell: UIView, ConversationMessageCell {
    // MARK: Lifecycle

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

    // MARK: Internal

    typealias Configuration = ConversationReplyContentView.Configuration

    var isSelected = false

    let contentView: ConversationReplyContentView
    var container: ReplyRoundCornersView

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?

    func configure(with object: Configuration, animated: Bool) {
        contentView.configure(with: object)
    }

    @objc
    func onTap() {
        delegate?.perform(action: .openQuote, for: message!, view: self)
    }

    // MARK: Private

    private func configureSubviews() {
        container.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        addSubview(container)
    }

    private func configureConstraints() {
        container.translatesAutoresizingMaskIntoConstraints = false
        container.fitIn(view: self)
    }
}

// MARK: - ConversationReplyCellDescription

final class ConversationReplyCellDescription: ConversationMessageCellDescription {
    // MARK: Lifecycle

    init(quotedMessage: ZMConversationMessage?) {
        self.configuration = View.Configuration(quotedMessage: quotedMessage)
    }

    // MARK: Internal

    typealias View = ConversationReplyCell

    let configuration: View.Configuration

    var showEphemeralTimer = false
    var topMargin: Float = 8
    let isFullWidth = false
    let supportsActions = false
    let containsHighlightableContent = true

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    let accessibilityLabel: String? = L10n.Localizable.Content.Message.originalLabel
    let accessibilityIdentifier: String? = "ReplyCell"
}

extension ZMConversationMessage {
    fileprivate var typeString: String {
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
