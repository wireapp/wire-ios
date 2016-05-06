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


@import ZMTransport;
@import MobileCoreServices;
#import "ZMAssetClientMessage.h"
#import "ZMGenericMessageData.h"
#import <ZMCDataModel/ZMCDataModel-Swift.h>

static NSString * const AssetIdDataKey = @"assetId_data";
static NSString * const AssetIdKey = @"assetId";
NSString * const ZMAssetClientMessage_NeedsToUploadPreviewKey = @"needsToUploadPreview";
NSString * const ZMAssetClientMessage_NeedsToUploadMediumKey = @"needsToUploadMedium";
NSString * const ZMAssetClientMessage_NeedsToUploadNotUploadedKey = @"needsToUploadNotUploaded";
static NSString * const PreprocessedSizeKey = @"preprocessedSize";
static NSString * const PreprocessedSizeDataKey = @"preprocessedSize_data";
static NSString * const AssetClientMessageDataSetKey = @"dataSet";
NSString * const ZMAssetClientMessageTransferStateKey = @"transferState";
NSString * const ZMAssetClientMessageProgressKey = @"progress";
NSString * const ZMAssetClientMessageLoadedMediumDataKey = @"loadedMediumData";
NSString * const ZMAssetClientMessageDidCancelFileDownloadNotificationName = @"ZMAssetClientMessageDidCancelFileDOwnloadNotification";

static NSString * const AssociatedTaskIdentifierDataKey = @"associatedTaskIdentifier_data";


@interface ZMAssetClientMessage (ZMImageAssetStorage) <ZMImageAssetStorage>

- (ZMGenericMessageData *)genericMessageDataFromDataSetForFormat:(ZMImageFormat)format;

@end



@interface ZMAssetClientMessage (ZMImageMessageData) <ZMImageMessageData>

@end



@interface ZMAssetClientMessage() <ZMFileMessageData>

@property (nonatomic) NSData *assetId_data;
@property (nonatomic) NSData *associatedTaskIdentifier_data;
@property (nonatomic) CGSize preprocessedSize;
@property (nonatomic) BOOL loadedMediumData;
@property (nonatomic) NSOrderedSet *dataSet;


@property (nonatomic) BOOL needsToUploadPreview;
@property (nonatomic) BOOL needsToUploadMedium;
@property (nonatomic) BOOL needsToUploadNotUploaded;

@property (nonatomic, readonly) ZMGenericMessage *genericAssetMessage;

@end



@implementation ZMAssetClientMessage

@dynamic needsToUploadPreview;
@dynamic needsToUploadMedium;
@dynamic needsToUploadNotUploaded;
@dynamic assetId_data;
@dynamic delivered;
@dynamic preprocessedSize;
@dynamic loadedMediumData;
@dynamic dataSet;
@dynamic size;
@dynamic transferState;
@dynamic progress;
@dynamic associatedTaskIdentifier_data;

+ (instancetype)assetClientMessageWithOriginalImageData:(NSData *)imageData nonce:(NSUUID *)nonce managedObjectContext:(NSManagedObjectContext *)moc;
{
    [moc.zm_imageAssetCache storeAssetData:nonce format:ZMImageFormatOriginal encrypted:NO data:imageData];
    
    ZMAssetClientMessage *message = [ZMAssetClientMessage insertNewObjectInManagedObjectContext:moc];
    
    ZMGenericMessage *mediumData = [ZMGenericMessage messageWithMediumImageProperties:nil processedImageProperties:nil encryptionKeys:nil nonce:nonce.transportString format:ZMImageFormatMedium];
    ZMGenericMessage *previewData = [ZMGenericMessage messageWithMediumImageProperties:nil processedImageProperties:nil encryptionKeys:nil nonce:nonce.transportString format:ZMImageFormatPreview];
    [message addGenericMessage:mediumData];
    [message addGenericMessage:previewData];
    message.preprocessedSize = [ZMImagePreprocessor sizeOfPrerotatedImageWithData:imageData];
    message.loadedMediumData = YES;
    return message;
}

