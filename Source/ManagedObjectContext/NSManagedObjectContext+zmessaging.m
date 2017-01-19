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

@import ZMUtilities;
@import UIKit;
@import Cryptobox;

#import "NSManagedObjectContext+zmessaging-Internal.h"
#import "NSManagedObjectContext+tests.h"
#import "ZMManagedObject.h"
#import "ZMUser+Internal.h"
#import "ZMSyncMergePolicy.h"
#import "ZMConversation+Internal.h"
#import "ZMUserDisplayNameGenerator.h"
#import "ZMNotifications.h"

#import "ZMConversation+Internal.h"
#import <objc/runtime.h>
#import <libkern/OSAtomic.h>
#import <ZMUtilities/ZMUtilities-Swift.h>
#import <ZMCDataModel/ZMCDataModel-Swift.h>

static NSString * const IsSyncContextKey = @"ZMIsSyncContext";
static NSString * const IsSearchContextKey = @"ZMIsSearchContext";
static NSString * const SyncContextKey = @"ZMSyncContext";
static NSString * const UserInterfaceContextKey = @"ZMUserInterfaceContext";
static NSString * const IsRefreshOfObjectsDisabled = @"ZMIsRefreshOfObjectsDisabled";
static NSString * const IsUserInterfaceContextKey = @"ZMIsUserInterfaceContext";
static NSString * const IsSaveDisabled = @"ZMIsSaveDisabled";
static NSString * const IsFailingToSave = @"ZMIsFailingToSave";

static BOOL UsesInMemoryStore;
static NSPersistentStoreCoordinator *sharedPersistentStoreCoordinator;
static NSPersistentStoreCoordinator *inMemorySharedPersistentStoreCoordinator;
static NSString * const ClearPersistentStoreOnStartKey = @"ZMClearPersistentStoreOnStart";
static NSString * const TimeOfLastSaveKey = @"ZMTimeOfLastSave";
static NSString * const FirstEnqueuedSaveKey = @"ZMTimeOfLastSave";
static NSString * const FailedToEstablishSessionStoreKey = @"FailedToEstablishSessionStoreKey";


static dispatch_queue_t UIContextCreationQueue(void);
static NSManagedObjectContext *SharedUserInterfaceContext = nil;
static id applicationProtectedDataDidBecomeAvailableObserver = nil;

static NSString* ZMLogTag ZM_UNUSED = @"NSManagedObjectContext";
//
// For testing, we want to use an NSInMemoryStoreType (it's faster).
// The only way for multiple contexts to share the same NSInMemoryStoreType is to share
// the persistent store coordinator.
//


@interface NSManagedObjectContext (CleanUp)

- (void)refreshUnneededObjects;

@end



@implementation NSManagedObjectContext (zmessaging)

static BOOL storeIsReady = NO;

+ (BOOL)needsToPrepareLocalStoreAtURL:(NSURL *)storeURL
{
    BOOL needsMigration = NO;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:storeURL.path]) {
        NSManagedObjectModel *mom = self.loadManagedObjectModel;
        NSDictionary *sharedContainerMetadata = [self metadataForStoreAtURL:storeURL];
        needsMigration = sharedContainerMetadata != nil && ![mom isConfiguration:nil compatibleWithStoreMetadata:sharedContainerMetadata];
    }

    PersistentStoreRelocator *storeRelocator = [[PersistentStoreRelocator alloc] initWithStoreLocation:storeURL];

    return needsMigration || storeRelocator.storeNeedsToBeRelocated || [self databaseExistsButIsNotReadableDueToEncryptionAtURL:storeURL];
}

