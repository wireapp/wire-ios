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

public enum ConversationAddParticipantsError: Error, Equatable {
    case unknown
    case invalidOperation
    case accessDenied
    case notConnectedToUser
    case conversationNotFound
    case tooManyMembers
    case missingLegalHoldConsent
    case failedToAddMLSMembers
    case unreachableDomains(Set<String>)
    case nonFederatingDomains(Set<String>)
}

public class AddParticipantAction: EntityAction {
    public var resultHandler: ResultHandler?

    public typealias Result = Void
    public typealias Failure = ConversationAddParticipantsError

    public let userIDs: [NSManagedObjectID]
    public let conversationID: NSManagedObjectID

    public required init(users: [ZMUser], conversation: ZMConversation) {
        self.userIDs = users.map(\.objectID)
        self.conversationID = conversation.objectID
    }
}
