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

class AccountsAPIV7: AccountsAPIV6 {
    override var apiVersion: APIVersion {
        .v7
    }

    override func upgradeToTeam(teamName: String) async throws -> UpgradedAccountTeam {
        let path = "/upgrade-personal-to-team"
        let body = UpgradeToTeamRequestBodyV7(name: teamName)

        let encodedJSON: Data
        do {
            encodedJSON = try JSONEncoder.defaultEncoder.encode(body)
        } catch {
            assertionFailure("failed to encode body")
            throw AccountsAPIError.invalidRequestBody
        }

        let request = try URLRequestBuilder(path: path)
            .withBody(encodedJSON, contentType: .json)
            .withMethod(.post)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try ResponseParser(decoder: decoder)
            .success(code: .ok, type: UpgradeToTeamResponseV7.self)
            .failure(code: .forbidden, label: "user-already-in-a-team", error: AccountsAPIError.userAlreadyInATeam)
            .failure(code: .notFound, label: "not-found", error: AccountsAPIError.userNotFound)
            .parse(code: response.statusCode, data: data)
    }
}
