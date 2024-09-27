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
import WireTransport

extension Payload {
    struct UpdateConverationMemberLeave: CodableEventData {
        enum Reason: String, Codable {
            /// The user has been removed from the team and therefore removed from all conversations.
            case userDeleted = "user-deleted"
            case left
            case removed
        }

        enum CodingKeys: String, CodingKey {
            case userIDs = "user_ids"
            case qualifiedUserIDs = "qualified_user_ids"
            case reason
        }

        static var eventType: ZMUpdateEventType { .conversationMemberLeave }

        let userIDs: [UUID]?
        let qualifiedUserIDs: [QualifiedID]?
        let reason: Reason?
    }
}
