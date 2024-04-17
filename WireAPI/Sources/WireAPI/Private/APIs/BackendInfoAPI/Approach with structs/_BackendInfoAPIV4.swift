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

struct _BackendInfoAPIV4: BackendInfoAPI {

    let httpClient: HTTPClient

    private let path = "/api-version"
    private let decoder = ResponsePayloadDecoder(decoder: .defaultDecoder)

    func getBackendInfo() async throws -> BackendInfo {
        let request = HTTPRequest(
            path: path,
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        switch try decoder.decodePayload(
            from: response,
            as: BackendInfoResponseV4.self
        ) {
        case .success(let payload):
            return payload.toParent()

        case .failure(let payload):
            throw payload
        }
    }

}

private struct BackendInfoResponseV4: Decodable {

    var domain: String
    var federation: Bool
    var supported: [UInt]
    var development: [UInt]

    func toParent() -> BackendInfo {
        .init(
            domain: domain,
            isFederationEnabled: federation,
            supportedVersions: Set(supported.compactMap(APIVersion.init)),
            developmentVersions: Set(development.compactMap(APIVersion.init))
        )
    }

}
