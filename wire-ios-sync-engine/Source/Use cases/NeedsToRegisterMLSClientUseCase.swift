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

    func invoke() -> Bool

}

// MARK: - NeedsToRegisterMLSClientUseCase

struct NeedsToRegisterMLSClientUseCase: NeedsToRegisterMLSClientUseCaseProtocol {

    private let context: NSManagedObjectContext
    private let getMLSFeatureUseCase: GetMLSFeatureUseCaseProtocol
    private let actionsProvider: MLSActionsProvider

    public init(
        context: NSManagedObjectContext,
        getMLSFeatureUseCase: GetMLSFeatureUseCaseProtocol,
        actionsProvider: MLSActionsProvider = MLSActionsProvider()
    ) {
        self.context = context
        self.getMLSFeatureUseCase = getMLSFeatureUseCase
        self.actionsProvider = actionsProvider
    }

    public func invoke() -> Bool {
        var isMLSEnabledOnBackend = false
        guard !needsToRegisterClient else {
            return false
        }
        Task {
            isMLSEnabledOnBackend = await containsBackendPublicKeys
        }
        return !hasRegisteredMLSClient && isAllowedToRegisterMLSCLient && isMLSEnabledOnBackend
    }

    // MARK: - Helpers

    private var needsToRegisterClient: Bool {
        guard let clientID = context.persistentStoreMetadata(forKey: ZMPersistedClientIdKey) as? String else {
            return true
        }
        return clientID.isEmpty
    }

    private var hasRegisteredMLSClient: Bool {
        guard let selfClient = ZMUser.selfUser(in: context).selfClient() else {
            return false
        }
        return selfClient.hasRegisteredMLSClient
    }

    private var isAllowedToRegisterMLSCLient: Bool {
        let mlsFeature = getMLSFeatureUseCase.invoke()
        return mlsFeature.isEnabled && (BackendInfo.apiVersion ?? .v0) >= .v5
    }

    private var containsBackendPublicKeys: Bool {
        get async {
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

}
