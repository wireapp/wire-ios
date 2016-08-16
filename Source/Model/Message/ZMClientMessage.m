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


@import ZMCSystem;
@import ZMUtilities;
@import ZMTransport;
@import ZMProtos;
@import CoreGraphics;
@import ImageIO;
@import MobileCoreServices;
@import Cryptobox;

#import "ZMClientMessage.h"
#import "ZMConversation+Internal.h"
#import "ZMConversation+Transport.h"
#import "ZMUpdateEvent+ZMCDataModel.h"
#import "ZMGenericMessage+UpdateEvent.h"

#import "ZMGenericMessageData.h"
#import "ZMUser+Internal.h"
#import "ZMOTRMessage.h"
#import "ZMGenericMessage+External.h"
#import <ZMCDataModel/ZMCDataModel-Swift.h>

static NSString * const ClientMessageDataSetKey = @"dataSet";
static NSString * const ClientMessageGenericMessageKey = @"genericMessage";
static NSString * const ClientMessageUpdateTimestamp = @"updatedTimestamp";

NSString * const ZMClientMessageLinkPreviewImageDownloadNotificationName = @"ZMClientMessageLinkPreviewImageDownloadNotificationName";
NSString * const ZMClientMessageLinkPreviewStateKey = @"linkPreviewState";
NSString * const ZMFailedToCreateEncryptedMessagePayloadString = @"💣";
// From https://github.com/wearezeta/generic-message-proto:
// "If payload is smaller then 256KB then OM can be sent directly"
// Just to be sure we set the limit lower, to 128KB (base 10)
NSUInteger const ZMClientMessageByteSizeExternalThreshold = 128000;

@interface ZMClientMessage()

@property (nonatomic) ZMGenericMessage *genericMessage;

@end

@interface ZMClientMessage (ZMKnockMessageData) <ZMKnockMessageData>

@end

@interface ZMClientMessage (ZMLocationMessageData) <ZMLocationMessageData>

@end

@interface ZMClientMessage (ZMTextMessageData) <ZMTextMessageData>

@end

@implementation ZMClientMessage

@dynamic linkPreviewState;
@dynamic updatedTimestamp;

@synthesize genericMessage = _genericMessage;

- (void)awakeFromInsert;
{
    [super awakeFromInsert];
    self.nonce = nil;
}

+ (NSString *)entityName;
{
    return @"ClientMessage";
}

- (NSSet *)ignoredKeys
{
    return [[super ignoredKeys] setByAddingObject:ClientMessageUpdateTimestamp];
}

- (NSDate *)updatedAt
{
    return self.updatedTimestamp;
}

- (void)addData:(NSData *)data
{
    if (data == nil) {
        return;
    }
    
    ZMGenericMessageData *messageData = [self mergeWithExistingData:data];
    [self setGenericMessage:self.genericMessageFromDataSet];
    
    if (self.nonce == nil) {
        self.nonce = [NSUUID uuidWithTransportString:messageData.genericMessage.messageId];
    }
    
    [self setLocallyModifiedKeys:[NSSet setWithObject:ClientMessageDataSetKey]];
}

- (ZMGenericMessage *)genericMessage
{
    if (_genericMessage == nil) {
        _genericMessage = [self genericMessageFromDataSet] ?: (ZMGenericMessage *)[NSNull null];
    }
    if (_genericMessage == (ZMGenericMessage *)[NSNull null]) {
        return nil;
    }
    return _genericMessage;
}

- (ZMGenericMessageData *)mergeWithExistingData:(NSData *)data
{
    _genericMessage = nil;
    ZMGenericMessageData *existingMessageData = [self.dataSet firstObject];
    
    if (existingMessageData != nil) {
        existingMessageData.data = data;
        
        NSManagedObjectContext *uiMOC = self.managedObjectContext.zm_userInterfaceContext;
        NSManagedObjectID *objectID = self.objectID;
        
        [uiMOC performGroupedBlock:^{
            ZMClientMessage *uiMOCMessage = [uiMOC existingObjectWithID:objectID error:nil];
            if (nil == uiMOCMessage) {
                return;
            }
            [uiMOC.globalManagedObjectContextObserver notifyNonCoreDataChangeInManagedObject:uiMOCMessage];
        }];
        
        return existingMessageData;
    }
    else {
        ZMGenericMessageData *messageData = [NSEntityDescription insertNewObjectForEntityForName:[ZMGenericMessageData entityName] inManagedObjectContext:self.managedObjectContext];
        messageData.data = data;
        messageData.message = self;
        return messageData;
    }
}

