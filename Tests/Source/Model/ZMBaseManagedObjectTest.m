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


#import "ZMBaseManagedObjectTest.h"
#import <libkern/OSAtomic.h>
#import <CommonCrypto/CommonCrypto.h>

#import "ZMClientMessage.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "NSManagedObjectContext+tests.h"
#import "MockModelObjectContextFactory.h"
#import "ZMAssetClientMessage.h"

#import "ZMUser+Internal.h"
#import "ZMConversation+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMUserDisplayNameGenerator.h"
#import "ZMConversation+UnreadCount.h"

#import "NSString+RandomString.h"

static const int32_t Mersenne1 = 524287;
static const int32_t Mersenne2 = 131071;
static const int32_t Mersenne3 = 8191;
NSString *const ZMPersistedClientIdKey = @"PersistedClientId";


@interface ZMBaseManagedObjectTest ()

@property (nonatomic) NSManagedObjectContext *uiMOC;
@property (nonatomic) NSManagedObjectContext *syncMOC;
@property (nonatomic) NSManagedObjectContext *testMOC;
@property (nonatomic) NSManagedObjectContext *alternativeTestMOC;
@property (nonatomic) NSManagedObjectContext *searchMOC;


@property (nonatomic) NSTimeInterval originalConversationLastReadEventIDTimerValue; // this will speed up the tests A LOT

@end




@implementation ZMBaseManagedObjectTest
{
    dispatch_semaphore_t _successSemaphore;
    int32_t successCount;
    int32_t completionCount;
    int32_t verySmallJPEGData;
}

- (BOOL)shouldSlowTestTimers
{
    return [self.class isDebuggingTests] && !self.ignoreTestDebugFlagForTestTimers;
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
    
    self.originalConversationLastReadEventIDTimerValue = ZMConversationDefaultLastReadEventIDSaveDelay;
    ZMConversationDefaultLastReadEventIDSaveDelay = 0.02;
    
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
    
    [self reseedImageCounter];
    _successSemaphore = dispatch_semaphore_create(0);
    
    self.testMOC = [MockModelObjectContextFactory testContext];
    [self.testMOC addGroup:self.dispatchGroup];
    self.alternativeTestMOC = [MockModelObjectContextFactory alternativeMocForPSC:self.testMOC.persistentStoreCoordinator];
    [self.alternativeTestMOC addGroup:self.dispatchGroup];
    self.searchMOC = [NSManagedObjectContext createSearchContext];
    [self.searchMOC addGroup:self.dispatchGroup];
    WaitForAllGroupsToBeEmpty(500); // we want the test to get stuck if there is something wrong. Better than random failures
}

- (void)tearDown;
{
    ZMConversationDefaultLastReadEventIDSaveDelay = self.originalConversationLastReadEventIDTimerValue;
    [self resetState];
    [self wipeCaches];
    [super tearDown];
    WaitForAllGroupsToBeEmpty(500); // we want the test to get stuck if there is something wrong. Better than random failures
}

- (void)resetState
{
    [self cleanUpAndVerify];
    [self.syncMOC.globalManagedObjectContextObserver tearDown];
    [self.uiMOC.globalManagedObjectContextObserver tearDown];
    
    self.uiMOC = nil;
    self.syncMOC = nil;
    self.testMOC = nil;
    self.alternativeTestMOC = nil;
    
    successCount = 0;
    completionCount = 0;
    self.ignoreTestDebugFlagForTestTimers = NO;
    [NSManagedObjectContext resetUserInterfaceContext];
    [NSManagedObjectContext resetSharedPersistentStoreCoordinator];
}

- (void)waitAndDeleteAllManagedObjectContexts;
{
    NSManagedObjectContext *refUiMOC = self.uiMOC;
    NSManagedObjectContext *refTestMOC = self.testMOC;
    NSManagedObjectContext *refAlternativeTestMOC = self.alternativeTestMOC;
    NSManagedObjectContext *refSearchMoc = self.searchMOC;
    NSManagedObjectContext *refSyncMoc = self.syncMOC;
    
    WaitForAllGroupsToBeEmpty(2);
    
    self.uiMOC = nil;
    self.syncMOC = nil;
    self.testMOC = nil;
    self.alternativeTestMOC = nil;
    self.searchMOC = nil;
    
    [refUiMOC performBlockAndWait:^{
        // Do nothing.
    }];
    [refSyncMoc performBlockAndWait:^{
        
    }];
    [refTestMOC performBlockAndWait:^{
        // Do nothing
    }];
    [refAlternativeTestMOC performBlockAndWait:^{
        // Do nothing
    }];
    [refSearchMoc performBlockAndWait:^{
        // Do nothing
    }];
    
    [refUiMOC.globalManagedObjectContextObserver tearDown];
    [refSyncMoc.globalManagedObjectContextObserver tearDown];
}

- (void)cleanUpAndVerify {
    [self waitAndDeleteAllManagedObjectContexts];
    [self verifyMocksNow];
}

