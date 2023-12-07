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

@testable import WireRequestStrategy

class E2eIEnrollmentTests: ZMTBaseTest {

    var sut: E2eIEnrollment!
    var mockAcmeApi: MockAcmeApi!
    var mockApiProvider: MockAPIProviderInterface!
    var mockE2eiService: MockE2eIService!
    var previousApiVersion: APIVersion!

    override func setUp() {
        super.setUp()

        previousApiVersion = BackendInfo.apiVersion
        let acmeDirectory = AcmeDirectory(newNonce: "https://acme.elna.wire.link/acme/defaultteams/new-nonce",
                                          newAccount: "https://acme.elna.wire.link/acme/defaultteams/new-account",
                                          newOrder: "https://acme.elna.wire.link/acme/defaultteams/new-order")
        mockAcmeApi = MockAcmeApi()
        mockApiProvider = MockAPIProviderInterface()
        mockE2eiService = MockE2eIService()
        sut = E2eIEnrollment(acmeApi: mockAcmeApi,
                             apiProvider: mockApiProvider,
                             e2eiService: mockE2eiService,
                             acmeDirectory: acmeDirectory)
    }

    override func tearDown() {
        sut = nil
        mockAcmeApi = nil
        mockApiProvider = nil
        mockE2eiService = nil
        BackendInfo.apiVersion = previousApiVersion

        super.tearDown()
    }

    func testThatItGetsACMENonce() async throws {
        // expectation
        let expectedNonce = "Nonce"

        // given
        mockAcmeApi.mockNonce = expectedNonce

        // when
        let result = try await sut.getACMENonce()

        // then
        XCTAssertEqual(result, expectedNonce)
    }

    func testThatItCreatesNewAccount() async throws {
        // expectation
        let expectedNewAccount = "NewAccount"

        // given
        mockAcmeApi.mockNonce = expectedNewAccount

        // when
        let result = try await sut.createNewAccount(prevNonce: "prevNonce")

        // then
        XCTAssertEqual(result, expectedNewAccount)
    }

    func testThatItCreateNewOrder() async throws {
        // expectation
        let expectedNonce = "Nonce"
        let expectedLocation = "Location"
        let expectedAcmeOrder = NewAcmeOrder(delegate: [], authorizations: ["new order"])

        // given
        mockAcmeApi.mockNonce = expectedNonce
        mockAcmeApi.mockLocation = expectedLocation
        mockE2eiService.mockAcmeOrder = expectedAcmeOrder

        // when
        let result = try await sut.createNewOrder(prevNonce: "prevNonce")

        // then
        XCTAssertEqual(result.nonce, expectedNonce)
        XCTAssertEqual(result.location, expectedLocation)
        XCTAssertEqual(result.acmeOrder, expectedAcmeOrder)
    }

    func testThatItCreatesAuthz() async throws {
        // expectation
        let expectedNonce = "Nonce"
        let expectedLocation = "Location"
        let wireDpopChallenge = AcmeChallenge(delegate: [], url: "url", target: "wire server")
        let wireOidcChallenge = AcmeChallenge(delegate: [], url: "url", target: "google")

        // given
        mockAcmeApi.mockNonce = expectedNonce
        mockAcmeApi.mockLocation = expectedLocation
        mockE2eiService.wireDpopChallenge = wireDpopChallenge
        mockE2eiService.wireOidcChallenge = wireOidcChallenge

        // when
        let result = try await sut.createAuthz(prevNonce: "prevNonce", authzEndpoint: "https://endpoint.com")

        // then
        XCTAssertEqual(result.nonce, expectedNonce)
        XCTAssertEqual(result.location, expectedLocation)
        XCTAssertEqual(result.challenges.wireDpopChallenge, wireDpopChallenge)
        XCTAssertEqual(result.challenges.wireOidcChallenge, wireOidcChallenge)
    }

