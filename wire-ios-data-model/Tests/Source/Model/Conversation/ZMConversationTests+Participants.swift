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
import WireDataModelSupport
@testable import WireDataModel

final class ConversationParticipantsTests: ZMConversationTestsBase {
    func testThatSortedOtherParticipantsReutrnsUsersSortedByName() {
        // GIVEN
        let sut = createConversation(in: uiMOC)

        let user1 = createUser()
        user1.name = "Zeta"

        let user2 = createUser()
        user2.name = "Alpha"

        let user3 = createUser()
        user3.name = "Beta"
        user3.providerIdentifier = "dummy ID"
        user3.serviceIdentifier = "dummy ID"

        sut.addParticipantsAndUpdateConversationState(users: Set([user1, user2, user3]), role: nil)

        // WHEN & THEN
        XCTAssertEqual(sut.sortedOtherParticipants as! [ZMUser], [user2, user1])
    }

    func testThatSortedServiceUsersReutrnsUsersSortedByName() {
        // GIVEN
        let sut = createConversation(in: uiMOC)

        let user1 = createUser()
        user1.name = "Zeta"
        user1.providerIdentifier = "dummy ID"
        user1.serviceIdentifier = "dummy ID"

        let user2 = createUser()
        user2.name = "Alpha"
        user2.providerIdentifier = "dummy ID"
        user2.serviceIdentifier = "dummy ID"

        let user3 = createUser()
        user3.name = "Beta"

        sut.addParticipantsAndUpdateConversationState(users: Set([user2, user1, user3]), role: nil)

        // WHEN & THEN
        XCTAssertEqual(sut.sortedServiceUsers as! [ZMUser], [user2, user1])
    }

    func testThatLocalParticipantsExcludesUsersMarkedForDeletion() {
        // GIVEN
        let sut = createConversation(in: uiMOC)
        let user1 = createUser()
        let user2 = createUser()
        sut.addParticipantsAndUpdateConversationState(users: Set([user1, user2]), role: nil)
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // WHEN
        sut.removeParticipantsAndUpdateConversationState(users: Set([user2]), initiatingUser: selfUser)

        // THEN
        XCTAssertEqual(sut.localParticipants, Set([user1]))
    }

    func testThatLocalRolesExcludesUsersMarkedForDeletion() {
        // GIVEN
        let sut = createConversation(in: uiMOC)
        let user1 = createUser()
        let user2 = createUser()
        sut.addParticipantsAndUpdateConversationState(users: Set([user1, user2]), role: nil)

        // WHEN
        sut.removeParticipantsAndUpdateConversationState(users: Set([user2]), initiatingUser: selfUser)

        // THEN
        XCTAssertEqual(sut.localParticipantRoles.map(\.user), [user1])
    }

    func testThatRemoveThenAddParticipants() {
        // GIVEN
        let sut = createConversation(in: uiMOC)
        let user1 = createUser()
        let user2 = createUser()
        let selfUser = ZMUser.selfUser(in: uiMOC)

        sut.addParticipantsAndUpdateConversationState(users: Set([user1, user2]), role: nil)

        XCTAssertEqual(sut.participantRoles.count, 2)
        XCTAssertEqual(sut.localParticipants.count, 2)

        // WHEN
        sut.removeParticipantsAndUpdateConversationState(users: Set([user2]), initiatingUser: selfUser)
        sut.addParticipantAndUpdateConversationState(user: user2, role: nil)

        // THEN
        XCTAssertEqual(Set(sut.participantRoles.map(\.user)), Set([user1, user2]))
        XCTAssertEqual(sut.localParticipants, Set([user1, user2]))
    }

    func testThatAddThenRemoveParticipants() {
        // GIVEN
        let sut = createConversation(in: uiMOC)
        let user1 = createUser()
        let user2 = createUser()

        sut.addParticipantAndUpdateConversationState(user: user1, role: nil)

        // WHEN
        sut.addParticipantAndUpdateConversationState(user: user2, role: nil)
        sut.removeParticipantsAndUpdateConversationState(users: Set([user2]), initiatingUser: selfUser)
        uiMOC.processPendingChanges()

        // THEN
        XCTAssertEqual(Set(sut.participantRoles.map(\.user)), Set([user1]))
        XCTAssertEqual(sut.localParticipants, Set([user1]))

        XCTAssert(user2.participantRoles.isEmpty, "\(user2.participantRoles)")
    }

    func testThatItAddsMissingParticipantInGroup() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group

        // when
        conversation.addParticipantAndSystemMessageIfMissing(user, date: Date())

