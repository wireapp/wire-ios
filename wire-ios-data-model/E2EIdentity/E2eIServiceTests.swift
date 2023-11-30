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

    func testThatItGetsNewAccountRequest() async throws {
        // Expectation
        let expectedAccountRequest = Data()

        // Given
        var mockGetNewAccountCount = 0

        // Mock
        mockE2eIdentity.mockNewAccountRequest = { _ in
            mockGetNewAccountCount += 1
            return expectedAccountRequest.bytes
        }

        // When
        let accountRequest = try await sut.getNewAccountRequest(nonce: "")

        // Then
        XCTAssertEqual(mockGetNewAccountCount, 1)
        XCTAssertEqual(accountRequest, expectedAccountRequest)
    }

    func testThatItSetsAccountResponse() async throws {
        // Given
        var mockSetAccountResponse = 0

        // Mock
        mockE2eIdentity.mockNewAccountResponse = { _ in
            mockSetAccountResponse += 1
        }

        // When
        try await sut.setAccountResponse(accountData: Data())

        // Then
        XCTAssertEqual(mockSetAccountResponse, 1)
    }

    func testThatItGetsNewOrderRequest() async throws {
        // Expectation
        let expectedOrderRequest = Data()

        // Given
        var mockGetNewOrderCount = 0

        // Mock
        mockE2eIdentity.mockNewOrderRequest = { _ in
            mockGetNewOrderCount += 1
            return expectedOrderRequest.bytes
        }

        // When
        let orderRequest = try await sut.getNewOrderRequest(nonce: "nonce")

        // Then
        XCTAssertEqual(mockGetNewOrderCount, 1)
        XCTAssertEqual(orderRequest, expectedOrderRequest)
    }

    func testThatItSetsOrderResponse() async throws {
        // Expectation
        let expectedAcmeOrder = NewAcmeOrder(delegate: [], authorizations: ["example.com"])

        // Given
        var mockSetOrderResponse = 0

        // Mock
        mockE2eIdentity.mockNewOrderResponse = { _ in
            mockSetOrderResponse += 1
            return expectedAcmeOrder
        }

        // When
        let acmeOrder = try await sut.setOrderResponse(order: Data())

        // Then
        XCTAssertEqual(mockSetOrderResponse, 1)
        XCTAssertEqual(acmeOrder, expectedAcmeOrder)
    }

    func testThatItGetsNewAuthzRequest() async throws {
        // Expectation
        let expectedAuthzRequest = Data()

        // Given
        var mockGetNewAuthzCount = 0

        // Mock
        mockE2eIdentity.mockNewAuthzRequest = { _, _ in
            mockGetNewAuthzCount += 1
            return expectedAuthzRequest.bytes
        }

        // When
        let authzRequest = try await sut.getNewAuthzRequest(url: "", previousNonce: "nonce")

        // Then
        XCTAssertEqual(mockGetNewAuthzCount, 1)
        XCTAssertEqual(authzRequest, expectedAuthzRequest)
    }

    func testThatItSetsAuthzResponse() async throws {
        // Expectation
        let expectedAcmeOrder = NewAcmeAuthz(identifier: "", wireDpopChallenge: nil, wireOidcChallenge: nil)

        // Given
        var mockSetAuthzResponse = 0

        // Mock
        mockE2eIdentity.mockNewAuthzResponse = { _ in
            mockSetAuthzResponse += 1
            return expectedAcmeOrder
        }

        // When
        let acmeAuthz = try await sut.setAuthzResponse(authz: Data())

        // Then
        XCTAssertEqual(mockSetAuthzResponse, 1)
        XCTAssertEqual(acmeAuthz, expectedAcmeOrder)
    }

}
