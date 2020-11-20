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
import CoreData
import UIKit

/// Singleton to manage the creation of the CoreData stack
@objcMembers public class StorageStack: NSObject {
    
    /// Root folder for account specific data
    fileprivate static let accountDataFolder = "AccountData"
    
    /// In-memory stores. These are mainly used for testing
    private var inMemoryStores: [String: ManagedObjectContextDirectory] = [:]
    
    fileprivate static var currentStack: StorageStack?
    private static let singletonQueue = DispatchQueue(label: "SharedStorageStack")
    /// Singleton instance
    public static var shared: StorageStack {
        singletonQueue.sync {
            currentStack = currentStack ?? StorageStack()
        }
        return currentStack!
    }
    
    /// Created managed object context directory. If I don't retain it here, it will
    /// eventually de-init and call the tear down of the contexes at the wrong time,
    /// even if someone is still holding on to it
    private var managedObjectContextDirectory: ManagedObjectContextDirectory?
    
    /// Whether the next storage should be create as in memory instead of on disk.
    /// This is mostly useful for testing.
    public var createStorageAsInMemory: Bool = false

    private let isolationQueue = DispatchQueue(label: "StorageStack")
    
    /// Attempts to access the legacy store and fetch the user ID of the self user.
    /// - parameter completionHandler: this callback is invoked with the user ID, if it exists, else nil.
    @objc public func fetchUserIDFromLegacyStore(
        applicationContainer: URL,
        startedMigrationCallback: (() -> Void)? = nil,
        completionHandler: @escaping (UUID?) -> Void
        )
    {
        guard let oldLocation = MainPersistentStoreRelocator.exisingLegacyStore(applicationContainer: applicationContainer, accountIdentifier: nil) else {
            completionHandler(nil)
            return
        }
        
        isolationQueue.async {
            
            NSPersistentStoreCoordinator.create(storeFile: oldLocation, applicationContainer: applicationContainer)
            { psc in
                DispatchQueue.main.async {
                    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
                    context.persistentStoreCoordinator = psc
                    completionHandler(ZMUser.selfUser(in: context).remoteIdentifier)
                }
            }

        }
    }
    
    /// Creates a managed object context directory in an asynchronous fashion.
    /// This method should be invoked from the main queue, and the callback will be dispatched on the main queue.
    /// This method should not be called again before any previous invocation completion handler has been called.
    /// - parameter completionHandler: this callback is invoked on the main queue.
    /// - parameter accountIdentifier: user identifier that the store should be created for
    /// - parameter container: the shared container for the app
    @objc(createManagedObjectContextDirectoryForAccountIdentifier:applicationContainer:dispatchGroup:startedMigrationCallback:completionHandler:)
    public func createManagedObjectContextDirectory(
        accountIdentifier: UUID,
        applicationContainer: URL,
        dispatchGroup: ZMSDispatchGroup? = nil,
        startedMigrationCallback: (() -> Void)? = nil,
        completionHandler: @escaping (ManagedObjectContextDirectory) -> Void
        )
    {
        if #available(iOSApplicationExtension 12.0, *) {
            ExtendedSecureUnarchiveFromData.register()
        }
        
        let accountDirectory = StorageStack.accountFolder(accountIdentifier: accountIdentifier, applicationContainer: applicationContainer)
        FileManager.default.createAndProtectDirectory(at: accountDirectory)
        
