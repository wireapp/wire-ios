//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

import SwiftUI
import WireDataModel
import WireCommonComponents

final class AvailabilityStringBuilder: NSObject {

    static func titleForUser(
        name: String,
        availability: Availability,
        isCertified: Bool /*= false*/,
        isVerified: Bool /*= false*/,
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

        guard let textColor = color, let iconColor = iconColor else { return nil }
        let icon = AvailabilityStringBuilder.icon(for: availability, with: iconColor, and: fontSize)
        let attributedText = IconStringsBuilder.iconString(
            leadingIcons: [icon].compactMap(\.self),
            title: title,
            trailingIcons: [
                isCertified ? .init(imageResource: .certificateValid) : nil,
                isVerified ? .init(imageResource: .verifiedShield) : nil
            ].compactMap { $0 },
            interactive: false,
            color: textColor
        )
        return attributedText
    }

    static func icon(for availability: Availability, with color: UIColor, and size: FontSize) -> NSTextAttachment? {
        guard availability != .none, let iconType = availability.iconType
            else { return nil }

        let verticalCorrection: CGFloat

        switch size {
        case .small:
            verticalCorrection = -1
        case .medium, .large, .normal, .header, .titleThree, .subHeadline, .bodyTwo, .buttonSmall, .body, .buttonBig:
            verticalCorrection = 0
        }

        return NSTextAttachment.textAttachment(for: iconType, with: color, iconSize: 12, verticalCorrection: verticalCorrection)
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
}

#Preview {
    NavigationView {
        ScrollView {
            VStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("title(userName:availability:style:color:)")
                    Rectangle().fill(.black).frame(height: 1)
                    if let value = AvailabilityStringBuilder.titleForUser(
                        name: "Available (List)", availability: .available, isCertified: true, isVerified: true, style: .list
                    ) {
                        Text(AttributedString(value))
                    }
                    if let value = AvailabilityStringBuilder.titleForUser(
                        name: "Available (Participants)", availability: .available, isCertified: true, isVerified: true, style: .participants
                    ) {
                        Text(AttributedString(value))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("AvailabilityStringBuilder")
        .navigationBarTitleDisplayMode(.inline)
    }
}
