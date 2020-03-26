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


#import "ZMGenericMessage+Utils.h"
#import "ZMGenericMessage+PropertyUtils.h"
#import <WireDataModel/WireDataModel-Swift.h>

@import ImageIO;
@import MobileCoreServices;
@import WireImages;


@interface ZMImageAssetEncryptionKeys()

@property (nonatomic, copy) NSData *otrKey;
@property (nonatomic, copy) NSData *macKey;
@property (nonatomic, copy) NSData *mac;
@property (nonatomic, copy) NSData *sha256;

@end

@implementation ZMImageAssetEncryptionKeys

- (instancetype)initWithOtrKey:(NSData *)otrKey macKey:(NSData *)macKey mac:(NSData *)mac;
{
    self = [super init];
    if (self) {
        self.otrKey = [otrKey copy];
        self.macKey = [macKey copy];
        self.mac = [mac copy];
    }
    return self;
}

- (instancetype)initWithOtrKey:(NSData *)otrKey sha256:(NSData *)sha256;
{
    self = [super init];
    if (self) {
        self.otrKey = [otrKey copy];
        self.sha256 = sha256;
    }
    return self;
}

- (BOOL)hasHMACDigest
{
    return self.mac != nil;
}

- (BOOL)hasSHA256Digest
{
    return self.sha256 != nil;
}

@end


@implementation ZMGenericMessage (Utils)

- (BOOL)knownMessage
{
    return
    self.hasText ||
    self.hasKnock ||
    self.hasImage ||
    self.hasReaction ||
    self.hasLastRead ||
    self.hasCleared ||
    self.hasClientAction ||
    self.hasAsset ||
    self.hasLocation ||
    self.hasDeleted ||
    self.hasHidden ||
    self.hasEdited ||
    self.hasConfirmation ||
    self.hasEphemeral ||
    self.hasCalling ||
    self.hasExternal ||
    self.hasAvailability ||
    self.hasButtonAction ||
    self.hasButtonActionConfirmation ||
    self.hasComposite;
}

@end


@implementation ZMImageAsset (Internal)


+ (instancetype)imageAssetWithMediumProperties:(ZMIImageProperties *)mediumFormatProperties
                           processedProperties:(ZMIImageProperties *)processedProperties
                                encryptionKeys:(ZMImageAssetEncryptionKeys *)encryptionKeys
                                        format:(ZMImageFormat)format;
{
    ZMImageAssetBuilder *builder = [self builder];
    builder.width = (int)processedProperties.size.width;
    builder.height = (int)processedProperties.size.height;
    builder.size = (int)processedProperties.length;
    builder.originalWidth = (int)mediumFormatProperties.size.width;
    builder.originalHeight = (int)mediumFormatProperties.size.height;
    builder.otrKey = encryptionKeys.otrKey;
    builder.sha256 = encryptionKeys.sha256;
    builder.mimeType = processedProperties.mimeType;
    builder.tag = StringFromImageFormat(format);
    ZMImageAsset *processedAsset = [builder build];
    return processedAsset;
}

+ (instancetype)imageAssetWithImageSource:(CGImageSourceRef)imageSource imageData:(NSData *)imageData format:(ZMImageFormat)format
{
    if (![self acceptableSourceType: imageSource]) {
        return nil;
    }

    ZMImageAssetBuilder *builder = [ZMImageAsset builder];
    
    NSString *type = CFBridgingRelease(CGImageSourceGetType(imageSource));
    NSString *mediaType = CFBridgingRelease(UTTypeCopyPreferredTagWithClass((__bridge CFStringRef) type, kUTTagClassMIMEType));
    builder.mimeType = mediaType;
    
    CGSize imageSize = [ZMImagePreprocessor sizeOfPrerotatedImageWithData:imageData];
    builder.originalWidth = (int)imageSize.width;
    builder.originalHeight = (int)imageSize.height;
    builder.width = 0;
    builder.height = 0;
    builder.size = 0;
    builder.tag = StringFromImageFormat(format);
    ZMImageAsset *asset = [builder build];
    return asset;
}

+ (instancetype)imageAssetWithData:(NSData *)imageData format:(ZMImageFormat)format
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef) imageData, NULL);
    ZMImageAsset *asset = [self imageAssetWithImageSource:imageSource imageData:imageData format:format];
    CFBridgingRelease(imageSource);
    return asset;
}


+ (BOOL)acceptableSourceType:(CGImageSourceRef)source
{
    return UTTypeConformsTo(CGImageSourceGetType(source), kUTTypeImage) != 0;
}

- (ZMImageFormat)imageFormat
{
    return ImageFormatFromString(self.tag);
}

@end

