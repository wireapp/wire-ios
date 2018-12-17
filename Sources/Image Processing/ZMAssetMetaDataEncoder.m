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
#import "ZMImageOwner.h"

#if TARGET_OS_IPHONE
@import MobileCoreServices;
#endif

@implementation ZMAssetMetaDataEncoder


+ (NSString *)contentTypeForImageData:(NSData *)imageData
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef) imageData, NULL);

    CFStringRef imageType = CGImageSourceGetType(imageSource);
    NSString *mediaType = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(imageType, kUTTagClassMIMEType));
    
    CFBridgingRelease(imageSource);
    
    return mediaType;
}

@end
