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
public protocol MLSConversationVerificationStatusProviderInterface {

    func updateStatus(_ groupID: MLSGroupID) async throws

}

public class MLSConversationVerificationStatusProvider: MLSConversationVerificationStatusProviderInterface {

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
        guard let conversation = await syncContext.perform({
            ZMConversation.fetch(with: groupID, in: self.syncContext)
        }) else {
            throw E2eIVerificationStatusService.E2eIVerificationStatusError.missingConversation
        }
        do {
            let coreCryptoStatus = try await e2eIVerificationStatusService.getConversationStatus(groupID: groupID)
            await syncContext.perform {
                self.updateStatusAndNotifyUserIfNeeded(newStatusFromCC: coreCryptoStatus, conversation: conversation)
            }
        } catch {
            throw error
        }
    }

    // MARK: - Helpers

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

        appendSystemMessage(type: .conversationIsVerified,
                            sender: selfUser,
                            users: [],
                            clients: [],
                            timestamp: Date())
    }

    func appendConversationDegradedSystemMessage() {
        guard let context = managedObjectContext else {
            return
        }
        let selfUser = ZMUser.selfUser(in: context)

        appendSystemMessage(type: .conversationIsDegraded,
                            sender: selfUser,
                            users: [],
                            clients: [],
                            timestamp: Date())
    }

}
