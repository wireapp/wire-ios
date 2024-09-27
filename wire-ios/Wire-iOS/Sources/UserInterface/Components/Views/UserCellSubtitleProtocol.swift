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

import Foundation
import WireCommonComponents
import WireDataModel
import WireDesign

// MARK: - UserCellSubtitleProtocol

protocol UserCellSubtitleProtocol: AnyObject {
    func subtitle(forRegularUser user: UserType?) -> NSAttributedString?

    static var boldFont: FontSpec { get }
    static var lightFont: FontSpec { get }
}

extension UserCellSubtitleProtocol where Self: UIView {
    func subtitle(forRegularUser user: UserType?) -> NSAttributedString? {
        guard let user else {
            return nil
        }

        var components: [NSAttributedString?] = []

        if let handle = user.handleDisplayString(withDomain: user.isFederated), !handle.isEmpty {
            components.append(handle && UserCell.boldFont.font!)
        } else if let domain = user.domainString, !domain.isEmpty {
            components.append(domain && UserCell.boldFont.font!)
        }

        WirelessExpirationTimeFormatter.shared.string(for: user).map {
            components.append($0 && UserCell.boldFont.font!)
        }

        if let user = user as? ZMUser, let addressBookName = user.addressBookEntry?.cachedName {
            let color = SemanticColors.Label.textDefault
            let formatter = AddressBookCorrelationFormatter(
                lightFont: Self.lightFont,
                boldFont: Self.boldFont,
                color: color
            )
            components.append(formatter.correlationText(for: user, addressBookName: addressBookName))
        }

        return components.compactMap { $0 }
            .joined(separator: " " + String.MessageToolbox.middleDot + " " && UserCell.lightFont.font!)
    }
}
