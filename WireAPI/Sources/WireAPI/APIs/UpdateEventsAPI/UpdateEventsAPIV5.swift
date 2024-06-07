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

class UpdateEventsAPIV5: UpdateEventsAPIV4 {

    override var apiVersion: APIVersion {
        .v5
    }

    private var basePath: String {
        "/notifications"
    }

    override func getLastUpdateEvent(selfClientID: String) async throws -> UpdateEventEnvelope {
        var components = URLComponents(string: "\(pathPrefix)\(basePath)/last")
        components?.queryItems = [URLQueryItem(name: "client", value: selfClientID)]

        guard let path = components?.string else {
            assertionFailure("generated an invalid path")
            throw UpdateEventsAPIError.invalidPath
        }

        let request = HTTPRequest(
            path: path,
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        // Change: 400 error removed.
        return try ResponseParser()
            .success(code: 200, type: UpdateEventEnvelope.self)
            .failure(code: 404, label: "not-found", error: UpdateEventsAPIError.notFound)
            .parse(response)
    }

}