- (void)resetUIandSyncContextsAndResetPersistentStore:(BOOL)resetPersistentStore
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
        self.uiMOC = [NSManagedObjectContext createUserInterfaceContext];
    }];
    [self.uiMOC addGroup:self.dispatchGroup];
    self.uiMOC.userInfo[@"TestName"] = self.name;
    
    self.syncMOC = [NSManagedObjectContext createSyncContext];
    [self.syncMOC performGroupedBlockAndWait:^{
        self.syncMOC.userInfo[@"TestName"] = self.name;
    }];
    [self.syncMOC addGroup:self.dispatchGroup];
    [self.syncMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(2);
    
    [self.uiMOC setPersistentStoreMetadata:clientID forKey:ZMPersistedClientIdKey];
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(2);
    
    [self.syncMOC setZm_userInterfaceContext:self.uiMOC];
    [self.uiMOC setZm_syncContext:self.syncMOC];
}


static int32_t eventIdCounter;

- (ZMEventID *)createEventID
{
    return [self.class createEventID];
}

+ (ZMEventID *)createEventID
{
    int32_t major = OSAtomicIncrement32(&eventIdCounter) + 1;
    major += 1;
    int32_t minor = ((Mersenne1 * OSAtomicIncrement32(&eventIdCounter)) % Mersenne2) + Mersenne3;
    return [ZMEventID eventIDWithMajor:(uint64_t)major
                                 minor:(uint64_t)minor];
}


+ (NSInteger)randomSignedIntWithMax:(NSInteger)max;
{
    int32_t c = OSAtomicIncrement32(&eventIdCounter);
    return (((int)c * Mersenne3) + Mersenne2) % (max+1);
}

static int16_t imageCounter;

- (void)reseedImageCounter;
{
    NSData *data = [self.name dataUsingEncoding:NSUTF8StringEncoding];
    union {
        int16_t counter;
        uint8_t md[CC_SHA1_DIGEST_LENGTH];
    } u;
    CC_SHA1(data.bytes, (CC_LONG) data.length, u.md);
    imageCounter = u.counter;
}

- (BOOL)waitWithTimeout:(NSTimeInterval)timeout forSaveOfContext:(NSManagedObjectContext *)moc untilBlock:(BOOL(^)(void))block;
{
    Require(moc != nil);
    Require(block != nil);
    
    timeout = [ZMBaseManagedObjectTest timeToUseForOriginalTime:timeout];
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
        [ZMBaseManagedObjectTest performRunLoopTick];
    }
    
    [center removeObserver:token];
    PrintTimeoutWarning(self, timeout, -[start timeIntervalSinceNow]);
    return success;
}


@end



@implementation ZMBaseManagedObjectTest (Asyncronous)

- (NSArray *)allManagedObjectContexts;
{
    NSMutableArray *result = [NSMutableArray array];
    if (self.uiMOC != nil) {
        [result addObject:self.uiMOC];
    }
    if (self.syncMOC != nil) {
        [result addObject:self.syncMOC];
    }
    if (self.testMOC != nil) {
        [result addObject:self.testMOC];
    }
    if (self.alternativeTestMOC != nil) {
        [result addObject:self.alternativeTestMOC];
    }
    if (self.searchMOC != nil) {
        [result addObject:self.searchMOC];
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


- (XCTestExpectation *)expectationForSaveOnContext:(NSManagedObjectContext *)moc withUpdateOfClass:(Class)aClass handler:(SaveExpectationHandler)handler;
{
    return [self expectationForNotification:NSManagedObjectContextDidSaveNotification object:moc handler:^BOOL(NSNotification *notification) {
        NSSet *updated = notification.userInfo[NSUpdatedObjectsKey];
        for (ZMManagedObject *mo in updated) {
            if ([mo isKindOfClass:aClass] &&
                handler(mo))
            {
                return YES;
            }
        }
        return NO;
    }];
}

@end



@implementation ZMBaseManagedObjectTest (DisplayNameGenerator)

- (void)updateDisplayNameGeneratorWithUsers:(NSArray *)users;
{
    [self.uiMOC saveOrRollback];
    NSNotification *note = [NSNotification notificationWithName:@"TestNotification" object:nil userInfo:@{
                                                                                                          NSInsertedObjectsKey : [NSSet setWithArray:users],
                                                                                                          NSUpdatedObjectsKey :[NSSet set],
                                                                                                          NSDeletedObjectsKey : [NSSet set]
                                                                                                          }];
    [self.uiMOC updateDisplayNameGeneratorWithChanges:note];
}

@end



@implementation ZMBaseManagedObjectTest (UserTesting)

- (void)setEmailAddress:(NSString *)emailAddress onUser:(ZMUser *)user;
{
    user.emailAddress = emailAddress;
}

- (void)setPhoneNumber:(NSString *)phoneNumber onUser:(ZMUser *)user;
{
    user.phoneNumber = phoneNumber;
}

@end



@implementation ZMBaseManagedObjectTest (FilesInCache)

/// Sets up the asset caches on the managed object contexts
- (void)setUpCaches
{
    self.uiMOC.zm_imageAssetCache = [[ImageAssetCache alloc] initWithMBLimit:5];
    self.syncMOC.zm_imageAssetCache = self.uiMOC.zm_imageAssetCache;
    
    self.uiMOC.zm_userImageCache = [[UserImageLocalCache alloc] init];
    self.syncMOC.zm_userImageCache = self.uiMOC.zm_userImageCache;
    
    self.uiMOC.zm_fileAssetCache = [[FileAssetCache alloc] init];
    self.syncMOC.zm_fileAssetCache = self.uiMOC.zm_fileAssetCache;
}

- (void)wipeCaches
{
    [FileAssetCache wipeCaches];
    
    [self.uiMOC.zm_imageAssetCache wipeCache];
    [self.syncMOC.zm_imageAssetCache wipeCache];
    
    [self.uiMOC.zm_userImageCache wipeCache];
    [self.syncMOC.zm_userImageCache wipeCache];
}

@end

@implementation ZMBaseManagedObjectTest (OTR)

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
        UserClient *selfClient = [ZMUser selfUserInContext:self.syncMOC].selfClient;
        NSError *error;
        CBPreKey *key = [selfClient.keysStore lastPreKeyAndReturnError:&error];
        [selfClient establishSessionWithClient:userClient usingPreKey:key.data.base64String];
    }
    return userClient;
}

