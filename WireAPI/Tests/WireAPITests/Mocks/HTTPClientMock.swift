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
@testable import WireAPI

struct HTTPClientMockError: Error {

    let message: String

}

final class HTTPClientMock: HTTPClient {

    private(set) var receivedRequests: [HTTPRequest] = []

    var receivedRequest: HTTPRequest? {
        receivedRequests.first
    }

    var executeRequestMock: (HTTPRequest) async throws -> HTTPResponse

    convenience init() {
        self.init { request in
            throw HTTPClientMockError(message: "response not mocked for request: \(request.path)")
        }
    }

    convenience init(responses: [HTTPResponse]) {
        var responses = responses

        self.init { _ in
            if responses.isEmpty {
                throw HTTPClientMockError(message: "no more responses")
            } else {
                return responses.removeFirst()
            }
        }
    }

    convenience init(
        code: HTTPStatusCode,
        payloadResourceName: String
    ) throws {
        let response = PredefinedResponse(resourceName: payloadResourceName)

        self.init(
            code: code,
            payload: try response.data()
        )
    }

    convenience init(
        code: HTTPStatusCode,
        errorLabel: String
    ) throws {
        try self.init(
            code: code,
            jsonResponse: """
            {
                "code": \(code.rawValue),
                "label": "\(errorLabel)",
                "message": ""
            }
            """
        )
    }

    convenience init(
        code: HTTPStatusCode,
        jsonResponse: String
    ) throws {
        guard let payload = jsonResponse.data(using: .utf8) else {
            throw HTTPClientMockError(message: "failed to create response payload data")
        }

        self.init(
            code: code,
            payload: payload
        )
    }

    convenience init(
        code: HTTPStatusCode,
        payload: Data?
    ) {
        self.init { _ in
            HTTPResponse(
                code: code.rawValue,
                payload: payload
            )
        }
    }

    init(executeRequestMock: @escaping (HTTPRequest) async throws -> HTTPResponse) {
        self.executeRequestMock = executeRequestMock
    }

    func executeRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        receivedRequests.append(request)
        return try await executeRequestMock(request)
    }
}

// MARK: - Predefined responses

extension HTTPClientMock {

    struct PredefinedResponse {
        var resourceName: String

        func data() throws -> Data {
            guard let url = Bundle.module.url(
                forResource: resourceName,
                withExtension: "json"
            ) else {
                throw HTTPClientMockError(message: "payload resource \(resourceName).json not found")
            }

            let payload: Data
            do {
                payload = try Data(contentsOf: url)
            } catch {
                throw HTTPClientMockError(message: "unable to load data from resource: \(error)")
            }
            return payload
        }
    }
}
