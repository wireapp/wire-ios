//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireDataModel

// MARK: - Data Source

/**
 * An object that determines what details to display for the given message.
 */

class ConversationSenderMessageDetailsDataSource {

    /// The displayed message.
    let message: ZMConversationMessage

    // MARK: - Initialization

    /// Creates a message details data source for the given message.
    init(message: ZMConversationMessage) {
        self.message = message
    }

    /// Creates the timestamp text.
    func timestampString(_ message: ZMConversationMessage) -> String? {
        let timestampString: String?

        if let dateTimeString = message.formattedReceivedDate() {
            timestampString = dateTimeString
        } else {
            timestampString = .none
        }

        return timestampString
    }

}
