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
import WireDataModel

/**
 * The description of a cell for message details.
 * - note: This class needs to be NSCopying to be used in an ordered set for diffing.
 */

final class MessageDetailsCellDescription: NSObject {

    /// The user to display.
    let user: UserType

    /// The subtitle string to display under the user name.
    let subtitle: String?

    /// The attributed string for the subtitle.
    let attributedSubtitle: NSAttributedString?

    /// The label of the subtitle.
    let accessibleSubtitleLabel: String?

    /// The value of the subtitle.
    let accessibleSubtitleValue: String?

    // MARK: - Initialization

    /// Creates a new cell description.
    init(user: UserType, subtitle: String?, accessibleSubtitleLabel: String?, accessibleSubtitleValue: String?) {
        self.user = user
        self.subtitle = subtitle
        self.attributedSubtitle = subtitle.map { $0 && UserCell.boldFont.font! }
        self.accessibleSubtitleLabel = accessibleSubtitleLabel
        self.accessibleSubtitleValue = accessibleSubtitleValue
    }
}

// MARK: - Helpers

extension MessageDetailsCellDescription {

    typealias MessageDetails = L10n.Localizable.MessageDetails

    static func makeReactionCells(_ users: [UserType]) -> [MessageDetailsCellDescription] {
        return users.map {
            let handle = $0.handle.map { "@" + $0 }
            return MessageDetailsCellDescription(user: $0, subtitle: handle,
                                                 accessibleSubtitleLabel: MessageDetails.userHandleSubtitleLabel,
                                                 accessibleSubtitleValue: $0.handle)
        }
    }

    static func makeReceiptCell(_ receipts: [ReadReceipt]) -> [MessageDetailsCellDescription] {
        return receipts.map {
            let formattedDate = $0.serverTimestamp.map(Message.shortDateTimeFormatter.string)
            let formattedAccessibleDate = $0.serverTimestamp.map(Message.spellOutDateTimeFormatter.string)

            return MessageDetailsCellDescription(user: $0.userType, subtitle: formattedDate,
                                                 accessibleSubtitleLabel: MessageDetails.userReadTimestampSubtitleLabel,
                                                 accessibleSubtitleValue: formattedAccessibleDate)
        }
    }
}