+ (instancetype)assetClientMessageWithAssetURL:(NSURL *)fileURL
                                          size:(unsigned long long)size
                                      mimeType:(NSString *)mimeType
                                          name:(NSString *)name
                                         nonce:(NSUUID *)nonce
                          managedObjectContext:(NSManagedObjectContext *)moc;
{
    NSError *error;
    NSData *data = [NSData dataWithContentsOfURL:fileURL options:NSDataReadingMappedIfSafe error:&error];
    
    if (nil != error) {
        ZMLogWarn(@"Failed to read data of file at url %@ : %@", fileURL, error);
        return nil;
    }
    
    [moc.zm_fileAssetCache storeAssetData:nonce fileName:name encrypted:NO data:data];
    
    ZMAssetClientMessage *message = [ZMAssetClientMessage insertNewObjectInManagedObjectContext:moc];
    ZMGenericMessage *originalAssetMessage = [ZMGenericMessage genericMessageWithSize:size
                                                                             mimeType:mimeType
                                                                                 name:name
                                                                            messageID:nonce.transportString];
    message.transferState = ZMFileTransferStateUploading;
    [message addGenericMessage:originalAssetMessage];
    message.delivered = NO;
    return message;
}

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    self.nonce = nil;
}

+ (NSString *)entityName;
{
    return @"AssetClientMessage";
}

- (NSSet *)ignoredKeys
{
    NSSet *keys = [super ignoredKeys];
    return [keys setByAddingObjectsFromArray:@[AssetIdDataKey,
                                               PreprocessedSizeDataKey,
                                               ZMAssetClientMessageLoadedMediumDataKey,
                                               AssetClientMessageDataSetKey,
                                               ZMAssetClientMessageTransferStateKey,
                                               ZMAssetClientMessageProgressKey,
                                               AssociatedTaskIdentifierDataKey
                                               ]];
}

- (NSURL *)fileURL {
    if(self.filename) {
        return [self.managedObjectContext.zm_fileAssetCache accessAssetURL:self.nonce fileName:self.filename];
    } else {
        return nil;
    }
}

- (ZMGenericMessage *)genericAssetMessage
{
    return [self genericMessageMergedFromDataSetWithFilter:^BOOL(ZMGenericMessage *message) {
        return message.hasAsset;
    }];
}

- (void)addGenericMessage:(ZMGenericMessage *)genericMessage
{
    if (genericMessage == nil) {
        return;
    }

    ZMGenericMessageData *messageData = [self mergeWithExistingData:genericMessage.data];
    
    if (self.nonce == nil) {
        self.nonce = [NSUUID uuidWithTransportString:messageData.genericMessage.messageId];
    }
    
    if (self.mediumGenericMessage.image.otrKey.length > 0 && self.previewGenericMessage.image.width > 0 && self.deliveryState == ZMDeliveryStatePending) {
        [self setNeedsToUploadData:ZMAssetClientMessageDataTypePlaceholder needsToUpload:YES];
        [self setNeedsToUploadData:ZMAssetClientMessageDataTypeFileData needsToUpload:YES];
    }
}

- (ZMGenericMessageData *)mergeWithExistingData:(NSData *)data
{
    ZMGenericMessage *genericMessage = (ZMGenericMessage *)[[[ZMGenericMessage builder] mergeFromData:data] build];
    ZMImageFormat imageFormat = genericMessage.image.imageFormat;
    ZMGenericMessageData *existingMessageData = [self genericMessageDataFromDataSetForFormat:imageFormat];
    
    if (existingMessageData != nil) {
        existingMessageData.data = data;
        return existingMessageData;
    }
    else {
        return [self createNewGenericMessageData:data];
    }
}

- (ZMGenericMessageData *)createNewGenericMessageData:(NSData *)data
{
    ZMGenericMessageData *messageData = [NSEntityDescription insertNewObjectForEntityForName:[ZMGenericMessageData entityName] inManagedObjectContext:self.managedObjectContext];
    messageData.data = data;
    messageData.asset = self;
    [self.managedObjectContext processPendingChanges];
    return messageData;
}

- (void)setNeedsToUploadData:(ZMAssetClientMessageDataType)dataType needsToUpload:(BOOL)needsToUpload;
{
    NSString *key = nil;
    switch (dataType) {
        case ZMAssetClientMessageDataTypeFileData:
            self.needsToUploadMedium = needsToUpload;
            key = ZMAssetClientMessage_NeedsToUploadMediumKey;
            break;
        case ZMAssetClientMessageDataTypePlaceholder:
            self.needsToUploadPreview = needsToUpload;
            key = ZMAssetClientMessage_NeedsToUploadPreviewKey;
            break;
        default:
            RequireString(false, "Should not set this format for ZMAssetClientMessage");
    }
    
    if (needsToUpload) {
        [self setLocallyModifiedKeys:[NSSet setWithObject:key]];
    }
    else {
        [self resetLocallyModifiedKeys:[NSSet setWithObject:key]];
    }
}

