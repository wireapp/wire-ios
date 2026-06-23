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

import Foundation
import WireTransport
@testable import WireRequestStrategy

final class AcmeAPITests: ZMTBaseTest {

    var acmeApi: AcmeAPI?
    var mockHttpClient: MockHttpClient?
    private let encoder: JSONEncoder = .defaultEncoder

    override func setUp() {
        super.setUp()

        mockHttpClient = MockHttpClient()
        if let mockHttpClient {
            let path = "https://acme/defaultteams/directory"
            acmeApi = AcmeAPI(acmeDiscoveryPath: path, httpClient: mockHttpClient)
        }
    }

    override func tearDown() {
        acmeApi = nil
        mockHttpClient = nil

        super.tearDown()
    }

    func testThatItSendsTrustAnchorRequest() async throws {
        // given
        let path = "https://acme/roots.pem"

        // mock
        let mockResponse = HTTPURLResponse(
            url: URL(string: path)!,
            statusCode: 200,
            httpVersion: "",
            headerFields: nil
        )!
        let mockData = Data()
        mockHttpClient?.mockResponse = (mockData, mockResponse)

        // when
        _ = try await acmeApi?.getTrustAnchor()
        let request = try XCTUnwrap(mockHttpClient?.sentRequests.first)

        // then
        XCTAssertEqual(request.url?.absoluteString, "https://acme/roots.pem")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testThatItSendsFederationCertificateRequest() async throws {
        // given
        let path = "https://acme/federation"

        // mock
        let mockResponse = HTTPURLResponse(
            url: URL(string: path)!,
            statusCode: 200,
            httpVersion: "",
            headerFields: nil
        )!

        let mockCertificates = [
            "certificate_1",
            "certificate_2",
            "certificate_3"
        ]
        let mockPayload = FederationCertificates(certificates: mockCertificates)
        let mockData = try encoder.encode(mockPayload)
        mockHttpClient?.mockResponse = (mockData, mockResponse)

        // when
        let certificates = try await acmeApi?.getFederationCertificates()
        let request = try XCTUnwrap(mockHttpClient?.sentRequests.first)

        // then
        XCTAssertEqual(request.url?.absoluteString, "https://acme/federation")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(certificates, mockCertificates)
    }

}

class MockHttpClient: HttpClientCustom {

    var mockResponse: (Data, URLResponse)?
    var sentRequests: [URLRequest] = []

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        sentRequests.append(request)
        guard let mockResponse else {
            throw NetworkError.errorDecodingURLResponse(mockResponse!.1)
        }
        return mockResponse
    }

}
