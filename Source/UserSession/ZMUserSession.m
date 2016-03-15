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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


@import UIKit;
@import CoreData;
@import ZMCSystem;
@import ZMUtilities;

#import "ZMUserSession+Background.h"

#import "ZMUserSession+Internal.h"
#import "ZMSyncStrategy.h"
#import "ZMOperationLoop.h"
#import "NSError+ZMUserSessionInternal.h"
#import "ZMCredentials.h"
#import <zmessaging/NSManagedObjectContext+zmessaging.h>
#import "ZMSearchDirectory+Internal.h"
#import <libkern/OSAtomic.h>
#import "ZMAuthenticationStatus.h"
#import "ZMApplicationLaunchStatus.h"
#import "ZMAddressBookTranscoder.h"
#import "ZMPushToken.h"
#import "ZMNotifications+Internal.h"
#import "ZMCommonContactsSearch.h"
#import "ZMConversation+Internal.h"
#import "ZMManagedObject+Internal.h"
#import "ZMBlacklistVerificator.h"
#import "ZMTracing.h"
#import "ZMAddressBookSync.h"
#import "ZMEmptyAddressBookSync.h"
#import "ZMConnection+InvitationToConnect.h"
#import "ZMSyncStateMachine.h"
#import "ZMUserSessionAuthenticationNotification.h"
#import "ZMUserProfileUpdateStatus.h"
#import "NSURL+LaunchOptions.h"
#import "ZMessagingLogs.h"
#import "ZMAddressBook.h"
#import "ZMAddressBookContact.h"
#import "ZMAVSBridge.h"
#import "ZMOnDemandFlowManager.h"
#import "ZMCookie.h"
#import <zmessaging/zmessaging-Swift.h>

#import "ZMStringLengthValidator.h"
#import "ZMEnvironmentsSetup.h"
#import "ZMClientRegistrationStatus.h"
#import "ZMLocalNotificationDispatcher.h"

static NSInteger const MaximumContactsToParse = 10000;

NSString * const ZMPhoneVerificationCodeKey = @"code";
NSString * const ZMLaunchedWithPhoneVerificationCodeNotificationName = @"ZMLaunchedWithPhoneVerificationCode";
NSString * const ZMLaunchedWithPersonalInvitationCodeNotificationName = @"ZMLaunchedWithPersonalInvitationCode";
NSString * const ZMUserSessionFailedToAccessAddressBookNotificationName = @"ZMUserSessionFailedToAccessAddressBook";
NSString * const ZMUserSessionTrackingIdentifierDidChangeNotification = @"ZMUserSessionTrackingIdentifierDidChange";
static NSString * const ZMRequestToOpenSyncConversationNotificationName = @"ZMRequestToOpenSyncConversation";
NSString * const ZMAppendAVSLogNotificationName = @"ZMAppendAVSLogNotification";
NSString * const ZMUserSessionResetPushTokensNotificationName = @"ZMUserSessionResetPushTokensNotification";

static NSString * const AppstoreURL = @"https://itunes.apple.com/us/app/zeta-client/id930944768?ls=1&mt=8";


@interface NSManagedObjectContext (KeyValueStore) <ZMKeyValueStore>
@end


@interface ZMUserSession ()
@property (nonatomic) ZMOperationLoop *operationLoop;
@property (nonatomic) ZMTransportRequest *runningLoginRequest;
@property (nonatomic) BOOL ownsQueue;
@property (nonatomic) ZMTransportSession *transportSession;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) NSManagedObjectContext *syncManagedObjectContext;
@property (nonatomic) id<AVSMediaManager> mediaManager;
@property (atomic) ZMNetworkState networkState;
@property (nonatomic) ZMBlacklistVerificator *blackList;
@property (nonatomic) ZMAPNSEnvironment *apnsEnvironment;
@property (nonatomic) ZMAuthenticationStatus *authenticationStatus;
@property (nonatomic) ZMUserProfileUpdateStatus *userProfileUpdateStatus;
@property (nonatomic) ZMClientRegistrationStatus *clientRegistrationStatus;
@property (nonatomic) ClientUpdateStatus *clientUpdateStatus;
@property (nonatomic) BackgroundAPNSPingBackStatus *pingBackStatus;