- (NSUUID *)assetId;
{
    return [self transientUUIDForKey:AssetIdKey];
}

- (void)setAssetId:(NSUUID *)assetId;
{
    [self setTransientUUID:assetId forKey:AssetIdKey];
}

+ (NSSet *)keyPathsForValuesAffectingAssetId
{
    return [NSSet setWithObject:AssetIdDataKey];
}

- (ZMTaskIdentifier *)associatedTaskIdentifier
{
    [self willAccessValueForKey:AssociatedTaskIdentifierDataKey];
    NSData *identifierData = [self primitiveValueForKey:AssociatedTaskIdentifierDataKey];
    [self didAccessValueForKey:AssociatedTaskIdentifierDataKey];
    
    return [ZMTaskIdentifier identifierFromData:identifierData];
}

- (void)setAssociatedTaskIdentifier:(ZMTaskIdentifier *)associatedTaskIdentifier
{
    NSData *data =associatedTaskIdentifier.data;
    [self willChangeValueForKey:AssociatedTaskIdentifierDataKey];
    [self setPrimitiveValue:data forKey:AssociatedTaskIdentifierDataKey];
    [self didChangeValueForKey:AssociatedTaskIdentifierDataKey];
}

+ (NSSet *)keyPathsForValuesAffectingAssociatedTaskIdentifier
{
    return [NSSet setWithObject:AssociatedTaskIdentifierDataKey];
}

- (id <ZMImageAssetStorage>)imageAssetStorage
{
    return self;
}

- (id<ZMImageMessageData>)imageMessageData
{
    BOOL isImageMessage = nil != self.mediumGenericMessage || nil != self.previewGenericMessage;
    return isImageMessage ? self : nil;
}

- (id <ZMFileMessageData>)fileMessageData
{
    BOOL isFileMessage = self.filename != nil;
    return isFileMessage ? self : nil;
}

- (void)resend {
    self.needsToUploadPreview = true;
    self.transferState = ZMFileTransferStateUploading;
    self.progress = 0;
    [self removeNotUploaded];
    [super resend];
}

- (void)removeNotUploaded {
    for (ZMGenericMessageData *data in self.dataSet) {
        if (data.genericMessage.hasAsset && data.genericMessage.asset.hasNotUploaded) {
            data.asset = nil;
            [self.managedObjectContext deleteObject:data];
            return;
        }
    }
}

- (void)updateWithGenericMessage:(ZMGenericMessage *)message updateEvent:(ZMUpdateEvent *)updateEvent
{
    [self addGenericMessage:message];
    
    if (self.nonce == nil) {
        self.nonce = [NSUUID uuidWithTransportString:message.messageId];
    }
    
    if (message.hasImage) {
        NSDictionary *eventData = [updateEvent.payload dictionaryForKey:@"data"];
        
        if ([message.image.tag isEqualToString:@"medium"]) {
            self.assetId = [NSUUID uuidWithTransportString:[eventData stringForKey:@"id"]];
        }
        
        NSString *inlinedDataString = [eventData optionalStringForKey:@"data"];
        if (inlinedDataString != nil) {
            NSData *inlinedData = [[NSData alloc] initWithBase64EncodedString:inlinedDataString options:0];
            if (inlinedData != nil) {
                [self updateMessageWithImageData:inlinedData forFormat:ZMImageFormatPreview];
                return;
            }
        }
    }
    
    if (message.asset.hasUploaded) {
        NSDictionary *eventData = [updateEvent.payload dictionaryForKey:@"data"];
        self.assetId = [NSUUID uuidWithTransportString:[eventData stringForKey:@"id"]];
        self.transferState = ZMFileTransferStateUploaded;
    }
    
    if (message.asset.hasNotUploaded) {
        switch(message.asset.notUploaded) {
            case ZMAssetNotUploadedCANCELLED:
                self.transferState = ZMFileTransferStateCancelledUpload;
                break;
            case ZMAssetNotUploadedFAILED:
                self.transferState = ZMFileTransferStateFailedUpload;
                break;
        }
    }
}

- (unsigned long long)size
{
    ZMAsset *asset = self.genericAssetMessage.asset;
    unsigned long long originalSize = asset.original.size;
    unsigned long long previewSize = asset.preview.size;
    
    if (originalSize == 0) {
        return previewSize;
    }
    
    return originalSize;
}

