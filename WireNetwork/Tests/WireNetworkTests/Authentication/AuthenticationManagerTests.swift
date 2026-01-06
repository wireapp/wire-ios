//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireFoundationSupport
import XCTest

@testable import WireNetwork
@testable import WireNetworkSupport

final class AuthenticationManagerTests: XCTestCase {

    var sut: AuthenticationManager!
    var backendURL: URL!
    var cookieStorage: MockCookieStorageProtocol!

    private var mockDateProvider: CurrentDateProvidingMock!
    private var accessTokenDidFail = false

    override func setUpWithError() throws {
        mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-04-09T12:34:56Z")
        cookieStorage = MockCookieStorageProtocol()
        backendURL = try XCTUnwrap(URL(string: "https://www.example.com"))
        let networkService = NetworkService(
            baseURL: backendURL,
            serverTrustValidator: ServerTrustValidator(
                pinnedKeys: [],
                currentDateProvider: mockDateProvider
            )
        )
        networkService.configure(with: .mockURLSession())

        sut = AuthenticationManager(
            clientID: Scaffolding.clientID,
            cookieStorage: cookieStorage,
            networkService: networkService,
            onAuthenticationFailure: { self.accessTokenDidFail = true }
        )
    }

    override func tearDown() {
        cookieStorage = nil
        backendURL = nil
        sut = nil
        mockDateProvider = nil
        accessTokenDidFail = false
    }

    // MARK: - Get a valid token

    func testGetValidAccessToken_CacheIsEmpty() async throws {
        // Mock valid cookie.
        cookieStorage.fetchCookies_MockValue = [try Scaffolding.cookie()]

        // Mock successful token response.
        var receivedRequests = [URLRequest]()
        URLProtocolMock.mockHandler = {
            receivedRequests.append($0)
            return try $0.mockResponse(
                statusCode: .ok,
                jsonResourceName: "PostAccessSuccessResponse200"
            )
        }

        // When we get a valid token the first time
        let accessToken = try await sut.getValidAccessToken()

        // Then a request was made to get a new access token.
        try XCTAssertCount(receivedRequests, count: 1)
        let snapshotter = HTTPRequestSnapshotHelper()
        await snapshotter.verifyRequest(request: receivedRequests[0])

        // Then we got back a valid access token.
        XCTAssertEqual(accessToken.userID, Scaffolding.userID)
        XCTAssertEqual(accessToken.type, Scaffolding.tokenType)
        XCTAssertEqual(accessToken.token, Scaffolding.validAccessToken)
        XCTAssertFalse(accessToken.isExpiring)

        // When we ask for the token again.
        receivedRequests.removeAll()
        let secondAccessToken = try await sut.getValidAccessToken()

        // Then no new requests were made.
        XCTAssertTrue(receivedRequests.isEmpty)

        // Then it's the same (cached) token.
        XCTAssertEqual(secondAccessToken, accessToken)
    }

    func testGetValidAccessToken_CacheHitButItIsExpiring() async throws {
        // Given an existing but expiring.
        let cachedToken = try await setCachedExpiringAccessToken()
        XCTAssertTrue(cachedToken.isExpiring)

        // Mock successful token response.
        var receivedRequests = [URLRequest]()
        URLProtocolMock.mockHandler = {
            receivedRequests.append($0)
            return try $0.mockResponse(
                statusCode: .ok,
                jsonResourceName: "PostAccessSuccessResponse200"
            )
        }

        // When we ask for a valid token.
        let accessToken = try await sut.getValidAccessToken()

        // Then a request was made to get a new access token.
        try XCTAssertCount(receivedRequests, count: 1)
        let snapshotter = HTTPRequestSnapshotHelper()
        await snapshotter.verifyRequest(request: receivedRequests[0])

        // Then we got back a vaild access token.
        XCTAssertEqual(accessToken.userID, Scaffolding.userID)
        XCTAssertEqual(accessToken.type, Scaffolding.tokenType)
        XCTAssertEqual(accessToken.token, Scaffolding.validAccessToken)
        XCTAssertFalse(accessToken.isExpiring)
    }

    private func setCachedExpiringAccessToken() async throws -> AccessToken {
        cookieStorage.fetchCookies_MockValue = [try Scaffolding.cookie()]

        URLProtocolMock.mockHandler = {
            try $0.mockResponse(
                statusCode: .ok,
                jsonResourceName: "ExpiringAccessTokenResponse"
            )
        }

        return try await sut.getValidAccessToken()
    }

    func testGetValidAccessToken_AwaitTokenRefresh() async throws {
        // Mock valid cookie.
        cookieStorage.fetchCookies_MockValue = [try Scaffolding.cookie()]

        // Mock successful token response.
        var receivedRequests = [URLRequest]()
        URLProtocolMock.mockHandler = {
            receivedRequests.append($0)
            return try $0.mockResponse(
                statusCode: .ok,
                jsonResourceName: "PostAccessSuccessResponse200"
            )
        }

        // When multiple tasks all want an access token.
        await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 1 ... 10 {
                group.addTask { [sut] in
                    guard let sut else { return }
                    let accessToken = try await sut.getValidAccessToken()

                    // Then each task go back a valid access token.
                    XCTAssertEqual(accessToken.userID, Scaffolding.userID)
                    XCTAssertEqual(accessToken.type, Scaffolding.tokenType)
                    XCTAssertEqual(accessToken.token, Scaffolding.validAccessToken)
                    XCTAssertFalse(accessToken.isExpiring)
                }
            }
        }

        // Then only one request was made to get a new access token.
        try XCTAssertCount(receivedRequests, count: 1)
        let snapshotter = HTTPRequestSnapshotHelper()
        await snapshotter.verifyRequest(request: receivedRequests[0])
    }

    // MARK: - Refresh access token

    func testRefreshAccessToken_AfterAnError_WeCanStillRefresh() async throws {
        // Mock token refresh error.
        cookieStorage.fetchCookies_MockValue = [try Scaffolding.cookie()]
        cookieStorage.removeCookies_MockMethod = {}
        URLProtocolMock.mockHandler = {
            try $0.mockErrorResponse(
                statusCode: .forbidden,
                label: "invalid-credentials"
            )
        }

        // Then
        await XCTAssertThrowsErrorAsync(AuthenticationManager.Failure.invalidCredentials) {
            // When a new token is requested.
            try await self.sut.refreshAccessToken()
        }

        // Mock a successful token refresh.
        URLProtocolMock.mockHandler = {
            try $0.mockResponse(
                statusCode: .ok,
                jsonResourceName: "PostAccessSuccessResponse200"
            )
        }

        // When we try again.
        let accessToken = try await sut.refreshAccessToken()

        // Then it succeeds.
        XCTAssertEqual(accessToken.userID, Scaffolding.userID)
        XCTAssertEqual(accessToken.type, Scaffolding.tokenType)
        XCTAssertEqual(accessToken.token, Scaffolding.validAccessToken)
        XCTAssertFalse(accessToken.isExpiring)
    }

}

private enum Scaffolding {

    static let userID = UUID(uuidString: "70aa272d-3413-4cda-9059-64c097956583")!
    static let clientID = "abc123"
    static let tokenType = "Bearer"
    static let validAccessToken = "a-valid-access-token"

    static func cookie() throws -> HTTPCookie {
        try XCTUnwrap(
            HTTPCookie(properties: [
                .name: "zuid",
                .path: "some path",
                .value: "some value",
                .domain: "some domain"
            ])
        )
    }

}
