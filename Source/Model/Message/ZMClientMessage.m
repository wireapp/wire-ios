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
NSString * const ZMClientMessageLinkPreviewKey = @"linkPreview";
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
    
    [self updateCategoryCache];
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
    if ([genericMessage knownMessage] && genericMessage.imageAssetData == nil) {
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
        return [message knownMessage] && message.imageAssetData == nil;
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
    [self updateNormalizedText];
}

- (void)deleteContent
{
    _genericMessage = nil;
    self.dataSet = [NSOrderedSet orderedSet];
    self.normalizedText = nil;
    self.genericMessage = nil;
}

- (void)removeMessageClearingSender:(BOOL)clearingSender
{
    [self deleteContent];
    [super removeMessageClearingSender:clearingSender];
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
    if (self.genericMessage.textData != nil) {
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
    if (self.genericMessage.knockData != nil) {
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
    if (self.genericMessage.locationData != nil) {
        return self;
    }
    return nil;
}

- (void)updateWithPostPayload:(NSDictionary *)payload updatedKeys:(__unused NSSet *)updatedKeys
{
    // we don't want to update the conversation if the message is a confirmation message
    if (self.genericMessage.hasConfirmation || self.genericMessage.hasReaction)
    {
        return;
    }
    if (self.genericMessage.hasDeleted) {
        NSUUID *originalID = [NSUUID uuidWithTransportString:self.genericMessage.deleted.messageId];
        ZMMessage *original = [ZMMessage fetchMessageWithNonce:originalID forConversation:self.conversation inManagedObjectContext:self.managedObjectContext];
        original.sender = nil;
        original.senderClientID = nil;
    } else if (self.genericMessage.hasEdited) {
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
        [original removeMessageClearingSender:NO];
    } else {
        [super updateWithPostPayload:payload updatedKeys:nil];
    }
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeInsertedUpstream
{
    NSPredicate *encryptedNotSynced = [NSPredicate predicateWithFormat:@"%K == TRUE && %K == FALSE", ZMMessageIsEncryptedKey, DeliveredKey];
    NSPredicate *linkPreviewProcessed = [NSPredicate predicateWithFormat:@"%K == %d", ZMClientMessageLinkPreviewStateKey, ZMLinkPreviewStateUploaded];
    NSPredicate *notSynced = [NSCompoundPredicate orPredicateWithSubpredicates:@[encryptedNotSynced, linkPreviewProcessed]];
    NSPredicate *notExpired = [NSPredicate predicateWithFormat:@"%K == 0", ZMMessageIsExpiredKey];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[notSynced, notExpired]];
}

- (void)markAsSent
{
    [super markAsSent];
    if (self.linkPreviewState == ZMLinkPreviewStateUploaded) {
        self.linkPreviewState = ZMLinkPreviewStateDone;
    }
    [self setObfuscationTimerIfNeeded];
}

- (void)setObfuscationTimerIfNeeded
{
    if (!self.isEphemeral) {
        return;
    }
    if (self.genericMessage.textData != nil && self.genericMessage.linkPreviews.count > 0 &&
        self.linkPreviewState != ZMLinkPreviewStateDone)
    {
        // If we have link previews and they are not sent yet, we wait until they are sent
        return;
    }
    [self startDestructionIfNeeded];
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


@implementation ZMClientMessage (ZMKnockMessage)

@end

#pragma mark - ZMLocationMessageData

@implementation ZMClientMessage (ZMLocationMessageData)

- (float)latitude
{
    return self.genericMessage.locationData.latitude;
}

- (float)longitude
{
    return self.genericMessage.locationData.longitude;
}

- (NSString *)name
{
    return self.genericMessage.locationData.name;
}

- (int32_t)zoomLevel
{
    return self.genericMessage.locationData.zoom ?: 0;
}

@end


@implementation ZMClientMessage (ZMTextMessageData)

- (NSString *)messageText
{
    return self.genericMessage.textData.content;
}

- (BOOL)isEdited
{
    return self.genericMessage.hasEdited;
}

- (LinkPreview *)linkPreview
{
    ZMLinkPreview *linkPreview = self.firstZMLinkPreview;
    
    if (linkPreview.hasTweet) {
        return [[TwitterStatus alloc] initWithProtocolBuffer:linkPreview];
    }
    else if (linkPreview.hasArticle) {
        return [[Article alloc] initWithProtocolBuffer:linkPreview];
    }
    
    return nil;
}

+ (NSSet *)keyPathsForValuesAffectingLinkPreview
{
    return [NSSet setWithObjects:@"dataSet", @"dataSet.data", nil];
}

- (ZMLinkPreview *)firstZMLinkPreview
{
    return self.genericMessage.linkPreviews.firstObject;
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
    else if (nil != self.imageData) {
        return self.nonce.UUIDString;
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
    
    ZMLinkPreview *linkPreview = [self firstZMLinkPreview];
    
    if (nil == linkPreview) {
        return;
    }
    
    [self.managedObjectContext.zm_imageAssetCache storeAssetData:self.nonce format:format encrypted:NO data:imageData];
    ZMImageAssetEncryptionKeys *keys = [self.managedObjectContext.zm_imageAssetCache encryptFileAndComputeSHA256Digest:self.nonce format:format];
    
    ZMAssetImageMetaData *imageMetaData = [ZMAssetImageMetaData imageMetaDataWithWidth:(int32_t)properties.size.width height:(int32_t)properties.size.height];
    ZMAssetOriginal *original = [ZMAssetOriginal originalWithSize:imageData.length mimeType:properties.mimeType name:nil imageMetaData:imageMetaData];
    
    ZMLinkPreview *updatedPreview = [linkPreview updateWithOtrKey:keys.otrKey sha256:keys.sha256 original:original];
    
    if (self.genericMessage.hasText ||
        (self.genericMessage.hasEphemeral && self.genericMessage.ephemeral.hasText))
    {
        [self addData:[ZMGenericMessage messageWithText:self.textMessageData.messageText
                                                   linkPreview:updatedPreview
                                                         nonce:self.nonce.transportString
                                                   expiresAfter:@(self.deletionTimeout)].data];
    } else if (self.genericMessage.hasEdited) {
        [self addData:[ZMGenericMessage messageWithEditMessage:self.genericMessage.edited.replacingMessageId
                                                       newText:self.textMessageData.messageText
                                                   linkPreview:updatedPreview
                                                         nonce:self.nonce.transportString].data];
    }

    [self.managedObjectContext enqueueDelayedSave];
}

- (NSData *)imageDataForFormat:(ZMImageFormat)format;
{
    return [self.managedObjectContext.zm_imageAssetCache assetData:self.nonce format:format encrypted:NO];
}

/// The image formats that this @c ZMImageOwner wants preprocessed. Order of formats determines order in which data is preprocessed
- (NSOrderedSet *)requiredImageFormats;
{
    if (self.genericMessage.linkPreviews.count > 0) {
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




@implementation ZMClientMessage (Ephemeral)

- (BOOL)isEphemeral
{
    return self.destructionDate != nil || self.genericMessage.hasEphemeral || self.isObfuscated;
}

- (NSTimeInterval)deletionTimeout
{
    if (self.isEphemeral) {
        return self.genericMessage.ephemeral.expireAfterMillis/1000;
    }
    return -1;
}

- (void)obfuscate;
{
    [super obfuscate];
    if (self.genericMessage.knockData == nil) {
        ZMGenericMessage *obfuscatedMessage = [self.genericMessage obfuscatedMessage];
        [self deleteContent];
        if (obfuscatedMessage != nil) {
            [self mergeWithExistingData:obfuscatedMessage.data];
            [self setGenericMessage:self.genericMessageFromDataSet];
        }
    }
}

@end



