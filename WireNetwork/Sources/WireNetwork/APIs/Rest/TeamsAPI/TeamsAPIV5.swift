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

class TeamsAPIV5: TeamsAPIV4 {

    override var apiVersion: APIVersion {
        .v5
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

        // New: 404
        return try ResponseParser()
            .success(code: .ok, type: TeamResponseV2.self)
            .failure(code: .notFound, error: TeamsAPIError.invalidTeamID)
            .failure(code: .notFound, label: "no-team", error: TeamsAPIError.teamNotFound)
            .parse(code: response.statusCode, data: data)
    }

    // MARK: - Get team roles

    override func getTeamRoles(for teamID: Team.ID) async throws -> [ConversationRole] {
        let path = "\(basePath(for: teamID))/conversations/roles"

        let request = try URLRequestBuilder(path: path)
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
        let path = "\(basePath(for: teamID))/members"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .withQueryItem(name: "maxResults", value: "2000")
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
        let path = "\(basePath(for: teamID))/legalhold/\(userID.transportString())"

        let request = try URLRequestBuilder(path: path)
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

    // MARK: - Get whitelisted bots

    override func getWhitelistedBots(
        for teamID: Team.ID,
        with prefix: String
    ) -> PayloadPager<[WhitelistedBotProfile]> {

        let path = "\(basePath(for: teamID))/services/whitelisted"

        return PayloadPager(start: nil) { nextSince in // TODO: fix pagination

            var requestBuilder = try URLRequestBuilder(path: path)
                .withMethod(.get)

            if let nextSince {
                requestBuilder = requestBuilder.withQueryItem(name: "since", value: nextSince)
            }

            let request = requestBuilder.build()

            let (data, response) = try await self.apiService.executeRequest(
                request,
                requiringAccessToken: true
            )

            return try ResponseParser()
                .success(code: .ok, type: PaginatedWhitelistedBotProfileResponseV5.self)
                .parse(code: response.statusCode, data: data)

        }
    }

}

private struct PaginatedWhitelistedBotProfileResponseV5: Decodable, ToAPIModelConvertible {

    let services: [WhitelistedBotProfileResponseV5]
    let hasMore: Bool?

    enum CodingKeys: String, CodingKey {

        case services
        case hasMore = "has_more"

    }

    func toAPIModel() -> PayloadPager<[WhitelistedBotProfile]>.Page {
        .init(
            element: services.map { $0.toAPIModel() },
            hasMore: hasMore ?? false,
            nextStart: services.last?.id.uuidString ?? ""
        )
    }

}

private struct WhitelistedBotProfileResponseV5: Decodable, ToAPIModelConvertible {

    var id: UUID
    var qualifiedID: QualifiedIDV0?
    var name: String?
    var summary: String?
    var provider: UUID
    var handle: String?
    var teamID: UUID?
    var accentID: Int?
    var assets: [UserAssetV0]
    var isDeleted: Bool?

    enum CodingKeys: String, CodingKey {

        case id
        case qualifiedID = "qualified_id"
        case name
        case summary
        case provider
        case handle
        case teamID = "team"
        case accentID = "accent_id"
        case assets
        case isDeleted = "deleted"

    }

    func toAPIModel() -> WhitelistedBotProfile {
        WhitelistedBotProfile(
            id: id,
            qualifiedID: qualifiedID?.toAPIModel(),
            name: name ?? "",
            summary: summary ?? "",
            provider: provider,
            handle: handle ?? "",
            teamID: teamID,
            accentID: accentID,
            assets: assets.map { $0.toAPIModel() },
            isDeleted: isDeleted ?? false
        )
    }

}
