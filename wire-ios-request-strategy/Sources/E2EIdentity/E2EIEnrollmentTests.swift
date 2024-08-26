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

import Foundation
import WireCoreCrypto

@testable import WireDataModelSupport
@testable import WireRequestStrategy
@testable import WireRequestStrategySupport
import WireTransport

class E2EIEnrollmentTests: ZMTBaseTest {

    var sut: E2EIEnrollment!
    var mockAcmeApi: MockAcmeAPIInterface!
    var mockApiProvider: MockAPIProviderInterface!
    var mockE2eiService: MockE2EIServiceInterface!
    var mockKeyRotator: MockE2EIKeyPackageRotating!

    override func setUp() {
        super.setUp()

        let acmeDirectory = AcmeDirectory(newNonce: "https://acme.elna.wire.link/acme/defaultteams/new-nonce",
                                          newAccount: "https://acme.elna.wire.link/acme/defaultteams/new-account",
                                          newOrder: "https://acme.elna.wire.link/acme/defaultteams/new-order",
                                          revokeCert: "")
        mockAcmeApi = MockAcmeAPIInterface()
        mockApiProvider = MockAPIProviderInterface()
        mockE2eiService = MockE2EIServiceInterface()
        mockKeyRotator = MockE2EIKeyPackageRotating()
        sut = E2EIEnrollment(
            acmeApi: mockAcmeApi,
            apiProvider: mockApiProvider,
            e2eiService: mockE2eiService,
            acmeDirectory: acmeDirectory,
            keyRotator: mockKeyRotator
        )
        BackendInfo.apiVersion = .v0
    }

    override func tearDown() {
        sut = nil
        mockAcmeApi = nil
        mockApiProvider = nil
        mockE2eiService = nil
        mockKeyRotator = nil

        super.tearDown()
    }

    func testThatItGetsACMENonce() async throws {
        // expectation
        let expectedNonce = "Nonce"

        // given
        mockAcmeApi.getACMENoncePath_MockMethod = { _ in
            return expectedNonce
        }

        // when
        let result = try await sut.getACMENonce()

        // then
        XCTAssertEqual(result, expectedNonce)
    }

    func testThatItCreatesNewAccount() async throws {
        // expectation
        let expectedNonce = "Mock nonce"
        let acmeResponse = ACMEResponse(
            nonce: expectedNonce,
            location: "Location",
            response: Data())

        // given
        mockAcmeApi.sendACMERequestPathRequestBody_MockMethod = { _, _ in
            return acmeResponse
        }
        mockE2eiService.getNewAccountRequestNonce_MockMethod = { _ in
            return Data()
        }
        mockE2eiService.setAccountResponseAccountData_MockMethod = { _ in }

        // when
        let result = try await sut.createNewAccount(prevNonce: "prevNonce")

        // then
        XCTAssertEqual(result, expectedNonce)
    }

    func testThatItCreateNewOrder() async throws {
        // expectation
        let expectedNonce = "Nonce"
        let expectedLocation = "Location"
        let expectedAcmeOrder = NewAcmeOrder(
            delegate: Data(),
            authorizations: ["new order"])

        let acmeResponse = ACMEResponse(
            nonce: expectedNonce,
            location: expectedLocation,
            response: Data())

        // given
        mockAcmeApi.sendACMERequestPathRequestBody_MockMethod = { _, _ in
            return acmeResponse
        }
        mockE2eiService.getNewOrderRequestNonce_MockMethod = { _ in
            return Data()
        }
        mockE2eiService.setOrderResponseOrder_MockMethod = { _ in
            return expectedAcmeOrder
        }

        // when
        let result = try await sut.createNewOrder(prevNonce: "prevNonce")

        // then
        XCTAssertEqual(result.nonce, expectedNonce)
        XCTAssertEqual(result.location, expectedLocation)
        XCTAssertEqual(result.acmeOrder, expectedAcmeOrder)
    }

