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



#import "XCTestCase+Images.h"

#if TARGET_OS_IPHONE
@import MobileCoreServices;
#else
@import CoreServices;
#endif

@implementation XCTestCase (Images)

static int16_t imageCounter;

+ (NSData *)verySmallJPEGData;
{
    NSURL *imagesURL = [[NSBundle bundleForClass:[self class]] resourceURL];
    imagesURL = [imagesURL URLByAppendingPathComponent:@"verySmallJPEGs"];
    NSError *error;
    NSArray *imageURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:imagesURL includingPropertiesForKeys:@[NSURLTypeIdentifierKey] options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    imageURLs = [imageURLs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSURL *fileURL, __unused NSDictionary *bindings) {
        NSString *type;
        return ([fileURL getResourceValue:&type forKey:NSURLTypeIdentifierKey error:NULL] &&
                UTTypeConformsTo((__bridge CFStringRef) type, kUTTypeJPEG));
    }]];
    NSAssert(imageURLs.count != (NSUInteger) 0, @"No JPEGs found inside \"%@\"", [imagesURL path]);
    NSUInteger idx = ((NSUInteger) (imageCounter++)) % imageURLs.count;
    NSURL *imageURL = imageURLs[idx];
    return [NSData dataWithContentsOfURL:imageURL];
}

- (NSData *)verySmallJPEGData;
{
    return [[self class] verySmallJPEGData];
}

@end
