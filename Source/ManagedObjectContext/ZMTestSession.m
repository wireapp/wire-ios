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


#import "ZMTestSession.h"
#import <ZMCDataModel/ZMCDataModel-Swift.h>

#import "NSManagedObjectContext+zmessaging.h"
#import "NSManagedObjectContext+tests.h"


NSString *const ZMPersistedClientIdKey = @"PersistedClientId";


@interface ZMTestSession ()

@property (nonatomic) NSManagedObjectContext *uiMOC;
@property (nonatomic) NSManagedObjectContext *syncMOC;
@property (nonatomic) NSManagedObjectContext *searchMOC;
@property (nonatomic) ZMSDispatchGroup *dispatchGroup;
@property (nonatomic) NSString *testName;
@property (nonatomic) NSURL *databaseDirectory;
@property (nonatomic) NSURL *storeURL;

@property (nonatomic) NSTimeInterval originalConversationLastReadTimestampTimerValue; // this will speed up the tests A LOT

@end




@implementation ZMTestSession

- (instancetype)initWithDispatchGroup:(ZMSDispatchGroup *)dispatchGroup
{
    self = [super init];
    
    if (self) {
        _dispatchGroup = dispatchGroup;
        _shouldUseInMemoryStore = YES;
    }
    
    return self;
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

- (void)prepareForTestNamed:(NSString *)testName
{
    self.testName = testName;
    self.originalConversationLastReadTimestampTimerValue = ZMConversationDefaultLastReadTimestampSaveDelay;
    ZMConversationDefaultLastReadTimestampSaveDelay = 0.02;
    
    self.storeURL = [PersistentStoreRelocator storeURLInDirectory:NSDocumentDirectory];
    self.databaseDirectory = self.storeURL.URLByDeletingLastPathComponent;
    
    [NSManagedObjectContext setUseInMemoryStore:self.shouldUseInMemoryStore];
    
    [self resetState];
    
    [ZMPersistentCookieStorage setDoNotPersistToKeychain:!self.shouldUseRealKeychain];
    [self resetUIandSyncContextsAndResetPersistentStore:YES];
    [ZMPersistentCookieStorage deleteAllKeychainItems];
    
    self.searchMOC = [NSManagedObjectContext createSearchContextWithStoreAtURL:self.storeURL];
    [self.searchMOC addGroup:self.dispatchGroup];
}

- (void)tearDown;
{
    [self wipeCaches];
    ZMConversationDefaultLastReadTimestampSaveDelay = self.originalConversationLastReadTimestampTimerValue;
    [self resetState];
}

- (void)resetState
{
    [self waitAndDeleteAllManagedObjectContexts];
    [self.syncMOC.globalManagedObjectContextObserver tearDown];
    [self.uiMOC.globalManagedObjectContextObserver tearDown];
    
    self.uiMOC = nil;
    self.syncMOC = nil;
    
    [NSManagedObjectContext resetUserInterfaceContext];
    [NSManagedObjectContext resetSharedPersistentStoreCoordinator];
}

- (void)waitAndDeleteAllManagedObjectContexts
{
    NSManagedObjectContext *refUiMOC = self.uiMOC;
    NSManagedObjectContext *refSearchMoc = self.searchMOC;
    NSManagedObjectContext *refSyncMoc = self.syncMOC;
    
    [self.dispatchGroup waitWithTimeout:2];
    
    self.uiMOC = nil;
    self.syncMOC = nil;
    self.searchMOC = nil;
    
    [refUiMOC performBlockAndWait:^{
        // Do nothing.
    }];
    [refSyncMoc performBlockAndWait:^{
        
    }];
    [refSearchMoc performBlockAndWait:^{
        // Do nothing
    }];
    
    [refUiMOC.globalManagedObjectContextObserver tearDown];
    [refSyncMoc performGroupedBlockAndWait:^{
        [refSyncMoc.globalManagedObjectContextObserver tearDown];
    }];
}

- (void)resetUIandSyncContextsAndResetPersistentStore:(BOOL)resetPersistentStore
{
    [self.syncMOC performGroupedBlockAndWait:^ {        
        [self.syncMOC.globalManagedObjectContextObserver tearDown];
    }];
    [self.uiMOC.globalManagedObjectContextObserver tearDown];
    
    NSString *clientID = [self.uiMOC persistentStoreMetadataForKey:ZMPersistedClientIdKey];
    self.uiMOC = nil;
    self.syncMOC = nil;
    
    [self.dispatchGroup waitWithTimeout:2];
    
    [NSManagedObjectContext resetUserInterfaceContext];
    
    if (resetPersistentStore) {
        [NSManagedObjectContext resetSharedPersistentStoreCoordinator];
    }
    
    // NOTE this produces logs if self.useInMemoryStore = NO
    self.uiMOC = [NSManagedObjectContext createUserInterfaceContextWithStoreAtURL:self.storeURL];
    self.uiMOC.globalManagedObjectContextObserver.propagateChanges = YES;
    [self.uiMOC addGroup:self.dispatchGroup];
    self.uiMOC.userInfo[@"TestName"] = self.testName;
    [self performPretendingUiMocIsSyncMoc:^{
        [self.uiMOC setupUserKeyStoreForDirectory:self.databaseDirectory];
    }];
    
    self.syncMOC = [NSManagedObjectContext createSyncContextWithStoreAtURL:self.storeURL keyStoreURL:self.databaseDirectory];
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
}

- (void)setUpCaches
{
    self.uiMOC.zm_imageAssetCache = [[ImageAssetCache alloc] initWithMBLimit:5 location:nil];
    self.uiMOC.zm_userImageCache = [[UserImageLocalCache alloc] initWithLocation:nil];
    self.uiMOC.zm_fileAssetCache = [[FileAssetCache alloc] initWithLocation:nil];

    [self.syncMOC performGroupedBlockAndWait:^{
        self.syncMOC.zm_imageAssetCache = self.uiMOC.zm_imageAssetCache;
        self.syncMOC.zm_fileAssetCache = self.uiMOC.zm_fileAssetCache;
        self.syncMOC.zm_userImageCache = self.uiMOC.zm_userImageCache;
    }];
}

- (void)wipeCaches
{
    [self.uiMOC.zm_fileAssetCache wipeCaches];
    [self.uiMOC.zm_userImageCache wipeCache];
    [self.uiMOC.zm_imageAssetCache wipeCache];

    [self.syncMOC performGroupedBlockAndWait:^{
        [self.syncMOC.zm_fileAssetCache wipeCaches];
        [self.syncMOC.zm_imageAssetCache wipeCache];
        [self.syncMOC.zm_userImageCache wipeCache];
    }];
}

@end
