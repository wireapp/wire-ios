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

import Foundation
import WireDataModel
import WireLogging
import WireNetwork

public protocol InitiateResetMLSConversationUseCaseProtocol {
    func invoke(groupID: WireDataModel.MLSGroupID, epoch: Int64) async
}

public struct InitiateResetMLSConversationUseCase: InitiateResetMLSConversationUseCaseProtocol {

    private let api: MLSAPI
    private let mlsService: MLSServiceInterface
    private let conversationLocalStore: ConversationLocalStore

    enum Failure {
        case noConversation
    }

    public init(
        api: MLSAPI,
        mlsService: MLSServiceInterface,
        conversationLocalStore: ConversationLocalStore
    ) {
        self.api = api
        self.mlsService = mlsService
        self.conversationLocalStore = conversationLocalStore
    }

    public func invoke(groupID: WireDataModel.MLSGroupID, epoch: Int64) async {
        do {
            guard let conversation = await conversationLocalStore.fetchMLSConversation(
                groupID: groupID
            ) else {
                WireLogger.mls.error("Initiate reset broken MLS conversation failed: no conversation found")
                return
            }

            // send request to BE to reset broken conversation
            try await api
                .resetMLSConversation(
                    epoch: epoch,
                    groupID: groupID.data.base64String()
                )

            // re-create group and re-add all participants
            let users = conversation.localParticipants.map(MLSUser.init)
            _ = try await mlsService.establishGroup(for: groupID, with: users, removalKeys: nil)
        } catch {
            WireLogger.mls.error("Initiate reset broken MLS conversation failed: \(error.localizedDescription)")
        }
    }
}

public extension InitiateResetMLSConversationUseCase {
    static func make(
        apiService: APIServiceProtocol,
        apiVersion: WireNetwork.APIVersion,
        mlsService: MLSServiceInterface,
        context: NSManagedObjectContext
    ) -> Self {
        InitiateResetMLSConversationUseCase(
            api: MLSAPIBuilder(apiService: apiService)
                .makeAPI(for: apiVersion),
            mlsService: mlsService,
            conversationLocalStore: ConversationLocalStore(
                context: context,
                mlsService: mlsService,
                messageLocalStore: MessageLocalStore(context: context)
            )
        )
    }
}
