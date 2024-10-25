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

import WireDataModelSupport
import WireTestingPackage
import XCTest

@testable import Wire

final class ArchivedListViewModelTests: XCTestCase {
    private var stack: CoreDataStack!
    private var userSession: UserSessionMock!
    private var sut: ArchivedListViewModel!

    @MainActor
    override func setUp() async throws {
        let modelHelper = ModelHelper()
        stack = try await CoreDataStackHelper().createStack()
        userSession = UserSessionMock()
        userSession.mockConversationList = ConversationList(
            allConversations: ["A", "B", "C"].map { name in
                let conversation = modelHelper.createGroupConversation(in: stack.viewContext)
                conversation.userDefinedName = name
                conversation.isArchived = true
                return conversation
            },
            filteringPredicate: .init(value: true),
            managedObjectContext: .init(concurrencyType: .mainQueueConcurrencyType),
            description: "mock conversations"
        )
        sut = ArchivedListViewModel(userSession: userSession)
    }

    override func tearDown() async throws {
        stack = nil
        userSession = nil
        sut = nil
    }

    func testUnarchiveConversation() throws {
        // given
        let selectedRow = 1
        let objectID = sut[selectedRow].objectID

        // when
        sut.unarchiveConversation(at: 1)

        // then
        let fetchRequest = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
        let conversations = try stack.viewContext.fetch(fetchRequest)
        let unarchived = conversations.filter { !$0.isArchived }

        XCTAssertEqual(unarchived.count, 1)
        XCTAssertEqual(unarchived.first?.objectID, objectID)
    }
}
