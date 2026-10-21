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

class FeatureConfigsAPIV16: FeatureConfigsAPIV15 {

    override var apiVersion: APIVersion {
        .v16
    }

    override func getFeatureConfigs() async throws -> [FeatureConfig] {
        let request = try URLRequestBuilder(path: resourcePath)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: FeatureConfigsResponseAPIV16.self)
            .failure(code: .forbidden, label: "operation-denied", error: FeatureConfigsAPIError.insufficientPermissions)
            .failure(code: .forbidden, label: "no-team-member", error: FeatureConfigsAPIError.userIsNotTeamMember)
            .failure(code: .notFound, label: "no-team", error: FeatureConfigsAPIError.teamNotFound)
            .parse(code: response.statusCode, data: data)
    }

}

struct FeatureConfigsResponseAPIV16: Decodable, ToAPIModelConvertible {

    private let previousVersion: FeatureConfigsResponseAPIV14
    private let meetings: FeatureWithoutConfig

    private enum CodingKeys: String, CodingKey {
        case meetings
    }

    init(from decoder: any Decoder) throws {
        self.previousVersion = try FeatureConfigsResponseAPIV14(from: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.meetings = try container.decode(FeatureWithoutConfig.self, forKey: .meetings)
    }

    func toAPIModel() -> [FeatureConfig] {
        previousVersion.toAPIModel() + [
            .meetings(MeetingsFeatureConfig(status: meetings.status.toAPIModel()))
        ]
    }

}
