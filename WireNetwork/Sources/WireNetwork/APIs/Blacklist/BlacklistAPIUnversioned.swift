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

struct BlacklistAPIUnversioned: BlacklistAPI {

    let networkService: any NetworkServiceProtocol

    func getBlacklist() async throws -> BuildNumberBlacklist {
        let request = try URLRequestBuilder(path: "/ios")
            .withAcceptType(.json)
            .build()

        let (data, response) = try await networkService.executeRequest(request)

        return try ResponseParser()
            .success(code: .ok, type: ResponsePayload.self)
            .parse(code: response.statusCode, data: data)
    }

}

private struct ResponsePayload: Decodable, ToAPIModelConvertible {

    let minVersion: String
    let exclude: [String]

    enum CodingKeys: String, CodingKey {

        case minVersion = "min_version"
        case exclude

    }

    func toAPIModel() -> BuildNumberBlacklist {
        BuildNumberBlacklist(
            minimumLegalBuildNumber: minVersion,
            illegalBuildNumbers: Set(exclude)
        )
    }

}
