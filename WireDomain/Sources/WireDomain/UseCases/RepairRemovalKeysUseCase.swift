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

// sourcery: AutoMockable
/// Repairs conversations with faulty removal keys
public protocol RepairRemovalKeysUseCaseProtocol {
    func invoke() async throws
}

public struct RepairRemovalKeysUseCase: RepairRemovalKeysUseCaseProtocol {

    // TODO: Fill in
    static let faultyRemovalKey = Data(base64Encoded: "BM036midcNiOMgny9m7N5uS3n6hB3JBJRNGUPqT0zNMQzLzOypHL09PSMITiMLJoVF3OZKQtwZf8/mkxrVtt8nU=")!
    static let affectedDomain = "bella.wire.link"

    private let context: NSManagedObjectContext
    private let mlsService: MLSServiceInterface
    private let conversationsAPI: ConversationsAPI
    private let conversationLocalStore: ConversationLocalStoreProtocol
    private let initiateResetUseCase: InitiateResetMLSConversationUseCase

    init(
        context: NSManagedObjectContext,
        mlsService: MLSServiceInterface,
        conversationsAPI: ConversationsAPI,
        conversationLocalStore: ConversationLocalStoreProtocol,
        initiateResetUseCase: InitiateResetMLSConversationUseCase
    ) {
        self.context = context
        self.mlsService = mlsService
        self.conversationsAPI = conversationsAPI
        self.conversationLocalStore = conversationLocalStore
        self.initiateResetUseCase = initiateResetUseCase
    }

    public func invoke() async throws {
        WireLogger.mls.debug(
            "initiating repair of faulty removal keys",
            attributes: .safePublic
        )

        let allMLSConversations = try await conversationLocalStore.fetchAllMLSConversations(
            domain: Self.affectedDomain
        )

        var faultyConversations: [(MLSGroupID, WireNetwork.QualifiedID)] = []

        for conversation in allMLSConversations {
            let (groupID, qualifiedID) = await context.perform {
                (conversation.mlsGroupID, conversation.qualifiedID)
            }

            guard let groupID, let qualifiedID else {
                continue
            }

            let currentRemovalKey = try await mlsService.externalSenderKey(groupID: groupID)

            // The current removal key is faulty.
            if currentRemovalKey == Self.faultyRemovalKey {
                faultyConversations.append((
                    groupID,
                    qualifiedID.toAPIModel()
                ))
            }
        }

        WireLogger.mls.info(
            "detected \(faultyConversations.count)/\(allMLSConversations.count) affected conversations",
            attributes: .safePublic
        )

        for (groupID, qualifiedID) in faultyConversations {
            guard let remoteConversation = try? await conversationsAPI
                .getConversations(
                    for: [qualifiedID]
                ).found.first else {
                return
            }

            WireLogger.mls.debug(
                "initiating reset for faulty conversation: \(qualifiedID)",
                attributes: .safePublic
            )
            let epoch = UInt64(remoteConversation.epoch ?? 0)
            await initiateResetUseCase.invoke(groupID: groupID, epoch: epoch)
        }
    }

}
