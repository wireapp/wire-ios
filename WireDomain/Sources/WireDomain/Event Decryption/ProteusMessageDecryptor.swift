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

import Foundation
import WireCoreCrypto
import WireDataModel
import WireNetwork

struct ProteusMessageDecryptor: ProteusMessageDecryptorProtocol {

    let proteusService: any ProteusServiceInterface
    let userClientsLocalStore: any UserClientsLocalStoreProtocol
    let userLocalStore: any UserLocalStoreProtocol

    typealias Context = (
        selfClient: WireDataModel.UserClient,
        senderUser: WireDataModel.ZMUser,
        senderClient: WireDataModel.UserClient,
        proteusSessionID: ProteusSessionID
    )

    private let maxCiphertextSize = Int(12_000 * 1.5)

    init(
        proteusService: any ProteusServiceInterface,
        userClientsLocalStore: any UserClientsLocalStoreProtocol,
        userLocalStore: any UserLocalStoreProtocol
    ) {
        self.proteusService = proteusService
        self.userClientsLocalStore = userClientsLocalStore
        self.userLocalStore = userLocalStore
    }

    func decryptedEventData(
        from eventData: ConversationProteusMessageAddEvent,
        context: CoreCryptoContextProtocol?
    ) async throws -> ConversationProteusMessageAddEvent {
        // Only decrypt ciphertext, return plaintext unchanged.

        let ciphertext = eventData.message.encryptedMessage
        let ciphertextData = try validateCiphertext(ciphertext)
        let eventContext = try await extractContext(from: eventData)

        let (didCreateSession, plaintextData) = try await proteusService.decrypt(
            data: ciphertextData,
            forSession: eventContext.proteusSessionID,
            context: context
        )

        if didCreateSession {
            await userClientsLocalStore.clientSessionCreated(
                selfClient: eventContext.selfClient,
                newClient: eventContext.senderClient
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
        guard let selfClient = await userClientsLocalStore.fetchSelfClient() else {
            throw ProteusMessageDecryptorError.selfClientNotFound
        }

        let senderUser = await userLocalStore.fetchOrCreateUser(
            id: eventData.senderID.id,
            domain: eventData.senderID.domain
        )

        guard let senderClient = await userClientsLocalStore.fetchClient(
            id: eventData.messageSenderClientID,
            forUser: senderUser,
            createIfNeeded: true
        ) else {
            throw ProteusMessageDecryptorError.selfClientNotFound
        }

        await userClientsLocalStore.storeClient(
            discoveryDate: eventData.timestamp,
            client: senderClient
        )

        await userClientsLocalStore.addNewClientToIgnored(
            selfClient: selfClient,
            newClient: senderClient
        )

        guard let proteusSessionID = await userClientsLocalStore.proteusSessionID(
            for: senderClient
        ) else {
            throw ProteusMessageDecryptorError.proteusSessionIDNotFound
        }

        return (selfClient, senderUser, senderClient, proteusSessionID)
    }

}
