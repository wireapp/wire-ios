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
            path: path(for: teamID),
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        switch response.code {
        case 200:
            // New response payload.
            let payload = try decoder.decodePayload(
                from: response,
                as: TeamResponseV2.self
            )

            return payload.toParent()

        default:
            let failure = try decoder.decodePayload(
                from: response,
                as: FailureResponse.self
            )

            switch (failure.code, failure.label) {
            case (404, ""):
                throw TeamsAPIError.invalidTeamID

            case (404, "no-team"):
                throw TeamsAPIError.teamNotFound

            default:
                throw failure
            }
        }
    }

}

struct TeamResponseV2: Decodable {

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
