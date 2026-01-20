//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

@import WireUtilities;
@import WireTesting;
@import WireTransport;
@import UniformTypeIdentifiers;
#import "MockPicture.h"
#import "MockTransportSession+conversations.h"
#import "MockTransportSession+internal.h"
#import "MockTransportSession+connections.h"
#import "MockEvent.h"
#import "MockConnection.h"
#import "MockPreKey.h"
#import "MockReachability.h"
#import "WireMockTransport/WireMockTransport-Swift.h"
#import "NSManagedObjectContext+executeFetchRequestOrAssert.h"
#import "ZMSLogging.h"

NSString * const ZMPushChannelStateChangeNotificationName = @"ZMPushChannelStateChangeNotification";
NSString * const ZMPushChannelIsOpenKey = @"pushChannelIsOpen";
NSString * const ZMPushChannelResponseStatusKey = @"responseStatus";

@import CoreGraphics;
#if TARGET_OS_IPHONE
@import MobileCoreServices;
#else
@import CoreServices;
#endif


#define ENABLE_LOG_ALL_REQUESTS 0

#if ! ENABLE_LOG_ALL_REQUESTS
    #define LogNetwork(x, ...) ZMLogDebug(x, ##__VA_ARGS__)
#else
    #define LogNetwork(x, ...) NSLog(x, ##__VA_ARGS__)
#endif

static NSString* ZMLogTag ZM_UNUSED = @"MockTransportRequests";

@interface MockTransportSession ()

@property (nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) MockUser *selfUser;
@property (nonatomic, readonly) ZMSDispatchGroup *requestGroup;
@property (nonatomic, readonly) NSMutableArray* generatedTransportRequests;
@property (nonatomic, readonly) NSMutableArray* generatedPushEvents;

@property (nonatomic, readonly) NSMutableArray *nonCompletedRequests;

@property (atomic) BOOL shouldKeepPushChannelOpen;
@property (atomic) BOOL shouldSendPushChannelEvents;
@property (atomic) BOOL clientCompletedLogin;

@property (nonatomic) NSMutableSet* whitelistedEmails;
@property (nonatomic) NSMutableSet *phoneNumbersWaitingForVerificationForRegistration;
@property (nonatomic) NSMutableSet *phoneNumbersWaitingForVerificationForLogin;
@property (nonatomic) NSMutableSet *phoneNumbersWaitingForVerificationForProfile;

@property (nonatomic) NSMutableSet *emailsWaitingForVerificationForRegistration;

/// The mapping between the taskIdentifiers on ZMTransportRequest, can be used to cancel the request
@property (nonatomic) NSMutableDictionary <NSNumber *, ZMTransportRequest *> *taskIdentifierMapping;

@property (nonatomic, readwrite) NSDictionary <NSString *, NSDictionary *> *pushTokens;

@property (nonatomic, weak) id <ZMNetworkStateDelegate> networkStateDelegate;

- (ZMTransportResponse *)errorResponseWithCode:(NSInteger)code reason:(NSString *)reason apiVersion:(APIVersion)apiVersion;

/// Completes a request and removes from all pending requests lists
- (void)completeRequestAndRemoveFromLists:(ZMTransportRequest *)request response:(ZMTransportResponse *)response;

@end



@interface MockTransportSession (PushEvents)

- (void)managedObjectContextPropagateChangesWithInsertedObjects:(NSSet *)inserted
                                                 updatedObjects:(NSSet *)updated
                                                 deletedObjects:(NSSet *)deleted
                                     shouldSendEventsToSelfUser:(BOOL)shouldSendSelfEvents;

@end



@implementation MockTransportSession

- (instancetype)init
{
    NSAssert(false, @"Called wrong init for MockTransportSession");
    return [self initWithDispatchGroup:nil];
}