+ (void)prepareLocalStoreAtURL:(NSURL *)storeURL
       backupCorruptedDatabase:(BOOL)backupCorruptedDatabase
             completionHandler:(void (^)())completionHandler
{
    dispatch_block_t finally = ^() {
        storeIsReady = YES;
        if (nil != completionHandler) {
            completionHandler();
        }
    };
    
    //just try to create psc, contexts will be created later when user session is initialized
    if (UsesInMemoryStore) {
        RequireString(inMemorySharedPersistentStoreCoordinator == nil, "In-Memory persistent store was not nil");
        inMemorySharedPersistentStoreCoordinator = [self inMemoryPersistentStoreCoordinator];
        finally();
    }
    else {
        RequireString(sharedPersistentStoreCoordinator == nil, "Shared persistent store was not nil");
        
        // We need to handle the case when the database file is encrypted by iOS and user never entered the passcode
        // We use default core data protection mode NSFileProtectionCompleteUntilFirstUserAuthentication
        // This happens when
        // (1) User has passcode enabled
        // (2) User turns the phone on, but do not enter the passcode yet
        // (3) App is awake on the background due to VoIP push notification
        // We should wait then until the database is becoming available
        if ([self databaseExistsButIsNotReadableDueToEncryptionAtURL:storeURL]) {
            ZM_WEAK(self);
            NSAssert(applicationProtectedDataDidBecomeAvailableObserver == nil, @"prepareLocalStoreInternalBackingUpCorruptedDatabase: called twice");
            
            applicationProtectedDataDidBecomeAvailableObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationProtectedDataDidBecomeAvailable
                                                                  object:nil
                                                                   queue:nil
                                                              usingBlock:^(NSNotification * _Nonnull __unused note) {
                                                                  ZM_STRONG(self);
                                                                  sharedPersistentStoreCoordinator = [self initPersistentStoreCoordinatorAtURL:storeURL backupCorrupedDatabase:backupCorruptedDatabase];
                                                                  finally();
                                                                  [[NSNotificationCenter defaultCenter] removeObserver:applicationProtectedDataDidBecomeAvailableObserver];
                                                                  applicationProtectedDataDidBecomeAvailableObserver = nil;
                                                              }];
        }
        else {
            sharedPersistentStoreCoordinator = [self initPersistentStoreCoordinatorAtURL:storeURL backupCorrupedDatabase:backupCorruptedDatabase];
            finally();
        }
    }
}

+ (void)prepareLocalStoreAtURL:(NSURL *)storeURL
       backupCorruptedDatabase:(BOOL)backupCorruptedDatabase
                   synchronous:(BOOL)synchronous
             completionHandler:(void(^)())completionHandler;
{
    (synchronous ? dispatch_sync : dispatch_async)(UIContextCreationQueue(), ^{
        [self prepareLocalStoreAtURL:storeURL backupCorruptedDatabase:backupCorruptedDatabase completionHandler:completionHandler];
    });
}

+ (BOOL)storeIsReady
{
    return storeIsReady;
}

+ (NSPersistentStoreCoordinator *)persistentStoreCoordinatorAtURL:(NSURL *)storeURL
{
    NSPersistentStoreCoordinator *psc = UsesInMemoryStore ? inMemorySharedPersistentStoreCoordinator : sharedPersistentStoreCoordinator;
    
    if (psc == nil) {
        [self prepareLocalStoreAtURL:storeURL backupCorruptedDatabase:NO completionHandler:nil];
        psc = UsesInMemoryStore ? inMemorySharedPersistentStoreCoordinator : sharedPersistentStoreCoordinator;
        Require(psc != nil);
    }
    
    return psc;
}

+ (instancetype)createUserInterfaceContextWithStoreAtURL:(NSURL *)storeURL
{
    NSPersistentStoreCoordinator *psc = [self persistentStoreCoordinatorAtURL:storeURL];
    RequireString(psc != nil, "No persistent store coordinator, call -prepareLocalStore: first.");
    
    SharedUserInterfaceContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [SharedUserInterfaceContext markAsUIContext];
    [SharedUserInterfaceContext configureWithPersistentStoreCoordinator:psc];
    [SharedUserInterfaceContext initialiseSessionAndSelfUser];
    
    SharedUserInterfaceContext.mergePolicy = [[ZMSyncMergePolicy alloc] initWithMergeType:NSRollbackMergePolicyType];
    (void)SharedUserInterfaceContext.globalManagedObjectContextObserver;
    
    return SharedUserInterfaceContext;
}

+ (void)resetUserInterfaceContext
{
    dispatch_sync(UIContextCreationQueue(), ^{
        SharedUserInterfaceContext = nil;
    });
}

