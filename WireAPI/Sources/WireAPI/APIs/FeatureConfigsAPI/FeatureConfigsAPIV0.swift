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

class FeatureConfigsAPIV0: FeatureConfigsAPI, VersionedAPI {

    let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    var apiVersion: APIVersion {
        .v0
    }

    // MARK: - Get feature configs
    
    func getAllFeatureConfigs() async throws {
        let request = HTTPRequest(
            path: "\(pathPrefix)/",
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

//        return try ResponseParser()
//            .success(code: 200, type: UserResponseV0.self)
//            .failure(code: 404, label: "not-found", error: UsersAPIError.userNotFound)
//            .parse(response)
    }
    
}
