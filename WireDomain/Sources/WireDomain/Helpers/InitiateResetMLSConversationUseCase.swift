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
import WireDataModel
import WireLogging
import WireNetwork

// sourcery: AutoMockable
public protocol InitiateResetMLSConversationUseCaseProtocol {
    func invoke(groupID: WireDataModel.MLSGroupID, epoch: UInt64) async
}

public class InitiateResetMLSConversationUseCase: InitiateResetMLSConversationUseCaseProtocol {

    enum Failure: Error {
        case noRefreshedConversationFound
    }

    private let api: MLSAPI
    private let mlsService: MLSServiceInterface
    private let conversationLocalStore: ConversationLocalStoreProtocol
    private let conversationRepository: ConversationRepositoryProtocol
    private let lockRepository: ResetMLSConversationLockRepositoryProtocol

    public init(
        api: MLSAPI,
        mlsService: MLSServiceInterface,
        conversationLocalStore: ConversationLocalStoreProtocol,
        conversationRepository: ConversationRepositoryProtocol,
        lockRepository: ResetMLSConversationLockRepositoryProtocol
    ) {
        self.api = api
        self.mlsService = mlsService
        self.conversationLocalStore = conversationLocalStore
        self.conversationRepository = conversationRepository
        self.lockRepository = lockRepository
    }

    public func invoke(groupID: WireDataModel.MLSGroupID, epoch: UInt64) async {

        var attributes: LogAttributes = [:]

        do {

            guard let conversation = await conversationLocalStore.fetchMLSConversation(groupID: groupID),
                  let qualifiedID = await conversationLocalStore.qualifiedID(for: conversation)
            else {
                WireLogger.mls.error("Initiate reset broken MLS conversation failed: no conversation found")
                return
            }

            attributes = [.conversationId: qualifiedID.safeForLoggingDescription]

            lockRepository.setInitiatedReset(conversationID: qualifiedID)

            WireLogger.mls.info(
                "Initiate reset broken MLS conversation use case started",
                attributes: attributes
            )

            // send request to BE to reset broken conversation
            try await api.resetMLSConversation(epoch: epoch, groupID: groupID.data.base64String())

            // wipe group
            try await mlsService.wipeGroup(groupID)

            // sync local database with remote because new group ID has to be generated for a conversation
            try await conversationRepository
                .pullConversation(
                    id: qualifiedID.uuid,
                    domain: qualifiedID.domain
                )

            // get that update conversation from local db
            guard let refreshedConversation = await conversationLocalStore.fetchConversation(
                id: qualifiedID.uuid,
                domain: qualifiedID.domain
            ), let newGroupID = await conversationLocalStore.mlsConversationInfo(
                conversation: refreshedConversation
            )?.0 else {
                throw Failure.noRefreshedConversationFound
            }

            try await mlsService.establishPendingGroup(groupID: newGroupID)

            WireLogger.mls.info(
                "Initiate reset broken MLS conversation use case finished",
                attributes: attributes
            )

        } catch {
            WireLogger.mls.error(
                "Initiate reset broken MLS conversation use case failed: \(error.localizedDescription)",
                attributes: attributes
            )
        }
    }
}

extension InitiateResetMLSConversationUseCase: ResetBrokenMLSConversationDelegate {

    public func didCatchBrokenMLSConversation(groupID: MLSGroupID, epoch: UInt64) async {
        await invoke(groupID: groupID, epoch: epoch)
    }

}
