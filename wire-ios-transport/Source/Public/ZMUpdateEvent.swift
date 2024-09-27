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
import WireUtilities

// MARK: - ZMUpdateEventsPolicy

@objc
public enum ZMUpdateEventsPolicy: Int {
    case buffer /// store live events in a buffer, to be processed later
    case ignore /// process events received through /notifications or /conversation/.../events
    case process /// process events received through the push channel
}

// MARK: - ZMUpdateEventSource

@objc
public enum ZMUpdateEventSource: Int {
    case webSocket
    case pushNotification
    case download
}

// MARK: - ZMUpdateEventType

@objc
public enum ZMUpdateEventType: UInt, CaseIterable, Equatable {
    case unknown = 0
    case conversationAssetAdd = 1
    case conversationConnectRequest = 2
    case conversationCreate = 3
    case conversationDelete = 39
    case conversationKnock = 4
    case conversationMemberJoin = 5
    case conversationMemberLeave = 6
    case conversationMemberUpdate = 7
    case conversationMessageAdd = 8
    case conversationClientMessageAdd = 9
    case conversationOtrMessageAdd = 10
    case conversationOtrAssetAdd = 11
    case conversationRename = 12
    case conversationProtocolUpdate = 45
    case conversationTyping = 13
    case conversationCodeUpdate = 14
    case conversationAccessModeUpdate = 15
    case conversationMessageTimerUpdate = 31
    case conversationReceiptModeUpdate = 34
    case conversationMLSWelcome = 41
    case conversationMLSMessageAdd = 42
    case userConnection = 16
    case userNew = 17
    case userUpdate = 18
    case userDelete = 35
    case userPushRemove = 19
    case userLegalHoldEnable = 38
    case userLegalHoldDisable = 37
    case userLegalHoldRequest = 36
    case userContactJoin = 20
    case userClientAdd = 21
    case userClientRemove = 22
    case userPropertiesSet = 32
    case userPropertiesDelete = 33
    case teamCreate = 23
    case teamDelete = 24
    // removed: teamUpdate = 25 [WPB-4552]: The event is no longer sent, clients must fetch team metadata (e.g. name, icon) every 24h
    // removed: teamMemberJoin = 26 [WPB-4538]: no need to handle "team.member-join" in clients
    case teamMemberLeave = 27 // [WPB-4538]: "team.member-leave" is only required for backwards compatibility
    case teamConversationCreate = 28
    case teamConversationDelete = 29
    case teamMemberUpdate = 30
    case featureConfigUpdate = 40
    case federationDelete = 43
    case federationConnectionRemoved = 44

    // Current max value: conversationProtocolUpdate = 45
}

extension ZMUpdateEventType {
    var stringValue: String? {
        switch self {
        case .unknown:
            nil
        case .conversationAssetAdd:
            "conversation.asset-add"
        case .conversationConnectRequest:
            "conversation.connect-request"
        case .conversationCreate:
            "conversation.create"
        case .conversationDelete:
            "conversation.delete"
        case .conversationKnock:
            "conversation.knock"
        case .conversationMemberJoin:
            "conversation.member-join"
        case .conversationMemberLeave:
            "conversation.member-leave"
        case .conversationMemberUpdate:
            "conversation.member-update"
        case .conversationMessageAdd:
            "conversation.message-add"
        case .conversationClientMessageAdd:
            "conversation.client-message-add"
        case .conversationOtrMessageAdd:
            "conversation.otr-message-add"
        case .conversationOtrAssetAdd:
            "conversation.otr-asset-add"
        case .conversationRename:
            "conversation.rename"
        case .conversationProtocolUpdate:
            "conversation.protocol-update"
        case .conversationTyping:
            "conversation.typing"
        case .conversationCodeUpdate:
            "conversation.code-update"
        case .conversationAccessModeUpdate:
            "conversation.access-update"
        case .conversationReceiptModeUpdate:
            "conversation.receipt-mode-update"
        case .conversationMLSWelcome:
            "conversation.mls-welcome"
        case .conversationMLSMessageAdd:
            "conversation.mls-message-add"
        case .userConnection:
            "user.connection"
        case .userNew:
            "user.new"
        case .userUpdate:
            "user.update"
        case .userDelete:
            "user.delete"
        case .userPushRemove:
            "user.push-remove"
        case .userContactJoin:
            "user.contact-join"
        case .userLegalHoldEnable:
            "user.legalhold-enable"
        case .userLegalHoldDisable:
            "user.legalhold-disable"
        case .userLegalHoldRequest:
            "user.legalhold-request"
        case .userClientAdd:
            "user.client-add"
        case .userClientRemove:
            "user.client-remove"
        case .teamCreate:
            "team.create"
        case .teamDelete:
            "team.delete"
        case .teamMemberLeave:
            "team.member-leave"
        case .teamConversationCreate:
            "team.conversation-create"
        case .teamConversationDelete:
            "team.conversation-delete"
        case .teamMemberUpdate:
            "team.member-update"
        case .conversationMessageTimerUpdate:
            "conversation.message-timer-update"
        case .userPropertiesSet:
            "user.properties-set"
        case .userPropertiesDelete:
            "user.properties-delete"
        case .featureConfigUpdate:
            "feature-config.update"
        case .federationDelete:
            "federation.delete"
        case .federationConnectionRemoved:
            "federation.connectionRemoved"
        }
    }

