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

import CoreData

// MARK: - CoreDataMigratorProtocol

protocol CoreDataMigratorProtocol {
    associatedtype DatabaseVersion

    func requiresMigration(at storeURL: URL, toVersion version: DatabaseVersion) -> Bool
    func migrateStore(at storeURL: URL, toVersion version: DatabaseVersion) throws
}

// MARK: - CoreDataMigratorError

enum CoreDataMigratorError: Error {
    case missingStoreURL
    case missingFiles(message: String)
    case unknownVersion
    case migrateStoreFailed(error: Error)
    case failedToForceWALCheckpointing
    case failedToReplacePersistentStore(sourceURL: URL, targetURL: URL, underlyingError: Error)
    case failedToDestroyPersistentStore(storeURL: URL)
}

// MARK: LocalizedError

extension CoreDataMigratorError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingStoreURL:
            return "missingStoreURL"

        case let .missingFiles(message):
            return "missingFiles: \(message)"

        case .unknownVersion:
            return "unknownVersion"

        case let .migrateStoreFailed(error):
            let nsError = error as NSError
            return "migrateStoreFailed: \(error.localizedDescription). "
                + "NSError code: \(nsError.code) --- domain \(nsError.domain) --- userInfo: \(dump(nsError.userInfo))."

        case .failedToForceWALCheckpointing:
            return "failedToForceWALCheckpointing"

        case let .failedToReplacePersistentStore(sourceURL, targetURL, underlyingError):
            let nsError = underlyingError as NSError
            return "failedToReplacePersistentStore: \(underlyingError.localizedDescription). sourceURL: \(sourceURL). targetURL: \(targetURL). "
                + "NSError code: \(nsError.code) --- domain \(nsError.domain) --- userInfo: \(dump(nsError.userInfo))"

        case let .failedToDestroyPersistentStore(storeURL):
            return "failedToDestroyPersistentStore: \(storeURL)"
        }
    }
}

// MARK: - CoreDataMigrator

final class CoreDataMigrator<Version: CoreDataMigrationVersion>: CoreDataMigratorProtocol {
    // MARK: Lifecycle

    init(isInMemoryStore: Bool) {
        self.isInMemoryStore = isInMemoryStore
    }

    // MARK: Internal

    func requiresMigration(at storeURL: URL, toVersion version: Version) -> Bool {
        guard let metadata = try? metadataForPersistentStore(at: storeURL) else {
            return false
        }
        return compatibleVersionForStoreMetadata(metadata) != version
    }

    func migrateStore(at storeURL: URL, toVersion version: Version) throws {
        WireLogger.localStorage.info(
            "migrateStore at: \(SanitizedString(stringLiteral: storeURL.absoluteString)) to version: \(SanitizedString(stringLiteral: version.rawValue))",
            attributes: .safePublic
        )

        try forceWALCheckpointingForStore(at: storeURL)

        var currentURL = storeURL

        for migrationStep in try migrationStepsForStore(at: storeURL, to: version) {
            let logMessage =
                "core data store migration step \(migrationStep.sourceVersion) to \(migrationStep.destinationVersion)"
            WireLogger.localStorage.info(logMessage, attributes: .safePublic)

            try runPreMigrationStep(migrationStep, for: currentURL)

            let manager = NSMigrationManager(
                sourceModel: migrationStep.sourceModel,
                destinationModel: migrationStep.destinationModel
            )
            let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent(UUID().uuidString)

            do {
                try manager.migrateStore(
                    from: currentURL,
                    type: persistentStoreType,
                    mapping: migrationStep.mappingModel,
                    to: destinationURL,
                    type: persistentStoreType
                )
                WireLogger.localStorage.info(
                    "finish migrate store for \(migrationStep.sourceVersion)",
                    attributes: .safePublic
                )
            } catch {
                throw CoreDataMigratorError.migrateStoreFailed(error: error)
            }

            if currentURL != storeURL {
                WireLogger.localStorage.info("destroy store \(storeURL)", attributes: .safePublic)
                // Destroy intermediate step's store
                try destroyStore(at: currentURL)
            }

            currentURL = destinationURL

            WireLogger.localStorage.info(
                "finish migration step for \(migrationStep.sourceVersion)",
                attributes: .safePublic
            )

            try runPostMigrationStep(migrationStep, for: currentURL)
        }
        WireLogger.localStorage.info("replace store \(storeURL), with \(currentURL)", attributes: .safePublic)
        try replaceStore(at: storeURL, withStoreAt: currentURL)
        WireLogger.localStorage.info("replace store finished", attributes: .safePublic)

        if currentURL != storeURL {
            WireLogger.localStorage.info("destroy last store \(currentURL)", attributes: .safePublic)
            try destroyStore(at: currentURL)
        }
    }

    // MARK: - Write-Ahead Logging (WAL)

