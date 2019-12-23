//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
@testable import WireDataModel

extension ZMConversationTransportTests {

    func testThatItDoesNotUpdatesLastModifiedDateIfAlreadyExists() {
        syncMOC.performGroupedAndWait() {_ in
            // given
            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let uuid = UUID.create()
            conversation.remoteIdentifier = uuid
            let currentTime = Date()

            // assume that the backup date is one day before
            let lastModifiedDate = currentTime.addingTimeInterval(86400)
            conversation.lastModifiedDate = lastModifiedDate
            let serverTimestamp = currentTime

            let payload = self.payloadForMetaData(of: conversation, conversationType: .group, isArchived: true, archivedRef: currentTime, isSilenced: true, silencedRef: currentTime, silencedStatus: nil)

            // when
            conversation.update(transportData: payload as! [String: Any], serverTimeStamp: serverTimestamp)

            // then
            XCTAssertEqual(conversation.lastServerTimeStamp, serverTimestamp)
            XCTAssertEqual(conversation.lastModifiedDate, lastModifiedDate)
            XCTAssertNotEqual(conversation.lastModifiedDate, serverTimestamp)
        }
    }
    
    func testThatItDoesNotUpdateArchivedChangedWhenParsingSelfUser() {
        // Test that, if the conversation is new (self user is not there yet)
        // and we parse the payload, this won't alter the `archivedChangedTimestamp`
        // like it would normally do when adding the self user to a conversation
        // that the self user did not belong to
        syncMOC.performGroupedAndWait() {_ in
            // given
            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let uuid = UUID.create()
            conversation.remoteIdentifier = uuid
            conversation.archivedChangedTimestamp = nil
            
            let payload = self.payloadForMetaData(
                of: conversation,
                conversationType: .group,
                isArchived: false,
                archivedRef: nil,
                isSilenced: false,
                silencedRef: nil,
                silencedStatus: nil)
            
            // when
            conversation.update(transportData: payload as! [String: Any], serverTimeStamp: Date())
            
            // then
            XCTAssertFalse(conversation.isArchived)
            XCTAssertNil(conversation.archivedChangedTimestamp)
        }
    }
    
    func testThatItParserRolesFromConversationMetadataNotInTeam() {
        
        syncMOC.performGroupedAndWait() { _ -> () in
            // given
            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            let user1ID = UUID.create()
            let user2ID = UUID.create()
            
            let payload = self.simplePayload(
                conversation: conversation,
                team: nil,
                otherActiveUsersAndRoles: [
                    (user1ID, nil),
                    (user2ID, "test_role")
                ]
            )
            
            // when
            conversation.update(transportData: payload, serverTimeStamp: Date())
            
            // then
            XCTAssertEqual(
                Set(conversation.localParticipants.map { $0.remoteIdentifier }),
                Set([user1ID, user2ID, selfUser.remoteIdentifier!])
            )
            guard let participant1 = conversation.participantForUser(id: user1ID),
                let participant2 = conversation.participantForUser(id: user2ID)
                else { return XCTFail() }
            
            XCTAssertNil(participant1.role)
            XCTAssertEqual(participant2.role?.name, "test_role")
            XCTAssertEqual(conversation.nonTeamRoles.count, 1)
            XCTAssertEqual(conversation.nonTeamRoles.first, participant2.role)
        }
    }
    
    func testThatItParserRolesFromConversationMetadataInTeam() {
        
        syncMOC.performGroupedAndWait() { _ -> () in
            // given
            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            let user1ID = UUID.create()
            let user2ID = UUID.create()
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = UUID.create()
            
            let payload = self.simplePayload(
                conversation: conversation,
                team: team,
                otherActiveUsersAndRoles: [
                    (user1ID, "test_role1"),
                    (user2ID, "test_role2")
                ]
            )
            
            // when
            conversation.update(transportData: payload, serverTimeStamp: Date())
            
            // then
            XCTAssertEqual(
                Set(conversation.localParticipants.map { $0.remoteIdentifier }),
                Set([user1ID, user2ID, selfUser.remoteIdentifier!])
            )
            guard let participant1 = conversation.participantForUser(id: user1ID),
                let participant2 = conversation.participantForUser(id: user2ID)
                else { return XCTFail() }
            
            XCTAssertEqual(participant1.role?.team, team)
            XCTAssertEqual(participant2.role?.team, team)
            XCTAssertEqual(participant1.role?.name, "test_role1")
            XCTAssertEqual(participant2.role?.name, "test_role2")
            XCTAssertEqual(team.roles, Set([participant1.role, participant2.role].compactMap {$0}))
            
        }
    }
    
    func testThatItChangesRolesFromMetadataInTeam() {
        
        syncMOC.performGroupedAndWait() { _ -> () in
            // given
            
            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            let user1 = ZMUser.insertNewObject(in: self.syncMOC)
            user1.name = "U1"
            user1.remoteIdentifier = UUID.create()
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = UUID.create()
            conversation.team = team
            let oldRole = Role.create(managedObjectContext: self.syncMOC, name: "ROLE1", team: team)
            conversation.addParticipantAndUpdateConversationState(user: user1, role: oldRole)
            
            let payload = self.simplePayload(
                conversation: conversation,
                team: team,
                otherActiveUsersAndRoles: [
                    (user1.remoteIdentifier, "new_role")
                ]
            )
            
            // when
            conversation.update(transportData: payload, serverTimeStamp: Date())
            
            // then
            XCTAssertEqual(conversation.localParticipants, Set([user1, selfUser]))
            guard let newRole = conversation.participantForUser(user1)?.role
                else { return XCTFail() }
            
            XCTAssertNotEqual(oldRole, newRole)
            XCTAssertEqual(newRole.team, team)
            XCTAssertEqual(newRole.name, "new_role")
            XCTAssertEqual(team.roles, Set([newRole, oldRole]))
        }
    }
    