- (instancetype)initWithDispatchGroup:(ZMSDispatchGroup *)group;
{
    self = [super init];
    if (self != nil) {
        if (group == nil) {
            group = [[ZMSDispatchGroup alloc] initWithLabel:@"MockTransportSession"];
        }
        [self setupWithDispatchGroup:group];
        _generatedTransportRequests = [NSMutableArray array];
        _requestGroup = group;
        _generatedPushEvents = [NSMutableArray array];
        self.taskIdentifierMapping = [NSMutableDictionary new];
        self.whitelistedEmails = [NSMutableSet set];
        self.phoneNumbersWaitingForVerificationForRegistration = [NSMutableSet set];
        self.phoneNumbersWaitingForVerificationForLogin = [NSMutableSet set];
        self.phoneNumbersWaitingForVerificationForProfile = [NSMutableSet set];

        self.emailsWaitingForVerificationForRegistration = [NSMutableSet set];
        
        self.reachability = [[MockReachability alloc] init];
        self.pushTokens = [NSMutableDictionary dictionary];
        _nonCompletedRequests = [NSMutableArray array];
        [MockRole createConversationRolesWithContext:self.managedObjectContext];

        self.supportedAPIVersions = [[NSArray alloc] initWithObjects:@0, @1, nil];
        self.developmentAPIVersions = [[NSArray alloc] init];
        self.domain = @"wire.com";
        self.federation = false;
        self.isAPIVersionEndpointAvailable = true;
        self.isInternalError = false;
    }
    return self;
}

- (void)dealloc {
    self.managedObjectContext.dispatchGroupContext = nil;
}

- (void)enterBackground
{
    
}

- (void)enterForeground
{
    
}

- (void)prepareForSuspendedState
{
    
}

- (void)addPushToken:(NSString *)token payload:(NSDictionary *)payload
{
    NSMutableDictionary *dict = (NSMutableDictionary *)self.pushTokens;
    dict[token] = payload;
}

- (void)removePushToken:(NSString *)token
{
    NSMutableDictionary *dict = (NSMutableDictionary *)self.pushTokens;
    [dict removeObjectForKey:token];
}

- (void)expireAllBlockedRequests;
{
    ZMTransportResponse *emptyResponse = [ZMTransportResponse responseWithTransportSessionError:[NSError errorWithDomain:ZMTransportSessionErrorDomain code:ZMTransportSessionErrorCodeRequestExpired userInfo:nil] apiVersion:0];
    NSArray *nonCompleted = [self.nonCompletedRequests copy];
    for(ZMTransportRequest *request in nonCompleted) {
        [self completeRequestAndRemoveFromLists:request response:emptyResponse];
    }
    [self.nonCompletedRequests removeAllObjects];
}

- (void)completeAllBlockedRequests
{
    NSArray *requests = self.nonCompletedRequests.copy;
    [self.nonCompletedRequests removeAllObjects];
    
    for (ZMTransportRequest *request in requests) {
        [self completePreviouslySuspendendRequest:request];
    }
}

- (void)tearDown
{
    // Because we re-use the same MockTransportSession for both authenticated and unauthenticated sessions
    // we don't want to do any tear down here. We should only tear it down after test is complete
}

- (void)cleanUp
{
    self.managedObjectContext = nil;
    [self expireAllBlockedRequests];
    [self.generatedTransportRequests removeAllObjects];
}

- (void)generateEmailVerificationCode
{
    _generatedEmailVerificationCode = @"123456";
}

- (ZMTransportSession *)mockedTransportSession;
{
    return (id) self;
}

- (void)setupWithDispatchGroup:(ZMSDispatchGroup *)group;
{
    self.baseURL = [NSURL URLWithString:@"test://example.com/"];
    
    NSURL *momURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"MockTransportSession" withExtension:@"momd"];
    NSAssert(momURL != nil, @"");
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    NSAssert(mom != nil, @"");
    
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    __unused id store = [psc addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];
    NSAssert(store != nil, @"");
    
    self.managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [self.managedObjectContext createDispatchGroups];
    [self.managedObjectContext addGroup:group];
    self.managedObjectContext.persistentStoreCoordinator = psc;    
}

-(void)resetReceivedRequests
{
    ZM_WEAK(self);
    [self.managedObjectContext performGroupedBlockAndWait:^{
        ZM_STRONG(self);
        [self.generatedTransportRequests removeAllObjects];
    }];
}

