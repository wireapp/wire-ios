//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
        context: NotificationContext
    ) async throws -> Data

    func fetchSubgroup(
        conversationID: UUID,
        domain: String,
        type: SubgroupType,
        context: NotificationContext
    ) async throws -> MLSSubgroup

}

class MLSActionsProvider: MLSActionsProviderProtocol {

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
        excludedSelfClientID: String?,
        in context: NotificationContext
    ) async throws -> [KeyPackage] {
        var action = ClaimMLSKeyPackageAction(
            domain: domain,
            userId: userID,
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
        in context: NotificationContext)
    async throws -> [ZMUpdateEvent] {
        var action = SendCommitBundleAction(commitBundle: bundle)
        return try await action.perform(in: context)
    }

    func fetchConversationGroupInfo(
        conversationId: UUID,
        domain: String,
        context: NotificationContext
    ) async throws -> Data {
        var action = FetchMLSConversationGroupInfoAction(
            conversationId: conversationId,
            domain: domain
        )

        return try await action.perform(in: context)
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

}
