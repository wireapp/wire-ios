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

import Foundation
import WireLogging
import WireNetwork

struct PullAllFeatureConfigsSync: PullAllFeatureConfigsSyncProtocol {

    private let api: any FeatureConfigsAPI
    private let store: any FeatureConfigLocalStoreProtocol

    init(
        api: any FeatureConfigsAPI,
        store: any FeatureConfigLocalStoreProtocol
    ) {
        self.api = api
        self.store = store
    }

    func pull() async throws {
        let featureConfigs = try await api.getFeatureConfigs()

        for featureConfig in featureConfigs {
            await store.storeFeatureConfig(featureConfig)
        }
    }

}

extension FeatureConfigLocalStoreProtocol {

    func storeFeatureConfig(_ featureConfig: WireNetwork.FeatureConfig) async {
        switch featureConfig {
        case let .appLock(config):
            await storeFeature(
                name: .appLock,
                isEnabled: config.status == .enabled,
                config: config.toDomainModel()
            )
        case let .apps(config):
            await storeFeature(
                name: .apps,
                isEnabled: config.status == .enabled,
                config: nil
            )
        case let .assetAuditLog(config):
            await storeFeature(
                name: .assetAuditLog,
                isEnabled: config.status == .enabled,
                config: nil
            )
        case let .classifiedDomains(config):
            await storeFeature(
                name: .classifiedDomains,
                isEnabled: config.status == .enabled,
                config: config.toDomainModel()
            )
        case let .conferenceCalling(config):
            await storeFeature(
                name: .conferenceCalling,
                isEnabled: config.status == .enabled,
                config: config.toDomainModel()
            )
        case let .conversationGuestLinks(config):
            await storeFeature(
                name: .conversationGuestLinks,
                isEnabled: config.status == .enabled,
                config: nil
            )
        case let .digitalSignature(config):
            await storeFeature(
                name: .digitalSignature,
                isEnabled: config.status == .enabled,
                config: nil
            )
        case let .endToEndIdentity(config):
            await storeFeature(
                name: .e2ei,
                isEnabled: config.status == .enabled,
                config: config.toDomainModel()
            )
        case let .fileSharing(config):
            await storeFeature(
                name: .fileSharing,
                isEnabled: config.status == .enabled,
                config: nil
            )
        case let .mls(config):
            await storeFeature(
                name: .mls,
                isEnabled: config.status == .enabled,
                config: config.toDomainModel()
            )
        case let .mlsMigration(config):
            await storeFeature(
                name: .mlsMigration,
                isEnabled: config.status == .enabled,
                config: config.toDomainModel()
            )
        case let .selfDeletingMessages(config):
            await storeFeature(
                name: .selfDeletingMessages,
                isEnabled: config.status == .enabled,
                config: config.toDomainModel()
            )
        case let .channels(config):
            await storeFeature(
                name: .channels,
                isEnabled: config.status == .enabled,
                config: config.toDomainModel()
            )
        case let .allowedGlobalOperations(config):
            await storeFeature(
                name: .allowedGlobalOperations,
                isEnabled: config.status == .enabled,
                config: config.toDomainModel()
            )
        case let .consumableNotifications(config):
            await storeFeature(
                name: .consumableNotifications,
                isEnabled: config.status == .enabled,
                config: nil
            )
        case let .chatBubblesSimple(config):
            await storeFeature(
                name: .chatBubblesSimple,
                isEnabled: config.status == .enabled,
                config: nil
            )
        case let .cells(config):
            await storeFeature(
                name: .cells,
                isEnabled: config.status == .enabled,
                config: nil
            )
        case let .unknown(name):
            WireLogger.featureConfigs.warn("encountered unknown feature config '\(name)' when storing, skipping")
            return
        }
    }

}
