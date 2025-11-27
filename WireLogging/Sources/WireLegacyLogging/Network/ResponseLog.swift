//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

struct ResponseLog: Codable {
    enum CodingKeys: String, CodingKey {
        case endpoint
        case status
        case failureBody = "failure_body"
    }

    var endpoint: String
    var status: Int
    var failureBody: FailureBody?

    init?(_ response: HTTPURLResponse, body: Data?) {
        guard let url = response.url else { return nil }
        self.endpoint = url.endpointRemoteLogDescription
        self.status = response.statusCode
        if let data = body, 400 ..< 500 ~= self.status {
            self.failureBody = try? JSONDecoder().decode(FailureBody.self, from: data)
        }
    }
}

struct FailureBody: Codable {
    let code: Int
    let label: String
    let message: String
}
