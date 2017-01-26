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
@import ZMTransport;
@import ZMCMockTransport;
@import ZMCDataModel;

#import "MessagingTest.h"
#import <libkern/OSAtomic.h>
#import <CommonCrypto/CommonCrypto.h>
#import "WireMessageStrategyTests-Swift.h"

NSString *const ZMPersistedClientIdKey = @"PersistedClientId";


@interface MessagingTest () 

@property (nonatomic) NSManagedObjectContext *uiMOC;
@property (nonatomic) NSManagedObjectContext *syncMOC;
@property (nonatomic) NSURL *storeURL;
@property (nonatomic) NSURL *keyStoreURL;

@property (nonatomic) NSTimeInterval originalConversationLastReadTimestampTimerValue; // this will speed up the tests A LOT
@property (nonatomic) MockTransportSession *mockTransportSession;

@end

@interface MessagingTest (Caches)
+ (void)deleteAllFilesInCache;
@end


@implementation MessagingTest

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

- (BOOL)shouldUseRealKeychain;
{
    return NO;
}

- (BOOL)shouldUseInMemoryStore;
{
    return YES;
}

- (void)setUp;
{
    [super setUp];
    [self deleteAllOtherEncryptionContexts];
    
    self.storeURL = [PersistentStoreRelocator storeURLInDirectory:NSCachesDirectory];
    self.keyStoreURL = [self.storeURL URLByDeletingLastPathComponent];
    
    self.originalConversationLastReadTimestampTimerValue = ZMConversationDefaultLastReadTimestampSaveDelay;
    ZMConversationDefaultLastReadTimestampSaveDelay = 0.02;

    
    NSString *testName = NSStringFromSelector(self.invocation.selector);
    NSString *methodName = [NSString stringWithFormat:@"setup%@%@", [testName substringToIndex:1].capitalizedString, [testName substringFromIndex:1]];
    SEL selector = NSSelectorFromString(methodName);
    if ([self respondsToSelector:selector]) {
        ZM_SILENCE_CALL_TO_UNKNOWN_SELECTOR([self performSelector:selector]);
    }

    [NSManagedObjectContext setUseInMemoryStore:self.shouldUseInMemoryStore];

    [self resetState];
    
    if (self.shouldUseRealKeychain) {
        [ZMPersistentCookieStorage setDoNotPersistToKeychain:NO];
        
#if ! TARGET_IPHONE_SIMULATOR
        // On the Xcode Continuous Intergration server the tests run as a user whose username starts with an underscore.
        BOOL const runningOnIntegrationServer = [[[NSProcessInfo processInfo] environment][@"USER"] hasPrefix:@"_"];
        if (runningOnIntegrationServer) {
            [ZMPersistentCookieStorage setDoNotPersistToKeychain:YES];
        }
#endif
    } else {
        [ZMPersistentCookieStorage setDoNotPersistToKeychain:YES];
    }
    
    [self resetUIandSyncContextsAndResetPersistentStore:YES];
    
    [ZMPersistentCookieStorage deleteAllKeychainItems];
    self.mockTransportSession = [[MockTransportSession alloc] initWithDispatchGroup:self.dispatchGroup];
    Require([self waitForAllGroupsToBeEmptyWithTimeout:5]);
}

- (void)tearDown;
{
    ZMConversationDefaultLastReadTimestampSaveDelay = self.originalConversationLastReadTimestampTimerValue;
    [self resetState];
    [MessagingTest deleteAllFilesInCache];
    [super tearDown];
    [self deleteAllOtherEncryptionContexts];
    Require([self waitForAllGroupsToBeEmptyWithTimeout:5]);
}

