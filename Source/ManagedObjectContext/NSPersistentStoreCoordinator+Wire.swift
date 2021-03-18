//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

extension NSPersistentStoreCoordinator {
    
    /// Creates a filesystem-based persistent store at the given url with the given model
    convenience init (
        storeFile: URL,
        accountIdentifier: UUID?,
        applicationContainer: URL,
        model: NSManagedObjectModel,
        startedMigrationCallback: (() -> Void)?) throws {

        self.init(managedObjectModel: model)
        var migrationStarted = false
        func notifyMigrationStarted() -> () {
            if !migrationStarted {
                migrationStarted = true
                startedMigrationCallback?()
            }
        }
        
        if let accountIdentifier = accountIdentifier {
            MainPersistentStoreRelocator.moveLegacyStoreIfNecessary(storeFile: storeFile,
                                                                    accountIdentifier: accountIdentifier,
                                                                    applicationContainer: applicationContainer,
                                                                    startedMigrationCallback: startedMigrationCallback)
        }
        
        let containingFolder = storeFile.deletingLastPathComponent()
        FileManager.default.createAndProtectDirectory(at: containingFolder)

        try self.addPersistentStore(at: storeFile,
                                    model: model,
                                    startedMigrationCallback: notifyMigrationStarted)
    }

    private func addPersistentStore(at storeURL: URL,
                                    model: NSManagedObjectModel,
                                    startedMigrationCallback: () -> Void) throws {
        if NSPersistentStoreCoordinator.shouldMigrateStoreToNewModelVersion(at: storeURL,
                                                                            model: model) {
            startedMigrationCallback()
            try self.migrateAndAddPersistentStore(url: storeURL)
        } else {
            try self.addPersistentStoreWithNoMigration(at: storeURL)
        }
    }
    
    /// Creates an in memory persistent store coordinator with the given model
    convenience init(inMemoryWithModel model: NSManagedObjectModel) {
        self.init(managedObjectModel: model)
        do {
            try self.addPersistentStore(
                ofType: NSInMemoryStoreType,
                configurationName: nil,
                at: nil,
                options: nil)
        } catch {
            fatal("Unable to create in-memory Core Data store: \(error)")
        }
    }
    
    /// Adds the persistent store
    fileprivate func addPersistentStoreWithNoMigration(at url: URL) throws {
        let options = NSPersistentStoreCoordinator.persistentStoreOptions(supportsMigration: false)
        try self.addPersistentStore(ofType: NSSQLiteStoreType,
                                    configurationName: nil,
                                    at: url,
                                    options: options)
    }    
}

extension NSPersistentStoreCoordinator {
    
    /// Check if the store should be migrated (as opposed to discarded) based on model versions
    @objc(shouldMigrateStoreToNewModelVersionAtURL:withModel:)
    static func shouldMigrateStoreToNewModelVersion(at url: URL, model: NSManagedObjectModel) -> Bool {
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            // Store doesn't exist yet so no need to migrate it.
            return false
        }
        
        let metadata = self.metadataForStore(at: url)
        guard let oldModelVersion = metadata.managedObjectModelVersionIdentifier else {
            return false // if we have no version, we better wipe
        }
        
        // Between non-E2EE and E2EE we should not migrate the DB for privacy reasons.
        // We know that the old mom is a version supporting E2EE when it
        // contains the 'ClientMessage' entity or is at least of version 1.25
        if metadata.managedObjectModelEntityNames.contains(ZMClientMessage.entityName()) {
            return true
        }
        
        let atLeastVersion1_25 = (oldModelVersion as NSString).compare("1.25", options: .numeric) != .orderedAscending
        
        // Unfortunately the 1.24 Release has a mom version of 1.3 but we do not want to migrate from it
        return atLeastVersion1_25 && oldModelVersion != "1.3"
    }
    
    
    /// Retrieves the metadata for the store
    fileprivate static func metadataForStore(at url: URL) -> [String: Any] {
        guard
            FileManager.default.fileExists(atPath: url.path),
            let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: url) else {
            return [:]
        }
        return metadata
    }
    
    /// Performs a migration, crashes if failed
    fileprivate func migrateAndAddPersistentStore(url: URL) throws {
        let options = NSPersistentStoreCoordinator.persistentStoreOptions(supportsMigration: true)
        _ = try self.addPersistentStore(
            ofType: NSSQLiteStoreType,
            configurationName: nil,
            at: url,
            options: options)
    }
 
    /// Returns the set of options that need to be passed to the persistent sotre
    static func persistentStoreOptions(supportsMigration: Bool) -> [String: Any] {
        return [
            // https://www.sqlite.org/pragma.html
            NSSQLitePragmasOption: [
                "journal_mode" : "WAL",
                "synchronous": "FULL",
                "secure_delete" : "TRUE"
            ],
            NSMigratePersistentStoresAutomaticallyOption: supportsMigration,
            NSInferMappingModelAutomaticallyOption: supportsMigration
        ]
    }
}

extension Dictionary where Key == String {
    
    fileprivate var managedObjectModelVersionIdentifier: String? {
        guard let versions = self[NSStoreModelVersionIdentifiersKey] as? [String] else { return nil }
        return versions.first
    }
    
    fileprivate var managedObjectModelEntityNames: Set<String> {
        guard let entities = self[NSStoreModelVersionHashesKey] as? [String : Any] else { return [] }
        return Set(entities.keys)
    }
}

extension NSManagedObjectModel {
    
    var firstVersionIdentifier: String {
        return self.versionIdentifiers.first! as! String
    }
}
