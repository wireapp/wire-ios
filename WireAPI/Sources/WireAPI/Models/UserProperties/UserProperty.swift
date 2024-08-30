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

/// A persisted property stored on the server used to
/// share self user settings across devices.

public enum UserProperty: Equatable, Codable {

    /// Whether the self user has enabled read receipts.

    case areReadReceiptsEnabled(Bool)

    /// Whether the self user has enabled typing indicators.

    case areTypingIndicatorsEnabled(Bool)

    /// The conversation labels setting.

    case conversationLabels([ConversationLabel])

    /// An unknown property.

    case unknown(key: String)

}

public extension UserProperty {

    /// The user property key.

    enum Key: String {

        /// Wire receipt mode

        case wireReceiptMode = "WIRE_RECEIPT_MODE"

        /// Wire typing indicator mode

        case wireTypingIndicatorMode = "WIRE_TYPING_INDICATOR_MODE"

        /// Labels

        case labels

    }
}
