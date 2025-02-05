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
import WireAPI

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

private extension FeatureConfigLocalStoreProtocol {

    func storeFeatureConfig(_ featureConfig: WireAPI.FeatureConfig) async {
        switch featureConfig {
        case .appLock(let config):
            await storeFeature(
                name: .appLock,
                isEnabled: config.status == .enabled,
                config: config.toDomainModel()
            )
        case .classifiedDomains(let config):
            await storeFeature(
                name: .classifiedDomains,
                isEnabled: config.status == .enabled,
                config: config.toDomainModel()
            )
        case .conferenceCalling(let config):
            await storeFeature(
                name: .conferenceCalling,
                isEnabled: config.status == .enabled,
                config: config.toDomainModel()
            )
        case .conversationGuestLinks(let config):
            await storeFeature(
                name: .conversationGuestLinks,
                isEnabled: config.status == .enabled,
                config: nil
            )
        case .digitalSignature(let config):
            await storeFeature(
                name: .digitalSignature,
                isEnabled: config.status == .enabled,
                config: nil
            )
        case .endToEndIdentity(let config):
            await storeFeature(
                name: .e2ei,
                isEnabled: config.status == .enabled,
                config: config.toDomainModel()
            )
        case .fileSharing(let config):
            await storeFeature(
                name: .fileSharing,
                isEnabled: config.status == .enabled,
                config: nil
            )
        case .mls(let config):
            await storeFeature(
                name: .mls,
                isEnabled: config.status == .enabled,
                config: config.toDomainModel()
            )
        case .mlsMigration(let config):
            await storeFeature(
                name: .mlsMigration,
                isEnabled: config.status == .enabled,
                config: config.toDomainModel()
            )
        case .selfDeletingMessages(let config):
            await storeFeature(
                name: .selfDeletingMessages,
                isEnabled: config.status == .enabled,
                config: config.toDomainModel()
            )
        case .unknown:
            return
        }
    }

}
