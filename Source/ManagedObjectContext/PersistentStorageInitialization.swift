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
import WireSystem

extension NSPersistentStoreCoordinator {
    
    /// Creates a filesystem-backed persistent store coordinator with the model contained in this bundle
    /// The callback will be invoked on an arbitrary queue.
    static func create(
        storeFile: URL,
        applicationContainer: URL,
        completionHandler: @escaping (NSPersistentStoreCoordinator) -> Void
        ) {
        
        PersistentStorageInitialization.executeWhenFileIsAccessible(storeFile) {
            let model = NSManagedObjectModel.loadModel()
            completionHandler(NSPersistentStoreCoordinator(
                storeFile: storeFile,
                accountIdentifier: nil,
                applicationContainer: applicationContainer,
                model: model,
                startedMigrationCallback: nil
            ))
        }
    }
    
    /// Creates a filesystem-backed persistent store coordinator with the model contained in this bundle and migrates
    /// the legacy store and keystore if they exist. The callback will be invoked on an arbitrary queue.
    static func createAndMigrate(
        storeFile: URL,
        accountIdentifier: UUID,
        accountDirectory: URL,
        applicationContainer: URL,
        startedMigrationCallback: (() -> Void)?,
        completionHandler: @escaping (NSPersistentStoreCoordinator) -> Void
        ) {
        
        PersistentStorageInitialization.executeWhenFileIsAccessible(storeFile) {
            let model = NSManagedObjectModel.loadModel()
            UserClientKeysStore.migrateIfNeeded(accountIdentifier: accountIdentifier, accountDirectory: accountDirectory, applicationContainer: applicationContainer)
            
            completionHandler(NSPersistentStoreCoordinator(
                storeFile: storeFile,
                accountIdentifier: accountIdentifier,
                applicationContainer: applicationContainer,
                model: model,
                startedMigrationCallback: startedMigrationCallback
            ))
        }
    }
}

/// Creates a persistent store CoreData stack
class PersistentStorageInitialization {
    
    fileprivate init() {}
    
    /// Observer token for application becoming available
    fileprivate var applicationProtectedDataDidBecomeAvailableObserver: Any! = nil
    
    fileprivate static func executeWhenFileIsAccessible(_ file: URL, usingBlock block: @escaping () -> Void) {
        // We need to handle the case when the database file is encrypted by iOS and user never entered the passcode
        // We use default core data protection mode NSFileProtectionCompleteUntilFirstUserAuthentication
        let storageInitialization = PersistentStorageInitialization()
        
        storageInitialization.applicationProtectedDataDidBecomeAvailableObserver = FileManager.default.executeWhenFileSystemIsAccessible { 
            storageInitialization.applicationProtectedDataDidBecomeAvailableObserver = nil
            block()
        }
    }
}

extension NSManagedObjectModel {
    /// Loads the CoreData model from the current bundle
    @objc public static func loadModel() -> NSManagedObjectModel {
        let modelBundle = Bundle(for: ZMManagedObject.self)
        guard let result = NSManagedObjectModel.mergedModel(from: [modelBundle]) else {
            fatal("Can't load data model bundle")
        }
        return result
    }
}

/// Creates an in memory stack CoreData stack
class InMemoryStoreInitialization {
    
    static func createManagedObjectContextDirectory(
        accountDirectory: URL,
        dispatchGroup: ZMSDispatchGroup? = nil,
        applicationContainer: URL) -> ManagedObjectContextDirectory
        
    {
        let model = NSManagedObjectModel.loadModel()
        let psc = NSPersistentStoreCoordinator(inMemoryWithModel: model)
        let managedObjectContextDirectory = ManagedObjectContextDirectory(
            persistentStoreCoordinator: psc,
            accountDirectory: accountDirectory,
            applicationContainer: applicationContainer,
            dispatchGroup: dispatchGroup
        )
        MemoryReferenceDebugger.register(managedObjectContextDirectory)
        return managedObjectContextDirectory
    }
}

