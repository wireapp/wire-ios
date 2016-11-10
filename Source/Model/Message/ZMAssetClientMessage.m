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


@import ZMTransport;
@import MobileCoreServices;
@import ZMUtilities;
@import Cryptobox;
#import "ZMAssetClientMessage.h"
#import "ZMGenericMessageData.h"
#import <ZMCDataModel/ZMCDataModel-Swift.h>

static NSString * const AssetIdDataKey = @"assetId_data";
static NSString * const AssetIdKey = @"assetId";
static NSString * const VersionKey = @"version";
NSString * const ZMAssetClientMessageUploadedStateKey = @"uploadState";
static NSString * const PreprocessedSizeKey = @"preprocessedSize";
static NSString * const PreprocessedSizeDataKey = @"preprocessedSize_data";
static NSString * const AssetClientMessageDataSetKey = @"dataSet";
NSString * const ZMAssetClientMessageTransferStateKey = @"transferState";
NSString * const ZMAssetClientMessageProgressKey = @"progress";
NSString * const ZMAssetClientMessageDownloadedImageKey = @"hasDownloadedImage";
NSString * const ZMAssetClientMessageDownloadedFileKey = @"hasDownloadedFile";
NSString * const ZMAssetClientMessageDidCancelFileDownloadNotificationName = @"ZMAssetClientMessageDidCancelFileDOwnloadNotification";

static NSString * const AssociatedTaskIdentifierDataKey = @"associatedTaskIdentifier_data";


@interface ZMAssetClientMessage (ZMImageAssetStorage) <ZMImageAssetStorage>

- (ZMGenericMessageData *)genericMessageDataFromDataSetForFormat:(ZMImageFormat)format;

@end



@interface ZMAssetClientMessage (ImageAndFileMessageData) <ZMFileMessageData>

@end



@interface ZMAssetClientMessage()

@property (nonatomic) NSData *assetId_data;
@property (nonatomic) NSData *associatedTaskIdentifier_data;
@property (nonatomic) CGSize preprocessedSize;
@property (nonatomic) NSOrderedSet *dataSet;
@property (nonatomic) ZMGenericMessage *cachedGenericAssetMessage;
@property (nonatomic) int16_t version;

@property (nonatomic, readonly) V2Asset *v2Asset;
@property (nonatomic, readonly) V3Asset *v3Asset;

@end

@interface ZMAssetClientMessage (Deletion)

- (void)deleteContent;

@end


@implementation ZMAssetClientMessage

@dynamic version;
@dynamic uploadState;
@dynamic assetId_data;
@dynamic delivered;
@dynamic preprocessedSize;
@dynamic dataSet;
@dynamic size;
@dynamic transferState;
@dynamic progress;
@dynamic associatedTaskIdentifier_data;

@synthesize cachedGenericAssetMessage;


+ (instancetype)assetClientMessageWithOriginalImageData:(NSData *)imageData nonce:(NSUUID *)nonce managedObjectContext:(NSManagedObjectContext *)moc expiresAfter:(NSTimeInterval)timeout;
{
    [moc.zm_imageAssetCache storeAssetData:nonce format:ZMImageFormatOriginal encrypted:NO data:imageData];
    
    ZMAssetClientMessage *message = [ZMAssetClientMessage insertNewObjectInManagedObjectContext:moc];
    
    ZMGenericMessage *mediumData = [ZMGenericMessage genericMessageWithMediumImageProperties:nil processedImageProperties:nil encryptionKeys:nil nonce:nonce.transportString format:ZMImageFormatMedium expiresAfter:@(timeout)];
    
    ZMGenericMessage *previewData = [ZMGenericMessage genericMessageWithMediumImageProperties:nil processedImageProperties:nil encryptionKeys:nil nonce:nonce.transportString format:ZMImageFormatPreview expiresAfter:@(timeout)];
    [message addGenericMessage:mediumData];
    [message addGenericMessage:previewData];
    message.preprocessedSize = [ZMImagePreprocessor sizeOfPrerotatedImageWithData:imageData];
    message.uploadState = ZMAssetUploadStateUploadingPlaceholder;
    return message;
}

