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
@testable import WireDataModelSupport

class E2eIServiceTests: ZMConversationTestsBase {

    var sut: E2eIService!
    var mockE2eIdentity: MockE2eiEnrollment!

    override func setUp() {
        super.setUp()

        mockE2eIdentity = MockE2eiEnrollment()
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
                                                  newOrder: "https://acme.elna.wire.link/acme/defaultteams/new-order",
                                                  revokeCert: "")

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
            return expectedAccountRequest
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
            return expectedOrderRequest
        }

        // When
        let orderRequest = try await sut.getNewOrderRequest(nonce: "nonce")

        // Then
        XCTAssertEqual(mockGetNewOrderCount, 1)
        XCTAssertEqual(orderRequest, expectedOrderRequest)
    }

//    func testThatItSetsOrderResponse() async throws {
//        // Expectation
//        let expectedAcmeOrder = NewAcmeOrder(delegate: [], authorizations: ["example.com"])
//
//        // Given
//        var mockSetOrderResponse = 0
//
//        // Mock
//        mockE2eIdentity.mockNewOrderResponse = { _ in
//            mockSetOrderResponse += 1
//            return expectedAcmeOrder
//        }
//
//        // When
//        let acmeOrder = try await sut.setOrderResponse(order: Data())
//
//        // Then
//        XCTAssertEqual(mockSetOrderResponse, 1)
//        XCTAssertEqual(acmeOrder, expectedAcmeOrder)
//    }

    func testThatItGetsNewAuthzRequest() async throws {
        // Expectation
        let expectedAuthzRequest = Data()

        // Given
        var mockGetNewAuthzCount = 0

        // Mock
        mockE2eIdentity.mockNewAuthzRequest = { _, _ in
            mockGetNewAuthzCount += 1
            return expectedAuthzRequest
        }

        // When
        let authzRequest = try await sut.getNewAuthzRequest(url: "", previousNonce: "nonce")

        // Then
        XCTAssertEqual(mockGetNewAuthzCount, 1)
        XCTAssertEqual(authzRequest, expectedAuthzRequest)
    }

    func testThatItSetsAuthzResponse() async throws {
        // Expectation
        let wireDpopChallenge = AcmeChallenge(delegate: Data(), url: "", target: "")
        let wireOidcChallenge = AcmeChallenge(delegate: Data(), url: "", target: "")
        let expectedAcmeOrder = NewAcmeAuthz(identifier: "",
                                             keyauth: "",
                                             wireDpopChallenge: wireDpopChallenge,
                                             wireOidcChallenge: wireOidcChallenge)

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

    func testThatItCreatesDpopToken() async throws {
        // Expectation
        let expectedDpopToken = "DpopToken"

        // Given
        var mockCreatesDpopToken = 0

        // Mock
        mockE2eIdentity.mockCreateDpopToken = { _, _ in
            mockCreatesDpopToken += 1
            return expectedDpopToken
        }

        // When
        let dpopToken = try await sut.createDpopToken(nonce: "nonce")

        // Then
        XCTAssertEqual(mockCreatesDpopToken, 1)
        XCTAssertEqual(dpopToken, expectedDpopToken)
    }

    func testThatItGetsNewDpopChallengeRequest() async throws {
        // Expectation
        let expectedDpopChallenge = Data()

        // Given
        var mocNewDpopChallengeRequest = 0

        // Mock
        mockE2eIdentity.mockNewDpopChallengeRequest = { _, _ in
            mocNewDpopChallengeRequest += 1
            return expectedDpopChallenge
        }

        // When
        let dpopChallenge = try await sut.getNewDpopChallengeRequest(accessToken: "accessToken", nonce: "nonce")

        // Then
        XCTAssertEqual(mocNewDpopChallengeRequest, 1)
        XCTAssertEqual(dpopChallenge, expectedDpopChallenge)
    }

//    func testThatItGetsNewOidcChallengeRequest() async throws {
//        // Expectation
//        let expectedOidcChallenge = Data()
//
//        // Given
//        var mockGetsNewOidcChallengeRequest = 0
//
//        // Mock
//        mockE2eIdentity.mockNewOidcChallengeRequest = { _, _ in
//            mockGetsNewOidcChallengeRequest += 1
//            return expectedOidcChallenge
//        }
//
//        // When
//        let oidcChallenge = try await sut.getNewOidcChallengeRequest(idToken: "idToken", nonce: "nonce")
//
//        // Then
//        XCTAssertEqual(mockGetsNewOidcChallengeRequest, 1)
//        XCTAssertEqual(oidcChallenge, expectedOidcChallenge)
//    }

//    func testThatItSetsChallengeResponse() async throws {
//        // Given
//        var mockSetsChallengeResponse = 0
//
//        // Mock
//        mockE2eIdentity.mockNewChallengeResponse = { _ in
//            mockSetsChallengeResponse += 1
//        }
//
//        // When
//        try await sut.setChallengeResponse(challenge: Data())
//
//        // Then
//        XCTAssertEqual(mockSetsChallengeResponse, 1)
//    }

    func testThatItChecksOrderRequest() async throws {
        // Expectation
        let expectedOrderRequest = Data()

        // Given
        var mockChecksOrderRequest = 0

        // Mock
        mockE2eIdentity.mockCheckOrderRequest = { _, _ in
            mockChecksOrderRequest += 1
            return expectedOrderRequest
        }

        // When
        let orderRequest = try await sut.checkOrderRequest(orderUrl: "orderUrl", nonce: "nonce")

        // Then
        XCTAssertEqual(mockChecksOrderRequest, 1)
        XCTAssertEqual(orderRequest, expectedOrderRequest)
    }

    func testThatItChecksOrderResponse() async throws {
        // Expectation
        let expectedOrderResponse = "mock"

        // Given
        var mockChecksOrderResponse = 0

        // Mock
        mockE2eIdentity.mockCheckOrderResponse = { _ in
            mockChecksOrderResponse += 1
            return expectedOrderResponse
        }

        // When
        let orderRequest = try await sut.checkOrderResponse(order: Data())

        // Then
        XCTAssertEqual(mockChecksOrderResponse, 1)
        XCTAssertEqual(orderRequest, expectedOrderResponse)
    }

    func testThatItFinalizesRequest() async throws {
        // Expectation
        let expectedfinalizeRequest = Data()

        // Given
        var mockFinalizesRequest = 0

        // Mock
        mockE2eIdentity.mockFinalizeRequest = { _ in
            mockFinalizesRequest += 1
            return expectedfinalizeRequest
        }

        // When
        let finalizeRequest = try await sut.finalizeRequest(nonce: "nonce")

        // Then
        XCTAssertEqual(mockFinalizesRequest, 1)
        XCTAssertEqual(finalizeRequest, expectedfinalizeRequest)
    }

    func testThatItFinalizesResponse() async throws {
        // Expectation
        let expectedFinalizeResponse = "test"

        // Given
        var mockFinalizesResponse = 0

        // Mock
        mockE2eIdentity.mockFinalizeResponse = { _ in
            mockFinalizesResponse += 1
            return expectedFinalizeResponse
        }

        // When
        let finalizeResponse = try await sut.finalizeResponse(finalize: Data())

        // Then
        XCTAssertEqual(mockFinalizesResponse, 1)
        XCTAssertEqual(finalizeResponse, expectedFinalizeResponse)
    }

    func testThatItCreatesCertificateRequest() async throws {
        // Expectation
        let expectedCertificateRequest = Data()

        // Given
        var mockCreatesCertificateRequest = 0

        // Mock
        mockE2eIdentity.mockCertificateRequest = { _ in
            mockCreatesCertificateRequest += 1
            return expectedCertificateRequest
        }

        // When
        let certificateRequest = try await sut.certificateRequest(nonce: "nonce")

        // Then
        XCTAssertEqual(mockCreatesCertificateRequest, 1)
        XCTAssertEqual(certificateRequest, expectedCertificateRequest)
    }

}
