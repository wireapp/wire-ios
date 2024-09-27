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

enum AvailabilityStringBuilder {
    // MARK: Internal

    static func titleForUser(
        name: String,
        availability: Availability,
        isE2EICertified: Bool,
        isProteusVerified: Bool,
        appendYouSuffix: Bool,
        style: AvailabilityLabelStyle,
        color: UIColor? = nil
    ) -> NSAttributedString? {
        let fallbackTitle = L10n.Localizable.Profile.Details.Title.unavailable
        var title: String
        var color = color
        var iconColor = color
        var fontSize: FontSize = .small

        switch style {
        case .list:
            do {
                if !name.isEmpty {
                    title = name
                } else {
                    title = fallbackTitle
                    color = SemanticColors.Label.textCollectionSecondary
                }

                fontSize = .normal

                if color == nil {
                    color = SemanticColors.Label.textDefault
                }
                iconColor = self.color(for: availability)
            }

        case .participants:
            do {
                title = name.localizedUppercase
                color = SemanticColors.Label.textDefault
                iconColor = self.color(for: availability)
            }
        }

        let youSuffix = L10n.Localizable.UserCell.Title.youSuffix
        if appendYouSuffix {
            title += youSuffix
        }

        guard let textColor = color, let iconColor else {
            return nil
        }
        let icon = AvailabilityStringBuilder.icon(for: availability, with: iconColor, and: fontSize)
        var attributedText = IconStringsBuilder.iconString(
            leadingIcons: [icon].compactMap { $0 },
            title: title,
            trailingIcons: [
                isE2EICertified ? e2eiCertifiedShield : nil,
                isProteusVerified ? proteusVerifiedShield : nil,
            ].compactMap { $0 },
            interactive: false,
            color: textColor
        )
        if appendYouSuffix {
            attributedText = attributedText.setAttributes(
                [.foregroundColor: SemanticColors.Label.textYouSuffix],
                toSubstring: youSuffix
            )
        }
        return attributedText
    }

    static func icon(for availability: Availability, with color: UIColor, and size: FontSize) -> NSTextAttachment? {
        guard availability != .none, let iconType = availability.iconType
        else {
            return nil
        }

        let verticalCorrection: CGFloat =
            switch size {
            case .small:
                -1
            case .body,
                 .bodyTwo,
                 .buttonBig,
                 .buttonSmall,
                 .header,
                 .large,
                 .medium,
                 .normal,
                 .subHeadline,
                 .titleThree:
                0
            }

        return NSTextAttachment.textAttachment(
            for: iconType,
            with: color,
            iconSize: 12,
            verticalCorrection: verticalCorrection
        )
    }

    static func color(for availability: Availability) -> UIColor {
        typealias IconColors = SemanticColors.Icon

        switch availability {
        case .none:
            return UIColor.clear
        case .available:
            return IconColors.foregroundAvailabilityAvailable
        case .busy:
            return IconColors.foregroundAvailabilityBusy
        case .away:
            return IconColors.foregroundAvailabilityAway
        }
    }

    // MARK: Private

    private static var e2eiCertifiedShield: NSTextAttachment {
        let textAttachment = NSTextAttachment(imageResource: .certificateValid)
        if let imageSize = textAttachment.image?.size {
            textAttachment.bounds = .init(origin: .init(x: 0, y: -1.5), size: imageSize)
        }
        return textAttachment
    }

    private static var proteusVerifiedShield: NSTextAttachment {
        let textAttachment = NSTextAttachment(imageResource: .verifiedShield)
        if let imageSize = textAttachment.image?.size {
            textAttachment.bounds = .init(origin: .init(x: 0, y: -1.5), size: imageSize)
        }
        return textAttachment
    }
}
