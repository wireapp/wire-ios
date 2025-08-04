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

import WireDataModel
import WireLogging
import WireNetwork

struct ConversationMLSResetEventProcessor: ConversationMLSResetEventProcessorProtocol {

    enum Failure: Error {
        case conversationNotFound
        case failedToGetMLSGroupIDs
    }

    private let mlsService: any MLSServiceInterface
    private let conversationLocalStore: any ConversationLocalStoreProtocol
<<<<<<< HEAD
    private let featureRepository: any LegacyFeatureRepositoryInterface
=======
    private let featureConfigRepository: any FeatureConfigRepositoryProtocol
    private let lockRepository: ResetMLSConversationLockRepositoryProtocol
>>>>>>> d97f6b2466 (feat: Reset MLS conversation Additional logic - WPB-18664 (#3420))

    init(
        mlsService: any MLSServiceInterface,
        conversationLocalStore: any ConversationLocalStoreProtocol,
<<<<<<< HEAD
        featureRepository: any LegacyFeatureRepositoryInterface
=======
        featureConfigRepository: any FeatureConfigRepositoryProtocol,
        lockRepository: ResetMLSConversationLockRepositoryProtocol
>>>>>>> d97f6b2466 (feat: Reset MLS conversation Additional logic - WPB-18664 (#3420))
    ) {
        self.mlsService = mlsService
        self.conversationLocalStore = conversationLocalStore
        self.featureConfigRepository = featureConfigRepository
        self.lockRepository = lockRepository
    }

    func processEvent(_ event: ConversationMLSResetEvent) async throws {
<<<<<<< HEAD

        let feature = await featureRepository.fetchAllowGlobalOperations()
        guard feature.status == .enabled, feature.config.mlsConversationReset == true else {
            WireLogger.mls.debug(
                "No need to process reset broken MLS conversation, FF is OFF"
            )
            return
        }

        WireLogger.mls.info("MLS event processor is processing reset broken MLS conversation")

        let oldMLSGroupIDBase64 = event.oldMLSGroupIDBase64
        let newMLSGroupIDBase64 = event.newMLSGroupIDBase64
        guard
            let oldMLSGroupID = MLSGroupID(base64Encoded: oldMLSGroupIDBase64),
            let newMLSGroupID = MLSGroupID(base64Encoded: newMLSGroupIDBase64)
        else {
            WireLogger.mls.error("Failed to get old and new group IDs to reset MLS conversation")
            throw Failure.invalidArguments
        }

        guard let localConversation = await conversationLocalStore
            .fetchConversation(id: event.conversationID.id, domain: event.conversationID.domain) else {
            WireLogger.mls.error("Failed to get local conversation to reset MLS conversation")
            throw Failure.conversationNotFound
        }

=======
>>>>>>> d97f6b2466 (feat: Reset MLS conversation Additional logic - WPB-18664 (#3420))
        do {
            let attributes: LogAttributes = [.conversationId: event.conversationID.id.safeForLoggingDescription]

            let feature = try await featureConfigRepository.fetchAllowedGlobalOperations()
            guard feature.status == .enabled, feature.config?.mlsConversationReset == true else {
                WireLogger.mls.debug(
                    "No need to process reset broken MLS conversation, FF is OFF",
                    attributes: attributes
                )
                return
            }
            guard !lockRepository
                .wasResetInitiated(conversationID: event.conversationID.toDomainModel()) else {
                WireLogger.mls.info(
                    "Reset was initiated from this device thus no need to process it",
                    attributes: attributes
                )
                lockRepository.removeResetInitiated(conversationID: event.conversationID.toDomainModel())
                return
            }

            WireLogger.mls.info(
                "MLS event processor is processing reset broken MLS conversation",
                attributes: attributes
            )

            let oldMLSGroupIDBase64 = event.oldMLSGroupIDBase64
            let newMLSGroupIDBase64 = event.newMLSGroupIDBase64
            guard
                let oldMLSGroupID = MLSGroupID(base64Encoded: oldMLSGroupIDBase64),
                let newMLSGroupID = MLSGroupID(base64Encoded: newMLSGroupIDBase64)
            else {
                throw Failure.failedToGetMLSGroupIDs
            }

            guard let localConversation = await conversationLocalStore
                .fetchConversation(id: event.conversationID.id, domain: event.conversationID.domain) else {
                WireLogger.mls.error(
                    "Failed to get local conversation to reset MLS conversation",
                    attributes: attributes
                )
                throw Failure.conversationNotFound
            }

            try await mlsService.wipeGroup(oldMLSGroupID)

            await conversationLocalStore.storeMLSConversationPendingJoin(
                newMLSGroupID: newMLSGroupID,
                conversation: localConversation
            )

            WireLogger.mls.info(
                "MLS event processor is finished processing reset broken MLS conversation",
                attributes: attributes
            )

        } catch {
            throw error
        }
    }
}