- (NSString *)mimeType
{
    ZMAsset *asset = self.genericAssetMessage.asset;
    if (asset.original.hasMimeType) {
        return asset.original.mimeType;
    }
    
    if (asset.preview.hasMimeType) {
        return asset.original.mimeType;
    }
    
    if (self.previewGenericMessage.image.hasMimeType) {
        return self.previewGenericMessage.image.mimeType;
    }
    
    if (self.mediumGenericMessage.image.hasMimeType) {
        return self.mediumGenericMessage.image.mimeType;
    }
    
    return nil;
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeUpdatedUpstream;
{
    NSPredicate *needsToUpload = [NSPredicate predicateWithFormat:@"%K == YES OR %K == YES", ZMAssetClientMessage_NeedsToUploadMediumKey, ZMAssetClientMessage_NeedsToUploadPreviewKey];
    NSPredicate *notExpired = [NSPredicate predicateWithFormat:@"%K == NO", ZMMessageIsExpiredKey];
    
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[needsToUpload, notExpired]];
}

- (void)updateWithPostPayload:(NSDictionary *)payload updatedKeys:(NSSet *)updatedKeys
{
    if ([updatedKeys contains:ZMAssetClientMessage_NeedsToUploadPreviewKey]) {
        NSDate *serverTimestamp = [payload dateForKey:@"time"];
        if (serverTimestamp != nil) {
            self.serverTimestamp = serverTimestamp;
        }
        [self.conversation updateLastReadServerTimeStampIfNeededWithTimeStamp:serverTimestamp andSync:YES];
        [self.conversation resortMessagesWithUpdatedMessage:self];
        [self.conversation updateWithMessage:self timeStamp:serverTimestamp eventID:self.eventID];
    }
}

- (NSString *)filename
{
    return self.genericAssetMessage.asset.original.name;
}

- (void)requestFullContent
{
    if (self.assetExistsLocally) {
        self.transferState = ZMFileTransferStateDownloaded;
        return;
    }
    
    self.transferState = ZMFileTransferStateDownloading;
}

- (void)cancelTransfer
{
    if (self.transferState != ZMFileTransferStateDownloading && self.transferState != ZMFileTransferStateUploading) {
        ZMLogWarn(@"Trying to cancel transfer from state %d, aborting", self.transferState);
        return;
    }
    
    if (self.transferState == ZMFileTransferStateUploading) {
        [self didCancelUploadingTransfer];
        self.transferState = ZMFileTransferStateCancelledUpload;
        [self expire];
    }
    else if (self.transferState == ZMFileTransferStateDownloading) {
        self.transferState = ZMFileTransferStateUploaded;
        [self obtainPermanentObjectID];
        [NSNotificationCenter.defaultCenter postNotificationName:ZMAssetClientMessageDidCancelFileDownloadNotificationName
                                                          object:self.objectID];
    }
}

- (void)setAndSyncNotUploaded:(ZMAssetNotUploaded)notUploaded
{
    if(self.genericAssetMessage.asset.hasNotUploaded) {
        // already canceled
        return;
    }

    ZMGenericMessage *notUploadedMessage = [ZMGenericMessage genericMessageWithNotUploaded:notUploaded
                                                                                 messageID:self.nonce.transportString];
    [self addGenericMessage:notUploadedMessage];
    self.needsToUploadNotUploaded = YES;
    [self setLocallyModifiedKeys:[NSSet setWithObject:ZMAssetClientMessage_NeedsToUploadNotUploadedKey]];
}

- (void)didCancelUploadingTransfer
{
    [self setAndSyncNotUploaded:ZMAssetNotUploadedCANCELLED];
}

- (void)didFailToUploadFileData
{
    [self setAndSyncNotUploaded:ZMAssetNotUploadedFAILED];
}

- (void)obtainPermanentObjectID
{
    if (self.objectID.isTemporaryID) {
        NSError *error;
        if(![self.managedObjectContext obtainPermanentIDsForObjects:@[self] error:&error]) {
            ZMLogError(@"Can't get permanent object ID for object: %@", error);
        }
    }
}

- (BOOL)assetExistsLocally
{
    NSData *assetData = [self.managedObjectContext.zm_fileAssetCache assetData:self.nonce fileName:self.filename encrypted:NO];
    return nil != assetData;
}

