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

class TeamsAPIV5: TeamsAPIV4 {

    override var apiVersion: APIVersion {
        .v5
    }

    // MARK: - Get team

    override func getTeam(for teamID: Team.ID) async throws -> Team {
        let components = URLComponents(string: basePath(for: teamID))

        guard let url = components?.url else {
            assertionFailure("generated an invalid url")
            throw TeamsAPIError.invalidURL
        }

        let request = URLRequestBuilder(url: url)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        // New: 404
        return try ResponseParser()
            .success(code: .ok, type: TeamResponseV2.self)
            .failure(code: .notFound, error: TeamsAPIError.invalidTeamID)
            .failure(code: .notFound, label: "no-team", error: TeamsAPIError.teamNotFound)
            .parse(code: response.statusCode, data: data)
    }

    // MARK: - Get team roles

    override func getTeamRoles(for teamID: Team.ID) async throws -> [ConversationRole] {
        let components = URLComponents(string: "\(basePath(for: teamID))/conversations/roles")

        guard let url = components?.url else {
            assertionFailure("generated an invalid url")
            throw TeamsAPIError.invalidURL
        }

        let request = URLRequestBuilder(url: url)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        // New: 400 error was removed.
        return try ResponseParser()
            .success(code: .ok, type: ConversationRolesListResponseV0.self)
            .failure(code: .forbidden, label: "no-team-member", error: TeamsAPIError.selfUserIsNotTeamMember)
            .parse(code: response.statusCode, data: data)
    }

    // MARK: - Get team members

    override func getTeamMembers(
        for teamID: Team.ID,
        maxResults: UInt
    ) async throws -> [TeamMember] {
        var components = URLComponents(string: "\(basePath(for: teamID))/members")
        components?.queryItems = [URLQueryItem(name: "maxResults", value: "2000")]

        guard let url = components?.url else {
            assertionFailure("generated an invalid url")
            throw TeamsAPIError.invalidURL
        }

        let request = URLRequestBuilder(url: url)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        // New: 400 error was removed.
        return try ResponseParser()
            .success(code: .ok, type: TeamMemberListResponseV0.self)
            .failure(code: .forbidden, label: "no-team-memper", error: TeamsAPIError.selfUserIsNotTeamMember)
            .parse(code: response.statusCode, data: data)
    }

    // MARK: - Get team member legalhold

    override func getLegalholdInfo(
        for teamID: Team.ID,
        userID: UUID
    ) async throws -> TeamMemberLegalholdInfo {
        let components = URLComponents(string: "\(basePath(for: teamID))/legalhold/\(userID.transportString())")

        guard let url = components?.url else {
            assertionFailure("generated an invalid url")
            throw TeamsAPIError.invalidURL
        }

        let request = URLRequestBuilder(url: url)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        // New: 404 invalid request.
        return try ResponseParser()
            .success(code: .ok, type: TeamMemberLegalholdResponseV0.self)
            .failure(code: .notFound, error: TeamsAPIError.invalidRequest)
            .failure(code: .notFound, label: "no-team-member", error: TeamsAPIError.teamMemberNotFound)
            .parse(code: response.statusCode, data: data)
    }

}
