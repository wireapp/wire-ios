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

// MARK: - MLSGroupVerificationProtocol

// sourcery: AutoMockable
public protocol MLSGroupVerificationProtocol {
    func startObserving()
    func updateConversation(by groupID: MLSGroupID) async
    func updateConversation(_ conversation: ZMConversation, with groupID: MLSGroupID) async
    func updateAllConversations() async
}

// MARK: - MLSGroupVerification

public final class MLSGroupVerification: MLSGroupVerificationProtocol {
    // MARK: Lifecycle

    // MARK: - Initialize

    public init(
        updateVerificationStatus: any UpdateMLSGroupVerificationStatusUseCaseProtocol,
        mlsService: any MLSServiceInterface,
        syncContext: NSManagedObjectContext
    ) {
        self.updateVerificationStatus = updateVerificationStatus
        self.mlsService = mlsService
        self.syncContext = syncContext
    }

    deinit {
        observationTask?.cancel()
    }

    // MARK: Public

    // MARK: Observing

    public func startObserving() {
        observationTask = .detached { [weak self] in
            guard let asyncStream = self?.mlsService.epochChanges() else {
                return
            }

            for await groupID in asyncStream {
                if Task.isCancelled {
                    return
                }
                await self?.updateConversation(by: groupID)
            }
        }
    }

    // MARK: Update Conversation

    public func updateConversation(by groupID: MLSGroupID) async {
        guard let conversation = await syncContext.perform({
            ZMConversation.fetch(with: groupID, in: self.syncContext)
        }) else {
            return WireLogger.e2ei.warn("failed to fetch the conversation by mlsGroupID \(groupID)")
        }

        await updateConversation(conversation, with: groupID)
    }

    public func updateConversation(_ conversation: ZMConversation, with groupID: MLSGroupID) async {
        do {
            try await updateVerificationStatus.invoke(for: conversation, groupID: groupID)
        } catch {
            WireLogger.e2ei
                .warn(
                    "failed to update MLS group: \(groupID.safeForLoggingDescription) verification status: \(String(describing: error))"
                )
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
            await updateConversation(conversation, with: groupID)
        }
    }

    // MARK: Private

    // MARK: - Properties

    private let updateVerificationStatus: any UpdateMLSGroupVerificationStatusUseCaseProtocol

    private let mlsService: MLSServiceInterface
    private let syncContext: NSManagedObjectContext

    private var observationTask: Task<Void, Never>?
}
