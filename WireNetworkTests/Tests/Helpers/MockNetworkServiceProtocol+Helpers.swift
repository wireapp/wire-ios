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

@testable import WireNetwork
@testable import WireNetworkSupport

extension MockNetworkServiceProtocol {

    typealias Response = (statusCode: HTTPStatusCode, resourceName: String?)

    /// Create a mock network service that returns zero or more responses.
    ///
    /// Some ways you can use this:
    /// - Mock a series of paged responses
    /// - Mock a series or responses for repeated requests
    /// - Mock a single response
    ///
    /// - Parameter responses: The responses to return, one per request received.
    /// - Returns: A mock network service.

    static func withResponses(_ responses: [Response]) -> MockNetworkServiceProtocol {
        let networkService = MockNetworkServiceProtocol()
        var responses = responses

        networkService.executeRequest_MockMethod = { request in
            guard !responses.isEmpty else {
                throw "no response"
            }

            let response = responses.removeFirst()

            return try request.mockResponse(
                statusCode: response.statusCode,
                jsonResourceName: response.resourceName
            )
        }

        return networkService
    }

    static func withError(statusCode: HTTPStatusCode, label: String = "") -> MockNetworkServiceProtocol {
        let networkService = MockNetworkServiceProtocol()
        networkService.executeRequest_MockMethod = { request in
            try request.mockErrorResponse(
                statusCode: statusCode,
                label: label
            )
        }

        return networkService
    }

}
