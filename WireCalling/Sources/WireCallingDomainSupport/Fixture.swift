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

package import Foundation
package import WireCallingDomain

package extension Meeting {

    static func fixture(
        id: UUID = UUID(),
        title: String,
        start: Date,
        duration: TimeInterval = 3600,
        conversation: Conversation? = nil
    ) -> Meeting {
        let defaultConversation = conversation ?? Conversation(
            id: UUID(),
            name: title,
            members: Conversation.Members(
                others: [
                    Conversation.Member(id: UUID(), name: "Alice"),
                    Conversation.Member(id: UUID(), name: "Bob"),
                    Conversation.Member(id: UUID(), name: "Charlie")
                ],
                selfMember: Conversation.Member(id: UUID(), name: "You")
            )
        )

        return Meeting(
            id: id,
            title: title,
            start: start,
            end: start.addingTimeInterval(duration),
            conversation: defaultConversation
        )
    }

}