+ (instancetype)createSyncContextWithStoreAtURL:(NSURL *)storeURL keyStoreURL:(NSURL *)keyStoreURL
{
    NSPersistentStoreCoordinator *psc = [self persistentStoreCoordinatorAtURL:storeURL];
    RequireString(psc != nil, "No persistent store coordinator, call -prepareLocalStore: first.");

    NSManagedObjectContext *moc = [[self alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [moc performBlockAndWait:^{
        [moc markAsSyncContext];
        [moc configureWithPersistentStoreCoordinator:psc];
        [moc setupLocalCachedSessionAndSelfUser];
        [moc setupUserKeyStoreForDirectory:keyStoreURL];
        moc.undoManager = nil;
        moc.mergePolicy = [[ZMSyncMergePolicy alloc] initWithMergeType:NSMergeByPropertyObjectTrumpMergePolicyType];
    }];
    return moc;
}

+ (instancetype)createSearchContextWithStoreAtURL:(NSURL *)storeURL
{
    NSPersistentStoreCoordinator *psc = [self persistentStoreCoordinatorAtURL:storeURL];
    RequireString(psc != nil, "No persistent store coordinator, call -prepareLocalStore: first.");
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [moc performBlockAndWait:^{        
        [moc markAsSearchContext];
        [moc configureWithPersistentStoreCoordinator:psc];
        [moc setupLocalCachedSessionAndSelfUser];
        moc.undoManager = nil;
        moc.mergePolicy = [[ZMSyncMergePolicy alloc] initWithMergeType:NSRollbackMergePolicyType];
    }];
    return moc;
}

- (void)configureWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)psc
{
    RequireString(self.zm_isSyncContext || self.zm_isUserInterfaceContext || self.zm_isSearchContext, "Context is not marked, yet");
    [self createDispatchGroups];
    self.persistentStoreCoordinator = psc;
}

- (id)validUserInfoValueOfClass:(Class)class forKey:(NSString *)key
{
    id value = self.userInfo[key];
    if (value == nil) {
        return nil;
    }
    if (![value isKindOfClass:class]) {
        
        NSMutableString *userInfoKeys = [NSMutableString string];
        for(NSString *dictKey in self.userInfo.allKeys) {
            [userInfoKeys appendString:[NSString stringWithFormat:@"%@, ", dictKey]];
        }
        
        if ([value isKindOfClass:NSDictionary.class]) {
            NSMutableString *keys = [NSMutableString string];
            for (NSString *dictKey in ((NSDictionary*) value).allKeys) {
                [keys appendString:[NSString stringWithFormat:@"%@, ", dictKey]];
            }
            RequireString([value isKindOfClass:class], "Value for key %s is a dictionary: keys %s. \n User info has keys: %s", [key cStringUsingEncoding:NSUTF8StringEncoding], [keys cStringUsingEncoding:NSUTF8StringEncoding], [userInfoKeys cStringUsingEncoding:NSUTF8StringEncoding]);

        } else {
            RequireString([value isKindOfClass:class], "Value for key %s is not of class %s. \n User info has keys: %s", [key cStringUsingEncoding:NSUTF8StringEncoding], [NSStringFromClass(class) cStringUsingEncoding:NSUTF8StringEncoding], [userInfoKeys cStringUsingEncoding:NSUTF8StringEncoding]);
        }
    }
    return value;
}

- (BOOL)zm_isSyncContext
{
    return [[self validUserInfoValueOfClass:[NSNumber class] forKey:IsSyncContextKey] boolValue];
}

- (BOOL)zm_isUserInterfaceContext
{
    return [[self validUserInfoValueOfClass:[NSNumber class] forKey:IsUserInterfaceContextKey] boolValue];
}

- (BOOL)zm_isSearchContext
{
    return [self.userInfo[IsSearchContextKey] boolValue];
}

- (NSManagedObjectContext*)zm_syncContext
{
    if (self.zm_isSyncContext) {
        return self;
    }
    else {
        UnownedNSObject *unownedContext = self.userInfo[SyncContextKey];
        if (nil != unownedContext) {
            return (NSManagedObjectContext *)unownedContext.unbox;
        }
    }
    
    return nil;
}

- (void)setZm_syncContext:(NSManagedObjectContext *)zm_syncContext
{
    self.userInfo[SyncContextKey] = [[UnownedNSObject alloc] init:zm_syncContext];
}

- (NSManagedObjectContext*)zm_userInterfaceContext
{
    if (self.zm_isUserInterfaceContext) {
        return self;
    }
    else {
        UnownedNSObject *unownedContext = self.userInfo[UserInterfaceContextKey];
        if (nil != unownedContext) {
            return (NSManagedObjectContext *)unownedContext.unbox;
        }
    }
    
    return nil;
}

- (void)setZm_userInterfaceContext:(NSManagedObjectContext *)zm_userInterfaceContext
{
    self.userInfo[UserInterfaceContextKey] = [[UnownedNSObject alloc] init:zm_userInterfaceContext];
}

- (BOOL)zm_isRefreshOfObjectsDisabled;
{
    return [self.userInfo[IsRefreshOfObjectsDisabled] boolValue];
}

- (BOOL)zm_shouldRefreshObjectsWithSyncContextPolicy
{
    return self.zm_isSyncContext && !self.zm_isRefreshOfObjectsDisabled;
}

- (BOOL)zm_shouldRefreshObjectsWithUIContextPolicy
{
    return self.zm_isUserInterfaceContext && !self.zm_isRefreshOfObjectsDisabled;
}

+ (BOOL)useInMemoryStore;
{
    return UsesInMemoryStore;
}

+ (void)setUseInMemoryStore:(BOOL)useInMemoryStore
{
    UsesInMemoryStore = useInMemoryStore;
}

+ (NSPersistentStoreCoordinator *)inMemoryPersistentStoreCoordinator
{
    NSManagedObjectModel *mom = [self loadManagedObjectModel];
    NSPersistentStoreCoordinator* persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    
    NSError *error = nil;
    NSPersistentStore *store = [persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType
                                                                        configuration:nil
                                                                                  URL:nil
                                                                              options:nil
                                                                                error:&error];
    
    NSAssert(store != nil, @"Unable to create in-memory Core Data store: %@", error);
    NOT_USED(store);
    return persistentStoreCoordinator;
}

+ (void)setClearPersistentStoreOnStart:(BOOL)flag
{
    if (flag) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:ClearPersistentStoreOnStartKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:ClearPersistentStoreOnStartKey];
    }
}

