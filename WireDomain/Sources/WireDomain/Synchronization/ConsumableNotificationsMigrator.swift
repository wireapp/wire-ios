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

import WireDataModel
import WireLogging
import WireNetwork

typealias IncrementalSyncV1 = IncrementalSync

public final class ConsumableNotificationsMigrator: ConsumableNotificationsMigratorProtocol {
    let sync: SyncMigratorProtocol
    let apiVersion: WireNetwork.APIVersion
    let userClientsLocalStore: UserClientsLocalStoreProtocol
    let userClientsAPI: UserClientsAPI
    var journal: JournalProtocol
    let featureConfigRepository: FeatureConfigRepositoryProtocol

    init(
        sync: SyncMigratorProtocol,
        featureConfigRepository: FeatureConfigRepositoryProtocol,
        userClientsAPI: UserClientsAPI,
        userClientsLocalStore: UserClientsLocalStoreProtocol,
        apiVersion: WireNetwork.APIVersion,
        journal: JournalProtocol
    ) {
        self.sync = sync
        self.apiVersion = apiVersion
        self.userClientsLocalStore = userClientsLocalStore
        self.journal = journal
        self.userClientsAPI = userClientsAPI
        self.featureConfigRepository = featureConfigRepository
    }

    public enum Failure: Error {
        case apiVersionTooLow
        case missingClient
        case missingClientID
        case featureConfigNotEnabled
    }

    public func migrate() async throws {
        // 0) check feature config
        guard await featureConfigRepository.isFeatureEnabled(.consumableNotifications),
              DeveloperFlag.consumableNotifications.isOn else {
            throw Failure.featureConfigNotEnabled
        }

        // 1) register consumable notifications capabilities
        guard apiVersion >= .v9 else {
            throw Failure.apiVersionTooLow
        }

        if await !userClientsLocalStore.hasRegisteredConsumableNotificationsCapable() {
            try await registerConsumableNotificationsCapability()
        }

        // 2) do incremental sync with v1 with no push channel
        WireLogger.sync.debug("incremental sync v1")
        try await sync.migrateFromIncrementalSyncV1()

        // 3) we're done
        WireLogger.sync.debug("ready for consumable notifications")
        journal[.isConsumableNotificationsEnabled] = true
    }

    private func registerConsumableNotificationsCapability() async throws {
        guard let id = await userClientsLocalStore.fetchSelfClientID() else {
            throw Failure.missingClientID
        }

        WireLogger.sync.debug("registering client with consumable notifications capabilities")
        let payload: ClientUpdate = .init(
            capabilities: [.legalholdConsent, .consumableNotifications]
        )
        try await userClientsAPI.updateClient(id: id, clientUpdate: payload)
    }
}
