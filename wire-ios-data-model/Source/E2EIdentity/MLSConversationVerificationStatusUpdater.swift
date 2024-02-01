//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
public protocol MLSConversationVerificationStatusUpdating {

    func updateStatus(_ groupID: MLSGroupID) async throws
    func updateAllStatuses() async throws

}

public class MLSConversationVerificationStatusUpdater: MLSConversationVerificationStatusUpdating {

    // MARK: - Properties

    private var e2eIVerificationStatusService: E2eIVerificationStatusServiceInterface
    private var syncContext: NSManagedObjectContext

    // MARK: - Life cycle

    public init(
        e2eIVerificationStatusService: E2eIVerificationStatusServiceInterface,
        syncContext: NSManagedObjectContext
    ) {
        self.e2eIVerificationStatusService = e2eIVerificationStatusService
        self.syncContext = syncContext
    }

    // MARK: - Public interface

    public func updateStatus(_ groupID: MLSGroupID) async throws {
        let conversation = await syncContext.perform {
            ZMConversation.fetch(with: groupID, in: self.syncContext)
        }

        guard let conversation else {
            throw E2eIVerificationStatusService.E2eIVerificationStatusError.missingConversation
        }

        try await updateStatus(for: conversation, groupID: groupID)
    }

    public func updateAllStatuses() async {
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
                try await updateStatus(for: conversation, groupID: groupID)
            } catch {
                // TODO: Handle error
            }
        }
    }

    // MARK: - Helpers

    private func updateStatus(for conversation: ZMConversation, groupID: MLSGroupID) async throws {
        do {
            let coreCryptoStatus = try await e2eIVerificationStatusService.getConversationStatus(groupID: groupID)
            await syncContext.perform {
                self.updateStatusAndNotifyUserIfNeeded(newStatusFromCC: coreCryptoStatus, conversation: conversation)
            }
        } catch {
            throw error
        }
    }

    private func updateStatusAndNotifyUserIfNeeded(newStatusFromCC: MLSVerificationStatus,
                                                   conversation: ZMConversation) {
        guard let currentStatus = conversation.mlsVerificationStatus else {
            return conversation.mlsVerificationStatus = newStatusFromCC
        }

        let newStatus = resolveNewStatus(newStatusFromCC: newStatusFromCC, currentStatus: currentStatus)
        guard newStatus != currentStatus else {
            return
        }
        conversation.mlsVerificationStatus = newStatus
        notifyUserAboutStateChangesIfNeeded(newStatus, in: conversation)
    }

    private func resolveNewStatus(newStatusFromCC: MLSVerificationStatus,
                                  currentStatus: MLSVerificationStatus) -> MLSVerificationStatus {
        switch (newStatusFromCC, currentStatus) {
        case (.notVerified, .verified):
            return .degraded
        case(.notVerified, .degraded):
            return .degraded
        default:
            return newStatusFromCC
        }
    }

    private func notifyUserAboutStateChangesIfNeeded(_ newStatus: MLSVerificationStatus, in conversation: ZMConversation) {
        switch newStatus {
        case .verified:
            conversation.appendConversationVerifiedSystemMessage()
        case .degraded:
            conversation.appendConversationDegradedSystemMessage()
        case .notVerified:
            return
        }
    }

}

// MARK: - Append system messages

private extension ZMConversation {

    func appendConversationVerifiedSystemMessage() {
        guard let context = managedObjectContext else {
            return
        }
        let selfUser = ZMUser.selfUser(in: context)
        appendConversationVerifiedSystemMessage(sender: selfUser, at: Date())
    }

    func appendConversationDegradedSystemMessage() {
        guard let context = managedObjectContext else {
            return
        }
        let selfUser = ZMUser.selfUser(in: context)
        appendConversationDegradedSystemMessage(sender: selfUser, at: Date())
    }

}
