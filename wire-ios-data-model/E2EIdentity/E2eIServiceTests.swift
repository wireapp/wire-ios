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

import Foundation
import WireCoreCrypto
@testable import WireDataModel

 class E2eIServiceTests: ZMConversationTestsBase {

    var sut: E2eIService!
    var mockE2eIdentity: MockWireE2eIdentity!

    override func setUp() {
        super.setUp()

        mockE2eIdentity = MockWireE2eIdentity()
        sut = E2eIService(e2eIdentity: mockE2eIdentity)
    }

    override func tearDown() {
        mockE2eIdentity = nil
        sut = nil

        super.tearDown()
    }

    func testThatItContainsCorrectAcmeDirectoryInTheResponse() async throws {
        // Expectation
        let expectedacmeDirectory = AcmeDirectory(newNonce: "https://acme.elna.wire.link/acme/defaultteams/new-nonce",
                                                  newAccount: "https://acme.elna.wire.link/acme/defaultteams/new-account",
                                                  newOrder: "https://acme.elna.wire.link/acme/defaultteams/new-order")

        // Given
        var mockDirectoryResponseCount = 0

        let acmeResponse = """
        {
            "newNonce": "https://acme.elna.wire.link/acme/defaultteams/new-nonce",
            "newAccount": "https://acme.elna.wire.link/acme/defaultteams/new-account",
            "newOrder": "https://acme.elna.wire.link/acme/defaultteams/new-order",
            "revokeCert": "https://acme.elna.wire.link/acme/defaultteams/revoke-cert",
            "keyChange": "https://acme.elna.wire.link/acme/defaultteams/key-change"
        }
        """
        let acmeResponseData = acmeResponse.data(using: .utf8)!

        // Mock
        mockE2eIdentity.mockDirectoryResponse = { _ in
            mockDirectoryResponseCount += 1
            return expectedacmeDirectory
        }

        // When
        let acmeDirectory = try await sut.getDirectoryResponse(directoryData: acmeResponseData)

        // Then
        XCTAssertEqual(mockDirectoryResponseCount, 1)
        XCTAssertEqual(acmeDirectory, expectedacmeDirectory)
    }

 }
