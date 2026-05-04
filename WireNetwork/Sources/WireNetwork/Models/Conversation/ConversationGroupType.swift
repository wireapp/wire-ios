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

public enum ConversationGroupType: Sendable {
    case group
    case channel
}

enum ConversationGroupTypeV8: String, Sendable, Codable, ToAPIModelConvertible {
    case group = "group_conversation"
    case channel

    func toAPIModel() -> ConversationGroupType {
        switch self {
        case .group:
            .group
        case .channel:
            .channel
        }
    }
}

extension ConversationGroupType: ToNetworkConvertible {
    func toNetworkModel() -> ConversationGroupTypeV8 {
        switch self {
        case .group:
            .group
        case .channel:
            .channel
        }
    }
}
