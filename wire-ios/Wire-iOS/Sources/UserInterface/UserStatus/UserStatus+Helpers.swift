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

extension UserStatus {

    func title(
        color: UIColor,
        includeAvailability: Bool,
        includeVerificationStatus: Bool,
        appendYouSuffix: Bool
    ) -> NSAttributedString? {

        // TODO [WPB-765]: actually the "(You)" suffix should be drawn in gray.
        let name = name + (appendYouSuffix ? L10n.Localizable.UserCell.Title.youSuffix : "")

        if includeAvailability || includeVerificationStatus {
            return AvailabilityStringBuilder.titleForUser(
                name: name,
                availability: includeAvailability ? availability : .none,
                isCertified: includeVerificationStatus && isCertified,
                isVerified: includeVerificationStatus && isVerified,
                style: .list,
                color: color
            )

        } else if !name.isEmpty {
            return .init(string: name, attributes: [.foregroundColor: color])

        } else {
            let fallbackTitle = L10n.Localizable.Profile.Details.Title.unavailable
            let fallbackColor = SemanticColors.Label.textCollectionSecondary
            return .init(string: fallbackTitle, attributes: [.foregroundColor: fallbackColor])
        }
    }
}
