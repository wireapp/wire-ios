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

final class NetworkServiceTests: XCTestCase {

    private var sut: NetworkService!
    private var backendURL: URL!
    private var mockDateProvider: CurrentDateProvidingMock!

    override func setUp() async throws {
        // certificate expires on 2025-04-10 GMT
        mockDateProvider = CurrentDateProvidingMock()
        mockDateProvider.now = try Date.ISO8601FormatStyle().parse("2025-04-09T23:59:59Z")

        backendURL = try XCTUnwrap(URL(string: "https://www.example.com"))
        sut = NetworkService(
            baseURL: backendURL,
            urlSessionConfiguration: .mock,
            serverTrustValidator: ServerTrustValidator(
                pinnedKeys: [
                    try PinnedKey(rawKey: PublicKeys.wire, hosts: [.equals("prod-nginz-https.wire.com")])
                ],
                currentDateProvider: mockDateProvider
            )
        )
    }

    override func tearDown() async throws {
        backendURL = nil
        sut = nil
        mockDateProvider = nil
    }

    // MARK: - Init

    func testInit_It_Adds_Slash_To_Path() async throws {
        // Given
        let baseURL = try XCTUnwrap(URL(string: "www.wire.com/staging"))

        // When
        let sut = NetworkService(
            baseURL: baseURL,
            urlSessionConfiguration: .mock,
            serverTrustValidator: ServerTrustValidator(
                pinnedKeys: [],
                currentDateProvider: mockDateProvider
            )
        )

        // Then
        XCTAssertEqual(sut.baseURL.absoluteString, "www.wire.com/staging/")
    }

    func testInit_It_Does_Not_Add_Slash_To_Path_If_It_Has_One() async throws {
        // Given
        let baseURL = try XCTUnwrap(URL(string: "www.wire.com/staging/"))

        // When
        let sut = NetworkService(
            baseURL: baseURL,
            urlSessionConfiguration: .mock,
            serverTrustValidator: ServerTrustValidator(
                pinnedKeys: [],
                currentDateProvider: mockDateProvider
            )
        )

        // Then
        XCTAssertEqual(sut.baseURL.absoluteString, "www.wire.com/staging/")
    }

    // MARK: - Execute request

    func testExecuteRequest_It_Does_Not_Execute_An_Invalid_Request() async throws {
        // Given
        let invalidRequest = Scaffolding.invalidRequest

        // Then
        await XCTAssertThrowsErrorAsync(NetworkServiceError.invalidRequest) {
            // When
            try await self.sut.executeRequest(invalidRequest)
        }
    }

    func testExecuteRequest_It_Throws_When_There_Is_An_Invalid_Response() async throws {
        // Given
        let request = Scaffolding.getRequest

        // Mock an invalid response.
        URLProtocolMock.mockHandler = { _ in
            (Data(), URLResponse())
        }

        // Then
        await XCTAssertThrowsErrorAsync(NetworkServiceError.notAHTTPURLResponse) {
            // When
            try await self.sut.executeRequest(request)
        }
    }

    func testExecuteRequest_Success() async throws {
        // Given
        let request = Scaffolding.getRequest

        // Mock a dummy response.
        var receivedRequests = [URLRequest]()
        URLProtocolMock.mockHandler = {
            receivedRequests.append($0)
            return (Data(), HTTPURLResponse())
        }

        // When
        _ = try await sut.executeRequest(request)

        // Then one request was received.
        try XCTAssertCount(receivedRequests, count: 1)

        // Then the request is made against the backend url.
        let receivedRequest = receivedRequests[0]
        XCTAssertEqual(receivedRequest.url?.absoluteString, backendURL.appendingPathComponent("/foo").absoluteString)
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

    static func makeCredential() -> URLCredential {
        URLCredential(user: "user", password: "password", persistence: .none)
    }

}
