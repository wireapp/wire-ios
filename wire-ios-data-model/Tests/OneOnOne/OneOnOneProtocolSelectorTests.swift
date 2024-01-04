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

    func test_GetProtocolForUser_MLS() throws {
        // Given
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.supportedProtocols = [.proteus, .mls]

        let userID = QualifiedID.random()
        let user = createUser(id: userID, in: uiMOC)
        user.supportedProtocols = [.proteus, .mls]

        // When
        let result = sut.getProtocolForUser(
            with: userID,
            in: uiMOC
        )

        // Then
        XCTAssertEqual(result, .mls)
    }

    func test_GetProtocolForUser_Proteus() throws {
        // Given
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.supportedProtocols = [.proteus, .mls]

        let userID = QualifiedID.random()
        let user = createUser(id: userID, in: uiMOC)
        user.supportedProtocols = [.proteus]

        // When
        let result = sut.getProtocolForUser(
            with: userID,
            in: uiMOC
        )

        // Then
        XCTAssertEqual(result, .proteus)
    }

    func test_GetProtocolForUser_NoCommonProtocol() throws {
        // Given
        let selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.supportedProtocols = [.mls]

        let userID = QualifiedID.random()
        let user = createUser(id: userID, in: uiMOC)
        user.supportedProtocols = [.proteus]

        // When
        let result = sut.getProtocolForUser(
            with: userID,
            in: uiMOC
        )

        // Then
        XCTAssertNil(result)
    }

}