- (void)resetState
{
    [self.uiMOC.globalManagedObjectContextObserver tearDown];
    [self.uiMOC zm_teardownMessageDeletionTimer];
    
    [self.syncMOC performGroupedBlock:^{
        [self.syncMOC.globalManagedObjectContextObserver tearDown];
        [self.syncMOC zm_tearDownCryptKeyStore];
        [self.syncMOC zm_teardownMessageObfuscationTimer];
        [self.syncMOC.userInfo removeAllObjects];
    }];

    WaitForAllGroupsToBeEmpty(0.5);
    
    // teardown all mmanagedObjectContexts
    [self cleanUpAndVerify];
    
    [self.mockTransportSession tearDown];
    self.mockTransportSession = nil;
    
    self.ignoreTestDebugFlagForTestTimers = NO;
    [NSManagedObjectContext resetUserInterfaceContext];
    [NSManagedObjectContext resetSharedPersistentStoreCoordinator];
}

- (void)waitAndDeleteAllManagedObjectContexts;
{
    NSManagedObjectContext *refUiMOC = self.uiMOC;
    NSManagedObjectContext *refSyncMoc = self.syncMOC;
    
    WaitForAllGroupsToBeEmpty(2);
    
    self.uiMOC = nil;
    self.syncMOC = nil;
    
    [refUiMOC performBlockAndWait:^{
        // Do nothing.
    }];
    [refSyncMoc performBlockAndWait:^{
        
    }];
    [self.mockTransportSession.managedObjectContext performBlockAndWait:^{
        // Do nothing
    }];
    [refUiMOC.globalManagedObjectContextObserver tearDown];

    [refSyncMoc performGroupedBlockAndWait:^{
        [refSyncMoc.globalManagedObjectContextObserver tearDown];
    }];
}

- (void)cleanUpAndVerify {
    //[self.mockTransportSession expireAllBlockedRequests];
    [self waitAndDeleteAllManagedObjectContexts];
    [self verifyMocksNow];
}

- (void)resetUIandSyncContextsAndResetPersistentStore:(BOOL)resetPersistentStore
{
    [self resetUIandSyncContextsAndResetPersistentStore:resetPersistentStore notificationContentHidden:NO];
}

- (void)resetUIandSyncContextsAndResetPersistentStore:(BOOL)resetPersistentStore notificationContentHidden:(BOOL)notificationContentVisible;
{
    [self.syncMOC.globalManagedObjectContextObserver tearDown];
    [self.uiMOC.globalManagedObjectContextObserver tearDown];
    
    NSString *clientID = [self.uiMOC persistentStoreMetadataForKey:ZMPersistedClientIdKey];
    self.uiMOC = nil;
    self.syncMOC = nil;
    
    WaitForAllGroupsToBeEmpty(2);
    
    [NSManagedObjectContext resetUserInterfaceContext];
    
    if (resetPersistentStore) {
        [NSManagedObjectContext resetSharedPersistentStoreCoordinator];
    }
    [self performIgnoringZMLogError:^{
        self.uiMOC = [NSManagedObjectContext createUserInterfaceContextWithStoreAtURL:self.storeURL];
    }];
    
    ImageAssetCache *imageAssetCache = [[ImageAssetCache alloc] initWithMBLimit:100 location:nil];
    FileAssetCache *fileAssetCache = [[FileAssetCache alloc] initWithLocation:nil];
    
    [self.uiMOC addGroup:self.dispatchGroup];
    self.uiMOC.userInfo[@"TestName"] = self.name;
    
    self.syncMOC = [NSManagedObjectContext createSyncContextWithStoreAtURL:self.storeURL keyStoreURL:self.keyStoreURL];
    [self.syncMOC performGroupedBlockAndWait:^{
        self.syncMOC.userInfo[@"TestName"] = self.name;
        [self.syncMOC addGroup:self.dispatchGroup];
        [self.syncMOC saveOrRollback];
        
        [self.syncMOC setZm_userInterfaceContext:self.uiMOC];
        [self.syncMOC setPersistentStoreMetadata:@(notificationContentVisible) forKey:@"ZMShouldNotificationContentKey"];
        self.syncMOC.zm_imageAssetCache = imageAssetCache;
        self.syncMOC.zm_fileAssetCache = fileAssetCache;
    }];
    
    WaitForAllGroupsToBeEmpty(2);
    
    [self.uiMOC setPersistentStoreMetadata:clientID forKey:ZMPersistedClientIdKey];
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(2);
    
    
    [self.uiMOC setZm_syncContext:self.syncMOC];
    [self.uiMOC   setPersistentStoreMetadata:@(notificationContentVisible) forKey:@"ZMShouldNotificationContentKey"];

    self.uiMOC.zm_imageAssetCache = imageAssetCache;
    self.uiMOC.zm_fileAssetCache = fileAssetCache;
}