+ (void)clearPersistentStoreAtURL:(NSURL *)storeURL
{
    dispatch_once(&clearStoreOnceToken, ^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:ClearPersistentStoreOnStartKey]) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:ClearPersistentStoreOnStartKey];
            [self removePersistentStoreFromFilesystemAndCopyToBackup:NO storeURL:storeURL];
        }
    });
}

- (NSMutableSet *)zm_failedToEstablishSessionStore
{
    if (!self.zm_isSyncContext) {
        return nil;
    }
    
    if (nil == self.userInfo[FailedToEstablishSessionStoreKey]) {
        self.userInfo[FailedToEstablishSessionStoreKey] = [NSMutableSet set];
    }
    
    return self.userInfo[FailedToEstablishSessionStoreKey];
}

/// @param copyToBackup: if true, will dump the database to a safe location before deleting it
+ (void)removePersistentStoreFromFilesystemAndCopyToBackup:(BOOL)copyToBackup storeURL:(NSURL *)storeFileURL;
{
    // Enumerate all files in the store directory and find the ones that match the store name.
    // We need to do this, because the store consists of several files.
    
    NSString * const storeName = [storeFileURL lastPathComponent];
    NSURL *storeFolder;
    if (![storeFileURL getResourceValue:&storeFolder forKey:NSURLParentDirectoryURLKey error:NULL]) {
        return;
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if(copyToBackup) {
        
        NSURL *rootFolder;
        if ([storeFolder getResourceValue:&rootFolder forKey:NSURLParentDirectoryURLKey error:NULL]) {
            NSString *timeStamp = [NSString stringWithFormat:@"DB-%lu.bak", (unsigned long)(1000 *[NSDate date].timeIntervalSince1970)];
            NSURL *backupFolder = [rootFolder URLByAppendingPathComponent:timeStamp];
            [backupFolder setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
            
            NSError *copyError;
            if(![fm copyItemAtURL:storeFolder toURL:backupFolder error:&copyError]) {
                ZMLogError(@"Failed to copy to backup folder: %@", copyError);
            }
            else {
                ZMLogWarn(@"Copied backup of corrupted DB to: %@", backupFolder.absoluteString);
            }
        }
        else {
            ZMLogError(@"Failed to copy to backup folder: can't access root folder of %@", storeFolder);
        }
    }
    
    for (NSURL *fileURL in [fm enumeratorAtURL:storeFolder includingPropertiesForKeys:@[NSURLNameKey] options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil]) {
        NSError *error = nil;
        NSString *name;
        if (! [fileURL getResourceValue:&name forKey:NSURLNameKey error:&error]) {
            ZMLogDebug(@"Skipping item \"%@\" because we can't get the name: %@", fileURL.path, error);
            continue;
        }
        // "external binary data" is stored inside ".storeName_SUPPORT"
        if ([name hasPrefix:storeName] ||
            [name hasPrefix:[NSString stringWithFormat:@".%@_", storeName]])
        {
            if (! [fm removeItemAtURL:fileURL error:&error]) {
                ZMLogError(@"Unable to delete item \"%@\": %@", fileURL.path, error);
            }
        }
    }
}

static dispatch_once_t storeURLOnceToken;
static dispatch_once_t clearStoreOnceToken;

+ (void)resetSharedPersistentStoreCoordinator;
{
    inMemorySharedPersistentStoreCoordinator = nil;
    sharedPersistentStoreCoordinator = nil;
    storeURLOnceToken = 0;
    clearStoreOnceToken = 0;
}

+ (NSPersistentStoreCoordinator *)onDiskPersistentStoreCoordinator
{
    return sharedPersistentStoreCoordinator;
}

+ (NSPersistentStoreCoordinator *)initPersistentStoreCoordinatorAtURL:(NSURL *)storeURL backupCorrupedDatabase:(BOOL)backupCorruptedDatabase
{
    [self clearPersistentStoreAtURL:storeURL];
    [self createDirectoryForStoreAtURL:storeURL];
    
    PersistentStoreRelocator *storeRelocator = [[PersistentStoreRelocator alloc] initWithStoreLocation:storeURL];
    
    NSError *error = nil;
    [storeRelocator moveStoreIfNecessaryAndReturnError:&error];
    
    if (error != nil) {
        ZMLogError(@"Moving store failed: %@", error);
        return nil;
    }
    
    NSManagedObjectModel *mom = [self loadManagedObjectModel];
    NSPersistentStoreCoordinator* psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];

    BOOL shouldMigrate = [self shouldMigrateStoreToNewModelVersion:storeURL];
    [self addPersistenStoreWithMigration:shouldMigrate toCoordinator:psc storeURL:storeURL backupCorruptedDatabase:backupCorruptedDatabase];

    return psc;
}

+ (void)createDirectoryForStoreAtURL:(NSURL *)storeURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *directory = storeURL.URLByDeletingLastPathComponent;
    
    if (! [fileManager fileExistsAtPath:directory.path]) {
        NSError *error;
        short const permissions = 0700;
        NSDictionary *attr = @{NSFilePosixPermissions: @(permissions)};
        RequireString([fileManager createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:attr error:&error],
                      "Failed to create directory: %lu, error: %lu", (unsigned long)directory,  (unsigned long) error.code);
    }
    
    // Make sure this is not backed up:
    NSError *error;
    if (! [directory setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error]) {
        ZMLogError(@"Error excluding %@ from backup %@", directory.path, error);
    }
}