- (void)setGenericMessage:(ZMGenericMessage *)genericMessage
{
    if ([genericMessage knownMessage] && !genericMessage.hasImage) {
        _genericMessage = genericMessage;
    }
}

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    _genericMessage = nil;
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
    [super awakeFromSnapshotEvents:flags];
    _genericMessage = nil;
}

- (void)didTurnIntoFault
{
    [super didTurnIntoFault];
    _genericMessage = nil;
}

- (ZMGenericMessage *)genericMessageFromDataSet
{
    NSArray <ZMGenericMessage *> *filteredMessages = [[self.dataSet.array mapWithBlock:^ZMGenericMessage *(ZMGenericMessageData *data) {
        return data.genericMessage;
    }] filterWithBlock:^BOOL(ZMGenericMessage *message) {
        return [message knownMessage] && !message.hasImage;
    }];

    if (0 == filteredMessages.count) {
        return nil;
    }
    
    ZMGenericMessageBuilder *builder = ZMGenericMessage.builder;
    for (ZMGenericMessage *message in filteredMessages) {
        [builder mergeFrom:message];
    }
    
    return builder.build;
}

+ (NSSet *)keyPathsForValuesAffectingGenericMessage
{
    return [NSSet setWithObject:ClientMessageDataSetKey];
}

- (void)updateWithGenericMessage:(ZMGenericMessage *)message updateEvent:(ZMUpdateEvent *__unused)updateEvent
{
    [self addData:message.data];
}

- (void)removeMessage
{
    _genericMessage = nil;
    self.dataSet = [NSOrderedSet orderedSet];
    [super removeMessage];
}

- (void)expire
{
    if (self.genericMessage.hasEdited) {
        // Fetch original message
        NSUUID *originalID = [NSUUID uuidWithTransportString:self.genericMessage.edited.replacingMessageId];
        ZMMessage *originalMessage = [ZMMessage fetchMessageWithNonce:originalID forConversation:self.conversation inManagedObjectContext:self.managedObjectContext];
        
        // Replace the nonce with the original
        // This way if we get a delete from a different device while we are waiting for the response it will delete this message
        self.nonce = originalID;
        
        // delete the original message - we do not care about the old one anymore
        [self.managedObjectContext deleteObject:originalMessage];
    }
    [super expire];
}

- (void)resend
{
    if (self.genericMessage.hasEdited) {
        [ZMMessage edit:self newText:self.textMessageData.messageText];
    } else {
        [super resend];
    }
}

- (id<ZMTextMessageData>)textMessageData
{
    if (self.genericMessage.hasText || self.genericMessage.hasEdited) {
        return self;
    }
    return nil;
}

- (id<ZMImageMessageData>)imageMessageData
{
    return nil;
}

- (id<ZMKnockMessageData>)knockMessageData
{
    if (self.genericMessage.hasKnock) {
        return self;
    }
    return nil;
}

- (id<ZMFileMessageData>)fileMessageData
{
    return nil;
}

- (id<ZMLocationMessageData>)locationMessageData
{
    if (self.genericMessage.hasLocation) {
        return self;
    }
    return nil;
}

- (void)updateWithPostPayload:(NSDictionary *)payload updatedKeys:(__unused NSSet *)updatedKeys
{
    if (self.genericMessage.hasEdited) {
        NSUUID *nonce = [self nonceFromPostPayload:payload];
        if (nonce != nil && ![self.nonce isEqual:nonce]) {
            ZMLogWarn(@"send message response nonce does not match");
            return;
        }
        NSDate *serverTimestamp = [payload dateForKey:@"time"];
        if (serverTimestamp != nil) {
            self.updatedTimestamp = serverTimestamp;
        }
        NSUUID *originalID = [NSUUID uuidWithTransportString:self.genericMessage.edited.replacingMessageId];
        ZMMessage *original = [ZMMessage fetchMessageWithNonce:originalID forConversation:self.conversation inManagedObjectContext:self.managedObjectContext];
        [original removeMessage];
    } else {
        [super updateWithPostPayload:payload updatedKeys:nil];
    }
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeInsertedUpstream
{
    NSPredicate *publicNotSynced = [NSPredicate predicateWithFormat:@"%K == NULL && %K == FALSE", ZMMessageEventIDDataKey, ZMMessageIsEncryptedKey];
    NSPredicate *encryptedNotSynced = [NSPredicate predicateWithFormat:@"%K == TRUE && %K == FALSE", ZMMessageIsEncryptedKey, DeliveredKey];
    NSPredicate *linkPreviewProcessed = [NSPredicate predicateWithFormat:@"%K == %d", ZMClientMessageLinkPreviewStateKey, ZMLinkPreviewStateUploaded];
    NSPredicate *notSynced = [NSCompoundPredicate orPredicateWithSubpredicates:@[publicNotSynced, encryptedNotSynced, linkPreviewProcessed]];
    NSPredicate *notExpired = [NSPredicate predicateWithFormat:@"%K == 0", ZMMessageIsExpiredKey];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[notSynced, notExpired]];
}

