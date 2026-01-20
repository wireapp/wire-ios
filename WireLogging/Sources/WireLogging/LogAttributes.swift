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

public typealias LogAttributes = [LogAttributesKey: any Encodable]

public enum LogAttributesKey: String, Comparable, Sendable {

    case selfClientId = "self_client_id"
    case selfUserId = "self_user_id"
    case recipientID = "recipient_id"
    case eventId = "event_id"
    case eventType = "event_type"
    case eventEnvelopeID = "event_envelope_id"
    case ackMultipleEventsCount = "ack_events_count"
    case multipleEvents = "ack_multiple_events"
    case senderUserId = "sender_user_id"
    case nonce = "message_nonce"
    case messageType = "message_type"
    case lastEventID = "last_event_id"
    case conversationId = "conversation_id"
    case syncPhase = "sync_phase"
    case eventSource = "event_source"
    case `public`
    case tag
    case processId = "process_id"
    case processName = "process_name"
    case coreCryptoContext = "core_crypto_context"
    case nse = "NSE"
    case accountID = "account_id"
    case mlsGroupID = "mls_group_id"
    case pushChannelVersion = "push_channel"
    case duration
    case syncType = "sync_type"
    case syncVersion = "sync_version"
    case workItemID = "work_item_id"

    public static func < (lhs: LogAttributesKey, rhs: LogAttributesKey) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public extension LogAttributes {
    static let safePublic = [LogAttributesKey.public: true]
    /// PushChannelV2 (consumable notications sync)
    static let pushChannelV2 = [LogAttributesKey.pushChannelVersion: "v2"]
    /// PushChannel V1 (regular sync)
    static let pushChannelV1 = [LogAttributesKey.pushChannelVersion: "v1"]
    /// legacy pushChannel (Starscream)
    static let pushChannelV0 = [LogAttributesKey.pushChannelVersion: "v0"]
}
