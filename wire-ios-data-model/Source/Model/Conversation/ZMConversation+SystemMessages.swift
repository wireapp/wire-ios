//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

extension ZMConversation {

    public func appendSessionResetSystemMessage(user: ZMUser, client: UserClient, at timestamp: Date) {
        appendSystemMessage(type: .sessionReset,
                            sender: user,
                            users: [],
                            clients: [client],
                            timestamp: timestamp)
    }

    public func appendTeamMemberRemovedSystemMessage(user: ZMUser, at timestamp: Date) {
        appendSystemMessage(type: .teamMemberLeave,
                            sender: user,
                            users: [user],
                            clients: nil,
                            timestamp: timestamp)
    }

    public func appendParticipantRemovedSystemMessage(user: ZMUser, sender: ZMUser? = nil, at timestamp: Date) {
        appendSystemMessage(type: .participantsRemoved,
                            sender: sender ?? user,
                            users: [user],
                            clients: nil,
                            timestamp: timestamp)
    }

    public func appendParticipantsRemovedSystemMessage(users: Set<ZMUser>, sender: ZMUser, at timestamp: Date) {
        appendSystemMessage(type: .participantsRemoved,
                            sender: sender,
                            users: users,
                            clients: nil,
                            timestamp: timestamp)
    }

    public func appendFailedToAddUsersSystemMessage(users: Set<ZMUser>, sender: ZMUser, at timestamp: Date) {
        appendSystemMessage(type: .failedToAddParticipants,
                            sender: sender,
                            users: users,
                            clients: nil,
                            timestamp: timestamp.nextNearestTimestamp)
    }

    @objc(appendNewConversationSystemMessageAtTimestamp:users:)
    public func appendNewConversationSystemMessage(at timestamp: Date, users: Set<ZMUser>) {
        let systemMessage = appendSystemMessage(type: .newConversation,
                                                sender: creator,
                                                users: users,
                                                clients: nil,
                                                timestamp: timestamp)

        systemMessage.text = userDefinedName

        // Fill out team specific properties if the conversation was created in the self user team
        if let context = managedObjectContext, let selfUserTeam = ZMUser.selfUser(in: context).team, team == selfUserTeam {

            let members = selfUserTeam.members.compactMap { $0.user }
            let guests = users.filter { !$0.isServiceUser && $0.membership == nil }

            systemMessage.allTeamUsersAdded = users.isSuperset(of: members)
            systemMessage.numberOfGuestsAdded = Int16(guests.count)
        }

        if hasReadReceiptsEnabled {
            appendMessageReceiptModeIsOnMessage(timestamp: timestamp.nextNearestTimestamp)
        }
    }

    public func appendMessageTimerUpdateSystemMessage(fromUser user: ZMUser, timer: Double, timestamp: Date) {
        appendSystemMessage(type: .messageTimerUpdate,
                            sender: user,
                            users: [user],
                            clients: nil,
                            timestamp: timestamp,
                            messageTimer: timer)
    }

    @objc(appendNewPotentialGapSystemMessage:inContext:)
    static public func appendNewPotentialGapSystemMessage(at timestamp: Date?, inContext moc: NSManagedObjectContext) {
        let offset = 0.1
        var lastMessageTimestamp = timestamp
        guard let conversations = moc.executeFetchRequestOrAssert(ZMConversation.sortedFetchRequest()) as? [ZMConversation] else {
            return
        }
        for conversation in conversations {
            if lastMessageTimestamp == nil {
                // In case we did not receive a payload we will add 1/10th to the last modified date of
                // the conversation to make sure it appears below the last message
                lastMessageTimestamp = conversation.lastModifiedDate?.addingTimeInterval(offset) ?? Date()
            }
            if let timestamp = lastMessageTimestamp {
                conversation.appendNewPotentialGapSystemMessage(users: conversation.localParticipants, timestamp: timestamp)
            }
        }
    }

    public func appendParticipantsRemovedAnonymouslySystemMessage(users: Set<ZMUser>,
                                                                  sender: ZMUser,
                                                                  removedReason: ZMParticipantsRemovedReason,
                                                                  at timestamp: Date) {
        appendSystemMessage(type: .participantsRemoved,
                            sender: sender,
                            users: users,
                            clients: nil,
                            timestamp: timestamp,
                            removedReason: removedReason)
    }

    public func appendFederationTerminationSystemMessage(domains: [String], sender: ZMUser, at timestamp: Date) {
        appendSystemMessage(type: .domainsStoppedFederating,
                            sender: sender,
                            users: nil,
                            clients: nil,
                            timestamp: timestamp,
                            domains: domains)
    }

    // MARK: - MLS Migration

    public func appendMLSMigrationFinalizedSystemMessage(
        users: Set<ZMUser>,
        sender: ZMUser,
        at timestamp: Date
    ) {
        appendSystemMessage(
            type: .mlsMigrationFinalized,
            sender: sender,
            users: users,
            clients: nil,
            timestamp: timestamp
        )
    }

    public func appendMLSMigrationJoinAfterwardsSystemMessage(
        users: Set<ZMUser>,
        sender: ZMUser,
        at timestamp: Date
    ) {
        appendSystemMessage(
            type: .mlsMigrationJoinAfterwards,
            sender: sender,
            users: users,
            clients: nil,
            timestamp: timestamp
        )
    }

    public func appendMLSMigrationOngoingCallSystemMessage(
        users: Set<ZMUser>,
        sender: ZMUser,
        at timestamp: Date
    ) {
        appendSystemMessage(
            type: .mlsMigrationOngoingCall,
            sender: sender,
            users: users,
            clients: nil,
            timestamp: timestamp
        )
    }

    public func appendMLSMigrationStartedSystemMessage(
        users: Set<ZMUser>,
        sender: ZMUser,
        at timestamp: Date
    ) {
        appendSystemMessage(
            type: .mlsMigrationStarted,
            sender: sender,
            users: users,
            clients: nil,
            timestamp: timestamp
        )
    }

    public func appendMLSMigrationUpdateVersionSystemMessage(
        users: Set<ZMUser>,
        sender: ZMUser,
        at timestamp: Date
    ) {
        appendSystemMessage(
            type: .mlsMigrationUpdateVersion,
            sender: sender,
            users: users,
            clients: nil,
            timestamp: timestamp
        )
    }

    public func appendMLSMigrationPotentialGapSystemMessage(sender: ZMUser, at timestamp: Date) {
        guard let context = managedObjectContext else {
            return
        }

        let previousLastMessage = lastMessage

        self.appendSystemMessage(
            type: .potentialGap,
            sender: sender,
            users: nil,
            clients: nil,
            timestamp: timestamp
        )

        if let previousLastMessage = previousLastMessage as? ZMSystemMessage, previousLastMessage.systemMessageType == .potentialGap,
           let previousLastMessageTimestamp = previousLastMessage.serverTimestamp, previousLastMessageTimestamp <= timestamp {
            context.delete(previousLastMessage)

        }

    }

}