-(NSArray *)receivedRequests
{
    __block NSArray *requests;
    ZM_WEAK(self);
    [self.managedObjectContext performBlockAndWait:^{
        ZM_STRONG(self);
        requests = [self.generatedTransportRequests copy];
    }];
    return requests;
}

- (ZMTransportResponse *)errorResponseWithCode:(NSInteger)code reason:(NSString *)reason apiVersion:(APIVersion)apiVersion;
{
    NSDictionary *payload = @{
                              @"label":reason
                              };
    return [ZMTransportResponse responseWithPayload:payload HTTPStatus:code transportSessionError:nil apiVersion:apiVersion];
}

- (BOOL)waitForAllRequestsToCompleteWithTimeout:(NSTimeInterval)timeout;
{
    __block BOOL didComplete = NO;
    [self.requestGroup notifyOnQueue:dispatch_get_main_queue() block:^{
        didComplete = YES;
    }];
    NSDate *end = [NSDate dateWithTimeIntervalSinceNow:timeout];
    while (! didComplete && (0. < [end timeIntervalSinceNow])) {
        if (! [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.002]]) {
            [NSThread sleepForTimeInterval:0.002];
        }
    }
    return didComplete;
}

- (void)completePreviouslySuspendendRequest:(ZMTransportRequest *)request;
{
    [self completeRequest:request completionHandler:^(ZMTransportResponse *response){
        [self completeRequestAndRemoveFromLists:request response:response];
    }];
}

- (void)logoutSelfUser;
{
    self.selfUser = nil;
}

- (void)cancelTaskWithIdentifier:(ZMTaskIdentifier *)taskIdentifier
{
    ZMTransportRequest *request = self.taskIdentifierMapping[@(taskIdentifier.identifier)];
    if (nil != request) {
        ZMTransportResponse *response = [ZMTransportResponse responseWithTransportSessionError:NSError.tryAgainLaterError apiVersion:request.apiVersion];
        [self completeRequestAndRemoveFromLists:request response:response];
    }
}


- (void)completeRequestAndRemoveFromLists:(ZMTransportRequest *)request response:(ZMTransportResponse *)response {
    [self.nonCompletedRequests removeObject:request];
    __block NSNumber *foundKey = nil;
    [self.taskIdentifierMapping enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, ZMTransportRequest * _Nonnull obj, BOOL * _Nonnull stop) {
        if(obj == request) {
            foundKey = key;
            *stop = YES;
        }
    }];
    if(foundKey != nil) {
        [self.taskIdentifierMapping removeObjectForKey:foundKey];
    }
    [request completeWithResponse:response];
}

- (MockConnection *)connectionFromUserIdentifier:(NSString *)fromUserIdentifier toUserIdentifier:(NSString *)toUserIdentifier;
{
    NSFetchRequest *request = [MockConnection sortedFetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"from.identifier == %@ AND to.identifier == %@", fromUserIdentifier, toUserIdentifier];
    
    NSArray *connections = [self.managedObjectContext executeFetchRequestOrAssert_mt:request];
    RequireString(connections.count <= 1, "Too many connections with one identifier");
    
    return [connections firstObject];
}

- (void)setAccessTokenRenewalFailureHandler:(ZMCompletionHandlerBlock)handler
{
    self->_accessTokenFailureHandler = [handler copy];
}


- (void)setAccessTokenRenewalSuccessHandler:(ZMAccessTokenHandlerBlock)handler
{
    self->_accessTokenSuccessHandler = [handler copy];
}

- (void)renewAccessTokenWithClientID:(NSString *)clientID {
    // no op
}

@end



@implementation MockTransportSession (Mock)

- (void)enqueueRequest:(ZMTransportRequest *)request queue:(id<ZMSGroupQueue>)queue completionHandler:(void (^)(ZMTransportResponse * _Nonnull))completionHandler {
    [request addCompletionHandler:[ZMCompletionHandler handlerOnGroupQueue:queue block:completionHandler]];
    [self enqueueOneTimeRequest:request];
}

- (void)enqueueOneTimeRequest:(ZMTransportRequest *)request;
{
    [self attemptToEnqueueSyncRequestWithGenerator:^ZMTransportRequest *{
        return request;
    }];
}

