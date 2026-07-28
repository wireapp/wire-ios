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

final class ConversationScheduledForDeletionSystemMessageCell:
    ConversationIconBasedCell<ConversationScheduledForDeletionCellDescription>,
    ConversationMessageCell {

    static var readMoreURL: URL { WireURLs.shared.learnMoreAboutAdminlessGroupPrevention }

    struct Configuration {
        let attributedText: NSAttributedString?
        var icon: UIImage?
        var iconTintColor: UIColor?
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    func setupView() {
        lineView.isHidden = true

        // Rely on `textLabel`'s own native accessibility (which exposes the embedded "Read more" link via
        // VoiceOver's link rotor) instead of treating the whole cell as one opaque element. Only one of
        // `isAccessibilityElement`/`textLabel.isAccessibilityElement` should be true at a time, otherwise
        // VoiceOver announces the content twice.
        isAccessibilityElement = false
        textLabel.isAccessibilityElement = true
    }

    func configure(with object: Configuration, animated: Bool) {
        textLabel.linkTextAttributes = [:]
        attributedText = object.attributedText
        imageView.image = object.icon
        imageView.tintColor = object.iconTintColor
    }
}

final class ConversationScheduledForDeletionCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationScheduledForDeletionSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(deletionDate: Date) {
        let formattedDate = Message.longDateFormatter.string(from: deletionDate)
        let title = L10n.Localizable.Content.System.MessageConversationScheduledForDeletion.text(
            formattedDate
        )
        let readMore = L10n.Localizable.Content.System.MessageConversationScheduledForDeletion.ReadMore.text
        let redColor = ColorTheme.Base.primary(.red)

        let text = NSAttributedString(string: title + "\n\(readMore)")
        let attributedText = NSMutableAttributedString(attributedString: text)
        attributedText.addAttribute(
            .foregroundColor,
            value: redColor,
            range: NSRange(location: 0, length: NSAttributedString(string: title).length)
        )

        let nsString = attributedText.string as NSString
        let range = nsString.range(of: readMore)

        if range.location != NSNotFound {
            let linkAttributes: [NSAttributedString.Key: AnyObject] = [
                .font: UIFont.mediumSemiboldFont,
                .foregroundColor: ColorTheme.Buttons.Secondary.onEnabled,
                .link: View.readMoreURL as AnyObject,
                .underlineStyle: NSUnderlineStyle.single.rawValue as AnyObject,
                .underlineColor: ColorTheme.Buttons.Secondary.onEnabled
            ]
            attributedText.addAttributes(linkAttributes, range: range)
        }

        let icon = UIImage(resource: .attention).withRenderingMode(.alwaysTemplate)

        self.configuration = View.Configuration(
            attributedText: attributedText,
            icon: icon,
            iconTintColor: redColor
        )
        self.accessibilityLabel = configuration.attributedText?.string
    }
}