+ (BOOL)shouldMigrateStoreToNewModelVersion:(NSURL *)storeURL
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:storeURL.path]) {
        // Store doesn't exist yet so need to migrate it.
        return NO;
    }
    
    NSManagedObjectModel *mom = self.loadManagedObjectModel;
    NSDictionary *metadata = [self metadataForStoreAtURL:storeURL];
    NSString *oldModelVersion = [metadata[NSStoreModelVersionIdentifiersKey] firstObject];
    
    // Between non-E2EE and E2EE we should not migrate the DB for privacy reasons.
    // We know that the old mom is a version supporting E2EE when it
    // contains the 'ClientMessage' entity or is at least of version 1.25
    BOOL otrBuild = [[metadata[NSStoreModelVersionHashesKey] allKeys] containsObject:ZMClientMessage.entityName];
    BOOL atLeastVersion1_25 = oldModelVersion != nil &&  [oldModelVersion compare:@"1.25" options:NSNumericSearch] != NSOrderedDescending;

    // Unfortunately the 1.24 Release has a mom version of 1.3 but we do not want to migrate from it
    NSString *currentModelIdentifier = mom.versionIdentifiers.anyObject;
    BOOL newerOTRVersion = atLeastVersion1_25 && ![oldModelVersion isEqualToString:@"1.3"];
    BOOL shouldMigrate = otrBuild || newerOTRVersion;

    // this is used to avoid migrating internal builds when we update the DB internally between releases
    BOOL isSameAsCurrent = [currentModelIdentifier isEqualToString:oldModelVersion];
    
    return shouldMigrate && !isSameAsCurrent;
}

+ (NSDictionary *)metadataForStoreAtURL:(NSURL *)storeURL
{
    NSError *metadataError = nil;
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:storeURL error:&metadataError];
    
    // Something happened while reading the current database metadata
    if (nil != metadataError) {
        ZMLogError(@"Error reading store metadata: %@", metadataError);
    }

    return sourceMetadata;
}

+ (NSPersistentStore *)addPersistenStoreWithMigration:(BOOL)migrate
                                        toCoordinator:(NSPersistentStoreCoordinator *)psc
                                             storeURL:(NSURL *)storeURL
                              backupCorruptedDatabase:(BOOL)backupCorruptedDatabase
{
    if (migrate) {
        NSError *error = nil;
        NSDictionary *metadata = [self metadataForStoreAtURL:storeURL];
        NSDictionary *options = [self persistentStoreOptionsDictionarySupportingMigration:YES];
        NSPersistentStore *store = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
        NSString *errorString = [NSString stringWithFormat:@"when adding persistent store: %@", error];
        NSString *oldModelVersion = [metadata[NSStoreModelVersionIdentifiersKey] firstObject];
        NSString *currentModelIdentifier = psc.managedObjectModel.versionIdentifiers.anyObject;

        RequireString(nil != store, "Unable to perform migration and create SQLite Core Data store %s. "
                      "-- Old model version was: %s, current version: %s",
                      errorString.UTF8String,
                      oldModelVersion.UTF8String,
                      currentModelIdentifier.UTF8String);
        if (nil != store) {
            return store;
        }
    }

    return [self addPersistentStoreBackingUpCorruptedDatabases:backupCorruptedDatabase storeURL:storeURL toPSC:psc];
}

