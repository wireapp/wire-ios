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
import WireDataModel
import WireDesign

/// Tells the user that the device is offline and their messages are sent once it's online again.
final class ConversationOfflineNoticeCell:
    ConversationIconBasedCell<ConversationOfflineNoticeCellDescription>,
    ConversationMessageCell {

    struct Configuration {
        let attributedText: NSAttributedString
        let icon: UIImage?
        let iconTintColor: UIColor
    }

    private var unscaledAttributedText: NSAttributedString?

    override init(frame: CGRect) {
        super.init(frame: frame)
        lineView.isHidden = true
        isAccessibilityElement = true
        accessibilityTraits = .staticText
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    func configure(with object: Configuration, animated: Bool) {
        unscaledAttributedText = object.attributedText
        updateAttributedText()
        imageView.image = object.icon
        imageView.tintColor = object.iconTintColor
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            updateAttributedText()
        }
    }

    private func updateAttributedText() {
        guard let unscaledAttributedText else { return }
        let scaledText = NSMutableAttributedString(attributedString: unscaledAttributedText)
        let metrics = UIFontMetrics(forTextStyle: .subheadline)
        unscaledAttributedText.enumerateAttribute(
            .font,
            in: NSRange(location: 0, length: unscaledAttributedText.length)
        ) { value, range, _ in
            guard let font = value as? UIFont else { return }
            scaledText.addAttribute(
                .font,
                value: metrics.scaledFont(for: font, compatibleWith: self.traitCollection),
                range: range
            )
        }
        attributedText = scaledText
    }
}

final class ConversationOfflineNoticeCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationOfflineNoticeCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = "offline_notice"
    let accessibilityLabel: String?

    init() {
        typealias Strings = L10n.Localizable.Content.System.OfflineNotice

        let textColor = SemanticColors.Label.textDefault
        let attributedText = NSMutableAttributedString(
            string: Strings.title,
            attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .semibold), .foregroundColor: textColor]
        )
        attributedText.append(NSAttributedString(
            string: " " + Strings.message,
            attributes: [.font: UIFont.systemFont(ofSize: 14, weight: .regular), .foregroundColor: textColor]
        ))

        self.configuration = View.Configuration(
            attributedText: attributedText,
            icon: UIImage(systemName: "wifi.exclamationmark")?.withRenderingMode(.alwaysTemplate),
            iconTintColor: ColorTheme.Base.primary(.red)
        )
        self.accessibilityLabel = attributedText.string
    }
}
