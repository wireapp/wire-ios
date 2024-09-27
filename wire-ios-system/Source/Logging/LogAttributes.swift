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

public typealias LogAttributes = [LogAttributesKey: Encodable]

// MARK: - LogAttributesKey

public enum LogAttributesKey: String, Comparable {
    case selfClientId = "self_client_id"
    case selfUserId = "self_user_id"
    case recipientID = "recipient_id"
    case eventId = "event_id"
    case eventEnvelopeID = "event_envelope_id"
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

    public static func < (lhs: LogAttributesKey, rhs: LogAttributesKey) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension LogAttributes {
    public static var safePublic = [LogAttributesKey.public: true]
}
