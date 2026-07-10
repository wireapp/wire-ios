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
import WireLogging

class TeamsAPIV10: TeamsAPIV9 {

    override var apiVersion: APIVersion { .v10 }

    // MARK: - Get collaborators

    override func getCollaborators(
        for teamID: Team.ID
    ) async throws -> [CollaboratorInfo] {

        let path = "\(basePath(for: teamID))/collaborators"
        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: GetCollaboratorsResponseV10.self)
            .parse(code: response.statusCode, data: data)

    }

}

private struct GetCollaboratorsResponseV10: Decodable, ToAPIModelConvertible {

    var collaborators: [CollaboratorV10]

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.collaborators = try container.decode([CollaboratorV10].self)
    }

    func toAPIModel() -> [CollaboratorInfo] {
        collaborators.map { $0.toAPIModel() }
    }

}

private struct CollaboratorV10: Decodable, ToAPIModelConvertible {

    var user: UUID
    var team: UUID
    var permissions: [String]

    func toAPIModel() -> CollaboratorInfo {
        CollaboratorInfo(
            userID: user,
            teamID: team,
            permissions: permissions.compactMap { rawValue in
                guard let permission = CollaboratorPermission(rawValue: rawValue) else {
                    WireLogger.network.warn(
                        "CollaboratorPermission \"\(rawValue)\" is unknown",
                        attributes: .safePublic
                    )
                    return nil
                }
                return permission
            }
        )
    }

}
