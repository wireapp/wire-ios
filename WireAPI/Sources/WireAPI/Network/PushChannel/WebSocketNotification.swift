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
        case notificationsMissed = "notifications_missed"
        case messagesCount = "message_count"
    }
    
    enum DataType: Decodable {
        case event(EventNotificationData)
        case messageCount(MessageCountData)
    }
    
    struct MessageCountData: Decodable {
        var count: Int
    }
    
    struct EventNotificationData: Decodable {
        enum CodingKeys: String, CodingKey {
            case deliveryTag = "delivery_tag"
            case event
        }
        
        var deliveryTag: UInt64
        var event: UpdateEventEnvelopeV8
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
    
    init(messageCount: Int) {
        self.type = .messagesCount
        self.data = .messageCount(.init(count: messageCount))
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
        case .messagesCount:
            let data = try container.decode(WebSocketNotification.MessageCountData.self, forKey: .data)
            self.data = .messageCount(data)
        }
    }
}

extension WebSocketNotification: ToAPIModelConvertible {

    var messageCount: Int {
        switch data {
        case .messageCount(let data):
            return data.count
        case .event, .none:
            return 0
        }
    }
    
    func toAPIModel() -> UpdateEventEnvelope {
        switch data {
        case .event(let eventData):
            return UpdateEventEnvelope(
                id: eventData.event.id,
                events: eventData.event.payload.map(\.updateEvent),
                isTransient: false,
                deliveryTag: eventData.deliveryTag
            )
        case .messageCount(let data):
            fatalError()
        case .none:
            fatalError()
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
