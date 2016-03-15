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
#import "zmessaging/zmessaging-Swift.h"
#import "ZMAssetClientMessage.h"
#import "ZMGenericMessageData.h"
#import "ZMOperationLoop.h"

static NSString * const AssetIdDataKey = @"assetId_data";
static NSString * const AssetIdKey = @"assetId";
NSString * const ZMAssetClientMessage_NeedsToUploadPreviewKey = @"needsToUploadPreview";
NSString * const ZMAssetClientMessage_NeedsToUploadMediumKey = @"needsToUploadMedium";
static NSString * const PreprocessedSizeKey = @"preprocessedSize";
static NSString * const PreprocessedSizeDataKey = @"preprocessedSize_data";
static NSString * const LoadedMediumDataKey = @"loadedMediumData";
static NSString * const AssetClientMessageDataSetKey = @"dataSet";




@interface ZMAssetClientMessage()

@property (nonatomic) NSData *assetId_data;
@property (nonatomic) CGSize preprocessedSize;
@property (nonatomic) BOOL loadedMediumData;
@property (nonatomic) NSOrderedSet *dataSet;

@property (nonatomic) BOOL needsToUploadPreview;
@property (nonatomic) BOOL needsToUploadMedium;

- (AssetDirectory *)directory;

@end


@interface ZMAssetClientMessage (ZMImageMessageData) <ZMImageMessageData>

@end



@implementation ZMAssetClientMessage

@dynamic needsToUploadPreview;
@dynamic needsToUploadMedium;
@dynamic assetId_data;
@dynamic delivered;
@dynamic preprocessedSize;
@dynamic loadedMediumData;
@dynamic dataSet;

- (AssetDirectory *)directory {
    return [[AssetDirectory alloc] init];
}

+ (instancetype)assetClientMessageWithOriginalImageData:(NSData *)imageData nonce:(NSUUID *)nonce managedObjectContext:(NSManagedObjectContext *)moc;
{
    AssetDirectory *assetDirectory = [[AssetDirectory alloc] init];
    [assetDirectory storeAssetData:nonce format:ZMImageFormatOriginal encrypted:NO data:imageData];
    
    ZMAssetClientMessage *message = [ZMAssetClientMessage insertNewObjectInManagedObjectContext:moc];
    
    ZMGenericMessage *mediumData = [ZMGenericMessage messageWithMediumImageProperties:nil processedImageProperties:nil encryptionKeys:nil nonce:nonce.transportString format:ZMImageFormatMedium];
    ZMGenericMessage *previewData = [ZMGenericMessage messageWithMediumImageProperties:nil processedImageProperties:nil encryptionKeys:nil nonce:nonce.transportString format:ZMImageFormatPreview];
    [message addGenericMessage:mediumData];
    [message addGenericMessage:previewData];
    message.preprocessedSize = [ZMImagePreprocessor sizeOfPrerotatedImageWithData:imageData];
    message.loadedMediumData = YES;
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
    return [keys setByAddingObjectsFromArray:@[AssetIdDataKey, PreprocessedSizeDataKey, LoadedMediumDataKey, AssetClientMessageDataSetKey]];
}

