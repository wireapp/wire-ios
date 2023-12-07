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

import CoreData

// sourcery: AutoMockable
protocol CoreDataMessagingMigratorProtocol {
    func requiresMigration(at storeURL: URL, toVersion version: CoreDataMessagingMigrationVersion) -> Bool
    func migrateStore(at storeURL: URL, toVersion version: CoreDataMessagingMigrationVersion) throws
}

enum CoreDataMessagingMigratorError: Error {
    case missingStoreURL
    case missingFiles(message: String)
    case unknownVersion
    case migrateStoreFailed(error: Error)
    case failedToForceWALCheckpointing
    case failedToReplacePersistentStore(sourceURL: URL, targetURL: URL)
    case failedToDestroyPersistentStore(storeURL: URL)
}

final class CoreDataMessagingMigrator: CoreDataMessagingMigratorProtocol {

    private let isInMemoryStore: Bool

    @available(iOS 15.0, *)
    private var persistentStoreType: NSPersistentStore.StoreType {
        isInMemoryStore ? .inMemory : .sqlite
    }

    @available(iOS, obsoleted: 15.0, renamed: "persistentStoreType")
    private var storeType: String {
        isInMemoryStore ? NSInMemoryStoreType : NSSQLiteStoreType
    }

    init(isInMemoryStore: Bool) {
        self.isInMemoryStore = isInMemoryStore
    }

    func dataModelVersionForStore(at storeURL: URL) -> String? {
        guard let metadata = try? metadataForPersistentStore(at: storeURL) else {
            return nil
        }
        return compatibleVersionForStoreMetadata(metadata)?.dataModelVersion
    }

    func requiresMigration(at storeURL: URL, toVersion version: CoreDataMessagingMigrationVersion) -> Bool {
        guard let metadata = try? metadataForPersistentStore(at: storeURL) else {
            return false
        }
        return compatibleVersionForStoreMetadata(metadata) != version
    }

    func migrateStore(at storeURL: URL, toVersion version: CoreDataMessagingMigrationVersion) throws {
        try forceWALCheckpointingForStore(at: storeURL)

        var currentURL = storeURL

        for migrationStep in try migrationStepsForStore(at: storeURL, to: version) {
            WireLogger.localStorage.info("messaging core data store migration step \(migrationStep.sourceVersion) to \(migrationStep.destinationVersion)")

            let manager = NSMigrationManager(sourceModel: migrationStep.sourceModel, destinationModel: migrationStep.destinationModel)
            let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(UUID().uuidString)

            do {
                if #available(iOS 15, *) {
                    try manager.migrateStore(
                        from: currentURL,
                        type: persistentStoreType,
                        mapping: migrationStep.mappingModel,
                        to: destinationURL,
                        type: persistentStoreType
                    )
                } else {
                    try manager.migrateStore(
                        from: currentURL,
                        sourceType: storeType,
                        options: nil,
                        with: migrationStep.mappingModel,
                        toDestinationURL: destinationURL,
                        destinationType: storeType,
                        destinationOptions: nil
                    )
                }
            } catch let error {
                throw CoreDataMessagingMigratorError.migrateStoreFailed(error: error)
            }

            if currentURL != storeURL {
                // Destroy intermediate step's store
                try destroyStore(at: currentURL)
            }

            currentURL = destinationURL
        }

        try replaceStore(at: storeURL, withStoreAt: currentURL)

        if currentURL != storeURL {
            try destroyStore(at: currentURL)
        }
    }

    private func migrationStepsForStore(
        at storeURL: URL,
        to destinationVersion: CoreDataMessagingMigrationVersion
    ) throws -> [CoreDataMessagingMigrationStep] {
        guard
            let metadata = try? metadataForPersistentStore(at: storeURL),
            let sourceVersion = compatibleVersionForStoreMetadata(metadata)
        else {
            throw CoreDataMessagingMigratorError.unknownVersion
        }

        return try migrationSteps(fromSourceVersion: sourceVersion, toDestinationVersion: destinationVersion)
    }

    private func migrationSteps(
        fromSourceVersion sourceVersion: CoreDataMessagingMigrationVersion,
        toDestinationVersion destinationVersion: CoreDataMessagingMigrationVersion
    ) throws -> [CoreDataMessagingMigrationStep] {
        var sourceVersion = sourceVersion
        var migrationSteps: [CoreDataMessagingMigrationStep] = []

        while sourceVersion != destinationVersion, let nextVersion = sourceVersion.nextVersion {
            let step = try CoreDataMessagingMigrationStep(sourceVersion: sourceVersion, destinationVersion: nextVersion)
            migrationSteps.append(step)

            sourceVersion = nextVersion
        }

        return migrationSteps
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
            return
        }

        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

            let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
            let store: NSPersistentStore

            if #available(iOS 15.0, *) {
                store = try persistentStoreCoordinator.addPersistentStore(type: persistentStoreType, at: storeURL, options: options)
            } else {
                store = try persistentStoreCoordinator.addPersistentStore(
                    ofType: storeType,
                    configurationName: nil,
                    at: storeURL,
                    options: options
                )
            }
            try persistentStoreCoordinator.remove(store)
        } catch {
            throw CoreDataMessagingMigratorError.failedToForceWALCheckpointing
        }
    }

    // MARK: - Helpers

    private func metadataForPersistentStore(at storeURL: URL) throws -> [String: Any] {
        if #available(iOS 15.0, *) {
            return try NSPersistentStoreCoordinator.metadataForPersistentStore(type: persistentStoreType, at: storeURL)
        } else {
            return try NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: storeType, at: storeURL)
        }
    }

    private func compatibleVersionForStoreMetadata(_ metadata: [String: Any]) -> CoreDataMessagingMigrationVersion? {
        let allVersions = CoreDataMessagingMigrationVersion.allCases
        let compatibleVersion = allVersions.first {
            guard let url = $0.managedObjectModelURL() else {
                return false
            }

            let model = NSManagedObjectModel(contentsOf: url)
            return model?.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) == true
        }

        return compatibleVersion
    }

    // MARK: - NSPersistentStoreCoordinator File Managing

    private func replaceStore(at targetURL: URL, withStoreAt sourceURL: URL) throws {
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
            try persistentStoreCoordinator.replacePersistentStore(
                at: targetURL,
                destinationOptions: nil,
                withPersistentStoreFrom: sourceURL,
                sourceOptions: nil,
                ofType: storeType
            )
        } catch {
            throw CoreDataMessagingMigratorError.failedToReplacePersistentStore(sourceURL: sourceURL, targetURL: targetURL)
        }
    }

    private func destroyStore(at storeURL: URL) throws {
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
            try persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: storeType, options: nil)
        } catch {
            throw CoreDataMessagingMigratorError.failedToDestroyPersistentStore(storeURL: storeURL)
        }
    }
}