- (NSData *)encryptedMessagePayloadForDataType:(ZMAssetClientMessageDataType)dataType
{
    UserClient *selfClient = [ZMUser selfUserInContext:self.managedObjectContext].selfClient;
    VerifyReturnNil(nil != selfClient.remoteIdentifier);
    
    ZMGenericMessage *genericMessage = [self genericMessageForDataType:dataType];
    VerifyReturnNil(nil != genericMessage);
    
    NSArray <ZMUserEntry *>* recipients = [ZMClientMessage recipientsWithDataToEncrypt:genericMessage.data
                                                                            selfClient:selfClient
                                                                          conversation:self.conversation];
    
    if (dataType == ZMAssetClientMessageDataTypeFileData) {
        ZMOtrAssetMeta *assetMeta = [ZMOtrAssetMeta otrAssetMetaWithSender:selfClient nativePush:YES inline:NO recipients:recipients];
        return assetMeta.data;
    }
    
    if (dataType == ZMAssetClientMessageDataTypePlaceholder) {
        ZMNewOtrMessage *otrMessage = [ZMNewOtrMessage messageWithSender:selfClient nativePush:YES recipients:recipients blob:nil];
        return otrMessage.data;
    }
    
    return nil;
}

- (ZMGenericMessage *)genericMessageForDataType:(ZMAssetClientMessageDataType)dataType
{
    if (dataType == ZMAssetClientMessageDataTypeFileData) {
        ZMGenericMessage *genericMessage = self.genericAssetMessage;
        VerifyReturnNil(genericMessage.hasAsset && genericMessage.asset.hasUploaded);
        return genericMessage;
    }
    
    if (dataType == ZMAssetClientMessageDataTypePlaceholder) {
        return [self genericMessageMergedFromDataSetWithFilter:^BOOL(ZMGenericMessage *message) {
            return message.hasAsset && (message.asset.hasOriginal || message.asset.hasNotUploaded);
        }];
    }
    
    return nil;
}

- (ZMGenericMessage *)genericMessageMergedFromDataSetWithFilter:(BOOL(^)(ZMGenericMessage *))filter
{
    NSArray <ZMGenericMessage *> *filteredMessages = [[self.dataSet.array mapWithBlock:^ZMGenericMessage *(ZMGenericMessageData *data) {
        return data.genericMessage;
    }] filterWithBlock:filter];
    
    if (0 == filteredMessages.count) {
        return nil;
    }
    
    ZMGenericMessageBuilder *builder = ZMGenericMessage.builder;
    for (ZMGenericMessage *message in filteredMessages) {
        [builder mergeFrom:message];
    }
    
    return builder.build;
}

@end


#pragma mark - ZMImageAssetStorage


@implementation ZMAssetClientMessage (ZMImageAssetStorage)

- (CGSize)preprocessedSize {
    return [self transientCGSizeForKey:PreprocessedSizeKey];
}

- (void)setPreprocessedSize:(CGSize)preprocessedSize
{
    [self setTransientCGSize:preprocessedSize forKey:PreprocessedSizeKey];
}

- (ZMGenericMessage *)mediumGenericMessage
{
    return [self genericMessageDataFromDataSetForFormat:ZMImageFormatMedium].genericMessage;
}

- (ZMGenericMessage *)previewGenericMessage
{
    return [self genericMessageDataFromDataSetForFormat:ZMImageFormatPreview].genericMessage;
}

- (BOOL)shouldReprocessForFormat:(ZMImageFormat)format
{
    NSData *originalImageData = [self.managedObjectContext.zm_imageAssetCache assetData:self.nonce format:format encrypted:NO];
    NSData *encryptedImageData = [self.managedObjectContext.zm_imageAssetCache assetData:self.nonce format:format encrypted:YES];
    if (encryptedImageData == nil && originalImageData != nil) {
        return YES;
    }
    return NO;
}

- (ZMGenericMessage *)genericMessageForFormat:(ZMImageFormat)format;
{
    switch(format) {
        case ZMImageFormatMedium:
            return self.mediumGenericMessage;
        case ZMImageFormatPreview:
            return self.previewGenericMessage;
        case ZMImageFormatInvalid:
        case ZMImageFormatOriginal:
        case ZMImageFormatProfile:
            return nil;
    }
}

- (ZMGenericMessageData *)genericMessageDataFromDataSetForFormat:(ZMImageFormat)format
{
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(ZMGenericMessageData *evaluatedObject, NSDictionary *__unused bindings) {
        return evaluatedObject.genericMessage.image.imageFormat == format && evaluatedObject.genericMessage.hasImage;
    }];
    ZMGenericMessageData *messageData = [self.dataSet filteredOrderedSetUsingPredicate:predicate].firstObject;
    return messageData;
}