@property (nonatomic) ZMApplicationLaunchStatus *applicationLaunchStatus;
@property (nonatomic) GiphyRequestsStatus *giphyRequestStatus;
@property (nonatomic) BOOL isVersionBlacklisted;
@property (nonatomic) NSArray *cachedAddressBookContacts;
@property (nonatomic) dispatch_once_t loadAddressBookContactsOnce;
@property (nonatomic) ZMOnDemandFlowManager *onDemandFlowManager;

@property (nonatomic) ZMPushRegistrant *pushRegistrant;
@property (nonatomic) ZMApplicationRemoteNotification *applicationRemoteNotification;
@property (nonatomic) ZMStoredLocalNotification *pendingLocalNotification;
@property (nonatomic) ZMLocalNotificationDispatcher *localNotificationDispatcher;

/// map from NSUUID to ZMCommonContactsSearchCachedEntry
@property (nonatomic) NSCache *commonContactsCache;

@end

@interface ZMUserSession (AlertView) <UIAlertViewDelegate>
@end


NSURL *__nullable CBCreateTemporaryDirectoryAndReturnURL(void);


NSURL *__nullable CBCreateTemporaryDirectoryAndReturnURL()
{
    NSError *error = nil;
    NSURL *directoryURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]] isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        return nil;
    }
    
    return directoryURL;
}

@implementation ZMUserSession

ZM_EMPTY_ASSERTING_INIT()

+ (BOOL)shouldSendOnlyEncrypted
{
    return [[NSProcessInfo processInfo] environment][@"ZMEncryptionOnly"] != nil;
}

+ (BOOL)needsToPrepareLocalStore
{
    return [NSManagedObjectContext needsToPrepareLocalStore];
}

+ (void)prepareLocalStore:(void (^)())completionHandler
{
    ZMDeploymentEnvironmentType environment = [[ZMDeploymentEnvironment alloc] init].environmentType;
    BOOL shouldBackupCorruptedDatabase = environment == ZMDeploymentEnvironmentTypeInternal || DEBUG;
    [NSManagedObjectContext prepareLocalStoreSync:NO backingUpCorruptedDatabase:shouldBackupCorruptedDatabase completionHandler:completionHandler];
}

+ (BOOL)storeIsReady
{
    return [NSManagedObjectContext storeIsReady];
}

- (instancetype)initWithMediaManager:(id<AVSMediaManager>)mediaManager
{   
    zmSetupEnvironments();
    ZMBackendEnvironment *environment = [[ZMBackendEnvironment alloc] init];
    NSURL *backendURL = environment.backendURL;
    NSURL *websocketURL = environment.backendWSURL;
    
    ZMAPNSEnvironment *apnsEnvironment = [[ZMAPNSEnvironment alloc] init];

    NSManagedObjectContext *syncMOC = [NSManagedObjectContext createSyncContext];

    ZMTransportSession *session = [[ZMTransportSession alloc] initWithBaseURL:backendURL websocketURL:websocketURL keyValueStore:syncMOC];

    UIApplication *application = [UIApplication sharedApplication];
    
    self = [self initWithTransportSession:session syncManagedObjectContext:syncMOC mediaManager:mediaManager apnsEnvironment:apnsEnvironment operationLoop:nil application:application];
    if (self != nil) {
        self.ownsQueue = YES;
        self.loadAddressBookContactsOnce = 0;
    }
    return self;
}

