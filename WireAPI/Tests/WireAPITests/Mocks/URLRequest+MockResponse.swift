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

extension URLRequest {

    func mockResponse(
        statusCode: HTTPStatusCode,
        jsonResourceName: String
    ) throws -> (Data, HTTPURLResponse) {
        guard let url else {
            throw "Unable to create mock response, request is missing url"
        }

        guard let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode.rawValue,
            httpVersion: nil,
            headerFields: ["Content-Type": HTTPContentType.json.rawValue]
        ) else {
            throw "Unable to create mock response"
        }

        let jsonPayload = HTTPClientMock.PredefinedResponse(resourceName: jsonResourceName)

        return (try jsonPayload.data(), response)
    }

}
