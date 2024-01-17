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
    struct UpdateConversationMLSWelcome: Codable {

        enum CodingKeys: String, CodingKey {
            case id = "conversation"
            case qualifiedID = "qualified_conversation"
            case from
            case qualifiedFrom = "qualified_from"
            case timestamp = "time"
            case type
            case data
        }

        // This is currently the id of the self conversation.
        let id: UUID

        let qualifiedID: QualifiedID?
        let from: UUID
        let qualifiedFrom: QualifiedID?
        let timestamp: Date
        let type: String
        let data: String
    }
}