- (ZMTransportEnqueueResult *)attemptToEnqueueSyncRequestWithGenerator:(__attribute__((noescape)) ZMTransportRequestGenerator)generator;
{
    if (self.disableEnqueueRequests) {
        return [ZMTransportEnqueueResult resultDidHaveLessRequestsThanMax:NO didGenerateNonNullRequest:NO];
    }
    ZMTransportRequest *request = generator();
    
    static NSUInteger taskCounter = 0;
    taskCounter++;
    self.taskIdentifierMapping[@(taskCounter)] = request;
    [request callTaskCreationHandlersWithIdentifier:taskCounter sessionIdentifier:@"mock-session-identifier"];
    
    if (request && request.expirationDate != nil && self.doNotRespondToRequests == YES) {
        
        NSTimeInterval delay = [request.expirationDate timeIntervalSinceDate:[NSDate date]];
        dispatch_time_t dispatchTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delay * NSEC_PER_SEC) );

        [self.requestGroup enter];
        ZM_WEAK(self);
        dispatch_after(dispatchTime, dispatch_get_main_queue(), ^(void){
            [self.managedObjectContext performGroupedBlock:^{
                ZM_STRONG(self);
                ZMTransportResponse *response = [ZMTransportResponse responseWithTransportSessionError:[NSError errorWithDomain:ZMTransportSessionErrorDomain code:ZMTransportSessionErrorCodeRequestExpired userInfo:nil] apiVersion:request.apiVersion];
                response.dispatchGroup = self.requestGroup;
                [self completeRequestAndRemoveFromLists:request response:response];
                [self.requestGroup leave];
            }];
        });
        
    }
    else if(request && self.doNotRespondToRequests == NO) {
        [self.requestGroup enter];
        ZM_WEAK(self);
        [self.managedObjectContext performGroupedBlock:^{
            ZM_STRONG(self);
            [self processRequest:request completionHandler:^(ZMTransportResponse *response) {
                if(response != nil) {
                    response.dispatchGroup = self.requestGroup;
                    [self completeRequestAndRemoveFromLists:request response:response];
                }
                [self.requestGroup leave];
            }];
        }];
    }
    return [ZMTransportEnqueueResult resultDidHaveLessRequestsThanMax:YES didGenerateNonNullRequest:request != nil];
}

- (NSArray *)methodMap
{
    return @[
             @[@"/push/fallback", @"processNotificationFallbackRequest:"],
             @[@"/push/tokens", @"processPushTokenRequest:"],
             @[@"/connections", @"processSelfConnectionsRequest:"],
             @[@"/users", @"processUsersRequest:"],
             @[@"/clients", @"processClientsRequest:"],
             @[@"/conversations", @"processConversationsRequest:"],
             @[@"/login/send", @"processLoginCodeRequest:"],
             @[@"/login", @"processLoginRequest:"],
             @[@"/self", @"processSelfUserRequest:"],
             @[@"/assets/v4", @"processAssetV4Request:"],
             @[@"/assets/v3", @"processAssetV3Request:"],
             @[@"/assets", @"processAssetRequest:"],
             @[@"/search/contacts", @"processSearchRequest:"],
             @[@"/notifications", @"processNotificationsRequest:"],
             @[@"/register", @"processRegistrationRequest:"],
             @[@"/activate/send", @"processVerificationCodeRequest:"],
             @[@"/activate", @"processPhoneActivationRequest:"],
             @[@"/invitations", @"processInvitationsRequest:"],
             @[@"/teams", @"processTeamsRequest:"],
             @[@"/broadcast", @"processBroadcastRequest:"],
             @[@"/providers", @"processServicesProvidersRequest:"],
             @[@"/api-version", @"processAPIVersionRequest:"],
             @[@"/verification-code/send", @"processVerificationCodeSendRequest:"],
             @[@"/feature-configs", @"processFeatureConfigsRequest:"],
             ];
}