- (instancetype)initWithTransportSession:(ZMTransportSession *)session syncManagedObjectContext:(NSManagedObjectContext *)syncManagedObjectContext mediaManager:(id<AVSMediaManager>)mediaManager apnsEnvironment:(ZMAPNSEnvironment *)apnsEnvironment operationLoop:(ZMOperationLoop *)operationLoop application:(ZMApplication *)application;
{
    self = [super init];
    if(self) {
        zmSetupEnvironments();
        [ZMUserSession enableLogsByEnvironmentVariable];
        self.didStartInitialSync = NO;
        self.apnsEnvironment = apnsEnvironment;
        self.networkIsOnline = YES;
        self.managedObjectContext.isOffline = NO;
        self.managedObjectContext = [NSManagedObjectContext createUserInterfaceContext];
        self.syncManagedObjectContext = syncManagedObjectContext;
        
        self.syncManagedObjectContext.zm_userInterfaceContext = self.managedObjectContext;
        self.managedObjectContext.zm_syncContext = self.syncManagedObjectContext;
        
        ZMCookie *cookie = [[ZMCookie alloc] initWithManagedObjectContext:self.managedObjectContext cookieStorage:session.cookieStorage];
        self.authenticationStatus = [[ZMAuthenticationStatus alloc] initWithManagedObjectContext:syncManagedObjectContext cookie:cookie];
        self.userProfileUpdateStatus = [[ZMUserProfileUpdateStatus alloc] initWithManagedObjectContext:syncManagedObjectContext];
        self.clientUpdateStatus = [[ClientUpdateStatus alloc] initWithSyncManagedObjectContext:syncManagedObjectContext];
        
        self.clientRegistrationStatus = [[ZMClientRegistrationStatus alloc] initWithManagedObjectContext:syncManagedObjectContext
                                                                                 loginCredentialProvider:self.authenticationStatus
                                                                                updateCredentialProvider:self.userProfileUpdateStatus
                                                                                                  cookie:cookie
                                                                              registrationStatusDelegate:self];

        self.applicationLaunchStatus = [[ZMApplicationLaunchStatus alloc] initWithManagedObjectContext:syncManagedObjectContext];
        
        self.giphyRequestStatus = [GiphyRequestsStatus new];
        
        self.localNotificationDispatcher =
        [[ZMLocalNotificationDispatcher alloc] initWithManagedObjectContext:syncManagedObjectContext sharedApplication:application];
        
        self.pingBackStatus = [[BackgroundAPNSPingBackStatus alloc] initWithSyncManagedObjectContext:syncManagedObjectContext
                                                                              authenticationProvider:self.authenticationStatus localNotificationDispatcher:self.localNotificationDispatcher];
        
        self.transportSession = session;
        self.transportSession.clientID = self.selfUserClient.remoteIdentifier;
        self.transportSession.networkStateDelegate = self;
        self.mediaManager = mediaManager;
        
        self.onDemandFlowManager = [[ZMOnDemandFlowManager alloc] initWithMediaManager:self.mediaManager];
        
        _application = application;
        
        NSCache *userImagesCache = [[NSCache alloc] init];
        [self.managedObjectContext setUserImagesCache:userImagesCache];
        [self.syncManagedObjectContext setUserImagesCache:userImagesCache];
        
        self.operationLoop = operationLoop ?: [[ZMOperationLoop alloc] initWithTransportSession:session
                                                                           authenticationStatus:self.authenticationStatus
                                                                        userProfileUpdateStatus:self.userProfileUpdateStatus
                                                                       clientRegistrationStatus:self.clientRegistrationStatus
                                                                             clientUpdateStatus:self.clientUpdateStatus
                                                                        applicationLaunchStatus:self.applicationLaunchStatus
                                                                             giphyRequestStatus:self.giphyRequestStatus
                                                                   backgroundAPNSPingBackStatus:self.pingBackStatus
                                                                    localNotificationdispatcher:self.localNotificationDispatcher
                                                                                   mediaManager:mediaManager
                                                                            onDemandFlowManager:self.onDemandFlowManager
                                                                                          uiMOC:self.managedObjectContext
                                                                                        syncMOC:self.syncManagedObjectContext
                                                                              syncStateDelegate:self];
        
        __weak id weakSelf = self;
        session.accessTokenRenewalFailureHandler = ^(ZMTransportResponse *response) {
            ZMUserSession *strongSelf = weakSelf;
            [strongSelf transportSessionAccessTokenDidFail:response];
        };
        session.accessTokenRenewalSuccessHandler = ^(NSString *token, NSString *type) {
            ZMUserSession *strongSelf = weakSelf;
            [strongSelf transportSessionAccessTokenDidSucceedWithToken:token ofType:type];
        };
        
        self.commonContactsCache = [[NSCache alloc] init];
        self.commonContactsCache.name = @"ZMUserSession commonContactsCache";
        
        [self registerForResetPushTokensNotification];
        [self registerForBackgroundNotifications];
        [self registerForRequestToOpenConversationNotification];
        [self enablePushNotifications];
        [self enableBackgroundFetch];
        ZM_ALLOW_MISSING_SELECTOR([[NSNotificationCenter defaultCenter] addObserver:self
                                                                           selector:@selector(didEnterEventProcessingState:)
                                                                               name:ZMApplicationDidEnterEventProcessingStateNotificationName
                                                                             object:nil]);
    }
    return self;
}

