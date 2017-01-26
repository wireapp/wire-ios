// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


@import CoreData;
@import ZMCSystem;
@import ZMUtilities;
@import PINCache;

@class NSOperationQueue;

@interface NSManagedObjectContext (zmessaging)

+ (NSManagedObjectModel *)loadManagedObjectModel;

/// Checks if migration is needed or the database has to be moved
+ (BOOL)needsToPrepareLocalStoreAtURL:(NSURL *)storeURL;

/// Creates persistent store coordinator and migrates store if needed
/// @param synchronous defines if the method should execute sycnhronously or not (ususally it makes sence to execute it
///         synchronously when @c +needsToPrepareLocalStore is YES)
/// @param storeURL where database should be created / moved to
/// @param backupCorruptedDatabase if true, will copy a corrupted database to another folder for later investigation
/// @param completionHandler callback to be executed on completion (nullable), will be invoked on an arbitrary queue, it's the
///     caller responsibility to ensure this is switched back to the correct queue
+ (void)prepareLocalStoreAtURL:(NSURL *)storeURL
       backupCorruptedDatabase:(BOOL)backupCorruptedDatabase
                   synchronous:(BOOL)synchronous
             completionHandler:(void(^)())completionHandler;

/// Returns whether the store is ready to be opened
+ (BOOL)storeIsReady;

/// Create context used by the UI
/// @param storeURL where database is located
+ (instancetype)createUserInterfaceContextWithStoreAtURL:(NSURL *)storeURL;

/// Reset the user interface context. NOTE: only used in testing with a in-memory store.
+ (void)resetUserInterfaceContext;

/// This context will mark updates to objects in such a way that these fields are "up to date", ie. that these fields have been fetched.
/// C.f. @c zm_isSyncContext
/// @param storeURL where database is located
/// @param keyStoreURL where cryptobox sessions are located
+ (instancetype)createSyncContextWithStoreAtURL:(NSURL *)storeURL keyStoreURL:(NSURL *)keyStoreURL;

/// Create context used for searching
/// @param storeURL where database is located
+ (instancetype)createSearchContextWithStoreAtURL:(NSURL *)storeURL;

/// Returns @c YES if the receiver is a context that is used for synchronisation with the backend.
///
/// Individual fields are marked as "needs to be pushed to the server" or "is in sync with server" when they are changed by either a user interface context or a sync context repsectively.
@property (readonly) BOOL zm_isSyncContext;
/// Inverse of @c zm_isSyncContext
@property (readonly) BOOL zm_isUserInterfaceContext;

/// Returns @c YES if the receiver is a context that is used for searching.
@property (readonly) BOOL zm_isSearchContext;

/// Returns @c YES if the context should refresh objects following the policy for the sync context
@property (readonly) BOOL zm_shouldRefreshObjectsWithSyncContextPolicy;

/// Returns @c YES if the context should refresh objects following the policy for the UI context
@property (readonly) BOOL zm_shouldRefreshObjectsWithUIContextPolicy;

/// Returns @c self in case this is a sync context, or attached sync context, if present
@property (nonatomic) NSManagedObjectContext* zm_syncContext;

/// Returns @c self in case this is a UI context, or attached UI context, if present
@property (nonatomic) NSManagedObjectContext* zm_userInterfaceContext;

/// Returns the set containing all user clients that failed to establish a session with selfClient
@property (nonatomic, readonly) NSMutableSet* zm_failedToEstablishSessionStore;

/// This is used for unit tests.
+ (void)setUseInMemoryStore:(BOOL)useInMemoryStore;
+ (BOOL)useInMemoryStore;

/// This is used for unit tests. It only has an effect when @c setUseInMemoryStore: was set to @c YES
+ (void)resetSharedPersistentStoreCoordinator;
/// Sets a flag (in NSUserDefaults) that will cause the store to get deleted next time to app launches.
+ (void)setClearPersistentStoreOnStart:(BOOL)flag;

/// Calls @c -save: only if the receiver returns @c YES for @c -hasChanges
/// If the save fails, calls @c -rollback on the receiver.
/// returns @c NO if there was a rollback, @c YES otherwise
- (BOOL)saveOrRollback;

/// Calls @c -save: even if the receiver returns @c NO for @c -hasChanges
/// If the save fails, calls @c -rollback on the receiver.
/// returns @c NO if there was a rollback, @c YES otherwise
- (BOOL)forceSaveOrRollback;

/// This will trigger a call to @c -saveOrRollback once a coalescence timer has expired or immediately if there are too many pending changes
- (void)enqueueDelayedSave;
/// This will trigger a call to @c -saveOrRollback if there are too many pending changes. Returns YES if it saved
- (BOOL)saveIfTooManyChanges;

/// This will trigger a call to @c -enqueueDelayedSave once the receiver's group has emptied or
/// immediately if the receiver has a lot of pending changes.
- (void)enqueueDelayedSaveWithGroup:(ZMSDispatchGroup *)group;

/// Executes a fetch request and asserts in case of error
/// For generic requests in Swift please refer to `func fetchOrAssert<T>(request: NSFetchRequest<T>) -> [T]`
- (NSArray *)executeFetchRequestOrAssert:(NSFetchRequest *)request;

/// Fetch metadata for key from in-memory non-persisted metadata
/// or from persistent store metadata, in that order
- (id)persistentStoreMetadataForKey:(NSString *)key;

@end