- (ZMClientMessage *)createClientTextMessage:(BOOL)encrypted
{
    return [self createClientTextMessage:self.name encrypted:encrypted];
}

- (ZMClientMessage *)createClientTextMessage:(NSString *)text encrypted:(BOOL)encrypted
{
    ZMClientMessage *message = [ZMClientMessage insertNewObjectInManagedObjectContext:self.syncMOC];
    NSUUID *messageNonce = [NSUUID createUUID];
    ZMGenericMessage *textMessage = [ZMGenericMessage messageWithText:text nonce:messageNonce.transportString];
    [message addData:textMessage.data];
    message.isEncrypted = encrypted;
    return message;
}

- (ZMAssetClientMessage *)createImageMessageWithImageData:(NSData *)imageData format:(ZMImageFormat)format processed:(BOOL)processed stored:(BOOL)stored encrypted:(BOOL)encrypted moc:(NSManagedObjectContext *)moc
{
    NSUUID *nonce = [NSUUID createUUID];
    ZMAssetClientMessage *imageMessage = [ZMAssetClientMessage assetClientMessageWithOriginalImageData:imageData nonce:nonce managedObjectContext:moc];
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
        
        ZMGenericMessage *message = [ZMGenericMessage messageWithMediumImageProperties:properties processedImageProperties:properties encryptionKeys:keys nonce:nonce.transportString format:format];
        [imageMessage addGenericMessage:message];
        
        if (stored) {
            [self.uiMOC.zm_imageAssetCache storeAssetData:nonce format:ZMImageFormatOriginal encrypted:NO data:imageData];
        }
        if (processed) {
            [self.uiMOC.zm_imageAssetCache storeAssetData:nonce format:format encrypted:NO data:imageData];
        }
        if (encrypted) {
            [self.uiMOC.zm_imageAssetCache storeAssetData:nonce format:format encrypted:YES data:imageData];
        }
    }
    return imageMessage;
}

@end


@implementation  ZMBaseManagedObjectTest (SwiftBridgeConversation)

- (void)simulateUnreadCount:(NSUInteger)unreadCount forConversation:(ZMConversation *)conversation;
{
    BOOL isSyncContext = conversation.managedObjectContext.zm_isSyncContext;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *syncConv = conversation;
        if (!isSyncContext) {
            NSManagedObjectID *objectID = conversation.objectID;
            syncConv = (id)[self.syncMOC objectWithID:objectID];
        }
        syncConv.internalEstimatedUnreadCount = [@(unreadCount) intValue];
        [self.syncMOC saveOrRollback];
    }];
    if (!isSyncContext) {
        [self.uiMOC refreshObject:conversation mergeChanges:YES];
    }
}

- (void)simulateUnreadMissedCallInConversation:(ZMConversation *)conversation;
{
    BOOL isSyncContext = conversation.managedObjectContext.zm_isSyncContext;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *syncConv = conversation;
        if (!isSyncContext) {
            NSManagedObjectID *objectID = conversation.objectID;
            syncConv = (id)[self.syncMOC objectWithID:objectID];
        }
        syncConv.lastUnreadMissedCallDate = [NSDate date];
        [self.syncMOC saveOrRollback];
    }];
    if (!isSyncContext) {
        [self.uiMOC refreshObject:conversation mergeChanges:YES];
    }
}


- (void)simulateUnreadMissedKnockInConversation:(ZMConversation *)conversation;
{
    BOOL isSyncContext = conversation.managedObjectContext.zm_isSyncContext;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *syncConv = conversation;
        if (!isSyncContext) {
            NSManagedObjectID *objectID = conversation.objectID;
            syncConv = (id)[self.syncMOC objectWithID:objectID];
        }
        syncConv.lastUnreadKnockDate = [NSDate date];
        [self.syncMOC saveOrRollback];
    }];
    if (!isSyncContext) {
        [self.uiMOC refreshObject:conversation mergeChanges:YES];
    }
}

@end