- (BOOL)shouldReprocessForFormat:(ZMImageFormat)format
{
    NSData *originalImageData = [self.directory assetData:self.nonce format:format encrypted:NO];
    NSData *encryptedImageData = [self.directory assetData:self.nonce format:format encrypted:YES];
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

- (ZMGenericMessage *)mediumGenericMessage
{
    return [self genericMessageDataFromDataSetForFormat:ZMImageFormatMedium].genericMessage;
}

- (ZMGenericMessage *)previewGenericMessage
{
    return [self genericMessageDataFromDataSetForFormat:ZMImageFormatPreview].genericMessage;
}

- (void)addGenericMessage:(ZMGenericMessage *)genericMessage
{
    if (genericMessage == nil) {
        return;
    }

    ZMGenericMessageData *messageData = [self mergeWithExistingData:genericMessage.data] ?: [self createNewGenericMessageData:genericMessage.data];
    ZMGenericMessage *newGenericMessage = messageData.genericMessage;
    
    if (self.nonce == nil) {
        self.nonce = [NSUUID uuidWithTransportString:newGenericMessage.messageId];
    }
    
    if(self.mediumGenericMessage.image.otrKey.length > 0 && self.previewGenericMessage.image.width > 0 && self.deliveryState == ZMDeliveryStatePending) {
        [self setNeedsToUploadFormat:ZMImageFormatPreview needsToUpload:YES];
        [self setNeedsToUploadFormat:ZMImageFormatMedium needsToUpload:YES];
    }
}

- (void)setNeedsToUploadFormat:(ZMImageFormat)format needsToUpload:(BOOL)needsToUpload;
{
    NSString *key = nil;
    switch(format) {
        case ZMImageFormatMedium:
            self.needsToUploadMedium = needsToUpload;
            key = ZMAssetClientMessage_NeedsToUploadMediumKey;
            break;
        case ZMImageFormatPreview:
            self.needsToUploadPreview = needsToUpload;
            key = ZMAssetClientMessage_NeedsToUploadPreviewKey;
            break;
        default:
            RequireString(false, "Should not set this format for ZMAssetClientMessage");
    }
    if(needsToUpload) {
        [self setLocallyModifiedKeys:[NSSet setWithObject:key]];
    }
    else {
        [self resetLocallyModifiedKeys:[NSSet setWithObject:key]];
    }
}


- (ZMGenericMessageData *)mergeWithExistingData:(NSData *)data
{
    ZMGenericMessage *genericMessage = (ZMGenericMessage *)[[[ZMGenericMessage builder] mergeFromData:data] build];
    ZMImageFormat imageFormat = genericMessage.image.imageFormat;
    ZMGenericMessageData *existingMessageData = [self genericMessageDataFromDataSetForFormat:imageFormat];
    
    if (existingMessageData != nil) {
        ZMGenericMessage *existingGenericMessage = existingMessageData.genericMessage;
        BOOL existingMessageIsEmpty = (existingGenericMessage.image.originalWidth == 0 && existingGenericMessage.image.originalHeight == 0);
        if (existingMessageIsEmpty) {
            existingMessageData.data = data;
            return existingMessageData;
        }
    }
    return nil;
}

- (ZMGenericMessageData *)createNewGenericMessageData:(NSData *)data
{
    ZMGenericMessageData *messageData = [NSEntityDescription insertNewObjectForEntityForName:[ZMGenericMessageData entityName] inManagedObjectContext:self.managedObjectContext];
    messageData.data = data;
    messageData.asset = self;
    return messageData;
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

- (id<ZMImageMessageData>)imageMessageData
{
    return self;
}

+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent inManagedObjectContext:(NSManagedObjectContext *)moc prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    return [ZMClientMessage createOrUpdateMessageFromUpdateEvent:updateEvent inManagedObjectContext:moc entityClass:self prefetchResult:prefetchResult];
}

+ (ZMGenericMessage *)genericMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
{
    ZMGenericMessage *message;
    if (updateEvent.type == ZMUpdateEventConversationOtrAssetAdd) {
        NSString *base64Content = [[updateEvent.payload dictionaryForKey:@"data"] stringForKey:@"info"];
        VerifyReturnNil(base64Content != nil);
        @try {
            message = [ZMGenericMessage messageWithBase64String:base64Content];
        }
        @catch(NSException *e) {
            ZMLogError(@"Cannot create message from protobuffer: %@ event: %@", e, updateEvent);
            return nil;
        }
        VerifyReturnNil(message != nil);
    }
    return message;
}

- (instancetype)updateWithGenericMessage:(ZMGenericMessage *)message updateEvent:(ZMUpdateEvent *)updateEvent
{
    [self addGenericMessage:message];
    if (self.nonce == nil) {
        self.nonce = [NSUUID uuidWithTransportString:message.messageId];
    }
    
    NSDictionary *eventData = [updateEvent.payload dictionaryForKey:@"data"];
    
    if ([message.image.tag isEqualToString:@"medium"]) {
        self.assetId = [NSUUID uuidWithTransportString:[eventData stringForKey:@"id"]];
    }
    
    NSString *inlinedDataString = [eventData optionalStringForKey:@"data"];
    if (inlinedDataString != nil) {
        NSData *inlinedData = [[NSData alloc] initWithBase64EncodedString:inlinedDataString options:0];
        if (inlinedData != nil) {
            return [self updateMessageWithImageData:inlinedData forFormat:ZMImageFormatPreview];
        }
    }
    return self;
}

- (instancetype)updateMessageWithImageData:(NSData *)imageData forFormat:(ZMImageFormat)format
{
    [self.directory storeAssetData:self.nonce format:format encrypted:self.isEncrypted data:imageData];
    
    if (self.isEncrypted) {
        ZMImageAsset *imageAsset = [self genericMessageForFormat:format].image;
        if (imageAsset.otrKey.length != 0) {
            
            BOOL decrypted = NO;
            if(imageAsset.hasSha256) {
                decrypted = [AssetEncryption decryptFileIfItMatchesDigest:self.nonce
                                                                   format:imageAsset.imageFormat
                                                            encryptionKey:imageAsset.otrKey
                                                             sha256Digest:imageAsset.sha256
                             
                             ];
            }
            else if(imageAsset.hasMac) {
                decrypted = [AssetEncryption decryptFileIfItMatchesDigest:self.nonce
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

- (CGSize)preprocessedSize {
    return [self transientCGSizeForKey:PreprocessedSizeKey];
}

- (void)setPreprocessedSize:(CGSize)preprocessedSize
{
    [self setTransientCGSize:preprocessedSize forKey:PreprocessedSizeKey];
}

@end




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



@implementation ZMAssetClientMessage (OTR)

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
    NSArray *recipients = [ZMClientMessage recipientsWithDataToEncrypt:genericMessage.data selfClient:selfClient conversation:self.conversation];
    [builder setRecipientsArray:recipients];
    
    ZMOtrAssetMeta *metaData = [builder build];
    
    return metaData;
}

@end



@implementation ZMAssetClientMessage (ImageOwner)

- (NSData *)originalImageData
{
    return [self.directory assetData:self.nonce format:ZMImageFormatOriginal encrypted:NO];
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
    [self.directory storeAssetData:self.nonce format:format encrypted:NO data:imageData];
    if (self.isEncrypted) {
        keys = [AssetEncryption encryptFileAndComputeSHA256Digest:self.nonce format:format];
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
    ZMImageMessage *plaintextMessage = [ZMImageMessage fetchMessageWithNonce:self.nonce forConversation:self.conversation inManagedObjectContext:self.managedObjectContext];
    
    if (plaintextMessage != nil) {
        [plaintextMessage processingDidFinish];
    }
    
    [self.directory deleteAssetData:self.nonce format:ZMImageFormatOriginal encrypted:NO];
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
    
    return [self.directory assetData:self.nonce format:format encrypted:encrypted];
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