- (void)tearDown
{
    self.mediaManager = nil;
    [self.operationLoop tearDown];
    [self.localNotificationDispatcher tearDown];
    self.localNotificationDispatcher = nil;

    if(self.ownsQueue) {
        [self.transportSession tearDown];
        self.transportSession = nil;
    }
    [self.clientUpdateStatus tearDown];
    self.clientUpdateStatus = nil;
    [self.clientRegistrationStatus tearDown];
    self.clientRegistrationStatus = nil;
    self.authenticationStatus = nil;
    self.applicationLaunchStatus = nil;
    self.userProfileUpdateStatus = nil;
    self.giphyRequestStatus = nil;
    
    NSManagedObjectContext *uiMoc = self.managedObjectContext;
    
    [self.managedObjectContext.globalManagedObjectContextObserver tearDown];
    [self.managedObjectContext zm_tearDownCallTimer];
    self.managedObjectContext = nil;
    self.syncManagedObjectContext = nil;
    
    BOOL shouldWaitOnUiMoc = !([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue] && uiMoc.concurrencyType == NSMainQueueConcurrencyType);
    
    if(shouldWaitOnUiMoc)
    {
        [uiMoc performBlockAndWait:^{ // warning: this will hang if the uiMoc queue is same as self.requestQueue (typically uiMoc queue is the main queue)
            // nop
        }];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)isLoggedIn
{
    return self.authenticationStatus.currentPhase == ZMAuthenticationPhaseAuthenticated &&
    self.clientRegistrationStatus.currentPhase == ZMClientRegistrationPhaseRegistered;
}

- (void)registerForRequestToOpenConversationNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRequestToOpenSyncConversation:) name:ZMRequestToOpenSyncConversationNotificationName object:nil];
}

- (void)registerForBackgroundNotifications;
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)registerForResetPushTokensNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetPushTokens) name:ZMUserSessionResetPushTokensNotificationName object:nil];
}

- (void)didRequestToOpenSyncConversation:(NSNotification *)note
{
    ZM_WEAK(self);
    [self.managedObjectContext performGroupedBlock:^{
        ZM_STRONG(self);
        NSManagedObjectID *objectID = note.object;
        id managedObject = [self.managedObjectContext objectWithID:objectID];
        if(managedObject != nil) {
            [self.requestToOpenViewDelegate showConversation:managedObject];
        }
    }];
}


- (void)saveOrRollbackChanges;
{
    [self.managedObjectContext saveOrRollback];
}

- (void)performChanges:(dispatch_block_t)block;
{
    ZM_WEAK(self);
    [self.managedObjectContext performGroupedBlockAndWait:^{
        ZM_STRONG(self);
        block();
        [self saveOrRollbackChanges];
    }];
}

- (void)enqueueChanges:(dispatch_block_t)block
{
    [self enqueueChanges:block completionHandler:nil];
}

- (void)enqueueChanges:(dispatch_block_t)block completionHandler:(dispatch_block_t)completionHandler;
{
    ZM_WEAK(self);
    [self.managedObjectContext performGroupedBlock:^{
        ZM_STRONG(self);
        block();
        [self saveOrRollbackChanges];
        
        if(completionHandler != nil) {
            completionHandler();
        }
    }];
}

- (void)setMediaManager:(id <AVSMediaManager>)delegate;
{
    NOT_USED(delegate);
}

- (void)startAndCheckClientVersion:(NSString *)appVersion checkInterval:(NSTimeInterval)interval blackListedBlock:(void (^)())blackListed;
{
    [self start];
    ZM_WEAK(self);
    self.blackList = [[ZMBlacklistVerificator alloc] initWithCheckInterval:interval
                                                                   version:appVersion
                                                              workingGroup:self.syncManagedObjectContext.dispatchGroup
                                                         blacklistCallback:^(BOOL isBlackListed) {
        ZM_STRONG(self);
        if (!self.isVersionBlacklisted && isBlackListed && blackListed) {
            blackListed();
            self.isVersionBlacklisted = YES;
        }
    }];
}

