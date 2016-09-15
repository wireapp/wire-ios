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



@interface ZMAssetClientMessage (ImageAndFileMessageData) <ZMImageMessageData, ZMFileMessageData>

@end



@interface ZMAssetClientMessage()

@property (nonatomic) NSData *assetId_data;
@property (nonatomic) NSData *associatedTaskIdentifier_data;
@property (nonatomic) CGSize preprocessedSize;
@property (nonatomic) NSOrderedSet *dataSet;
@property (nonatomic) ZMGenericMessage *cachedGenericAssetMessage;

@end



@implementation ZMAssetClientMessage

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

+ (instancetype)assetClientMessageWithOriginalImageData:(NSData *)imageData nonce:(NSUUID *)nonce managedObjectContext:(NSManagedObjectContext *)moc;
{
    [moc.zm_imageAssetCache storeAssetData:nonce format:ZMImageFormatOriginal encrypted:NO data:imageData];
    
    ZMAssetClientMessage *message = [ZMAssetClientMessage insertNewObjectInManagedObjectContext:moc];
    
    ZMGenericMessage *mediumData = [ZMGenericMessage messageWithMediumImageProperties:nil processedImageProperties:nil encryptionKeys:nil nonce:nonce.transportString format:ZMImageFormatMedium];
    ZMGenericMessage *previewData = [ZMGenericMessage messageWithMediumImageProperties:nil processedImageProperties:nil encryptionKeys:nil nonce:nonce.transportString format:ZMImageFormatPreview];
    [message addGenericMessage:mediumData];
    [message addGenericMessage:previewData];
    message.preprocessedSize = [ZMImagePreprocessor sizeOfPrerotatedImageWithData:imageData];
    message.uploadState = ZMAssetUploadStateUploadingPlaceholder;
    return message;
}

