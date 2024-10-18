//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

@import CoreGraphics;
@import MobileCoreServices;
@import ImageIO;
@import WireUtilities;
@import WireTransport;

#import "ZMMessage+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "ZMConversation+Internal.h"
#import "WireDataModel/WireDataModel-Swift.h"

#pragma mark - Image message

@interface ZMImageMessage ()

@property (nonatomic) BOOL isAnimatedGIF;
@property (nonatomic) NSString *imageType;

@end


@implementation ZMImageMessage

+ (NSArray *)sortDescriptorsForUpdating;
{
    NSMutableArray *result = [NSMutableArray array];
    for (NSSortDescriptor *conversationSD in ZMConversation.sortDescriptorsForUpdating) {
        NSString *key = [NSString stringWithFormat:@"%@.%@", ZMMessageConversationKey, conversationSD.key];
        [result addObject:[NSSortDescriptor sortDescriptorWithKey:key ascending:conversationSD.ascending]];
    }
    [result addObject:[NSSortDescriptor sortDescriptorWithKey:ZMMessageServerTimestampKey ascending:NO]];
    return result;
}

@dynamic mediumDataLoaded;
@dynamic originalDataProcessed;

@dynamic imageType;
@dynamic isAnimatedGIF;

+ (NSString *)imageTypeForData:(NSData *)data
{
    if(data.length == 0) {
        return nil;
    }
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) data, NULL);
    VerifyReturnNil(source != NULL);
    NSString *type = CFBridgingRelease(CGImageSourceGetType(source));
    CFRelease(source);
    return type;
}

- (NSData *)imageData;
{
    return self.mediumData ?: self.originalImageData;
}

- (NSString *)imagePreviewDataIdentifier;
{
    return (self.previewData == nil) ? nil : self.nonce.UUIDString;
}

- (NSString *)imageDataIdentifier;
{
    NSUUID *identifier = self.mediumRemoteIdentifier;
    if (identifier != nil) {
        return identifier.UUIDString;
    } else if (self.imageData) {
        return [NSString stringWithFormat:@"orig-%@", self.nonce.UUIDString];
    }
    return nil;
}

+ (NSString *)entityName;
{
    return @"ImageMessage";
}

- (NSUUID *)mediumRemoteIdentifier;
{
    return [self transientUUIDForKey:ZMMessageMediumRemoteIdentifierKey];
}

- (void)setMediumRemoteIdentifier:(NSUUID *)mediumRemoteIdentifier;
{
    [self setTransientUUID:mediumRemoteIdentifier forKey:ZMMessageMediumRemoteIdentifierKey];
}

+ (NSSet *)keyPathsForValuesAffectingMediumRemoteIdentifier
{
    return [NSSet setWithObject:ZMMessageMediumRemoteIdentifierDataKey];
}

- (CGSize)originalSize;
{
    return [self transientCGSizeForKey:ZMMessageOriginalSizeKey];
}

- (void)setOriginalSize:(CGSize)originalSize;
{
    [self setTransientCGSize:originalSize forKey:ZMMessageOriginalSizeKey];
}

- (NSData *)mediumData
{
    return [self imageDataForFormat:ZMImageFormatMedium];
}

- (NSData *)previewData
{
    return [self imageDataForFormat:ZMImageFormatPreview];
}

- (id<ZMImageMessageData>)imageMessageData
{
    return self;
}

- (BOOL)isDownloaded
{
    return [self.managedObjectContext.zm_fileAssetCache hasImageDataForMessage:self];
}

- (void)removeMessageClearingSender:(BOOL)clearingSender
{
    [self.managedObjectContext.zm_fileAssetCache deleteAssetData:self];
    self.originalSize = CGSizeZero;
    self.mediumRemoteIdentifier = nil;

    [super removeMessageClearingSender:clearingSender];
}

- (void)fetchImageDataWithQueue:(dispatch_queue_t)queue completionHandler:(void (^)(NSData *))completionHandler {
    NSManagedObjectContext *syncContext =  self.managedObjectContext.zm_syncContext;
    
    [syncContext performGroupedBlock:^{
        ZMImageMessage *imageMessage = [syncContext objectWithID:self.objectID];
        NSData *imageData = imageMessage.imageData;
        
        [syncContext.dispatchGroup asyncOnQueue:queue block:^{
            completionHandler(imageData);
        }];
    }];
}