    func testThatItResuesExistingTeamRolesWhenParsingMetadata() {
        
        syncMOC.performGroupedAndWait() { _ -> () in
            // given
            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            let user1ID = UUID.create()
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = UUID.create()
            let teamRole = Role.create(managedObjectContext: self.syncMOC, name: "role1", team: team)
            
            let payload = self.simplePayload(
                conversation: conversation,
                team: team,
                otherActiveUsersAndRoles: [
                    (user1ID, "role1")
                ]
            )
            
            // when
            conversation.update(transportData: payload, serverTimeStamp: Date())
            
            // then
            XCTAssertEqual(
                Set(conversation.localParticipants.map { $0.remoteIdentifier }),
                Set([user1ID, selfUser.remoteIdentifier!])
            )
            guard let participant1 = conversation.participantForUser(id: user1ID)
                else { return XCTFail() }
            
            XCTAssertEqual(participant1.role, teamRole)
            
        }
    }
    
    func testThatItParserSelfRoleFromConversationMetadataInTeam() {
        
        syncMOC.performGroupedAndWait() { _ -> () in
            // given
            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            let team = Team.insertNewObject(in: self.syncMOC)
            team.remoteIdentifier = UUID.create()
            
            let payload = self.simplePayload(
                conversation: conversation,
                team: team,
                selfRole: "test_role"
            )
            
            // when
            conversation.update(transportData: payload, serverTimeStamp: Date())
            
            // then
            XCTAssertEqual(conversation.localParticipants, [selfUser])
            guard let selfRole = conversation.participantForUser(selfUser)?.role else {
                return XCTFail()
            }
            XCTAssertEqual(selfRole.team, team)
            XCTAssertEqual(selfRole.name, "test_role")
            XCTAssertEqual(team.roles, Set([selfRole]))
            
        }
    }
    
    func testThatItParserSelfRoleFromConversationMetadataNotInTeam() {
        
        syncMOC.performGroupedAndWait() { _ -> () in
            // given
            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            
            let payload = self.simplePayload(
                conversation: conversation,
                team: nil,
                selfRole: "test_role"
            )
            
            // when
            conversation.update(transportData: payload, serverTimeStamp: Date())
            
            // then
            XCTAssertEqual(conversation.localParticipants, [selfUser])
            guard let selfRole = conversation.participantForUser(selfUser)?.role else {
                return XCTFail()
            }
            XCTAssertEqual(selfRole.conversation, conversation)
            XCTAssertEqual(selfRole.name, "test_role")
            XCTAssertEqual(conversation.participantRoles.map { $0.role }, [selfRole])
        }
    }
    
    func testThatItParsesSelfUserFragmentWithRole() {
        
        // given
        let conversation = ZMConversation.insertNewObject(in: self.uiMOC)
        let selfUser = ZMUser.selfUser(in: self.uiMOC)
        selfUser.remoteIdentifier = UUID.create()
        conversation.remoteIdentifier = UUID.create()
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
        
        // when
        conversation.updateSelfStatus(
            dictionary: [
                "id": selfUser.remoteIdentifier.transportString(),
                "conversation_role": "boss"
            ],
            timeStamp: nil,
            previousLastServerTimeStamp: nil)
        
        // then
        XCTAssertEqual(conversation.participantRoles.first?.role?.name, "boss")
    }
    
    func testThatItRefetchesRolesIfNoRolesAfterUpdate() {
        
        syncMOC.performGroupedAndWait() { _ -> () in
            // given
            
            ZMUser.selfUser(in: self.syncMOC).teamIdentifier = UUID()
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            let selfUser = ZMUser.selfUser(in: self.syncMOC)
            conversation.remoteIdentifier = UUID.create()
            conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)
            let payload = self.simplePayload(
                conversation: conversation,
                team: nil,
                selfRole: "test_role"
            )
            
            // when
            conversation.update(transportData: payload, serverTimeStamp: Date())
            
            // then
            XCTAssertTrue(conversation.needsToDownloadRoles)
        }
    }
    
}

extension ZMConversation {
    
    fileprivate func participantForUser(_ user: ZMUser) -> ParticipantRole?  {
        return self.participantForUser(id: user.remoteIdentifier!)
    }
    
    fileprivate func participantForUser(id: UUID) -> ParticipantRole? {
        return self.participantRoles.first(where: { $0.user.remoteIdentifier == id })
    }
}

extension ZMConversationTransportTests {
    
    func simplePayload(
        conversation: ZMConversation,
        team: Team?,
        selfRole: String? = nil,
        conversationType: BackendConversationType = BackendConversationType.group,
        otherActiveUsersAndRoles: [(UUID, String?)] = []
        ) -> [String: Any] {
        
        let others = otherActiveUsersAndRoles.map { id, role -> [String: Any] in
            var dict: [String: Any] = ["id": id.transportString()]
            if let role = role {
                dict["conversation_role"] = role
            }
            return dict
        }
        
        return [
            "name": NSNull(),
            "creator": "3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
            "members": [
                "self": [
                    "id" : ZMUser.selfUser(in: conversation.managedObjectContext!).remoteIdentifier.transportString(),
                    "conversation_role": (selfRole ?? NSNull()) as Any
                ],
                "others": others,
            ],
            "type" : conversationType.rawValue,
            "id" : conversation.remoteIdentifier?.transportString() ?? "",
            "team": team?.remoteIdentifier?.transportString() ?? NSNull(),
            "access": [],
            "access_role": "non_activated",
            "receipt_mode": 0
        ]
    }
}

