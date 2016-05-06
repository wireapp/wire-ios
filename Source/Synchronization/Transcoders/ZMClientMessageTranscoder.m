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

@import ZMCDataModel;

#import "ZMClientMessageTranscoder+Internal.h"
#import "ZMMessageTranscoder+Internal.h"
#import "ZMUpstreamInsertedObjectSync.h"
#import "ZMMessageExpirationTimer.h"
#import "ZMUpstreamTranscoder.h"
#import "ZMImagePreprocessingTracker.h"

#import "ZMClientRegistrationStatus.h"
#import "ZMLocalNotificationDispatcher.h"

#import "CBCryptoBox+UpdateEvents.h"
#import <zmessaging/zmessaging-Swift.h>
#import "ZMOperationLoop.h"

@interface ZMClientMessageTranscoder()

@property (nonatomic) ZMUpstreamModifiedObjectSync *assetModifiedSync;
@property (nonatomic) ZMDownstreamObjectSync *downstreamSync;
@property (nonatomic) ClientMessageRequestFactory *requestsFactory;
@property (nonatomic) ZMImagePreprocessingTracker *imagePreprocessor;
@property (nonatomic, weak) ZMClientRegistrationStatus *clientRegistrationStatus;

@end


@implementation ZMClientMessageTranscoder

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                 localNotificationDispatcher:(ZMLocalNotificationDispatcher *)dispatcher
                    clientRegistrationStatus:(ZMClientRegistrationStatus *)clientRegistrationStatus;
{
    ZMUpstreamInsertedObjectSync *clientTextMessageUpstreamSync = [[ZMUpstreamInsertedObjectSync alloc] initWithTranscoder:self entityName:[ZMClientMessage entityName] filter:nil managedObjectContext:moc];
    ZMMessageExpirationTimer *messageTimer = [[ZMMessageExpirationTimer alloc] initWithManagedObjectContext:moc entityName:[ZMClientMessage entityName] localNotificationDispatcher:dispatcher filter:nil];
    ZMUpstreamModifiedObjectSync *assetModifiedSync = [[ZMUpstreamModifiedObjectSync alloc] initWithTranscoder:self
                                                                                                    entityName:[ZMAssetClientMessage entityName]
                                                                                               updatePredicate:nil
                                                                                                        filter:[NSPredicate predicateWithFormat:@"filename == nil"]
                                                                                                    keysToSync:nil
                                                                                          managedObjectContext:moc];
    
    NSPredicate *mediumDataNeedsToBeDownloaded = [NSPredicate predicateWithFormat:@"assetId_data != NIL && loadedMediumData == NO"];
    ZMDownstreamObjectSync *downstreamSync = [[ZMDownstreamObjectSync alloc] initWithTranscoder:self
                                                                                     entityName:[ZMAssetClientMessage entityName]
                                                                  predicateForObjectsToDownload:mediumDataNeedsToBeDownloaded
                                                                                         filter:[NSPredicate predicateWithFormat:@"imageMessageData != nil"]
                                                                           managedObjectContext:moc];
    ClientMessageRequestFactory *factory = [ClientMessageRequestFactory new];
    
    self = [super initWithManagedObjectContext:moc
                    upstreamInsertedObjectSync:clientTextMessageUpstreamSync
                   localNotificationDispatcher:dispatcher
                        messageExpirationTimer:messageTimer];
    if (self) {
        self.assetModifiedSync = assetModifiedSync;
        self.downstreamSync = downstreamSync;
        self.requestsFactory = factory;
        self.clientRegistrationStatus = clientRegistrationStatus;
        
        NSPredicate *needToProcessPredicate = [NSPredicate predicateWithFormat:@"(mediumGenericMessage.image.width == 0 || previewGenericMessage.image.width == 0) && delivered == NO"];
        NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"delivered == NO"];
        NSOperationQueue *preprocessQueue = [[NSOperationQueue alloc] init];
        self.imagePreprocessor = [[ZMImagePreprocessingTracker alloc] initWithManagedObjectContext:moc
                                                                              imageProcessingQueue:preprocessQueue
                                                                                    fetchPredicate:fetchPredicate
                                                                          needsProcessingPredicate:needToProcessPredicate
                                                                                       entityClass:ZMAssetClientMessage.class];
    }
    return self;
}

