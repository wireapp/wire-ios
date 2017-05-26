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
import WireDataModel
@testable import WireMockTransport

class MockTransportSessionTeamEventsTests : MockTransportSessionTests {
    
    func check(event: TestPushChannelEvent?, hasType type: ZMTUpdateEventType, team: MockTeam, data: [String : String]? = nil, file: StaticString = #file, line: UInt = #line) {
        check(event: event, hasType: type, teamIdentifier: team.identifier, data: data, file: file, line: line)
    }
    
    func check(event: TestPushChannelEvent?, hasType type: ZMTUpdateEventType, teamIdentifier: String, data: [String : String]? = nil, file: StaticString = #file, line: UInt = #line) {
        guard let event = event else { XCTFail("Should have event", file: file, line: line); return }
        
        XCTAssertEqual(event.type, type, "Wrong type", file: file, line: line)
        
        guard let payload = event.payload as? [String : Any] else { XCTFail("Event should have payload", file: file, line: line); return }
        
        XCTAssertEqual(payload["team"] as? String, teamIdentifier, "Wrong team identifier", file: file, line: line)
        
        guard let expectedData = data else {
            return
        }
        guard let data = payload["data"] as? [String : String] else { XCTFail("Event payload should have data", file: file, line: line); return }

        for (key, value) in expectedData {
            guard let dataValue = data[key] else {
                XCTFail("Event payload data does not contain key: \"\(key)\"", file: file, line: line)
                continue
            }
            XCTAssertEqual(dataValue, value, "Event payload data for \"\(key)\" does not match, expected \"\(value)\", got \"\(dataValue)\"", file: file, line: line)
        }
    }
}

// MARK: - Team events
extension MockTransportSessionTeamEventsTests {

