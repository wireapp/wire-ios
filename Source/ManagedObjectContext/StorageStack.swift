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
@objc public class StorageStack: NSObject {
    
    /// In-memory stores. These are mainly used for testing
    private var inMemoryStores: [String: ManagedObjectContextDirectory] = [:]
    
    /// Singleton instance
    public private(set) static var shared = StorageStack()
    
    /// Directory of managed object contexes
    public var managedObjectContextDirectory: ManagedObjectContextDirectory? = nil
    
    /// Whether the next storage should be create as in memory instead of on disk.
    /// This is mostly useful for testing.
    public var createStorageAsInMemory: Bool = false

    private let isolationQueue = DispatchQueue(label: "StorageStack")

    /// Persistent store currently being initialized
    private var currentPersistentStoreInitialization: PersistentStorageInitialization? = nil
    
    /// Attempts to access the legacy store and fetch the user ID of the self user.
    /// - parameter completionHandler: this callback is invoked with the user ID, if it exists, else nil.
    @objc public func fetchUserIDFromLegacyStore(
        applicationContainer: URL,
        startedMigrationCallback: (() -> Void)? = nil,
        completionHandler: @escaping (UUID?) -> Void
        )
    {
        guard let oldLocation = MainPersistentStoreRelocator.exisingLegacyStore(applicationContainer: applicationContainer) else {
            completionHandler(nil)
            return
        }
        
        self.currentPersistentStoreInitialization = PersistentStorageInitialization()
        isolationQueue.async {
            self.currentPersistentStoreInitialization?.createPersistentStoreCoordinator(storeFile: oldLocation,
                                                                                        applicationContainer: applicationContainer,
                                                                                        migrateIfNeeded: false,
                                                                                        startedMigrationCallback: nil)
            { [weak self] psc in
                DispatchQueue.main.async {
                    self?.currentPersistentStoreInitialization = nil
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
                    accountDirectory: accountDirectory,
                    storeFile: storeFile,
                    applicationContainer: applicationContainer,
                    migrateIfNeeded: true,
                    startedMigrationCallback: {
                        DispatchQueue.main.async {
                            startedMigrationCallback?()
                        }
                    },
                    completionHandler: { mocs in
                        DispatchQueue.main.async {
                            completionHandler(mocs)
                        }
                    }
                )
            }
        }
    }

    /// Creates a managed object context directory on disk
    func createOnDiskStack(
        accountDirectory: URL,
        storeFile: URL,
        applicationContainer: URL,
        migrateIfNeeded: Bool,
        startedMigrationCallback: (() -> Void)? = nil,
        completionHandler: @escaping (ManagedObjectContextDirectory) -> Void
        )
    {
        guard self.currentPersistentStoreInitialization == nil else {
            fatal("Trying to create a new store before a previous one is done creating")
        }
        
        self.currentPersistentStoreInitialization = PersistentStorageInitialization()
        self.currentPersistentStoreInitialization?.createPersistentStoreCoordinator(
            storeFile: storeFile,
            applicationContainer: applicationContainer,
            migrateIfNeeded: migrateIfNeeded,
            startedMigrationCallback: startedMigrationCallback)
        { [weak self] psc in
            self?.currentPersistentStoreInitialization = nil // need to hold a reference, see `PersistentStorageInitialization.createPersistentStoreCoordinator`
            let directory = ManagedObjectContextDirectory(
                persistentStoreCoordinator: psc,
                accountDirectory: accountDirectory,
                applicationContainer: applicationContainer)
            self?.managedObjectContextDirectory = directory
            completionHandler(directory)
        }
    }
    
    /// Resets the stack. After calling this, the stack is ready to be reinitialized.
    /// Using a ManagedObjectContextDirectory created by a stack after the stack has been
    /// reset will cause a crash
    public static func reset() {
        StorageStack.shared = StorageStack()
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
        return managedObjectContextDirectory
    }
}


