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

/// List of context
@objc public class ManagedObjectContextDirectory: NSObject {
    
    init(persistentStoreCoordinator: NSPersistentStoreCoordinator, forAccountWith accountIdentifier: UUID?,
         inContainerAt containerUrl: URL) {
        // TODO Sabine
        //self.storeURL = store
        //self.keyStoreURL = keyStore
        self.uiContext = ManagedObjectContextDirectory.createUIManagedObjectContext(persistentStoreCoordinator: persistentStoreCoordinator)
        self.syncContext = ManagedObjectContextDirectory.createSyncManagedObjectContext(persistentStoreCoordinator: persistentStoreCoordinator,
                                                                                        forAccountWith: accountIdentifier,
                                                                                        inContainerAt: containerUrl)
        self.searchContext = ManagedObjectContextDirectory.createSearchManagedObjectContext(persistentStoreCoordinator: persistentStoreCoordinator)
        super.init()
    }

    // TODO Sabine
    //public let storeURL: URL
    //public let keyStoreURL: URL
    
    /// User interface context. It can be used only from the main queue
    public let uiContext: NSManagedObjectContext
    
    /// Local storage and network synchronization context. It can be used only from its private queue.
    /// This context track changes to its objects and synchronizes them from/to the backend.
    public let syncContext: NSManagedObjectContext
    
    /// Search context. It can be used only from its private queue.
    /// This context is used to perform searches, not to slow down or insert temporary results in the
    /// sync context.
    public let searchContext: NSManagedObjectContext
    
    deinit {
        // TODO Silvan: Test that it tears down
        self.uiContext.tearDown()
        self.syncContext.tearDown()
        self.searchContext.tearDown()
    }
}

extension ManagedObjectContextDirectory {
    
    fileprivate static func createUIManagedObjectContext(
        persistentStoreCoordinator: NSPersistentStoreCoordinator) -> NSManagedObjectContext {
        
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.performAndWait {
            moc.markAsUIContext()
            moc.configure(with: persistentStoreCoordinator)
            ZMUser.selfUser(in: moc)
        }
        moc.mergePolicy = ZMSyncMergePolicy(merge: .rollbackMergePolicyType)
        return moc
    }
    
    fileprivate static func createSyncManagedObjectContext(
        persistentStoreCoordinator: NSPersistentStoreCoordinator,
        forAccountWith accountIdentifier: UUID?,
        inContainerAt containerUrl: URL) -> NSManagedObjectContext {
        
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.markAsSyncContext()
        moc.performAndWait {
            moc.configure(with: persistentStoreCoordinator)
            moc.setupLocalCachedSessionAndSelfUser()
            moc.setupUserKeyStore(in: containerUrl, for: accountIdentifier)
            moc.undoManager = nil
            moc.mergePolicy = ZMSyncMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
            
        }
        
        // this will be done async, not to block the UI thread, but
        // enqueued on the syncMOC anyway, so it will execute before
        // any other block of code has a chance to use it
        moc.performGroupedBlock {
            moc.applyPersistedDataPatchesForCurrentVersion()
        }
        return moc
    }
 
    fileprivate static func createSearchManagedObjectContext(
        persistentStoreCoordinator: NSPersistentStoreCoordinator) -> NSManagedObjectContext {
        
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.markAsSearch()
        moc.performAndWait {
            moc.configure(with: persistentStoreCoordinator)
            moc.setupLocalCachedSessionAndSelfUser()
            moc.undoManager = nil
            moc.mergePolicy = ZMSyncMergePolicy(merge: .rollbackMergePolicyType)
        }
        return moc
    }
}

extension NSManagedObjectContext {
    
    fileprivate func configure(with persistentStoreCoordinator: NSPersistentStoreCoordinator) {
        self.createDispatchGroups()
        self.persistentStoreCoordinator = persistentStoreCoordinator
    }
    
    // This function setup the user info on the context, the session and self user must be initialised before end.
    fileprivate func setupLocalCachedSessionAndSelfUser() {
        let session = self.executeFetchRequestOrAssert(ZMSession.sortedFetchRequest()).first as! ZMSession
        self.userInfo[SessionObjectIDKey] = session.objectID
        ZMUser.boxSelfUser(session.selfUser, inContextUserInfo: self)
    }
}
