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

// TODO: Add tests
public protocol MLSClientManagerProtocol {

    func initializeMLSClientIfNeeded(
        for qualifiedClientID: QualifiedClientID,
        hasRegisteredMLSClient: Bool,
        mlsFeature: Feature.MLS
    ) async

}

public final class MLSClientManager: MLSClientManagerProtocol {

    // MARK: - Properties

    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private let mlsService: MLSServiceInterface

    // MARK: - Initialize

    public init(
        coreCryptoProvider: CoreCryptoProviderProtocol,
        mlsService: any MLSServiceInterface
    ) {
        self.coreCryptoProvider = coreCryptoProvider
        self.mlsService = mlsService
    }

    // MARK: - Public Implementation

    public func initializeMLSClientIfNeeded(
        for qualifiedClientID: QualifiedClientID,
        hasRegisteredMLSClient: Bool,
        mlsFeature: Feature.MLS
    ) async {
        guard BackendInfo.isMLSEnabled && mlsFeature.isEnabled else {
            return
        }

        if !hasRegisteredMLSClient {
            let mlsClientID = MLSClientID(qualifiedClientID: qualifiedClientID)
            await createMLSClient(mlsClientID: mlsClientID)
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

    private func createMLSClient(mlsClientID: MLSClientID) async {
        do {
            try await coreCryptoProvider.initialiseMLSWithBasicCredentials(mlsClientID: mlsClientID)
        } catch {
            WireLogger.mls.error("Failed to initialise mls client: \(error)")
        }
    }

}
