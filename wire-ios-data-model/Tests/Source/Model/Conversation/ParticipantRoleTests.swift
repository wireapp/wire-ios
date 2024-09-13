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

class ParticipantRoleTests: ZMBaseManagedObjectTest {
    var user: ZMUser!
    var conversation: ZMConversation!
    var role: Role!

    override func setUp() {
        super.setUp()
        user = ZMUser.insertNewObject(in: uiMOC)
        conversation = ZMConversation.insertNewObject(in: uiMOC)
        role = Role.insertNewObject(in: uiMOC)
    }

    private func createParticipantRole() -> ParticipantRole {
        let pr = ParticipantRole.insertNewObject(in: uiMOC)
        pr.user = user
        pr.conversation = conversation
        pr.role = role
        return pr
    }

    func testThatServicesBelongToOneToOneConversations() throws {
        // GIVEN
        let selfUser = ZMUser.selfUser(in: uiMOC)
        let service = createService(in: uiMOC, named: "Bob the Robot")

        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = UUID.create()

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID()
        conversation.conversationType = .group
        conversation.team = team

        let serviceUser = try XCTUnwrap(service as? ZMUser)
        conversation.oneOnOneUser = serviceUser

        // WHEN
        conversation.addParticipantAndUpdateConversationState(user: serviceUser, role: nil)
        conversation.addParticipantAndUpdateConversationState(user: selfUser, role: nil)

        // THEN
        let factory = ConversationPredicateFactory(selfTeam: team)
        XCTAssertTrue(factory.predicateForOneToOneConversations().evaluate(with: conversation))
    }
}
