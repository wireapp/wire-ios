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

public import Foundation

/// Represents a conversation associated with a meeting
public struct Conversation: Equatable, Sendable {

    /// The unique identifier of the conversation
    public let id: UUID

    /// The conversation's name
    public let name: String?

    /// The conversation's participants
    public let members: Members

    public init(
        id: UUID,
        name: String? = nil,
        members: Members
    ) {
        self.id = id
        self.name = name
        self.members = members
    }
}

public extension Conversation {

    /// Represents all conversation's members including self
    struct Members: Equatable, Sendable {

        /// The participants excluding the self user
        public let others: [Member]

        /// The self user
        public let selfMember: Member?

        public init(
            others: [Member],
            selfMember: Member? = nil
        ) {
            self.others = others
            self.selfMember = selfMember
        }

        /// All members including self
        public var all: [Member] {
            var allMembers = others
            if let selfMember {
                allMembers.append(selfMember)
            }
            return allMembers
        }

        /// Total count of all members
        public var count: Int {
            others.count + (selfMember != nil ? 1 : 0)
        }
    }

    /// Represents a conversation's member
    struct Member: Equatable, Sendable {

        /// The unique identifier of the member
        public let id: UUID

        /// The member's name
        public let name: String?

        public init(
            id: UUID,
            name: String? = nil
        ) {
            self.id = id
            self.name = name
        }
    }
}
