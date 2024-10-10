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

final class FixDuplicateOneOnOneConversationsAction: CoreDataMigrationAction {

    override func execute(in context: NSManagedObjectContext) throws {

        // 1) fetch all conversations to fix
        guard let fake1On1Conversations: [ZMConversation] = try? fakeOneOnOneConversations(context: context), !fake1On1Conversations.isEmpty else {
            return
        }

        let fakeOneOnOnePerUser = conversationsPerUser(from: fake1On1Conversations)

        for (user, conversations) in fakeOneOnOnePerUser {
            guard conversations.count > 1 else {
                // if only one conversation, nothing to fix
                continue
            }
            var sortedConversations = conversations.sorted { lhs, rhs in
                lhs.primaryKey < rhs.primaryKey
            }

            // 2) set 1:1 conversation
            let theOneOnOneConversation = sortedConversations.removeFirst()
            user.oneOnOneConversation = theOneOnOneConversation

            WireLogger.localStorage.debug("Fixing oneOnOne conversation", attributes: [.conversationId: theOneOnOneConversation.remoteIdentifier.safeForLoggingDescription])

            // 3) select all messages from other conversations
            for otherConversation in sortedConversations {
                moveMessages(from: otherConversation, to: theOneOnOneConversation)
            }
        }
    }

    private func conversationsPerUser(from conversations: [ZMConversation]) -> [ZMUser: [ZMConversation]] {
        var fakeOnOnOnePerUser = [ZMUser: [ZMConversation]]()
        for conversation in conversations {
            if let otherUser = conversation.localParticipantsExcludingSelf.first {
                if fakeOnOnOnePerUser[otherUser] == nil {
                    fakeOnOnOnePerUser[otherUser] = [conversation]
                } else {
                    fakeOnOnOnePerUser[otherUser]?.append(conversation)
                }

            }
        }
        return fakeOnOnOnePerUser
    }

    private func moveMessages(from otherConversation: ZMConversation,
                              to theOneOnOneConversation: ZMConversation) {
        otherConversation.allMessages.forEach { message in

            // 4) set them to conversation 1:1
            if message.visibleInConversation != nil {
                message.visibleInConversation = theOneOnOneConversation
            }
            if message.hiddenInConversation != nil {
                message.hiddenInConversation = theOneOnOneConversation
            }
        }

        // get the draft message if available and none present
        if theOneOnOneConversation.draftMessageData == nil {
            theOneOnOneConversation.draftMessageData = otherConversation.draftMessageData
        }
        if theOneOnOneConversation.draftMessageNonce == nil {
            theOneOnOneConversation.draftMessageNonce = otherConversation.draftMessageNonce
        }
    }

    private func fakeOneOnOneConversations(context: NSManagedObjectContext) throws -> [ZMConversation] {
        // Look for an existing "fake" one on one team conversation,
        // a special group conversation pretending to be a one on one.
        let request = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())

        // We consider a conversation being an existing 1:1 team conversation in case the following points are true:
        //  1. It is a conversation inside the team
        //  2. The only participants are the current user and the selected user
        //  3. It does not have a custom display name
        let selfUser = ZMUser.selfUser(in: context)

        guard let selfTeam = selfUser.team else {
            return []
        }
        let sameTeam = NSPredicate(format: "team == %@", selfTeam)
        let groupConversation = NSPredicate(format: "%K == %d", ZMConversationConversationTypeKey, ZMConversationType.group.rawValue)
        let noUserDefinedName = NSPredicate(format: "%K == NULL", ZMConversationUserDefinedNameKey)
        let sameParticipant = NSPredicate(
            format: "%K.@count == 2 AND ANY %K.user == %@",
            ZMConversationParticipantRolesKey,
            ZMConversationParticipantRolesKey,
            selfUser
        )

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            sameTeam,
            groupConversation,
            noUserDefinedName,
            sameParticipant
        ])

        //  4. sort by their fully qualified conversation ID in ascending oder, and use the first one.
        // primary_key is basically the qualified id
        request.sortDescriptors = [NSSortDescriptor(key: "primaryKey", ascending: true)]

        return try context.fetch(request)
    }
}
