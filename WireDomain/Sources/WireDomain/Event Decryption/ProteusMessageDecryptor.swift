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

// MARK: - ProteusMessageDecryptorProtocol

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

// MARK: - ProteusMessageDecryptor

struct ProteusMessageDecryptor: ProteusMessageDecryptorProtocol {
    let proteusService: any ProteusServiceInterface
    let managedObjectContext: NSManagedObjectContext

    private let maxCiphertextSize = Int(12000 * 1.5)

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
        guard case let .ciphertext(ciphertext) = eventData.message else {
            return eventData
        }

        let ciphertextData = try validateCiphertext(ciphertext)

        if case let .ciphertext(externalCiphertext) = eventData.externalData {
            try validateExternalCiphertext(externalCiphertext)
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

    private func validateCiphertext(_ ciphertext: String) throws -> Data {
        guard ciphertext != ZMFailedToCreateEncryptedMessagePayloadString else {
            throw ProteusMessageDecryptorError.senderFailedToEncrypt
        }

        guard
            ciphertext.count <= maxCiphertextSize,
            let ciphertextData = Data(base64Encoded: ciphertext)
        else {
            throw ProteusError.decodeError
        }

        return ciphertextData
    }

    private func validateExternalCiphertext(_ ciphertext: String) throws {
        // External messages aren't encrypted via Proteus, instead they are symmetrically
        // encrypted with a key that is E2EE via Proteus. Decryption of external messages
        // happens during event processing, here we just want to validate it.
        guard ciphertext.count <= maxCiphertextSize else {
            throw ProteusError.decodeError
        }
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