- (void)markAsDelivered
{
    [super markAsDelivered];
    
    if (self.linkPreviewState == ZMLinkPreviewStateUploaded) {
        self.linkPreviewState = ZMLinkPreviewStateDone;
    }
}

- (BOOL)hasDownloadedImage
{
    if (nil != self.textMessageData && nil != self.textMessageData.linkPreview) {
        return [self.managedObjectContext.zm_imageAssetCache assetData:self.nonce format:ZMImageFormatMedium encrypted:NO] != nil // processed or downloaded
        || [self.managedObjectContext.zm_imageAssetCache assetData:self.nonce format:ZMImageFormatOriginal encrypted:NO] != nil; // original
    }
    return false;
}

@end



@implementation ZMClientMessage (OTR)

- (NSData *)encryptedMessagePayloadData
{
    return [ZMClientMessage encryptedMessagePayloadDataWithGenericMessage:self.genericMessage
                                                             conversation:self.conversation
                                                     managedObjectContext:self.managedObjectContext
                                                             externalData:nil];
}

+ (NSData *)encryptedMessagePayloadDataWithGenericMessage:(ZMGenericMessage *)genericMessage
                                             conversation:(ZMConversation *)conversation
                                     managedObjectContext:(NSManagedObjectContext *)moc
                                             externalData:(NSData *)externalData
{
    UserClient *selfClient = [ZMUser selfUserInContext:moc].selfClient;
    if (selfClient.remoteIdentifier == nil) {
        return nil;
    }
    
    NSArray <ZMUserEntry *>*recipients = [ZMClientMessage recipientsWithDataToEncrypt:genericMessage.data
                                                                           selfClient:selfClient
                                                                         conversation:conversation];
    ZMNewOtrMessage *message = [ZMNewOtrMessage messageWithSender:selfClient nativePush:YES recipients:recipients blob:externalData];
    
    
    NSData *messageData = message.data;
    if (messageData.length > ZMClientMessageByteSizeExternalThreshold && nil == externalData) {
        
        // The payload is too big, we therefore rollback the session since we won't use the message we just encrypted.
        // This will prevent us advancing sender chain multiple time before sending a message, and reduce the risk of TooDistantFuture.
        [self rollbackUsersClientsSessionFromConversation:conversation selfClient:selfClient];
        return [self encryptedMessageDataWithExternalDataBlobFromMessage:genericMessage
                                                          inConversation:conversation
                                                    managedObjectContext:moc];
    }
    
    // here we know that the encrypted message(s) are going to be used to send a request, we persist the sessions
    [selfClient.keysStore.box saveSessionsRequiringSave];
    return messageData;
}

+ (NSArray <ZMUserEntry *>*)recipientsWithDataToEncrypt:(NSData *)dataToEncrypt selfClient:(UserClient *)selfClient conversation:(ZMConversation *)conversation;
{
    CBCryptoBox *box = selfClient.keysStore.box;
    
    NSArray <ZMUserEntry *>*recipients = [conversation.activeParticipants.array mapWithBlock:^ZMUserEntry *(ZMUser *user) {
        NSArray <ZMClientEntry *>*clientsEntries = [user.clients.allObjects mapWithBlock:^ZMClientEntry *(UserClient *client) {
            
            NSError *error;
            if (![client.remoteIdentifier isEqual:selfClient.remoteIdentifier]) {
                CBSession *session = [box sessionById:client.remoteIdentifier error:&error];
                
                // We do not have a session and will insert bogus data for this client
                // in order to show him a "failed to decrypt" message
                BOOL corruptedClient = client.failedToEstablishSession;
                client.failedToEstablishSession = NO;
                
                if (nil == session) {
                    if(corruptedClient) {
                        NSData *data = [ZMFailedToCreateEncryptedMessagePayloadString dataUsingEncoding:NSUTF8StringEncoding];
                        return [ZMClientEntry entryWithClient:client data:data];
                    } else {
                        return nil;
                    }
                }
                
                NSData *encryptedData = [session encrypt:dataToEncrypt error:&error];
                if (encryptedData != nil) {
                    [box setSessionToRequireSave:session];
                    return [ZMClientEntry entryWithClient:client data:encryptedData];
                } else {
                    // We failed to encrypt the data using that session, which is not normal.
                    // We rollback the session to the last serialised state
                    [box rollbackSession:session];
                }
            }

            return nil;
        }];
        
        if (clientsEntries.count == 0) {
            return nil;
        }
        
        return [ZMUserEntry entryWithUser:user clientEntries:clientsEntries];
    }];

    return recipients;
}

