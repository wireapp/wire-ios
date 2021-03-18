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

#import <WireDataModel/WireDataModel-Swift.h>

#import "ZMTestSession.h"

#import "NSManagedObjectContext+zmessaging.h"
#import "NSManagedObjectContext+tests.h"
@import WireTransport.Testing;

@interface ZMTestSession ()

@property (nonatomic) ManagedObjectContextDirectory *contextDirectory;
@property (nonatomic) ZMSDispatchGroup *dispatchGroup;
@property (nonatomic) NSString *testName;
@property (nonatomic) NSURL *storeURL;
@property (nonatomic) NSURL *containerURL;
@property (nonatomic) NSUUID *accountIdentifier;

@property (nonatomic) NSTimeInterval originalConversationLastReadTimestampTimerValue; // this will speed up the tests A LOT

@end




@implementation ZMTestSession


- (instancetype)initWithDispatchGroup:(ZMSDispatchGroup *)dispatchGroup accountIdentifier:(NSUUID *)identifier
{
    self = [super init];

    if (self) {
        _dispatchGroup = dispatchGroup;
        self.accountIdentifier = identifier;
        self.containerURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
        self.storeURL = [[StorageStack accountFolderWithAccountIdentifier:self.accountIdentifier applicationContainer:self.containerURL] URLAppendingPersistentStoreLocation];
        self.shouldUseInMemoryStore = YES;
    }

    return self;
}

- (instancetype)initWithDispatchGroup:(ZMSDispatchGroup *)dispatchGroup
{
    return [self initWithDispatchGroup:dispatchGroup accountIdentifier:[[NSUUID alloc] init]];
}

- (NSManagedObjectContext *)uiMOC
{
    return self.contextDirectory.uiContext;
}


- (NSManagedObjectContext *)syncMOC
{
    return self.contextDirectory.syncContext;
}


- (NSManagedObjectContext *)searchMOC
{
    return self.contextDirectory.searchContext;
}

- (void)performPretendingUiMocIsSyncMoc:(void(^)(void))block;
{
    if(!block) {
        return;
    }
    [self.uiMOC resetContextType];
    [self.uiMOC markAsSyncContext];
    block();
    [self.uiMOC resetContextType];
    [self.uiMOC markAsUIContext];
}

- (void)performPretendingSyncMocIsUiMoc:(void(^)(void))block;
{
    if(!block) {
        return;
    }
    [self.syncMOC resetContextType];
    [self.syncMOC markAsUIContext];
    block();
    [self.syncMOC resetContextType];
    [self.syncMOC markAsSyncContext];
}

- (void)prepareForTestNamed:(NSString *)testName
{
    self.testName = testName;
    self.originalConversationLastReadTimestampTimerValue = ZMConversationDefaultLastReadTimestampSaveDelay;
    ZMConversationDefaultLastReadTimestampSaveDelay = 0.02;
    
    [self waitAndDeleteAllManagedObjectContexts];
    
    [ZMPersistentCookieStorage setDoNotPersistToKeychain:!self.shouldUseRealKeychain];
    [self resetUIandSyncContextsAndResetPersistentStore:YES];
    
}

- (void)tearDown;
{
    [self wipeCaches];
    ZMConversationDefaultLastReadTimestampSaveDelay = self.originalConversationLastReadTimestampTimerValue;
    [self waitAndDeleteAllManagedObjectContexts];
    self.contextDirectory = nil;
    [StorageStack reset];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.containerURL includingPropertiesForKeys:nil options:0 error:nil];
    for (NSURL *file in files){
        [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
    }
}

- (void)waitAndDeleteAllManagedObjectContexts
{
    NSManagedObjectContext *refUiMOC = self.uiMOC;
    NSManagedObjectContext *refSearchMoc = self.searchMOC;
    NSManagedObjectContext *refSyncMoc = self.syncMOC;

    [self.dispatchGroup waitWithTimeout:2];

    [StorageStack reset];
    [[StorageStack shared] setCreateStorageAsInMemory:self.shouldUseInMemoryStore];

    [refUiMOC performBlockAndWait:^{
        // Do nothing.
    }];
    [refSyncMoc performBlockAndWait:^{
        
    }];
    [refSearchMoc performBlockAndWait:^{
        // Do nothing
    }];
}

