////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireUtilities
import WireTransport

public protocol ProteusToMLSMigrationCoordinating {
    func updateMigrationStatus()
}

public class ProteusToMLSMigrationCoordinator: ProteusToMLSMigrationCoordinating {

    // MARK: - Types

    enum MigrationStatus {
        case notStarted
        case started
        case finalising
        case finalised
    }

    enum MigrationStartStatus {
        case canStart
        case cannotStart(reason: CannotStartMigrationReason)

        enum CannotStartMigrationReason {
            case unsupportedAPIVersion
            case mlsProtocolIsNotSupported
            case clientDoesntSupportMLS
            case backendDoesntSupportMLS
            case mlsMigrationIsNotEnabled
            case startTimeHasNotBeenReached
        }
    }

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let featureRepository: FeatureRepository
    private let actionsProvider: MLSActionsProviderProtocol
    private let storage: ProteusToMLSMigrationStorage
    private let logger = WireLogger.mls

    private var migrationStatus: MigrationStatus {
        storage.migrationStatus ?? .notStarted
    }

    // MARK: - Life cycle

    public convenience init(
        context: NSManagedObjectContext,
        userID: UUID
    ) {
        self.init(
            context: context,
            userID: userID,
            featureRepository: nil,
            actionsProvider: nil
        )
    }

    init(
        context: NSManagedObjectContext,
        userID: UUID,
        userDefaults: UserDefaults = .standard,
        featureRepository: FeatureRepository? = nil,
        actionsProvider: MLSActionsProviderProtocol? = nil
    ) {
        self.context = context
        self.storage = ProteusToMLSMigrationStorage(
            userID: userID,
            userDefaults: userDefaults
        )
        self.featureRepository = featureRepository ?? FeatureRepository(context: context)
        self.actionsProvider = actionsProvider ?? MLSActionsProvider()

        if storage.migrationStatus == nil {
            storage.migrationStatus = .notStarted
        }
    }

    // MARK: - Interface

    public func updateMigrationStatus() {
        switch migrationStatus {
        case .notStarted:
            Task {
                await startMigrationIfNeeded()
            }
        case .started:
            // check if it should be finalised
            break
        default:
            break
        }
    }

    // MARK: - Private Methods

    func startMigrationIfNeeded() async {
        logger.info("checking if proteus-to-mls migration can start")
        let migrationStartStatus = await resolveMigrationStartStatus()

        switch migrationStartStatus {
        case .canStart:
            guard let mlsService = context.mlsService else {
                return logger.warn("can't start migration: missing `mlsService`")
            }

            logger.info("starting proteus-to-mls migration")
            mlsService.startProteusToMLSMigration()
            storage.migrationStatus = .started
        case .cannotStart(reason: let reason):
            logger.info("proteus-to-mls migration can't start (reason: \(reason))")
        }
    }

    private func resolveMigrationStartStatus() async -> MigrationStartStatus {

        // TODO: Might need to perform this on the context
        let mlsFeature = featureRepository.fetchMLS()
        let mlsMigrationFeature = featureRepository.fetchMLSMigration()

        if (BackendInfo.apiVersion ?? .v0) < .v5 {
            return .cannotStart(reason: .unsupportedAPIVersion)
        }

        if !mlsFeature.config.supportedProtocols.contains(.mls) {
            return .cannotStart(reason: .mlsProtocolIsNotSupported)
        }

        if !DeveloperFlag.enableMLSSupport.isOn {
            return .cannotStart(reason: .clientDoesntSupportMLS)
        }

        if await !isMLSEnabledOnBackend() {
            return .cannotStart(reason: .backendDoesntSupportMLS)
        }

        if mlsMigrationFeature.status == .disabled {
            return .cannotStart(reason: .mlsMigrationIsNotEnabled)
        }

        if mlsMigrationFeature.config.startTime > .now {
            return .cannotStart(reason: .startTimeHasNotBeenReached)
        }

        return .canStart
    }

    // MARK: - Helpers

    // TODO: add a catch for the `mls-not-enabled` error and log any other error
    private func isMLSEnabledOnBackend() async -> Bool  {
        do {
            _ = try await actionsProvider.fetchBackendPublicKeys(in: context.notificationContext)
            return true
        } catch {
            return false
        }
    }

}

class ProteusToMLSMigrationStorage {

    // MARK: - Properties

    private let storage: PrivateUserDefaults<Key>

    // MARK: - Types

    private enum Key: String, DefaultsKey {
        case migrationStatus = "com.wire.mls.migration.status"
    }

    typealias MigrationStatus = ProteusToMLSMigrationCoordinator.MigrationStatus

    // MARK: - Life cycle

    public init(
        userID: UUID,
        userDefaults: UserDefaults
    ) {
        storage = PrivateUserDefaults(
            userID: userID,
            storage: userDefaults
        )
    }

    // MARK: - Interface

    var migrationStatus: MigrationStatus? {
        get {
            storage.object(forKey: Key.migrationStatus) as? MigrationStatus
        }

        set {
            storage.set(newValue, forKey: Key.migrationStatus)
        }
    }
}
