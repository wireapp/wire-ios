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

class BackendInfoAPIV0: BackendInfoAPI {

    let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    let path = "/api-version"
    let decoder = ResponsePayloadDecoder()

    func getBackendInfo() async throws -> BackendInfo {
        let request = HTTPRequest(
            path: path,
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        switch try decoder.decodePayload(
            from: response,
            as: BackendInfoResponseV0.self
        ) {
        case .success(let payload):
            return payload.toParent()

        case .failure(let payload):
            throw payload
        }
    }

}

private struct BackendInfoResponseV0: Decodable {

    var domain: String
    var federation: Bool
    var supported: [UInt]

    func toParent() -> BackendInfo {
        .init(
            domain: domain,
            isFederationEnabled: federation,
            supportedVersions: Set(supported.compactMap(APIVersion.init)),
            developmentVersions: []
        )
    }

}