- (void)completeRequest:(ZMTransportRequest *)request completionHandler:(ZMCompletionHandlerBlock)completionHandler
{
    ZMTransportResponse *response;
    
    SEL matchedSelector = NULL;
    
    // Check the path components and find the method to call:
    for (NSArray *pair in self.methodMap) {
        NSAssert(pair.count == 2, @"Unexpected pair count in method map");
        NSString *path = pair[0];
        NSString *selectorString = pair[1];


        NSString* requestPathWithoutVersion = [request.path removingAPIVersion];
        if ([requestPathWithoutVersion hasPrefix:path])
        {
            matchedSelector = NSSelectorFromString(selectorString);
            break;
        }
    }
    
    if (matchedSelector != NULL) {
        NSAssert([self respondsToSelector:matchedSelector], @"Unknown selector %@", NSStringFromSelector(matchedSelector));
        NSMethodSignature *signature = [self methodSignatureForSelector:matchedSelector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.target = self;
        invocation.selector = matchedSelector;
        [invocation setArgument:(void *) &request atIndex:2];
        [invocation invoke];
        [invocation getReturnValue:(void *) &response];
        // NSInvocation & ARC need this:
        if (response) {
            CFRetain((CFTypeRef) response);
        }
    }
        
    if (response != nil) {
        LogNetwork(@"<--- Response to %@: %@", request.path, response);
        if(completionHandler) {
            completionHandler(response);
        }
    } else {
        LogNetwork(@"<--- Response to %@: 404 (request not handled)", request.path);
        response = [self errorResponseWithCode:404 reason:@"no-endpoint" apiVersion:request.apiVersion];
        if(completionHandler) {
            completionHandler(response);
        }
    }
    
}


- (void)processRequest:(ZMTransportRequest *)request completionHandler:(ZMCompletionHandlerBlock)completionHandler;
{
    [self.generatedTransportRequests addObject:request];
    
    ZMTransportResponse *response;
    
    LogNetwork(@"---> Request: %@", request);
    
    
    if(self.responseGeneratorBlock) {
        response = self.responseGeneratorBlock(request);
        if (response == ResponseGenerator.ResponseNotCompleted) {
            // do not complete this request
            LogNetwork(@"<--- Not completing request to %@ due to custom responseHandler", request.path);
            [self.nonCompletedRequests addObject:request];
            if(completionHandler) {
                completionHandler((ZMTransportResponse * _Nonnull) nil);
            }
            return;
        }
        if (response != nil) {
            LogNetwork(@"<--- Custom response to %@: %@", request.path, response);
            if(completionHandler) {
                completionHandler(response);
            }
            return;
        }
    }
    
    [self completeRequest:request completionHandler:completionHandler];
    
}

- (MockConnection *)fetchConnectionFrom:(MockUser *)user to:(MockUser *)otherUser;
{
    NSFetchRequest *request = [MockConnection sortedFetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"(from == %@) AND (to == %@)", user, otherUser];
    NSArray *connections = [self.managedObjectContext executeFetchRequestOrAssert_mt:request];

    if (connections.count == 0) {
        return nil;
    }
    
    return connections[0];
}

@end



@implementation MockTransportSession (CreatingObjects)

- (void)saveAndCreatePushChannelEvents
{
    [self saveAndCreatePushChannelEvents:NO];
}

- (void)saveAndCreatePushChannelEventForSelfUser
{
    [self saveAndCreatePushChannelEvents:YES];
}

- (void)saveAndCreatePushChannelEvents:(BOOL)shouldSendEventsToSelfUser;
{
    __unused NSError *error;
    
    NSSet *insertedObjects = self.managedObjectContext.insertedObjects;
    NSSet *updatedObjects = self.managedObjectContext.updatedObjects;
    NSSet *deletedObjects = self.managedObjectContext.deletedObjects;
    
    BOOL result = [self.managedObjectContext save:&error];
    (void)result;
    NSAssert(result, @"Failed to save: %@", error);
}

- (void)performRemoteChanges:(void(^)(id<MockTransportSessionObjectCreation>))block;
{
    // If you crash here, it's probably due to bug in the block being passed to this method
    ZM_WEAK(self);
    [self.managedObjectContext performGroupedBlockAndWait:^{
        ZM_STRONG(self);
        block(self);
        [self saveAndCreatePushChannelEvents:YES];
    }];
}

@end

@implementation MockTransportSession (MockTransportSessionObjectCreation)

- (void)createAssetWithData:(NSData *)data identifier:(NSString *)identifier contentType:(NSString *)contentType forConversation:(NSString *)conversation
{
    MockAsset *asset = [MockAsset insertIntoManagedObjectContext:self.managedObjectContext];
    asset.data = data;
    asset.identifier = identifier;
    asset.contentType = contentType;
    asset.conversation = conversation;
}

- (NSString *)createUUIDString;
{
    NSUUID *uuid = [NSUUID createUUID];
    return [uuid transportString];
}

- (MockUser *)insertSelfUserWithName:(NSString *)name
{
    RequireString(self.selfUser == nil, "SelfUser already exists!");
    self.selfUser = [self insertUserWithName:name includeClient:NO];
    return self.selfUser;
}

- (NSDictionary<NSString *, MockPicture *> *)addProfilePictureToUser:(MockUser *)user
{
    MockPicture *smallProfile = (id) [NSEntityDescription insertNewObjectForEntityForName:@"Picture" inManagedObjectContext:self.managedObjectContext];
    MockPicture *medium = (id) [NSEntityDescription insertNewObjectForEntityForName:@"Picture" inManagedObjectContext:self.managedObjectContext];
    user.pictures = [NSOrderedSet orderedSetWithObjects:smallProfile, medium, nil];
    
    NSData *imageData = [ZMTBaseTest verySmallJPEGData];
    
    [smallProfile setAsSmallProfileFromImageData:imageData forUser:user];
    [medium setAsMediumWithSmallProfile:smallProfile forUser:user imageData:imageData];
    
    return @{ medium.info[@"tag"] : medium, smallProfile.info[@"tag"] : smallProfile };
}

- (NSDictionary<NSString *, MockAsset *> *)addV3ProfilePictureToUser:(MockUser *)user
{
    MockAsset *previewAsset = [self insertAssetWithID:[NSUUID createUUID] assetToken:[NSUUID createUUID] assetData:[ZMTBaseTest verySmallJPEGData] contentType:@"application/octet-stream"];
    MockAsset *completeAsset = [self insertAssetWithID:[NSUUID createUUID] assetToken:[NSUUID createUUID] assetData:[ZMTBaseTest verySmallJPEGData] contentType:@"application/octet-stream"];
    user.previewProfileAssetIdentifier = previewAsset.identifier;
    user.completeProfileAssetIdentifier = completeAsset.identifier;
    
    return @{ @"preview" : previewAsset, @"complete" : completeAsset };
}

- (MockConnection *)insertConnectionWithSelfUser:(MockUser *)selfUser toUser:(MockUser *)toUser
{
    MockConnection *connection = (id) [NSEntityDescription insertNewObjectForEntityForName:@"Connection" inManagedObjectContext:self.managedObjectContext];
    connection.from = selfUser;
    connection.to = toUser;
    connection.lastUpdate = [NSDate date];
    
    return connection;
}

- (MockConversation *)insertSelfConversationWithSelfUser:(MockUser *)selfUser;
{
    MockConversation *conversation = [self insertConversationWithSelfUser:selfUser otherUsers:@[] type:ZMTConversationTypeSelf];

    return conversation;
}

- (MockConversation *)insertOneOnOneConversationWithSelfUser:(MockUser *)selfUser otherUser:(MockUser *)otherUser;
{
    MockConversation *conversation = [self insertConversationWithSelfUser:selfUser otherUsers:@[otherUser] type:ZMTConversationTypeOneOnOne];
    return conversation;
}

- (MockConversation *)insertGroupConversationWithSelfUser:(MockUser *)selfUser otherUsers:(NSArray *)otherUsers;
{
    return [self insertConversationWithSelfUser:selfUser otherUsers:otherUsers type:ZMTConversationTypeGroup];
}

- (MockConversation *)insertConversationWithSelfUser:(MockUser *)selfUser otherUsers:(NSArray *)otherUsers type:(ZMTConversationType)conversationType;
{
    return [MockConversation conversationInMoc:self.managedObjectContext withCreator:selfUser otherUsers:otherUsers type:conversationType];
}

- (MockConversation *)insertConversationWithSelfUser:(MockUser *)selfUser creator:(MockUser *)creator otherUsers:(NSArray *)otherUsers type:(ZMTConversationType)conversationType;
{
    return [MockConversation insertConversationIntoContext:self.managedObjectContext withSelfUser:selfUser creator:creator otherUsers:otherUsers type:conversationType];
}

- (MockConversation *)insertConversationWithSelfUserAndGroupRoles:(MockUser *)selfUser otherUsers:(NSArray *)otherUsers;
{
    return [MockConversation insertConversationWithRolesIntoContext:self.managedObjectContext withCreator:selfUser otherUsers:otherUsers ];
}

- (MockConversation *)insertConversationWithCreator:(MockUser *)creator otherUsers:(NSArray *)otherUsers type:(ZMTConversationType)conversationType;
{
    return [MockConversation insertConversationIntoContext:self.managedObjectContext creator:creator otherUsers:otherUsers type:conversationType];
}

- (MockAsset *)insertAssetWithID:(NSUUID *)assetID assetToken:(NSUUID *)assetToken assetData:(NSData *)assetData contentType:(NSString *)contentType;
{
    return [self insertAssetWithID:assetID domain:NULL assetToken:assetToken assetData:assetData contentType:contentType];
}

- (MockAsset *)insertAssetWithID:(NSUUID *)assetID domain:(NSString *)domain assetToken:(NSUUID *)assetToken assetData:(NSData *)assetData contentType:(NSString *)contentType
{
    Require(assetID != nil);
    Require(assetData != nil);
    Require(contentType != nil);
    
    MockAsset *asset = [MockAsset insertIntoManagedObjectContext:self.managedObjectContext];
    asset.identifier = assetID.transportString;
    asset.token = assetToken.transportString ?: @"";
    asset.data = assetData;
    asset.contentType = contentType;
    asset.domain = domain;
    return asset;
}

- (void)whiteListEmail:(NSString *)email;
{
    [self.whitelistedEmails addObject:email];
    
    [self.emailsWaitingForVerificationForRegistration addObject:email];

    NSFetchRequest *fetchRequest = [MockUser sortedFetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"email == %@", email];
    NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert_mt:fetchRequest];
    for(MockUser *user in users) {
        user.isEmailValidated = YES;
    }
}

