//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

import XCTest
@testable import WireDataModel

final class OneOnOneMigratorTests: ZMBaseManagedObjectTest {

    var sut: OneOnOneMigrator!
    var mlsService: MockMLSService!

    override func setUp() {
        super.setUp()
        mlsService = MockMLSService()
        sut = OneOnOneMigrator(mlsService: mlsService)
    }

    override func tearDown() {
        sut = nil
        mlsService = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_MigrateToMLS() async throws {
        // Given
        let userID = QualifiedID.random()
        let user = createUser(id: userID, in: uiMOC)

        let (connection, proteusConversation) = createConnection(
            status: .accepted,
            to: user,
            in: uiMOC
        )

        let mlsGroupID = MLSGroupID.random()
        let mlsConversation = ZMConversation.insertNewObject(in: uiMOC)
        mlsConversation.remoteIdentifier = .create()
        mlsConversation.domain = "local@domain.com"
        mlsConversation.mlsGroupID = mlsGroupID
        mlsConversation.messageProtocol = .mls
        mlsConversation.conversationType = .oneOnOne

        XCTAssertEqual(connection.conversation, proteusConversation)
        XCTAssertNil(mlsConversation.connection)

        // Mock
        _ = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success(mlsGroupID),
            context: uiMOC.notificationContext
        )

        mlsService.conversationExistsMock = { _ in false }

        // When
        try await sut.migrateToMLS(
            userID: userID,
            in: uiMOC
        )

        // Then
        XCTAssertEqual(mlsService.calls.createGroup, [mlsGroupID])
        XCTAssertEqual(mlsService.calls.addMembersToConversation.map(\.0), [[MLSUser(userID)]])
        XCTAssertEqual(mlsService.calls.addMembersToConversation.map(\.1), [mlsGroupID])

        XCTAssertEqual(connection.conversation, mlsConversation)
        XCTAssertNil(proteusConversation.connection)
    }

    func test_MigrateToMLS_ConversationAlreadyExists() async throws {
        // Given
        let userID = QualifiedID.random()
        let user = createUser(id: userID, in: uiMOC)

        let (connection, proteusConversation) = createConnection(
            status: .accepted,
            to: user,
            in: uiMOC
        )

        let mlsGroupID = MLSGroupID.random()
        let mlsConversation = ZMConversation.insertNewObject(in: uiMOC)
        mlsConversation.remoteIdentifier = .create()
        mlsConversation.domain = "local@domain.com"
        mlsConversation.mlsGroupID = mlsGroupID
        mlsConversation.messageProtocol = .mls
        mlsConversation.conversationType = .oneOnOne

        XCTAssertEqual(connection.conversation, proteusConversation)
        XCTAssertNil(mlsConversation.connection)

        // Mock
        _ = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success(mlsGroupID),
            context: uiMOC.notificationContext
        )

        mlsService.conversationExistsMock = { _ in true }

        // When
        try await sut.migrateToMLS(
            userID: userID,
            in: uiMOC
        )

        // Then
        XCTAssertTrue(mlsService.calls.createGroup.isEmpty)
        XCTAssertTrue(mlsService.calls.addMembersToConversation.isEmpty)

        XCTAssertEqual(connection.conversation, mlsConversation)
        XCTAssertNil(proteusConversation.connection)
    }


}