- (BOOL)waitWithTimeout:(NSTimeInterval)timeout forSaveOfContext:(NSManagedObjectContext *)moc untilBlock:(BOOL(^)(void))block;
{
    Require(moc != nil);
    Require(block != nil);
    
    timeout = [MessagingTest timeToUseForOriginalTime:timeout];
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    NSDate * const start = [NSDate date];
    NSNotificationCenter * const center = [NSNotificationCenter defaultCenter];
    id token = [center addObserverForName:NSManagedObjectContextDidSaveNotification object:moc queue:nil usingBlock:^(NSNotification *note) {
        NOT_USED(note);
        if (block()) {
            dispatch_semaphore_signal(sem);
        }
    }];
    
    BOOL success = NO;
    
    // We try to block the current thread as much as possible to not use too much CPU:
    NSDate * const stopDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    while ((! success) && (NSDate.timeIntervalSinceReferenceDate < stopDate.timeIntervalSinceReferenceDate)) {
        // Block this thread for a bit:
        NSTimeInterval const blockingTimeout = 0.01;
        success = (0 == dispatch_semaphore_wait(sem, dispatch_walltime(NULL, llround(blockingTimeout * NSEC_PER_SEC))));
        // Let anything on the main run loop run:
        [MessagingTest performRunLoopTick];
    }
    
    [center removeObserver:token];
    PrintTimeoutWarning(self, timeout, -[start timeIntervalSinceNow]);
    return success;
}


@end



@implementation MessagingTest (Asyncronous)

- (NSArray *)allManagedObjectContexts;
{
    NSMutableArray *result = [NSMutableArray array];
    if (self.uiMOC != nil) {
        [result addObject:self.uiMOC];
    }
    if (self.syncMOC != nil) {
        [result addObject:self.syncMOC];
    }
    if (self.mockTransportSession.managedObjectContext != nil) {
        [result addObject:self.mockTransportSession.managedObjectContext];
    }
    return result;
}

- (NSArray *)allDispatchGroups;
{
    NSMutableArray *groups = [NSMutableArray array];
    [groups addObject:self.dispatchGroup];
    for (NSManagedObjectContext *moc in self.allManagedObjectContexts) {
        [groups addObject:moc.dispatchGroup];
    }
    return groups;
}

@end




@implementation MessagingTest (FilesInCache)

+ (NSURL *)cacheFolder {
    return (NSURL *)[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject;
}

+ (void)deleteAllFilesInCache {
    NSFileManager *fm = [NSFileManager defaultManager];
    for(NSURL *url in [self filesInCache]) {
        [fm removeItemAtURL:url error:nil];
    }
}

+ (NSSet *)filesInCache {
    return [NSSet setWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtURL:[self cacheFolder] includingPropertiesForKeys:@[NSURLNameKey] options:0 error:nil]];
}

@end


@implementation MessagingTest (OTR)

- (UserClient *)createSelfClient
{
    ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
    selfUser.remoteIdentifier = selfUser.remoteIdentifier ?: [NSUUID createUUID];
    
    UserClient *selfClient = [UserClient insertNewObjectInManagedObjectContext:self.syncMOC];
    selfClient.remoteIdentifier = [NSString createAlphanumericalString];
    selfClient.user = selfUser;
    
    [self.syncMOC setPersistentStoreMetadata:selfClient.remoteIdentifier forKey:ZMPersistedClientIdKey];
    
    [UserClient createOrUpdateClient:@{@"id": selfClient.remoteIdentifier, @"type": @"permanent", @"time": [[NSDate date] transportString]} context:self.syncMOC];
    [self.syncMOC saveOrRollback];
    
    return selfClient;
}