- (void)requestFileDownload { 
    [self requestFileDownload_Swift];
}

- (void)fetchPreviewDataWithQueue:(dispatch_queue_t)queue completionHandler:(void (^)(NSData *))completionHandler {
    NSManagedObjectContext *syncContext =  self.managedObjectContext.zm_syncContext;
    
    [syncContext performGroupedBlock:^{
        ZMImageMessage *imageMessage = [syncContext objectWithID:self.objectID];
        NSData *imageData = imageMessage.previewData;
        
        [syncContext.dispatchGroup asyncOnQueue:queue block:^{
            completionHandler(imageData);
        }];
    }];
}

@end



@implementation ZMImageMessage (Internal)

@dynamic mediumDataLoaded;
@dynamic originalDataProcessed;


+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent __unused *)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext __unused *)moc
                                      prefetchResult:(ZMFetchRequestBatchResult __unused *)prefetchResult
{
    return nil;
}

- (void)setImageData:(NSData *)imageData forFormat:(ZMImageFormat)format properties:(ZMIImageProperties * __unused)properties;
{
    if (imageData == nil) {
        return;
    }
    else {
        FileAssetCache *cache = self.managedObjectContext.zm_fileAssetCache;

        switch (format) {
            case ZMImageFormatMedium:
                [cache storeMediumImageData:imageData forMessage:self];
                self.mediumDataLoaded = YES;
                self.isAnimatedGIF = [imageData isDataAnimatedGIF];
                self.imageType = [ZMImageMessage imageTypeForData:imageData];
                break;
            case ZMImageFormatPreview:
                [cache storePreviewImageData:imageData forMessage:self];
                break;
            case ZMImageFormatOriginal:
                [cache storeOriginalImageData:imageData forMessage:self];
                self.isAnimatedGIF = [imageData isDataAnimatedGIF];
                break;
            default:
                RequireString(NO, "Invalid image format in ZMMessage: %ld", (long)format);
                break;
        }
    }
}

- (NSData *)imageDataForFormat:(ZMImageFormat)format
{
    switch (format) {
        case ZMImageFormatPreview:
            return [self.managedObjectContext.zm_fileAssetCache previewImageDataFor:self];
        case ZMImageFormatMedium:
            return [self.managedObjectContext.zm_fileAssetCache mediumImageDataFor:self];
        case ZMImageFormatOriginal:
            return [self.managedObjectContext.zm_fileAssetCache originalImageDataFor:self];
        default:
            return nil;
    }
}

- (CGSize)originalImageSize
{
    return self.originalSize;
}

- (NSData *)originalImageData
{
    return [self imageDataForFormat:ZMImageFormatOriginal];
}

- (void)setOriginalImageData:(NSData *)originalImageData
{
    if (originalImageData) {
        [self setImageData:originalImageData forFormat:ZMImageFormatOriginal properties:nil];
    } else {
        [self.managedObjectContext.zm_fileAssetCache deleteOriginalImageDataFor:self];
    }

}

- (void)setMediumData:(NSData *)mediumData
{
    if (mediumData) {
        [self setImageData:mediumData forFormat:ZMImageFormatMedium properties:nil];
    } else {
        [self.managedObjectContext.zm_fileAssetCache deleteMediumImageDataFor:self];
    }

}

- (void)setPreviewData:(NSData *)previewData
{
    if (previewData) {
        [self setImageData:previewData forFormat:ZMImageFormatPreview properties:nil];
    } else {
        [self.managedObjectContext.zm_fileAssetCache deletePreviewImageDataFor:self];
    }
}

- (NSOrderedSet *)requiredImageFormats;
{
    return [NSOrderedSet orderedSetWithObjects:@(ZMImageFormatPreview), @(ZMImageFormatMedium), nil];
}

- (void)processingDidFinish;
{
    [self.managedObjectContext.zm_fileAssetCache deleteOriginalImageDataFor:self];

    self.originalDataProcessed = YES;
    [self.managedObjectContext enqueueDelayedSave];
}

@end
