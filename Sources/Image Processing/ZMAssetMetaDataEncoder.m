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


@import CoreGraphics;
@import ImageIO;
@import WireSystem;

#import "ZMAssetMetaDataEncoder.h"
#import "NSData+ZMAdditions.h"
#import "NSObject+ZMTransportEncoding.h"
#import "ZMImageOwner.h"

#if TARGET_OS_IPHONE
@import MobileCoreServices;
#endif

@implementation ZMAssetMetaDataEncoder


+ ( NSDictionary * __nonnull )contentDispositionForImageOwner:(id<ZMImageOwner> __nonnull)imageOwner format:(ZMImageFormat)format conversationID:(NSUUID * __nonnull)convID correlationID:(NSUUID * __nonnull)correlationID;
{
    Require(imageOwner != nil);
    Require(convID != nil);
    NSData *imageData = [imageOwner imageDataForFormat:format];
    Require(imageData != nil);
    NSString * const MD5String = [[imageData MD5Digest] base64EncodedStringWithOptions:0];
    CGSize const imageSize = [self imageSizeForImageData:imageData];
    Require(MD5String != nil);
    Require(convID.transportString);
    
    NSString *tag = StringFromImageFormat(format);
    Require(tag != nil);
    
    // C.f <https://github.com/wearezeta/cargohold/blob/master/README.md>

    id const correlationIDString = correlationID.transportString ?: [NSNull null];
    
    return @{@"zasset": [NSNull null], //This is used later (somewhere deep down in the system) to specify the "zasset" in "Content-Disposition: zasset;conv_id=709e4e1b-5199-4f78-8f88-b..."
             @"conv_id": convID.transportString,
             @"md5": MD5String,
             @"width": @(imageSize.width),
             @"height": @(imageSize.height),
             @"original_width": @(imageOwner.originalImageSize.width),
             @"original_height": @(imageOwner.originalImageSize.height),
             @"inline": @([imageOwner isInlineForFormat:format]),
             @"public": @([imageOwner isPublicForFormat:format]),
             @"correlation_id": correlationIDString,
             @"tag": tag,
             @"nonce": correlationIDString,
             @"native_push": @([imageOwner isUsingNativePushForFormat:format]),
             };
}



+ ( NSDictionary * __nonnull )createAssetDataWithID:(NSUUID * __nonnull)identifier imageOwner:(id<ZMImageOwner> __nonnull)imageOwner format:(ZMImageFormat)format correlationID:(NSUUID * __nonnull)correlationID
{
    RequireString(identifier != nil, "No image identifier given");
    RequireString(imageOwner != nil, "No imageOwner given");
    RequireString(correlationID != nil, "No image correlation id given");

    NSData *imageData = [imageOwner imageDataForFormat:format];
    CGSize size = [self imageSizeForImageData:imageData];
    NSString *contentType = [self contentTypeForImageData:imageData] ?: @"application/binary";
    
    NSDictionary *assetInfo = [self createAssetInfoWithFormat:format
                                                correlationID:correlationID
                                                         size:size
                                                 originalSize:imageOwner.originalImageSize
                                                     isPublic:[imageOwner isPublicForFormat:format]];
    
    return @{@"content_length": @(imageData.length),
             @"content_type": contentType,
             @"id": identifier.transportString,
             @"info":assetInfo};
}


+ (NSDictionary *)createAssetInfoWithFormat:(ZMImageFormat)format
                              correlationID:(NSUUID *)correlationID
                                       size:(CGSize)size
                               originalSize:(CGSize)originalSize
                                   isPublic:(BOOL)isPublic
{
    return @{
             @"height": @(size.height),
             @"width": @(size.width),
             @"tag": StringFromImageFormat(format),
             @"original_width": @(originalSize.width),
             @"correlation_id": correlationID.transportString,
             @"original_height": @(originalSize.height),
             @"nonce": correlationID.transportString,
             @"public": @(isPublic)
             };
    
}

+ (CGSize)imageSizeForImageData:(NSData *)imageData
{
    NSDictionary *properties;
    if(imageData != nil) {
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef) imageData, NULL);
        properties = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL));
        CFBridgingRelease(imageSource);
    }
    
    NSNumber *boxedWidth = properties[(__bridge id)kCGImagePropertyPixelWidth];
    NSInteger width = boxedWidth ? boxedWidth.integerValue : -1;

    NSNumber *boxedHeight = properties[(__bridge id)kCGImagePropertyPixelHeight];
    NSInteger height = boxedHeight ? boxedHeight.integerValue : -1;

    return CGSizeMake(width, height);
}


+ (NSString *)contentTypeForImageData:(NSData *)imageData
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef) imageData, NULL);

    CFStringRef imageType = CGImageSourceGetType(imageSource);
    NSString *mediaType = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(imageType, kUTTagClassMIMEType));
    
    CFBridgingRelease(imageSource);
    
    return mediaType;
}



@end