/// Creates a persistent store CoreData stack
class PersistentStorageInitialization {
    
    fileprivate init() {}
    
    /// Observer token for application becoming available
    fileprivate var applicationProtectedDataDidBecomeAvailableObserver: Any? = nil
    
    /// Creates a filesystem-backed persistent store coordinator with the model contained in this bundle
    /// The caller should hold on to the returned instance until the `completionHandler` is invoked.
    /// If not, the callback might end up not being invoked.
    /// The callback will be invoked on an arbitrary queue.
    fileprivate func createPersistentStoreCoordinator(
        storeFile: URL,
        applicationContainer: URL,
        migrateIfNeeded: Bool,
        startedMigrationCallback: (() -> Void)?,
        completionHandler: @escaping (NSPersistentStoreCoordinator) -> Void
        ) {
        
        let model = NSManagedObjectModel.loadModel()
        let creation: (Void) -> NSPersistentStoreCoordinator = {
            NSPersistentStoreCoordinator(
                storeFile: storeFile,
                applicationContainer: applicationContainer,
                migrateIfNeeded: migrateIfNeeded,
                model: model,
                startedMigrationCallback: startedMigrationCallback
             )
        }
        
        // We need to handle the case when the database file is encrypted by iOS and user never entered the passcode
        // We use default core data protection mode NSFileProtectionCompleteUntilFirstUserAuthentication
        if PersistentStorageInitialization.databaseExistsButIsNotReadableDueToEncryption(at: storeFile) {
            self.executeOnceFileSystemIsUnlocked {
                completionHandler(creation())
            }
        } else {
            let psc = creation()
            completionHandler(psc)
        }
    }
    
    /// Listen for the notification for when first authentication has been completed
    /// (c.f. `NSFileProtectionCompleteUntilFirstUserAuthentication`). Once it's available, it will
    /// execute the closure
    private func executeOnceFileSystemIsUnlocked(execute block: @escaping ()->()) {
        
        // This happens when
        // (1) User has passcode enabled
        // (2) User turns the phone on, but do not enter the passcode yet
        // (3) App is awake on the background due to VoIP push notification
        
        guard self.applicationProtectedDataDidBecomeAvailableObserver == nil else {
            fatal("Was already waiting on file system unlock?")
        }
        
        NotificationCenter.default.addObserver(
            forName: .UIApplicationProtectedDataDidBecomeAvailable,
            object: nil,
            queue: nil) { [weak self] _ in
                guard let `self` = self else { return }
                if let token = self.applicationProtectedDataDidBecomeAvailableObserver {
                    NotificationCenter.default.removeObserver(token)
                }
                self.applicationProtectedDataDidBecomeAvailableObserver = nil
                block()
        }
    }
    
    /// Check if the database is created, but still locked (potentially due to file system protection)
    private static func databaseExistsButIsNotReadableDueToEncryption(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else { return false }
        return (try? FileHandle(forReadingFrom: url)) == nil
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

public extension StorageStack {
    
    /// Returns the URL that holds the data for the given account
    /// It will be in the format <application container>/<bundle ID>/<account identifier>
    @objc public static func accountFolder(accountIdentifier: UUID, applicationContainer: URL) -> URL {
        
        guard let bundleId = Bundle.main.bundleIdentifier ?? Bundle(for: ZMUser.self).bundleIdentifier else {
            fatal("No bundle??")
        }
        
        return applicationContainer
            .appendingPathComponent(bundleId)
            .appendingPathComponent(accountIdentifier.uuidString)
    }
}

public extension URL {
    
    /// Returns the location of the persistent store file in the given account folder
    public func appendingPersistentStoreLocation() -> URL {
        return self.appendingPathComponent("store").appendingStoreFile()
    }
}

public extension NSURL {

    /// Returns the location of the persistent store file in the given account folder
    @objc public func URLAppendingPersistentStoreLocation() -> URL {
        return (self as URL).appendingPersistentStoreLocation()
    }
}