+ (void)rollbackUsersClientsSessionFromConversation:(ZMConversation *)conversation selfClient:(UserClient *)selfClient;
{
    CBCryptoBox *box = selfClient.keysStore.box;
    for (ZMUser *user in conversation.activeParticipants) {
        for (UserClient *client in user.clients) {
            if (![client.remoteIdentifier isEqual:selfClient.remoteIdentifier]) {

                NSError *error;
                CBSession *session = [box sessionById:client.remoteIdentifier error:&error];
                
                BOOL corruptedClient = client.failedToEstablishSession;
                client.failedToEstablishSession = NO;
                
                if (nil != session && !corruptedClient) {
                    [box rollbackSession:session];
                }
            }
        }
    }
}

@end



@implementation ZMClientMessage (External)


+ (NSData *)encryptedMessageDataWithExternalDataBlobFromMessage:(ZMGenericMessage *)message
                                                 inConversation:(ZMConversation *)conversation
                                           managedObjectContext:(NSManagedObjectContext *)context
{
    ZMExternalEncryptedDataWithKeys *encryptedDataWithKeys = [ZMGenericMessage encryptedDataWithKeysFromMessage:message];
    ZMGenericMessage *externalGenericMessage = [ZMGenericMessage genericMessageWithKeyWithChecksum:encryptedDataWithKeys.keys
                                                                                         messageID:NSUUID.UUID.transportString];
    
    return [self encryptedMessagePayloadDataWithGenericMessage:externalGenericMessage
                                                  conversation:conversation
                                          managedObjectContext:context
                                                  externalData:encryptedDataWithKeys.data];
}

@end



@implementation ZMClientMessage (ZMKnockMessage)

@end

#pragma mark - ZMLocationMessageData

@implementation ZMClientMessage (ZMLocationMessageData)

- (float)latitude
{
    return self.genericMessage.location.latitude;
}

- (float)longitude
{
    return self.genericMessage.location.longitude;
}

- (NSString *)name
{
    if (self.genericMessage.location.hasName) {
        return self.genericMessage.location.name;
    }
    
    return nil;
}

- (int32_t)zoomLevel
{
    if (self.genericMessage.location.hasZoom) {
        return self.genericMessage.location.zoom;
    }
    
    return 0;
}

@end


@implementation ZMClientMessage (ZMTextMessageData)

- (NSString *)messageText
{
    if (self.genericMessage.hasEdited) {
        return self.genericMessage.edited.text.content;
    }
    return self.genericMessage.text.content;
}

- (BOOL)isEdited
{
    return self.genericMessage.hasEdited;
}

- (LinkPreview *)linkPreview
{
    if (self.genericMessage.text.linkPreview.count > 0) {
        ZMLinkPreview *linkPreview = self.firstZMLinkPreview;
        
        if (linkPreview.hasTweet) {
            return [[TwitterStatus alloc] initWithProtocolBuffer:linkPreview];
        }
        else if (linkPreview.hasArticle) {
            return [[Article alloc] initWithProtocolBuffer:linkPreview];
        }
        
    }
    
    return nil;
}

- (ZMLinkPreview *)firstZMLinkPreview
{
    return self.genericMessage.text.linkPreview.firstObject;
}

- (void)requestImageDownload
{
    if (nil == self.linkPreview || self.objectID.isTemporaryID) {
        return;
    }
    
    ZMLinkPreview *linkPreview = self.firstZMLinkPreview;
    if (!linkPreview.article.image.uploaded.hasAssetId && !linkPreview.image.uploaded.hasAssetId) {
        return;
    }
    
    if (nil != self.imageData) {
        return;
    }

    [NSNotificationCenter.defaultCenter postNotificationName:ZMClientMessageLinkPreviewImageDownloadNotificationName
                                                      object:self.objectID
                                                    userInfo:nil];
}