- (ZMOtrAssetMeta *)encryptedMessagePayloadForImageFormat:(ZMImageFormat)imageFormat
{
    UserClient *selfClient = [ZMUser selfUserInContext:self.managedObjectContext].selfClient;
    if (selfClient.remoteIdentifier == nil) {
        return nil;
    }
    
    ZMOtrAssetMetaBuilder *builder = [ZMOtrAssetMeta builder];
    [builder setIsInline:[self isInlineForFormat:imageFormat]];
    [builder setNativePush:[self isUsingNativePushForFormat:imageFormat]];
    
    [builder setSender:selfClient.clientId];
    
    ZMGenericMessage *genericMessage = [self genericMessageForFormat:imageFormat];
    if(genericMessage == nil) {
        return nil;
    }
    NSArray *recipients = [ZMClientMessage recipientsWithDataToEncrypt:genericMessage.data selfClient:selfClient conversation:self.conversation];
    [builder setRecipientsArray:recipients];
    
    ZMOtrAssetMeta *metaData = [builder build];
    
    return metaData;
}

- (NSData *)originalImageData
{
    return [self.managedObjectContext.zm_imageAssetCache assetData:self.nonce format:ZMImageFormatOriginal encrypted:NO];
}

- (BOOL)isPublicForFormat:(ZMImageFormat)format
{
    NOT_USED(format);
    return NO;
}

- (ZMIImageProperties *)propertiesFromGenericMessage:(ZMGenericMessage *)genericMessage
{
    return [ZMIImageProperties imagePropertiesWithSize:CGSizeMake(genericMessage.image.width, genericMessage.image.height)
                                                length:(unsigned long)genericMessage.image.size
                                              mimeType:genericMessage.image.mimeType];
}

- (ZMImageAssetEncryptionKeys *)keysFromGenericMessage:(ZMGenericMessage *)genericMessage
{
    if(genericMessage.image.hasSha256) {
        return [[ZMImageAssetEncryptionKeys alloc] initWithOtrKey:genericMessage.image.otrKey sha256:genericMessage.image.sha256];
    }
    else {
        return [[ZMImageAssetEncryptionKeys alloc] initWithOtrKey:genericMessage.image.otrKey macKey:genericMessage.image.macKey mac:genericMessage.image.mac];
    }
}

- (void)setImageData:(NSData *)imageData forFormat:(ZMImageFormat)format properties:(ZMIImageProperties *)properties
{
    
    ZMImageMessage *plaintextMessage = [ZMImageMessage fetchMessageWithNonce:self.nonce forConversation:self.conversation inManagedObjectContext:self.managedObjectContext];
    
    if (plaintextMessage != nil) {
        [plaintextMessage setImageData:imageData forFormat:format properties:properties];
    }
    
    ZMImageAssetEncryptionKeys *keys = nil;
    [self.managedObjectContext.zm_imageAssetCache storeAssetData:self.nonce format:format encrypted:NO data:imageData];
    if (self.isEncrypted) {
        keys = [self.managedObjectContext.zm_imageAssetCache encryptFileAndComputeSHA256Digest:self.nonce format:format];
    }
    
    // We need to set the medium size on the preview message
    if(format == ZMImageFormatMedium) {
        ZMGenericMessage *genericMessage = [ZMGenericMessage messageWithMediumImageProperties:properties
                                                                     processedImageProperties:properties
                                                                               encryptionKeys:keys
                                                                                        nonce:self.nonce.transportString
                                                                                       format:ZMImageFormatMedium];
        [self addGenericMessage:genericMessage];
        ZMGenericMessage *previewGenericMessage = [self genericMessageForFormat:ZMImageFormatPreview];
        if(previewGenericMessage.image.size > 0) { // if the preview is there, update it with the medium size
            previewGenericMessage = [ZMGenericMessage messageWithMediumImageProperties:[self propertiesFromGenericMessage:genericMessage]
                                                              processedImageProperties:[self propertiesFromGenericMessage:previewGenericMessage]
                                                                        encryptionKeys:[self keysFromGenericMessage:previewGenericMessage]
                                                                                 nonce:self.nonce.transportString
                                                                                format:ZMImageFormatPreview];
            [self addGenericMessage:previewGenericMessage];
        }
        
    }
    else if(format == ZMImageFormatPreview) {
        ZMGenericMessage *mediumGenericMessage = [self genericMessageForFormat:ZMImageFormatMedium]; // if the medium is there, update the preview with it
        ZMGenericMessage *genericMessage = [ZMGenericMessage messageWithMediumImageProperties:mediumGenericMessage != nil ? [self propertiesFromGenericMessage:mediumGenericMessage] : nil
                                                                     processedImageProperties:properties
                                                                               encryptionKeys:keys
                                                                                        nonce:self.nonce.transportString
                                                                                       format:ZMImageFormatPreview];
        [self addGenericMessage:genericMessage];
    }
    else {
        RequireString(false, "Unexpected format in setImageData:");
    }
    [self.managedObjectContext enqueueDelayedSave];
}