+ (instancetype)assetClientMessageWithFileMetadata:(ZMFileMetadata *)metadata nonce:(NSUUID *)nonce managedObjectContext:(NSManagedObjectContext *)moc
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
    [message addGenericMessage:[ZMGenericMessage genericMessageWithFileMetadata:metadata messageID:nonce.transportString]];
    message.delivered = NO;
    
    if (metadata.thumbnail != nil) {
        [moc.zm_imageAssetCache storeAssetData:nonce format:ZMImageFormatOriginal encrypted:NO data:metadata.thumbnail];
    }
    
    return message;
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
    if (self.cachedGenericAssetMessage == nil) {
        self.cachedGenericAssetMessage = [self genericMessageMergedFromDataSetWithFilter:^BOOL(ZMGenericMessage *message) {
            return message.hasAsset;
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
    
    if (self.mediumGenericMessage.image.otrKey.length > 0 && self.previewGenericMessage.image.width > 0 && self.deliveryState == ZMDeliveryStatePending) {
        self.uploadState = ZMAssetUploadStateUploadingPlaceholder;
    }
}

- (ZMGenericMessageData *)mergeWithExistingData:(NSData *)data
{
    self.cachedGenericAssetMessage = nil;
    
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
    BOOL isImageMessage = self.mediumGenericMessage.hasImage || self.previewGenericMessage.hasImage;
    return isImageMessage ? self : nil;
}

- (id <ZMFileMessageData>)fileMessageData
{
    BOOL isFileMessage = self.genericAssetMessage.hasAsset;
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
        if (data.genericMessage.hasAsset && data.genericMessage.asset.hasNotUploaded) {
            data.asset = nil;
            [self.managedObjectContext deleteObject:data];
            return;
        }
    }
}


- (BOOL)hasDownloadedImage
{
    if(self.imageMessageData != nil || self.fileMessageData != nil) {
        return [self.managedObjectContext.zm_imageAssetCache assetData:self.nonce format:ZMImageFormatMedium encrypted:NO] != nil // processed or downloaded
        || [self.managedObjectContext.zm_imageAssetCache assetData:self.nonce format:ZMImageFormatOriginal encrypted:NO] != nil; // original
    }
    return false;
}

- (BOOL)hasDownloadedFile
{
    return self.fileMessageData != nil && self.filename != nil &&
        [self.managedObjectContext.zm_fileAssetCache hasDataOnDisk:self.nonce fileName:self.filename encrypted:NO];
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
    
    if (message.asset.preview.hasRemote && !message.asset.hasUploaded) {
        NSDictionary *eventData = [updateEvent.payload dictionaryForKey:@"data"];
        NSString *thumbnailId = [eventData stringForKey:@"id"];
        

        if (nil != thumbnailId) {
            self.fileMessageData.thumbnailAssetID = thumbnailId;
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
        [self.conversation updateWithMessage:self timeStamp:serverTimestamp eventID:self.eventID];
    }
}

- (NSString *)filename
{
    return self.genericAssetMessage.asset.original.name;
}

- (void)requestFileDownload
{
    if (self.fileMessageData != nil) {
        if (self.hasDownloadedFile) {
            self.transferState = ZMFileTransferStateDownloaded;
            return;
        }
        
        self.transferState = ZMFileTransferStateDownloading;
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
            VerifyReturnNil(genericMessage.hasAsset && genericMessage.asset.hasUploaded);
            return genericMessage;
        }
        
        if (dataType == ZMAssetClientMessageDataTypePlaceholder) {
            return [self genericMessageMergedFromDataSetWithFilter:^BOOL(ZMGenericMessage *message) {
                return message.hasAsset && (message.asset.hasOriginal || message.asset.hasNotUploaded);
            }];
        }
        
        if (dataType == ZMAssetClientMessageDataTypeThumbnail) {
            return [self genericMessageMergedFromDataSetWithFilter:^BOOL(ZMGenericMessage *message) {
                return message.hasAsset && message.asset.hasPreview && !message.asset.hasUploaded;
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
        if(dataMessage.hasAsset && dataMessage.asset.hasPreview && !dataMessage.asset.hasUploaded) {
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
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(ZMGenericMessageData *evaluatedObject, NSDictionary *__unused bindings) {
        return evaluatedObject.genericMessage.image.imageFormat == format && evaluatedObject.genericMessage.hasImage;
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
    ZMGenericMessage *filePreviewMessage = [ZMGenericMessage genericMessageWithAsset:asset messageID:self.nonce.transportString];
    
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
            ZMAssetRemoteData *remote = self.genericAssetMessage.asset.preview.remote;
            otrKey = remote.otrKey;
            sha256 = remote.sha256;
        } else if (self.imageMessageData != nil) {
            ZMImageAsset *imageAsset = [self genericMessageForFormat:format].image;
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



#pragma mark - ZMImageMessageData, ZMFileMessageData



@implementation ZMAssetClientMessage (ImageAndFileMessageData)

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
        return imageData;

    }
    return nil;
}

- (NSData *)previewData
{
    if (nil != self.fileMessageData && self.hasDownloadedImage) {
        // File message preview
        NSData *originalData =  [self.managedObjectContext.zm_imageAssetCache assetData:self.nonce
                                                                                 format:ZMImageFormatOriginal
                                                                              encrypted:NO];
        
        NSData *mediumData = [self.managedObjectContext.zm_imageAssetCache assetData:self.nonce
                                                                              format:ZMImageFormatMedium
                                                                           encrypted:NO];
        
        return originalData ?: mediumData;
    }
    else if (self.previewGenericMessage.image.width > 0) {
        // Image message preview
        NSData *imageData = [self imageDataForFormat:ZMImageFormatPreview encrypted:NO];
        return imageData;
    }
    return nil;
}

- (NSString *)thumbnailAssetID {
    if(self.fileMessageData == nil) {
        return nil;
        
    }
    ZMGenericMessage *previewGenericMessage = [self genericMessageForDataType:ZMAssetClientMessageDataTypeThumbnail];
    if(!previewGenericMessage.asset.preview.remote.hasAssetId) {
        return nil;
    }
    NSString *assetID = previewGenericMessage.asset.preview.remote.assetId;
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
    
    
    if(thumbnailMessage.hasAsset) {
        if(thumbnailMessage.asset.hasPreview) {
            if(thumbnailMessage.asset.preview.hasRemote) {
                [remoteBuilder mergeFrom:thumbnailMessage.asset.preview.remote];
            }
            [previewBuilder mergeFrom:thumbnailMessage.asset.preview];
        }
        [assetBuilder mergeFrom:thumbnailMessage.asset];
    }
    [messageBuilder mergeFrom:thumbnailMessage];
    
    [remoteBuilder setAssetId:thumbnailAssetID];
    ZMAssetRemoteData *remoteData = [remoteBuilder build];
    [previewBuilder setRemote:remoteData];
    ZMAssetPreview *assetPreview = [previewBuilder build];
    [assetBuilder setPreview:assetPreview];
    ZMAsset *asset = [assetBuilder build];
    [messageBuilder setAsset:asset];
    
    [self replaceGenericMessageForThumbnailWithGenericMessage:[messageBuilder build]];
}

- (NSString *)imageDataIdentifier;
{
    if(self.mediumGenericMessage.hasImage) {
        return [NSString stringWithFormat:@"%@-w%d-%@", self.nonce.transportString, (int)self.mediumGenericMessage.image.width, @(self.hasDownloadedImage)];
    }
    if(self.previewGenericMessage.hasImage) {
        return [NSString stringWithFormat:@"%@-w%d-%@", self.nonce.transportString, (int)self.previewGenericMessage.image.width, @(self.hasDownloadedImage)];
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
    SInt32 width = self.genericAssetMessage.asset.original.video.width;
    SInt32 height = self.genericAssetMessage.asset.original.video.height;
    return CGSizeMake(width, height);
}

- (NSUInteger)durationMilliseconds
{
    if (self.isVideo) {
        return (NSUInteger) self.genericAssetMessage.asset.original.video.durationInMillis;
    }
    else if (self.isAudio) {
        return (NSUInteger) self.genericAssetMessage.asset.original.audio.durationInMillis;
    }
    else {
        return 0;
    }
}

- (NSArray<NSNumber *> *)normalizedLoudness
{
    if (self.isAudio && self.genericAssetMessage.asset.original.audio.hasNormalizedLoudness) {
        return self.genericAssetMessage.asset.original.normalizedLoudnessLevels;
    }
    
    return @[];
}

@end


#pragma mark - Deletion
@implementation ZMAssetClientMessage (Deletion)

- (void)removeMessageClearingSender:(BOOL)clearingSender {
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
    }

    self.dataSet = [NSOrderedSet orderedSet];
    self.cachedGenericAssetMessage = nil;
    self.assetId = nil;
    self.associatedTaskIdentifier = nil;
    self.preprocessedSize = CGSizeZero;

    [super removeMessageClearingSender:clearingSender];
}

@end
