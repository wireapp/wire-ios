//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireTransport

@available(iOS 15, *)
final class NotificationsAPIClient: Loggable {

    // MARK: - Properties

    private let networkSession: NetworkSession

    // MARK: - Life cycle

    init(networkSession: NetworkSession) {
        self.networkSession = networkSession
    }

    // MARK: - Methods

    func fetchEvent(eventID: UUID) async throws -> ZMUpdateEvent {
        logger.trace("fetching event with eventID (\(eventID))")
        switch try await networkSession.execute(endpoint: API.fetchNotification(eventID: eventID)) {
        case .success(let event):
            return event

        case .failure(let error):
            throw error
        }
    }

}

struct NotificationByIDEndpoint: Endpoint, Loggable {

    // MARK: - Types

    typealias Output = ZMUpdateEvent

    enum Failure: Error {

        case invalidResponse
        case failedToDecodePayload
        case notifcationNotFound
        case unknownError(ErrorResponse)

    }

    // MARK: - Properties

    let eventID: UUID

    // MARK: - Request

    var request: NetworkRequest {
        NetworkRequest(
            path: "/notifications/\(eventID.uuidString.lowercased())",
            httpMethod: .get,
            contentType: .json,
            acceptType: .json
        )
    }

    // MARK: - Response

    // Expected response payload:
    // { "id": UUID, "payload": <Some update event> }

    func parseResponse(_ response: NetworkResponse) -> Swift.Result<Output, Failure> {
        logger.trace("parsing response: \(response)")
        switch response {
        case .success(let response) where response.status == 200:
            // TODO: check the content type of the response matches what is expected
            // TODO: get the id, make sure it matches the `eventID`.
            logger.trace("decoding response payload")
            guard let payload = try? JSONSerialization.jsonObject(with: response.data, options: []) as? [AnyHashable: Any] else {
                return .failure(.failedToDecodePayload)
            }

            logger.info("received event response payload: \(payload)")

            guard let events = ZMUpdateEvent.eventsArray(
                from: payload as ZMTransportData,
                source: .pushNotification
            ) else {
                return .failure(.failedToDecodePayload)
            }

            logger.info("received events: \(events)")

            guard let event = events.first else {
                return .failure(.notifcationNotFound)
            }

            return .success(event)

        case .failure(let response):
            switch (response.code, response.label) {
            case (404, "not-found"):
                return .failure(.notifcationNotFound)

            default:
                return .failure(.unknownError(response))
            }

        default:
            return .failure(.invalidResponse)
        }
    }

}
