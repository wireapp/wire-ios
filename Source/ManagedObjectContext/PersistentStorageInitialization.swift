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

private let log = ZMSLog(tag: "NSPersistentStoreCoordinator")

extension NSPersistentStoreCoordinator {
    
    /// Creates a filesystem-backed persistent store coordinator with the model contained in this bundle
    /// The callback will be invoked on an arbitrary queue.
    static func create(storeFile: URL,
                       applicationContainer: URL) throws -> NSPersistentStoreCoordinator? {

        var persistentStoreCoordinator: NSPersistentStoreCoordinator?

        do {
            let model = NSManagedObjectModel.loadModel()
            persistentStoreCoordinator = try NSPersistentStoreCoordinator(storeFile: storeFile,
                                                                          accountIdentifier: nil,
                                                                          applicationContainer: applicationContainer,
                                                                          model: model,
                                                                          startedMigrationCallback: nil)
        } catch let error {
            log.debug("Error to create the NSPersistentStoreCoordinator: \(error)")
        }

        return persistentStoreCoordinator
    }
    
    /// Creates a filesystem-backed persistent store coordinator with the model contained in this bundle and migrates
    /// the legacy store and keystore if they exist. The callback will be invoked on an arbitrary queue.
    static func createAndMigrate(storeFile: URL,
                                 accountIdentifier: UUID,
                                 accountDirectory: URL,
                                 applicationContainer: URL,
                                 startedMigrationCallback: (() -> Void)?,
                                 databaseLoadingFailureCallBack: (() -> Void)?)  throws -> NSPersistentStoreCoordinator? {

        var persistentStoreCoordinator: NSPersistentStoreCoordinator?

        do {
            let model = NSManagedObjectModel.loadModel()
            UserClientKeysStore.migrateIfNeeded(accountIdentifier: accountIdentifier,
                                                accountDirectory: accountDirectory,
                                                applicationContainer: applicationContainer)

            persistentStoreCoordinator = try NSPersistentStoreCoordinator(storeFile: storeFile,
                                                                          accountIdentifier: accountIdentifier,
                                                                          applicationContainer: applicationContainer,
                                                                          model: model,
                                                                          startedMigrationCallback: startedMigrationCallback)
        } catch {
            databaseLoadingFailureCallBack?()
            log.debug("Error to create the NSPersistentStoreCoordinator: \(error)")
        }

        return persistentStoreCoordinator
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