+ (instancetype)assetClientMessageWithFileMetadata:(ZMFileMetadata *)metadata nonce:(NSUUID *)nonce managedObjectContext:(NSManagedObjectContext *)moc expiresAfter:(NSTimeInterval)timeout
{
    return [self assetClientMessageWithFileMetadata:metadata nonce:nonce managedObjectContext:moc expiresAfter:timeout version3:NO];
}

+ (instancetype)assetClientMessageWithFileMetadata:(ZMFileMetadata *)metadata nonce:(NSUUID *)nonce managedObjectContext:(NSManagedObjectContext *)moc expiresAfter:(NSTimeInterval)timeout version3:(BOOL)version3
{
    NSError *error;
    NSData *data = [NSData dataWithContentsOfURL:metadata.fileURL options:NSDataReadingMappedIfSafe error:&error];
    
    if (nil != error) {
        ZMLogWarn(@"Failed to read data of file at url %@ : %@", metadata.fileURL, error);
        return nil;
    }
    
    [moc.zm_fileAssetCache storeAssetData:nonce fileName:metadata.fileURL.lastPathComponent encrypted:NO data:data];
    
    
    ZMAssetClientMessage *message = [ZMAssetClientMessage insertNewObjectInManagedObjectContext:moc];
    message.transferState = ZMFileTransferStateUploading;
    message.uploadState = ZMAssetUploadStateUploadingPlaceholder;
    [message addGenericMessage:[ZMGenericMessage genericMessageWithFileMetadata:metadata messageID:nonce.transportString expiresAfter:@(timeout)]];
    message.delivered = NO;

    if (version3) {
        message.version = 3;
    }
    
    if (metadata.thumbnail != nil) {
        [moc.zm_imageAssetCache storeAssetData:nonce format:ZMImageFormatOriginal encrypted:NO data:metadata.thumbnail];
    }
    
    return message;
}

- (id <AssetProxyType>)asset
{
    return self.v2Asset ?: self.v3Asset;
}

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    self.nonce = nil;
}

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    self.cachedGenericAssetMessage = nil;
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
    [super awakeFromSnapshotEvents:flags];
    self.cachedGenericAssetMessage = nil;
}

- (void)didTurnIntoFault
{
    [super didTurnIntoFault];
    self.cachedGenericAssetMessage = nil;
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
                                               ZMAssetClientMessageDownloadedImageKey,
                                               ZMAssetClientMessageDownloadedFileKey,
                                               AssetClientMessageDataSetKey,
                                               ZMAssetClientMessageTransferStateKey,
                                               ZMAssetClientMessageProgressKey,
                                               AssociatedTaskIdentifierDataKey,
                                               VersionKey
                                               ]];
}

- (NSURL *)fileURL
{
    return self.asset.fileURL;
}

- (V2Asset *)v2Asset
{
    return [[V2Asset alloc] initWith:self];
}

- (V3Asset *)v3Asset
{
    return [[V3Asset alloc] initWith:self];
}

- (ZMGenericMessage *)genericAssetMessage
{
    if (self.cachedGenericAssetMessage == nil) {
        self.cachedGenericAssetMessage = [self genericMessageMergedFromDataSetWithFilter:^BOOL(ZMGenericMessage *message) {
            return message.assetData != nil;
        }];
    }
    
    return self.cachedGenericAssetMessage;
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
    
    if (self.mediumGenericMessage.imageAssetData.otrKey.length > 0 && self.previewGenericMessage.imageAssetData.width > 0 && self.deliveryState == ZMDeliveryStatePending) {
        self.uploadState = ZMAssetUploadStateUploadingPlaceholder;
    }
}

