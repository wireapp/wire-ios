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

final class ZMConversationTests_Services: BaseZMMessageTests {

    var team: Team!
    var service: ServiceUser!
    var user: ZMUser!

    override func setUp() {
        super.setUp()
        team = createTeam(in: uiMOC)
        service = createService(in: uiMOC, named: "Botty")
        user = createUser(in: uiMOC)
    }

    override func tearDown() {
        super.tearDown()
        team = nil
        service = nil
        user = nil
    }

    func createConversation(with service: ServiceUser) throws -> ZMConversation {
        let conversation = createConversation(in: uiMOC)
        conversation.team = team
        conversation.conversationType = .group
        let serviceUser = try XCTUnwrap(service as? ZMUser)
        conversation.oneOnOneUser = serviceUser
        conversation.addParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: uiMOC), role: nil)
        conversation.addParticipantAndUpdateConversationState(user: serviceUser, role: nil)
        try uiMOC.save()
        return conversation
    }

    func testThatConversationIsNotFoundWhenThereIsNoTeam() {
        // when
        let conversation = ZMConversation.existingConversation(in: uiMOC, service: service, team: nil)

        // then
        XCTAssertNil(conversation)
    }

    func testThatConversationIsNotFoundWhenUserIsNotAService() {
        // when
        let conversation = ZMConversation.existingConversation(in: uiMOC, service: user, team: team)

        // then
        XCTAssertNil(conversation)
    }

    func testThatItFindsConversationWithService() throws {
        // given
        let existingConversation = try createConversation(with: service)

        // when
        let conversation = ZMConversation.existingConversation(in: uiMOC, service: service, team: team)

        // then
        XCTAssertNotNil(conversation)
        XCTAssertEqual(existingConversation, conversation)
    }

    func testThatItDoesNotFindConversationWithMoreMembers() throws {
        // given
        let existingConversation = try createConversation(with: service)
        existingConversation.addParticipantAndUpdateConversationState(user: createUser(in: uiMOC), role: nil)

        // when
        let conversation = ZMConversation.existingConversation(in: uiMOC, service: service, team: team)

        // then
        XCTAssertNil(conversation)
    }

    func testThatItChecksOnlyConversationsWhereIAmPresent() throws {
        // given
        let existingConversation = try createConversation(with: service)

        // when
        existingConversation.removeParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: uiMOC))
        let conversation = ZMConversation.existingConversation(in: uiMOC, service: service, team: team)

        // then
        XCTAssertNil(conversation)
    }

    func testThatItChecksOnlyConversationsWithNoUserDefinedName() throws {
        // given
        let existingConversation = try createConversation(with: service)

        // when
        existingConversation.userDefinedName = "First"
        let conversation = ZMConversation.existingConversation(in: uiMOC, service: service, team: team)

        // then
        XCTAssertNil(conversation)
    }

    func testThatItFindsConversationWithCorrectService() throws {
        // given
        let existingConversation = try createConversation(with: service)
        _ = try createConversation(with: createService(in: uiMOC, named: "BAD"))

        // when
        let conversation = ZMConversation.existingConversation(in: uiMOC, service: service, team: team)

        // then
        XCTAssertNotNil(conversation)
        XCTAssertEqual(existingConversation, conversation)
    }

}