        // then
        XCTAssertTrue(conversation.localParticipants.contains(user))
        let systemMessage = conversation.lastMessage as? ZMSystemMessage
        XCTAssertEqual(systemMessage?.systemMessageType, ZMSystemMessageType.participantsAdded)
    }

    func testThatItDoesntAddParticipantsAddedSystemMessageIfUserIsNotMissing() {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)

        // when
        conversation.addParticipantAndSystemMessageIfMissing(user, date: Date())

        // then
        XCTAssertTrue(conversation.localParticipants.contains(user))
        XCTAssertEqual(conversation.allMessages.count, 0)
    }

    func testThatItDoesntCreateAConnectionIfSelfUserIsMissing() {
        // given
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let user = ZMUser.insertNewObject(in: uiMOC)
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let connection = ZMConnection.insertNewObject(in: uiMOC)
        conversation.conversationType = .oneOnOne
        user.connection = connection
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)

        // when
        conversation.addParticipantAndSystemMessageIfMissing(selfUser, date: Date())

        // then
        XCTAssertNotEqual(selfUser.connection, connection)
    }

    func testThatItCreatesAConnectionIfUserIsNotATeamMember() {
        // given
        let selfUser = ZMUser.selfUser(in: uiMOC)

        let otherUser = ZMUser.insertNewObject(in: uiMOC)
        otherUser.remoteIdentifier = .create()

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .oneOnOne
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

        XCTAssertNil(otherUser.connection)
        XCTAssertFalse(otherUser.isOnSameTeam(otherUser: selfUser))

        // when
        conversation.addParticipantAndSystemMessageIfMissing(otherUser, date: Date())

        // then
        XCTAssertNotNil(otherUser.connection)
    }

    func testThatItDoesntCreateAConnectionIfUserIsTeamMember() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = .create()

        let selfUser = ZMUser.selfUser(in: uiMOC)
        let selfUserMembership = Member.insertNewObject(in: uiMOC)
        selfUserMembership.team = team
        selfUserMembership.user = selfUser

        let otherUser = ZMUser.insertNewObject(in: uiMOC)
        otherUser.remoteIdentifier = .create()
        let otherUserMembership = Member.insertNewObject(in: uiMOC)
        otherUserMembership.team = team
        otherUserMembership.user = otherUser

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .oneOnOne
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

        XCTAssertNil(otherUser.connection)
        XCTAssertTrue(otherUser.isOnSameTeam(otherUser: selfUser))

        // when
        conversation.addParticipantAndSystemMessageIfMissing(otherUser, date: Date())

        // then
        XCTAssertNil(otherUser.connection)
    }

    func testThatItAddsParticipants() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        let user1 = createUser()
        let user2 = createUser()

        // when
        conversation.addParticipantAndUpdateConversationState(user: user1, role: nil)
        conversation.addParticipantAndUpdateConversationState(user: user2, role: nil)

        // then
        let expectedActiveParticipants = Set([user1, user2])
        XCTAssertEqual(expectedActiveParticipants, conversation.localParticipants)
    }

    func testThatItDoesNotUnarchiveTheConversationWhenTheSelfUserIsAddedIfMuted() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.isArchived = true
        conversation.mutedStatus = MutedMessageOptionValue.all.rawValue
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.remoteIdentifier = UUID.create()

        // when
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(conversation.isArchived)
    }

    func testThatItUnarchivesTheConversationWhenTheSelfUserIsAdded() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.isArchived = true
        conversation.remoteIdentifier = UUID.create()
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.remoteIdentifier = UUID.create()

        // when
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

        // then
        XCTAssertFalse(conversation.isArchived)
    }

    func testThatItCanRemoveTheSelfUser() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        let user1 = createUser()
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.remoteIdentifier = UUID.create()

        conversation.addParticipantsAndUpdateConversationState(users: Set([selfUser, user1]), role: nil)

        XCTAssertTrue(conversation.isSelfAnActiveMember)

        // when
        conversation.removeParticipantAndUpdateConversationState(user: selfUser, initiatingUser: user1)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(conversation.isSelfAnActiveMember)
    }

    func testThatItDoesNothingForUnknownParticipants() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        let user1 = createUser()
        let user2 = createUser()
        let user3 = createUser()
        let unknownUser = createUser()
        conversation.addParticipantsAndUpdateConversationState(users: Set([user1, user2, user3]), role: nil)

        // when
        conversation.removeParticipantAndUpdateConversationState(user: unknownUser, initiatingUser: user1)

        // then
        let expectedActiveParticipants = Set([user1, user2, user3])
        XCTAssertEqual(expectedActiveParticipants, conversation.localParticipants)
    }

    func testThatActiveParticipantsContainsSelf() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // when
        conversation.addParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: uiMOC), role: nil)

        // then
        XCTAssertTrue(conversation.localParticipants.contains(selfUser))

        // when
        conversation.removeParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: uiMOC))

        // then
        XCTAssertFalse(conversation.localParticipants.contains(selfUser))
    }

    func testThatLocalParticipantsExcludingSelfDoesNotContainSelf() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // when
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        uiMOC.saveOrRollback()

        // then
        XCTAssertFalse(conversation.localParticipantsExcludingSelf.contains(selfUser))
    }

    func testThatAddingSelfToExistingConversationMarksItAsNeedingToUpdate() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create() // this makes it "exists"
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // when
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        uiMOC.saveOrRollback()

        // then
        XCTAssertTrue(conversation.needsToBeUpdatedFromBackend)
    }

    func testThatAddingSelfToNonExistingConversationDoesNotNeedUpdate() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = nil // this makes it as local only
        let selfUser = ZMUser.selfUser(in: uiMOC)

        // when
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        uiMOC.saveOrRollback()

        // then
        XCTAssertFalse(conversation.needsToBeUpdatedFromBackend)
    }

    // MARK: - Sorting

    func testThatItSortsParticipantsByFullName() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        let uuid = UUID.create()
        conversation.remoteIdentifier = uuid

        let selfUser = ZMUser.selfUser(in: uiMOC)
        let user1 = createUser()
        let user2 = createUser()
        let user3 = createUser()
        let user4 = createUser()

        selfUser.name = "Super User"
        user1.name = "Hans im Glueck"
        user2.name = "Anna Blume"
        user3.name = "Susi Super"
        user4.name = "Super Susann"

        // when
        conversation.addParticipantsAndUpdateConversationState(users: Set([user1, user2, user3, user4]), role: nil)
        uiMOC.saveOrRollback()

        // then
        let expected = [user2, user1, user4, user3]

        XCTAssertEqual(conversation.sortedActiveParticipants, expected)
    }

    // MARK: - ConnectedUser

    func testThatTheConnectedUserIsNilForGroupConversation() {
        // when
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.addParticipantAndUpdateConversationState(user: ZMUser.insertNewObject(in: uiMOC), role: nil)
        conversation.addParticipantAndUpdateConversationState(user: ZMUser.insertNewObject(in: uiMOC), role: nil)

        // then
        XCTAssertNil(conversation.connectedUser)
    }

    func testThatTheConnectedUserIsNilForSelfconversation() {
        // when
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .self

        // then
        XCTAssertNil(conversation.connectedUser)
    }

    func testThatWeHaveAConnectedUserForOneOnOneConversation() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .oneOnOne
        let user = ZMUser.insertNewObject(in: uiMOC)
        let connection = ZMConnection.insertNewObject(in: uiMOC)
        connection.to = user

        // when
        user.oneOnOneConversation = conversation

        // then
        XCTAssertEqual(conversation.connectedUser, user)
    }

    func testThatWeHaveAConnectedUserForConnectionConversation() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .connection
        let user = ZMUser.insertNewObject(in: uiMOC)
        let connection = ZMConnection.insertNewObject(in: uiMOC)
        connection.to = user

        // when
        user.oneOnOneConversation = conversation

        // then
        XCTAssertEqual(conversation.connectedUser, user)
    }

    // MARK: - Roles

    func testThatWeGetAConversationRolesIfItIsAPartOfATeam() {
        // given
        let team = createTeam(in: uiMOC)
        let user1 = createTeamMember(in: uiMOC, for: team)
        let user2 = createTeamMember(in: uiMOC, for: team)
        let conversation = ZMConversation.insertGroupConversation(
            moc: uiMOC,
            participants: [user1, user2],
            name: name,
            team: team
        )

        // when
        let adminRole = Role.create(managedObjectContext: uiMOC, name: "wire_admin", team: team)
        let memberRole = Role.create(managedObjectContext: uiMOC, name: "wire_member", team: team)
        team.roles.insert(adminRole)
        team.roles.insert(memberRole)

        // then
        XCTAssertNotNil(conversation!.team)
        XCTAssertEqual(conversation!.getRoles(), conversation!.team!.roles)
        XCTAssertNotEqual(conversation!.getRoles(), conversation!.nonTeamRoles)
    }

    func testThatWeGetAConversationRolesIfItIsNotAPartOfATeam() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group

        // when
        let adminRole = Role.create(managedObjectContext: uiMOC, name: "wire_admin", conversation: conversation)
        conversation.nonTeamRoles.insert(adminRole)

        // then
        XCTAssertNil(conversation.team)
        XCTAssertEqual(conversation.getRoles(), conversation.nonTeamRoles)
        XCTAssertNotEqual(conversation.getRoles(), conversation.team?.roles)
    }

    func testThatItAddsParticipantsWithTheGivenRoleForAllParticipants() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        let role1 = Role.create(managedObjectContext: uiMOC, name: "role1", conversation: conversation)
        conversation.nonTeamRoles.insert(role1)
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "user1"
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "user2"

        // when
        conversation.addParticipantsAndUpdateConversationState(users: Set([user1, user2]), role: role1)

        // then
        XCTAssertEqual(conversation.participantRoles.count, 2)
        XCTAssertEqual(conversation.participantRoles.compactMap(\.role), [role1, role1])
    }

    func testThatItAddsParticipantsWithTheGivenRole() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        let role1 = Role.create(managedObjectContext: uiMOC, name: "role1", conversation: conversation)
        conversation.nonTeamRoles.insert(role1)
        let role2 = Role.create(managedObjectContext: uiMOC, name: "role2", conversation: conversation)
        conversation.nonTeamRoles.insert(role2)
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "user1"
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "user2"

        // when
        conversation.addParticipantsAndUpdateConversationState(usersAndRoles: [
            (user1, role1),
            (user2, role2),
        ])

        // then
        XCTAssertEqual(conversation.participantRoles.count, 2)
        XCTAssertEqual(conversation.participantRoles.first { $0.user == user1 }?.role, role1)
        XCTAssertEqual(conversation.participantRoles.first { $0.user == user2 }?.role, role2)
    }

    func testThatItDoesNotAddDeletedParticipants() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        let role1 = Role.create(managedObjectContext: uiMOC, name: "role1", conversation: conversation)
        conversation.nonTeamRoles.insert(role1)
        let role2 = Role.create(managedObjectContext: uiMOC, name: "role2", conversation: conversation)
        conversation.nonTeamRoles.insert(role2)
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "user1"
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "user2"
        user2.isAccountDeleted = true

        // when
        conversation.addParticipantsAndUpdateConversationState(usersAndRoles: [
            (user1, role1),
            (user2, role2),
        ])

        // then
        XCTAssertEqual(conversation.participantRoles.count, 1)
        XCTAssertEqual(conversation.participantRoles.first { $0.user == user1 }?.role, role1)
    }

    func testThatItUpdateParticipantWithTheGivenRole() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        let role1 = Role.create(managedObjectContext: uiMOC, name: "role1", conversation: conversation)
        conversation.nonTeamRoles.insert(role1)
        let role2 = Role.create(managedObjectContext: uiMOC, name: "role2", conversation: conversation)
        conversation.nonTeamRoles.insert(role2)
        let user1 = ZMUser.insertNewObject(in: uiMOC)
        user1.name = "user1"
        let user2 = ZMUser.insertNewObject(in: uiMOC)
        user2.name = "user2"
        conversation.addParticipantsAndUpdateConversationState(usersAndRoles: [
            (user1, role1),
            (user2, role1),
        ])

        // when
        conversation.addParticipantsAndUpdateConversationState(usersAndRoles: [
            (user1, role1),
            (user2, role2),
        ])

        // then
        XCTAssertEqual(conversation.participantRoles.count, 2)
        XCTAssertEqual(conversation.participantRoles.first { $0.user == user1 }?.role, role1)
        XCTAssertEqual(conversation.participantRoles.first { $0.user == user2 }?.role, role2)
    }

    func testThatItRefetchesRolesIfNoRoles() {
        syncMOC.performGroupedAndWait {
            // given

            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            conversation.conversationType = .group
            conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

            // when
            conversation.markToDownloadRolesIfNeeded()

            // then
            XCTAssertTrue(conversation.needsToDownloadRoles)
        }
    }

    func testThatItRefetchesRolesIfRolesAreEmpty() {
        syncMOC.performGroupedAndWait {
            // given

            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            conversation.conversationType = .group
            let role = Role.create(managedObjectContext: self.syncMOC, name: "foo", conversation: conversation)
            conversation.addParticipantAndUpdateConversationState(user: selfUser, role: role)

            // when
            conversation.markToDownloadRolesIfNeeded()

            // then
            XCTAssertTrue(conversation.needsToDownloadRoles)
        }
    }

    func testThatItDoesNotRefetchRolesIfRolesAreNotEmpty() {
        syncMOC.performGroupedAndWait {
            // given

            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            conversation.conversationType = .group
            let role = Role.create(managedObjectContext: self.syncMOC, name: "foo", conversation: conversation)
            let action = Action.fetchOrCreate(name: "delete", in: self.syncMOC)
            role.actions.insert(action)
            conversation.addParticipantAndUpdateConversationState(user: selfUser, role: role)

            // when
            conversation.markToDownloadRolesIfNeeded()

            // then
            XCTAssertFalse(conversation.needsToDownloadRoles)
        }
    }
}
