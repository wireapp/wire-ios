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
import XCTest
import WireTesting
@testable import WireDataModel

final class DuplicatedEntityRemovalTests: DiskDatabaseTest {
    

    func appendSystemMessage(conversation: ZMConversation,
                             type: ZMSystemMessageType,
                             sender: ZMUser,
                             users: Set<ZMUser>?,
                             addedUsers: Set<ZMUser> = Set(),
                             clients: Set<UserClient>?,
                             timestamp: Date?,
                             duration: TimeInterval? = nil
        ) -> ZMSystemMessage {

        let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: moc)
        systemMessage.systemMessageType = type
        systemMessage.sender = sender
        systemMessage.users = users ?? Set()
        systemMessage.addedUsers = addedUsers
        systemMessage.clients = clients ?? Set()
        systemMessage.serverTimestamp = timestamp
        if let duration = duration {
            systemMessage.duration = duration
        }

        conversation.append(systemMessage)
        systemMessage.visibleInConversation = conversation
        return systemMessage
    }

    func addedOrRemovedSystemMessages(conversation: ZMConversation,
                                      client: UserClient
                                      ) -> [ZMSystemMessage] {
        let addedMessage = self.appendSystemMessage(conversation: conversation,
                                                    type: .newClient,
                                                    sender: ZMUser.selfUser(in: self.moc),
                                                    users: Set(arrayLiteral: client.user!),
                                                    addedUsers: Set(arrayLiteral: client.user!),
                                                    clients: Set(arrayLiteral: client),
                                                    timestamp: Date())

        let ignoredMessage = self.appendSystemMessage(conversation: conversation,
                                                      type: .ignoredClient,
                                                      sender: ZMUser.selfUser(in: self.moc),
                                                      users: Set(arrayLiteral: client.user!),
                                                      clients: Set(arrayLiteral: client),
                                                      timestamp: Date())

        return [addedMessage, ignoredMessage]
    }

    func messages(conversation: ZMConversation) -> [ZMMessage] {
        return (0..<5).map { try! conversation.appendText(content: "Message \($0)") as! ZMMessage }
    }
}

// MARK: - Merge tests
extension DuplicatedEntityRemovalTests {
    
    func testThatItMergesTwoUserClients() {
        
        // GIVEN
        let user = createUser()
        let conversation = createConversation()
        let client1 = createClient(user: user)

        let client2 = createClient(user: user)
        client2.remoteIdentifier = client1.remoteIdentifier

        let addedOrRemovedInSystemMessages = Set<ZMSystemMessage>(
            addedOrRemovedSystemMessages(conversation: conversation, client: client2)
        )
        let ignoredByClients = Set((0..<5).map { _ in createClient(user: user) })
        let messagesMissingRecipient = Set<ZMMessage>(messages(conversation: conversation))
        let trustedByClients = Set((0..<5).map { _ in createClient(user: user) })
        let missedByClient = createClient(user: user)

        client2.addedOrRemovedInSystemMessages = addedOrRemovedInSystemMessages
        client2.ignoredByClients = ignoredByClients
        client2.messagesMissingRecipient = messagesMissingRecipient
        client2.trustedByClients = trustedByClients
        client2.missedByClient = missedByClient

        // WHEN
        client1.merge(with: client2)
        self.moc.delete(client2)
        self.moc.saveOrRollback()

        // THEN
        XCTAssertEqual(addedOrRemovedInSystemMessages.count, 2)

        XCTAssertEqual(client1.addedOrRemovedInSystemMessages, addedOrRemovedInSystemMessages)
        XCTAssertEqual(client1.ignoredByClients, ignoredByClients)
        XCTAssertEqual(client1.messagesMissingRecipient, messagesMissingRecipient)
        XCTAssertEqual(client1.trustedByClients, trustedByClients)
        XCTAssertEqual(client1.missedByClient, missedByClient)

        addedOrRemovedInSystemMessages.forEach {
            XCTAssertTrue($0.clients.contains(client1))
            XCTAssertFalse($0.clients.contains(client2))
        }
    }

