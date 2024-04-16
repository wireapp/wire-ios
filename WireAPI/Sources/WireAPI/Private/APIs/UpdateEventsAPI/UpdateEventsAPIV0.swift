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

    var path = "/notifications"
    var decoder = ResponsePayloadDecoder()

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func getLastUpdateEvent(selfClientID: String) async throws -> UpdateEvent {
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

        if let data = response.payload, let string = String(data: data, encoding: .utf8) {
            print("Got response: \(string)")
        }

        switch try decoder.decodePayload(
            from: response,
            as: UpdateEventV0.self
        ) {
        case .success(let payload):
            return payload.toParent()

        case .failure(let error):
            if error.code == 400 {
                throw UpdateEventsAPIError.invalidClient
            }

            if error.code == 400 && error.label == "not-found" {
                throw UpdateEventsAPIError.notFound
            }

            throw error
        }

    }

}

private struct UpdateEventV0: Decodable {

    var id: UUID
    var payload: [UpdateEventPayload]?
    var transient: Bool?

    func toParent() -> UpdateEvent {
        UpdateEvent(
            id: id,
            payloads: payload ?? [],
            isTransient: transient ?? false
        )
    }

}
