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

    func test_ResolveOneOnOneConversation_MLSSupported() throws {
        // Given
        let userID = QualifiedID.random()

        // Mock
        protocolSelector.getProtocolForUserWithIn_MockValue = .mls
        migrator.migrateToMLSUserIDIn_MockMethod = { _, _ in }

        let isDone = XCTestExpectation(description: "isDone")

        // When
        sut.resolveOneOnOneConversation(with: userID, in: uiMOC) {
            switch $0 {
            case .success:
                break

            case .failure(let error):
                XCTFail("unexpected error: \(error)")
            }

            isDone.fulfill()
        }

        wait(for: [isDone])

        // Then
        XCTAssertEqual(migrator.migrateToMLSUserIDIn_Invocations.count, 1)
        let invocation = try XCTUnwrap(migrator.migrateToMLSUserIDIn_Invocations.first)
        XCTAssertEqual(invocation.userID, userID)
    }

    func test_ResolveOneOnOneConversation_ProteusSupported() throws {
        // Given
        let userID = QualifiedID.random()

        // Mock
        protocolSelector.getProtocolForUserWithIn_MockValue = .proteus

        let isDone = XCTestExpectation(description: "isDone")

        // When
        sut.resolveOneOnOneConversation(with: userID, in: uiMOC) {
            switch $0 {
            case .success:
                break

            case .failure(let error):
                XCTFail("unexpected error: \(error)")
            }

            isDone.fulfill()
        }

        wait(for: [isDone])

        // Then
        XCTAssertEqual(migrator.migrateToMLSUserIDIn_Invocations.count, 0)
    }

    func test_ResolveOneOnOneConversation_NoCommonProtocols() throws {
        // Given
        let userID = QualifiedID.random()

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

        // Mock
        protocolSelector.getProtocolForUserWithIn_MockValue = .some(nil)

        let isDone = XCTestExpectation(description: "isDone")

        // When
        sut.resolveOneOnOneConversation(with: userID, in: uiMOC) {
            switch $0 {
            case .success:
                break

            case .failure(let error):
                XCTFail("unexpected error: \(error)")
            }

            isDone.fulfill()
        }

        wait(for: [isDone])

        // Then
        XCTAssertEqual(conversation.messageProtocol, .proteus)
        XCTAssertTrue(conversation.isForcedReadOnly)
    }

}