+ (NSPersistentStore *)addPersistentStoreBackingUpCorruptedDatabases:(BOOL)backupCorruptedDatabase storeURL:(NSURL *)storeURL toPSC:(NSPersistentStoreCoordinator *)psc
{
    // If we do not have a store by now, we are either already at the current version, or updating from a non E2EE build, or the migration failed.
    // Either way we will try to create a persistent store without perfoming any migrations.
    NSDictionary *options = [self persistentStoreOptionsDictionarySupportingMigration:NO];
    NSError *error;
    
    NSPersistentStore *store = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
    if (store == nil) {
        // Something really wrong
        // Try to remove the store and create from scratch
        if(backupCorruptedDatabase) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:ZMDatabaseCorruptionNotificationName
                                                                    object:nil
                                                                  userInfo:@{ NSUnderlyingErrorKey: error }];
            });
        }
        ZMLogError(@"Failed to open database. Corrupted database? Error: %@", error);
        
        [self removePersistentStoreFromFilesystemAndCopyToBackup:backupCorruptedDatabase storeURL:storeURL];
        // Re-try to add the store
        store = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
    }
    RequireString(store != nil, "Unable to create SQLite Core Data store: %lu", (long) error.code);

    return store;
}


+ (NSDictionary *)persistentStoreOptionsDictionarySupportingMigration:(BOOL)supportsMigration
{
    return @{
             // https://www.sqlite.org/pragma.html
             NSSQLitePragmasOption: @{ @"journal_mode": @"WAL", @"synchronous" : @"FULL" },
             NSMigratePersistentStoresAutomaticallyOption: @(supportsMigration),
             NSInferMappingModelAutomaticallyOption: @(supportsMigration)
             };
}

/// Checks if database is created, but it is still locked with iOS file protection
+ (BOOL)databaseExistsButIsNotReadableDueToEncryptionAtURL:(NSURL *)storeURL
{
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL fileExists = [fm fileExistsAtPath:storeURL.path isDirectory:nil];
    
    NSError *readError = nil;
    [NSFileHandle fileHandleForReadingFromURL:storeURL error:&readError];
    
    BOOL result = fileExists && readError != nil;
    if (result) {
        ZMLogError(@"database exists but is not readable due to encryption, error=%@", readError);
    }

    return result;
}

- (BOOL)saveOrRollback;
{
    return [self saveOrRollbackIgnoringChanges:NO];
}

- (BOOL)forceSaveOrRollback;
{
    return [self saveOrRollbackIgnoringChanges:YES];
}

- (BOOL)saveOrRollbackIgnoringChanges:(BOOL)shouldIgnoreChanges;
{
    if(self.userInfo[IsSaveDisabled]) {
        return YES;
    }
    
    ZMLogDebug(@"%@ <%@: %p>.", NSStringFromSelector(_cmd), self.class, self);
    
    NSDictionary *oldMetadata = [self.persistentStoreCoordinator metadataForPersistentStore:[self firstPersistentStore]];
    [self makeMetadataPersistent];
    
    if (self.userInfo[IsFailingToSave]) {
        [self rollbackWithOldMetadata:oldMetadata];
        return NO;
    }
    
    // We need to save even if hasChanges is NO as long as the callState changes. An empty save will result in an empty did-save notification.
    // That notification in turn will result in a merge, even if it is empty, and thus merge the call state.
    if (self.zm_hasChanges || shouldIgnoreChanges) {
        NSError *error;
        ZMLogDebug(@"Saving <%@: %p>.", self.class, self);
        self.timeOfLastSave = [NSDate date];
        ZMSTimePoint *tp = [ZMSTimePoint timePointWithInterval:10 label:[NSString stringWithFormat:@"Saving context %@", self.zm_isSyncContext ? @"sync": @"ui"]];
        if (! [self save:&error]) {
            ZMLogError(@"Failed to save: %@", error);
            [self reportSaveErrorWithError:error];
            [self rollbackWithOldMetadata:oldMetadata];
            [tp warnIfLongerThanInterval];
            return NO;
        }
        [tp warnIfLongerThanInterval];
        [self refreshUnneededObjects];
        self.zm_hasUserInfoChanges = NO;
    }
    else {
        ZMLogDebug(@"Not saving because there is no change");
    }
    return YES;
}

- (void)rollbackWithOldMetadata:(NSDictionary *)oldMetadata;
{
    [self rollback];
    [self.persistentStoreCoordinator setMetadata:oldMetadata forPersistentStore:[self firstPersistentStore]];
}

