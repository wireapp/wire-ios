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

class TeamsAPIV2: TeamsAPIV1 {

    override var apiVersion: APIVersion {
        .v2
    }

    // MARK: - Get team

    override func getTeam(for teamID: Team.ID) async throws -> Team {
        let request = try URLRequestBuilder(path: basePath(for: teamID))
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            // New response payload.
            .success(code: .ok, type: TeamResponseV2.self)
            .failure(code: .notFound, error: TeamsAPIError.invalidTeamID)
            .failure(code: .notFound, label: "no-team", error: TeamsAPIError.teamNotFound)
            .parse(code: response.statusCode, data: data)
    }

    // MARK: - Get team members for ids

    override func getTeamMembers(
        of teamID: Team.ID,
        for userIDs: [UUID]
    ) async throws -> [TeamMember] {

        let maxResults = 2000 // backend-side limit
        guard userIDs.count <= maxResults else {
            throw TeamsAPIError.invalidRequest
        }

        let path = "\(basePath(for: teamID))/get-members-by-ids-using-post"

        let body = try JSONEncoder.defaultEncoder.encode(
            GetMembersByIDsRequestV2(userIDs: userIDs)
        )

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withQueryItem(name: "maxResults", value: "\(maxResults)")
            .withBody(body, contentType: .json)
            .withAcceptType(.json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            // The specs mention, that the backend currently doesn't paginate for this endpoint.
            .success(code: .ok, type: TeamMemberListResponseV0.self)
            .failure(code: .badRequest, error: TeamsAPIError.invalidQueryParmeter)
            .failure(code: .forbidden, label: "no-team-member", error: TeamsAPIError.selfUserIsNotTeamMember)
            .failure(code: .notFound, error: TeamsAPIError.teamNotFound)
            .parse(code: response.statusCode, data: data)

    }

}

struct TeamResponseV2: Decodable, ToAPIModelConvertible {

    let id: UUID
    let name: String
    let creator: UUID
    let icon: String
    let iconKey: String?
    let binding: Bool?

    // New
    let splashScreen: String?

    enum CodingKeys: String, CodingKey {

        case id
        case name
        case creator
        case icon
        case iconKey = "icon_key"
        case binding
        case splashScreen = "splash_screen"

    }

    func toAPIModel() -> Team {
        Team(
            id: id,
            name: name,
            creatorID: creator,
            logoID: icon,
            logoKey: iconKey,
            splashScreenID: splashScreen
        )
    }

}

private struct GetMembersByIDsRequestV2: Encodable {

    var userIDs: [UUID]

    enum CodingKeys: String, CodingKey {
        case userIDs = "user_ids"
    }

}
