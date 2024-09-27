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

extension ZMUpdateEvent {
    // MARK: MLS Message Events

    /// Creates a new instance of `ZMUpdateEvent` replacing the encrypted event data with the decrypted data passed as
    /// parameter
    /// - Parameter decryptedData: data representing the decrypted value of the update event data. Must have been
    /// decrypted with core crypto
    /// - Returns: a version of `self` with a payload containing the decrypted data
    func decryptedMLSEvent(decryptedData: Data, senderClientID: String?) -> ZMUpdateEvent? {
        assert(type == .conversationMLSMessageAdd, "decrypting wrong type of event")

        guard var payload = payload as? [String: Any] else {
            return nil
        }

        var data = [plaintextPayloadKey: decryptedData.base64EncodedString()]

        if let senderClientID {
            data["sender"] = senderClientID
        }

        payload["data"] = data
        return decryptedEvent(payload: payload)
    }

    // MARK: - Proteus Message Events

    /// Returns a decrypted version of self, injecting the decrypted data
    /// in its payload and wrapping the payload in a new updateEvent
    func decryptedEvent(decryptedData: Data) -> ZMUpdateEvent? {
        guard
            var payload = payload as? [String: Any],
            var eventData = payload["data"] as? [String: Any]
        else {
            return nil
        }

        if type == .conversationOtrMessageAdd, let wrappedData = eventData["data"] as? String {
            payload["external"] = wrappedData
        }

        eventData[plaintextPayloadKey] = decryptedData.base64String()
        payload["data"] = eventData

        return decryptedEvent(payload: payload)
    }

    /// Payload dictionary key that holds the plaintext (protobuf) data
    private var plaintextPayloadKey: String {
        switch type {
        case .conversationMLSMessageAdd, .conversationOtrMessageAdd:
            "text"
        case .conversationOtrAssetAdd:
            "info"
        default:
            fatal("Decrypting wrong type of event")
        }
    }

    // MARK: - Helpers

    private func decryptedEvent(payload: [String: Any]) -> ZMUpdateEvent? {
        let decryptedEvent = ZMUpdateEvent.decryptedUpdateEvent(
            fromEventStreamPayload: payload as NSDictionary,
            uuid: uuid,
            transient: false,
            source: source
        )

        if !debugInformation.isEmpty {
            decryptedEvent?.appendDebugInformation(debugInformation)
        }

        return decryptedEvent
    }
}
