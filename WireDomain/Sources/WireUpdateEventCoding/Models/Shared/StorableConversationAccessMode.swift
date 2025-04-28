//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireAPI

enum StorableConversationAccessMode: String, Equatable, Codable, Sendable {

    case `private`
    case invite
    case link
    case code

    init(_ value: WireAPI.ConversationAccessMode) {
        switch value {
        case .private:
            self = .private
        case .invite:
            self = .invite
        case .link:
            self = .link
        case .code:
            self = .code
        }
    }

    func toAPIModel() -> WireAPI.ConversationAccessMode {
        switch self {
        case .private:
            return .private
        case .invite:
            return .invite
        case .link:
            return .link
        case .code:
            return .code
        }
    }

}
