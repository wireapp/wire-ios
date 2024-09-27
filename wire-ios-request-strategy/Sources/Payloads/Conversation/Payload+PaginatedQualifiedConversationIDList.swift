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

extension Payload {
    struct PaginatedQualifiedConversationIDList: Codable, Paginatable {
        enum CodingKeys: String, CodingKey {
            case conversations = "qualified_conversations"
            case pagingState = "paging_state"
            case hasMore = "has_more"
        }

        let conversations: [QualifiedID]
        let pagingState: String
        let hasMore: Bool

        var nextStartReference: String? {
            pagingState
        }
    }
}