- (NSDate *)timeOfLastSave;
{
    return self.userInfo[TimeOfLastSaveKey];
}

- (void)setTimeOfLastSave:(NSDate *)date;
{
    if (date != nil) {
        self.userInfo[TimeOfLastSaveKey] = date;
    } else {
        [self.userInfo removeObjectForKey:TimeOfLastSaveKey];
    }
}

- (NSDate *)firstEnqueuedSave {
    return self.userInfo[FirstEnqueuedSaveKey];
}

- (void)setFirstEnqueuedSave:(NSDate *)date;
{
    if (date != nil) {
        self.userInfo[FirstEnqueuedSaveKey] = date;
    } else {
        [self.userInfo removeObjectForKey:FirstEnqueuedSaveKey];
    }
}

- (void)enqueueDelayedSave;
{
    [self enqueueDelayedSaveWithGroup:nil];
}

- (BOOL)saveIfTooManyChanges
{
    NSUInteger const changeCount = self.deletedObjects.count + self.insertedObjects.count + self.updatedObjects.count;
    NSUInteger const threshold = 200;
    if (threshold < changeCount) {
        ZMLogDebug(@"enqueueSaveIfTooManyChanges: calling -saveOrRollback synchronuously because change count is %llu.", (unsigned long long) changeCount);
        [self saveOrRollback];
        return YES;
    }
    return NO;
}

- (BOOL)saveIfDelayIsTooLong
{
    if (self.firstEnqueuedSave == nil) {
        self.firstEnqueuedSave = [NSDate date];
    } else {
        if ([[NSDate date] timeIntervalSinceDate:self.firstEnqueuedSave] > 0.25) {
            [self saveOrRollback];
            self.firstEnqueuedSave = nil;
            return YES;
        }
    }
    return NO;
}

- (void)enqueueDelayedSaveWithGroup:(ZMSDispatchGroup *)group;
{
    if(self.userInfo[IsSaveDisabled]) {
        return;
    }
    
    if ([self saveIfTooManyChanges] ||
        [self saveIfDelayIsTooLong])
    {
        return;
    }
    
    // Delay function (not to scale):
    //       ^
    //       │
    //  0.100│\
    //       │  \
    //       │    \
    //       │      \
    // delay │        \
    //       │          \
    //       │            \
    //  0.002│              +------------------
    //       │              :
    //       +———————————————————————————————————>
    //       0              1s
    //            time since last save
    
    const double delta_s = (self.timeOfLastSave != nil) ? (-[self.timeOfLastSave timeIntervalSinceNow]) : 10000;
    const double delay_s = (delta_s > 0.98) ? 0.002 : (-0.1*delta_s + 0.1);
    const unsigned int delay_ms = (unsigned int) lround(delay_s*1000);
    
    // Grab a unique number, for debugging only:
    static int32_t c;
    int32_t myCount = ++c;
    
    ZMLogDebug(@"enqueueDelayedSaveWithGroup: called (%d)", myCount);
    
    // This code is a bit daunting at first. There are a total of 3 groups:
    //
    // otherGroups: This keeps track of "the context is doing some work" INCLUDING delayed save
    // secondaryGroup: This keeps track of "the context is doing some work" EXCLUDING delayed save
    // group: Passed in group
    //
    // (1) We'll enter all groups.
    //
    // (2) We increment the pendingSaveCounter
    //
    // (2) After a tiny time interval, we'll leave the secondary group. Since calls to -performGroupedBlock:
    //     also get added to this group, we can use
    //         dispatch_group_notify(secondaryGroup, ...)
    //     to know that no further work is scheduled on this context. At that point we decrement pendingSaveCounter.
    //
    // (3) If pendingSaveCounter is 0 at this point (no outstanding saves), we perform the actual save.
    //
    // The pendingSaveCounter ensures that only the last enqueued save will perform the actual save, ie. it's
    // safe and efficient to call this method multiple times.
    //
    //     work -> enqueueSave -> work -> enqueueSave -> work -> enqueueSave
    //                                                                      \--> save at this point
    //
    
    
    // Enter all groups:
    if (group) {
        [group enter];
    }
    ZMSDispatchGroup *secondaryGroup;
    NSArray *otherGroups;
    {
        NSArray *groups = [self enterAllGroups];
        secondaryGroup = groups[1];
        NSMutableIndexSet *otherIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, groups.count)];
        [otherIndexes removeIndex:1];
        otherGroups = [groups objectsAtIndexes:otherIndexes];
    }
    
    ++self.pendingSaveCounter;
    
    // We'll wait just a little bit, just in case the group empties for a short span of time.
    {
        ZMLogDebug(@"dispatch_after() entered (%d)", myCount);
        dispatch_time_t when = dispatch_walltime(NULL, delay_ms * NSEC_PER_MSEC);
        dispatch_queue_t waitQueue = (ZMHasQualityOfServiceSupport() ?
                                      dispatch_get_global_queue(QOS_CLASS_UTILITY, 0) :
                                      dispatch_get_global_queue(0, 0));
        dispatch_after(when, waitQueue, ^{
            [secondaryGroup leave];
            ZMLogDebug(@"dispatch_after() completed (%d)", myCount);
        });
    }
    
    // Once the save group is empty (no pending saves), we'll do the actual save:
    [secondaryGroup notifyOnQueue:dispatch_get_global_queue(0, 0) block:^{
        [self performGroupedBlock:^{
            NSInteger const c2 = --self.pendingSaveCounter;
            if (c2 == 0) {
                ZMLogDebug(@"Calling -saveOrRollback (%d)", myCount);
                [self saveOrRollback];
            } else {
                ZMLogDebug(@"Not calling -saveOrRollback (%d)", myCount);
            }
            if (group) {
                [group leave];
            }
            [self leaveAllGroups:otherGroups];
        }];
    }];
}

