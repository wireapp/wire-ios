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

final class SystemSettingsAPIV18: SystemSettingsAPI, VersionedAPI {

    let networkService: any NetworkServiceProtocol

    init(networkService: any NetworkServiceProtocol) {
        self.networkService = networkService
    }

    var apiVersion: APIVersion {
        .v18
    }

    func getSystemSettings(accessToken: AccessToken?) async throws -> SystemSettings {
        var request = try URLRequestBuilder(path: "\(pathPrefix)/system/settings")
            .withMethod(.get)
            .withAcceptType(.json)
            .build()

        if let accessToken {
            request.setAccessToken(accessToken)
        }

        let (data, response) = try await networkService.executeRequest(request)

        return try ResponseParser()
            .success(code: .ok, type: SystemSettingsResponseV18.self)
            .parse(code: response.statusCode, data: data)
    }

}

private struct SystemSettingsResponseV18: Decodable, ToAPIModelConvertible {

    let nomadProfiles: Bool?
    let setEnableMls: Bool
    let setRestrictUserCreation: Bool
    let ssoIdpChangeDetectionEnabled: Bool

    func toAPIModel() -> SystemSettings {
        SystemSettings(
            nomadProfiles: nomadProfiles ?? false,
            setEnableMls: setEnableMls,
            setRestrictUserCreation: setRestrictUserCreation,
            ssoIdpChangeDetectionEnabled: ssoIdpChangeDetectionEnabled
        )
    }

}
