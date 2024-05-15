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

// sourcery: AutoMockable
public protocol MLSGroupVerificationProtocol {

    func updateAllConversations() async

}

public final class MLSGroupVerification: MLSGroupVerificationProtocol {

    // MARK: - Properties

    public let updateUseCase: any UpdateMLSGroupVerificationStatusUseCaseProtocol

    private let mlsService: MLSServiceInterface
    private let syncContext: NSManagedObjectContext

    private var observingTask: Task<Void, Never>?

    // MARK: - Initialize

    public init(
        e2eiVerificationStatusService: any E2EIVerificationStatusServiceInterface,
        featureRepository: any FeatureRepositoryInterface,
        mlsService: any MLSServiceInterface,
        syncContext: NSManagedObjectContext
    ) {
        let updateUseCase = UpdateMLSGroupVerificationStatusUseCase(
            e2eIVerificationStatusService: e2eiVerificationStatusService,
            syncContext: syncContext,
            featureRepository: featureRepository
        )

        self.updateUseCase = updateUseCase
        self.mlsService = mlsService
        self.syncContext = syncContext
    }

    // MARK: Observing

    public func startObserving() {
        observingTask = .detached { [mlsService, weak self] in
            for await groupID in mlsService.epochChanges() {
                await self?.updateConversation(with: groupID)
            }
        }
    }

    // MARK: Update Conversation

    private func updateConversation(with groupID: MLSGroupID) async {
        guard let conversation = await syncContext.perform({
            ZMConversation.fetch(with: groupID, in: self.syncContext)
        }) else {
            return WireLogger.e2ei.warn("failed to fetch the conversation by mlsGroupID \(groupID)")
        }

        do {
            try await updateUseCase.invoke(for: conversation, groupID: groupID)
        } catch {
            WireLogger.e2ei.warn("failed to update MLS group: \(groupID) verification status: \(error)")
        }
    }

    public func updateAllConversations() async {
        WireLogger.e2ei.info("updating all MLS conversations verification status")

        let groupIDConversationTuples: [(MLSGroupID, ZMConversation)] = await syncContext.perform { [self] in
            let conversations = ZMConversation.fetchMLSConversations(in: syncContext)
            return conversations.compactMap {
                guard let groupID = $0.mlsGroupID else {
                    return nil
                }
                return (groupID, $0)
            }
        }

        for (groupID, conversation) in groupIDConversationTuples {
            do {
                try await updateUseCase.invoke(for: conversation, groupID: groupID)
            } catch {
                WireLogger.e2ei.warn("failed to update verification status for (\(groupID.safeForLoggingDescription)): \(String(describing: error))")
            }
        }
    }
}
