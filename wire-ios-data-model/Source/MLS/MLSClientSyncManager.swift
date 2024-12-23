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

import WireLogging

public protocol MLSClientSyncManagerProtocol {

    func initiateOrSyncMLSClient() async

}

public final class MLSClientSyncManager: MLSClientSyncManagerProtocol {

    // MARK: - Properties

    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private let mlsService: MLSServiceInterface
    private let syncContext: NSManagedObjectContext
    private let mlsFeature: Feature.MLS

    // MARK: - Initialize

    public init(
        coreCryptoProvider: CoreCryptoProviderProtocol,
        mlsService: any MLSServiceInterface,
        syncContext: NSManagedObjectContext,
        mlsFeature: Feature.MLS
    ) {
        self.coreCryptoProvider = coreCryptoProvider
        self.mlsService = mlsService
        self.syncContext = syncContext
        self.mlsFeature = mlsFeature
    }

    // MARK: - Public Implentation

    public func initiateOrSyncMLSClient() async {
        print("something")
        let (proteusService, conversationID) = await syncContext.perform { [syncContext] in (
            "proteusService",
            "conversationID"
        ) }
        print(proteusService)
        print(conversationID)
        let (qualifiedSelfClientID, hasRegisteredMLSClient) = await syncContext.perform { [syncContext] in
            let selfClient = ZMUser.selfUser(in: syncContext).selfClient()
            let hasRegisteredMLSClient = selfClient?.hasRegisteredMLSClient == true
            return (selfClient?.qualifiedClientID, hasRegisteredMLSClient)
        }

        if let qualifiedSelfClientID, !hasRegisteredMLSClient {
            await createMLSClientIfNeeded(qualifiedID: qualifiedSelfClientID)
        }
        await performsMLSClientUpdates()
    }

    // MARK: - Private Implentation

    private func performsMLSClientUpdates() async {
        // these operations are not dependent and should not be executed in same do/catch
        do {
            try await mlsService.performPendingJoins()
        } catch {
            WireLogger.mls.error("Failed to performPendingJoins: \(String(reflecting: error))")
        }
        await mlsService.uploadKeyPackagesIfNeeded()
        await mlsService.updateKeyMaterialForAllStaleGroupsIfNeeded()
    }

    private func createMLSClientIfNeeded(qualifiedID: QualifiedClientID) async {
        // If we discover that
        // there are MLS public keys on the backend, the MLS feature is enabled and there is no registered MLS
        // client,
        // we should create one.
        guard BackendInfo.isMLSEnabled && mlsFeature.isEnabled else {
            return
        }
        let mlsClientID = await syncContext.perform {
            MLSClientID(qualifiedClientID: qualifiedID)
        }

        do {
            try await coreCryptoProvider.initialiseMLSWithBasicCredentials(mlsClientID: mlsClientID)
        } catch {
            WireLogger.mls.error("Failed to initialise mls client: \(error)")
        }
    }

}
