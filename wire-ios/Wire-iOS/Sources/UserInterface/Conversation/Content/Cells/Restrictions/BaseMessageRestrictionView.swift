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

// MARK: - BaseMessageRestrictionView

class BaseMessageRestrictionView: UIView {
    // MARK: Lifecycle

    init(messageType: RestrictedMessageType) {
        self.messageType = messageType
        super.init(frame: .zero)

        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    // MARK: - Properties

    let topLabel = UILabel()
    let bottomLabel = UILabel()
    let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = SemanticColors.Icon.foregroundDefault
        return imageView
    }()

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 56)
    }

    // MARK: - Helpers

    func setupViews() {
        backgroundColor = SemanticColors.View.backgroundCollectionCell
        setupLabels()
        setupIconView()
    }

    func setupLabels() {
        topLabel.numberOfLines = 1
        topLabel.lineBreakMode = .byTruncatingMiddle
        topLabel.accessibilityIdentifier = "\(messageType.rawValue) + MessageRestrictionTopLabel"

        bottomLabel.numberOfLines = 1
        bottomLabel.accessibilityIdentifier = "\(messageType.rawValue) + MessageRestrictionBottomLabel"
    }

    func setupIconView() {
        iconView.contentMode = .center
        iconView.accessibilityIdentifier = "\(messageType.rawValue) + MessageRestrictionIcon"
    }

    /// Override this method to provide a different view.
    func createConstraints() {
        topLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
    }

    func configure() {
        iconView.setTemplateIcon(messageType.icon, size: messageType.iconSize)

        let titleString = messageType.title.localizedUppercase && .smallSemiboldFont && SemanticColors.Label.textDefault
        let subtitleString = messageType.subtitle.localizedUppercase && .smallLightFont && SemanticColors.Label
            .textCollectionSecondary
        topLabel.attributedText = titleString
        bottomLabel.attributedText = subtitleString
    }

    // MARK: Private

    private var messageType: RestrictedMessageType {
        didSet {
            configure()
        }
    }
}

// MARK: - RestrictedMessageType

enum RestrictedMessageType: String {
    case audio
    case video
    case image
    case file

    // MARK: Internal

    var icon: StyleKitIcon {
        switch self {
        case .audio:
            .microphone
        case .video:
            .play
        case .image:
            .photo
        case .file:
            .document
        }
    }

    var iconSize: StyleKitIcon.Size {
        switch self {
        case .audio, .file:
            .small
        case .video, .image:
            .tiny
        }
    }

    var title: String {
        typealias MessagePreview = L10n.Localizable.Conversation.InputBar.MessagePreview
        switch self {
        case .audio:
            return MessagePreview.audio
        case .video:
            return MessagePreview.video
        case .image:
            return MessagePreview.image
        case .file:
            return MessagePreview.file
        }
    }

    var subtitle: String {
        typealias FileSharingRestrictions = L10n.Localizable.FeatureConfig.FileSharingRestrictions
        switch self {
        case .audio:
            return FileSharingRestrictions.audio
        case .video:
            return FileSharingRestrictions.video
        case .image:
            return FileSharingRestrictions.picture
        case .file:
            return FileSharingRestrictions.file
        }
    }
}
