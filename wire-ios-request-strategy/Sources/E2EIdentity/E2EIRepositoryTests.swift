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
@testable import WireRequestStrategy

class E2EIRepositoryTests: ZMTBaseTest {

    /// TODO: will be implemented in the next PRs
    func test1() async throws {
        // given

        // when

        // then

    }

    func test2() async throws {
        // given

        // when

        // then

    }

    func test3() async throws {
        // given

        // when

        // then

    }

    func test4() async throws {
        // given

        // when

        // then

    }

    func test5() async throws {
        // given

        // when

        // then

    }

}

class MockAcmeClient: AcmeClientInterface {

    let domain: String

    init(domain: String) {
        self.domain = domain
    }

    func getACMEDirectory() async throws -> Data {
        let payload = acmeDirectoriesResponse()

        return try JSONSerialization.data(withJSONObject: payload, options: [])
    }

    func getACMENonce(url: String) async throws -> String {
        return ""
    }

    func sendACMERequest(url: String, requestBody: Data) async throws -> ACMEResponse {
        return ACMEResponse(nonce: "", location: "", response: Data())
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

class MockHttpClient: HttpClient {

    var mockResponse1: ZMTransportResponse?
    var mockResponse: (Data, URLResponse)?

    func send(_ request: ZMTransportRequest) async throws -> ZMTransportResponse {
        guard let mockResponse1 = mockResponse1 else {
            throw NetworkError.invalidResponse
        }
        return mockResponse1
    }

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        return mockResponse ?? (Data(), URLResponse())
    }

}

class MockAcmeResponse {

    func acmeDirectory() -> AcmeDirectoriesResponse {
        return AcmeDirectoriesResponse(newNonce: "https://acme.elna.wire.link/acme/defaultteams/new-nonce",
                                       newAccount: "https://acme.elna.wire.link/acme/defaultteams/new-account",
                                       newOrder: "https://acme.elna.wire.link/acme/defaultteams/new-order",
                                       revokeCert: "https://acme.elna.wire.link/acme/defaultteams/revoke-cert",
                                       keyChange: "https://acme.elna.wire.link/acme/defaultteams/key-change")

    }

}
