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

import WireDataModel
import WireLogging
import WireNetwork

// sourcery: AutoMockable
/// Repairs conversations with faulty removal keys
public protocol RepairRemovalKeysUseCaseProtocol {
    func invoke() async throws
}

public struct RepairRemovalKeysUseCase: RepairRemovalKeysUseCaseProtocol {

    let faultyMLSRemovalKeysByDomain: [String: [String]]

    private let context: NSManagedObjectContext
    private let mlsService: MLSServiceInterface
    private let conversationsAPI: ConversationsAPI
    private let conversationLocalStore: ConversationLocalStoreProtocol
    private let initiateResetUseCase: InitiateResetMLSConversationUseCaseProtocol

    init(
        faultyMLSRemovalKeysByDomain: [String: [String]],
        context: NSManagedObjectContext,
        mlsService: MLSServiceInterface,
        conversationsAPI: ConversationsAPI,
        conversationLocalStore: ConversationLocalStoreProtocol,
        initiateResetUseCase: InitiateResetMLSConversationUseCaseProtocol
    ) {
        self.faultyMLSRemovalKeysByDomain = faultyMLSRemovalKeysByDomain
        self.context = context
        self.mlsService = mlsService
        self.conversationsAPI = conversationsAPI
        self.conversationLocalStore = conversationLocalStore
        self.initiateResetUseCase = initiateResetUseCase
    }

    public func invoke() async throws {
        WireLogger.mls.info(
            "initiating repair of faulty removal keys",
            attributes: .safePublic
        )

        guard !faultyMLSRemovalKeysByDomain.isEmpty else {
            WireLogger.mls.info(
                "no faulty removal keys to repair, aborting",
                attributes: .safePublic
            )
            return
        }

        // Process each domain
        for (domain, faultyKeyHexStrings) in faultyMLSRemovalKeysByDomain {
            try await processDomain(
                domain: domain,
                faultyKeyHexStrings: faultyKeyHexStrings
            )
        }
    }

    // MARK: - Private

    private func processDomain(
        domain: String,
        faultyKeyHexStrings: [String]
    ) async throws {
        WireLogger.mls.info(
            "checking domain for \(faultyKeyHexStrings.count) faulty key(s)",
            attributes: .safePublic
        )

        // Convert hex strings to Data
        let faultyKeyDataList = faultyKeyHexStrings.compactMap(Data.init(hexString:))
        guard faultyKeyDataList.count == faultyKeyHexStrings.count else {
            WireLogger.mls.error(
                "failed to decode some faulty removal key hex strings",
                attributes: .safePublic
            )
            return
        }

        let allMLSConversations = try await conversationLocalStore.fetchAllMLSConversations(
            domain: domain
        )

        // Find faulty conversations for this domain
        let faultyConversations = await findFaultyConversations(
            in: allMLSConversations,
            faultyKeys: faultyKeyDataList
        )

        WireLogger.mls.info(
            "detected \(faultyConversations.count)/\(allMLSConversations.count) affected conversations",
            attributes: .safePublic
        )

        // Repair each faulty conversation in parallel
        await withTaskGroup(of: Void.self) { group in
            for (groupID, qualifiedID) in faultyConversations {
                group.addTask {
                    await repairConversation(
                        groupID: groupID,
                        qualifiedID: qualifiedID
                    )
                }
            }
        }
    }

    private func findFaultyConversations(
        in conversations: [ZMConversation],
        faultyKeys: [Data]
    ) async -> [(MLSGroupID, WireDataModel.QualifiedID)] {
        var faultyConversations: [(MLSGroupID, WireDataModel.QualifiedID)] = []

        for conversation in conversations {
            let (groupID, qualifiedID) = await context.perform {
                (conversation.mlsGroupID, conversation.qualifiedID)
            }

            guard let groupID, let qualifiedID else {
                continue
            }

            let currentRemovalKey: Data
            do {
                currentRemovalKey = try await mlsService.externalSenderKey(groupID: groupID)
            } catch {
                WireLogger.mls.error(
                    "failed to get current removal key for a group, skipping: \(String(describing: error))",
                    attributes: .safePublic
                )
                continue
            }

            // Check if the current removal key matches any of the faulty keys
            if faultyKeys.contains(currentRemovalKey) {
                faultyConversations.append((
                    groupID,
                    qualifiedID
                ))
            }
        }

        return faultyConversations
    }

    private func repairConversation(
        groupID: MLSGroupID,
        qualifiedID: WireDataModel.QualifiedID
    ) async {
        let remoteConversation: WireNetwork.Conversation?
        do {
            remoteConversation = try await conversationsAPI.getConversations(
                for: [qualifiedID.toAPIModel()]
            ).found.first
        } catch {
            WireLogger.mls.error(
                "failed to get epoch for a group, skipping: \(String(describing: error))",
                attributes: .safePublic, [.conversationId: qualifiedID.safeForLoggingDescription]
            )
            return
        }

        guard let remoteConversation else {
            WireLogger.mls.error(
                "remote conversation for a group not found, skipping",
                attributes: .safePublic, [.conversationId: qualifiedID.safeForLoggingDescription]
            )
            return
        }

        WireLogger.mls.info(
            "initiating reset for faulty conversation: \(qualifiedID)",
            attributes: .safePublic, [.conversationId: qualifiedID.safeForLoggingDescription]
        )

        let epoch = UInt64(remoteConversation.epoch ?? 0)
        await initiateResetUseCase.invoke(groupID: groupID, epoch: epoch)
    }

}
