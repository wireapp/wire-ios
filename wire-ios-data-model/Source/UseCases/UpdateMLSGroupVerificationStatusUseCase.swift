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

// MARK: - UpdateMLSGroupVerificationStatusUseCaseProtocol

// sourcery: AutoMockable
public protocol UpdateMLSGroupVerificationStatusUseCaseProtocol {
    func invoke(for conversation: ZMConversation, groupID: MLSGroupID) async throws
}

// MARK: - UpdateMLSGroupVerificationStatusUseCase

public class UpdateMLSGroupVerificationStatusUseCase: UpdateMLSGroupVerificationStatusUseCaseProtocol {
    // MARK: Lifecycle

    public init(
        e2eIVerificationStatusService: E2EIVerificationStatusServiceInterface,
        syncContext: NSManagedObjectContext,
        featureRepository: FeatureRepositoryInterface
    ) {
        self.e2eIVerificationStatusService = e2eIVerificationStatusService
        self.context = syncContext
        self.featureRepository = featureRepository
    }

    // MARK: Public

    // MARK: - Public interface

    public func invoke(for conversation: ZMConversation, groupID: MLSGroupID) async throws {
        let isE2EIEnabled = await context.perform {
            self.featureRepository.fetchE2EI().isEnabled
        }
        guard isE2EIEnabled else {
            return
        }

        try await updateStatus(for: conversation, groupID: groupID)
    }

    // MARK: Private

    // MARK: - Properties

    private let e2eIVerificationStatusService: E2EIVerificationStatusServiceInterface
    private let context: NSManagedObjectContext
    private let featureRepository: FeatureRepositoryInterface

    // MARK: - Helpers

    private func updateStatus(for conversation: ZMConversation, groupID: MLSGroupID) async throws {
        let coreCryptoStatus = try await e2eIVerificationStatusService.getConversationStatus(groupID: groupID)
        let context = conversation.managedObjectContext ?? context
        await context.perform {
            self.updateStatusAndNotifyUserIfNeeded(newStatusFromCC: coreCryptoStatus, conversation: conversation)
            context.saveOrRollback()
        }
    }

    private func updateStatusAndNotifyUserIfNeeded(
        newStatusFromCC: MLSVerificationStatus,
        conversation: ZMConversation
    ) {
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

    private func resolveNewStatus(
        newStatusFromCC: MLSVerificationStatus,
        currentStatus: MLSVerificationStatus
    ) -> MLSVerificationStatus {
        switch (newStatusFromCC, currentStatus) {
        case (.notVerified, .verified):
            .degraded
        case(.notVerified, .degraded):
            .degraded
        default:
            newStatusFromCC
        }
    }

    private func notifyUserAboutStateChangesIfNeeded(
        _ newStatus: MLSVerificationStatus,
        in conversation: ZMConversation
    ) {
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

extension ZMConversation {
    fileprivate func appendConversationVerifiedSystemMessage() {
        guard let context = managedObjectContext else {
            return
        }
        let selfUser = ZMUser.selfUser(in: context)
        appendConversationVerifiedSystemMessage(sender: selfUser, at: Date())
    }

    fileprivate func appendConversationDegradedSystemMessage() {
        guard let context = managedObjectContext else {
            return
        }
        let selfUser = ZMUser.selfUser(in: context)
        appendConversationDegradedSystemMessage(sender: selfUser, at: Date())
    }
}