- (void)whiteListPhone:(NSString *)phone;
{
    [self.phoneNumbersWaitingForVerificationForLogin addObject:phone];
}

- (void)remotelyAcceptConnectionToUser:(MockUser*)user;
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"to == %@", user];
    NSFetchRequest *request = [MockConnection sortedFetchRequest];
    request.predicate = predicate;
    
    NSArray *connections = [self.managedObjectContext executeFetchRequestOrAssert_mt:request];
    MockConnection *connection = connections.firstObject;
    [connection accept];
}

- (MockConnection *)createConnectionRequestFromUser:(MockUser*)fromUser toUser:(MockUser*)toUser message:(NSString *)message;
{
    MockConversation *existingConversation;
    for (MockConnection *connection in fromUser.connectionsFrom) {
        if (connection.to == toUser) {
            existingConversation = connection.conversation;
            break;
        }
    }
    
    MockConnection *connection = [self connectionFromUserIdentifier:fromUser.identifier toUserIdentifier:toUser.identifier];
    if (nil == connection) {
        connection = [MockConnection connectionInMOC:self.managedObjectContext from:fromUser to:toUser message:message];
    } else {
        connection.message = message;
        connection.conversation.type = ZMTConversationTypeConnection;
    }
    connection.status = @"sent";
    MockConversation *conversation = existingConversation ?: [MockConversation conversationInMoc:self.managedObjectContext withCreator:fromUser otherUsers:@[] type:ZMTConversationTypeConnection];
    [conversation connectRequestByUser:fromUser toUser:toUser message:message];
    connection.conversation = conversation;
    return connection;
    
}