- (void)initialiseSessionAndSelfUser;
{
    [ZMUser selfUserInContext:self];
}

// This function setup the user info on the context, the session and self user must be initialised before end.
- (void)setupLocalCachedSessionAndSelfUser;
{
    ZMSession *session = (ZMSession *)[self executeFetchRequestOrAssert:[ZMSession sortedFetchRequest]].firstObject;
    self.userInfo[SessionObjectIDKey] = session.objectID;
    [ZMUser boxSelfUser:session.selfUser inContextUserInfo:self];
}

- (NSPersistentStore *)firstPersistentStore
{
    NSArray *stores = [self.persistentStoreCoordinator persistentStores];
    NSAssert(stores.count == 1, @"Invalid number of stores");
    NSPersistentStore *store = stores[0];
    return store;
}

+ (NSManagedObjectModel *)loadManagedObjectModel;
{
    // On iOS we can't put the model into the library. We need to load it from the test bundle.
    // On OS X, we'll load it from the zmessaging Framework.
    NSBundle *modelBundle = [NSBundle bundleForClass:[ZMManagedObject class]];
    NSManagedObjectModel *result = [NSManagedObjectModel mergedModelFromBundles:@[modelBundle]];
    NSAssert(result != nil, @"Unable to load zmessaging model.");
    return result;
}

- (NSArray *)executeFetchRequestOrAssert:(NSFetchRequest *)request;
{
    NSError *error;
    NSArray *result = [self executeFetchRequest:request error:&error];
    RequireString(result != nil, "Error in fetching: %lu", (long) error.code);
    return result;
}

@end


static dispatch_queue_t UIContextCreationQueue(void)
{
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("moc.singletonContextIsolation", 0);
    });
    return queue;
}



@implementation NSManagedObjectContext (zmessagingTests)

- (void)enableForceRollback;
{
    self.userInfo[IsFailingToSave] = @YES;
}

- (void)disableForceRollback;
{
    [self.userInfo removeObjectForKey:IsFailingToSave];
}

- (void)disableSaves;
{
    self.userInfo[IsSaveDisabled] = @YES;
}

- (void)enableSaves;
{
    [self.userInfo removeObjectForKey:IsSaveDisabled];
}

- (void)markAsSyncContext;
{
    [self performBlockAndWait:^{
        self.userInfo[IsSyncContextKey] = @YES;
    }];
}

- (void)markAsSearchContext;
{
    [self performBlockAndWait:^{
        self.userInfo[IsSearchContextKey] = @YES;
    }];
}

- (void)markAsUIContext
{
    [self performBlockAndWait:^{
        self.userInfo[IsUserInterfaceContextKey] = @YES;
        self.displayNameGenerator = [[ZMUserDisplayNameGenerator alloc] initWithManagedObjectContext:self];
    }];
}

- (void)resetContextType
{
    [self performBlockAndWait:^{
        self.userInfo[IsSyncContextKey] = @NO;
        self.userInfo[IsUserInterfaceContextKey] = @NO;
        self.userInfo[IsSearchContextKey] = @NO;
    }];
}

- (void)disableObjectRefresh;
{
    self.userInfo[IsRefreshOfObjectsDisabled] = @YES;
}

@end



@implementation NSManagedObjectContext (CleanUp)

- (void)refreshUnneededObjects
{
    if(self.zm_shouldRefreshObjectsWithSyncContextPolicy) {
        [ZMConversation refreshObjectsThatAreNotNeededInSyncContext:self];
    }
}


@end
