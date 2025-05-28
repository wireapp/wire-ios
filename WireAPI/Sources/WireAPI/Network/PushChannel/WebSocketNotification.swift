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

/// Received data from websocket when async stream enabled
struct WebSocketNotification: Decodable {

    enum NotificationType: String, Decodable {
        case event
        case notificationsMissed = "notifications.missed"
    }

    struct NotificationData: Decodable {
        enum CodingKeys: String, CodingKey {
            case deliveryTag = "delivery_tag"
            case event
        }

        var deliveryTag: UInt64
        var event: UpdateEventEnvelopeV8
    }

    var type: NotificationType
    var data: NotificationData?

    init(type: NotificationType, data: NotificationData? = nil) {
        self.type = type
        self.data = data
    }
}

extension WebSocketNotification: ToAPIModelConvertible {

    func toAPIModel() -> UpdateEventEnvelope {
        guard let event = data?.event  else {
            assertionFailure("don't call toAPIModel() when type is `notificationsMissed`")
            return UpdateEventEnvelope(
                id: UUID(),
                events: [],
                isTransient: false
            )
        }
        return UpdateEventEnvelope(
            id: event.id,
            events: event.payload.map(\.updateEvent),
            isTransient: false,
            deliveryTag: data?.deliveryTag
        )
    }
}

// MARK: - For Testing

extension WebSocketNotification {

    public static var notificationMissed: WebSocketNotification {
        WebSocketNotification(type: .notificationsMissed)
    }

    public init(event: UpdateEventEnvelopeV8, deliveryTag: UInt64) {
        self.type = .event
        self.data = .init(deliveryTag: deliveryTag, event: event)
    }
}