    func testThatItGetsWireNonce() async throws {
        // expectation
        let expectedNonce = "Nonce"

        // given
        BackendInfo.apiVersion = .v5
        let e2eIAPI = MockE2eIAPI()
        e2eIAPI.getWireNonce_MockMethod = {_ in
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
        mockE2eiService.mockDpopToken = expectedDPoPToken

        // when
        let result = try await sut.getDPoPToken("nonce")

        // then
        XCTAssertEqual(result, expectedDPoPToken)
    }

    func testThatItGetsWireAccessToken() async throws {
        // expectation
        let expectedAccessToken = AccessTokenResponse(expiresIn: "", token: "", type: "")

        // given
        BackendInfo.apiVersion = .v5
        let e2eIAPI = MockE2eIAPI()
        e2eIAPI.getAccessToken_MockMethod = {_, _ in
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
        let expectedChallengeResponse = ChallengeResponse(type: "JWD",
                                                          url: "url",
                                                          status: "valid",
                                                          token: "token",
                                                          nonce: "nonce")
        // given
        mockAcmeApi.mockChallengeResponse = expectedChallengeResponse

        // when
        let result = try await sut.validateDPoPChallenge(accessToken: "11",
                                                         prevNonce: "Nonce",
                                                         acmeChallenge: AcmeChallenge(delegate: [],
                                                                                      url: "",
                                                                                      target: ""))

        // then
        XCTAssertEqual(result, expectedChallengeResponse)
    }

    func testThatItValidatesOIDCChallenge() async throws {
        // expectation
        let expectedChallengeResponse = ChallengeResponse(type: "JWD",
                                                          url: "url",
                                                          status: "valid",
                                                          token: "token",
                                                          nonce: "nonce")

        // given
        mockAcmeApi.mockChallengeResponse = expectedChallengeResponse

        // when
        let result = try await sut.validateOIDCChallenge(idToken: "idToken",
                                                         prevNonce: "Nonce",
                                                         acmeChallenge: AcmeChallenge(delegate: [],
                                                                                      url: "",
                                                                                      target: ""))

        // then
        XCTAssertEqual(result, expectedChallengeResponse)
    }

    func testThatItValidatesChallenge() async throws {
        // given
        let challengeResponse = ChallengeResponse(type: "JWD",
                                                  url: "url",
                                                  status: "valid",
                                                  token: "token",
                                                  nonce: "nonce")

        // when
        try await sut.validateChallenge(challengeResponse: challengeResponse)

        // then
        XCTAssertEqual(mockE2eiService.mockSetChallengeResponse, 1)
    }

    func testThatItChecksOrderRequest() async throws {
        // expectation
        let expectedOrder = "OrderResponse"
        let expectedNonce = "Nonce"
        let expectedLocation = "Location"
        let expectedData = Data()
        let expectedACMEResponse = ACMEResponse(nonce: expectedNonce, location: expectedLocation, response: expectedData)

        // given
        mockE2eiService.mockOrderResponse = expectedOrder
        mockAcmeApi.mockNonce = expectedNonce
        mockAcmeApi.mockLocation = expectedLocation
        mockAcmeApi.mockResponseData = expectedData

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
        let expectedACMEResponse = ACMEResponse(nonce: expectedNonce, location: expectedLocation, response: expectedData)

        // given
        mockE2eiService.mockFinalizeResponse = expected
        mockAcmeApi.mockNonce = expectedNonce
        mockAcmeApi.mockLocation = expectedLocation
        mockAcmeApi.mockResponseData = expectedData

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
        let expectedACMEResponse = ACMEResponse(nonce: expectedNonce, location: expectedLocation, response: expectedData)

        // given
        mockAcmeApi.mockNonce = expectedNonce
        mockAcmeApi.mockLocation = expectedLocation
        mockAcmeApi.mockResponseData = expectedData

        // when
        let result = try await sut.certificateRequest(location: "location", prevNonce: "nonce")

        // then
        XCTAssertEqual(result, expectedACMEResponse)
    }
}

class MockAcmeApi: AcmeAPIInterface {

    let domain: String = "example.com"
    var mockNonce: String?
    var mockLocation: String?
    var mockResponseData: Data?
    var mockChallengeResponse: ChallengeResponse?

    func getACMEDirectory() async throws -> Data {
        let payload = acmeDirectoriesResponse()

        return try JSONSerialization.data(withJSONObject: payload, options: [])
    }

    func getACMENonce(path: String) async throws -> String {
        return mockNonce ?? ""
    }

    func sendACMERequest(path: String, requestBody: Data) async throws -> ACMEResponse {
        return ACMEResponse(nonce: mockNonce ?? "",
                            location: mockLocation ?? "",
                            response: mockResponseData ?? Data())
    }

    func sendChallengeRequest(path: String, requestBody: Data) async throws -> ChallengeResponse {
        return mockChallengeResponse ?? ChallengeResponse(type: "",
                                                          url: "",
                                                          status: "",
                                                          token: "",
                                                          nonce: "")
    }

    private func acmeDirectoriesResponse() -> [String: String] {
        return [
            "newNonce": "https://\(domain)/acme/defaultteams/new-nonce",
            "newAccount": "https://\(domain)/acme/defaultteams/new-account",
            "newOrder": "https://\(domain)/acme/defaultteams/new-order",
            "revokeCert": "https://\(domain)/acme/defaultteams/revoke-cert",
            "keyChange": "https://\(domain)/acme/defaultteams/key-change"
        ]

    }

}

class MockE2eIService: E2eIServiceInterface {

    var mockAcmeOrder: NewAcmeOrder?
    var wireDpopChallenge: AcmeChallenge?
    var wireOidcChallenge: AcmeChallenge?
    var mockDpopToken: String?
    var mockSetChallengeResponse: Int = 0
    var mockOrderResponse: String?
    var mockFinalizeResponse: String?

    func getDirectoryResponse(directoryData: Data) async throws -> AcmeDirectory {
        return AcmeDirectory(newNonce: "", newAccount: "", newOrder: "")
    }

    func getNewAccountRequest(nonce: String) async throws -> Data {
        return Data()
    }

    func setAccountResponse(accountData: Data) async throws {
    }

    func getNewOrderRequest(nonce: String) async throws -> Data {
        return Data()
    }

    func setOrderResponse(order: Data) async throws -> NewAcmeOrder {
        return mockAcmeOrder ?? NewAcmeOrder(delegate: [], authorizations: [])
    }

    func getNewAuthzRequest(url: String, previousNonce: String) async throws -> Data {
        return Data()
    }

    func setAuthzResponse(authz: Data) async throws -> NewAcmeAuthz {
        return NewAcmeAuthz(identifier: "111",
                            wireDpopChallenge: wireDpopChallenge,
                            wireOidcChallenge: wireOidcChallenge)
    }

    func createDpopToken(nonce: String) async throws -> String {
        return mockDpopToken ?? ""
    }

    func getNewDpopChallengeRequest(accessToken: String, nonce: String) async throws -> Data {
        return Data()
    }

    func getNewOidcChallengeRequest(idToken: String, nonce: String) async throws -> Data {
        return Data()
    }

    func setChallengeResponse(challenge: Data) async throws {
        mockSetChallengeResponse += 1
    }

    func checkOrderRequest(orderUrl: String, nonce: String) async throws -> Data {
        return Data()
    }

    func checkOrderResponse(order: Data) async throws -> String {
        return mockOrderResponse ?? ""
    }

    func finalizeRequest(nonce: String) async throws -> Data {
        return Data()
    }

    func finalizeResponse(finalize: Data) async throws -> String {
        return mockFinalizeResponse ?? ""
    }

    func certificateRequest(nonce: String) async throws -> Data {
        return Data()
    }

}
