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

class TeamsAPIV2: TeamsAPIV1 {

    override var apiVersion: APIVersion {
        .v2
    }

    // MARK: - Get team

    override func getTeam(for teamID: Team.ID) async throws -> Team {
        let request = HTTPRequest(
            path: basePath(for: teamID),
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            // New response payload.
            .success(code: 200, type: TeamResponseV2.self)
            .failure(code: 404, error: TeamsAPIError.invalidTeamID)
            .failure(code: 404, label: "no-team", error: TeamsAPIError.teamNotFound)
            .parse(response)
    }

}

struct TeamResponseV2: Decodable, ToParentConvertible {

    let id: UUID
    let name: String
    let creator: UUID
    let icon: String
    let icon_key: String?
    let binding: Bool?

    // New
    let splash_screen: String?

    func toParent() -> Team {
        Team(
            id: id,
            name: name,
            creatorID: creator,
            logoID: icon,
            logoKey: icon_key,
            splashScreenID: splash_screen
        )
    }

}
