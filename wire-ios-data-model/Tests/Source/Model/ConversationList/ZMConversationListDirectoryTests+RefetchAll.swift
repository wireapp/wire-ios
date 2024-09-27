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

final class ZMConversationListDirectoryTests_RefetchAll: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()

        let coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()

        await coreDataStack.viewContext.perform { [self] in
            team = Team.insertNewObject(in: coreDataStack.viewContext)
            team.remoteIdentifier = .create()

            oneToOneTeamConversation = createOneToOneTeamConversation(in: team)

            sut = coreDataStack.viewContext.conversationListDirectory()
        }
    }

    override func tearDown() async throws {
        sut = nil
        team = nil
        coreDataStack = nil
        oneToOneTeamConversation = nil
        try await super.tearDown()
    }

    func testRefetchAllConversations_FindsOneToOneTeamConversation_AfterSettingTeamForSelfUser() async {
        await coreDataStack.viewContext.perform { [self] in
            // GIVEN
            let membership = Member.insertNewObject(in: coreDataStack.viewContext)
            membership.team = team
            let selfUser = ZMUser.selfUser(in: coreDataStack.viewContext)
            selfUser.membership = membership

            XCTAssertTrue(sut.conversationsIncludingArchived.items.isEmpty)

            // WHEN
            sut.refetchAllLists(in: coreDataStack.viewContext)

            // THEN
            XCTAssertEqual(sut.conversationsIncludingArchived.items, [oneToOneTeamConversation])
        }
    }

    // MARK: Private

    private var coreDataStack: CoreDataStack!
    private var sut: ZMConversationListDirectory!
    private var team: Team!
    private var oneToOneTeamConversation: ZMConversation!

    private func createOneToOneTeamConversation(
        in team: Team
    ) -> ZMConversation {
        let membership = Member.insertNewObject(in: coreDataStack.viewContext)
        membership.team = team

        let user = ZMUser.insertNewObject(in: coreDataStack.viewContext)
        user.membership = membership

        let conversation = ZMConversation.insertNewObject(in: coreDataStack.viewContext)
        conversation.lastServerTimeStamp = Date()
        conversation.lastReadServerTimeStamp = conversation.lastServerTimeStamp
        conversation.remoteIdentifier = .create()
        conversation.team = team
        conversation.isArchived = false
        conversation.conversationType = .oneOnOne
        conversation.messageProtocol = .proteus
        conversation.oneOnOneUser = user

        return conversation
    }
}
