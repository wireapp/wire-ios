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
@testable import WireDataModelSupport

final class OneOnOneMigratorTests: ZMBaseManagedObjectTest {

    var sut: OneOnOneMigrator!
    var mlsService: MockMLSServiceInterface!

    override func setUp() {
        super.setUp()
        mlsService = MockMLSServiceInterface()
        mlsService.createGroupFor_MockMethod = { _ in }
        mlsService.addMembersToConversationWithFor_MockMethod = { _, _ in}

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
        let mlsGroupID = MLSGroupID.random()

        let (connection, proteusConversation, mlsConversation) = await uiMOC.perform { [self] in
            let user = createUser(id: userID, in: uiMOC)

            let (connection, proteusConversation) = createConnection(
                status: .accepted,
                to: user,
                in: uiMOC
            )

            let mlsConversation = ZMConversation.insertNewObject(in: uiMOC)
            mlsConversation.remoteIdentifier = .create()
            mlsConversation.domain = "local@domain.com"
            mlsConversation.mlsGroupID = mlsGroupID
            mlsConversation.messageProtocol = .mls
            mlsConversation.conversationType = .oneOnOne

            XCTAssertEqual(proteusConversation.oneOnOneUser, user)
            XCTAssertNil(mlsConversation.oneOnOneUser)

            return (
                connection,
                proteusConversation,
                mlsConversation
            )
        }

        // Mock
        _ = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success(mlsGroupID),
            context: uiMOC.notificationContext
        )

        mlsService.conversationExistsGroupID_MockValue = false

        // When
        try await sut.migrateToMLS(
            userID: userID,
            in: uiMOC
        )

        // Then
        XCTAssertEqual(mlsService.createGroupFor_Invocations, [mlsGroupID])
        XCTAssertEqual(mlsService.addMembersToConversationWithFor_Invocations.map(\.users), [[MLSUser(userID)]])
        XCTAssertEqual(mlsService.addMembersToConversationWithFor_Invocations.map(\.groupID), [mlsGroupID])

        await uiMOC.perform {
            XCTAssertEqual(mlsConversation.oneOnOneUser, connection.to)
            XCTAssertNil(proteusConversation.oneOnOneUser)
        }
    }

    func test_MigrateToMLS_ConversationAlreadyExists() async throws {
        // Given
        let userID = QualifiedID.random()
        let mlsGroupID = MLSGroupID.random()

        let (connection, proteusConversation, mlsConversation) = await uiMOC.perform { [self] in
            let user = createUser(id: userID, in: uiMOC)

            let (connection, proteusConversation) = createConnection(
                status: .accepted,
                to: user,
                in: uiMOC
            )

            let mlsConversation = ZMConversation.insertNewObject(in: uiMOC)
            mlsConversation.remoteIdentifier = .create()
            mlsConversation.domain = "local@domain.com"
            mlsConversation.mlsGroupID = mlsGroupID
            mlsConversation.messageProtocol = .mls
            mlsConversation.conversationType = .oneOnOne

            XCTAssertEqual(proteusConversation.oneOnOneUser, user)
            XCTAssertNil(mlsConversation.oneOnOneUser)

            return (
                connection,
                proteusConversation,
                mlsConversation
            )
        }

        // Mock
        _ = MockActionHandler<SyncMLSOneToOneConversationAction>(
            result: .success(mlsGroupID),
            context: uiMOC.notificationContext
        )

        mlsService.conversationExistsGroupID_MockValue = true

        // When
        try await sut.migrateToMLS(
            userID: userID,
            in: uiMOC
        )

        // Then
        XCTAssertTrue(mlsService.createGroupFor_Invocations.isEmpty)
        XCTAssertTrue(mlsService.addMembersToConversationWithFor_Invocations.isEmpty)

        await uiMOC.perform {
            XCTAssertEqual(mlsConversation.oneOnOneUser, connection.to)
            XCTAssertNil(proteusConversation.oneOnOneUser)
        }
    }

}
