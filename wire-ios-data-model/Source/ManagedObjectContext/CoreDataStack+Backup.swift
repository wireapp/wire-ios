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

import Foundation
import WireLogging
import WireUtilities

private let log = ZMSLog(tag: "Backup")

public extension CoreDataStack {

    private static let metadataFilename = "export.json"
    private static let databaseDirectoryName = "data"
    private static let workQueue = DispatchQueue(label: "database backup", qos: .userInitiated)
    private static let fileManager = FileManager()

    // Each backup for any account will be created in a unique subdirectory inside.
    // Calling `clearBackupDirectory` will remove this directory and all backups.
    static var backupsDirectory: URL {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return tempURL.appendingPathComponent("backups")
    }

    // Directory in which unzipped backups should be places.
    // This directory is located inside of `backupsDirectory`.
    // Calling `clearBackupDirectory` will remove this directory.
    static var importsDirectory: URL {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return tempURL.appendingPathComponent("imports")
    }

    enum BackupImportError: Error {
        case incompatibleBackup(Error)
        case failedToCopy(Error)
        case missingModelVersion(String)
    }

    enum BackupError: Error {
        case failedToRead
        case failedToWrite(Error)
        case missingEARMigrator
    }

    struct BackupInfo {
        public let url: URL
        public let metadata: BackupMetadata
    }

    // Calling this method will delete all backups stored inside `backupsDirectory`
    // as well as inside `importsDirectory` if there are any.
    static func clearBackupDirectory(dispatchGroup: ZMSDispatchGroup) {
        func remove(at url: URL) {
            do {
                guard fileManager.fileExists(atPath: url.path) else { return }
                try fileManager.removeItem(at: url)
            } catch {
                log.debug("error removing directory: \(error)")
                WireLogger.localStorage.debug("backup: clearBackupDirectory got error removing directory: \(error)")
            }
        }

        workQueue.async(group: dispatchGroup) {
            remove(at: backupsDirectory)
            remove(at: importsDirectory)
        }
    }

