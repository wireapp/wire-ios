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
import WireCommonComponents
import WireDataModel
import WireDesign
import WireSyncEngine

final class ConversationLinkAttachmentCell: UIView, ConversationMessageCell, HighlightableView, ContextMenuDelegate {

    struct Configuration: Equatable {
        var attachment: LinkAttachment
        var thumbnailResource: WireImageResource?

        static func == (lhs: Configuration, rhs: Configuration) -> Bool {
            lhs.attachment == rhs.attachment &&
                lhs.thumbnailResource?.cacheIdentifier == rhs.thumbnailResource?.cacheIdentifier
        }
    }

    lazy var attachmentView: MediaPreviewView = {
        let view = MediaPreviewView()

        view.delegate = self
        view.isUserInteractionEnabled = true

        return view
    }()

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?
    weak var actionController: ConversationMessageActionController?

    var isSelected: Bool = false
    var currentAttachment: LinkAttachment?
    var attachmentViewHeightRatioConstraint: NSLayoutConstraint?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubviews() {
        isAccessibilityElement = true
        shouldGroupAccessibilityChildren = true
        accessibilityIdentifier = "link-attachment"
        accessibilityTraits = [.link]
        attachmentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(attachmentView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        attachmentView.addGestureRecognizer(tapGesture)
    }

    private func configureConstraints() {
        let widthConstraint = attachmentView.widthAnchor.constraint(equalToConstant: 414)
        widthConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            attachmentView.topAnchor.constraint(equalTo: topAnchor),
            attachmentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            attachmentView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            bottomAnchor.constraint(equalTo: attachmentView.bottomAnchor),
            widthConstraint
        ])
    }

    private func updateAspectRatio(_ heightRatio: CGFloat) {
        attachmentViewHeightRatioConstraint?.isActive = false

        let attachmentViewHeightRatioConstraint = attachmentView.heightAnchor.constraint(
            equalTo: attachmentView.widthAnchor,
            multiplier: heightRatio
        )
        attachmentViewHeightRatioConstraint.isActive = true
        self.attachmentViewHeightRatioConstraint = attachmentViewHeightRatioConstraint
    }

    // MARK: - Configuration

    func configure(with object: Configuration, animated: Bool) {
        currentAttachment = object.attachment
        attachmentView.titleLabel.text = object.attachment.title
        attachmentView.previewImageView.setImageResource(object.thumbnailResource, hideLoadingView: true)
        accessibilityValue = object.attachment.title

        switch object.attachment.type {
        case .youTubeVideo:
            updateAspectRatio(3 / 4)
            attachmentView.providerImageView.image = WireStyleKit.imageOfYoutube(color: .white)
            accessibilityLabel = L10n.Localizable.Content.Message.LinkAttachment.AccessibilityLabel.youtube

        case .soundCloudTrack:
            updateAspectRatio(1 / 1)
            attachmentView.providerImageView.image = UIImage(named: "soundcloud")
            accessibilityLabel = L10n.Localizable.Content.Message.LinkAttachment.AccessibilityLabel.soundcloudSong

        case .soundCloudPlaylist:
            updateAspectRatio(1 / 1)
            attachmentView.providerImageView.image = UIImage(named: "soundcloud")
            accessibilityLabel = L10n.Localizable.Content.Message.LinkAttachment.AccessibilityLabel.soundcloudSet
        }
    }

    // MARK: - HighlightableView

    var highlightContainer: UIView {
        attachmentView
    }

    // MARK: - Events

    @objc
    private func handleTapGesture() {
        currentAttachment?.permalink.open()
    }

}

extension ConversationLinkAttachmentCell: LinkViewDelegate {
    var url: URL? {
        currentAttachment?.permalink
    }
}

final class ConversationLinkAttachmentCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationLinkAttachmentCell

    var configuration: View.Configuration

    weak var message: ZMConversationMessage? {
        didSet {
            if let message, let attachment = message.linkAttachments?.first {
                configuration.thumbnailResource = message.linkAttachmentImage
                configuration.attachment = attachment
            }
        }
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    let supportsActions: Bool = true
    let containsHighlightableContent: Bool = true
    let shouldAlignMessageContentForBubbles: Bool = true

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init(
        attachment: LinkAttachment,
        thumbnailResource: WireImageResource?
    ) {
        self.configuration = View.Configuration(
            attachment: attachment,
            thumbnailResource: thumbnailResource
        )
        self.actionController = nil
    }
}
