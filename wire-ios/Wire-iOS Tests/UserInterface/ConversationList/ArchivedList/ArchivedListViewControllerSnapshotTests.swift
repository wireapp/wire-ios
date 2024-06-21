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
import XCTest

@testable import Wire

final class ArchivedListViewControllerSnapshotTests: XCTestCase {

    private var userSessionMock: UserSessionMock!

    override func setUp() {
        super.setUp()
        userSessionMock = .init()
    }

    override func tearDown() {
        userSessionMock = nil
        super.tearDown()
    }

    func testEmpty() {

        userSessionMock.mockConversationList = ZMConversationContainer(
            allConversations: [],
            filteringPredicate: .init(value: true),
            moc: .init(concurrencyType: .mainQueueConcurrencyType),
            description: "all conversations"
        )

        let sut = ArchivedListViewController(userSession: userSessionMock)
        verify(matching: UINavigationController(rootViewController: sut))
    }

    func testNonEmpty() {

        let fixture = CoreDataFixture()
        let modelHelper = ModelHelper()
        let selfUser = modelHelper.createSelfUser(in: fixture.coreDataStack.viewContext)
        let conversation = modelHelper.createGroupConversation(in: fixture.coreDataStack.viewContext)
        conversation.userDefinedName = "Lorem Ipsum"
        conversation.isArchived = true
        userSessionMock.mockConversationList = ZMConversationContainer(
            allConversations: [conversation],
            filteringPredicate: .init(value: true),
            moc: .init(concurrencyType: .mainQueueConcurrencyType),
            description: "mock conversations"
        )

        let sut = ArchivedListViewController(userSession: userSessionMock)
        verify(matching: UINavigationController(rootViewController: sut))
    }
}