- (NSData *)imageDataForFormat:(ZMImageFormat)format
{
    return [self imageDataForFormat:format encrypted:NO];
}

- (instancetype)updateMessageWithImageData:(NSData *)imageData forFormat:(ZMImageFormat)format
{
    [self.managedObjectContext.zm_imageAssetCache storeAssetData:self.nonce format:format encrypted:self.isEncrypted data:imageData];
    
    if (self.isEncrypted) {
        ZMImageAsset *imageAsset = [self genericMessageForFormat:format].image;
        if (imageAsset.otrKey.length != 0) {
            
            BOOL decrypted = NO;
            if(imageAsset.hasSha256) {
                decrypted = [self.managedObjectContext.zm_imageAssetCache decryptFileIfItMatchesDigest:self.nonce
                                                                                           format:imageAsset.imageFormat
                                                                                    encryptionKey:imageAsset.otrKey
                                                                                     sha256Digest:imageAsset.sha256];
            }
            else if(imageAsset.hasMac) {
                decrypted = [self.managedObjectContext.zm_imageAssetCache decryptAssetIfItMatchesDigest:self.nonce
                                                                                                 format:imageAsset.imageFormat
                                                                                          encryptionKey:imageAsset.otrKey
                                                                                                 macKey:imageAsset.macKey
                                                                                              macDigest:imageAsset.mac];
            }
            if (!decrypted) {
                [self.managedObjectContext deleteObject:self];
                return nil;
            }
            
            //We change flag only after we decrypted data so that we will try to reload data again later
            //(i.e. if we crashed at some point before decryption finishes or we crashed while saving result of decryption)
            //but if encrypted data was stored already we will not make http request, but will use this data rigth away.
            //@see: [ZMClientMessageTranscoder requestForFetchingObject:downstreamSync:]
            if (format == ZMImageFormatMedium) {
                self.loadedMediumData = YES;
            }
        }
    }
    return self;
}

- (CGSize)originalImageSize
{
    ZMGenericMessage *genericMessage = self.mediumGenericMessage ?: self.previewGenericMessage;
    if(genericMessage.image.originalWidth != 0) {
        return CGSizeMake(genericMessage.image.originalWidth, genericMessage.image.originalHeight);
    }
    else {
        return self.preprocessedSize;
    }
}

- (NSOrderedSet *)requiredImageFormats
{
    return [NSOrderedSet orderedSetWithObjects:@(ZMImageFormatMedium), @(ZMImageFormatPreview), nil];
}

- (BOOL)isInlineForFormat:(ZMImageFormat)format
{
    switch(format) {
        case ZMImageFormatPreview:
            return YES;
        case ZMImageFormatInvalid:
        case ZMImageFormatMedium:
        case ZMImageFormatOriginal:
        case ZMImageFormatProfile:
            return NO;
    }
}

- (BOOL)isUsingNativePushForFormat:(ZMImageFormat)format
{
    switch(format) {
        case ZMImageFormatMedium:
            return YES;
        case ZMImageFormatInvalid:
        case ZMImageFormatPreview:
        case ZMImageFormatOriginal:
        case ZMImageFormatProfile:
            return NO;
    }
}

- (void)processingDidFinish
{
    ZMImageMessage *plaintextMessage = [ZMImageMessage fetchMessageWithNonce:self.nonce
                                                             forConversation:self.conversation
                                                      inManagedObjectContext:self.managedObjectContext];
    
    if (plaintextMessage != nil) {
        [plaintextMessage processingDidFinish];
    }
    
    [self.managedObjectContext.zm_imageAssetCache deleteAssetData:self.nonce format:ZMImageFormatOriginal encrypted:NO];
    [self.managedObjectContext enqueueDelayedSave];
}

- (NSData *)imageDataForFormat:(ZMImageFormat)format encrypted:(BOOL)encrypted
{
    if (format != ZMImageFormatOriginal) {
        ZMGenericMessage *genericMessage = (format == ZMImageFormatMedium)? self.mediumGenericMessage : self.previewGenericMessage;
        if (genericMessage.image.size == 0) {
            return nil;
        }
        
        if (encrypted && genericMessage.image.otrKey.length == 0) {
            return nil;
        }
    }
    
    return [self.managedObjectContext.zm_imageAssetCache assetData:self.nonce format:format encrypted:encrypted];
}

