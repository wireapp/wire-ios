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

/// Received data from websocket when consumable notifications sync system enabled
struct WebSocketNotification: Decodable {

    enum NotificationType: String, Decodable {
        case event
        case notificationsMissed = "notifications_missed"
        case synchronization
    }

    enum DataType: Decodable {
        case event(EventNotificationData)
        case synchronization(SynchronisationData)
    }

    struct EventNotificationData: Decodable {
        enum CodingKeys: String, CodingKey {
            case deliveryTag = "delivery_tag"
            case event
        }

        var deliveryTag: UInt64
        var event: UpdateEventEnvelopeV8
    }

    struct SynchronisationData: Decodable {
        enum CodingKeys: String, CodingKey {
            case deliveryTag = "delivery_tag"
            case markerId = "marker_id"
        }

        var deliveryTag: UInt64
        var markerId: String
    }

    var type: NotificationType
    var data: DataType?

    init(type: NotificationType, data: DataType? = nil) {
        self.type = type
        self.data = data
    }

    init(eventData: EventNotificationData) {
        self.type = .event
        self.data = .event(eventData)
    }

    enum CodingKeys: CodingKey {
        case type
        case data
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(WebSocketNotification.NotificationType.self, forKey: .type)

        switch type {
        case .event:
            let data = try container.decode(WebSocketNotification.EventNotificationData.self, forKey: .data)
            self.data = .event(data)
        case .notificationsMissed:
            self.data = nil
        case .synchronization:
            let data = try container.decode(WebSocketNotification.SynchronisationData.self, forKey: .data)
            self.data = .synchronization(data)
        }
    }

    var updateEventEnveloppe: UpdateEventEnvelope? {
        switch data {
        case let .event(eventData):
            UpdateEventEnvelope(
                id: eventData.event.id,
                events: eventData.event.payload.map(\.updateEvent),
                isTransient: false,
                deliveryTag: eventData.deliveryTag
            )
        case .synchronization:
            nil
        case .none:
            nil
        }
    }

    var synchronizationData: SynchronisationData? {
        switch data {
        case let .synchronization(data):
            data
        case .event:
            nil
        case .none:
            nil
        }
    }
}

// MARK: - For Testing

extension WebSocketNotification {

    public static var notificationMissed: WebSocketNotification {
        WebSocketNotification(type: .notificationsMissed)
    }

    public init(event: UpdateEventEnvelopeV8, deliveryTag: UInt64) {
        self.type = .event
        self.data = .event(.init(deliveryTag: deliveryTag, event: event))
    }
}
