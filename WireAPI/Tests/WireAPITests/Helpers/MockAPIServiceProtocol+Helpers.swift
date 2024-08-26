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
@testable import WireAPISupport

extension MockAPIServiceProtocol {

    typealias Response = (statusCode: HTTPStatusCode, resourceName: String)

    static func withResponses(_ responses: [Response]) -> MockAPIServiceProtocol {
        let apiService = MockAPIServiceProtocol()
        var responses = responses

        apiService.executeRequestRequiringAccessToken_MockMethod = { request, _ in
            guard !responses.isEmpty else {
                throw "no response"
            }

            let response = responses.removeFirst()

            return try request.mockResponse(
                statusCode: response.statusCode,
                jsonResourceName: response.resourceName
            )
        }

        return apiService
    }

    static func withError(statusCode: HTTPStatusCode, label: String = "") -> MockAPIServiceProtocol {
        let apiService = MockAPIServiceProtocol()
        apiService.executeRequestRequiringAccessToken_MockMethod = { request, _ in
            try request.mockErrorResponse(
                statusCode: statusCode,
                label: label
            )
        }

        return apiService
    }

}