    func testThatItCreatesEventsForInsertedTeams() {
        // Given
        let name1 = "foo"
        let name2 = "bar"
        
        var team1: MockTeam!
        var team2: MockTeam!
        
        createAndOpenPushChannel()
        
        // When
        sut.performRemoteChanges { session in
            team1 = session.insertTeam(withName: name1, users: [self.sut.selfUser])
            team2 = session.insertTeam(withName: name2, users: [self.sut.selfUser])
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        let events = pushChannelReceivedEvents as! [TestPushChannelEvent]
        XCTAssertEqual(events.count, 2)
        
        check(event: events.first, hasType: .ZMTUpdateEventTeamCreate, team: team1)
        check(event: events.last, hasType: .ZMTUpdateEventTeamCreate, team: team2)
    }
    
    func testThatItCreatesEventsForDeletedTeams() {
        // Given
        var team: MockTeam!
        var teamIdentifier: String!
        
        sut.performRemoteChanges { session in
            let selfUser = session.insertSelfUser(withName: "Am I")
            team = session.insertTeam(withName: "some", users: [selfUser])
            teamIdentifier = team.identifier
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        createAndOpenPushChannelAndCreateSelfUser(false)

        // When
        sut.performRemoteChanges { session in
            session.delete(team)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // Then
        let events = pushChannelReceivedEvents as! [TestPushChannelEvent]
        XCTAssertEqual(events.count, 1)
        
        check(event: events.first, hasType: .ZMTUpdateEventTeamDelete, teamIdentifier: teamIdentifier)
    }
    
    func testThatItCreatesEventsForUpdatedTeams() {
        // Given
        var team: MockTeam!
        
        sut.performRemoteChanges { session in
            let selfUser = session.insertSelfUser(withName: "Am I")
            team = session.insertTeam(withName: "some", users: [selfUser])
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        createAndOpenPushChannelAndCreateSelfUser(false)
        
        // When
        let newName = "other"
        let assetKey = "123-082"
        let assetId = "541-992"
        sut.performRemoteChanges { session in
            team.name = newName
            team.pictureAssetId = assetId
            team.pictureAssetKey = assetKey
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // Then
        let events = pushChannelReceivedEvents as! [TestPushChannelEvent]
        XCTAssertEqual(events.count, 1)
        
        let updateData = [
            "name" : newName,
            "icon" : assetId,
            "icon_key" : assetKey
        ]
        check(event: events.first, hasType: .ZMTUpdateEventTeamUpdate, team: team, data: updateData)
    }
    
    func testThatItCreatesEventsForUpdatedTeamsAndHasOnlyChangedData() {
        // Given
        var team: MockTeam!
        
        sut.performRemoteChanges { session in
            let selfUser = session.insertSelfUser(withName: "Am I")
            team = session.insertTeam(withName: "some", users: [selfUser])
            team.pictureAssetId = "123-082"
            team.pictureAssetKey = "541-992"
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        createAndOpenPushChannelAndCreateSelfUser(false)
        
        // When
        let newName = "other"
        sut.performRemoteChanges { session in
            team.name = newName
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // Then
        let events = pushChannelReceivedEvents as! [TestPushChannelEvent]
        XCTAssertEqual(events.count, 1)
        
        let updateData = [
            "name" : newName,
        ]
        check(event: events.first, hasType: .ZMTUpdateEventTeamUpdate, team: team, data: updateData)
    }

}

// MARK: - Members events
extension MockTransportSessionTeamEventsTests {
    
    func testThatItCreatesEventWhenMemberJoinsTheTeam() {
        // Given
        var team: MockTeam!
        
        sut.performRemoteChanges { session in
            let selfUser = session.insertSelfUser(withName: "Am I")
            team = session.insertTeam(withName: "some", users: [selfUser])
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        createAndOpenPushChannelAndCreateSelfUser(false)
        
        // When
        var newUser: MockUser!
        sut.performRemoteChanges { session in
            newUser = session.insertUser(withName: "name")
            _ = session.insertMember(with: newUser, in: team)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // Then
        let events = pushChannelReceivedEvents as! [TestPushChannelEvent]
        XCTAssertEqual(events.count, 1)
        
        let updateData = [
            "user" : newUser.identifier,
            ]
        check(event: events.first, hasType: .ZMTUpdateEventTeamMemberJoin, team: team, data: updateData)
    }
    
    func testThatItCreatesEventWhenMemberIsRemovedFromTeam() {
        // Given
        var team: MockTeam!
        var user: MockUser!
        
        sut.performRemoteChanges { session in
            let selfUser = session.insertSelfUser(withName: "Am I")
            team = session.insertTeam(withName: "some", users: [selfUser])
            user = session.insertUser(withName: "name")
            _ = session.insertMember(with: user, in: team)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        createAndOpenPushChannelAndCreateSelfUser(false)
        
        // When
        sut.performRemoteChanges { session in
            session.removeMember(with: user, from: team)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // Then
        let events = pushChannelReceivedEvents as! [TestPushChannelEvent]
        XCTAssertEqual(events.count, 1)
        
        let updateData = [
            "user" : user.identifier,
            ]
        check(event: events.first, hasType: .ZMTUpdateEventTeamMemberLeave, team: team, data: updateData)
    }
    
    func testThatItCreatesEventsWhenMemberIsAddedToMultipleTeams() {
        // Given
        var team1: MockTeam!
        var team2: MockTeam!
        
        sut.performRemoteChanges { session in
            let selfUser = session.insertSelfUser(withName: "Am I")
            team1 = session.insertTeam(withName: "some", users: [selfUser])
            team2 = session.insertTeam(withName: "other", users: [selfUser])
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        createAndOpenPushChannelAndCreateSelfUser(false)
        
        // When
        var newUser: MockUser!
        sut.performRemoteChanges { session in
            newUser = session.insertUser(withName: "name")
            _ = session.insertMember(with: newUser, in: team1)
            _ = session.insertMember(with: newUser, in: team2)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // Then
        let events = pushChannelReceivedEvents as! [TestPushChannelEvent]
        XCTAssertEqual(events.count, 2)
        
        let updateData = [
            "user" : newUser.identifier,
            ]
        var eventsByTeamId = [String : TestPushChannelEvent]()
        for event in events {
            guard let payload = event.payload as? [String : Any] else { continue }
            guard let teamId = payload["team"] as? String else { continue }
            eventsByTeamId[teamId] = event
        }
        
        check(event: eventsByTeamId[team1.identifier], hasType: .ZMTUpdateEventTeamMemberJoin, team: team1, data: updateData)
        check(event: eventsByTeamId[team2.identifier], hasType: .ZMTUpdateEventTeamMemberJoin, team: team2, data: updateData)
    }
}

// MARK: - Conversation events
extension MockTransportSessionTeamEventsTests {
    func testThatItCreatesEventWhenConversationIsCreatedInTeam() {
        // Given
        var team: MockTeam!
        var user: MockUser!
        
        sut.performRemoteChanges { session in
            let selfUser = session.insertSelfUser(withName: "Am I")
            team = session.insertTeam(withName: "some", users: [selfUser])
            user = session.insertUser(withName: "some user")
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        createAndOpenPushChannelAndCreateSelfUser(false)
        
        // When
        var conversation: MockConversation!
        sut.performRemoteChanges { session in
            conversation = session.insertTeamConversation(to: team, with: [user])
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation.team, team)
        
        // Then
        let events = pushChannelReceivedEvents as! [TestPushChannelEvent]
        XCTAssertEqual(events.count, 1)
        
        let updateData = [
            "conv" : conversation.identifier,
            ]
        check(event: events.first, hasType: .ZMTUpdateEventTeamConversationCreate, team: team, data: updateData)
    }

    func testThatItCreatesEventWhenConversationIsDeletedInTeam() {
        // Given
        var team: MockTeam!
        var user: MockUser!
        var conversation: MockConversation!
        var conversationIdentifier: String!

        sut.performRemoteChanges { session in
            let selfUser = session.insertSelfUser(withName: "Am I")
            team = session.insertTeam(withName: "some", users: [selfUser])
            user = session.insertUser(withName: "some user")
            conversation = session.insertTeamConversation(to: team, with: [user])
            conversationIdentifier = conversation.identifier
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation.team, team)
        createAndOpenPushChannelAndCreateSelfUser(false)
        
        // When
        sut.performRemoteChanges { session in
            session.delete(conversation)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // Then
        let events = pushChannelReceivedEvents as! [TestPushChannelEvent]
        XCTAssertEqual(events.count, 1)
        
        let updateData = [
            "conv" : conversationIdentifier!,
            ]
        check(event: events.first, hasType: .ZMTUpdateEventTeamConversationDelete, team: team, data: updateData)
    }
    
    func testThatItDoesNotSendEventsFromATeamThatYouAreNotAMemberOf() {
        // Given
        createAndOpenPushChannel()
        
        // When
        sut.performRemoteChanges { session in
            let user1 = session.insertUser(withName: "one")
            let team = session.insertTeam(withName: "some", users: [user1])
            
            let user2 = session.insertUser(withName: "some user")
            _ = session.insertTeamConversation(to: team, with: [user1, user2])
        }
        
        // Then
        let events = pushChannelReceivedEvents as! [TestPushChannelEvent]
        XCTAssertEqual(events.count, 0)
    }
    
    func testThatItDoesSendConversationEventsInATeamConversationWhereYouAreGuest() {
        // Given
        createAndOpenPushChannel()
        
        // When
        sut.performRemoteChanges { session in
            let user1 = session.insertUser(withName: "one")
            let team = session.insertTeam(withName: "some", users: [user1])
            
            let user2 = session.insertUser(withName: "some user")
            _ = session.insertTeamConversation(to: team, with: [user1, user2, self.sut.selfUser])
        }
        
        // Then
        let events = pushChannelReceivedEvents as! [TestPushChannelEvent]
        XCTAssertEqual(events.count, 1)

    }
}
