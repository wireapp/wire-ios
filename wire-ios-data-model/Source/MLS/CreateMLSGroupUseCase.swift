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

import WireCoreCrypto

struct CreateMLSGroupUseCase {
    // MARK: Lifecycle

    init(
        parentGroupID: MLSGroupID?,
        defaultCipherSuite: Feature.MLS.Config.MLSCipherSuite,
        coreCrypto: any SafeCoreCryptoProtocol,
        staleKeyMaterialDetector: any StaleMLSKeyDetectorProtocol,
        actionsProvider: any MLSActionsProviderProtocol,
        notificationContext: NotificationContext
    ) {
        self.parentGroupID = parentGroupID
        self.defaultCipherSuite = defaultCipherSuite

        self.coreCrypto = coreCrypto
        self.staleKeyMaterialDetector = staleKeyMaterialDetector
        self.actionsProvider = actionsProvider
        self.notificationContext = notificationContext
    }

    // MARK: Internal

    func invoke(groupID: MLSGroupID) async throws -> MLSCipherSuite {
        logger.info("creating group for id: \(groupID.safeForLoggingDescription)")

        guard let ciphersuite = MLSCipherSuite(rawValue: defaultCipherSuite.rawValue) else {
            throw MLSService.MLSGroupCreationError.invalidCiphersuite
        }

        do {
            let externalSenders: [Data]
            if let parentGroupID {
                // Anyone in the parent conversation can create a subconversation,
                // even people from different domains. We need to make sure that
                // the external senders is the same as the parent, otherwise we
                // won't be able to decrypt external remove proposals from the
                // owning domain.
                externalSenders = try await coreCrypto.perform {
                    try await [$0.getExternalSender(conversationId: parentGroupID.data)]
                }
            } else if let backendPublicKeys = await fetchBackendPublicKeys() {
                externalSenders = backendPublicKeys.externalSenderKey(for: ciphersuite)
            } else {
                throw MLSService.MLSGroupCreationError.failedToGetExternalSenders
            }

            let config = ConversationConfiguration(
                ciphersuite: UInt16(ciphersuite.rawValue),
                externalSenders: externalSenders,
                custom: .init(keyRotationSpan: nil, wirePolicy: nil)
            )

            try await coreCrypto.perform {
                let e2eiIsEnabled = try await $0.e2eiIsEnabled(ciphersuite: UInt16(ciphersuite.rawValue))
                try await $0.createConversation(
                    conversationId: groupID.data,
                    creatorCredentialType: e2eiIsEnabled ? .x509 : .basic,
                    config: config
                )
            }
        } catch {
            logger.warn("failed to create group (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
            throw MLSService.MLSGroupCreationError.failedToCreateGroup
        }

        staleKeyMaterialDetector.keyingMaterialUpdated(for: groupID)

        return ciphersuite
    }

    // MARK: Private

    private let logger = WireLogger.mls

    private let parentGroupID: MLSGroupID?
    private let defaultCipherSuite: Feature.MLS.Config.MLSCipherSuite
    private let coreCrypto: any SafeCoreCryptoProtocol
    private let staleKeyMaterialDetector: any StaleMLSKeyDetectorProtocol
    private let actionsProvider: any MLSActionsProviderProtocol
    private let notificationContext: NotificationContext

    private func fetchBackendPublicKeys() async -> BackendMLSPublicKeys? {
        logger.info("fetching backend public keys")

        do {
            return try await actionsProvider.fetchBackendPublicKeys(in: notificationContext)
        } catch {
            logger.warn("failed to fetch backend public keys: \(String(describing: error))")
            return nil
        }
    }
}
