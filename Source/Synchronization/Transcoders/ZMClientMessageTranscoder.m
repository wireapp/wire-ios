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


#import "ZMClientMessageTranscoder+Internal.h"
#import "ZMMessageTranscoder+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMConversation+Internal.h"
#import "ZMUpdateEvent.h"
#import "ZMUser+Internal.h"
#import <zmessaging/NSManagedObjectContext+zmessaging.h>
#import "ZMUpstreamInsertedObjectSync.h"
#import "ZMMessageExpirationTimer.h"
#import "ZMUpstreamTranscoder.h"
#import "ZMAssetPreprocessingTracker.h"

#import "ZMClientRegistrationStatus.h"
#import "ZMLocalNotificationDispatcher.h"

#import <zmessaging/zmessaging-Swift.h>
#import "CBCryptoBox+UpdateEvents.h"
#import <zmessaging/zmessaging-Swift.h>
#import "ZMOperationLoop.h"
#import "ZMNotifications+Internal.h"

@interface ZMClientMessageTranscoder()

@property (nonatomic) ZMUpstreamModifiedObjectSync *assetModifiedSync;
@property (nonatomic) ZMDownstreamObjectSync *downstreamSync;
@property (nonatomic) ClientMessageRequestFactory *requestsFactory;
@property (nonatomic) ZMAssetPreprocessingTracker *assetPreprocessor;
@property (nonatomic, weak) ZMClientRegistrationStatus *clientRegistrationStatus;

@end


@implementation ZMClientMessageTranscoder

+ (instancetype)clientMessageTranscoderWithManagedObjectContext:(NSManagedObjectContext *)moc upstreamInsertedObjectSync:(ZMUpstreamInsertedObjectSync *)upstreamObjectSync localNotificationDispatcher:(ZMLocalNotificationDispatcher *)dispatcher messageExpirationTimer:(ZMMessageExpirationTimer *)expirationTimer clientRegistrationStatus:(ZMClientRegistrationStatus *)clientRegistrationStatus
{
    return [[ZMClientMessageTranscoder alloc] initWithManagedObjectContext:moc upstreamInsertedObjectSync:upstreamObjectSync localNotificationDispatcher:dispatcher messageExpirationTimer:expirationTimer clientRegistrationStatus:clientRegistrationStatus];
}

