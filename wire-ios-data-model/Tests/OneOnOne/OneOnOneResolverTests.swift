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

final class OneOnOneResolverTests: ZMBaseManagedObjectTest {

    var sut: OneOnOneResolver!
    var protocolSelector: MockOneOnOneProtocolSelectorInterface!
    var migrator: MockOneOnOneMigratorInterface!

    override func setUp() {
        super.setUp()
        protocolSelector = MockOneOnOneProtocolSelectorInterface()
        migrator = MockOneOnOneMigratorInterface()
        sut = OneOnOneResolver(protocolSelector: protocolSelector, migrator: migrator)
    }

    override func tearDown() {
        sut = nil
        protocolSelector = nil
        migrator = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_ResolveOneOnOneConversation_MLSSupported() async throws {
        // Given
        let userID: QualifiedID = .random()

        await uiMOC.perform {
            let user = ZMUser.insertNewObject(in: self.uiMOC)
            user.remoteIdentifier = userID.uuid
            user.domain = userID.domain
        }

        // Mock
        protocolSelector.getProtocolInsersectionBetweenSelfUserOtherUserIn_MockValue = .mls
        migrator.migrateToMLSUserIn_MockMethod = { _, _ in .random() }

        // When
        try await sut.resolveOneOnOneConversation(with: userID, in: uiMOC)

        // Then
        XCTAssertEqual(migrator.migrateToMLSUserIn_Invocations.count, 1)
        let invocation = try XCTUnwrap(migrator.migrateToMLSUserIn_Invocations.first)

        await uiMOC.perform {
            XCTAssertEqual(invocation.user.qualifiedID, userID)
        }
    }

    func test_ResolveOneOnOneConversation_ProteusSupported() async throws {
        // Given
        // Mock
        protocolSelector.getProtocolInsersectionBetweenSelfUserOtherUserIn_MockValue = .proteus

        let user = await uiMOC.perform {
            let userID = QualifiedID.random()
            let user = ZMUser.insertNewObject(in: self.uiMOC)
            user.remoteIdentifier = userID.uuid
            user.domain = userID.domain
            return user
        }

        // When
        try await sut.resolveOneOnOneConversation(with: user, in: uiMOC)

        // Then
        XCTAssertEqual(migrator.migrateToMLSUserIn_Invocations.count, 0)
    }

    func test_ResolveOneOnOneConversation_NoCommonProtocols() async throws {
        // Given
        let userID = QualifiedID.random()

        let conversation = await uiMOC.perform { [self] in
            let user = createUser(in: uiMOC)
            user.remoteIdentifier = userID.uuid
            user.domain = userID.domain

            let (_, conversation) = createConnection(
                status: .pending,
                to: user,
                in: uiMOC
            )

            XCTAssertEqual(conversation.messageProtocol, .proteus)
            XCTAssertFalse(conversation.isForcedReadOnly)

            return conversation
        }

        // Mock
        protocolSelector.getProtocolInsersectionBetweenSelfUserOtherUserIn_MockValue = .some(nil)

        // When
        try await sut.resolveOneOnOneConversation(with: userID, in: uiMOC)

        // Then
        await uiMOC.perform {
            XCTAssertEqual(conversation.messageProtocol, .proteus)
            XCTAssertTrue(conversation.isForcedReadOnly)
        }
    }
}