    func testThatItCreatesAuthorization() async throws {
        // expectation
        let expectedNonce = "Nonce"
        let expectedLocation = "Location"
        let expectedChallengeType: AuthorizationChallengeType = .OIDC

        let wireOidcChallenge = AcmeChallenge(
            delegate: Data(),
            url: "url",
            target: "google")

        let newAcmeAuthz = NewAcmeAuthz(
            identifier: "111",
            keyauth: "keyauth",
            challenge: wireOidcChallenge)

        let authorizationResponse = ACMEAuthorizationResponse(
            nonce: expectedNonce,
            location: expectedLocation,
            response: Data(),
            challengeType: expectedChallengeType)

        // given
        mockAcmeApi.sendAuthorizationRequestPathRequestBody_MockMethod = { _, _ in
            return authorizationResponse
        }
        mockE2eiService.getNewAuthzRequestUrlPreviousNonce_MockMethod = { _, _ in
            return Data()
        }
        mockE2eiService.setAuthzResponseAuthz_MockMethod = { _ in
            return newAcmeAuthz
        }

        // when
        let result = try await sut.createAuthorization(prevNonce: "prevNonce", authzEndpoint: "https://endpoint.com")

        // then
        XCTAssertEqual(result.nonce, expectedNonce)
        XCTAssertEqual(result.location, expectedLocation)
        XCTAssertEqual(result.challengeType, expectedChallengeType)
    }

    func testThatItGetsWireNonce() async throws {
        // expectation
        let expectedNonce = "Nonce"

        // given
        BackendInfo.apiVersion = .v5
        let e2eIAPI = MockE2eIAPI()
        e2eIAPI.getWireNonceClientId_MockMethod = {_ in
            return expectedNonce
        }
        mockApiProvider.e2eIAPIApiVersion_MockValue = e2eIAPI

        // when
        let result = try await sut.getWireNonce(clientId: "12345")

        // then
        XCTAssertEqual(result, expectedNonce)
    }

    func testThatItGetsDPoPToken() async throws {
        // expectation
        let expectedDPoPToken = "Token"

        // given
        mockE2eiService.createDpopTokenNonce_MockMethod = { _ in
            return expectedDPoPToken
        }

        // when
        let result = try await sut.getDPoPToken("nonce")

        // then
        XCTAssertEqual(result, expectedDPoPToken)
    }

    func testThatItGetsWireAccessToken() async throws {
        // expectation
        let expectedAccessToken = AccessTokenResponse(expiresIn: 1, token: "", type: "")

        // given
        BackendInfo.apiVersion = .v5
        let e2eIAPI = MockE2eIAPI()
        e2eIAPI.getAccessTokenClientIdDpopToken_MockMethod = {_, _ in
            return expectedAccessToken
        }
        mockApiProvider.e2eIAPIApiVersion_MockValue = e2eIAPI

        // when
        let result = try await sut.getWireAccessToken(clientId: "12345", dpopToken: "dpopToken")

        // then
        XCTAssertEqual(result, expectedAccessToken)
    }

    func testThatItValidatesDPoPChallenge() async throws {
        // expectation
        let expectedChallengeResponse = ChallengeResponse(
            type: "JWD",
            url: "url",
            status: "valid",
            token: "token",
            target: "target",
            nonce: "nonce")

        // given
        mockAcmeApi.sendChallengeRequestPathRequestBody_MockMethod = { _, _ in
            return expectedChallengeResponse
        }
        mockE2eiService.getNewDpopChallengeRequestAccessTokenNonce_MockMethod = { _, _ in
            return Data()
        }
        mockE2eiService.setDPoPChallengeResponseChallenge_MockMethod = { _ in }

        // when
        let acmeChallenge = AcmeChallenge(
            delegate: Data(),
            url: "",
            target: "")
        let result = try await sut.validateDPoPChallenge(
            accessToken: "11",
            prevNonce: "Nonce",
            acmeChallenge: acmeChallenge)

        // then
        XCTAssertEqual(result, expectedChallengeResponse)
    }

    func testThatItValidatesOIDCChallenge() async throws {
        // expectation
        let expectedChallengeResponse = ChallengeResponse(
            type: "JWD",
            url: "url",
            status: "valid",
            token: "token",
            target: "target",
            nonce: "nonce")

        // given
        mockAcmeApi.sendChallengeRequestPathRequestBody_MockMethod = { _, _ in
            return expectedChallengeResponse
        }
        mockE2eiService.getNewOidcChallengeRequestIdTokenRefreshTokenNonce_MockMethod = { _, _, _ in
            return Data()
        }
        mockE2eiService.setOIDCChallengeResponseChallenge_MockMethod = { _ in }

        // when
        let acmeChallenge = AcmeChallenge(
            delegate: Data(),
            url: "",
            target: "")

        let result = try await sut.validateOIDCChallenge(
            idToken: "idToken",
            refreshToken: "refreshToken",
            prevNonce: "Nonce",
            acmeChallenge: acmeChallenge)

        // then
        XCTAssertEqual(result, expectedChallengeResponse)
    }

