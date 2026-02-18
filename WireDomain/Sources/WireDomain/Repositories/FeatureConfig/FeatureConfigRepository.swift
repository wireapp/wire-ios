//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import Combine
import WireDataModel
import WireLogging
import WireNetwork

public final class FeatureConfigRepository: FeatureConfigRepositoryProtocol {

    // MARK: - Properties

    private let featureConfigsAPI: any FeatureConfigsAPI
    private let featureConfigLocalStore: any FeatureConfigLocalStoreProtocol
    private let logger = WireLogger.featureConfigs
    private let featureStateSubject = PassthroughSubject<FeatureState, Never>()

    // MARK: - Object lifecycle

    init(
        featureConfigsAPI: any FeatureConfigsAPI,
        featureConfigLocalStore: any FeatureConfigLocalStoreProtocol
    ) {
        self.featureConfigsAPI = featureConfigsAPI
        self.featureConfigLocalStore = featureConfigLocalStore
    }

    // MARK: - Public

    public func pullFeatureConfigs() async throws {
        let featureConfigs = try await featureConfigsAPI.getFeatureConfigs()

        for featureConfig in featureConfigs {
            await featureConfigLocalStore.storeFeatureConfig(featureConfig)
            await sendFeatureState(for: featureConfig)
        }
    }

    public func isFeatureEnabled(
        _ feature: Feature.Name
    ) async -> Bool {
        do {
            let feature = try await featureConfigLocalStore.fetchFeature(
                name: feature
            )
            return await featureConfigLocalStore.isFeatureEnabled(
                feature: feature
            )
        } catch {
            return false
        }
    }

    public func observeFeatureStates() -> AnyPublisher<FeatureState, Never> {
        featureStateSubject.eraseToAnyPublisher()
    }

    public func updateFeatureConfig(
        _ featureConfig: FeatureConfig
    ) async {
        await featureConfigLocalStore.storeFeatureConfig(featureConfig)
        await sendFeatureState(for: featureConfig)
    }

    public func fetchAllowedGlobalOperations() async throws -> LocalFeature<Feature.AllowedGlobalOperations.Config> {
        try await fetchFeatureConfig(
            name: .allowedGlobalOperations,
            type: Feature.AllowedGlobalOperations.Config.self
        )
    }

    public func fetchMLSConfig() async throws -> LocalFeature<Feature.MLS.Config> {
        try await fetchFeatureConfig(
            name: .mls,
            type: Feature.MLS.Config.self
        )
    }

    public func fetchMLSMigrationConfig() async throws -> LocalFeature<Feature.MLSMigration.Config> {
        try await fetchFeatureConfig(
            name: .mlsMigration,
            type: Feature.MLSMigration.Config.self
        )
    }

    public func fetchAppLock() async throws -> LocalFeature<Feature.AppLock.Config> {
        try await fetchFeatureConfig(
            name: .appLock,
            type: Feature.AppLock.Config.self
        )
    }

    public func fetchCellsInternal() async throws -> LocalFeature<Feature.CellsInternal.Config> {
        try await fetchFeatureConfig(
            name: .cellsInternal,
            type: Feature.CellsInternal.Config.self
        )
    }

    // MARK: - Private

    private func sendFeatureState(for featureConfig: FeatureConfig) async {
        guard let featureState = try? await getFeatureState(
            forFeatureConfig: featureConfig
        ) else { return }

        featureStateSubject.send(featureState)
    }

    private func getFeatureState(forFeatureConfig config: FeatureConfig) async throws -> FeatureState? {
        switch config {
        case let .appLock(appLockFeatureConfig):
            return FeatureState(
                name: .appLock,
                isEnabled: appLockFeatureConfig.status == .enabled
            )

        case let .apps(appsConfig):
            return FeatureState(
                name: .apps,
                isEnabled: appsConfig.status == .enabled
            )

        case let .assetAuditLog(config):
            return FeatureState(
                name: .assetAuditLog,
                isEnabled: config.status == .enabled
            )

        case let .classifiedDomains(classifiedDomainsFeatureConfig):

            return FeatureState(
                name: .classifiedDomains,
                isEnabled: classifiedDomainsFeatureConfig.status == .enabled
            )

        case let .conferenceCalling(conferenceCallingFeatureConfig):

            return FeatureState(
                name: .conferenceCalling,
                isEnabled: conferenceCallingFeatureConfig.status == .enabled
            )

        case let .conversationGuestLinks(conversationGuestLinksFeatureConfig):

            return FeatureState(
                name: .conversationGuestLinks,
                isEnabled: conversationGuestLinksFeatureConfig.status == .enabled
            )

        case let .digitalSignature(digitalSignatureFeatureConfig):

            return FeatureState(
                name: .digitalSignature,
                isEnabled: digitalSignatureFeatureConfig.status == .enabled
            )

        case let .endToEndIdentity(endToEndIdentityFeatureConfig):

            return FeatureState(
                name: .e2ei,
                isEnabled: endToEndIdentityFeatureConfig.status == .enabled
            )

        case let .fileSharing(fileSharingFeatureConfig):

            return FeatureState(
                name: .fileSharing,
                isEnabled: fileSharingFeatureConfig.status == .enabled
            )

        case let .mls(mlsFeatureConfig):

            return FeatureState(
                name: .mls,
                isEnabled: mlsFeatureConfig.status == .enabled
            )

        case let .mlsMigration(mLSMigrationFeatureConfig):

            return FeatureState(
                name: .mlsMigration,
                isEnabled: mLSMigrationFeatureConfig.status == .enabled
            )

        case let .selfDeletingMessages(selfDeletingMessagesFeatureConfig):

            return FeatureState(
                name: .selfDeletingMessages,
                isEnabled: selfDeletingMessagesFeatureConfig.status == .enabled
            )

        case let .channels(channelsFeatureConfig):

            return FeatureState(
                name: .channels,
                isEnabled: channelsFeatureConfig.status == .enabled
            )

        case let .allowedGlobalOperations(config):
            return FeatureState(
                name: .allowedGlobalOperations,
                isEnabled: config.status == .enabled
            )

        case let .consumableNotifications(config):
            return FeatureState(
                name: .consumableNotifications,
                isEnabled: config.status == .enabled
            )

        case let .simplifiedUserConnectionRequestQRCode(config):
            return FeatureState(
                name: .simplifiedUserConnectionRequestQRCode,
                isEnabled: config.status == .enabled
            )

        case let .cells(cellsConfig):
            return FeatureState(
                name: .cells,
                isEnabled: cellsConfig.status == .enabled
            )

        case let .cellsInternal(cellsInternalConfig):
            return FeatureState(
                name: .cellsInternal,
                isEnabled: cellsInternalConfig.status == .enabled
            )

        case let .unknown(featureName):
            logger.warn(
                "Unknown feature name: \(featureName)"
            )

            return nil
        }
    }

    private func fetchFeatureConfig<T: Decodable>(
        name: Feature.Name,
        type: T.Type?
    ) async throws -> LocalFeature<T> {
        let feature = try await featureConfigLocalStore.fetchFeature(
            name: name
        )

        let featureConfig = await featureConfigLocalStore.featureConfig(feature: feature)

        if let type, let config = featureConfig.config {
            let decoder = JSONDecoder()
            let config = try decoder.decode(type, from: config)

            return LocalFeature(status: featureConfig.status, config: config)
        }

        return LocalFeature(status: featureConfig.status, config: nil)
    }
}
