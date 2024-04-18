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

extension APIService {
    public func getBackendInfo(for version: APIVersion) async throws -> BackendInfoModel {
        let endpoint = Endpoints.BackendInfo()
        let decoder = JSONDecoder() // TODO: use the custom decoder

        let data = try await request(endpoint)

        switch version {
        case .v0, .v1:
            return try decoder.decode(BackendInfoModelV0.self, from: data).toParent()
        case .v2, .v3, .v4, .v5, .v6:
            return try decoder.decode(BackendInfoModelV2.self, from: data).toParent()
        }
    }
}