    init(string: String) {
        let result = ZMUpdateEventType.allCases.lazy
            .compactMap { eventType -> (ZMUpdateEventType, String)? in
                guard let stringValue = eventType.stringValue else { return nil }
                return (eventType, stringValue)
            }
            .filter { _, stringValue -> Bool in
                stringValue == string
            }
            .map { eventType, _ -> ZMUpdateEventType in
                eventType
            }
            .first

        self = result ?? .unknown
    }
}

extension ZMUpdateEvent {
    @objc(updateEventTypeForEventTypeString:)
    public static func updateEventType(for string: String)
        -> ZMUpdateEventType {
        ZMUpdateEventType(string: string)
    }

    @objc(eventTypeStringForUpdateEventType:)
    public static func eventTypeString(for eventType: ZMUpdateEventType)
        -> String? {
        eventType.stringValue
    }
}

private let zmLog = ZMSLog(tag: "UpdateEvents")

// MARK: - ZMUpdateEvent

@objcMembers
open class ZMUpdateEvent: NSObject {
    // MARK: Lifecycle

    public init?(
        uuid: UUID?,
        payload: [AnyHashable: Any]?,
        transient: Bool,
        decrypted: Bool,
        source: ZMUpdateEventSource
    ) {
        guard let payload else { return nil }
        guard let payloadType = payload["type"] as? String else { return nil }

        self.uuid = uuid
        self.payload = payload
        self.isTransient = transient
        self.wasDecrypted = decrypted

        let eventType = ZMUpdateEventType(string: payloadType)
        guard eventType != .unknown else { return nil }
        self.type = eventType
        self.source = source
        self.wasDecrypted = false
    }

    /// Creates an update event
    public convenience init?(fromEventStreamPayload payload: ZMTransportData, uuid: UUID?) {
        let dictionary = payload.asDictionary()
        // Some payloads are wrapped inside "event" key (e.g. removing bot from conversation)
        // Check for this before
        let innerPayload = (dictionary?["event"] as? [AnyHashable: Any]) ?? dictionary

        self.init(uuid: uuid, payload: innerPayload, transient: false, decrypted: false, source: .download)
    }

    // MARK: Open

    open var payload: [AnyHashable: Any]
    open var type: ZMUpdateEventType
    open var source: ZMUpdateEventSource
    open var uuid: UUID?

    /// True if the event will not appear in the notification stream
    open var isTransient: Bool
    /// True if the event had encrypted payload but now it has decrypted payload
    open var wasDecrypted: Bool

    /// True if the event is encoded with ZMGenericMessage
    open var isGenericMessageEvent: Bool {
        switch type {
        case .conversationOtrMessageAdd, .conversationOtrAssetAdd, .conversationClientMessageAdd,
             .conversationMLSMessageAdd:
            true
        default:
            false
        }
    }

    /// Debug information
    open var debugInformation: String {
        debugInformationArray.joined(separator: "\n")
    }

    open class func eventsArray(fromPushChannelData transportData: ZMTransportData) -> [ZMUpdateEvent]? {
        eventsArray(from: transportData, source: .webSocket)
    }

