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

    var receivedRequest: HTTPRequest?
    var executeRequestMock: (HTTPRequest) async throws -> HTTPResponse

    convenience init() {
        self.init { request in
            throw HTTPClientMockError(message: "response not mocked for request: \(request.path)")
        }
    }

    convenience init(code: Int, jsonResponse: String) throws {
        guard let payload = jsonResponse.data(using: .utf8) else {
            throw HTTPClientMockError(message: "failed to create response payload data")
        }

        self.init { _ in
            HTTPResponse(
                code: code,
                payload: payload
            )
        }
    }

    init(executeRequestMock: @escaping (HTTPRequest) async throws -> HTTPResponse) {
        self.executeRequestMock = executeRequestMock
    }

    func executeRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        receivedRequest = request
        return try await executeRequestMock(request)
    }

}