- (NSArray *)contextChangeTrackers
{
    NSMutableArray *trackers = [[super contextChangeTrackers] mutableCopy];
    [trackers addObject:self.assetModifiedSync];
    [trackers addObject:self.downstreamSync];
    [trackers addObject:self.imagePreprocessor];
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

- (BOOL)shouldCreateRequestToSyncObject:(ZMAssetClientMessage *)message forKeys:(NSSet *)keys withSync:(id)sync
{
    NOT_USED(sync);
    ZMImageFormat format = [self imageFormatForKeys:keys];
    if(format == ZMImageFormatInvalid) {
        // we will ultimately crash here when trying to create the request
        return YES;
    }
    if ([message.imageAssetStorage shouldReprocessForFormat:format]) {
        // before we create an upstream request we should check if we can (and should) process image data again
        // if we can we reschedule processing
        // this might cause a loop if the message can not be processed whatsoever
        [self scheduleImageProcessingForMessage:message format:format];
        [self.managedObjectContext saveOrRollback];
        return NO;
    }
    return YES;
}

- (ZMImageFormat)imageFormatForKeys:(NSSet *)keys
{
    ZMImageFormat format = ZMImageFormatInvalid;
    if ([keys containsObject:ZMAssetClientMessage_NeedsToUploadPreviewKey]) {
        format = ZMImageFormatPreview;
    }
    else if ([keys containsObject:ZMAssetClientMessage_NeedsToUploadMediumKey]) {
        format = ZMImageFormatMedium;
    }
    return format;
}

- (ZMUpstreamRequest *)requestForUpdatingObject:(ZMAssetClientMessage *)message forKeys:(NSSet *)keys
{
    ZMImageFormat format = [self imageFormatForKeys:keys];
    if(format == ZMImageFormatInvalid) {
        ZMTrapUnableToGenerateRequest(keys, self);
        return nil;
    }
    ZMUpstreamRequest *request = [self requestForUpdatingAssetClientMessage:message format:format];
    if (request == nil) {
        // We will crash, but we should still delete the image
        [message.managedObjectContext deleteObject:message];
        [self.managedObjectContext saveOrRollback];
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
            ZMLogWarn(@"Tried to upload %@ for %@, but it was already on the backend. Ignoring.", [message.imageAssetStorage genericMessageForFormat:format].image.tag, message.nonce.transportString);
        } else if (response.HTTPStatus != 412) {
            //missing clients
            ZMLogWarn(@"Failed to upload %@ for %@. Ignoring.", [message.imageAssetStorage genericMessageForFormat:format].image.tag, message.nonce.transportString);
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
    [(ZMClientMessage *)message parseUploadResponse:response clientDeletionDelegate:self.clientRegistrationStatus];
}

- (BOOL)updateUpdatedObject:(ZMAssetClientMessage *)message
            requestUserInfo:(NSDictionary *)requestUserInfo
                   response:(ZMTransportResponse *)response
                keysToParse:(NSSet *)keysToParse
{
    BOOL result = [super updateUpdatedObject:message requestUserInfo:requestUserInfo response:response keysToParse:keysToParse];
    
    if([keysToParse contains:ZMAssetClientMessage_NeedsToUploadPreviewKey]) {
        [self.managedObjectContext.zm_imageAssetCache deleteAssetData:message.nonce format:ZMImageFormatPreview encrypted:YES];
    }
    if([keysToParse contains:ZMAssetClientMessage_NeedsToUploadMediumKey]) {
        NSUUID *assetId = [NSUUID uuidWithTransportString:response.headers[@"Location"]];
        message.assetId = assetId;
        [self.managedObjectContext.zm_imageAssetCache deleteAssetData:message.nonce format:ZMImageFormatMedium encrypted:YES];
    }
    [self resetFlagsForNeedsToUploadKeys:keysToParse onAssetMessage:message];
    [message parseUploadResponse:response clientDeletionDelegate:self.clientRegistrationStatus];    
    return result;
}

- (void)resetFlagsForNeedsToUploadKeys:(NSSet *)keys onAssetMessage:(ZMAssetClientMessage *)message
{
    if ([keys containsObject:ZMAssetClientMessage_NeedsToUploadMediumKey] ) {
        [message setNeedsToUploadData:ZMAssetClientMessageDataTypeFileData needsToUpload:NO];
    }
    if([keys containsObject:ZMAssetClientMessage_NeedsToUploadPreviewKey]) {
        [message setNeedsToUploadData:ZMAssetClientMessageDataTypePlaceholder needsToUpload:NO];
    }
}

- (BOOL)shouldRetryToSyncAfterFailedToUpdateObject:(ZMClientMessage *)message request:(ZMUpstreamRequest *__unused)upstreamRequest response:(ZMTransportResponse *)response keysToParse:(NSSet * __unused)keys
{
    BOOL shouldRetry = [message parseUploadResponse:response clientDeletionDelegate:self.clientRegistrationStatus];
    if(!shouldRetry && [message isKindOfClass:ZMAssetClientMessage.class]) {
        [self resetFlagsForNeedsToUploadKeys:keys onAssetMessage:(ZMAssetClientMessage *)message];
    }
    return shouldRetry;
}


- (ZMManagedObject *)dependentObjectNeedingUpdateBeforeProcessingObject:(ZMClientMessage *)message;
{
    return message.dependendObjectNeedingUpdateBeforeProcessing;
}

- (ZMMessage *)messageFromUpdateEvent:(ZMUpdateEvent *)event
                       prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    CBCryptoBox *box = [self.managedObjectContext zm_cryptKeyStore].box;
    ZMUpdateEvent *decryptedEvent = [box decryptUpdateEventAndAddClient:event managedObjectContext:self.managedObjectContext];
    
    if (decryptedEvent == nil) {
        return nil;
    }
    
    ZMMessage *message;
    switch (event.type) {
        case ZMUpdateEventConversationClientMessageAdd:
        case ZMUpdateEventConversationOtrMessageAdd:
        case ZMUpdateEventConversationOtrAssetAdd:
            message = [ZMOTRMessage createOrUpdateMessageFromUpdateEvent:decryptedEvent
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
    NSData *existingData = [self.managedObjectContext.zm_imageAssetCache assetData:imageMessage.nonce format:ZMImageFormatMedium encrypted:imageMessage.isEncrypted];
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
    [imageMessage.imageAssetStorage updateMessageWithImageData:mediumImageData forFormat:ZMImageFormatMedium];
}

@end