+ (instancetype)clientMessageTranscoderWithManagedObjectContext:(NSManagedObjectContext *)moc
                                    localNotificationDispatcher:(ZMLocalNotificationDispatcher *)dispatcher
                                       clientRegistrationStatus:(ZMClientRegistrationStatus *)clientRegistrationStatus
{
    return [[ZMClientMessageTranscoder alloc] initWithManagedObjectContext:moc entityName:ZMClientMessage.entityName localNotificationDispatcher:dispatcher clientRegistrationStatus:clientRegistrationStatus];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc upstreamInsertedObjectSync:(ZMUpstreamInsertedObjectSync *)upstreamObjectSync localNotificationDispatcher:(ZMLocalNotificationDispatcher *)dispatcher messageExpirationTimer:(ZMMessageExpirationTimer *)expirationTimer clientRegistrationStatus:(ZMClientRegistrationStatus *)clientRegistrationStatus;
{
    ZMUpstreamModifiedObjectSync *assetModifiedSync = [[ZMUpstreamModifiedObjectSync alloc] initWithTranscoder:self
                                                                                                    entityName:[ZMAssetClientMessage entityName]
                                                                                          managedObjectContext:moc];
    
    NSPredicate *mediumDataNeedsToBeDownloaded = [NSPredicate predicateWithFormat:@"assetId_data != NIL && loadedMediumData == NO"];
    ZMDownstreamObjectSync *downstreamSync = [[ZMDownstreamObjectSync alloc] initWithTranscoder:self
                                                                                     entityName:[ZMAssetClientMessage entityName]
                                                                  predicateForObjectsToDownload:mediumDataNeedsToBeDownloaded
                                                                           managedObjectContext:moc];
    
    ClientMessageRequestFactory *factory = [ClientMessageRequestFactory new];
    
    return [self initWithManagedObjectContext:moc
                   upstreamInsertedObjectSync:upstreamObjectSync
                   upstreamModifiedObjectSync:assetModifiedSync
                         downstreamObjectSync:downstreamSync
                  localNotificationDispatcher:dispatcher
                       messageExpirationTimer:expirationTimer
                               requestFactory:factory
                     clientRegistrationStatus:clientRegistrationStatus];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc entityName:(NSString *)entityName localNotificationDispatcher:(ZMLocalNotificationDispatcher *)dispatcher clientRegistrationStatus:(ZMClientRegistrationStatus *)clientRegistrationStatus;
{
    ZMUpstreamInsertedObjectSync *upstreamObjectSync = [[ZMUpstreamInsertedObjectSync alloc] initWithTranscoder:self entityName:[ZMClientMessage entityName] filter:nil managedObjectContext:moc];
    ZMMessageExpirationTimer *messageTimer = [[ZMMessageExpirationTimer alloc] initWithManagedObjectContext:moc entityName:entityName localNotificationDispatcher:dispatcher filter:nil];
    
    return [self initWithManagedObjectContext:moc upstreamInsertedObjectSync:upstreamObjectSync localNotificationDispatcher:dispatcher messageExpirationTimer:messageTimer clientRegistrationStatus:clientRegistrationStatus];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                  upstreamInsertedObjectSync:(ZMUpstreamInsertedObjectSync *)upstreamInsertedObjectSync
                  upstreamModifiedObjectSync:(ZMUpstreamModifiedObjectSync *)upstreamModifiedObjectSync
                        downstreamObjectSync:(ZMDownstreamObjectSync *)downstreamObjectSync
                 localNotificationDispatcher:(ZMLocalNotificationDispatcher *)dispatcher
                      messageExpirationTimer:(ZMMessageExpirationTimer *)expirationTimer
                              requestFactory:(ClientMessageRequestFactory *)factory
                    clientRegistrationStatus:(ZMClientRegistrationStatus *)clientRegistrationStatus;
{
    self = [super initWithManagedObjectContext:moc upstreamInsertedObjectSync:upstreamInsertedObjectSync localNotificationDispatcher:dispatcher messageExpirationTimer:expirationTimer];
    if (self) {
        self.assetModifiedSync = upstreamModifiedObjectSync;
        self.downstreamSync = downstreamObjectSync;
        self.requestsFactory = factory;
        self.clientRegistrationStatus = clientRegistrationStatus;

        NSPredicate *needToProcessPredicate = [NSPredicate predicateWithFormat:@"(mediumGenericMessage.image.width == 0 || previewGenericMessage.image.width == 0) && delivered == NO"];
        NSPredicate *fetchPredicate = [NSPredicate predicateWithValue:YES];
        NSOperationQueue *preprocessQueue = [[NSOperationQueue alloc] init];
        self.assetPreprocessor = [[ZMAssetPreprocessingTracker alloc] initWithManagedObjectContext:moc imageProcessingQueue:preprocessQueue fetchPredicate:fetchPredicate needsProcessingPredicate:needToProcessPredicate entityClass:ZMAssetClientMessage.class];
    }
    return self;
}

- (NSArray *)contextChangeTrackers
{
    NSMutableArray *trackers = [[super contextChangeTrackers] mutableCopy];
    [trackers addObject:self.assetModifiedSync];
    [trackers addObject:self.downstreamSync];
    [trackers addObject:self.assetPreprocessor];
    return trackers;
}

- (NSArray * __nonnull)requestGenerators
{
    NSMutableArray *generators = [[super requestGenerators] mutableCopy];
    [generators addObject:self.assetModifiedSync];
    [generators addObject:self.downstreamSync];
    return generators;
}

- (ZMTransportRequest *)requestForInsertingObject:(ZMClientMessage *)message
{
    //should be called only for not-image client messages
    ZMTransportRequest *request = [self.requestsFactory upstreamRequestForMessage:message forConversationWithId:message.conversation.remoteIdentifier];
    return request;
}

- (ZMUpstreamRequest *)requestForUpdatingObject:(ZMAssetClientMessage *)message forKeys:(NSSet *)keys
{
    ZMImageFormat format = ZMImageFormatInvalid;
    
    if ([keys containsObject:ZMAssetClientMessage_NeedsToUploadPreviewKey]) {
        format = ZMImageFormatPreview;
    }
    else if ([keys containsObject:ZMAssetClientMessage_NeedsToUploadMediumKey]) {
        format = ZMImageFormatMedium;
    }
    if(format == ZMImageFormatInvalid) {
        ZMTrapUnableToGenerateRequest(keys, self);
        return nil;
    }
    ZMUpstreamRequest *request = [self requestForUpdatingAssetClientMessage:message format:format];
    if (request == nil) {
        //when we failed to create upstream request we check if we can (and should) process image data again
        //if we can't than something is wrong and we can't really recover from that and we just delete such message
        //if we can we schedule processing
        if ([message shouldReprocessForFormat:format]) {
            [self scheduleImageProcessingForMessage:message format:format];
        }
        else {
            [message.managedObjectContext deleteObject:message];
        }
    }
    return request;
}

- (void)scheduleImageProcessingForMessage:(ZMAssetClientMessage *)message format:(ZMImageFormat)format
{
    // to trigger image processing we reset image properties to nil
    // this will make asset preprocessortracker from client message transcoder to pick up this image again
    ZMGenericMessage *genericMessage = [ZMGenericMessage messageWithMediumImageProperties:nil
                                                    processedImageProperties:nil
                                                              encryptionKeys:nil
                                                                       nonce:message.nonce.transportString
                                                                      format:format];
    [message addGenericMessage:genericMessage];
    [ZMOperationLoop notifyNewRequestsAvailable:self];
}

- (ZMUpstreamRequest *)requestForUpdatingAssetClientMessage:(ZMAssetClientMessage *)message format:(ZMImageFormat)format
{
    ZMTransportRequest *request = [self.requestsFactory upstreamRequestForAssetMessage:format message:message forConversationWithId:message.conversation.remoteIdentifier];
    if (request == nil) {
        return nil;
    }
    
    ZM_WEAK(self);
    [request addCompletionHandler:[ZMCompletionHandler handlerOnGroupQueue:self.managedObjectContext block:^(ZMTransportResponse *response) {
        if (response.result == ZMTransportResponseStatusSuccess) {
            ZM_STRONG(self);
            [message markAsDelivered];
            [self.managedObjectContext enqueueDelayedSave];
            [ZMOperationLoop notifyNewRequestsAvailable:self]; //to send next image
        } else if (response.HTTPStatus == 409) {
            ZMLogWarn(@"Tried to upload %@ for %@, but it was already on the backend. Ignoring.", [message genericMessageForFormat:format].image.tag, message.nonce.transportString);
        } else if (response.HTTPStatus != 412) {
            //missing clients
            ZMLogWarn(@"Failed to upload %@ for %@. Ignoring.", [message genericMessageForFormat:format].image.tag, message.nonce.transportString);
        }
    } ]];
    
    NSSet *actualKeys;
    if (format == ZMImageFormatPreview) {
        actualKeys = [NSSet setWithObject:ZMAssetClientMessage_NeedsToUploadPreviewKey];
    }
    else {
        actualKeys = [NSSet setWithObject:ZMAssetClientMessage_NeedsToUploadMediumKey];
    }
    
    return [[ZMUpstreamRequest alloc] initWithKeys:actualKeys transportRequest:request];

}

- (void)updateInsertedObject:(ZMMessage *)message request:(ZMUpstreamRequest *)upstreamRequest response:(ZMTransportResponse *)response;
{
    [super updateInsertedObject:message request:upstreamRequest response:response];
    [self deleteClientsFromResponse:response];
}

- (BOOL)updateUpdatedObject:(ZMAssetClientMessage *)message
            requestUserInfo:(NSDictionary *)requestUserInfo
                   response:(ZMTransportResponse *)response
                keysToParse:(NSSet *)keysToParse
{
    BOOL result = [super updateUpdatedObject:message requestUserInfo:requestUserInfo response:response keysToParse:keysToParse];
    
    if([keysToParse contains:ZMAssetClientMessage_NeedsToUploadPreviewKey]) {
        [message setNeedsToUploadFormat:ZMImageFormatPreview needsToUpload:NO];
        [[[AssetDirectory alloc] init] deleteAssetData:message.nonce format:ZMImageFormatPreview encrypted:YES];
    }
    if([keysToParse contains:ZMAssetClientMessage_NeedsToUploadMediumKey]) {
        NSUUID *assetId = [NSUUID uuidWithTransportString:response.headers[@"Location"]];
        message.assetId = assetId;
        [message setNeedsToUploadFormat:ZMImageFormatMedium needsToUpload:NO];
        [[[AssetDirectory alloc] init] deleteAssetData:message.nonce format:ZMImageFormatMedium encrypted:YES];
    }

    [self deleteClientsFromResponse:response];
    
    return result;
}

- (void)deleteClientsFromResponse:(ZMTransportResponse *)response {
    
    NSDictionary *payload = response.payload.asDictionary;
    NSDictionary *deleted = [payload optionalDictionaryForKey:@"deleted"];
    if (deleted.count > 0) {
        [self deleteClientsFromDeletedMap:deleted];
    }
}

- (BOOL)failedToUpdateInsertedObject:(ZMClientMessage *)message request:(ZMUpstreamRequest *__unused)upstreamRequest response:(ZMTransportResponse *)response keysToParse:(NSSet * __unused)keys
{
    
    // In case the self client got deleted remotely we will receive an event through the push channel and log out.
    // If we for some reason miss the push the BE will repond with a 403 and 'unknown-client' label to our
    // next sending attempt and we will logout and delete the current selfClient then
    if (response.HTTPStatus == 403) {
        NSString *errorLabel = [[response.payload asDictionary] optionalStringForKey:@"label"];
        if([errorLabel isEqualToString:@"unknown-client"]) {
            [self.clientRegistrationStatus didDetectCurrentClientDeletion];
            return NO;
        }
    }
    
    NSDictionary *payload = response.payload.asDictionary;
    NSDictionary *missingMap = [payload optionalDictionaryForKey:@"missing"];
    
    NSArray *missingUsersIdsData = [missingMap.allKeys mapWithBlock:^id(NSString *userIdTransportString) {
        return [NSUUID uuidWithTransportString:userIdTransportString].data;
    }];
    
    if (missingMap.count > 0) {
        
        NSSet<UserClient *> *missingClients = [self missingClientsFromMissingMap:missingMap forMessage:message];

        UserClient *selfClient = [ZMUser selfUserInContext:self.managedObjectContext].selfClient;
        [selfClient missesClients:missingClients];
        [message missesRecipients:missingClients];
        
        [selfClient addNewClientsToIgnored:missingClients causedBy:message];
        
        NSFetchRequest *missingUsersRequest = [NSFetchRequest fetchRequestWithEntityName:[ZMUser entityName]];
        missingUsersRequest.predicate = [NSPredicate predicateWithFormat:@"%K IN %@", [ZMUser remoteIdentifierDataKey], missingUsersIdsData];
        NSArray *existingMissingUsers = [self.managedObjectContext executeFetchRequestOrAssert:missingUsersRequest];
        
        for (NSString *userId in missingMap) {
            NSArray *userMissingClients = [missingMap arrayForKey:userId];
            NSUUID *userUUID = [NSUUID uuidWithTransportString:userId];
            NSPredicate *userByIdPredicate = [NSPredicate predicateWithFormat:@"%K == %@", [ZMUser remoteIdentifierDataKey], userUUID.data];
            ZMUser *user = [existingMissingUsers filteredArrayUsingPredicate:userByIdPredicate].firstObject;
            if(user == nil) {
                user = [ZMUser insertNewObjectInManagedObjectContext:self.managedObjectContext];
                user.remoteIdentifier = userUUID;
            }
            if (user != nil) {
                if (![message.conversation.activeParticipants containsObject:user]) {
                    message.conversation.needsToBeUpdatedFromBackend = YES;
                    [self updateConnectionIfNeededForCoversation:message.conversation user:user];
                }
                for (NSString *clientId in userMissingClients) {
                    UserClient *missingClient;
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"remoteIdentifier == %@", clientId];
                    missingClient = [[user.clients filteredSetUsingPredicate:predicate] anyObject];
                    if (missingClient == nil) {
                        missingClient = [UserClient insertNewObjectInManagedObjectContext:self.managedObjectContext];
                        missingClient.remoteIdentifier = clientId;
                        missingClient.user = user;
                    }
                    [selfClient missesClient:missingClient];
                    [message missesRecipient:missingClient];
                }
            }
        }
        [message.managedObjectContext enqueueDelayedSave];
        return YES;
    }
    
    [self deleteClientsFromResponse:response];
    
    return NO;
}

- (void)deleteClientsFromDeletedMap:(NSDictionary *)deletedMap
{
    for (NSString *userId in deletedMap) {
        ZMUser *user = [ZMUser userWithRemoteID:[NSUUID uuidWithTransportString:userId] createIfNeeded:NO inContext:self.managedObjectContext];
        if (user == nil) {
            continue;
        }
        NSSet<NSString *> *deletedClientsIds = [NSSet setWithArray:[deletedMap arrayForKey:userId]];
        for (NSString *clientId in deletedClientsIds) {
            UserClient *client = [UserClient fetchUserClientWithRemoteId:clientId forUser:user createIfNeeded:NO];
            [client deleteClientAndEndSession];
        }
    }
}

- (NSSet<UserClient *> *)missingClientsFromMissingMap:(NSDictionary *)missingMap forMessage:(ZMClientMessage *)message
{
    NSMutableSet<UserClient *> *missingClients = [NSMutableSet new];
    
    for (NSString *userId in missingMap) {
        ZMUser *user = [ZMUser userWithRemoteID:[NSUUID uuidWithTransportString:userId] createIfNeeded:YES inContext:message.managedObjectContext];
        if (user != nil) {
            NSSet<NSString *> *userMissingClientsIds = [NSSet setWithArray:[missingMap arrayForKey:userId]];
            NSSet<UserClient *> *userClients = [userMissingClientsIds mapWithBlock:^UserClient *(NSString *clientId) {
                return [UserClient fetchUserClientWithRemoteId:clientId forUser:user createIfNeeded:YES];
            }];
            [missingClients unionSet:userClients];
        }
    }
    return missingClients;
}


- (void)updateConnectionIfNeededForCoversation:(ZMConversation *)conversation user:(ZMUser *)user
{
    if (conversation.conversationType == ZMConversationTypeOneOnOne || conversation.conversationType == ZMConversationTypeConnection) {
        if (user.connection == nil) {
            if (conversation.connection == nil) {
                user.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.managedObjectContext];
                conversation.connection = user.connection;
            } else {
                user.connection = conversation.connection;
            }
        } else if (conversation.connection == nil) {
            conversation.connection = user.connection;
        }
        user.connection.needsToBeUpdatedFromBackend = YES;
    }
}

- (ZMManagedObject *)dependentObjectNeedingUpdateBeforeProcessingObject:(ZMClientMessage *)message;
{
    // If we receive a missing payload that includes users that are not part of the conversation, we need to refetch the conversation before recreating the message payload
    // Otherwise we end up in an endless loop receiving missing clients error
    ZMConversation *conversation = message.conversation;
    
    if (conversation.needsToBeUpdatedFromBackend) {
        return  conversation;
    }
    ZMConversationType convType = conversation.conversationType;
    if ((convType == ZMConversationTypeOneOnOne ||  convType == ZMConversationTypeConnection) &&
        conversation.connection.needsToBeUpdatedFromBackend)
    {
        return conversation.connection;
    }
    
    UserClient *selfClient = [ZMUser selfUserInContext:self.managedObjectContext].selfClient;
    NSSet *missingClients = selfClient.missingClients;
    if (missingClients.count > 0) {
        // for some reason flatten does not work?!
        NSMutableSet *activeClients = [NSMutableSet set];
        [conversation.activeParticipants enumerateObjectsUsingBlock:^(ZMUser *user, ZM_UNUSED NSUInteger idx, ZM_UNUSED BOOL * _Nonnull stop) {
            NSSet *clients = [NSSet setWithSet:user.clients];
            [activeClients unionSet:clients];
        }];
        // Don't block sending of messages in conversations that are not affected by missing clients
        if ([activeClients intersectsSet:missingClients]) {
            return selfClient;
        }
    }
    ZMManagedObject *dependency = [super dependentObjectNeedingUpdateBeforeProcessingObject:message];
    return dependency;

}

- (ZMMessage *)messageFromUpdateEvent:(ZMUpdateEvent *)event
                       prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    CBCryptoBox *box = [self.managedObjectContext zm_cryptKeyStore].box;
    ZMUpdateEvent *decryptedEvent = [box decryptUpdateEventAndAddClient:event managedObjectContext:self.managedObjectContext];
    
    if(decryptedEvent == nil) {
        return nil;
    }
    
    ZMMessage *message;
    switch (event.type) {
        case ZMUpdateEventConversationClientMessageAdd:
        case ZMUpdateEventConversationOtrMessageAdd:
            message = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:decryptedEvent
                                                     inManagedObjectContext:self.managedObjectContext
                                                             prefetchResult:prefetchResult];
            break;
        case ZMUpdateEventConversationOtrAssetAdd:
            message = [ZMAssetClientMessage createOrUpdateMessageFromUpdateEvent:decryptedEvent
                                                          inManagedObjectContext:self.managedObjectContext
                                                                  prefetchResult:prefetchResult];
            break;
        default:
            return nil;
    }
    [message markAsDelivered];
    return message;
}