- (void)start;
{
    [self didStartApplication];
    [ZMOperationLoop notifyNewRequestsAvailable:self];
}

- (void)didStartApplication
{
    [self.syncManagedObjectContext performGroupedBlock:^{
        if (self.isLoggedIn) {
            [ZMUserSessionAuthenticationNotification notifyAuthenticationDidSucceed];
            return;
        }

        if (self.authenticationStatus.needsCredentialsToLogin) {
            [ZMUserSessionAuthenticationNotification notifyAuthenticationDidFail:[NSError userSessionErrorWithErrorCode:ZMUserSessionNeedsCredentials
                                                                                                               userInfo:nil]];
        } else {
            [self.clientRegistrationStatus prepareForClientRegistration];
        }
    }];
}

- (void)resetPushTokens
{
    // instead of relying on the tokens we have cached locally we should always ask the OS about the latest tokens
    [self.managedObjectContext performGroupedBlockAndWait:^{
        NSData *pushKitToken = self.pushRegistrant.pushToken;
        if (pushKitToken != nil) {
            self.managedObjectContext.pushKitToken = nil;
            [self setPushKitToken:pushKitToken];
        } else {
            ZMLogError(@"The OS did not provide a valid VoIP token, pushRegistry might be nil");
        }
        
        ZMPushToken *pushToken = self.managedObjectContext.pushToken;
        if(pushToken != nil) {
            self.managedObjectContext.pushToken = nil;
            [self setPushToken:pushToken.deviceToken];
        }
        else {
            ZMLogError(@"No stored push token, pushRegistry might be nil");
        }
        
        // according to Apple's documentation, calling [registerForRemoteNotifications] should not cause additional overhead
        // and should return the existing device token to the app delegate via [didRegisterForRemoteNotifications:] immediately
        [self.application registerForRemoteNotifications];
        
        if (![self.managedObjectContext forceSaveOrRollback]) {
            ZMLogError(@"Failed to save push token after refresh");
        }
    }];
}

- (void)initiateUserDeletion
{
    [self.syncManagedObjectContext performGroupedBlock:^{
        [self.syncManagedObjectContext setPersistentStoreMetadata:@YES forKey:[DeleteAccountRequestStrategy userDeletionInitiatedKey]];
        [ZMOperationLoop notifyNewRequestsAvailable:self];
    }];
}

- (void)openAppstore
{
    NSURL *appStoreURL = [NSURL URLWithString:AppstoreURL];
    [[UIApplication sharedApplication] openURL:appStoreURL];
    [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(didNotUpdateApp:) userInfo:nil repeats:NO];
}

- (void)didNotUpdateApp:(NSTimer *)timer;
{
    NOT_USED(timer);
    __builtin_trap();
}

- (void)transportSessionAccessTokenDidFail:(ZMTransportResponse *)response
{
    ZMLogWithLevelAndTag(ZMLogLevelDebug, ZMTAG_NETWORK, @"Access token fail in %@: %@", self.class, NSStringFromSelector(_cmd));
    NOT_USED(response);
    
    [self.managedObjectContext performGroupedBlock:^{
        [ZMUserSessionAuthenticationNotification notifyAuthenticationDidFail:[NSError userSessionErrorWithErrorCode:ZMUserSessionNeedsCredentials userInfo:nil]];
    }];
}

- (void)transportSessionAccessTokenDidSucceedWithToken:(NSString *)token ofType:(NSString *)type;
{
    ZMLogWithLevelAndTag(ZMLogLevelDebug, ZMTAG_NETWORK, @"Access token succeeded in %@: %@", self.class, NSStringFromSelector(_cmd));
    
    [self.syncManagedObjectContext performGroupedBlock:^{
        [self.operationLoop accessTokenDidChangeWithToken:token ofType:type];
    }];
}

- (NSString *)trackingIdentifier;
{
    return self.managedObjectContext.userSessionTrackingIdentifier;
}

