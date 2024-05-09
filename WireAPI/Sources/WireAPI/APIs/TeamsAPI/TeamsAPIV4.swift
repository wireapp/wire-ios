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

class TeamsAPIV4: TeamsAPIV3 {

    override var apiVersion: APIVersion {
        .v4
    }

    // MARK: - Get team

    override func getTeam(for teamID: Team.ID) async throws -> Team {
        let request = HTTPRequest(
            path: basePath(for: teamID),
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        switch response.code {
        case 200:
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
            case (400, ""):
                // New
                throw TeamsAPIError.invalidTeamID

            case (404, "no-team"):
                throw TeamsAPIError.teamNotFound

            default:
                throw failure
            }
        }
    }

    // MARK: - Get team roles

    override func getTeamRoles(for teamID: Team.ID) async throws -> [ConversationRole] {
        let request = HTTPRequest(
            path: "\(basePath(for: teamID))/conversations/roles",
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        switch response.code {
        case 200:
            let payload = try decoder.decodePayload(
                from: response,
                as: ConversationRolesListResponseV0.self
            )

            return payload.conversation_roles.map {
                $0.toParent()
            }

        default:
            let failure = try decoder.decodePayload(
                from: response,
                as: FailureResponse.self
            )

            switch (failure.code, failure.label) {
            case (400, ""):
                // Changed: code was 404.
                throw TeamsAPIError.teamNotFound

            case (403, "no-team-member"):
                throw TeamsAPIError.selfUserIsNotTeamMember

            default:
                throw failure
            }
        }
    }

    // MARK: - Get team members

    override func getTeamMembers(
        for teamID: Team.ID,
        maxResults: UInt
    ) async throws -> [TeamMember] {
        var components = URLComponents(string: "\(basePath(for: teamID))/members")
        components?.queryItems = [URLQueryItem(name: "maxResults", value: "2000")]
        
        guard let path = components?.url?.absoluteString else {
            throw TeamsAPIError.failedToGenerateRequest
        }

        let request = HTTPRequest(
            path: path,
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        switch response.code {
        case 200:
            let payload = try decoder.decodePayload(
                from: response,
                as: TeamMemberListResponseV0.self
            )

            // Although this is a paginated response, we intentionally only return
            // the first page and ignore the rest. See WPB-6485.
            return payload.members.map {
                $0.toParent()
            }

        default:
            let failure = try decoder.decodePayload(
                from: response,
                as: FailureResponse.self
            )

            // Changed: 404 error was removed.
            switch (failure.code, failure.label) {
            case (400, ""):
                // New
                throw TeamsAPIError.invalidRequest

            case (403, "no-team-member"):
                throw TeamsAPIError.selfUserIsNotTeamMember

            default:
                throw failure
            }
        }
    }

}
