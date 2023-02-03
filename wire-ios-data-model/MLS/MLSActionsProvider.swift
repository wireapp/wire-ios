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

    func fetchPublicGroupState(
        conversationId: UUID,
        domain: String,
        context: NotificationContext
    ) async throws -> Data

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

    func fetchPublicGroupState(
        conversationId: UUID,
        domain: String,
        context: NotificationContext
    ) async throws -> Data {
        var action = FetchPublicGroupStateAction(
            conversationId: conversationId,
            domain: domain
        )

        return try await action.perform(in: context)
    }
}
