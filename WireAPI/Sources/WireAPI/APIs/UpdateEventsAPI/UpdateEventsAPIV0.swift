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

class UpdateEventsAPIV0: UpdateEventsAPI {

    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    var path: String {
        "/notifications"
    }

    // MARK: - Get last update event

    func getLastUpdateEvent(selfClientID: String) async throws -> UpdateEventEnvelope {
        var components = URLComponents(string: "\(path)/last")
        components?.queryItems = [URLQueryItem(name: "client", value: selfClientID)]

        guard let path = components?.string else {
            throw UpdateEventsAPIError.invalidPath
        }

        let request = HTTPRequest(
            path: path,
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        // TODO: remove
        if let data = response.payload, let string = String(data: data, encoding: .utf8) {
            print("Got response: \(string)")
        }

        return try ResponseParser()
            .success(code: 200, type: UpdateEventEnvelopeV0.self)
            .failure(code: 400, error: UpdateEventsAPIError.invalidClient)
            .failure(code: 400, label: "not-found", error: UpdateEventsAPIError.notFound)
            .parse(response)
    }

}

private struct UpdateEventEnvelopeV0: Decodable, ToAPIModelConvertible {

    var id: UUID
    var payload: [UpdateEvent]?
    var transient: Bool?

    func toAPIModel() -> UpdateEventEnvelope {
        UpdateEventEnvelope(
            id: id,
            payloads: payload ?? [],
            isTransient: transient ?? false
        )
    }

}