- (MockUserClient *)registerClientForUser:(MockUser *)user
{
    return [self registerClientForUser:user label:@"Mock Phone" type:@"permanent" deviceClass:@"phone"];
}

- (MockUserClient *)registerClientForUser:(MockUser *)user label:(NSString *)label type:(NSString *)type deviceClass:(NSString *)deviceClass
{
    MockUserClient *client = [MockUserClient insertClientWithLabel:label type:type deviceClass:deviceClass user:user context:self.managedObjectContext];
    return client;
}

- (void)deleteUserClientWithIdentifier:(NSString *)identifier forUser:(MockUser *)user;
{
    NSFetchRequest *userClientFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserClient"];
    userClientFetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier == %@ AND user == %@", identifier, user];
    
    NSArray *results = [self.managedObjectContext executeFetchRequestOrAssert_mt:userClientFetchRequest];

    for(MockUserClient *result in results) {
        [self.managedObjectContext deleteObject:result];
    }
}

- (MockUser *)userWithRemoteIdentifier:(NSString *)remoteIdentifier
{
    NSFetchRequest *userFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    userFetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier == %@", remoteIdentifier];
    
    NSArray *results = [self.managedObjectContext executeFetchRequestOrAssert_mt:userFetchRequest];
    return results.firstObject;
}

