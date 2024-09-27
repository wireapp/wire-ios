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
import WireDataModel
import WireDesign
import WireSyncEngine

extension ZMConversationMessage {
    func replyPreview() -> UIView? {
        guard canBeQuoted else {
            return nil
        }
        return preparePreviewView()
    }

    func preparePreviewView(shouldDisplaySender: Bool = true) -> UIView {
        if isImage || isVideo {
            MessageThumbnailPreviewView(message: self, displaySender: shouldDisplaySender)
        } else {
            MessagePreviewView(message: self, displaySender: shouldDisplaySender)
        }
    }
}

extension UITextView {
    fileprivate static func previewTextView() -> UITextView {
        let textView = UITextView()
        textView.textContainer.lineBreakMode = .byTruncatingTail
        textView.textContainer.maximumNumberOfLines = 1
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero

        textView.isEditable = false
        textView.isSelectable = true

        textView.backgroundColor = .clear
        textView.textColor = SemanticColors.SearchBar.textInputView

        textView.setContentCompressionResistancePriority(.required, for: .vertical)

        return textView
    }
}

// MARK: - MessageThumbnailPreviewView

final class MessageThumbnailPreviewView: UIView {
    // MARK: Lifecycle

    init(message: ZMConversationMessage, displaySender: Bool = true) {
        require(message.canBeQuoted || !displaySender)
        require(message.conversationLike != nil)
        self.message = message
        self.displaySender = displaySender
        super.init(frame: .zero)
        setupSubviews()
        setupConstraints()
        setupMessageObserver()
        updateForMessage()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let message: ZMConversationMessage

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else {
            return
        }
        updateForMessage()
    }

    // MARK: Private

    private static let thumbnailSize: CGFloat = 42

    private let senderLabel = UILabel()
    private var leftEditIconInset: CGFloat = 10
    private let contentTextView = UITextView.previewTextView()
    private let imagePreview = ImageResourceView()
    private var observerToken: Any?
    private let displaySender: Bool
    private let iconColor = SemanticColors.Icon.foregroundDefault

    private func setupMessageObserver() {
        if let userSession = ZMUserSession.shared() {
            observerToken = MessageChangeInfo.add(
                observer: self,
                for: message,
                userSession: userSession
            )
        }
    }

    private func setupSubviews() {
        var allViews: [UIView] = [contentTextView, imagePreview]

        if displaySender {
            allViews.append(senderLabel)
            senderLabel.font = FontSpec.mediumSemiboldFont.font!
            senderLabel.textColor = SemanticColors.Label.textDefault
            senderLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            senderLabel.isAccessibilityElement = true
            senderLabel.accessibilityIdentifier = "SenderLabel_ReplyPreview"
        }

        imagePreview.clipsToBounds = true
        imagePreview.contentMode = .scaleAspectFill
        imagePreview
            .imageSizeLimit = .maxDimensionForShortSide(MessageThumbnailPreviewView.thumbnailSize * UIScreen.main.scale)
        imagePreview.layer.cornerRadius = 4
        imagePreview.isAccessibilityElement = true
        imagePreview.accessibilityIdentifier = "ThumbnailImage_ReplyPreview"
        for view in allViews {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
    }

    private func setupConstraints() {
        let inset: CGFloat = 12

        NSLayoutConstraint.activate([
            contentTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            contentTextView.trailingAnchor.constraint(equalTo: imagePreview.leadingAnchor, constant: inset),
            imagePreview.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            imagePreview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset),
            imagePreview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            imagePreview.widthAnchor.constraint(equalToConstant: MessageThumbnailPreviewView.thumbnailSize),
            imagePreview.heightAnchor.constraint(equalToConstant: MessageThumbnailPreviewView.thumbnailSize),
        ])

        if displaySender {
            NSLayoutConstraint.activate([
                senderLabel.topAnchor.constraint(equalTo: topAnchor, constant: inset),
                senderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
                senderLabel.trailingAnchor.constraint(equalTo: imagePreview.leadingAnchor, constant: inset),
                contentTextView.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: inset),
                contentTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset),
            ])
        } else {
            contentTextView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        }
    }

    private func editIcon() -> NSAttributedString {
        if message.updatedAt != nil {
            NSAttributedString(
                attachment: NSTextAttachment.textAttachment(
                    for: .pencil,
                    with: iconColor,
                    iconSize: 8,
                    insets: UIEdgeInsets(
                        top: 0,
                        left: leftEditIconInset,
                        bottom: 0,
                        right: 0
                    )
                )
            )
        } else {
            NSAttributedString()
        }
    }

    private func updateForMessage() {
        typealias MessagePreview = L10n.Localizable.Conversation.InputBar.MessagePreview
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.smallSemiboldFont,
            .foregroundColor: SemanticColors.Label.textDefault,
        ]

        senderLabel.attributedText = (message.senderName && attributes) + editIcon()
        imagePreview.isHidden = !message.canBeShared

        if message.isImage {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.smallSemiboldFont,
                .foregroundColor: SemanticColors.Label.textDefault,
            ]
            let imageIcon = NSTextAttachment.textAttachment(for: .photo, with: iconColor, verticalCorrection: -1)
            let initialString = NSAttributedString(attachment: imageIcon) + "  " + MessagePreview.image
                .localizedUppercase
            contentTextView.attributedText = initialString && attributes

            if let imageResource = message.imageMessageData?.image {
                imagePreview.setImageResource(imageResource)
            }
        } else if message.isVideo, let fileMessageData = message.fileMessageData {
            let imageIcon = NSTextAttachment.textAttachment(for: .camera, with: iconColor, verticalCorrection: -1)
            let initialString = NSAttributedString(attachment: imageIcon) + "  " + MessagePreview.video
                .localizedUppercase
            contentTextView.attributedText = initialString && attributes

            imagePreview.setImageResource(fileMessageData.thumbnailImage)
        } else {
            fatal("Unknown message for preview: \(message)")
        }
    }
}