    func testThatItMergesTwoUsers() {
        // GIVEN
        let conversation = createConversation()
        let user1 = createUser()
        let user2 = createUser()
        user2.remoteIdentifier = user1.remoteIdentifier

        let team = createTeam()
        let membership = createMembership(user: user1, team: team)
        let reaction = Reaction.insertNewObject(in: self.moc)
        let systemMessage = ZMSystemMessage(nonce: UUID(), managedObjectContext: moc)

        let conversations = Set<ZMConversation>([conversation])
        let conversationsCreated = Set<ZMConversation>([conversation])
        let createdTeams = Set<Team>([team])
        let reactions = Set<Reaction>([reaction])
        let showingUserAdded = Set<ZMMessage>([systemMessage])
        let showingUserRemoved = Set<ZMMessage>([systemMessage])
        let systemMessages = Set<ZMSystemMessage>([systemMessage])

        conversations.forEach {
            $0.addParticipantAndUpdateConversationState(user: user2, role: nil)
        }
        user2.conversationsCreated = conversationsCreated
        user2.createdTeams = createdTeams
        user2.membership = membership
        user2.reactions = reactions
        user2.showingUserAdded = showingUserAdded
        user2.showingUserRemoved = showingUserRemoved
        user2.systemMessages = systemMessages

        // WHEN
        user1.merge(with: user2)
        
        user2.delete(from: moc)
        
        moc.saveOrRollback()

        // THEN
        XCTAssertEqual(Set(user1.participantRoles.map { $0.conversation }), conversations)
        XCTAssertEqual(user1.conversationsCreated, conversationsCreated)
        XCTAssertEqual(user1.createdTeams, createdTeams)
        XCTAssertEqual(user1.membership, membership)
        XCTAssertEqual(user1.reactions, reactions)
        XCTAssertEqual(user1.showingUserAdded, showingUserAdded)
        XCTAssertEqual(user1.showingUserRemoved, showingUserRemoved)
        XCTAssertEqual(user1.systemMessages, systemMessages)
        XCTAssertTrue(user1.needsToBeUpdatedFromBackend)
    }
    