- (BOOL)waitUntilDate:(NSDate *)runUntil verificationBlock:(BOOL(^)(void))block;
{
    BOOL success = NO;
    while (! success && (0. < [runUntil timeIntervalSinceNow])) {
        
        if (! [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]]) {
            [NSThread sleepForTimeInterval:0.005];
        }
        
        if ((block != nil) && block()) {
            success = YES;
            break;
        }
    }
    return success;
}

- (void)resetUIandSyncContextsAndResetPersistentStore:(BOOL)resetPersistentStore
{
    NSString *clientID = [self.uiMOC persistentStoreMetadataForKey:ZMPersistedClientIdKey];
    
    if (resetPersistentStore) {
        [StorageStack reset];
        [[StorageStack shared] setCreateStorageAsInMemory:self.shouldUseInMemoryStore];
    }
    self.contextDirectory = nil;
    [[StorageStack shared] createManagedObjectContextDirectoryForAccountIdentifier:self.accountIdentifier
                                                              applicationContainer:self.containerURL
                                                                     dispatchGroup:self.dispatchGroup
                                                          startedMigrationCallback:nil
                                                    databaseLoadingFailureCallBack:nil
                                                                 completionHandler:^(ManagedObjectContextDirectory * directory) {
        self.contextDirectory = directory;
    }];
    
    NSDate *runUntil = [NSDate dateWithTimeIntervalSinceNow: 5];
    BOOL didCreateDirectory = [self waitUntilDate:runUntil verificationBlock:^BOOL{
        return self.contextDirectory != nil;
    }];
    RequireString(didCreateDirectory, "Did not create context directory. Something might be blocking the main thread?");
    
    // NOTE this produces logs if self.useInMemoryStore = NO
    [self.uiMOC addGroup:self.dispatchGroup];
    self.uiMOC.userInfo[@"TestName"] = self.testName;
    [self performPretendingUiMocIsSyncMoc:^{
        NSURL *url = [StorageStack accountFolderWithAccountIdentifier:self.accountIdentifier applicationContainer:self.containerURL];
        [self.uiMOC setupUserKeyStoreInAccountDirectory:url applicationContainer:self.containerURL];
    }];
    
    [self.syncMOC performGroupedBlockAndWait:^{
        self.syncMOC.userInfo[@"TestName"] = self.testName;
        [self.syncMOC addGroup:self.dispatchGroup];
        [self.syncMOC saveOrRollback];
    }];
    [self.dispatchGroup waitWithTimeout:2];
    
    [self.uiMOC setPersistentStoreMetadata:clientID forKey:ZMPersistedClientIdKey];
    [self.uiMOC saveOrRollback];
    [self.dispatchGroup waitWithTimeout:2];
    
    [self.syncMOC performGroupedBlockAndWait:^{
        [self.syncMOC setZm_userInterfaceContext:self.uiMOC];
    }];
    [self.uiMOC setZm_syncContext:self.syncMOC];
    [self setUpCaches];
    
    [self.searchMOC addGroup:self.dispatchGroup];
}

- (void)setUpCaches
{
    self.uiMOC.zm_userImageCache = [[UserImageLocalCache alloc] initWithLocation:nil];
    self.uiMOC.zm_fileAssetCache = [[FileAssetCache alloc] initWithLocation:nil];
    
    [self.syncMOC performGroupedBlockAndWait:^{
        self.syncMOC.zm_fileAssetCache = self.uiMOC.zm_fileAssetCache;
        self.syncMOC.zm_userImageCache = self.uiMOC.zm_userImageCache;
    }];
}

- (void)wipeCaches
{
    [self.uiMOC.zm_fileAssetCache wipeCaches];
    [self.uiMOC.zm_userImageCache wipeCache];
    
    [self.syncMOC performGroupedBlockAndWait:^{
        [self.syncMOC.zm_fileAssetCache wipeCaches];
        [self.syncMOC.zm_userImageCache wipeCache];
    }];
    [PersonName.stringsToPersonNames removeAllObjects];
}

@end