    func testThatItSetDPoPChallenge() async throws {
        // given
        let challengeResponse = ChallengeResponse(
            type: "JWD",
            url: "url",
            status: "valid",
            token: "token",
            target: "target",
            nonce: "nonce")
        mockE2eiService.setDPoPChallengeResponseChallenge_MockMethod = { _ in }

        // when
        try await sut.setDPoPChallengeResponse(challengeResponse: challengeResponse)

        // then
        XCTAssertEqual(mockE2eiService.setDPoPChallengeResponseChallenge_Invocations.count, 1)
    }

    func testThatItSetOIDCChallenge() async throws {
        // given
        let challengeResponse = ChallengeResponse(
            type: "JWD",
            url: "url",
            status: "valid",
            token: "token",
            target: "target",
            nonce: "nonce")
        mockE2eiService.setOIDCChallengeResponseChallenge_MockMethod = { _ in }

        // when
        try await sut.setOIDCChallengeResponse(challengeResponse: challengeResponse)

        // then
        XCTAssertEqual(mockE2eiService.setOIDCChallengeResponseChallenge_Invocations.count, 1)
    }

    func testThatItChecksOrderRequest() async throws {
        // expectation
        let expectedOrder = "OrderResponse"
        let expectedNonce = "Nonce"
        let expectedLocation = "Location"
        let expectedData = Data()
        let expectedACMEResponse = ACMEResponse(
            nonce: expectedNonce,
            location: expectedLocation,
            response: expectedData)

        // given
        mockAcmeApi.sendACMERequestPathRequestBody_MockMethod = { _, _ in
            return expectedACMEResponse
        }
        mockE2eiService.checkOrderRequestOrderUrlNonce_MockMethod = { _, _ in
            return Data()
        }
        mockE2eiService.checkOrderResponseOrder_MockMethod = { _ in
            return expectedOrder
        }

        // when
        let result = try await sut.checkOrderRequest(location: "location", prevNonce: "nonce")

        // then
        XCTAssertEqual(result.location, expectedOrder)
        XCTAssertEqual(result.acmeResponse, expectedACMEResponse)
    }

    func testThatItFinalizes() async throws {
        // expectation
        let expected = "expected"
        let expectedNonce = "Nonce"
        let expectedLocation = "Location"
        let expectedData = Data()
        let expectedACMEResponse = ACMEResponse(
            nonce: expectedNonce,
            location: expectedLocation,
            response: expectedData)

        // given
        mockAcmeApi.sendACMERequestPathRequestBody_MockMethod = { _, _ in
            return expectedACMEResponse
        }
        mockE2eiService.finalizeRequestNonce_MockMethod = { _ in
            return Data()
        }
        mockE2eiService.finalizeResponseFinalize_MockMethod = { _ in
            return expected
        }

        // when
        let result = try await sut.finalize(location: "location", prevNonce: "nonce")

        // then
        XCTAssertEqual(result.location, expected)
        XCTAssertEqual(result.acmeResponse, expectedACMEResponse)
    }

    func testThatItGetsCertificateRequest() async throws {
        // expectation
        let expectedNonce = "Nonce"
        let expectedLocation = "Location"
        let expectedData = Data()
        let expectedACMEResponse = ACMEResponse(
            nonce: expectedNonce,
            location: expectedLocation,
            response: expectedData)

        // given
        mockAcmeApi.sendACMERequestPathRequestBody_MockMethod = { _, _ in
            return expectedACMEResponse
        }
        mockE2eiService.certificateRequestNonce_MockMethod = { _ in
            return Data()
        }

        // when
        let result = try await sut.certificateRequest(location: "location", prevNonce: "nonce")

        // then
        XCTAssertEqual(result, expectedACMEResponse)
    }

    func testThatItRotateKeysAndMigrateConversations() async throws {
        // Given
        let certificateChain = "123456"
        mockKeyRotator.rotateKeysAndMigrateConversationsEnrollmentCertificateChain_MockMethod = { _, _ in }
        mockE2eiService.underlyingE2eIdentity = MockE2EIEnrollment()

        // When
        try await sut.rotateKeysAndMigrateConversations(certificateChain: certificateChain)

        // Then
        let invocations = mockKeyRotator.rotateKeysAndMigrateConversationsEnrollmentCertificateChain_Invocations
        XCTAssertEqual(invocations.count, 1)
        XCTAssertEqual(invocations.first?.certificateChain, certificateChain)
    }
}
