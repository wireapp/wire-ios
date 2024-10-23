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
        let networkService = NetworkService(baseURL: backendURL)
        networkService.configure(with: .mockURLSession())
        sut = APIService(
            clientID: Scaffolding.clientID,
            networkService: networkService,
            authenticationStorage: authenticationStorage
        )
    }

    override func tearDown() async throws {
        backendURL = nil
        authenticationStorage = nil
        sut = nil
        try await super.tearDown()
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
        authenticationStorage.storeAccessToken(Scaffolding.validAccessToken)

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

    func testExecuteRequest_Requiring_Access_Token_But_None_Exists() async throws {
        // Given no existing access token.
        let request = Scaffolding.getRequest
        XCTAssertNil(authenticationStorage.fetchAccessToken())

        // Mock responses.
        var receivedRequests = [URLRequest]()
        URLProtocolMock.mockHandler = {
            receivedRequests.append($0)
            switch receivedRequests.count {
            case 1:
                // The first request should be to renew the access token.
                return try $0.mockResponse(
                    statusCode: .ok,
                    jsonResourceName: "PostAccessSuccessResponse200"
                )

            case 2:
                // The second request is just a dummy request.
                return try $0.mockResponse(statusCode: .ok)

            default:
                throw "unexpected request: \($0)"
            }
        }

        // When
        _ = try await sut.executeRequest(
            request,
            requiringAccessToken: true
        )

        // Then there are two requests.
        try XCTAssertCount(receivedRequests, count: 2)
        let snapshotter = HTTPRequestSnapshotHelper()

        // The first is for the access token.
        let accessTokenRequest = receivedRequests[0]
        await snapshotter.verifyRequest(request: accessTokenRequest)

        // The new access token was stored.
        let storedAccessToken = try XCTUnwrap(authenticationStorage.fetchAccessToken())
        XCTAssertEqual(storedAccessToken.userID, Scaffolding.newAccessToken.userID)
        XCTAssertEqual(storedAccessToken.token, Scaffolding.newAccessToken.token)
        XCTAssertEqual(storedAccessToken.type, Scaffolding.newAccessToken.type)

        // The second is for the original request.
        let originalRequest = receivedRequests[1]
        await snapshotter.verifyRequest(request: originalRequest)
    }

    func testExecuteRequest_Requiring_Access_Token_But_Existing_Token_Is_Expiring() async throws {
        // Given an expiring token.
        let request = Scaffolding.getRequest
        authenticationStorage.storeAccessToken(Scaffolding.expiringAccessToken)

        // Mock responses.
        var receivedRequests = [URLRequest]()
        URLProtocolMock.mockHandler = {
            receivedRequests.append($0)
            switch receivedRequests.count {
            case 1:
                // The first request should be to renew the access token.
                return try $0.mockResponse(
                    statusCode: .ok,
                    jsonResourceName: "PostAccessSuccessResponse200"
                )

            case 2:
                // The second request is just a dummy request.
                return try $0.mockResponse(statusCode: .ok)

            default:
                throw "unexpected request: \($0)"
            }
        }

        // When
        _ = try await sut.executeRequest(
            request,
            requiringAccessToken: true
        )

        // Then there are two requests.
        try XCTAssertCount(receivedRequests, count: 2)
        let snapshotter = HTTPRequestSnapshotHelper()

        // The first is for the access token.
        let accessTokenRequest = receivedRequests[0]
        await snapshotter.verifyRequest(request: accessTokenRequest)

        // The new access token was stored.
        let storedAccessToken = try XCTUnwrap(authenticationStorage.fetchAccessToken())
        XCTAssertEqual(storedAccessToken.userID, Scaffolding.newAccessToken.userID)
        XCTAssertEqual(storedAccessToken.token, Scaffolding.newAccessToken.token)
        XCTAssertEqual(storedAccessToken.type, Scaffolding.newAccessToken.type)

        // The second is for the original request.
        let originalRequest = receivedRequests[1]
        await snapshotter.verifyRequest(request: originalRequest)
    }

    func testExecuteRequest_Requiring_Access_Token_But_Invalid_Credentials() async throws {
        // Given an expiring token.
        let request = Scaffolding.getRequest
        authenticationStorage.storeAccessToken(Scaffolding.expiringAccessToken)

        // Mock responses.
        var receivedRequests = [URLRequest]()
        URLProtocolMock.mockHandler = {
            receivedRequests.append($0)
            switch receivedRequests.count {
            case 1:
                // The first request should be to renew the access token.
                return try $0.mockErrorResponse(
                    statusCode: .forbidden,
                    label: "invalid-credentials"
                )

            case 2:
                // The second request is just a dummy request.
                return try $0.mockResponse(statusCode: .ok)

            default:
                throw "unexpected request: \($0)"
            }
        }

        // Then
        await XCTAssertThrowsError(APIServiceError.invalidCredentials) {
            // When
            try await self.sut.executeRequest(
                request,
                requiringAccessToken: true
            )
        }

        // Then there is only one request for the access token renewal
        try XCTAssertCount(receivedRequests, count: 1)
        let accessTokenRequest = receivedRequests[0]
        await HTTPRequestSnapshotHelper().verifyRequest(request: accessTokenRequest)        
    }

}

private enum Scaffolding {

    static let userID = UUID(uuidString: "70aa272d-3413-4cda-9059-64c097956583")!
    static let clientID = "abc123"

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

    static let expiringAccessToken = AccessToken(
        userID: userID,
        token: "an-expiring-access-token",
        type: "Bearer",
        expirationDate: Date(timeIntervalSinceNow: 10)
    )

    static let newAccessToken = AccessToken(
        userID: userID,
        token: "a-new-access-token",
        type: "Bearer",
        expirationDate: Date(timeIntervalSinceNow: 900)
    )

}