    /// Will make a copy of account storage and place in a unique directory
    ///
    /// - Parameters:
    ///   - accountIdentifier: identifier of account being backed up
    ///   - applicationContainer: shared application container
    ///   - databaseKey: EAR database key
    ///
    ///   Returns: the folder where all data was written to.
    @MainActor
    static func backupLocalStorage(
        accountIdentifier: UUID,
        clientIdentifier: String,
        applicationContainer: URL,
        earMigrator: EARMigratorProtocol? = nil
    ) async throws -> BackupInfo {
        let accountDirectory = Self.accountDataFolder(
            accountIdentifier: accountIdentifier,
            applicationContainer: applicationContainer
        )
        let storeFile = accountDirectory.appendingPersistentStoreLocation()

        guard fileManager.fileExists(atPath: accountDirectory.path) else {
            throw BackupError.failedToRead
        }

        let backupDirectory = backupsDirectory.appendingPathComponent(UUID().uuidString)
        let databaseDirectory = backupDirectory.appendingPathComponent(databaseDirectoryName)
        let metadataURL = backupDirectory.appendingPathComponent(metadataFilename)

        let task = Task.detached {
            let model = CoreDataStack.loadMessagingModel()
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

            // Create target directory
            try fileManager.createDirectory(
                at: databaseDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            let backupLocation = databaseDirectory.appendingStoreFile()
            let options = NSPersistentStoreCoordinator.persistentStoreOptions(supportsMigration: false)

            // Recreate the persistent store inside a new location
            WireLogger.localStorage.debug("backup: Recreate the persistent store inside a new location")
            try coordinator.replacePersistentStore(
                at: backupLocation,
                destinationOptions: options,
                withPersistentStoreFrom: storeFile,
                sourceOptions: options,
                ofType: NSSQLiteStoreType
            )

            WireLogger.localStorage.debug("backup: prepareStoreForBackupExport")
            try prepareStoreForBackupExport(
                coordinator: coordinator,
                location: backupLocation,
                options: options,
                earMigrator: earMigrator
            )

            // Create & write metadata
            WireLogger.localStorage.debug("backup: Create & write metadata")
            let metadata = BackupMetadata(userIdentifier: accountIdentifier, clientIdentifier: clientIdentifier)
            try metadata.write(to: metadataURL)

            log.info("successfully created backup at: \(backupDirectory.path), metadata: \(metadata)")
            return BackupInfo(url: backupDirectory, metadata: metadata)
        }

        do {
            return try await task.value
        } catch {
            log.debug("error backing up local store: \(error)")
            throw BackupError.failedToWrite(error)
        }
    }

    /// Will import a backup for a given account
    ///
    /// - Parameters:
    ///   - accountIdentifier: account for which to import the backup
    ///   - backupDirectory: root directory of the decrypted and uncompressed backup
    ///   - applicationContainer: shared application container
    ///
    ///   Returns: the folder where all data was written to.
    @MainActor
    static func importLocalStorage(
        accountIdentifier: UUID,
        from backupDirectory: URL,
        applicationContainer: URL
    ) async throws -> URL {
        guard let activity = BackgroundActivityFactory.shared.startBackgroundActivity(name: "import backup") else {
            WireLogger.localStorage
                .error("backup: error backing up local store: \(CoreDataStackError.noDatabaseActivity)")
            log.debug("error backing up local store: \(CoreDataStackError.noDatabaseActivity)")
            throw CoreDataStackError.noDatabaseActivity
        }

        let result = try await importLocalStorage(
            accountIdentifier: accountIdentifier,
            from: backupDirectory,
            applicationContainer: applicationContainer,
            messagingMigrator: CoreDataMigrator<CoreDataMessagingMigrationVersion>(isInMemoryStore: false)
        )

        BackgroundActivityFactory.shared.endBackgroundActivity(activity)
        return result
    }

    @MainActor
    internal static func importLocalStorage(
        accountIdentifier: UUID,
        from backupDirectory: URL,
        applicationContainer: URL,
        messagingMigrator: CoreDataMessagingMigratorProtocol
    ) async throws -> URL {
        let accountDirectory = accountDataFolder(
            accountIdentifier: accountIdentifier,
            applicationContainer: applicationContainer
        )
        let accountStoreFile = accountDirectory.appendingPersistentStoreLocation()
        let backupStoreFile = backupDirectory.appendingPathComponent(databaseDirectoryName).appendingStoreFile()
        let metadataURL = backupDirectory.appendingPathComponent(metadataFilename)

        let task = Task.detached {
            let metadata: BackupMetadata
            do {
                metadata = try BackupMetadata(url: metadataURL)
            } catch {
                throw BackupImportError.failedToCopy(error)
            }
            let currentModel = CoreDataStack.loadMessagingModel()

            guard let backupModel = managedObjectModel(for: metadata.modelVersion) else {
                throw BackupImportError.missingModelVersion(metadata.modelVersion)
            }

            if let verificationError = metadata.verify(
                using: accountIdentifier,
                modelVersionProvider: currentModel
            ) {
                throw BackupImportError.incompatibleBackup(verificationError)
            }

            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: backupModel)

            do {
                // Create target directory
                try fileManager.createDirectory(
                    at: accountStoreFile.deletingLastPathComponent(),
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                let options = NSPersistentStoreCoordinator.persistentStoreOptions(supportsMigration: false)

                WireLogger.localStorage.debug("backup: import prepare", attributes: .safePublic)
                try prepareStoreForBackupImport(coordinator: coordinator, location: backupStoreFile, options: options)

                let tp = TimePoint(interval: 60.0, label: "db migration")
                WireLogger.localStorage
                    .debug("backup: migrate database \(metadata.modelVersion) to \(currentModel.version)")
                try messagingMigrator.migrateStore(at: backupStoreFile, toVersion: .current)
                if tp.warnIfLongerThanInterval() == false {
                    WireLogger.localStorage.info(
                        "time spent in migration only: \(tp.elapsedTime)",
                        attributes: .safePublic
                    )
                }

                // Import the persistent store to the account data directory
                WireLogger.localStorage.debug(
                    "backup: import the persistent store to the account data directory",
                    attributes: .safePublic
                )
                try coordinator.replacePersistentStore(
                    at: accountStoreFile,
                    destinationOptions: options,
                    withPersistentStoreFrom: backupStoreFile,
                    sourceOptions: options,
                    ofType: NSSQLiteStoreType
                )

                WireLogger.localStorage.info(
                    "successfully imported backup with metadata: \(metadata)",
                    attributes: .safePublic
                )

                return accountDirectory
            } catch {
                throw BackupImportError.failedToCopy(error)
            }
        }

        do {
            return try await task.value
        } catch {
            WireLogger.localStorage.error("backup: error backing up local store: \(error)", attributes: .safePublic)
            throw error
        }
    }

    private static func managedObjectModel(for dataModelVersion: String) -> NSManagedObjectModel? {
        let version = CoreDataMessagingMigrationVersion.allCases.first {
            $0.dataModelVersion == dataModelVersion
        }

        guard let modelURL = version?.managedObjectModelURL() else {
            return nil
        }

        return NSManagedObjectModel(contentsOf: modelURL)
    }

    // MARK: Prepare

    private static func prepareStoreForBackupExport(
        coordinator: NSPersistentStoreCoordinator,
        location: URL,
        options: [String: Any],
        earMigrator: EARMigratorProtocol?
    ) throws {
        // Add persistent store at the new location to allow creation of NSManagedObjectContext
        let store = try coordinator.addPersistentStore(
            type: .sqlite,
            configuration: nil,
            at: location,
            options: options
        )
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        try context.performGroupedAndWait {
            if context.encryptMessagesAtRest {
                guard let earMigrator else { throw BackupError.missingEARMigrator }
                try earMigrator.migrateAwayFromEncryptionAtRest(context: context)

                context.encryptMessagesAtRest = false
                _ = context.makeMetadataPersistent()
                try context.save()
            }
        }

        // Close the store, not doing so could lead to data loss when copying the store files.
        try coordinator.remove(store)
    }

    private static func prepareStoreForBackupImport(
        coordinator: NSPersistentStoreCoordinator,
        location: URL,
        options: [String: Any]
    ) throws {
        // Add persistent store at the new location to allow creation of NSManagedObjectContext
        let store = try coordinator.addPersistentStore(
            type: .sqlite,
            configuration: nil,
            at: location,
            options: options
        )
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        try context.performGroupedAndWait {
            context.prepareToImportBackup()
            try context.save()
        }

        // Close the store, not doing so could lead to data loss when copying the store files.
        try coordinator.remove(store)
    }

}