        if self.createStorageAsInMemory {
            // we need to reuse the exitisting contexts if we already have them,
            // otherwise when testing logout / login we loose all data.
            if let managedObjectContextDirectory = self.inMemoryStores[accountDirectory.path] {
                completionHandler(managedObjectContextDirectory)
            } else {
                let managedObjectContextDirectory = InMemoryStoreInitialization.createManagedObjectContextDirectory(
                    accountDirectory: accountDirectory,
                    dispatchGroup: dispatchGroup,
                    applicationContainer: applicationContainer
                )
                self.inMemoryStores[accountDirectory.path] = managedObjectContextDirectory
                completionHandler(managedObjectContextDirectory)
            }
        } else {
            let storeFile = accountDirectory.appendingPersistentStoreLocation()
            isolationQueue.async {
                self.createOnDiskStack(
                    accountIdentifier: accountIdentifier,
                    accountDirectory: accountDirectory,
                    storeFile: storeFile,
                    applicationContainer: applicationContainer,
                    migrateIfNeeded: true,
                    dispatchGroup: dispatchGroup,
                    startedMigrationCallback: {
                        DispatchQueue.main.async {
                            startedMigrationCallback?()
                        }
                    },
                    completionHandler: { [weak self] mocs in
                        self?.managedObjectContextDirectory = mocs
                        DispatchQueue.main.async {
                            completionHandler(mocs)
                        }
                    }
                )
            }
        }
    }
    
    public func needsToRelocateOrMigrateLocalStack(accountIdentifier: UUID, applicationContainer: URL) -> Bool {
        guard !self.createStorageAsInMemory else { return false }
        let accountDirectory = StorageStack.accountFolder(accountIdentifier: accountIdentifier, applicationContainer: applicationContainer)
        let storeFile = accountDirectory.appendingPersistentStoreLocation()
        if MainPersistentStoreRelocator.needsToMoveLegacyStore(storeFile: storeFile, accountIdentifier: accountIdentifier, applicationContainer: applicationContainer) {
            return true
        }
        let model = NSManagedObjectModel.loadModel()
        return NSPersistentStoreCoordinator.shouldMigrateStoreToNewModelVersion(at: storeFile, model: model)
    }

    /// Creates a managed object context directory on disk
    func createOnDiskStack(
        accountIdentifier: UUID,
        accountDirectory: URL,
        storeFile: URL,
        applicationContainer: URL,
        migrateIfNeeded: Bool,
        dispatchGroup: ZMSDispatchGroup? = nil,
        startedMigrationCallback: (() -> Void)? = nil,
        completionHandler: @escaping (ManagedObjectContextDirectory) -> Void
        )
    {
        NSPersistentStoreCoordinator.createAndMigrate(
            storeFile: storeFile,
            accountIdentifier: accountIdentifier,
            accountDirectory: accountDirectory,
            applicationContainer: applicationContainer,
            startedMigrationCallback: startedMigrationCallback)
        { psc in
            let directory = ManagedObjectContextDirectory(
                persistentStoreCoordinator: psc,
                accountDirectory: accountDirectory,
                applicationContainer: applicationContainer,
                dispatchGroup: dispatchGroup)
            MemoryReferenceDebugger.register(directory)

            completionHandler(directory)
        }
    }
    
    /// Resets the stack. After calling this, the stack is ready to be reinitialized.
    /// Using a ManagedObjectContextDirectory created by a stack after the stack has been
    /// reset will cause a crash
    public static func reset() {
        StorageStack.currentStack?.managedObjectContextDirectory?.tearDown()
        StorageStack.currentStack = nil
    }
}

public extension StorageStack {
    
    /// Returns the URL that holds the data for the given account
    /// It will be in the format <application container>/AccountData/<account identifier>
    @objc static func accountFolder(accountIdentifier: UUID, applicationContainer: URL) -> URL {
        return applicationContainer
            .appendingPathComponent(StorageStack.accountDataFolder)
            .appendingPathComponent(accountIdentifier.uuidString)
    }
}

public extension URL {
    
    /// Returns the location of the persistent store file in the given account folder
    func appendingPersistentStoreLocation() -> URL {
        return self.appendingPathComponent("store").appendingStoreFile()
    }
}

public extension NSURL {

    /// Returns the location of the persistent store file in the given account folder
    @objc func URLAppendingPersistentStoreLocation() -> URL {
        return (self as URL).appendingPersistentStoreLocation()
    }
}