- (void)notifyThirdPartyServices;
{
    if (! self.didNotifyThirdPartyServices) {
        self.didNotifyThirdPartyServices = YES;
        [self.thirdPartyServicesDelegate userSessionIsReadyToUploadServicesData:self];
    }
}

- (AVSFlowManager *)flowManager
{
    return self.onDemandFlowManager.flowManager;
}

@end



@implementation ZMUserSession (Test)

- (NSArray *)allManagedObjectContexts
{
    NSMutableArray *mocs = [NSMutableArray array];
    if (self.managedObjectContext != nil) {
        [mocs addObject:self.managedObjectContext];
    }
    if (self.syncManagedObjectContext != nil) {
        [mocs addObject:self.syncManagedObjectContext];
    }
    return mocs;
}

@end



@implementation ZMUserSession (PushToken)


- (void)setPushToken:(NSData *)deviceToken;
{
    NSString *transportType = [self.apnsEnvironment transportTypeForTokenType:ZMAPNSTypeNormal];
    NSString *appIdentifier = self.apnsEnvironment.appIdentifier;
    ZMPushToken *token = nil;
    if (transportType != nil && deviceToken != nil && appIdentifier != nil) {
        token = [[ZMPushToken alloc] initWithDeviceToken:deviceToken identifier:appIdentifier transportType:transportType fallback:nil isRegistered:NO];
    }
    
    if ((self.managedObjectContext.pushToken != token) && ! [self.managedObjectContext.pushToken isEqual:token]) {
        self.managedObjectContext.pushToken = token;
        if (![self.managedObjectContext forceSaveOrRollback]) {
            ZMLogError(@"Failed to save push token");
        }
    }
}

- (void)setPushKitToken:(NSData *)deviceToken;
{
    ZMAPNSType apnsType = ZMAPNSTypeVoIP;
    NSString *transportType = [self.apnsEnvironment transportTypeForTokenType:apnsType];
    NSString *appIdentifier = self.apnsEnvironment.appIdentifier;
    ZMPushToken *token = nil;
    if (transportType != nil && deviceToken != nil && appIdentifier != nil) {
        NSString *fallback = [self.apnsEnvironment fallbackForTransportType:apnsType];
        token = [[ZMPushToken alloc] initWithDeviceToken:deviceToken identifier:appIdentifier transportType:transportType fallback:fallback isRegistered:NO];
    }
    if ((self.managedObjectContext.pushKitToken != token) && ! [self.managedObjectContext.pushKitToken isEqual:token]) {
        self.managedObjectContext.pushKitToken = token;
        if (![self.managedObjectContext forceSaveOrRollback]) {
            ZMLogError(@"Failed to save pushKit token");
        }
    }
}

- (void)deletePushKitToken
{
    if(self.managedObjectContext.pushKitToken) {
        self.managedObjectContext.pushKitToken = [self.managedObjectContext.pushKitToken forDeletionMarkedCopy];
        if (![self.managedObjectContext forceSaveOrRollback]) {
            ZMLogError(@"Failed to save pushKit token marked for deletion");
        }
    }
}

- (void)deletePushToken
{
    if (self.managedObjectContext.pushToken != nil) {
        self.managedObjectContext.pushToken = [self.managedObjectContext.pushToken forDeletionMarkedCopy];
        if (![self.managedObjectContext forceSaveOrRollback]) {
            ZMLogError(@"Failed to save push token marked for deletion");
        }
    }
}

@end



@implementation ZMUserSession (AddressBookUpload)

+ (void)addAddressBookUploadObserver:(id<AddressBookUploadObserver>)observer;
{
    ZM_ALLOW_MISSING_SELECTOR([[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(failedToAccessAddressBook:) name:ZMUserSessionFailedToAccessAddressBookNotificationName object:nil]);
}

+ (void)removeAddressBookUploadObserver:(id<AddressBookUploadObserver>)observer;
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:ZMUserSessionFailedToAccessAddressBookNotificationName object:nil];
}

- (void)uploadAddressBook;
{
    [ZMAddressBookSync markAddressBookAsNeedingToBeUploadedInContext:self.managedObjectContext];
    if (![self.managedObjectContext forceSaveOrRollback]) {
        ZMLogWarn(@"Failed to save addressBook");
    }
}

