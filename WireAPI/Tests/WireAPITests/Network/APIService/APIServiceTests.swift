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

import WireTestingPackage
import XCTest

@testable import WireAPI
@testable import WireAPISupport

final class APIServiceTests: XCTestCase {

    var sut: APIService!
    var backendURL: URL!
    var authenticationStorage: InMemoryAuthenticationStorage!

    override func setUp() async throws {
        try await super.setUp()
        backendURL = try XCTUnwrap(URL(string: "https://www.example.com"))
        authenticationStorage = InMemoryAuthenticationStorage()
        sut = APIService(
            backendURL: backendURL,
            authenticationStorage: authenticationStorage,
            urlSession: .mock,
            minTLSVersion: .v1_2
        )
    }

    override func tearDown() async throws {
        backendURL = nil
        authenticationStorage = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Execute request

    func testItDoesNotExecuteAnInvalidRequest() async throws {
        // Given
        let invalidRequest = Scaffolding.invalidRequest

        // Then
        await XCTAssertThrowsError(APIServiceError.invalidRequest) {
            // When
            try await self.sut.executeRequest(
                invalidRequest,
                requiringAccessToken: false
            )
        }
    }

    func testItThrowsWhenThereIsAnInvalidResponse() async throws {
        // Given
        let request = Scaffolding.getRequest

        // Mock an invalid response.
        URLProtocolMock.mockHandler = { _ in
            (Data(), URLResponse())
        }

        // Then
        await XCTAssertThrowsError(APIServiceError.notAHTTPURLResponse) {
            // When
            try await self.sut.executeRequest(
                request,
                requiringAccessToken: false
            )
        }
    }

    func testItExecutesARequestNotRequiringAuthentication() async throws {
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

    func testItExecutesARequestRequiringAuthentication() async throws {
        // Given
        let request = Scaffolding.getRequest
        authenticationStorage.storeAccessToken(Scaffolding.accessToken)

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
        XCTAssertEqual(authorizationHeader, "Bearer some-access-token")
    }

    func testItThrowsIfAuthenticationIsRequiredButNoAccessTokenIsFound() async throws {
        // Given
        let request = Scaffolding.getRequest
        XCTAssertNil(authenticationStorage.fetchAccessToken())

        // Mock a dummy response.
        URLProtocolMock.mockHandler = { _ in
            (Data(), HTTPURLResponse())
        }

        // Then
        await XCTAssertThrowsError(APIServiceError.missingAccessToken) {
            // When
            try await self.sut.executeRequest(
                request,
                requiringAccessToken: true
            )
        }
    }

}

private enum Scaffolding {

    static let getRequest = try! URLRequestBuilder(path: "/foo")
        .withMethod(.get)
        .withAcceptType(.json)
        .build()

    static let invalidRequest: URLRequest = {
        var request = getRequest
        request.url = nil
        return request
    }()

    static let accessToken = AccessToken(
        userID: UUID(),
        token: "some-access-token",
        type: "Bearer",
        validityInSeconds: 900
    )

}
