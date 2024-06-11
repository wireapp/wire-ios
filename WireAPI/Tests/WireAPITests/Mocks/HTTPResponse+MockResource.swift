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

import WireAPI
import XCTest

extension HTTPResponse {
    // MARK: Error

    static func mockError(code: Int, label: String, message: String? = nil) throws -> HTTPResponse {
        let payloadString = """
        {
            "code": \(code),
            "label": "\(label)",
            "message": "\(message ?? "")"
        }
        """
        let payload = try XCTUnwrap(payloadString.data(using: .utf8))

        return HTTPResponse(
            code: code,
            payload: payload
        )
    }

    // MARK: JSON

    static func mockJSONResource(code: Int, jsonResource: String) throws -> HTTPResponse {
        try HTTPResponse(
            code: code,
            payload: data(jsonContentsOf: jsonResource)
        )
    }

    private static func data(jsonContentsOf resourceName: String) throws -> Data {
        guard let url = Bundle.module.url(
            forResource: resourceName,
            withExtension: "json"
        ) else {
            throw HTTPClientMockError(message: "payload resource \(resourceName).json not found")
        }

        do {
            return try Data(contentsOf: url)
        } catch {
            throw HTTPClientMockError(message: "unable to load data from resource: \(error)")
        }
    }
}
