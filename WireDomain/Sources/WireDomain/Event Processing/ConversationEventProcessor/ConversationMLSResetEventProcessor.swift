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
        case invalidArguments
        case failedToWipeMLSConversation
    }

    private let mlsService: any MLSServiceInterface
    private let conversationLocalStore: any ConversationLocalStoreProtocol
    private let featureRepository: any FeatureRepositoryInterface

    init(
        mlsService: any MLSServiceInterface,
        conversationLocalStore: any ConversationLocalStoreProtocol,
        featureRepository: any FeatureRepositoryInterface
    ) {
        self.mlsService = mlsService
        self.conversationLocalStore = conversationLocalStore
        self.featureRepository = featureRepository
    }

    func processEvent(_ event: ConversationMLSResetEvent) async throws {

        let feature = await featureRepository.fetchResetMLSConversations()
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

        do {
            try await mlsService.wipeGroup(oldMLSGroupID)
        } catch {
            WireLogger.mls.error("Failed to wipe group in order to reset MLS conversation")
            throw Failure.failedToWipeMLSConversation
        }

        await conversationLocalStore.storeMLSConversationPendingJoin(
            newMLSGroupID: newMLSGroupID,
            conversation: localConversation
        )

        WireLogger.mls.info("MLS event processor is finished processing reset broken MLS conversation")
    }

}
