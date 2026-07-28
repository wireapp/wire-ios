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

public enum ConversationRemoveParticipantError: Error, Equatable {
    case unknown
    case invalidOperation
    case conversationNotFound
    case failedToRemoveMLSMembers
    // Otherwise, the conversation would be left without an admin.
    case requiresAdmin([EligibleMember])

    public static func == (lhs: ConversationRemoveParticipantError, rhs: ConversationRemoveParticipantError) -> Bool {
        switch (lhs, rhs) {
        case let (.requiresAdmin(eligibleMembers1), .requiresAdmin(eligibleMembers2)):
            eligibleMembers1 == eligibleMembers2
        case (.conversationNotFound, .conversationNotFound):
            true
        case (.failedToRemoveMLSMembers, .failedToRemoveMLSMembers):
            true
        case (.invalidOperation, .invalidOperation):
            true
        default:
            false
        }
    }
}

public class RemoveParticipantAction: EntityAction {
    public var resultHandler: ResultHandler?

    public typealias Result = Void
    public typealias Failure = ConversationRemoveParticipantError

    public let userID: NSManagedObjectID
    public let conversationID: NSManagedObjectID

    public required init(user: ZMUser, conversation: ZMConversation) {
        self.userID = user.objectID
        self.conversationID = conversation.objectID
    }
}

public extension ConversationRemoveParticipantError {
    struct EligibleMember: Equatable {
        public let id: UUID
        public let domain: String

        public init?(payload: [AnyHashable: Any]) {
            guard
                let id = payload["id"] as? String,
                let uuid = UUID(uuidString: id),
                let domain = payload["domain"] as? String
            else { return nil }

            self.id = uuid
            self.domain = domain
        }
    }
}
