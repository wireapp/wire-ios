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

import WireDataModelSupport
import WireTestingPackage
import XCTest

@testable import Wire

final class ArchivedListViewControllerSnapshotTests: XCTestCase {

    private var userSessionMock: UserSessionMock!
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper()
        userSessionMock = .init()
    }

    override func tearDown() {
        snapshotHelper = nil
        userSessionMock = nil
        super.tearDown()
    }

    func testEmpty() {

        userSessionMock.mockConversationList = ConversationList(
            allConversations: [],
            filteringPredicate: .init(value: true),
            managedObjectContext: .init(concurrencyType: .mainQueueConcurrencyType),
            description: "all conversations"
        )

        let sut = ArchivedListViewController(userSession: userSessionMock)
        snapshotHelper.verify(matching: UINavigationController(rootViewController: sut))
    }

    @MainActor
    func testNonEmpty() async throws {

        let fixture = try await CoreDataFixture()
        let modelHelper = ModelHelper()
        let conversation = modelHelper.createGroupConversation(
            id: .init(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E56")!,
            in: fixture.coreDataStack.viewContext
        )
        conversation.userDefinedName = "Lorem Ipsum"
        conversation.isArchived = true
        userSessionMock.mockConversationList = ConversationList(
            allConversations: [conversation],
            filteringPredicate: .init(value: true),
            managedObjectContext: .init(concurrencyType: .mainQueueConcurrencyType),
            description: "mock conversations"
        )

        let sut = ArchivedListViewController(userSession: userSessionMock)
        snapshotHelper.verify(matching: UINavigationController(rootViewController: sut))
    }
}
