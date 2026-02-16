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

class TeamsAPIV14: TeamsAPIV13 {

    override var apiVersion: APIVersion { .v14 }

    override func getApp(
        for teamID: Team.ID,
        with id: UUID
    ) async throws -> App {

        let path = "\(basePath(for: teamID))/apps/\(id.transportString())"
        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: GetAppResponseV14.self)
        // TODO: errors?
//            .failure(code: .notFound, error: TeamsAPIError.invalidTeamID)
//            .failure(code: .notFound, label: "no-team", error: TeamsAPIError.teamNotFound)
            .parse(code: response.statusCode, data: data)

    }

}

struct GetAppResponseV14: Decodable, ToAPIModelConvertible {

//    let id: UUID
    let name: String
//    let creator: UUID
//    let icon: String
//    let iconKey: String?
//    let binding: Bool?

    enum CodingKeys: String, CodingKey {

//        case id
        case name
//        case creator
//        case icon
//        case iconKey = "icon_key"
//        case binding
//        case splashScreen = "splash_screen"

    }

    func toAPIModel() -> App {
        App(
            name: name
        )
    }

}