- (MockUserClient *)clientForUser:(MockUser *)user remoteIdentifier:(NSString *)remoteIdentifier
{
    NSFetchRequest *userClientFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"UserClient"];
    userClientFetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier == %@ AND user == %@", remoteIdentifier, user];
    
    NSArray *results = [self.managedObjectContext executeFetchRequestOrAssert_mt:userClientFetchRequest];
    return results.firstObject;
}

#pragma mark - Teams

- (MockTeam *)insertTeamWithName:(nullable NSString *)name isBound:(BOOL)isBound
{
    return [MockTeam insertIn:self.managedObjectContext name:name assetId:nil assetKey:nil isBound:isBound];
}

- (MockTeam *)insertTeamWithName:(nullable NSString *)name isBound:(BOOL)isBound users:(NSSet<MockUser*> *)users
{
    MockTeam *team = [MockTeam insertIn:self.managedObjectContext name:name assetId:nil assetKey:nil isBound:isBound];
    for (MockUser *user in users) {
        [self insertMemberWithUser:user inTeam:team];
    }
    return team;
}

- (void)deleteTeam:(nonnull MockTeam *)team
{
    [self.managedObjectContext deleteObject:team];
}

- (MockMember *)insertMemberWithUser:(MockUser *)user inTeam:(MockTeam *)team
{
    return [MockMember insertInContext:self.managedObjectContext forUser: user inTeam: team];
}

- (void)removeMemberWithUser:(MockUser *)user fromTeam:(MockTeam *)team
{
    MockMember *member = [team.members.allObjects firstObjectMatchingWithBlock:^BOOL(MockMember *aMember) {
        return [aMember.user isEqual:user];
    }];
    if (member != nil) {
        [[team mutableSetValueForKey:@"members"] removeObject:member];
        [self.managedObjectContext deleteObject: member];
    }
}

- (MockConversation *)insertTeamConversationToTeam:(MockTeam *)team withUsers:(NSArray<MockUser *> *)users creator:(MockUser *)creator {
    MockConversation *conversation = [MockConversation insertConversationIntoContext:self.managedObjectContext withCreator:creator forTeam:team users:users];
    NSAssert(self.selfUser.identifier, @"The self user needs to be set");
    if ([conversation.activeUsers containsObject:self.selfUser]) {
        conversation.selfIdentifier = self.selfUser.identifier;
    }
    return conversation;
}

- (void)deleteConversation:(nonnull MockConversation *)conversation
{
    conversation.team = nil;
    [self.managedObjectContext deleteObject:conversation];
}

- (void)deleteAccountForUser:(nonnull MockUser *)user
{
    user.isAccountDeleted = YES;
}

@end


@implementation MockTransportSession (PhoneVerification)

- (NSString *)phoneVerificationCodeForLogin
{
    return @"334564";
}

- (NSString *)phoneVerificationCodeForRegistration
{
    return @"644334";
}

- (NSString *)phoneVerificationCodeForUpdatingProfile
{
    return @"756345";
}

- (NSString *)invalidPhoneVerificationCode;
{
    return @"000000";
}

@end
