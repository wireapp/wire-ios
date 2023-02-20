//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireCryptobox

private let zmLog = ZMSLog(tag: "EventDecoder")

extension EventDecoder {

    // MARK: - Decryption

    /// Decrypts an event (if needed) and return a decrypted copy (or the original if no
    /// decryption was needed) and information about the decryption result.

    func decryptProteusEventAndAddClient(
        _ event: ZMUpdateEvent,
        in context: NSManagedObjectContext,
        sessionsDirectory: EncryptionSessionsDirectory
    ) -> ZMUpdateEvent? {
        guard !event.wasDecrypted else {
            return event
        }

        guard event.type.isOne(of: .conversationOtrMessageAdd, .conversationOtrAssetAdd) else {
            fatal("Can't decrypt event of type \(event.type) as it's not supposed to be encrypted")
        }

        // Is it for the current client?
        let selfUser = ZMUser.selfUser(in: context)

        guard
            let recipientID = event.recipientID,
            selfUser.selfClient()?.remoteIdentifier == recipientID
        else {
            return nil
        }

        guard let senderClient = createClientIfNeeded(
            from: event,
            in: context
        ) else {
            return nil
        }

        func fail(error: CBoxResult? = nil) {
            if senderClient.isInserted {
                selfUser.selfClient()?.addNewClientToIgnored(senderClient)
            }

            appendFailedToDecryptMessage(after: error, for: event, sender: senderClient, in: context)
        }

        // Decrypt event.
        let createdNewSession: Bool
        let decryptedEvent: ZMUpdateEvent

        do {
            guard let result = try decryptedUpdateEvent(
                for: event,
                sender: senderClient,
                sessionsDirectory: sessionsDirectory
            ) else {
                fail()
                return nil
            }

            (createdNewSession, decryptedEvent) = result

        } catch let error as CBoxResult {
            fail(error: error)
            return nil

        } catch {
            fatalError("Unknown error in decrypting payload, \(error)")
        }

        // New client discovered?
        if createdNewSession {
            let senderClientSet: Set<UserClient> = [senderClient]
            selfUser.selfClient()?.decrementNumberOfRemainingKeys()
            selfUser.selfClient()?.addNewClientToIgnored(senderClient)
            selfUser.selfClient()?.updateSecurityLevelAfterDiscovering(senderClientSet)
        }

        return decryptedEvent
    }

    // Create user and client if needed. The client will not be trusted.

    private func createClientIfNeeded(
        from updateEvent: ZMUpdateEvent,
        in context: NSManagedObjectContext
    ) -> UserClient? {
        guard
            let senderID = updateEvent.senderUUID,
            let senderClientID = updateEvent.senderClientID
        else {
            return nil
        }

        let user = ZMUser.fetchOrCreate(
            with: senderID,
            domain: updateEvent.senderDomain,
            in: context
        )

        let client = UserClient.fetchUserClient(
            withRemoteId: senderClientID,
            forUser: user,
            createIfNeeded: true
        )!

        client.discoveryDate = updateEvent.timestamp

        return client
    }

    // Appends a system message for a failed decryption
    private func appendFailedToDecryptMessage(
        after error: CBoxResult?,
        for event: ZMUpdateEvent,
        sender: UserClient,
        in context: NSManagedObjectContext
    ) {
        zmLog.safePublic("Failed to decrypt message with error: \(error), client id <\(sender.safeRemoteIdentifier))>")
        zmLog.error("event debug: \(event.debugInformation)")

        if error == CBOX_OUTDATED_MESSAGE || error == CBOX_DUPLICATE_MESSAGE {
            // Do not notify the user if the error is just "duplicated".
            return
        }

        var conversation: ZMConversation?
        if let conversationID = event.conversationUUID {
            conversation = ZMConversation.fetch(
                with: conversationID,
                domain: event.conversationDomain,
                in: context
            )

            conversation?.appendDecryptionFailedSystemMessage(
                at: event.timestamp,
                sender: sender.user!,
                client: sender,
                errorCode: Int(error?.rawValue ?? 0)
            )
        }

        let userInfo: [String: Any] = [
            "cause": error?.rawValue as Any,
            "deviceClass": sender.deviceClass ?? ""
        ]

        NotificationInContext(
            name: ZMConversation.failedToDecryptMessageNotificationName,
            context: sender.managedObjectContext!.notificationContext,
            object: conversation,
            userInfo: userInfo
        ).post()
    }

    // Returns the decrypted version of an update event. This is generated by decrypting
    // the encrypted version and creating a new event with the decrypted data in the expected
    // payload keys

    private func decryptedUpdateEvent(
        for event: ZMUpdateEvent,
        sender: UserClient,
        sessionsDirectory: EncryptionSessionsDirectory
    ) throws -> (createdNewSession: Bool, event: ZMUpdateEvent)? {
        guard
            let result = try self.decryptedData(
                event,
                client: sender,
                sessionsDirectory: sessionsDirectory
            ),
            let decryptedEvent = event.decryptedEvent(decryptedData: result.decryptedData)
        else {
            return nil
        }
        return (createdNewSession: result.createdNewSession, event: decryptedEvent)
    }

    private func decryptedData(
        _ event: ZMUpdateEvent,
        client: UserClient,
        sessionsDirectory: EncryptionSessionsDirectory
    ) throws -> (createdNewSession: Bool, decryptedData: Data)? {
        guard
            let encryptedData = try event.encryptedMessageData(),
            let sessionID = client.sessionIdentifier
        else {
            return nil
        }

        // Check if it's the "bomb" message (gave encrypting on the sender).
        guard encryptedData != ZMFailedToCreateEncryptedMessagePayloadString.data(using: .utf8) else {
            zmLog.safePublic("Received 'failed to encrypt for your client' special payload (bomb) from \(sessionID). Current device might have invalid prekeys on the BE.")
            return nil
        }

        return try sessionsDirectory.decryptData(encryptedData, for: sessionID)
    }

}

private extension ZMUpdateEvent {

    var recipientID: String? {
        return self.eventData?["recipient"] as? String
    }

    var eventData: [String: Any]? {
        guard let eventData = (self.payload as? [String: Any])?["data"] as? [String: Any] else {
            return nil
        }

        return eventData
    }

    func encryptedMessageData() throws -> Data? {
        guard
            let key = payloadKey,
            let string = eventData?[key] as? String,
            let data = Data(base64Encoded: string)
        else {
            return nil
        }

        // We need to check the size of the encrypted data payload for regular OTR and external messages.
        let maxReceivingSize = Int(12_000 * 1.5)

        guard
            string.count <= maxReceivingSize,
            externalStringCount <= maxReceivingSize
        else {
            throw CBOX_DECODE_ERROR
        }

        return data
    }

    var payloadKey: String? {
        switch type {
        case .conversationOtrMessageAdd:
            return "text"

        case .conversationOtrAssetAdd:
            return "key"

        default:
            return nil
        }
    }

    var externalStringCount: Int {
        return (eventData?["data"] as? String)?.count ?? 0
    }

}
