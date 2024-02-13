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

final class OneOnOneProtocolSelectorTests: ZMBaseManagedObjectTest {

    var sut: OneOnOneProtocolSelector!

    override func setUp() {
        super.setUp()
        sut = OneOnOneProtocolSelector()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_GetProtocolForUser_MLS() async throws {
        // Given
        let (selfUser, otherUser) = await createUsersUsingProtocols(
            self: [.proteus, .mls],
            other: [.proteus, .mls],
            in: uiMOC
        )

        // When
        let result = await sut.getProtocolInsersectionBetween(
            selfUser: selfUser,
            otherUser: otherUser,
            in: uiMOC
        )

        // Then
        XCTAssertEqual(result, .mls)
    }

    func test_GetProtocolForUser_Proteus() async throws {
        // Given
        let userID = QualifiedID.random()

        let (selfUser, otherUser) = await createUsersUsingProtocols(
            self: [.proteus, .mls],
            other: [.proteus],
            in: uiMOC
        )

        // When
        let result = await sut.getProtocolInsersectionBetween(
            selfUser: selfUser,
            otherUser: otherUser,
            in: uiMOC
        )

        // Then
        XCTAssertEqual(result, .proteus)
    }

    func test_GetProtocolForUser_NoCommonProtocol() async throws {
        // Given
        let (selfUser, otherUser) = await createUsersUsingProtocols(
            self: [.mls],
            other: [.proteus],
            in: uiMOC
        )

        // When
        let result = await sut.getProtocolInsersectionBetween(
            selfUser: selfUser,
            otherUser: otherUser,
            in: uiMOC
        )

        // Then
        XCTAssertNil(result)
    }

    // MARK: - Helpers

    private func createUsersUsingProtocols(
        self selfProtocols: Set<MessageProtocol>,
        other otherProtocols: Set<MessageProtocol>,
        in context: NSManagedObjectContext
    ) async -> (selfUser: ZMUser, otherUser: ZMUser) {
        await context.perform {
            let otherUser = self.createUser(id: .random(), in: context)
            otherUser.supportedProtocols = otherProtocols

            let selfUser = ZMUser.selfUser(in: context)
            selfUser.supportedProtocols = selfProtocols

            return (selfUser, otherUser)
        }
    }
}