@end


@implementation ZMUserSession(NetworkState)

- (void)changeNetworkStateAndNotify;
{
    ZMNetworkState state;
    if (self.networkIsOnline) {
        if (self.isPerformingSync) {
            state = ZMNetworkStateOnlineSynchronizing;
        } else {
            state = ZMNetworkStateOnline;
        }
        self.managedObjectContext.isOffline = NO;
    } else {
        state = ZMNetworkStateOffline;
        self.managedObjectContext.isOffline = YES;
    }
    
    ZMNetworkState const previous = self.networkState;
    self.networkState = state;
    if(previous != self.networkState && [[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground) {
        [[NSNotificationCenter defaultCenter] postNotification:[ZMNetworkAvailabilityChangeNotification notificationWithNetworkState:self.networkState userSession:self]];
    }
}

- (void)didReceiveData
{
    ZM_WEAK(self);
    [self.managedObjectContext performGroupedBlock:^{
        ZM_STRONG(self);
        self.networkIsOnline = YES;
        [self changeNetworkStateAndNotify];
    }];
}

- (void)didGoOffline
{
    ZM_WEAK(self);
    [self.managedObjectContext performGroupedBlock:^{
        ZM_STRONG(self);
        self.networkIsOnline = NO;
        
        [self changeNetworkStateAndNotify];
        
        [ZMConversation updateCallStateForOfflineModeInContext:self.managedObjectContext];
        [self saveOrRollbackChanges];
    }];
}

- (void)didStartSync
{
    ZM_WEAK(self);
    [self.managedObjectContext performGroupedBlock:^{
        ZM_STRONG(self);
        self.isPerformingSync = YES;
        self.didStartInitialSync = YES;
        [self changeNetworkStateAndNotify];
    }];
}

- (void)didFinishSync
{
    ZM_WEAK(self);
    [self.managedObjectContext performGroupedBlock:^{
        ZM_STRONG(self);
        self.isPerformingSync = NO;
        [self changeNetworkStateAndNotify];
        [self notifyThirdPartyServices];
    }];
}

@end



static unsigned long CommonContactsSearchUniqueCounter = 0;

@implementation ZMUserSession (CommonContacts)

- (void)syncSearchCommonContactsWithUserID:(NSUUID *)userID forToken:(id<ZMCommonContactsSearchToken>)token searchDelegate:(id<ZMCommonContactsSearchDelegate>)searchDelegate
{
    [ZMCommonContactsSearch startSearchWithTransportSession:self.transportSession
                                                     userID:userID
                                                      token:token
                                                    syncMOC:self.syncManagedObjectContext
                                                      uiMOC:self.managedObjectContext
                                             searchDelegate:searchDelegate
                                               resultsCache:self.commonContactsCache];
}

- (id<ZMCommonContactsSearchToken>)searchCommonContactsWithUserID:(NSUUID *)userID searchDelegate:(id<ZMCommonContactsSearchDelegate>)searchDelegate
{
    id token = @(++CommonContactsSearchUniqueCounter);
    __weak id<ZMCommonContactsSearchDelegate> weakDelegate = searchDelegate;
    ZM_WEAK(self);
    [self.syncManagedObjectContext performGroupedBlock:^{
        ZM_STRONG(self);
        [self syncSearchCommonContactsWithUserID:userID forToken:token searchDelegate:weakDelegate];
    }];
    return token;
}

@end

@implementation NSManagedObjectContext (NetworkState)

static NSString * const IsOfflineKey = @"IsOfflineKey";

- (void)setIsOffline:(BOOL)isOffline;
{
    self.userInfo[IsOfflineKey] = [NSNumber numberWithBool:isOffline];
}

- (BOOL)isOffline;
{
    return [self.userInfo[IsOfflineKey] boolValue];
}

@end



@implementation ZMUserSession (AlertView)

- (void)alertView:(UIAlertView * __unused)alertView clickedButtonAtIndex:(NSInteger __unused)buttonIndex
{
    [self openAppstore];
}

@end



@implementation NSManagedObjectContext (TrackingIdentifier)

static NSString * const TrackingIdentifierKey = @"ZMTrackingIdentifier";

- (NSString *)userSessionTrackingIdentifier;
{
    return [self persistentStoreMetadataForKey:TrackingIdentifierKey];
}

- (void)setUserSessionTrackingIdentifier:(NSString *)identifier;
{
    [self setPersistentStoreMetadata:[identifier copy] forKey:TrackingIdentifierKey];
}

@end



@implementation ZMUserSession (LaunchOptions)

- (void)didLaunchWithURL:(NSURL *)URL;
{
    if([URL isURLForInvitationToConnect]) {
        ZM_WEAK(self);
        [self.syncManagedObjectContext performGroupedBlock:^{
            ZM_STRONG(self);
            if(self.isLoggedIn) {
                [ZMConnection sendInvitationToConnectFromURL:URL managedObjectContext:self.syncManagedObjectContext];
            }
            else {
                [ZMConnection storeInvitationToConnectFromURL:URL managedObjectContext:self.syncManagedObjectContext];
            }
            
            [self.syncManagedObjectContext saveOrRollback];
        }];
    }
    else if ([URL isURLForPhoneVerification]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ZMLaunchedWithPhoneVerificationCodeNotificationName object:nil userInfo:@{ ZMPhoneVerificationCodeKey : [URL codeForPhoneVerification] }];
    }
    else if ([URL isURLForPersonalInvitation]) {
        [IncomingPersonalInvitationStrategy storePendingInvitation:URL.codeForPersonalInvitation context:self.syncManagedObjectContext];
        [ZMOperationLoop notifyNewRequestsAvailable:self];
    }
    else if ([URL isURLForPersonalInvitationError]) {
        [ZMIncomingPersonalInvitationNotification notifyDidNotFindPersonalInvitation];
    }
}

@end



@implementation ZMUserSession (RequestToOpenConversation)

+ (void)requestToOpenSyncConversationOnUI:(ZMConversation *)conversation;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ZMRequestToOpenSyncConversationNotificationName object:conversation.objectID];
}

