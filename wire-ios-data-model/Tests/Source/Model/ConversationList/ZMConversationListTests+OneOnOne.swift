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
@testable import WireDataModel

final class ZMConversationListTests_OneOnOne: ZMBaseManagedObjectTest {
    func testThatItReturnsAllOneOnOneConversations() throws {
        // Given
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let connectedUser = createUser(in: uiMOC)
        let unconnectedUser = createUser(in: uiMOC)
        let teamUser = createUser(in: uiMOC)

        _ = createConnection(status: .accepted, to: connectedUser, in: uiMOC)

        let team = createTeam(in: uiMOC)
        createMembership(in: uiMOC, user: selfUser, team: team)
        createMembership(in: uiMOC, user: teamUser, team: team)

        let oneOnOneConversation = ZMConversation.insertNewObject(in: uiMOC)
        oneOnOneConversation.remoteIdentifier = .create()
        oneOnOneConversation.conversationType = .oneOnOne
        oneOnOneConversation.oneOnOneUser = connectedUser

        let fakeOneOnOne = ZMConversation.insertNewObject(in: uiMOC)
        fakeOneOnOne.remoteIdentifier = .create()
        fakeOneOnOne.team = team
        fakeOneOnOne.conversationType = .group
        fakeOneOnOne.addParticipantsAndUpdateConversationState(users: [selfUser, teamUser], role: nil)
        fakeOneOnOne.oneOnOneUser = teamUser
        XCTAssertEqual(fakeOneOnOne.conversationType, .oneOnOne)

        let unconnectedConversation = ZMConversation.insertNewObject(in: uiMOC)
        unconnectedConversation.remoteIdentifier = .create()
        unconnectedConversation.conversationType = .connection
        unconnectedConversation.oneOnOneUser = unconnectedUser

        try uiMOC.save()

        let predicateFactory = ConversationPredicateFactory(selfTeam: team)

        // When
        let sut = ConversationList(
            allConversations: [oneOnOneConversation, fakeOneOnOne, unconnectedConversation],
            filteringPredicate: predicateFactory.predicateForOneToOneConversations(),
            managedObjectContext: uiMOC,
            description: "oneToOneConversations"
        )

        // Then
        XCTAssertEqual(Set(sut.items), [oneOnOneConversation, fakeOneOnOne, unconnectedConversation])
    }

    func testThatItDoesNotReturnNonOneOnOneConversations() throws {
        // Given
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let connectedUser = createUser(in: uiMOC)
        _ = createConnection(status: .accepted, to: connectedUser, in: uiMOC)

        let groupConversation = ZMConversation.insertNewObject(in: uiMOC)
        groupConversation.remoteIdentifier = .create()
        groupConversation.conversationType = .group
        groupConversation.userDefinedName = "Amazing group"
        groupConversation.addParticipantsAndUpdateConversationState(users: [selfUser, connectedUser], role: nil)

        let invalidOneOnOneConversation = ZMConversation.insertNewObject(in: uiMOC)
        invalidOneOnOneConversation.remoteIdentifier = .create()
        invalidOneOnOneConversation.conversationType = .oneOnOne
        invalidOneOnOneConversation.oneOnOneUser = nil

        try uiMOC.save()

        let predicateFactory = ConversationPredicateFactory(selfTeam: nil)

        // When
        let sut = ConversationList(
            allConversations: [groupConversation, invalidOneOnOneConversation],
            filteringPredicate: predicateFactory.predicateForOneToOneConversations(),
            managedObjectContext: uiMOC,
            description: "oneToOneConversations"
        )

        // Then
        XCTAssertEqual(sut.items, [])
    }
}