    /// Returns an array of @c ZMUpdateEvent from the given push channel data, the source will be set to @c
    /// ZMUpdateEventSourceWebSocket, if a non-nil @c NSUUID is given for the @c pushStartingAt parameter, all
    /// events earlier or equal to this uuid will have a source of @c ZMUpdateEventSourcePushNotification
    open class func eventsArray(
        fromPushChannelData transportData: ZMTransportData,
        pushStartingAt threshold: UUID?
    ) -> [Any]? {
        eventsArray(from: transportData, source: .webSocket, pushStartingAt: threshold)
    }

    /// Creates an update event that was encrypted and it's now decrypted
    open class func decryptedUpdateEvent(
        fromEventStreamPayload payload: ZMTransportData,
        uuid: UUID?,
        transient: Bool,
        source: ZMUpdateEventSource
    ) -> ZMUpdateEvent? {
        ZMUpdateEvent(
            uuid: uuid,
            payload: payload.asDictionary(),
            transient: transient,
            decrypted: true,
            source: source
        )
    }

    @objc(eventsArrayFromTransportData:source:)
    open class func eventsArray(from transportData: ZMTransportData, source: ZMUpdateEventSource) -> [ZMUpdateEvent]? {
        eventsArray(from: transportData, source: source, pushStartingAt: nil)
    }

    open class func eventsArray(
        from transportData: ZMTransportData,
        source: ZMUpdateEventSource,
        pushStartingAt threshold: UUID?
    ) -> [ZMUpdateEvent]? {
        let dictionary = transportData.asDictionary()
        guard let uuidString = dictionary?["id"] as? String, let uuid = UUID(uuidString: uuidString) else { return nil }
        guard let payloadArray = dictionary?["payload"] as? [Any] else { return nil }
        let transient = (dictionary?["transient"] as? Bool) ?? false

        return eventsArray(
            with: uuid,
            payloadArray: payloadArray,
            transient: transient,
            source: source,
            pushStartingAt: threshold
        )
    }

    /// Adds debug information
    open func appendDebugInformation(_ debugInformation: String) {
        debugInformationArray.append(debugInformation)
    }

    // MARK: Public

    // A hash of the event content. This is used to keep track of events
    // that we have already processed.
    public var contentHash: Int64?

    @objc(eventFromEventStreamPayload:uuid:)
    public static func eventFromEventStreamPayload(_ payload: ZMTransportData, uuid: UUID?) -> ZMUpdateEvent? {
        ZMUpdateEvent(fromEventStreamPayload: payload, uuid: uuid)
    }

    // MARK: Internal

    var debugInformationArray: [String] = []

    class func eventsArray(
        with uuid: UUID,
        payloadArray: [Any]?,
        transient: Bool,
        source: ZMUpdateEventSource,
        pushStartingAt sourceThreshold: UUID?
    ) -> [ZMUpdateEvent] {
        guard let payloads = payloadArray as? [[AnyHashable: AnyHashable]] else {
            WireLogger.updateEvent.error(
                "Push event payload is invalid",
                attributes: [.eventId: uuid.transportString().redactedAndTruncated()],
                .safePublic
            )
            return []
        }

        let events = payloads.compactMap { payload -> ZMUpdateEvent? in
            var actualSource = source
            if let thresholdUUID = sourceThreshold, thresholdUUID.isType1UUID, uuid.isType1UUID,
               (thresholdUUID as NSUUID).compare(withType1UUID: uuid as NSUUID) != .orderedDescending {
                actualSource = .pushNotification
            }
            return ZMUpdateEvent(
                uuid: uuid,
                payload: payload,
                transient: transient,
                decrypted: false,
                source: actualSource
            )
        }
        return events
    }
}

extension ZMUpdateEvent {
    override open var description: String {
        let uuidDescription = uuid?.transportString() ?? "<no uuid>"
        return "<\(Swift.type(of: self))> \(uuidDescription) \(payload) \n \(debugInformation)"
    }
}

extension ZMUpdateEvent {
    override open func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ZMUpdateEvent else {
            return false
        }

        return (uuid == other.uuid)
            && (type == other.type)
            && (payload as NSDictionary).isEqual(to: other.payload)
    }
}
