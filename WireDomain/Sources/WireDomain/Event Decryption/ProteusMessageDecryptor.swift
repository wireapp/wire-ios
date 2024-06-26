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
import WireAPI
import WireDataModel

// sourcery: AutoMockable
/// Decrypt proteus messages.
protocol ProteusMessageDecryptorProtocol {

    /// Decrypt a proteus message.
    ///
    /// - Parameter eventData: A payload containing the encrypted message.
    /// - Returns: The payload containing the decrypted message.

    func decryptedEventData(
        from eventData: ConversationProteusMessageAddEvent
    ) async throws -> ConversationProteusMessageAddEvent

}

struct ProteusMessageDecryptor: ProteusMessageDecryptorProtocol {

    let proteusService: any ProteusServiceInterface
    let managedObjectContext: NSManagedObjectContext

    private let maxCiphertextSize = Int(12_000 * 1.5)

    typealias Context = (
        selfClient: WireDataModel.UserClient,
        senderUser: WireDataModel.ZMUser,
        senderClient: WireDataModel.UserClient,
        proteusSessionID: ProteusSessionID
    )

    init(
        proteusService: any ProteusServiceInterface,
        managedObjectContext: NSManagedObjectContext
    ) {
        self.proteusService = proteusService
        self.managedObjectContext = managedObjectContext
    }

    func decryptedEventData(
        from eventData: ConversationProteusMessageAddEvent
    ) async throws -> ConversationProteusMessageAddEvent {
        // Only decrypt ciphertext, return plaintext unchanged.
        guard case .ciphertext(let ciphertext) = eventData.message else {
            return eventData
        }

        // Validate ciphertext.
        guard ciphertext != ZMFailedToCreateEncryptedMessagePayloadString else {
            throw ProteusMessageDecryptorError.senderFailedToEncrypt
        }

        // TODO: What about external data?
        guard
            ciphertext.count <= maxCiphertextSize,
            let ciphertextData = Data(base64Encoded: ciphertext)
        else {
            throw ProteusError.decodeError
        }

        let context = try await extractContext(from: eventData)

        let (didCreateSession, plaintextData) = try await proteusService.decrypt(
            data: ciphertextData,
            forSession: context.proteusSessionID
        )

        if didCreateSession {
            await managedObjectContext.perform {
                context.selfClient.decrementNumberOfRemainingProteusKeys()
                context.selfClient.updateSecurityLevelAfterDiscovering([context.senderClient])
            }
        }

        var decryptedEvent = eventData
        decryptedEvent.message = .plaintext(plaintextData.base64String())
        return decryptedEvent
    }

    private func extractContext(
        from eventData: ConversationProteusMessageAddEvent
    ) async throws -> Context {
        try await managedObjectContext.perform { [managedObjectContext] in
            guard let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient() else {
                throw ProteusMessageDecryptorError.selfClientNotFound
            }

            let senderUser = ZMUser.fetchOrCreate(
                with: eventData.senderID.uuid,
                domain: eventData.senderID.domain,
                in: managedObjectContext
            )

            guard let senderClient = UserClient.fetchUserClient(
                withRemoteId: eventData.messageSenderClientID,
                forUser: senderUser,
                createIfNeeded: true
            ) else {
                throw ProteusMessageDecryptorError.selfClientNotFound
            }

            if senderClient.isInserted {
                senderClient.discoveryDate = eventData.timestamp
                selfClient.addNewClientToIgnored(senderClient)
            }

            guard let proteusSessionID = senderClient.proteusSessionID else {
                throw ProteusMessageDecryptorError.proteusSessionIDNotFound
            }

            return (selfClient, senderUser, senderClient, proteusSessionID)
        }
    }

}
