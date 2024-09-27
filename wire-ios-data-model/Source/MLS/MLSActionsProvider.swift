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

// MARK: - MLSActionsProviderProtocol

// sourcery: AutoMockable
protocol MLSActionsProviderProtocol {
    func fetchBackendPublicKeys(
        in context: NotificationContext
    ) async throws -> BackendMLSPublicKeys

    func countUnclaimedKeyPackages(
        clientID: String,
        context: NotificationContext
    ) async throws -> Int

    func uploadKeyPackages(
        clientID: String,
        keyPackages: [String],
        context: NotificationContext
    ) async throws

    func claimKeyPackages(
        userID: UUID,
        domain: String?,
        ciphersuite: MLSCipherSuite,
        excludedSelfClientID: String?,
        in context: NotificationContext
    ) async throws -> [KeyPackage]

    func sendMessage(
        _ message: Data,
        in context: NotificationContext
    ) async throws -> [ZMUpdateEvent]

    func sendCommitBundle(
        _ bundle: Data,
        in context: NotificationContext
    ) async throws -> [ZMUpdateEvent]

    func fetchConversationGroupInfo(
        conversationId: UUID,
        domain: String,
        subgroupType: SubgroupType?,
        context: NotificationContext
    ) async throws -> Data

    func fetchSubgroup(
        conversationID: UUID,
        domain: String,
        type: SubgroupType,
        context: NotificationContext
    ) async throws -> MLSSubgroup

    func deleteSubgroup(
        conversationID: UUID,
        domain: String,
        subgroupType: SubgroupType,
        epoch: Int,
        groupID: MLSGroupID,
        context: NotificationContext
    ) async throws

    func leaveSubconversation(
        conversationID: UUID,
        domain: String,
        subconversationType: SubgroupType,
        context: NotificationContext
    ) async throws

    func syncConversation(
        qualifiedID: QualifiedID,
        context: NotificationContext
    ) async throws

    func updateConversationProtocol(
        qualifiedID: QualifiedID,
        messageProtocol: MessageProtocol,
        context: NotificationContext
    ) async throws

    func syncUsers(
        qualifiedIDs: [QualifiedID],
        context: NotificationContext
    ) async throws
}

// MARK: - MLSActionsProvider

final class MLSActionsProvider: MLSActionsProviderProtocol {
    func fetchBackendPublicKeys(
        in context: NotificationContext
    ) async throws -> BackendMLSPublicKeys {
        var action = FetchBackendMLSPublicKeysAction()
        return try await action.perform(in: context)
    }

    func countUnclaimedKeyPackages(
        clientID: String,
        context: NotificationContext
    ) async throws -> Int {
        var action = CountSelfMLSKeyPackagesAction(clientID: clientID)
        return try await action.perform(in: context)
    }

    func uploadKeyPackages(
        clientID: String,
        keyPackages: [String],
        context: NotificationContext
    ) async throws {
        var action = UploadSelfMLSKeyPackagesAction(
            clientID: clientID,
            keyPackages: keyPackages
        )

        try await action.perform(in: context)
    }

    func claimKeyPackages(
        userID: UUID,
        domain: String?,
        ciphersuite: MLSCipherSuite,
        excludedSelfClientID: String?,
        in context: NotificationContext
    ) async throws -> [KeyPackage] {
        var action = ClaimMLSKeyPackageAction(
            domain: domain,
            userId: userID,
            ciphersuite: ciphersuite,
            excludedSelfClientId: excludedSelfClientID
        )

        return try await action.perform(in: context)
    }

    func sendMessage(
        _ message: Data,
        in context: NotificationContext
    ) async throws -> [ZMUpdateEvent] {
        var action = SendMLSMessageAction(message: message)
        return try await action.perform(in: context)
    }

    func sendCommitBundle(
        _ bundle: Data,
        in context: NotificationContext
    )
        async throws -> [ZMUpdateEvent] {
        var action = SendCommitBundleAction(commitBundle: bundle)
        return try await action.perform(in: context)
    }

    func fetchConversationGroupInfo(
        conversationId: UUID,
        domain: String,
        subgroupType: SubgroupType?,
        context: NotificationContext
    ) async throws -> Data {
        if let subgroupType {
            var action = FetchMLSSubconversationGroupInfoAction(
                conversationId: conversationId,
                domain: domain,
                subgroupType: subgroupType
            )

            return try await action.perform(in: context)

        } else {
            var action = FetchMLSConversationGroupInfoAction(
                conversationId: conversationId,
                domain: domain
            )

            return try await action.perform(in: context)
        }
    }

    func fetchSubgroup(
        conversationID: UUID,
        domain: String,
        type: SubgroupType,
        context: NotificationContext
    ) async throws -> MLSSubgroup {
        var action = FetchSubgroupAction(
            domain: domain,
            conversationId: conversationID,
            type: type
        )

        return try await action.perform(in: context)
    }

    func deleteSubgroup(
        conversationID: UUID,
        domain: String,
        subgroupType: SubgroupType,
        epoch: Int,
        groupID: MLSGroupID,
        context: NotificationContext
    ) async throws {
        var action = DeleteSubgroupAction(
            conversationID: conversationID,
            domain: domain,
            subgroupType: subgroupType,
            epoch: epoch,
            groupID: groupID
        )

        try await action.perform(in: context)
    }

    func leaveSubconversation(
        conversationID: UUID,
        domain: String,
        subconversationType: SubgroupType,
        context: NotificationContext
    ) async throws {
        var action = LeaveSubconversationAction(
            conversationID: conversationID,
            domain: domain,
            subconversationType: subconversationType
        )

        try await action.perform(in: context)
    }

    func syncConversation(
        qualifiedID: QualifiedID,
        context: NotificationContext
    ) async throws {
        var action = SyncConversationAction(qualifiedID: qualifiedID)
        try await action.perform(in: context)
    }

    func updateConversationProtocol(
        qualifiedID: QualifiedID,
        messageProtocol: MessageProtocol,
        context: NotificationContext
    ) async throws {
        var action = UpdateConversationProtocolAction(
            qualifiedID: qualifiedID,
            messageProtocol: messageProtocol
        )
        try await action.perform(in: context)
    }

    func syncUsers(
        qualifiedIDs: [QualifiedID],
        context: NotificationContext
    ) async throws {
        var action = SyncUsersAction(qualifiedIDs: qualifiedIDs)
        return try await action.perform(in: context)
    }
}