- (UserClient *)createClientForUser:(ZMUser *)user createSessionWithSelfUser:(BOOL)createSessionWithSeflUser
{
    if(user.remoteIdentifier == nil) {
        user.remoteIdentifier = [NSUUID createUUID];
    }
    UserClient *userClient = [UserClient insertNewObjectInManagedObjectContext:self.syncMOC];
    userClient.remoteIdentifier = [NSString createAlphanumericalString];
    userClient.user = user;
    
    if (createSessionWithSeflUser) {
        [self establishSessionFromSelfToClient:userClient];
    }

    return userClient;
}

- (UserClient *)createClientForMockUser:(MockUser *)mockUser createSessionWithSelfUser:(BOOL)createSessionWithSeflUser
{
    ZMUser *user = [ZMUser fetchObjectWithRemoteIdentifier:mockUser.identifier.UUID inManagedObjectContext:self.syncMOC];
    if(user) {
        return [self createClientForUser:user createSessionWithSelfUser:createSessionWithSeflUser];
    }
    return nil;
}

- (ZMClientMessage *)createClientTextMessage:(BOOL)encrypted
{
    return [self createClientTextMessage:self.name encrypted:encrypted];
}

- (ZMClientMessage *)createClientTextMessage:(NSString *)text encrypted:(BOOL)encrypted
{
    ZMClientMessage *message = [ZMClientMessage insertNewObjectInManagedObjectContext:self.syncMOC];
    NSUUID *messageNonce = [NSUUID createUUID];
    ZMGenericMessage *textMessage = [ZMGenericMessage messageWithText:text nonce:messageNonce.transportString expiresAfter:nil];
    [message addData:textMessage.data];
    message.isEncrypted = encrypted;
    return message;
}


- (ZMAssetClientMessage *)createImageMessageWithImageData:(NSData *)imageData format:(ZMImageFormat)format processed:(BOOL)processed stored:(BOOL)stored encrypted:(BOOL)encrypted ephemeral:(BOOL)ephemeral moc:(NSManagedObjectContext *)moc
{
    NSUUID *nonce = [NSUUID createUUID];
    ZMAssetClientMessage *imageMessage = [ZMAssetClientMessage assetClientMessageWithOriginalImageData:imageData nonce:nonce managedObjectContext:moc expiresAfter:ephemeral ? 10 : 0];
    imageMessage.isEncrypted = encrypted;
    
    if(processed) {
        
        CGSize imageSize = [ZMImagePreprocessor sizeOfPrerotatedImageWithData:imageData];
        ZMIImageProperties *properties = [ZMIImageProperties imagePropertiesWithSize:imageSize
                                                                              length:imageData.length
                                                                            mimeType:@"image/jpeg"];
        ZMImageAssetEncryptionKeys *keys = nil;
        if (encrypted) {
            keys = [[ZMImageAssetEncryptionKeys alloc] initWithOtrKey:[NSData zmRandomSHA256Key]
                                                               macKey:[NSData zmRandomSHA256Key]
                                                                  mac:[NSData zmRandomSHA256Key]];
        }
        
        ZMGenericMessage *message = [ZMGenericMessage genericMessageWithMediumImageProperties:properties processedImageProperties:properties encryptionKeys:keys nonce:nonce.transportString format:format expiresAfter:ephemeral ? @10 : nil];
        [imageMessage addGenericMessage:message];
        
        ImageAssetCache *directory = self.uiMOC.zm_imageAssetCache;
        if (stored) {
            [directory storeAssetData:nonce format:ZMImageFormatOriginal encrypted:NO data:imageData];
        }
        if (processed) {
            [directory storeAssetData:nonce format:format encrypted:NO data:imageData];
        }
        if (encrypted) {
            [directory storeAssetData:nonce format:format encrypted:YES data:imageData];
        }
    }
    return imageMessage;
}

- (ZMAssetClientMessage *)createImageMessageWithImageData:(NSData *)imageData format:(ZMImageFormat)format processed:(BOOL)processed stored:(BOOL)stored encrypted:(BOOL)encrypted moc:(NSManagedObjectContext *)moc
{
    return [self createImageMessageWithImageData:imageData format:format processed:processed stored:stored encrypted:encrypted ephemeral:NO moc:moc];
}

@end

