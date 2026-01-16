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
import WireTestingPackage
import XCTest

@testable import WireNetwork
@testable import WireNetworkSupport

final class APIServiceTests: XCTestCase {

    var sut: APIService!
    var backendURL: URL!
    var authenticationManager: MockAuthenticationManagerProtocol!

    private var mockDateProvider: CurrentDateProvidingMock!

    override func setUp() async throws {
        mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-04-09T12:34:56Z")
        backendURL = try XCTUnwrap(URL(string: "https://www.example.com"))
        authenticationManager = MockAuthenticationManagerProtocol()
        let networkService = NetworkService(
            baseURL: backendURL,
            serverTrustValidator: ServerTrustValidator(
                pinnedKeys: [],
                currentDateProvider: mockDateProvider
            )
        )
        networkService.configure(with: .mockURLSession())
        sut = APIService(
            networkService: networkService,
            authenticationManager: authenticationManager
        )
    }

    override func tearDown() async throws {
        backendURL = nil
        authenticationManager = nil
        sut = nil
        mockDateProvider = nil
    }

    // MARK: - Execute request

    func testExecuteRequest_Not_Requiring_Access_Token() async throws {
        // Given
        let request = Scaffolding.getRequest

        // Mock a dummy response.
        var receivedRequests = [URLRequest]()
        URLProtocolMock.mockHandler = {
            receivedRequests.append($0)
            return (Data(), HTTPURLResponse())
        }

        // When
        _ = try await sut.executeRequest(
            request,
            requiringAccessToken: false
        )

        // Then one request was received.
        try XCTAssertCount(receivedRequests, count: 1)

        // Then the request is made against the backend url.
        let receivedRequest = receivedRequests[0]
        XCTAssertEqual(receivedRequest.url?.absoluteString, backendURL.appendingPathComponent("/foo").absoluteString)
    }

    func testExecuteRequest_Requiring_Access_Token() async throws {
        // Given
        let request = Scaffolding.getRequest
        authenticationManager.getValidAccessToken_MockValue = Scaffolding.validAccessToken

        // Mock a dummy response.
        var receivedRequests = [URLRequest]()
        URLProtocolMock.mockHandler = {
            receivedRequests.append($0)
            return (Data(), HTTPURLResponse())
        }

        // When
        _ = try await sut.executeRequest(
            request,
            requiringAccessToken: true
        )

        // Then one request was received.
        try XCTAssertCount(receivedRequests, count: 1)

        // Then the request is made against the backend url.
        let receivedRequest = receivedRequests[0]
        XCTAssertEqual(receivedRequest.url?.absoluteString, backendURL.appendingPathComponent("/foo").absoluteString)

        // Then the request has an access token attached.
        let authorizationHeader = receivedRequest.value(forHTTPHeaderField: "Authorization")
        XCTAssertEqual(authorizationHeader, "Bearer a-valid-access-token")
    }

    func testExecuteRequest_Retry_After_First_Authentication_Error() async throws {
        // Given
        let request = Scaffolding.getRequest
        authenticationManager.getValidAccessToken_MockValue = Scaffolding.validAccessToken

        // Mock a dummy response.
        var receivedRequests = [URLRequest]()
        URLProtocolMock.mockHandler = {
            receivedRequests.append($0)
            return try $0.mockErrorResponse(statusCode: .unauthorized)
        }

        // Mock new access token.
        authenticationManager.refreshAccessToken_MockValue = Scaffolding.newAccessToken

        // When
        _ = try await sut.executeRequest(
            request,
            requiringAccessToken: true
        )

        // Then an existing token was fetched.
        XCTAssertEqual(authenticationManager.getValidAccessToken_Invocations.count, 1)

        // Then two request was received.
        try XCTAssertCount(receivedRequests, count: 2)

        // Then first request has the old access token.
        let firstRequest = receivedRequests[0]
        XCTAssertEqual(
            firstRequest.url?.absoluteString,
            backendURL.appendingPathComponent("/foo").absoluteString
        )
        XCTAssertEqual(
            firstRequest.value(forHTTPHeaderField: "Authorization"),
            "Bearer a-valid-access-token"
        )

        // Then a new token was requested.
        XCTAssertEqual(authenticationManager.refreshAccessToken_Invocations.count, 1)

        // Then the second request has the new access token.
        let secondRequest = receivedRequests[1]
        XCTAssertEqual(
            secondRequest.url?.absoluteString,
            backendURL.appendingPathComponent("/foo").absoluteString
        )
        XCTAssertEqual(
            secondRequest.value(forHTTPHeaderField: "Authorization"),
            "Bearer a-new-access-token"
        )
    }

}

private enum Scaffolding {

    static let userID = UUID(uuidString: "70aa272d-3413-4cda-9059-64c097956583")!

    static let getRequest = try! URLRequestBuilder(path: "/foo")
        .withMethod(.get)
        .withAcceptType(.json)
        .build()

    static let validAccessToken = AccessToken(
        userID: userID,
        token: "a-valid-access-token",
        type: "Bearer",
        expirationDate: Date(timeIntervalSinceNow: 900)
    )

    static let newAccessToken = AccessToken(
        userID: userID,
        token: "a-new-access-token",
        type: "Bearer",
        expirationDate: Date(timeIntervalSinceNow: 900)
    )

}
