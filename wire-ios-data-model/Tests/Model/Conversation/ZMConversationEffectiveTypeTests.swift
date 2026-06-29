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
@testable import WireDataModel

/// Verifies that the persisted `effectiveConversationType` mirror is kept in sync (in `-willSave`) with the computed
/// `conversationType`, including the team-1:1 / service promotion.
final class ZMConversationEffectiveTypeTests: ZMBaseManagedObjectTest {

    func testThatEffectiveTypeMatchesPlainGroup() throws {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        conversation.conversationType = .group
        conversation.userDefinedName = "a group"

        try uiMOC.save()

        XCTAssertEqual(conversation.conversationType, .group)
        XCTAssertEqual(conversation.effectiveConversationType, .group)
    }

    func testThatEffectiveTypeMatchesOneOnOne() throws {
        let user = createUser(in: uiMOC)
        _ = createConnection(status: .accepted, to: user, in: uiMOC)

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        conversation.conversationType = .oneOnOne
        conversation.oneOnOneUser = user

        try uiMOC.save()

        XCTAssertEqual(conversation.conversationType, .oneOnOne)
        XCTAssertEqual(conversation.effectiveConversationType, .oneOnOne)
    }

    func testThatEffectiveTypePromotesTeamOneOnOne() throws {
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let team = createTeam(in: uiMOC)
        createMembership(in: uiMOC, user: selfUser, team: team)

        let teamUser = createUser(in: uiMOC)
        createMembership(in: uiMOC, user: teamUser, team: team)

        // A team 1:1 is stored as a group with no name and exactly two participants.
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        conversation.conversationType = .group
        conversation.team = team
        conversation.userDefinedName = nil
        conversation.addParticipantsAndUpdateConversationState(users: [selfUser, teamUser], role: nil)

        try uiMOC.save()

        // The computed getter promotes it to one-on-one, and the persisted mirror must agree.
        XCTAssertEqual(conversation.conversationType, .oneOnOne)
        XCTAssertEqual(conversation.effectiveConversationType, .oneOnOne)
    }

    func testThatEffectiveTypeUpdatesWhenAPromotedConversationGainsAName() throws {
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let team = createTeam(in: uiMOC)
        createMembership(in: uiMOC, user: selfUser, team: team)
        let teamUser = createUser(in: uiMOC)
        createMembership(in: uiMOC, user: teamUser, team: team)

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = .create()
        conversation.conversationType = .group
        conversation.team = team
        conversation.addParticipantsAndUpdateConversationState(users: [selfUser, teamUser], role: nil)
        try uiMOC.save()
        XCTAssertEqual(conversation.effectiveConversationType, .oneOnOne)

        // Giving it a user-defined name breaks the promotion: it becomes a real group again.
        conversation.userDefinedName = "named now"
        try uiMOC.save()

        XCTAssertEqual(conversation.conversationType, .group)
        XCTAssertEqual(conversation.effectiveConversationType, .group)
    }
}