@end

@implementation ZMClientMessageTranscoder (ZMDownstreamMediumImageTranscoder)

- (ZMTransportRequest *)requestForFetchingObject:(ZMAssetClientMessage *)imageMessage downstreamSync:(ZMDownstreamObjectSync * __unused)downstreamSync;
{
    //if we have data stored already we don't need to make request
    //we just update message using this data
    AssetDirectory *assetDirectory = [AssetDirectory new];
    NSData *existingData = [assetDirectory assetData:imageMessage.nonce format:ZMImageFormatMedium encrypted:imageMessage.isEncrypted];
    if (existingData == nil) {
        return [self.requestsFactory requestToGetAsset:imageMessage.assetId inConversation:imageMessage.conversation.remoteIdentifier isEncrypted:imageMessage.isEncrypted];
    }
    else {
        [self updateObject:imageMessage withImageData:existingData];
        [self.managedObjectContext enqueueDelayedSave];
        return nil;
    }
}

- (void)updateObject:(ZMManagedObject *)object withResponse:(ZMTransportResponse *)response downstreamSync:(ZMDownstreamObjectSync * __unused)downstreamSync;
{
    [self updateObject:(ZMAssetClientMessage *)object withImageData:response.rawData];
}

- (void)deleteObject:(ZMAssetClientMessage *)imageMessage downstreamSync:(ZMDownstreamObjectSync * __unused)downstreamSync;
{
    [imageMessage.managedObjectContext deleteObject:imageMessage];
}

- (void)updateObject:(ZMAssetClientMessage *)imageMessage withImageData:(NSData *)mediumImageData;
{
    [imageMessage updateMessageWithImageData:mediumImageData forFormat:ZMImageFormatMedium];
}

@end
