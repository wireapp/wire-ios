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

final class TeamsAPIV18: TeamsAPIV17 {

    override var apiVersion: APIVersion {
        .v18
    }

    override func getPreventAdminlessGroupsFeatureConfig(teamID: Team
        .ID) async throws -> PreventAdminlessGroupsFeatureConfig {
        let path = "\(basePath(for: teamID))/features/preventAdminlessGroups"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: FeatureWithConfig<FeatureConfigResponse.PreventAdminlessGroupsV18>.self)
            .failure(code: .forbidden, label: "no-team-member", error: TeamsAPIError.selfUserIsNotTeamMember)
            .failure(code: .notFound, label: "no-team", error: TeamsAPIError.teamNotFound)
            .parse(code: response.statusCode, data: data)
    }

}

extension FeatureWithConfig<FeatureConfigResponse.PreventAdminlessGroupsV18>: ToAPIModelConvertible {

    func toAPIModel() -> PreventAdminlessGroupsFeatureConfig {
        PreventAdminlessGroupsFeatureConfig(
            status: status.toAPIModel(),
            promotionStrategy: config.promotionStrategy,
            deletionTimeout: config.deletionTimeout,
            reminderTimeouts: config.reminderTimeouts
        )
    }
}
