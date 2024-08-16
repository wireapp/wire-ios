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

class BackendInfoAPIImpl: BackendInfoAPI {

    let apiService: any APIServiceProtocol

    init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    func getBackendInfo() async throws -> BackendInfo {
        let request = try URLRequestBuilder(path: "/api-version")
            .withMethod(.get)
            .withAcceptType(.json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: false
        )

        return try ResponseParser()
            .success(code: .ok, type: BackendInfoResponse.self)
            .parse(code: response.statusCode, data: data)
    }

}

private struct BackendInfoResponse: Decodable, ToAPIModelConvertible {

    var domain: String
    var federation: Bool
    var supported: [UInt]
    var development: [UInt]?

    func toAPIModel() -> BackendInfo {
        .init(
            domain: domain,
            isFederationEnabled: federation,
            supportedVersions: Set(supported.compactMap(APIVersion.init)),
            developmentVersions: Set(development?.compactMap(APIVersion.init) ?? [])
        )
    }

}
