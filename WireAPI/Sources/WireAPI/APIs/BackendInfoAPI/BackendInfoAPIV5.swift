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

class BackendInfoAPIV5: BackendInfoAPIV4 {

    override var apiVersion: APIVersion { .v5 }

    override func getBackendMLSPublicKeys() async throws -> BackendMLSPublicKeys {
        let request = try URLRequestBuilder(path: "\(pathPrefix)/mls/public-keys")
            .withMethod(.get)
            .withAcceptType(.json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: BackendMLSPublicKeysResponseV5.self)
            .failure(code: .badRequest, label: "mls-not-enabled", error: BackendInfoAPIError.mlsNotEnabled)
            .parse(code: response.statusCode, data: data)
    }

}

private struct BackendMLSPublicKeysResponseV5: Decodable, ToAPIModelConvertible {

    var removal: MLSPublicKeys

    func toAPIModel() -> BackendMLSPublicKeys {
        .init(removal: removal)
    }

}