// MARK: ZMMessageObserver

extension MessageThumbnailPreviewView: ZMMessageObserver {
    func messageDidChange(_: MessageChangeInfo) {
        guard !message.hasBeenDeleted else {
            return // Deleted message won't have any content
        }

        updateForMessage()
    }
}

// MARK: - MessagePreviewView

final class MessagePreviewView: UIView {
    // MARK: Lifecycle

    init(message: ZMConversationMessage, displaySender: Bool = true) {
        require(message.canBeQuoted || !displaySender)
        require(message.conversationLike != nil)
        self.message = message
        self.displaySender = displaySender
        super.init(frame: .zero)
        setupSubviews()
        setupConstraints()
        setupMessageObserver()
        updateForMessage()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let message: ZMConversationMessage

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else {
            return
        }
        updateForMessage()
    }

    // MARK: Private

    private let senderLabel = UILabel()
    private var leftEditIconInset: CGFloat = 10
    private let contentTextView = UITextView.previewTextView()
    private var observerToken: Any?
    private let displaySender: Bool
    private let iconColor = SemanticColors.Icon.foregroundDefault

    private func setupMessageObserver() {
        if let userSession = ZMUserSession.shared() {
            observerToken = MessageChangeInfo.add(
                observer: self,
                for: message,
                userSession: userSession
            )
        }
    }

    private func setupSubviews() {
        var allViews: [UIView] = [contentTextView]
        if displaySender {
            allViews.append(senderLabel)
            senderLabel.font = FontSpec.mediumSemiboldFont.font!
            senderLabel.textColor = SemanticColors.Label.textDefault
            senderLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            senderLabel.isAccessibilityElement = true
            senderLabel.accessibilityIdentifier = "SenderLabel_ReplyPreview"
        }
        for view in allViews {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
    }

    private func setupConstraints() {
        let inset: CGFloat = 12

        NSLayoutConstraint.activate([
            contentTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            contentTextView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset),
            contentTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
        ])

        if displaySender {
            NSLayoutConstraint.activate([
                senderLabel.topAnchor.constraint(equalTo: topAnchor, constant: inset),
                senderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
                senderLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
                contentTextView.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: inset / 2),
            ])
        } else {
            contentTextView.topAnchor.constraint(equalTo: topAnchor, constant: inset).isActive = true
        }
    }

    private func editIcon() -> NSAttributedString {
        if message.updatedAt != nil {
            NSAttributedString(
                attachment: NSTextAttachment.textAttachment(
                    for: .pencil,
                    with: iconColor,
                    iconSize: 8,
                    insets: UIEdgeInsets(
                        top: 0,
                        left: leftEditIconInset,
                        bottom: 0,
                        right: 0
                    )
                )
            )
        } else {
            NSAttributedString()
        }
    }

    private func updateForMessage() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: FontSpec.smallSemiboldFont.font!,
            .foregroundColor: SemanticColors.Label.textDefault,
        ]

        senderLabel.attributedText = (message.senderName && attributes) + editIcon()

        if let textMessageData = message.textMessageData {
            contentTextView.attributedText = NSAttributedString.formatForPreview(
                message: textMessageData,
                inputMode: true
            )
        } else if let location = message.locationMessageData {
            let imageIcon = NSTextAttachment.textAttachment(for: .locationPin, with: iconColor, verticalCorrection: -1)
            let initialString = NSAttributedString(attachment: imageIcon) + "  " +
                (location.name ?? L10n.Localizable.Conversation.InputBar.MessagePreview.location).localizedUppercase
            contentTextView.attributedText = initialString && attributes
        } else if message.isAudio {
            let imageIcon = NSTextAttachment.textAttachment(for: .microphone, with: iconColor, verticalCorrection: -1)
            let initialString = NSAttributedString(attachment: imageIcon) + "  " + L10n.Localizable.Conversation
                .InputBar.MessagePreview.audio.localizedUppercase
            contentTextView.attributedText = initialString && attributes
        } else if let fileData = message.fileMessageData {
            let imageIcon = NSTextAttachment.textAttachment(for: .document, with: iconColor, verticalCorrection: -1)
            let initialString = NSAttributedString(attachment: imageIcon) + "  " +
                (fileData.filename ?? L10n.Localizable.Conversation.InputBar.MessagePreview.file).localizedUppercase
            contentTextView.attributedText = initialString && attributes
        }
    }
}

// MARK: ZMMessageObserver

extension MessagePreviewView: ZMMessageObserver {
    func messageDidChange(_: MessageChangeInfo) {
        updateForMessage()
    }
}
