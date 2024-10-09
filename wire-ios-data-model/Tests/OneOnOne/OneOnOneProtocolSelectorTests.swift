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

@testable import WireDataModel
import XCTest

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
        let userID = QualifiedID.random()

        await uiMOC.perform { [self] in
            let user = createUser(id: userID, in: uiMOC)
            user.supportedProtocols = [.proteus, .mls]

            let selfUser = ZMUser.selfUser(in: uiMOC)
            selfUser.supportedProtocols = [.proteus, .mls]
        }

        // When
        let result = try await sut.getProtocolForUser(
            with: userID,
            in: uiMOC
        )

        // Then
        XCTAssertEqual(result, .mls)
    }

    func test_GetProtocolForUser_Proteus() async throws {
        // Given
        let userID = QualifiedID.random()

        await uiMOC.perform { [self] in
            let user = createUser(id: userID, in: uiMOC)
            user.supportedProtocols = [.proteus]

            let selfUser = ZMUser.selfUser(in: uiMOC)
            selfUser.supportedProtocols = [.proteus, .mls]
        }

        // When
        let result = try await sut.getProtocolForUser(
            with: userID,
            in: uiMOC
        )

        // Then
        XCTAssertEqual(result, .proteus)
    }

    func test_GetProtocolForUser_NoCommonProtocol() async throws {
        // Given
        let userID = QualifiedID.random()

        await uiMOC.perform { [self] in
            let user = createUser(id: userID, in: uiMOC)
            user.supportedProtocols = [.proteus]

            let selfUser = ZMUser.selfUser(in: uiMOC)
            selfUser.supportedProtocols = [.mls]
        }

        // When
        let result = try await sut.getProtocolForUser(
            with: userID,
            in: uiMOC
        )

        // Then
        XCTAssertNil(result)
    }

    func test_GetProtocolForUser_DefaultsToProteus() async throws {
        // Given
        let userID = QualifiedID.random()

        await uiMOC.perform { [self] in
            let user = createUser(id: userID, in: uiMOC)
            user.supportedProtocols = []

            let selfUser = ZMUser.selfUser(in: uiMOC)
            selfUser.supportedProtocols = [.proteus, .mls]
        }

        // When
        let result = try await sut.getProtocolForUser(
            with: userID,
            in: uiMOC
        )

        // Then
        XCTAssertEqual(result, .proteus)
    }

    func test_GetProtocolForUser_IfNoProtocolForSelfReturnsNil() async throws {
        // Given
        let userID = QualifiedID.random()

        await uiMOC.perform { [self] in
            let user = createUser(id: userID, in: uiMOC)
            user.supportedProtocols = [.proteus]

            let selfUser = ZMUser.selfUser(in: uiMOC)
            selfUser.supportedProtocols = []
        }

        // When
        let result = try await sut.getProtocolForUser(
            with: userID,
            in: uiMOC
        )

        // Then
        XCTAssertEqual(result, .none)
    }

    
}