    func testThatItMergesUsers_Connection_user1HasIt() {
    
        // GIVEN
        let user1 = createUser()
        let user2 = createUser()
        user2.remoteIdentifier = user1.remoteIdentifier
        let conversation = createConversation()
        conversation.conversationType = .oneOnOne
        let connection = createConnection(to: user1, conversation: conversation)
        user1.connection = connection
        conversation.addParticipantAndUpdateConversationState(user: user1, role: nil)
        self.moc.saveOrRollback()
        
        // WHEN
        user1.merge(with: user2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(user1.connection, connection)
        XCTAssertEqual(connection.to, user1)
        XCTAssertFalse(connection.isZombieObject)
    }
    
    func testThatItMergesUsers_Connection_user2HasIt() {
        
        // GIVEN
        let user1 = createUser()
        let user2 = createUser()
        user2.remoteIdentifier = user1.remoteIdentifier
        let conversation = createConversation()
        conversation.conversationType = .oneOnOne
        let connection = createConnection(to: user2, conversation: conversation)
        user2.connection = connection
        conversation.addParticipantAndUpdateConversationState(user: user2, role: nil)
        self.moc.saveOrRollback()
        
        // WHEN
        user1.merge(with: user2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(user1.connection, connection)
        XCTAssertEqual(connection.to, user1)
        XCTAssertFalse(connection.isZombieObject)
    }
    
    func testThatItMergesUsers_Connection_bothUserHaveIt() {
        
        // GIVEN
        let user1 = createUser()
        let user2 = createUser()
        user2.remoteIdentifier = user1.remoteIdentifier
        let conversation1 = createConversation()
        conversation1.conversationType = .oneOnOne
        conversation1.addParticipantAndUpdateConversationState(user: user1, role: nil)
        let conversation2 = createConversation()
        conversation2.conversationType = .oneOnOne
        conversation2.addParticipantAndUpdateConversationState(user: user2, role: nil)
        let connection1 = createConnection(to: user1, conversation: conversation1)
        user1.connection = connection1
        let connection2 = createConnection(to: user2, conversation: conversation2)
        user2.connection = connection2
        self.moc.saveOrRollback()
        
        // WHEN
        user1.merge(with: user2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(user1.connection, connection1)
        XCTAssertEqual(connection1.to, user1)
        XCTAssertFalse(connection1.isZombieObject)
        XCTAssertTrue(connection2.isZombieObject)
    }
    
    func testThatItMergesUsers_ABEntry_user1HasIt() {
        
        // GIVEN
        let user1 = createUser()
        let user2 = createUser()
        user2.remoteIdentifier = user1.remoteIdentifier
        let ABEntry = AddressBookEntry.insertNewObject(in: self.moc)
        ABEntry.user = user1
        self.moc.saveOrRollback()
        
        // WHEN
        user1.merge(with: user2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(user1.addressBookEntry, ABEntry)
        XCTAssertEqual(ABEntry.user, user1)
        XCTAssertFalse(ABEntry.isZombieObject)
    }
    
    func testThatItMergesUsers_ABEntry_user2HasIt() {
        
        let user1 = createUser()
        let user2 = createUser()
        user2.remoteIdentifier = user1.remoteIdentifier
        let ABEntry = AddressBookEntry.insertNewObject(in: self.moc)
        ABEntry.user = user2
        self.moc.saveOrRollback()
        
        // WHEN
        user1.merge(with: user2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(user1.addressBookEntry, ABEntry)
        XCTAssertEqual(ABEntry.user, user1)
        XCTAssertFalse(ABEntry.isZombieObject)
    }
    
    func testThatItMergesUsers_ABEntry_bothUserHaveIt() {
        
        // GIVEN
        let user1 = createUser()
        let user2 = createUser()
        user2.remoteIdentifier = user1.remoteIdentifier
        let ABEntry1 = AddressBookEntry.insertNewObject(in: self.moc)
        ABEntry1.user = user1
        let ABEntry2 = AddressBookEntry.insertNewObject(in: self.moc)
        ABEntry2.user = user2
        self.moc.saveOrRollback()
        
        // WHEN
        user1.merge(with: user2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(user1.addressBookEntry, ABEntry1)
        XCTAssertEqual(ABEntry1.user, user1)
        XCTAssertFalse(ABEntry1.isZombieObject)
        XCTAssertTrue(ABEntry2.isZombieObject)
    }
    
    func testThatItMergesUsers_LastServerSynchedActiveConversations() {
        
        // GIVEN
        let user1 = createUser()
        let user2 = createUser()
        user2.remoteIdentifier = user1.remoteIdentifier
        let conversation1 = createConversation()
        let conversation2 = createConversation()
        let conversation3 = createConversation()
        conversation1.addParticipantsAndUpdateConversationState(users: Set([user1, user2]), role: nil)
        conversation2.addParticipantAndUpdateConversationState(user: user1, role: nil)
        conversation3.addParticipantAndUpdateConversationState(user: user2, role: nil)
        self.moc.saveOrRollback()
        
        // sanity check
        XCTAssertEqual(Set(user1.participantRoles.map { $0.conversation }), Set([conversation1, conversation2]))
        XCTAssertEqual(Set(user2.participantRoles.map { $0.conversation }), Set([conversation1, conversation3]))
        
        // WHEN
        user1.merge(with: user2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(Set(user1.participantRoles.map { $0.conversation }), Set([conversation1, conversation2, conversation3]))
    }
    
    func testThatItMergesUsers_ActiveConversations() {
        
        // GIVEN
        let user1 = createUser()
        let user2 = createUser()
        user2.remoteIdentifier = user1.remoteIdentifier
        let conversation1 = createConversation()
        let conversation2 = createConversation()
        let conversation3 = createConversation()
        conversation1.addParticipantsAndUpdateConversationState(users: Set([user1, user2]), role: nil)
        conversation2.addParticipantAndUpdateConversationState(user: user1, role: nil)
        conversation3.addParticipantAndUpdateConversationState(user: user2, role: nil)
        self.moc.saveOrRollback()
        
        // sanity check
        XCTAssertEqual(Set(user1.participantRoles.map { $0.conversation }), Set([conversation1, conversation2]))
        XCTAssertEqual(Set(user2.participantRoles.map { $0.conversation }), Set([conversation1, conversation3]))
        
        // WHEN
        user1.merge(with: user2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(Set(user1.participantRoles.map { $0.conversation }), Set([conversation1, conversation2, conversation3]))
    }
    
    func testThatItMergesUsers_ConversationCreated() {
        
        // GIVEN
        let user1 = createUser()
        let user2 = createUser()
        user2.remoteIdentifier = user1.remoteIdentifier
        let conversation1 = createConversation()
        let conversation2 = createConversation()
        user1.conversationsCreated = Set([conversation1])
        user2.conversationsCreated = Set([conversation2])
        self.moc.saveOrRollback()
        
        // WHEN
        user1.merge(with: user2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(user1.conversationsCreated, Set([conversation1, conversation2]))
    }
    
    func testThatItMergesUsers_CreatedTeams() {
        
        // GIVEN
        let user1 = createUser()
        let user2 = createUser()
        user2.remoteIdentifier = user1.remoteIdentifier
        let team1 = createTeam()
        let team2 = createTeam()
        user1.createdTeams = Set([team1])
        user2.createdTeams = Set([team2])
        self.moc.saveOrRollback()
        
        // WHEN
        user1.merge(with: user2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(user1.createdTeams, Set([team1, team2]))
        
    }
    
    func testThatItMergesUsers_Membership_user1HasIt() {
        
        // GIVEN
        let user1 = createUser()
        let user2 = createUser()
        let team = createTeam()
        user2.remoteIdentifier = user1.remoteIdentifier
        let membership = self.createMembership(user: user1, team: team)
        self.moc.saveOrRollback()
        
        // WHEN
        user1.merge(with: user2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(user1.membership, membership)
        XCTAssertEqual(membership.user, user1)
        XCTAssertFalse(membership.isZombieObject)
    }
    
    func testThatItMergesUsers_Membership_user2HasIt() {
        
        let user1 = createUser()
        let user2 = createUser()
        let team = createTeam()
        user2.remoteIdentifier = user1.remoteIdentifier
        let membership = self.createMembership(user: user2, team: team)
        self.moc.saveOrRollback()
        
        // WHEN
        user1.merge(with: user2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(user1.membership, membership)
        XCTAssertEqual(membership.user, user1)
        XCTAssertFalse(membership.isZombieObject)
    }
    
    func testThatItMergesUsers_Membership_bothUserHaveIt() {
        
        // GIVEN
        let user1 = createUser()
        let user2 = createUser()
        let team = createTeam()
        user2.remoteIdentifier = user1.remoteIdentifier
        let membership1 = self.createMembership(user: user1, team: team)
        let membership2 = self.createMembership(user: user2, team: team)
        self.moc.saveOrRollback()
        
        // WHEN
        user1.merge(with: user2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(user1.membership, membership1)
        XCTAssertEqual(membership1.user, user1)
        XCTAssertFalse(membership1.isZombieObject)
        XCTAssertTrue(membership2.isZombieObject)
    }
    
    func testThatItMergesUsers_Reactions() {
        
        // GIVEN
        let user1 = createUser()
        let user2 = createUser()
        user2.remoteIdentifier = user1.remoteIdentifier
        let reaction1 = Reaction.insertNewObject(in: self.moc)
        let reaction2 = Reaction.insertNewObject(in: self.moc)
        reaction1.users = Set([user1])
        reaction2.users = Set([user1])
        self.moc.saveOrRollback()
        
        // WHEN
        user1.merge(with: user2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(user1.reactions, Set([reaction1, reaction2]))
    }

    func testThatItMergesUsers_DeletesClients() throws {

        // GIVEN
        let user1 = createUser()
        let user2 = createUser()
        user2.remoteIdentifier = user1.remoteIdentifier
        _ = createClient(user: user2)
        _ = createClient(user: user2)
        self.moc.saveOrRollback()

        // WHEN
        user1.merge(with: user2)
        self.moc.saveOrRollback()

        // THEN
        let allClients = try self.moc.fetch(UserClient.sortedFetchRequest()!)
        XCTAssertEqual(user1.clients.count, 0)
        XCTAssertEqual(allClients.count, 0)
    }
    
    func testThatItMergesUsers_ShowingUserAdded() {
        
        // GIVEN
        let user1 = createUser()
        let user2 = createUser()
        user2.remoteIdentifier = user1.remoteIdentifier
        let conversation = createConversation()
        let showingUserAdded1 = appendSystemMessage(
            conversation: conversation,
            type: .participantsAdded,
            sender: user1,
            users: Set([user1]),
            clients: nil,
            timestamp: nil)
        showingUserAdded1.addedUsers = Set([user1])
        let showingUserAdded2 = appendSystemMessage(
            conversation: conversation,
            type: .participantsAdded,
            sender: user2,
            users: Set([user2]),
            clients: nil,
            timestamp: nil)
        showingUserAdded2.addedUsers = Set([user2])
        self.moc.saveOrRollback()
        
        // WHEN
        user1.merge(with: user2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(user1.showingUserAdded, Set([showingUserAdded1, showingUserAdded2]))
    }
    
    func testThatItMergesUsers_ShowingUserRemoved() {
        
        // GIVEN
        let user1 = createUser()
        let user2 = createUser()
        user2.remoteIdentifier = user1.remoteIdentifier
        let conversation = createConversation()
        let showingUserRemoved1 = appendSystemMessage(
            conversation: conversation,
            type: .participantsRemoved,
            sender: user1,
            users: Set([user1]),
            clients: nil,
            timestamp: nil)
        showingUserRemoved1.removedUsers = Set([user1])
        let showingUserRemoved2 = appendSystemMessage(
            conversation: conversation,
            type: .participantsRemoved,
            sender: user2,
            users: Set([user2]),
            clients: nil,
            timestamp: nil)
        showingUserRemoved2.removedUsers = Set([user2])
        self.moc.saveOrRollback()
        
        // WHEN
        user1.merge(with: user2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(user1.showingUserRemoved, Set([showingUserRemoved1, showingUserRemoved2]))
    }
    
    func testThatItMergesUsers_SystemMessages() {
        
        // GIVEN
        let user1 = createUser()
        let user2 = createUser()
        user2.remoteIdentifier = user1.remoteIdentifier
        let conversation = createConversation()
        let showingUserRemoved1 = appendSystemMessage(
            conversation: conversation,
            type: .participantsRemoved,
            sender: user1,
            users: Set([user1]),
            clients: nil,
            timestamp: nil)
        showingUserRemoved1.removedUsers = Set([user1])
        let showingUserRemoved2 = appendSystemMessage(
            conversation: conversation,
            type: .participantsRemoved,
            sender: user2,
            users: Set([user2]),
            clients: nil,
            timestamp: nil)
        showingUserRemoved2.removedUsers = Set([user2])
        self.moc.saveOrRollback()
        
        // WHEN
        user1.merge(with: user2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(user1.systemMessages, Set([showingUserRemoved1, showingUserRemoved2]))
    }
    
    func testThatItMergesConversations_messages() {
        // GIVEN
        let conversation1 = createConversation()
        let conversation2 = createConversation()
        conversation1.remoteIdentifier = conversation2.remoteIdentifier
        
        let message1 = ZMClientMessage(nonce: UUID(), managedObjectContext: moc)
        let message2 = ZMClientMessage(nonce: UUID(), managedObjectContext: moc)
        
        conversation1.mutableMessages.add(message1)
        conversation2.mutableMessages.add(message2)
        self.moc.saveOrRollback()
        
        // WHEN
        conversation1.merge(with: conversation2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(Set(conversation1.allMessages), Set([message1, message2]))
    }
    
    func testThatItMergesConversations_hiddenMessages() {
        // GIVEN
        let conversation1 = createConversation()
        let conversation2 = createConversation()
        conversation1.remoteIdentifier = conversation2.remoteIdentifier
        
        let message1 = ZMClientMessage(nonce: UUID(), managedObjectContext: moc)
        let message2 = ZMClientMessage(nonce: UUID(), managedObjectContext: moc)
        
        message1.hiddenInConversation = conversation1
        message2.hiddenInConversation = conversation2
        self.moc.saveOrRollback()
        
        // WHEN
        conversation1.merge(with: conversation2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(conversation1.hiddenMessages, Set([message1, message2]))
    }
    
    func testThatItMergesConversations_team_convo1HasIt() {
        
        // GIVEN
        let conversation1 = createConversation()
        let conversation2 = createConversation()
        conversation2.remoteIdentifier = conversation1.remoteIdentifier
        let team = createTeam()
        conversation1.team = team
        self.moc.saveOrRollback()
        
        // WHEN
        conversation1.merge(with: conversation2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(conversation1.team, team)
    }
    
    func testThatItMergesConversations_team_convo2HasIt() {
        
        // GIVEN
        let conversation1 = createConversation()
        let conversation2 = createConversation()
        conversation2.remoteIdentifier = conversation1.remoteIdentifier
        let team = createTeam()
        conversation2.team = team
        self.moc.saveOrRollback()
        
        // WHEN
        conversation1.merge(with: conversation2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(conversation1.team, team)
    }
    
    func testThatItMergesConversations_team_bothHaveIt() {
        
        // GIVEN
        let conversation1 = createConversation()
        let conversation2 = createConversation()
        conversation2.remoteIdentifier = conversation1.remoteIdentifier
        let team1 = createTeam()
        let team2 = createTeam()
        conversation1.team = team1
        conversation2.team = team2
        self.moc.saveOrRollback()
        
        // WHEN
        conversation1.merge(with: conversation2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(conversation1.team, team1)
        XCTAssertFalse(team2.isZombieObject)
    }
    
    func testThatItMergesConversations_connection_convo1HasIt() {
        
        // GIVEN
        let conversation1 = createConversation()
        let conversation2 = createConversation()
        conversation2.remoteIdentifier = conversation1.remoteIdentifier
        let user = createUser()
        let connection = createConnection(to: user, conversation: conversation1)
        self.moc.saveOrRollback()
        
        // WHEN
        conversation1.merge(with: conversation2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(conversation1.connection, connection)
    }
    
    func testThatItMergesConversations_connection_convo2HasIt() {
        
        // GIVEN
        let conversation1 = createConversation()
        let conversation2 = createConversation()
        conversation2.remoteIdentifier = conversation1.remoteIdentifier
        let user = createUser()
        let connection = createConnection(to: user, conversation: conversation2)
        self.moc.saveOrRollback()
        
        // WHEN
        conversation1.merge(with: conversation2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(conversation1.connection, connection)
    }
    
    func testThatItMergesConversations_connection_bothHaveIt() {
        
        // GIVEN
        let conversation1 = createConversation()
        let conversation2 = createConversation()
        let user = createUser()
        conversation2.remoteIdentifier = conversation1.remoteIdentifier
        let connection1 = createConnection(to: user, conversation: conversation1)
        let connection2 = createConnection(to: user, conversation: conversation2)
        self.moc.saveOrRollback()
        
        // WHEN
        conversation1.merge(with: conversation2)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual(conversation1.connection, connection1)
        XCTAssertFalse(connection1.isZombieObject)
        XCTAssertTrue(connection2.isZombieObject)
    }
}

// MARK: - Testing deletion from patch
extension DuplicatedEntityRemovalTests {

    func testThatItRemovesDuplicatedClients() {
        // GIVEN
        let user = createUser()
        let client1 = createClient(user: user)
        let duplicates: [UserClient] = (0..<5).map { _ in
            let otherClient = createClient(user: user)
            otherClient.remoteIdentifier = client1.remoteIdentifier
            return otherClient
        }

        self.moc.saveOrRollback()

        // WHEN
        WireDataModel.DuplicatedEntityRemoval.deleteDuplicatedClients(in: self.moc)
        self.moc.saveOrRollback()

        // THEN
        let totalDeleted = (duplicates + [client1]).filter {
            $0.managedObjectContext == nil
            }.count

        XCTAssertEqual(totalDeleted, 5)
    }

    func testThatItRemovesDuplicatedUsers() {
        // GIVEN
        let user1 = createUser()
        let duplicates: [ZMUser] = (0..<5).map { _ in
            let otherUser = createUser()
            otherUser.remoteIdentifier = user1.remoteIdentifier
            return otherUser
        }

        self.moc.saveOrRollback()

        // WHEN
        WireDataModel.DuplicatedEntityRemoval.deleteDuplicatedUsers(in: self.moc)
        self.moc.saveOrRollback()

        // THEN
        let totalDeleted = (duplicates + [user1]).filter {
            $0.managedObjectContext == nil
            }.count

        XCTAssertEqual(totalDeleted, 5)
    }

    func testThatItRemovesDuplicatedConversations() {
        // GIVEN
        let conversation1 = createConversation()
        let duplicates: [ZMConversation] = (0..<5).map { _ in
            let otherConversation = createConversation()
            otherConversation.remoteIdentifier = conversation1.remoteIdentifier
            return otherConversation
        }

        self.moc.saveOrRollback()

        // WHEN
        WireDataModel.DuplicatedEntityRemoval.deleteDuplicatedConversations(in: self.moc)
        self.moc.saveOrRollback()

        // THEN
        let totalDeleted = (duplicates + [conversation1]).filter {
            $0.managedObjectContext == nil
            }.count

        XCTAssertEqual(totalDeleted, 5)
    }

    func testThatItRemovesAllDuplicates() {

        // GIVEN
        let userA1 = ZMUser.insertNewObject(in: self.moc)
        userA1.remoteIdentifier = UUID()
        userA1.name = "userA1"
        userA1.needsToBeUpdatedFromBackend = false
        let userA2 = ZMUser.insertNewObject(in: self.moc)
        userA2.remoteIdentifier = userA1.remoteIdentifier
        userA2.name = "userA2"
        userA2.needsToBeUpdatedFromBackend = false
        let userB = ZMUser.insertNewObject(in: self.moc)
        userB.remoteIdentifier = UUID()
        userB.name = "userB"
        userB.needsToBeUpdatedFromBackend = false
        let userC = ZMUser.insertNewObject(in: self.moc)
        userC.remoteIdentifier = UUID()
        userC.name = "userC"
        userC.needsToBeUpdatedFromBackend = false

        let convoA1 = ZMConversation.insertNewObject(in: self.moc)
        convoA1.remoteIdentifier = UUID()
        convoA1.conversationType = .oneOnOne
        convoA1.addParticipantAndUpdateConversationState(user: userA1, role: nil)
        convoA1.creator = userA1
        convoA1.userDefinedName = "convoA1"
        convoA1.needsToBeUpdatedFromBackend = false
        let convoA2 = ZMConversation.insertNewObject(in: self.moc)
        convoA2.remoteIdentifier = convoA1.remoteIdentifier
        convoA2.conversationType = .oneOnOne
        convoA2.addParticipantAndUpdateConversationState(user: userA2, role: nil)
        convoA2.creator = userA2
        convoA2.userDefinedName = "convoA2"
        convoA2.needsToBeUpdatedFromBackend = false
        let convoB1 = ZMConversation.insertNewObject(in: self.moc)
        convoB1.remoteIdentifier = UUID()
        convoB1.conversationType = .group
        convoB1.addParticipantAndUpdateConversationState(user: userA1, role: nil)
        convoB1.addParticipantAndUpdateConversationState(user: userB, role: nil)
        convoB1.creator = userB
        convoB1.addParticipantAndUpdateConversationState(user: userA1, role: nil) // missing userB
        convoB1.userDefinedName = "convoB1"
        convoB1.needsToBeUpdatedFromBackend = false
        let convoB2 = ZMConversation.insertNewObject(in: self.moc)
        convoB2.remoteIdentifier = convoB1.remoteIdentifier
        convoB2.conversationType = .group
        convoB2.addParticipantAndUpdateConversationState(user: userC, role: nil)
        convoB2.addParticipantAndUpdateConversationState(user: userB, role: nil)
        convoB2.creator = userB
        convoB2.addParticipantAndUpdateConversationState(user: userC, role: nil)
        convoB2.userDefinedName = "convoB2"
        convoB2.needsToBeUpdatedFromBackend = false
        let convoC = ZMConversation.insertNewObject(in: self.moc)
        convoC.remoteIdentifier = UUID()
        convoC.conversationType = .group
        convoC.addParticipantAndUpdateConversationState(user: userA2, role: nil)
        convoC.addParticipantAndUpdateConversationState(user: userC, role: nil)
        convoC.creator = userC
        convoC.addParticipantAndUpdateConversationState(user: userA2, role: nil) // missing user C
        convoC.userDefinedName = "convoC"
        convoC.needsToBeUpdatedFromBackend = false

        let connectionA1 = ZMConnection.insertNewObject(in: self.moc)
        connectionA1.to = userA1
        connectionA1.conversation = convoA1
        connectionA1.status = .accepted
        
        let connectionA2 = ZMConnection.insertNewObject(in: self.moc)
        connectionA2.to = userA2
        connectionA2.conversation = convoA2
        connectionA2.status = .accepted

        moc.saveOrRollback()
        
        // WHEN
        WireDataModel.DuplicatedEntityRemoval.removeDuplicated(in: self.moc)
        self.moc.saveOrRollback()
        
        // THEN
        XCTAssertEqual([userA1, userA2].nonZombies.count, 1)
        guard let userA = [userA1, userA2].nonZombies.first else {
            return XCTFail("Both deleted!")
        }
        
        XCTAssertEqual([convoA1, convoA2].nonZombies.count, 1)
        guard let convoA = [convoA1, convoA2].nonZombies.first else {
            return XCTFail("Both deleted!")
        }
        
        XCTAssertEqual([convoB1, convoB2].nonZombies.count, 1)
        guard let convoB = [convoB1, convoB2].nonZombies.first else {
            return XCTFail("Both deleted!")
        }
        
        XCTAssertEqual([connectionA1, connectionA2].nonZombies.count, 1)
        guard let connectionA = [connectionA1, connectionA2].nonZombies.first else {
            return XCTFail("Both deleted!")
        }
        
        XCTAssertEqual(convoA.localParticipants, Set([userA]))
        XCTAssertEqual(convoB.localParticipants, Set([userA, userB, userC]))
        XCTAssertEqual(convoC.localParticipants, Set([userA, userC]))
        
        XCTAssertTrue(convoA.needsToBeUpdatedFromBackend)
        XCTAssertTrue(convoB.needsToBeUpdatedFromBackend)
        XCTAssertTrue(convoC.needsToBeUpdatedFromBackend)
        
        XCTAssertTrue(userA.needsToBeUpdatedFromBackend)
        XCTAssertFalse(userC.needsToBeUpdatedFromBackend)
        
        XCTAssertEqual(connectionA.to, userA)
    }
}

extension Array where Element: ZMManagedObject {
    
    fileprivate var nonZombies: [Element] {
        return self.filter { !($0.isZombieObject || $0.isDeleted) }
    }
}

