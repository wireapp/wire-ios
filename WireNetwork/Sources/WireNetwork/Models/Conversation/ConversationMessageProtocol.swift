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

import Foundation

/// The current message protocol used in a conversation.

public enum ConversationMessageProtocol: Sendable {

    /// The Proteus messaging protocol.

    case proteus

    /// The conversation is in the process of migrating from
    /// Proteus to MLS.

    case mixed

    /// The Messaging Layer Security protocol.

    case mls

}

enum ConversationMessageProtocolV0: String, Sendable, Decodable, ToAPIModelConvertible {

    case proteus
    case mixed
    case mls

    func toAPIModel() -> ConversationMessageProtocol {
        switch self {
        case .proteus:
            .proteus
        case .mixed:
            .mixed
        case .mls:
            .mls
        }
    }
}

extension ConversationMessageProtocol: ToNetworkConvertible {
    func toNetworkModel() -> ConversationMessageProtocolV0 {
        switch self {
        case .proteus:
            .proteus
        case .mixed:
            .mixed
        case .mls:
            .mls
        }
    }
}