@end



@implementation ZMUserSession (AVSLogging)

+ (void)appendAVSLogMessageForConversation:(ZMConversation *)conversation withMessage:(NSString *)message;
{
    NSDictionary *userInfo = @{@"message" :message};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ZMAppendAVSLogNotificationName object:conversation userInfo:userInfo];
}

@end


@implementation NSManagedObjectContext (KeyValueStore)

- (void)setValue:(id)value forKey:(NSString *)key
{
    [self setPersistentStoreMetadata:value forKey:key];
}

- (id)valueForKey:(NSString *)key
{
    return [self persistentStoreMetadataForKey:key];
}

@end



@implementation ZMUserSession (AddressBook)

- (NSArray *)addressBookContacts
{
    if (self.cachedAddressBookContacts == nil) {
        if (! [ZMAddressBook userHasAuthorizedAccess]) {
            return @[]; // Don't cache contacts without address book authorization
        }
        
        dispatch_once(&_loadAddressBookContactsOnce, ^{
            [self reloadAddressBookContacts];
        });
    }
    
    return self.cachedAddressBookContacts;
}

- (void)reloadAddressBookContacts
{
    ZMAddressBook *addressBook = [ZMAddressBook addressBook];
    
    NSMutableArray *contacts = [NSMutableArray array];
    for (ZMAddressBookContact *contact in addressBook.contacts) {
        if(contacts.count > MaximumContactsToParse) {
            break;
        }
        [contacts addObject:contact];
    }
    
    self.cachedAddressBookContacts = contacts;
}

@end

@implementation ZMUserSession (PersonalInvitation)

- (NSURL *)checkForPersonalInvitationURL
{
    ZMBackendEnvironment *backendURL = [[ZMBackendEnvironment alloc] init];
    return [backendURL.frontendURL URLByAppendingPathComponent:@"/i/check"];
}

@end

@implementation ZMUserSession (SelfUserClient)

- (UserClient *)selfUserClient
{
    return [ZMUser selfUserInContext:self.managedObjectContext].selfClient;
}

@end

@implementation ZMUserSession (ClientRegistrationStatus)

- (void)didRegisterUserClient:(UserClient *)userClient
{
    self.transportSession.clientID = userClient.remoteIdentifier;
    [self.transportSession restartPushChannel];
}

@end