    // Taken from https://williamboles.com/progressive-core-data-migration/
    func forceWALCheckpointingForStore(at storeURL: URL) throws {
        guard
            let metadata = try? metadataForPersistentStore(at: storeURL),
            let version = compatibleVersionForStoreMetadata(metadata),
            let versionURL = version.managedObjectModelURL(),
            let model = NSManagedObjectModel(contentsOf: versionURL)
        else {
            WireLogger.localStorage.info("skip WAL checkpointing for store", attributes: .safePublic)
            return
        }

        WireLogger.localStorage.info("force WAL checkpointing for store", attributes: .safePublic)

        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

            let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
            let store = try persistentStoreCoordinator.addPersistentStore(
                type: persistentStoreType,
                at: storeURL,
                options: options
            )

            try persistentStoreCoordinator.remove(store)
            WireLogger.localStorage.info("finish WAL checkpointing for store", attributes: .safePublic)
        } catch {
            throw CoreDataMigratorError.failedToForceWALCheckpointing
        }
    }

    // MARK: - CoreDataMigration Actions

    func runPreMigrationStep(_ step: CoreDataMigrationStep<Version>, for storeURL: URL) throws {
        guard let action = CoreDataMigrationActionFactory.createPreMigrationAction(for: step.destinationVersion) else {
            return
        }
        WireLogger.localStorage.debug("run preMigration step \(step.destinationVersion)", attributes: .safePublic)
        try action.perform(
            on: storeURL,
            with: step.sourceModel
        )
    }

    func runPostMigrationStep(_ step: CoreDataMigrationStep<Version>, for storeURL: URL) throws {
        guard let action = CoreDataMigrationActionFactory.createPostMigrationAction(for: step.destinationVersion)
        else { return }

        WireLogger.localStorage.debug("run postMigration step \(step.destinationVersion)", attributes: .safePublic)
        try action.perform(
            on: storeURL,
            with: step.destinationModel
        )
    }

    // MARK: Private

    private let isInMemoryStore: Bool

    private var persistentStoreType: NSPersistentStore.StoreType {
        isInMemoryStore ? .inMemory : .sqlite
    }

    private func migrationStepsForStore(
        at storeURL: URL,
        to destinationVersion: Version
    ) throws -> [CoreDataMigrationStep<Version>] {
        guard
            let metadata = try? metadataForPersistentStore(at: storeURL),
            let sourceVersion = compatibleVersionForStoreMetadata(metadata)
        else {
            throw CoreDataMigratorError.unknownVersion
        }

        return try migrationSteps(fromSourceVersion: sourceVersion, toDestinationVersion: destinationVersion)
    }

    private func migrationSteps(
        fromSourceVersion sourceVersion: Version,
        toDestinationVersion destinationVersion: Version
    ) throws -> [CoreDataMigrationStep<Version>] {
        var sourceVersion = sourceVersion
        var migrationSteps: [CoreDataMigrationStep<Version>] = []

        while sourceVersion != destinationVersion, let nextVersion = sourceVersion.nextVersion {
            let step = try CoreDataMigrationStep(sourceVersion: sourceVersion, destinationVersion: nextVersion)
            migrationSteps.append(step)

            sourceVersion = nextVersion
        }

        return migrationSteps
    }

    // MARK: - Helpers

    private func metadataForPersistentStore(at storeURL: URL) throws -> [String: Any] {
        try NSPersistentStoreCoordinator.metadataForPersistentStore(type: persistentStoreType, at: storeURL)
    }

    private func compatibleVersionForStoreMetadata(_ metadata: [String: Any]) -> Version? {
        let allVersions = Version.allCases
        return allVersions.first {
            guard let url = $0.managedObjectModelURL() else {
                return false
            }

            let model = NSManagedObjectModel(contentsOf: url)
            return model?.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) == true
        }
    }

    // MARK: - NSPersistentStoreCoordinator File Managing

    private func replaceStore(at targetURL: URL, withStoreAt sourceURL: URL) throws {
        WireLogger.localStorage.info(
            "replace store at target url: \(SanitizedString(stringLiteral: targetURL.absoluteString))",
            attributes: .safePublic
        )
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
            try persistentStoreCoordinator.replacePersistentStore(
                at: targetURL,
                destinationOptions: nil,
                withPersistentStoreFrom: sourceURL,
                sourceOptions: nil,
                type: persistentStoreType
            )
        } catch {
            throw CoreDataMigratorError.failedToReplacePersistentStore(
                sourceURL: sourceURL,
                targetURL: targetURL,
                underlyingError: error
            )
        }
    }

    private func destroyStore(at storeURL: URL) throws {
        WireLogger.localStorage.info(
            "destroy store of at: \(SanitizedString(stringLiteral: storeURL.absoluteString))",
            attributes: .safePublic
        )

        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
            try persistentStoreCoordinator.destroyPersistentStore(at: storeURL, type: persistentStoreType, options: nil)
        } catch {
            throw CoreDataMigratorError.failedToDestroyPersistentStore(storeURL: storeURL)
        }
    }
}
