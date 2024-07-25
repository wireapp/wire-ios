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
import WireCryptobox

private let zmLog = ZMSLog(tag: "EventDecoder")

typealias ProteusDecryptionFunction = (ProteusSessionID, Data) async throws -> (didCreateNewSession: Bool, decryptedData: Data)?

extension EventDecoder {

    /// Decrypts an event (if needed) and return a decrypted copy (or the original if no
    /// decryption was needed) and information about the decryption result.
    func decryptProteusEventAndAddClient(
        _ event: ZMUpdateEvent,
        in context: NSManagedObjectContext,
        using decryptFunction: ProteusDecryptionFunction
    ) async -> ZMUpdateEvent? {
        WireLogger.updateEvent.info("decrypting proteus event...", attributes: event.logAttributes)

        guard !event.wasDecrypted else {
            WireLogger.updateEvent.info("returned already decrypted event", attributes: event.logAttributes)
            return event
        }

        guard event.type.isOne(of: .conversationOtrMessageAdd, .conversationOtrAssetAdd) else {
            fatal("Can't decrypt event of type \(event.type) as it's not supposed to be encrypted")
        }

        var selfUser: ZMUser?
        var selfClient: UserClient?

        let (senderClient, senderClientSessionId) = await context.perform {
            // Is it for the current client?
            selfUser = ZMUser.selfUser(in: context)
            selfClient = selfUser?.selfClient()

            guard
                let recipientID = event.recipientID,
                selfClient?.remoteIdentifier == recipientID
            else {
                let additionalInfo: LogAttributes = [
                    .recipientID: event.recipientID?.redactedAndTruncated() ?? "<nil>",
                    .selfClientId: selfClient?.safeRemoteIdentifier.safeForLoggingDescription ?? "<nil>",
                    .selfUserId: selfUser?.remoteIdentifier.safeForLoggingDescription ?? "<nil>"
                ]
                WireLogger.updateEvent.error("decrypting proteus event... failed: is not for self client, dropping...)", attributes: event.logAttributes, additionalInfo, .safePublic)
                return (UserClient?.none, ProteusSessionID?.none)
            }

            let client = self.createClientIfNeeded(from: event, in: context)
            return (client, client?.proteusSessionID)
        }

        guard let senderClient, let senderClientSessionId else {
            WireLogger.updateEvent.error("decrypting proteus event... failed: couldn't fetch sender client, dropping...", attributes: event.logAttributes)
            return nil
        }

        func fail(error: ProteusError? = nil) {
            context.performAndWait {
                if senderClient.isInserted {
                    selfClient?.addNewClientToIgnored(senderClient)
                }
                appendFailedToDecryptMessage(after: error, for: event, sender: senderClient, in: context)
            }
        }

        // Decrypt event.
        let createdNewSession: Bool
        let decryptedEvent: ZMUpdateEvent

        do {
            guard let result = try await decryptedUpdateEvent(
                for: event,
                senderSessionId: senderClientSessionId,
                using: decryptFunction
            ) else {
                fail()
                WireLogger.updateEvent.error("decrypting proteus event... failed: could not decrypt, dropping...", attributes: event.logAttributes)
                return nil
            }

            (createdNewSession, decryptedEvent) = result

        } catch let error as CBoxResult {
            let proteusError = ProteusError(cboxResult: error)
            fail(error: proteusError)
            WireLogger.updateEvent.error("decrypting proteus event... failed with proteus error: \(proteusError?.localizedDescription ?? "?")", attributes: event.logAttributes)
            return nil

        } catch let error as ProteusService.DecryptionError {
            let proteusError = error.proteusError
            fail(error: proteusError)
            WireLogger.updateEvent.error("decrypting proteus event... failed with proteus error: \(proteusError.localizedDescription)", attributes: event.logAttributes)
            return nil

        } catch {
            fail(error: nil)
            WireLogger.updateEvent.error("decrypting proteus event... failed with unkown error: \(error.localizedDescription)", attributes: event.logAttributes)
            return nil
        }

        // New client discovered?
        if createdNewSession {
            await context.perform {
                let senderClientSet: Set<UserClient> = [senderClient]
                selfClient?.decrementNumberOfRemainingProteusKeys()
                selfClient?.addNewClientToIgnored(senderClient)
                selfClient?.updateSecurityLevelAfterDiscovering(senderClientSet)
            }
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
        after error: ProteusError?,
        for event: ZMUpdateEvent,
        sender: UserClient,
        in context: NSManagedObjectContext
    ) {
        WireLogger.updateEvent.error("Failed to decrypt message with error: \(String(describing: error))",
                                     attributes: [.senderUserId: sender.safeRemoteIdentifier.value],
                                     event.logAttributes)
        WireLogger.updateEvent.debug("event debug: \(event.debugInformation)")

        if error == .outdatedMessage || error == .duplicateMessage {
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
            if let senderUser = sender.user {
                conversation?.appendDecryptionFailedSystemMessage(
                    at: event.timestamp,
                    sender: senderUser,
                    client: sender,
                    errorCode: Int(error?.rawValue ?? 0)
                )
            }
        }

        let userInfo: [String: Any] = [
            "cause": error?.rawValue as Any,
            "deviceClass": sender.deviceClass ?? ""
        ]

        NotificationInContext(
            name: ZMConversation.failedToDecryptMessageNotificationName,
            context: context.notificationContext,
            object: conversation,
            userInfo: userInfo
        ).post()
    }

    // Returns the decrypted version of an update event. This is generated by decrypting
    // the encrypted version and creating a new event with the decrypted data in the expected
    // payload keys
    private func decryptedUpdateEvent(
        for event: ZMUpdateEvent,
        senderSessionId: ProteusSessionID,
        using decryptFunction: ProteusDecryptionFunction
    ) async throws -> (didCreateNewSession: Bool, event: ZMUpdateEvent)? {
        guard
            let result = try await self.decryptedData(
                event,
                sessionID: senderSessionId,
                using: decryptFunction
            ),
            let decryptedEvent = event.decryptedEvent(decryptedData: result.decryptedData)
        else {
            return nil
        }
        return (result.didCreateNewSession, event: decryptedEvent)
    }

    private func decryptedData(
        _ event: ZMUpdateEvent,
        sessionID: ProteusSessionID,
        using decryptFunction: ProteusDecryptionFunction
    ) async throws -> (didCreateNewSession: Bool, decryptedData: Data)? {
        guard
            let encryptedData = try event.encryptedMessageData()
        else {
            return nil
        }

        // Check if it's the "bomb" message (gave encrypting on the sender).
        guard encryptedData != ZMFailedToCreateEncryptedMessagePayloadString.data(using: .utf8) else {
            zmLog.safePublic("Received 'failed to encrypt for your client' special payload (bomb) from \(sessionID). Current device might have invalid prekeys on the BE.")
            return nil
        }

        return try await decryptFunction(sessionID, encryptedData)
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
