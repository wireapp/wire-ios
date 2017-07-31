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
    
    /// Singleton instance
    public private(set) static var shared = StorageStack()
    
    /// Directory of managed object contexes
    public var managedObjectContextDirectory: ManagedObjectContextDirectory? = nil
    
    /// Whether the next storage should be create as in memory instead of on disk.
    /// This is mostly useful for testing.
    public var createStorageAsInMemory: Bool = false

    private var url: URL?

    public var storeExists: Bool {
        guard let storeURL = url else { return false }
        return FileManager.default.fileExists(atPath: storeURL.path)
            || (managedObjectContextDirectory != nil && createStorageAsInMemory)
    }

    /// Persistent store currently being initialized
    private var currentPersistentStoreInitialization: PersistentStorageInitialization? = nil
    
    /// Creates a managed object context directory in an asynchronous fashion.
    /// This method should be invoked from the main queue, and the callback will be dispatched on the main queue.
    /// This method should not be called again before any previous invocation completion handler has been called.
    /// - parameter completionHandler: this callback is invoked on the main queue. It is responsibility
    ///     of the caller to switch back to the same queue that this method was invoked on.
    @objc public func createManagedObjectContextDirectory(
        forAccountWith accountIdentifier: UUID?,
        inContainerAt containerUrl: URL,
        startedMigrationCallback: (() -> Void)? = nil,
        completionHandler: @escaping (ManagedObjectContextDirectory) -> Void
        )
    {
        guard self.currentPersistentStoreInitialization == nil else {
            fatal("Trying to create a new store before a previous one is done creating")
        }

        self.url = FileManager.currentStoreURLForAccount(with: accountIdentifier, in: containerUrl)

        // destroy previous stack if any
        if self.createStorageAsInMemory {
            let directory = InMemoryStoreInitialization.createManagedObjectContextDirectory(forAccountWith: accountIdentifier, inContainerAt: containerUrl)
            self.managedObjectContextDirectory = directory
            completionHandler(directory)
        } else {
            self.currentPersistentStoreInitialization = PersistentStorageInitialization.createManagedObjectContextDirectory(
                forAccountWith: accountIdentifier,
                inContainerAt: containerUrl,
                startedMigrationCallback: startedMigrationCallback)
            { [weak self] directory in
                DispatchQueue.main.async {
                    self?.currentPersistentStoreInitialization = nil
                    self?.managedObjectContextDirectory = directory
                    completionHandler(directory)
                }
            }
        }
    }
    
    /// Resets the stack. After calling this, the stack is ready to be reinitialized.
    public static func reset() {
        StorageStack.shared = StorageStack()
    }
    
}

/// Creates an in memory stack CoreData stack
class InMemoryStoreInitialization {

    @objc public static func createManagedObjectContextDirectory(forAccountWith accountIdentifier: UUID?,
                                                           inContainerAt containerUrl: URL) -> ManagedObjectContextDirectory
    {
        let model = NSManagedObjectModel.loadModel()
        let psc = NSPersistentStoreCoordinator(inMemoryWithModel: model)
        let managedObjectContextDirectory = ManagedObjectContextDirectory(
            persistentStoreCoordinator: psc,
            forAccountWith: accountIdentifier,
            inContainerAt: containerUrl
        )
        return managedObjectContextDirectory
    }
}


/// Creates a persistent store CoreData stack
class PersistentStorageInitialization {
    
    private init() {}
    
    /// Observer token for application becoming available
    fileprivate var applicationProtectedDataDidBecomeAvailableObserver: Any? = nil
    
    /// The caller should hold on to the returned instance
    /// until the `completionHandler` is invoked. 
    /// If not, the callback might end up not being invoked.
    fileprivate static func createManagedObjectContextDirectory(
        forAccountWith accountIdentifier: UUID?,
        inContainerAt containerUrl: URL,
        startedMigrationCallback: (() -> Void)?,
        completionHandler: @escaping (ManagedObjectContextDirectory) -> Void
    ) -> PersistentStorageInitialization {
        let initialization = PersistentStorageInitialization()
        DispatchQueue(label: "Store creation").async { [weak initialization] in
            guard let initialization = initialization else { return }
            initialization.createPersistentStoreAndContexes(
                forAccountWith: accountIdentifier,
                inContainerAt: containerUrl,
                startedMigrationCallback: startedMigrationCallback,
                completionHandler: completionHandler
            )
        }
        return initialization
    }
    
    fileprivate func createPersistentStoreAndContexes(
        forAccountWith accountIdentifier: UUID?,
        inContainerAt containerUrl: URL,
        startedMigrationCallback: (() -> Void)?,
        completionHandler: @escaping (ManagedObjectContextDirectory) -> Void)
    {
        let model = NSManagedObjectModel.loadModel()
        self.createPersistentStoreCoordinator(
            forAccountWith: accountIdentifier,
            inContainerAt: containerUrl,
            model: model,
            startedMigrationCallback: startedMigrationCallback
            ) { psc in
                let mocDirectory = ManagedObjectContextDirectory(
                    persistentStoreCoordinator: psc,
                    forAccountWith: accountIdentifier,
                    inContainerAt: containerUrl)
                completionHandler(mocDirectory)
        }
        
    }
}

// MARK: Initialization
extension PersistentStorageInitialization {
    
    /// Creates a filesystem-backed persistent store coordinator with the model contained in this bundle
    fileprivate func createPersistentStoreCoordinator(
        forAccountWith accountIdentifier: UUID?,
        inContainerAt containerUrl: URL,
        model: NSManagedObjectModel,
        startedMigrationCallback: (() -> Void)?,
        completionHandler: @escaping (NSPersistentStoreCoordinator) -> Void
        ) {
        
        let creation: (Void) -> NSPersistentStoreCoordinator = {
            NSPersistentStoreCoordinator(forAccountWith: accountIdentifier,
                                         inContainerAt: containerUrl,
                                         model: model,
                                         startedMigrationCallback: startedMigrationCallback
                                         )
        }
        
        let storeURL = FileManager.currentStoreURLForAccount(with: accountIdentifier, in: containerUrl)
        // We need to handle the case when the database file is encrypted by iOS and user never entered the passcode
        // We use default core data protection mode NSFileProtectionCompleteUntilFirstUserAuthentication
        if PersistentStorageInitialization.databaseExistsButIsNotReadableDueToEncryption(at: storeURL) {
            self.executeOnceFileSystemIsUnlocked {
                completionHandler(creation())
            }
        } else {
            let store = creation()
            completionHandler(store)
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

