//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

final class FeatureConfigRepository: FeatureConfigRepositoryProtocol {

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

    func pullFeatureConfigs() async throws {
        let featureConfigs = try await featureConfigsAPI.getFeatureConfigs()

        for featureConfig in featureConfigs {
            if let featureConfigInfo = getFeatureConfigInfo(featureConfig) {
                await featureConfigLocalStore.storeFeature(
                    name: featureConfigInfo.name,
                    isEnabled: featureConfigInfo.isEnabled,
                    config: featureConfigInfo.config
                )

                await sendFeatureState(for: featureConfig)
            }
        }
    }

    func observeFeatureStates() -> AnyPublisher<FeatureState, Never> {
        featureStateSubject.eraseToAnyPublisher()
    }

    func fetchFeatureConfig<T: Decodable>(
        name: Feature.Name,
        type: T.Type
    ) async throws -> LocalFeature<T> {
        let feature = try await featureConfigLocalStore.fetchFeature(
            name: name
        )

        let featureConfig = await featureConfigLocalStore.featureConfig(feature: feature)

        if let config = featureConfig.config {
            let decoder = JSONDecoder()
            let config = try decoder.decode(type, from: config)

            return LocalFeature(status: featureConfig.status, config: config)
        }

        return LocalFeature(status: featureConfig.status, config: nil)
    }

    func updateFeatureConfig(
        _ featureConfig: FeatureConfig
    ) async {
        guard let featureConfigInfo = getFeatureConfigInfo(
            featureConfig
        ) else {
            return
        }

        await featureConfigLocalStore.storeFeature(
            name: featureConfigInfo.name,
            isEnabled: featureConfigInfo.isEnabled,
            config: featureConfigInfo.config
        )

        await sendFeatureState(for: featureConfig)
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

        case let .unknown(featureName):
            logger.warn(
                "Unknown feature name: \(featureName)"
            )

            return nil
        }
    }

    private func getFeatureConfigInfo(
        _ featureConfig: FeatureConfig
    ) -> (name: Feature.Name, isEnabled: Bool, config: (any Codable)?)? {
        switch featureConfig {
        case let .appLock(appLockFeatureConfig):

            return (
                .appLock,
                appLockFeatureConfig.status == .enabled,
                appLockFeatureConfig.toDomainModel()
            )

        case let .classifiedDomains(classifiedDomainsFeatureConfig):

            return (
                .classifiedDomains,
                classifiedDomainsFeatureConfig.status == .enabled,
                classifiedDomainsFeatureConfig.toDomainModel()
            )

        case let .conferenceCalling(conferenceCallingFeatureConfig):

            return (
                .conferenceCalling,
                conferenceCallingFeatureConfig.status == .enabled,
                conferenceCallingFeatureConfig.toDomainModel()
            )

        case let .conversationGuestLinks(conversationGuestLinksFeatureConfig):

            return (
                .conversationGuestLinks,
                conversationGuestLinksFeatureConfig.status == .enabled,
                nil
            )

        case let .digitalSignature(digitalSignatureFeatureConfig):

            return (
                .digitalSignature,
                digitalSignatureFeatureConfig.status == .enabled,
                nil
            )

        case let .endToEndIdentity(endToEndIdentityFeatureConfig):

            return (
                .e2ei,
                endToEndIdentityFeatureConfig.status == .enabled,
                nil
            )

        case let .fileSharing(fileSharingFeatureConfig):

            return (
                .fileSharing,
                fileSharingFeatureConfig.status == .enabled,
                nil
            )

        case let .mls(mlsFeatureConfig):

            return (
                .mls,
                mlsFeatureConfig.status == .enabled,
                mlsFeatureConfig.toDomainModel()
            )

        case let .mlsMigration(mLSMigrationFeatureConfig):

            return (
                .mlsMigration,
                mLSMigrationFeatureConfig.status == .enabled,
                mLSMigrationFeatureConfig.toDomainModel()
            )

        case let .selfDeletingMessages(selfDeletingMessagesFeatureConfig):

            return (
                .selfDeletingMessages,
                selfDeletingMessagesFeatureConfig.status == .enabled,
                selfDeletingMessagesFeatureConfig.toDomainModel()
            )

        case let .channels(channelsFeatureConfig):

            return (
                .channels,
                channelsFeatureConfig.status == .enabled,
                channelsFeatureConfig.toDomainModel()
            )

        case let .allowedGlobalOperations(config):
            return (
                .allowedGlobalOperations,
                config.status == .enabled,
                config.toDomainModel()
            )

        case let .unknown(featureName):
            logger.warn(
                "Unknown feature name: \(featureName)"
            )

            return nil
        }
    }

}
