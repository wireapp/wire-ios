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
@objcMembers
public class ManagedObjectContextDirectory: NSObject {
    
    init(persistentStoreCoordinator: NSPersistentStoreCoordinator,
         accountDirectory: URL,
         applicationContainer: URL,
         dispatchGroup: ZMSDispatchGroup? = nil) {
        self.uiContext = ManagedObjectContextDirectory.createUIManagedObjectContext(persistentStoreCoordinator: persistentStoreCoordinator, dispatchGroup: dispatchGroup)
        self.syncContext = ManagedObjectContextDirectory.createSyncManagedObjectContext(persistentStoreCoordinator: persistentStoreCoordinator,
                                                                                        accountDirectory: accountDirectory,
                                                                                        dispatchGroup: dispatchGroup,
                                                                                        applicationContainer: applicationContainer)
        MemoryReferenceDebugger.register(self.syncContext)
        self.searchContext = ManagedObjectContextDirectory.createSearchManagedObjectContext(persistentStoreCoordinator: persistentStoreCoordinator, dispatchGroup: dispatchGroup)
        MemoryReferenceDebugger.register(self.searchContext)
        super.init()
        configureManagedObjectContextReferences()
    }
    
    /// User interface context. It can be used only from the main queue
    fileprivate(set) public var uiContext: NSManagedObjectContext!
    
    /// Local storage and network synchronization context. It can be used only from its private queue.
    /// This context track changes to its objects and synchronizes them from/to the backend.
    fileprivate(set) public var syncContext: NSManagedObjectContext!
    
    /// Search context. It can be used only from its private queue.
    /// This context is used to perform searches, not to slow down or insert temporary results in the
    /// sync context.
    fileprivate(set) public var searchContext: NSManagedObjectContext!

    deinit {
        self.tearDown()
    }
}

extension ManagedObjectContextDirectory {
    
    func configureManagedObjectContextReferences() {
        uiContext.performAndWait {
            uiContext.zm_sync = syncContext
        }
        syncContext.performAndWait {
            syncContext.zm_userInterface = uiContext
        }
    }
    
}

extension ManagedObjectContextDirectory {
    
    func tearDown() {
        // this will set all contextes to nil
        // making it crash if used after tearDown
        self.uiContext?.tearDown()
        self.syncContext?.tearDown()
        self.searchContext?.tearDown()
        self.uiContext?.tearDown()
        self.syncContext?.tearDown()
        self.searchContext?.tearDown()
        self.uiContext = nil
        self.syncContext = nil
        self.searchContext = nil
    }
}

extension ManagedObjectContextDirectory {
    
    fileprivate static func createUIManagedObjectContext(
        persistentStoreCoordinator: NSPersistentStoreCoordinator, dispatchGroup: ZMSDispatchGroup? = nil) -> NSManagedObjectContext {
        
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.performAndWait {
            moc.markAsUIContext()
            moc.configure(with: persistentStoreCoordinator)
            ZMUser.selfUser(in: moc)
            Label.fetchOrCreateFavoriteLabel(in: moc, create: true)
            dispatchGroup.apply(moc.add)
        }
        moc.mergePolicy = NSMergePolicy(merge: .rollbackMergePolicyType)
        return moc
    }
    
    fileprivate static func createSyncManagedObjectContext(
        persistentStoreCoordinator: NSPersistentStoreCoordinator,
        accountDirectory: URL,
        dispatchGroup: ZMSDispatchGroup? = nil,
        applicationContainer: URL) -> NSManagedObjectContext {
        
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.markAsSyncContext()
        moc.performAndWait {
            moc.configure(with: persistentStoreCoordinator)
            moc.setupLocalCachedSessionAndSelfUser()
            moc.setupUserKeyStore(accountDirectory: accountDirectory, applicationContainer: applicationContainer)
            moc.undoManager = nil
            moc.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
            dispatchGroup.apply(moc.add)
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
        persistentStoreCoordinator: NSPersistentStoreCoordinator,
        dispatchGroup: ZMSDispatchGroup? = nil
        ) -> NSManagedObjectContext {
        
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.markAsSearch()
        moc.performAndWait {
            moc.configure(with: persistentStoreCoordinator)
            moc.setupLocalCachedSessionAndSelfUser()
            moc.undoManager = nil
            moc.mergePolicy = NSMergePolicy(merge: .rollbackMergePolicyType)
            dispatchGroup.apply(moc.add)
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
        let request = ZMSession.sortedFetchRequest()
        
        guard let session = fetchOrAssert(request: request).first as? ZMSession else { return }
        
        userInfo[SessionObjectIDKey] = session.objectID
        ZMUser.boxSelfUser(session.selfUser, inContextUserInfo: self)
    }
    
}
