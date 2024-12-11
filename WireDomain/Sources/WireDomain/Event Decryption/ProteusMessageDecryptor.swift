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
    let userClientsRepository: any UserClientsRepositoryProtocol
    let userRepository: any UserRepositoryProtocol

    typealias Context = (
        selfClient: WireDataModel.UserClient,
        senderUser: WireDataModel.ZMUser,
        senderClient: WireDataModel.UserClient,
        proteusSessionID: ProteusSessionID
    )

    init(
        proteusService: any ProteusServiceInterface,
        userClientsRepository: any UserClientsRepositoryProtocol,
        userRepository: any UserRepositoryProtocol
    ) {
        self.proteusService = proteusService
        self.userClientsRepository = userClientsRepository
        self.userRepository = userRepository
    }

    func decryptedEventData(
        from eventData: ConversationProteusMessageAddEvent
    ) async throws -> ConversationProteusMessageAddEvent {
        // Only decrypt ciphertext, return plaintext unchanged.

        let ciphertext = eventData.message.encryptedMessage
        let ciphertextData = try validateCiphertext(ciphertext)

        if let externalCiphertext = eventData.externalData?.encryptedMessage {
            try validateExternalCiphertext(externalCiphertext)
        }

        let context = try await extractContext(from: eventData)

        let (didCreateSession, plaintextData) = try await proteusService.decrypt(
            data: ciphertextData,
            forSession: context.proteusSessionID
        )

        if didCreateSession {
            await userClientsRepository.clientSessionCreated(
                selfClient: context.selfClient,
                newClient: context.senderClient
            )
        }

        var decryptedEvent = eventData
        decryptedEvent.message.decryptedMessage = plaintextData.base64String()

        return decryptedEvent
    }

    private func validateCiphertext(_ ciphertext: String) throws -> Data {
        guard ciphertext != ZMFailedToCreateEncryptedMessagePayloadString else {
            throw ProteusMessageDecryptorError.senderFailedToEncrypt
        }

        guard let ciphertextData = Data(base64Encoded: ciphertext) else {
            throw ProteusMessageDecryptorError.invalidCiphertext
        }

        return ciphertextData
    }

    private func extractContext(
        from eventData: ConversationProteusMessageAddEvent
    ) async throws -> Context {
        guard let selfClient = await userClientsRepository.fetchSelfClient() else {
            throw ProteusMessageDecryptorError.selfClientNotFound
        }

        let senderUser = await userRepository.fetchOrCreateUser(
            id: eventData.senderID.uuid,
            domain: eventData.senderID.domain
        )

        guard let senderClient = await userClientsRepository.fetchClient(
            id: eventData.messageSenderClientID,
            forUser: senderUser,
            createIfNeeded: true
        ) else {
            throw ProteusMessageDecryptorError.selfClientNotFound
        }

        await userClientsRepository.storeClient(
            discoveryDate: eventData.timestamp,
            client: senderClient
        )

        await userClientsRepository.addNewClientToIgnored(
            selfClient: selfClient,
            newClient: senderClient
        )

        guard let proteusSessionID = await userClientsRepository.proteusSessionID(
            for: senderClient
        ) else {
            throw ProteusMessageDecryptorError.proteusSessionIDNotFound
        }

        return (selfClient, senderUser, senderClient, proteusSessionID)
    }

}
