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

public import Foundation

public extension WireLogAttribute {

    // TODO: declare only attributes which are needed amongst multiple targets, otherwise create an internal extensions

    // static func `public`(_ value: String) -> WireLogAttribute { .init("public", value) }
    // static func accountID(_ value: String) -> WireLogAttribute { .init("account_id", value) }
    // static func ackMultipleEventsCount(_ value: String) -> WireLogAttribute { .init("ack_events_count", value) }
    // static func conversationID(_ value: String) -> WireLogAttribute { .init("conversation_id", value) }
    // static func coreCryptoContext(_ value: String) -> WireLogAttribute { .init("core_crypto_context", value) }
    // static func duration(_ value: String) -> WireLogAttribute { .init("duration", value) }
    // static func eventEnvelopeID(_ value: String) -> WireLogAttribute { .init("event_envelope_id", value) }
    // static func eventID(_ value: String) -> WireLogAttribute { .init("event_id", value) }
    // static func eventSource(_ value: String) -> WireLogAttribute { .init("event_source", value) }
    // static func lastEventID(_ value: String) -> WireLogAttribute { .init("last_event_id", value) }
    // static func messageType(_ value: String) -> WireLogAttribute { .init("message_type", value) }
    // static func mlsGroupID(_ value: String) -> WireLogAttribute { .init("mls_group_id", value) }
    // static func multipleEvents(_ value: String) -> WireLogAttribute { .init("ack_multiple_events", value) }
    // static func nonce(_ value: String) -> WireLogAttribute { .init("message_nonce", value) }
    // static func nse(_ value: String) -> WireLogAttribute { .init("NSE", value) }
    static var processID: WireLogAttribute { .init("process_id", "\(ProcessInfo.processInfo.processIdentifier)") }
    static var processName: WireLogAttribute { .init("process_name", ProcessInfo.processInfo.processName) }
    // static func pushChannelVersion(_ value: String) -> WireLogAttribute { .init("push_channel", value) }
    // static func recipientID(_ value: String) -> WireLogAttribute { .init("recipient_id", value) }
    // static func selfClientID(_ value: String) -> WireLogAttribute { .init("self_client_id", value) }
    static func selfUserID(_ value: UUID) -> WireLogAttribute { .init("self_user_id", value.uuidString) }
    // static func senderUserID(_ value: String) -> WireLogAttribute { .init("sender_user_id", value) }
    // static func syncPhase(_ value: String) -> WireLogAttribute { .init("sync_phase", value) }
    // static func syncType(_ value: String) -> WireLogAttribute { .init("sync_type", value) }
    // static func syncVersion(_ value: String) -> WireLogAttribute { .init("sync_version", value) }
    // static func tag(_ value: String) -> WireLogAttribute { .init("tag", value) }
    // static func workItemID(_ value: String) -> WireLogAttribute { .init("work_item_id", value) }

}