- (void)setLinkPreviewState:(ZMLinkPreviewState)linkPreviewState
{
    [self willChangeValueForKey:ZMClientMessageLinkPreviewStateKey];
    [self setPrimitiveValue:@(linkPreviewState) forKey:ZMClientMessageLinkPreviewStateKey];
    [self didChangeValueForKey:ZMClientMessageLinkPreviewStateKey];
    
    if (ZMLinkPreviewStateDone != linkPreviewState) {
        [self setLocallyModifiedKeys:[NSSet setWithObject:ZMClientMessageLinkPreviewStateKey]];
    }
}

- (NSData *)imageData
{
    return [self.managedObjectContext.zm_imageAssetCache assetData:self.nonce format:ZMImageFormatOriginal encrypted:NO] ?:
    [self.managedObjectContext.zm_imageAssetCache assetData:self.nonce format:ZMImageFormatMedium encrypted:NO];
}

- (BOOL)hasImageData
{
    // If we already have processed the image, we can check the protobuf if it has an image,
    // there is a case however when sending a message that we don't have processed it yet but have the original image in the cache.
    ZMLinkPreview *linkPreview = [self firstZMLinkPreview];
    return linkPreview.article.hasImage || linkPreview.hasImage || self.imageData != nil;
}

- (NSString *)imageDataIdentifier
{
    ZMLinkPreview *linkPreview = [self firstZMLinkPreview];

    if (linkPreview.article.hasImage) {
        return linkPreview.article.image.uploaded.assetId;
    }
    else if (linkPreview.hasImage) {
        return linkPreview.image.uploaded.assetId;
    }
    
    return nil;
}

@end

@implementation ZMClientMessage (ZMImageOwner)

- (void)setImageData:(NSData *)imageData forFormat:(ZMImageFormat)format properties:(__unused ZMIImageProperties *)properties;
{
    if (format != ZMImageFormatMedium) {
        return;
    }
    
    ZMLinkPreview *linkPreview = [self.genericMessage.text.linkPreview firstObject];
    
    if (nil == linkPreview) {
        return;
    }
    
    [self.managedObjectContext.zm_imageAssetCache storeAssetData:self.nonce format:format encrypted:NO data:imageData];
    ZMImageAssetEncryptionKeys *keys = [self.managedObjectContext.zm_imageAssetCache encryptFileAndComputeSHA256Digest:self.nonce format:format];
    
    ZMAssetImageMetaData *imageMetaData = [ZMAssetImageMetaData imageMetaDataWithWidth:(int32_t)properties.size.width height:(int32_t)properties.size.height];
    ZMAssetOriginal *original = [ZMAssetOriginal originalWithSize:imageData.length mimeType:properties.mimeType name:nil imageMetaData:imageMetaData];
    
    [self addData:[ZMGenericMessage messageWithText:self.textMessageData.messageText
                                        linkPreview:[linkPreview updateWithOtrKey:keys.otrKey sha256:keys.sha256 original:original]
                                              nonce:self.nonce.transportString].data];
    
    [self.managedObjectContext enqueueDelayedSave];
}

- (NSData *)imageDataForFormat:(ZMImageFormat)format;
{
    return [self.managedObjectContext.zm_imageAssetCache assetData:self.nonce format:format encrypted:NO];
}

/// The image formats that this @c ZMImageOwner wants preprocessed. Order of formats determines order in which data is preprocessed
- (NSOrderedSet *)requiredImageFormats;
{
    if (self.genericMessage.text.linkPreview.count > 0) {
        return [NSOrderedSet orderedSetWithObject:@(ZMImageFormatMedium)];
    }
    return [NSOrderedSet orderedSet];
}

- (NSData *)originalImageData;
{
    return [self.managedObjectContext.zm_imageAssetCache assetData:self.nonce format:ZMImageFormatOriginal encrypted:NO];
}

- (CGSize)originalImageSize;
{
    NSData *originalImageData = self.originalImageData;
    
    if (originalImageData) {
        return [ZMImagePreprocessor sizeOfPrerotatedImageWithData:originalImageData];
    } else {
        return CGSizeZero;
    }
}

- (BOOL)isInlineForFormat:(__unused ZMImageFormat)format;
{
    return NO;
}

- (BOOL)isPublicForFormat:(__unused ZMImageFormat)format;
{
    return NO;
}

- (BOOL)isUsingNativePushForFormat:(__unused ZMImageFormat)format;
{
    return NO;
}

/// Notifies that the processing was competed
- (void)processingDidFinish;
{
    self.linkPreviewState = ZMLinkPreviewStateProcessed;
    [self.managedObjectContext.zm_imageAssetCache deleteAssetData:self.nonce format:ZMImageFormatOriginal encrypted:NO];
    [self.managedObjectContext enqueueDelayedSave];
}

@end