- (ZMGenericMessageData *)mergeWithExistingData:(NSData *)data
{
    self.cachedGenericAssetMessage = nil;
    
    ZMGenericMessage *genericMessage = (ZMGenericMessage *)[[[ZMGenericMessage builder] mergeFromData:data] build];
    ZMImageFormat imageFormat = genericMessage.imageAssetData.imageFormat;
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

- (void)setUploadState:(ZMAssetUploadState)state
{
    [self willChangeValueForKey:ZMAssetClientMessageUploadedStateKey];
    [self setPrimitiveValue:@(state) forKey:ZMAssetClientMessageUploadedStateKey];
    [self didChangeValueForKey:ZMAssetClientMessageUploadedStateKey];
    
    if (state != ZMAssetUploadStateDone) {
        [self setLocallyModifiedKeys:[NSSet setWithObject:ZMAssetClientMessageUploadedStateKey]];
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
    return self.asset.imageMessageData;
}

- (id <ZMFileMessageData>)fileMessageData
{
    BOOL isFileMessage = self.genericAssetMessage.assetData != nil;
    return isFileMessage ? self : nil;
}

- (void)resend {
    self.uploadState = ZMAssetUploadStateUploadingPlaceholder;
    self.transferState = ZMFileTransferStateUploading;
    self.progress = 0;
    [self removeNotUploaded];
    [super resend];
}

- (void)removeNotUploaded {
    for (ZMGenericMessageData *data in self.dataSet) {
        if (data.genericMessage.assetData != nil && data.genericMessage.assetData.hasNotUploaded) {
            data.asset = nil;
            [self.managedObjectContext deleteObject:data];
            return;
        }
    }
}

- (BOOL)hasDownloadedImage
{
    return self.asset.hasDownloadedImage;
}

- (BOOL)hasDownloadedFile
{
    return self.asset.hasDownloadedFile;
}

- (void)updateWithGenericMessage:(ZMGenericMessage *)message updateEvent:(ZMUpdateEvent *)updateEvent
{
    [self addGenericMessage:message];
    
    if (self.nonce == nil) {
        self.nonce = [NSUUID uuidWithTransportString:message.messageId];
    }
    
    if (message.imageAssetData != nil) {
        NSDictionary *eventData = [updateEvent.payload dictionaryForKey:@"data"];
        
        if ([message.imageAssetData.tag isEqualToString:@"medium"]) {
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
    
    if (message.assetData.hasUploaded) {
        BOOL isVersion_3 = message.assetData.hasUploaded && message.assetData.uploaded.hasAssetId;
        if (isVersion_3) { // V3, we directly access the protobuf for the assetId
            self.version = 3;
        } else { // V2
            NSDictionary *eventData = [updateEvent.payload dictionaryForKey:@"data"];
            self.assetId = [NSUUID uuidWithTransportString:[eventData stringForKey:@"id"]];
        }

        self.transferState = ZMFileTransferStateUploaded;
    }
    
    if (message.assetData.hasNotUploaded) {
        switch(message.assetData.notUploaded) {
            case ZMAssetNotUploadedCANCELLED:
                self.transferState = ZMFileTransferStateCancelledUpload;
                break;
            case ZMAssetNotUploadedFAILED:
                self.transferState = ZMFileTransferStateFailedUpload;
                break;
        }
    }

    // V2, we do not set the thumbnail assetId in case there is one in the protobuf, then we can access it directly for V3
    if (message.assetData.preview.hasRemote && !message.assetData.hasUploaded) {
        if (! message.assetData.preview.remote.hasAssetId) {
            NSDictionary *eventData = [updateEvent.payload dictionaryForKey:@"data"];
            NSString *thumbnailId = [eventData stringForKey:@"id"];

            if (nil != thumbnailId) {
                self.fileMessageData.thumbnailAssetID = thumbnailId;
            }
        } else {
            self.version = 3;
        }
    }

    if (message.assetData.original.hasImage) {
        self.version = 3;
    }
}

- (unsigned long long)size
{
    ZMAsset *asset = self.genericAssetMessage.assetData;
    unsigned long long originalSize = asset.original.size;
    unsigned long long previewSize = asset.preview.size;
    
    if (originalSize == 0) {
        return previewSize;
    }
    
    return originalSize;
}

- (NSString *)mimeType
{
    ZMAsset *asset = self.genericAssetMessage.assetData;
    if (asset.original.hasMimeType) {
        return asset.original.mimeType;
    }
    
    if (asset.preview.hasMimeType) {
        return asset.original.mimeType;
    }
    
    if (self.previewGenericMessage.imageAssetData.hasMimeType) {
        return self.previewGenericMessage.imageAssetData.mimeType;
    }
    
    if (self.mediumGenericMessage.imageAssetData.hasMimeType) {
        return self.mediumGenericMessage.imageAssetData.mimeType;
    }
    
    return nil;
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeUpdatedUpstream;
{
    return nil;
}

- (void)updateWithPostPayload:(NSDictionary *)payload updatedKeys:(NSSet *)updatedKeys
{
    if ([updatedKeys containsObject:ZMAssetClientMessageUploadedStateKey] && self.uploadState == ZMAssetUploadStateUploadingPlaceholder) {
        
        NSDate *serverTimestamp = [payload dateForKey:@"time"];
        if (serverTimestamp != nil) {
            self.serverTimestamp = serverTimestamp;
        }
        [self.conversation updateLastReadServerTimeStampIfNeededWithTimeStamp:serverTimestamp andSync:NO];
        [self.conversation resortMessagesWithUpdatedMessage:self];
        [self.conversation updateWithMessage:self timeStamp:serverTimestamp];
    }
    
    if ([updatedKeys containsObject:ZMAssetClientMessageUploadedStateKey]) {
        [self startDestructionIfNeeded];
    }
}

- (NSString *)filename
{
    return self.genericAssetMessage.assetData.original.name;
}

- (void)requestFileDownload
{
    [self.asset requestFileDownload];
}

- (void)requestImageDownload
{
    [self.asset requestImageDownload];
}

- (void)setAndSyncNotUploaded:(ZMAssetNotUploaded)notUploaded
{
    if(self.genericAssetMessage.assetData.hasNotUploaded) {
        // already canceled
        return;
    }

    ZMGenericMessage *notUploadedMessage = [ZMGenericMessage genericMessageWithNotUploaded:notUploaded
                                                                                 messageID:self.nonce.transportString
                                                                               expiresAfter:@(self.deletionTimeout)];
    [self addGenericMessage:notUploadedMessage];
    self.uploadState = ZMAssetUploadStateUploadingFailed;
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

- (ZMGenericMessage *)genericMessageForDataType:(ZMAssetClientMessageDataType)dataType
{
    if (nil != self.fileMessageData) {
        if (dataType == ZMAssetClientMessageDataTypeFullAsset) {
            ZMGenericMessage *genericMessage = self.genericAssetMessage;
            VerifyReturnNil(genericMessage.assetData != nil && genericMessage.assetData.hasUploaded);
            return genericMessage;
        }
        
        if (dataType == ZMAssetClientMessageDataTypePlaceholder) {
            return [self genericMessageMergedFromDataSetWithFilter:^BOOL(ZMGenericMessage *message) {
                return message.assetData != nil && (message.assetData.hasOriginal || message.assetData.hasNotUploaded);
            }];
        }
        
        if (dataType == ZMAssetClientMessageDataTypeThumbnail) {
            return [self genericMessageMergedFromDataSetWithFilter:^BOOL(ZMGenericMessage *message) {
                return message.assetData != nil && message.assetData.hasPreview && !message.assetData.hasUploaded;
            }];
        }
    }
    
    if (nil != self.imageMessageData) {
        if (dataType == ZMAssetClientMessageDataTypeFullAsset) {
            return self.mediumGenericMessage;
        }
        
        if (dataType == ZMAssetClientMessageDataTypePlaceholder) {
            return self.previewGenericMessage;
        }
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

- (void)replaceGenericMessageForThumbnailWithGenericMessage:(ZMGenericMessage *)genericMessage
{
    self.cachedGenericAssetMessage = nil;
    
    for(ZMGenericMessageData* data in self.dataSet) {
        ZMGenericMessage *dataMessage = [data genericMessage];
        if(dataMessage.assetData != nil && dataMessage.assetData.hasPreview && !dataMessage.assetData.hasUploaded) {
            data.data = genericMessage.data;
        }
    }
}

//For image messages we have two events - for preview and medium format
//To preserve messages order we need to keep the earliest serverTimestamp of these two events
- (void)updateTimestamp:(NSDate *)timestamp isUpdatingExistingMessage:(BOOL)isUpdate
{
    if (isUpdate) {
        self.serverTimestamp = [NSDate earliestOfDate:self.serverTimestamp and:timestamp];
    } else if (timestamp != nil) {
        self.serverTimestamp = timestamp;
    }
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
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(ZMGenericMessageData *obj, NSDictionary *__unused bindings) {
        return obj.genericMessage.imageAssetData != nil &&
               obj.genericMessage.imageAssetData.imageFormat == format;
    }];
    ZMGenericMessageData *messageData = [self.dataSet filteredOrderedSetUsingPredicate:predicate].firstObject;
    return messageData;
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
    return [ZMIImageProperties imagePropertiesWithSize:CGSizeMake(genericMessage.imageAssetData.width, genericMessage.imageAssetData.height)
                                                length:(unsigned long)genericMessage.imageAssetData.size
                                              mimeType:genericMessage.imageAssetData.mimeType];
}

- (ZMImageAssetEncryptionKeys *)keysFromGenericMessage:(ZMGenericMessage *)genericMessage
{
    if(genericMessage.imageAssetData.hasSha256) {
        return [[ZMImageAssetEncryptionKeys alloc] initWithOtrKey:genericMessage.imageAssetData.otrKey sha256:genericMessage.imageAssetData.sha256];
    }
    else {
        return [[ZMImageAssetEncryptionKeys alloc] initWithOtrKey:genericMessage.imageAssetData.otrKey macKey:genericMessage.imageAssetData.macKey mac:genericMessage.imageAssetData.mac];
    }
}

- (void)setImageData:(NSData *)imageData forFormat:(ZMImageFormat)format properties:(ZMIImageProperties *)properties
{
    [self.managedObjectContext.zm_imageAssetCache storeAssetData:self.nonce format:format encrypted:NO data:imageData];
    ZMImageAssetEncryptionKeys *keys = [self.managedObjectContext.zm_imageAssetCache encryptFileAndComputeSHA256Digest:self.nonce format:format];
    
    if (nil != self.imageMessageData) {
        [self processAddedImageWithFormat:format properties:properties encryptionKeys:keys];
    } else if (nil != self.fileMessageData) {
        [self processAddedFilePreviewWithFormat:format properties:properties encryptionKeys:keys imageData:imageData];
    } else {
        RequireString(false, "Message should represent either an image or a file");
    }
    
    [self.managedObjectContext enqueueDelayedSave];
}

- (void)processAddedImageWithFormat:(ZMImageFormat)format properties:(ZMIImageProperties *)properties encryptionKeys:(ZMImageAssetEncryptionKeys *)keys
{
    // We need to set the medium size on the preview message
    if(format == ZMImageFormatMedium) {
        ZMGenericMessage *genericMessage = [ZMGenericMessage genericMessageWithMediumImageProperties:properties
                                                                            processedImageProperties:properties
                                                                                      encryptionKeys:keys
                                                                                               nonce:self.nonce.transportString
                                                                                              format:ZMImageFormatMedium
                                                                                         expiresAfter:@(self.deletionTimeout)];
        [self addGenericMessage:genericMessage];
        ZMGenericMessage *previewGenericMessage = [self genericMessageForFormat:ZMImageFormatPreview];
        if(previewGenericMessage.imageAssetData.size > 0) { // if the preview is there, update it with the medium size
            previewGenericMessage = [ZMGenericMessage genericMessageWithMediumImageProperties:[self propertiesFromGenericMessage:genericMessage]
                                                                     processedImageProperties:[self propertiesFromGenericMessage:previewGenericMessage]
                                                                               encryptionKeys:[self keysFromGenericMessage:previewGenericMessage]
                                                                                        nonce:self.nonce.transportString
                                                                                       format:ZMImageFormatPreview
                                                                                  expiresAfter:@(self.deletionTimeout)];
            [self addGenericMessage:previewGenericMessage];
            
        }
        
    }
    else if(format == ZMImageFormatPreview) {
        ZMGenericMessage *mediumGenericMessage = [self genericMessageForFormat:ZMImageFormatMedium]; // if the medium is there, update the preview with it
        ZMGenericMessage *genericMessage = [ZMGenericMessage genericMessageWithMediumImageProperties:mediumGenericMessage != nil ? [self propertiesFromGenericMessage:mediumGenericMessage] : nil
                                                                            processedImageProperties:properties
                                                                                      encryptionKeys:keys
                                                                                               nonce:self.nonce.transportString
                                                                                              format:ZMImageFormatPreview
                                                                                         expiresAfter:@(self.deletionTimeout)];
        [self addGenericMessage:genericMessage];
    }
    else {
        RequireString(false, "Unexpected format in setImageData:");
    }
}

- (void)processAddedFilePreviewWithFormat:(ZMImageFormat)format properties:(ZMIImageProperties *)properties encryptionKeys:(__unused ZMImageAssetEncryptionKeys *)keys imageData:(NSData *)data
{
    RequireString(format == ZMImageFormatMedium, "File message preview should only be in format 'medium'");
    
    ZMAssetImageMetaData *imageMetaData = [ZMAssetImageMetaData imageMetaDataWithWidth:(int32_t)properties.size.width height:(int32_t)properties.size.height];
    ZMAssetRemoteData *remoteData = [ZMAssetRemoteData remoteDataWithOTRKey:keys.otrKey sha256:keys.sha256 assetId:nil assetToken:nil];
    ZMAssetPreview *preview = [ZMAssetPreview previewWithSize:data.length mimeType:properties.mimeType remoteData:remoteData imageMetaData:imageMetaData];
    ZMAssetBuilder *builder = ZMAsset.builder;
    [builder setPreview:preview];
    ZMAsset *asset = builder.build;
    ZMGenericMessage *filePreviewMessage = [ZMGenericMessage genericMessageWithAsset:asset messageID:self.nonce.transportString expiresAfter:@(self.deletionTimeout)];
    
    [self addGenericMessage:filePreviewMessage];
}

- (NSData *)imageDataForFormat:(ZMImageFormat)format
{
    return [self imageDataForFormat:format encrypted:NO];
}

- (instancetype)updateMessageWithImageData:(NSData *)imageData forFormat:(ZMImageFormat)format
{
    [self.managedObjectContext.zm_imageAssetCache storeAssetData:self.nonce format:format encrypted:self.isEncrypted data:imageData];
    
    if (self.isEncrypted) {
        NSData *otrKey = nil;
        NSData *sha256 = nil;
        
        if (self.fileMessageData != nil) {
            ZMAssetRemoteData *remote = self.genericAssetMessage.assetData.preview.remote;
            otrKey = remote.otrKey;
            sha256 = remote.sha256;
        } else if (self.imageMessageData != nil) {
            ZMImageAsset *imageAsset = [self genericMessageForFormat:format].imageAssetData;
            otrKey = imageAsset.otrKey;
            sha256 = imageAsset.sha256;
        }
        
        BOOL decrypted = NO;
        if (nil != otrKey && nil != sha256) {
            decrypted = [self.managedObjectContext.zm_imageAssetCache decryptFileIfItMatchesDigest:self.nonce
                                                                                                 format:format
                                                                                          encryptionKey:otrKey
                                                                                           sha256Digest:sha256];
        }
        
        if (!decrypted && self.imageMessageData != nil) {
            [self.managedObjectContext deleteObject:self];
            return nil;
        }
    }
    
    return self;
}

- (CGSize)originalImageSize
{
    return self.imageMessageData.originalSize;
}

- (NSOrderedSet *)requiredImageFormats
{
    if (nil != self.fileMessageData) {
        return [NSOrderedSet orderedSetWithObject:@(ZMImageFormatMedium)];
    } else if (nil != self.imageMessageData) {
        return [NSOrderedSet orderedSetWithObjects:@(ZMImageFormatMedium), @(ZMImageFormatPreview), nil];
    } else {
        return [NSOrderedSet new];
    }
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
    [self.managedObjectContext.zm_imageAssetCache deleteAssetData:self.nonce format:ZMImageFormatOriginal encrypted:NO];
    [self.managedObjectContext enqueueDelayedSave];
}

- (NSData *)imageDataForFormat:(ZMImageFormat)format encrypted:(BOOL)encrypted
{
    return [self.asset imageDataForFormat:format encrypted:encrypted];
}

- (ZMImageFormat)imageFormat
{
    ZMGenericMessage *genericMessage = self.mediumGenericMessage ?: self.previewGenericMessage;
    if (genericMessage.imageAssetData != nil) {
        return genericMessage.imageAssetData.imageFormat;
    }
    return ZMImageFormatInvalid;
}

@end



#pragma mark - ZMFileMessageData



@implementation ZMAssetClientMessage (ImageAndFileMessageData)


- (NSData *)previewData
{
    return self.asset.previewData;
}

- (NSString *)thumbnailAssetID {
    if(self.fileMessageData == nil) {
        return nil;
        
    }

    ZMGenericMessage *previewGenericMessage = [self genericMessageForDataType:ZMAssetClientMessageDataTypeThumbnail];
    if(!previewGenericMessage.assetData.preview.remote.hasAssetId) {
        return nil;
    }
    NSString *assetID = previewGenericMessage.assetData.preview.remote.assetId;
    return assetID.length > 0 ? assetID : nil;
}

- (void)setThumbnailAssetID:(NSString *)thumbnailAssetID {
    
    // This method has to inject this value in the currently existing thumbnail message.
    // Unfortunately it is immutable. So I need to create a copy, modify and then replace.
    if(self.fileMessageData == nil) {
        return;
    }
    
    ZMGenericMessage *thumbnailMessage = [self genericMessageForDataType:ZMAssetClientMessageDataTypeThumbnail];
    if(thumbnailMessage == nil) {
        return;
    }
    
    ZMAssetRemoteDataBuilder *remoteBuilder = [[ZMAssetRemoteDataBuilder alloc] init];
    ZMAssetPreviewBuilder *previewBuilder = [[ZMAssetPreviewBuilder alloc] init];
    ZMAssetBuilder *assetBuilder = [[ZMAssetBuilder alloc] init];
    ZMGenericMessageBuilder *messageBuilder = [[ZMGenericMessageBuilder alloc] init];
    
    
    if(thumbnailMessage.assetData != nil) {
        if(thumbnailMessage.assetData.hasPreview) {
            if(thumbnailMessage.assetData.preview.hasRemote) {
                [remoteBuilder mergeFrom:thumbnailMessage.assetData.preview.remote];
            }
            [previewBuilder mergeFrom:thumbnailMessage.assetData.preview];
        }
        [assetBuilder mergeFrom:thumbnailMessage.assetData];
    }
    [messageBuilder mergeFrom:thumbnailMessage];
    
    [remoteBuilder setAssetId:thumbnailAssetID];
    ZMAssetRemoteData *remoteData = [remoteBuilder build];
    [previewBuilder setRemote:remoteData];
    ZMAssetPreview *assetPreview = [previewBuilder build];
    [assetBuilder setPreview:assetPreview];
    ZMAsset *asset = [assetBuilder build];
    
    if (self.isEphemeral) {
        ZMEphemeral *ephemeral = [ZMEphemeral ephemeralWithPbMessage:asset expiresAfter:@(self.deletionTimeout)];
        [messageBuilder setEphemeral:ephemeral];
    } else {
        [messageBuilder setAsset:asset];
    }
    
    [self replaceGenericMessageForThumbnailWithGenericMessage:[messageBuilder build]];
}

- (NSString *)imagePreviewDataIdentifier;
{
    return self.asset.imagePreviewDataIdentifier;
}

- (void)cancelTransfer
{
    if (self.transferState != ZMFileTransferStateDownloading && self.transferState != ZMFileTransferStateUploading) {
        ZMLogWarn(@"Trying to cancel transfer from state %@, aborting", @(self.transferState));
        return;
    }
    
    if (self.transferState == ZMFileTransferStateUploading) {
        [self didCancelUploadingTransfer];
        self.transferState = ZMFileTransferStateCancelledUpload;
        self.progress = 0.0f;
        [self expire];
    }
    else if (self.transferState == ZMFileTransferStateDownloading) {
        self.transferState = ZMFileTransferStateUploaded;
        self.progress = 0.0f;
        [self obtainPermanentObjectID];
        
        [self.managedObjectContext saveOrRollback];
        [NSNotificationCenter.defaultCenter postNotificationName:ZMAssetClientMessageDidCancelFileDownloadNotificationName
                                                          object:self.objectID];
    }
}

- (BOOL)isVideo
{
    return [self.mimeType isVideoMimeType];
}

- (BOOL)isAudio
{
    return [self.mimeType isAudioMimeType];
}

- (CGSize)videoDimensions
{
    SInt32 width = self.genericAssetMessage.assetData.original.video.width;
    SInt32 height = self.genericAssetMessage.assetData.original.video.height;
    return CGSizeMake(width, height);
}

- (NSUInteger)durationMilliseconds
{
    if (self.isVideo) {
        return (NSUInteger) self.genericAssetMessage.assetData.original.video.durationInMillis;
    }
    else if (self.isAudio) {
        return (NSUInteger) self.genericAssetMessage.assetData.original.audio.durationInMillis;
    }
    else {
        return 0;
    }
}

- (NSArray<NSNumber *> *)normalizedLoudness
{
    if (self.isAudio && self.genericAssetMessage.assetData.original.audio.hasNormalizedLoudness) {
        return self.genericAssetMessage.assetData.original.normalizedLoudnessLevels;
    }
    
    return @[];
}

@end


#pragma mark - Deletion
@implementation ZMAssetClientMessage (Deletion)

- (void)deleteContent
{
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
        
        // Delete thumbnail data
        [self.managedObjectContext.zm_imageAssetCache deleteAssetData:self.nonce format:ZMImageFormatOriginal encrypted:NO];
        [self.managedObjectContext.zm_imageAssetCache deleteAssetData:self.nonce format:ZMImageFormatOriginal encrypted:YES];
        [self.managedObjectContext.zm_imageAssetCache deleteAssetData:self.nonce format:ZMImageFormatMedium encrypted:NO];
        [self.managedObjectContext.zm_imageAssetCache deleteAssetData:self.nonce format:ZMImageFormatMedium encrypted:YES];
    }
    
    self.dataSet = [NSOrderedSet orderedSet];
    self.cachedGenericAssetMessage = nil;
    self.assetId = nil;
    self.associatedTaskIdentifier = nil;
    self.preprocessedSize = CGSizeZero;
}

- (void)removeMessageClearingSender:(BOOL)clearingSender
{    
    [self deleteContent];
    [super removeMessageClearingSender:clearingSender];
}

@end



@implementation ZMAssetClientMessage (Ephemeral)

- (BOOL)isEphemeral
{
    return self.destructionDate != nil || self.ephemeral != nil || self.isObfuscated;
}

- (ZMEphemeral *)ephemeral
{
    NSArray <ZMGenericMessage *> *filteredMessages = [[self.dataSet.array mapWithBlock:^ZMGenericMessage *(ZMGenericMessageData *data) {
        return data.genericMessage;
    }] filterWithBlock:^BOOL(id genericMessage) {
        return [genericMessage hasEphemeral];
    }];
    
    return [filteredMessages.firstObject ephemeral];
}

- (NSTimeInterval)deletionTimeout
{
    if (self.isEphemeral) {
        return self.ephemeral.expireAfterMillis/1000;
    }
    return -1;
}

- (void)obfuscate;
{
    [super obfuscate];
    
    ZMGenericMessage *obfuscatedMessage;
    if (self.mediumGenericMessage != nil) {
        obfuscatedMessage = [self.mediumGenericMessage obfuscatedMessage];
    }
    else if (self.fileMessageData != nil) {
        obfuscatedMessage = [self.genericAssetMessage obfuscatedMessage];
    }
    [self deleteContent];
    
    if (obfuscatedMessage != nil) {
        [self createNewGenericMessageData:obfuscatedMessage.data];
    }
}

- (BOOL)startDestructionIfNeeded
{
    BOOL isSelfUser = self.sender.isSelfUser;

    if (!isSelfUser) {
        if (nil != self.imageMessageData && !self.hasDownloadedImage) {
            return NO;
        } else if (nil != self.fileMessageData) {
            if (!self.genericAssetMessage.assetData.hasUploaded &&
                !self.genericAssetMessage.assetData.hasNotUploaded)
            {
                return NO;
            }
        }
    }
    // This method is called after receiving the response but before updating the
    // uploadState, which means a state of fullAsset corresponds to the asset upload being done.
    if (isSelfUser && self.uploadState != ZMAssetUploadStateUploadingFullAsset) {
        return NO;
    }
    return [super startDestructionIfNeeded];
}

@end
