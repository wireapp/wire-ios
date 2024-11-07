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

import WireDataModel

// MARK: - NeedsToRegisterMLSClientUseCaseProtocol

public protocol NeedsToRegisterMLSClientUseCaseProtocol {

    func invoke() async -> Bool

}

// MARK: - NeedsToRegisterMLSClientUseCase

struct NeedsToRegisterMLSClientUseCase: NeedsToRegisterMLSClientUseCaseProtocol {

    private let context: NSManagedObjectContext
    private let mlsFeature: Feature.MLS
    private let actionsProvider: MLSActionsProvider

    public init(
        context: NSManagedObjectContext,
        mlsFeature: Feature.MLS,
        actionsProvider: MLSActionsProvider = MLSActionsProvider()
    ) {
        self.context = context
        self.mlsFeature = mlsFeature
        self.actionsProvider = actionsProvider
    }

    public func invoke() async -> Bool {
        guard await !needsToRegisterClient() else {
            return false
        }

        let hasRegisteredMLSClient = await hasRegisteredMLSClient()
        let isMLSEnabledOnBackend = await containsBackendPublicKeys()

        return !hasRegisteredMLSClient && isAllowedToRegisterMLSCLient && isMLSEnabledOnBackend
    }

    // MARK: - Helpers

    private func needsToRegisterClient() async -> Bool {
        return await context.perform {
            guard let clientID = context.persistentStoreMetadata(forKey: ZMPersistedClientIdKey) as? String else {
                return true
            }
            return clientID.isEmpty
        }
    }

    private func hasRegisteredMLSClient() async -> Bool {
        return await context.perform {
            return ZMUser.selfUser(in: context).selfClient()?.hasRegisteredMLSClient ?? false
        }
    }

    private var isAllowedToRegisterMLSCLient: Bool {
        return mlsFeature.isEnabled && (BackendInfo.apiVersion ?? .v0) >= .v5
    }

    private func containsBackendPublicKeys() async -> Bool {
        do {
            _ = try await actionsProvider.fetchBackendPublicKeys(in: context.notificationContext)
            return true
        } catch FetchBackendMLSPublicKeysAction.Failure.mlsNotEnabled {
            return false
        } catch {
            WireLogger.mls.warn("unexpected error fetching public keys: \(String(describing: error))")
            return false
        }
    }

}
