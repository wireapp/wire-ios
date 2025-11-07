//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

struct UpgradePersonalToTeamEndpoint {

    let apiVersion: APIVersion
    let apiService: any APIServiceProtocol

    func callAsFunction(
        for teamName: String
    ) async throws -> UpgradedAccountTeam {
        guard apiVersion >= .v7 else {
            throw RestAPIError.unsupportedAPIVersion(apiVersion)
        }

        let path = "/v\(apiVersion.rawValue)/upgrade-personal-to-team"
        let body = BodyV7(name: teamName)

        let encodedJSON: Data
        do {
            encodedJSON = try JSONEncoder.defaultEncoder.encode(body)
        } catch {
            assertionFailure("failed to encode body")
            throw RestAPIError.failedToEncodeBody(error)
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
            .success(
                code: .ok,
                type: ResponseV7.self
            )
            .failure(
                code: .forbidden,
                label: "user-already-in-a-team",
                error: AccountsAPIError.userAlreadyInATeam
            )
            .failure(
                code: .notFound,
                label: "not-found",
                error: AccountsAPIError.userNotFound
            )
            .parse(
                code: response.statusCode,
                data: data
            )
    }

    // MARK: - Payloads

    private struct BodyV7: Codable, Sendable {

        let currency: String?
        let icon: String
        let icon_key: String?
        let name: String

        init(
            currency: String? = nil,
            icon: String = "default",
            icon_key: String? = nil,
            name: String
        ) {
            self.currency = currency
            self.icon = icon
            self.icon_key = icon_key
            self.name = name
        }
    }

    private struct ResponseV7: Decodable, ToAPIModelConvertible, Sendable {

        let teamId: UUID
        let teamName: String

        func toAPIModel() -> UpgradedAccountTeam {
            UpgradedAccountTeam(
                teamId: teamId,
                teamName: teamName
            )
        }
    }

}