- (ZMImageFormat)imageFormat
{
    ZMGenericMessage *genericMessage = self.mediumGenericMessage ?: self.previewGenericMessage;
    if (genericMessage.hasImage) {
        return genericMessage.image.imageFormat;
    }
    return ZMImageFormatInvalid;
}

@end



#pragma mark - ZMImageMessageData



@implementation ZMAssetClientMessage (ZMImageMessageData)

/// Returns original data.
- (NSData *)imageData
{
    NSData *medium = self.mediumData;
    if(medium != nil) {
        return medium;
    }
    NSData *original = [self imageDataForFormat:ZMImageFormatOriginal encrypted:NO];
    return original;
}

- (NSData *)mediumData
{
    if (self.mediumGenericMessage.image.width > 0) {
        NSData *imageData = [self imageDataForFormat:ZMImageFormatMedium encrypted:NO];
        if (imageData == nil && self.loadedMediumData) {
            //if there is no encrypted data or we failed to decrypt it
            //we need to redownload asset
            self.loadedMediumData = NO;
            [self.managedObjectContext saveOrRollback];
        }
        return imageData;

    }
    return nil;
}

- (NSData *)previewData
{
    if (self.previewGenericMessage.image.width > 0) {
        NSData *imageData = [self imageDataForFormat:ZMImageFormatPreview encrypted:NO];
        return imageData;
    }
    return nil;
}

- (NSString *)imageDataIdentifier;
{
    if(self.mediumGenericMessage.hasImage) {
        return [NSString stringWithFormat:@"%@-w%d-%@", self.nonce.transportString, (int)self.mediumGenericMessage.image.width, @(self.loadedMediumData)];
    }
    if(self.previewGenericMessage.hasImage) {
        return [NSString stringWithFormat:@"%@-w%d-%@", self.nonce.transportString, (int)self.previewGenericMessage.image.width, @(self.loadedMediumData)];
    }
    
    NSUUID *assetId = self.assetId;
    if (assetId != nil) {
        return assetId.UUIDString;
    }
    NSData *originalImageData = self.imageData;
    if (originalImageData != nil) {
        return [NSString stringWithFormat:@"orig-%p", originalImageData];
    }
    return nil;
}

- (NSString *)imagePreviewDataIdentifier;
{
    return (self.previewData == nil) ? nil : self.nonce.UUIDString;
}

- (BOOL)isAnimatedGIF
{
    if(self.mediumGenericMessage.image.mimeType == nil) {
        return NO;
    }
    
    CFStringRef MIMEType = (__bridge_retained CFStringRef)[self.mediumGenericMessage.image.mimeType copy];
    NSString *UTIString = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, MIMEType, NULL);
    if(MIMEType != nil)
    {
        CFRelease(MIMEType);
    }
    return [UTIString isEqualToString:(__bridge NSString*)kUTTypeGIF];
}

- (NSString *)imageType
{
    return self.mediumGenericMessage.image.mimeType ?: self.previewGenericMessage.image.mimeType;
}

- (CGSize)originalSize
{
    return [self originalImageSize];
}

@end


#pragma mark - Deletion
@implementation ZMAssetClientMessage (Deletion)

- (void)removeMessage {
    if(self.imageMessageData != nil) {
        [self.managedObjectContext.zm_imageAssetCache deleteAssetData:self.nonce format:ZMImageFormatOriginal encrypted:NO];
        [self.managedObjectContext.zm_imageAssetCache deleteAssetData:self.nonce format:ZMImageFormatPreview encrypted:NO];
        [self.managedObjectContext.zm_imageAssetCache deleteAssetData:self.nonce format:ZMImageFormatMedium encrypted:NO];
        [self.managedObjectContext.zm_imageAssetCache deleteAssetData:self.nonce format:ZMImageFormatPreview encrypted:YES];
        [self.managedObjectContext.zm_imageAssetCache deleteAssetData:self.nonce format:ZMImageFormatMedium encrypted:YES];
    }
    if(self.fileMessageData != nil) {
        [self.managedObjectContext.zm_fileAssetCache deleteAssetData:self.nonce fileName:self.filename encrypted:NO];
        [self.managedObjectContext.zm_fileAssetCache deleteAssetData:self.nonce fileName:self.filename encrypted:YES];
    }
    [super removeMessage];
}

@end