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

final class TeamsAPIV15: TeamsAPIV14 {

    override var apiVersion: APIVersion { .v15 }

    // MARK: - Get apps

    override func getApps(
        for teamID: Team.ID
    ) async throws -> [App] {

        let path = "\(basePath(for: teamID))/apps"
        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: GetAppsResponseV15.self)
            .parse(code: response.statusCode, data: data)

    }

}

private struct GetAppsResponseV15: Decodable, ToAPIModelConvertible {

    var apps: [GetAppResponseV14]

    init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.apps = try container.decode([GetAppResponseV14].self)
    }

    func toAPIModel() -> [App] {
        apps.map { $0.toAPIModel() }
    }

}
