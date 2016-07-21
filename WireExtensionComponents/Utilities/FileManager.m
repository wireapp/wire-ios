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


#import "FileManager.h"
#import "Logging.h"


@implementation FileManager

+ (NSData *)getFileDataFromCache:(NSString *)filePath
{
    NSString *myPath = [self cachesBasePath];

    myPath = [myPath stringByAppendingPathComponent:filePath];
    DDLogDebug(@"get file path %@", myPath);
    NSError *error = nil;
    NSURL *fileURL = [NSURL fileURLWithPath:myPath isDirectory:NO];
    NSData *fData = [NSData dataWithContentsOfURL:fileURL options:0 error:&error];
    if (fData == nil) {
        NSLog(@"getFileData() - unable to read '%@': %@", fileURL.path, error);
    }
    return fData;
}

+ (BOOL)saveFileData:(NSData *)fileData toPathInCache:(NSString *)filePath overwrite:(BOOL)overwriteExistingFile
{
    NSURL *fileURL = [NSURL fileURLWithPath:[self cachesBasePath] isDirectory:YES];
    fileURL = [fileURL URLByAppendingPathComponent:filePath];

    NSError *error = nil;
    NSDataWritingOptions options = overwriteExistingFile ? 0 : NSDataWritingWithoutOverwriting;
    if (! [fileData writeToURL:fileURL options:options error:&error] && overwriteExistingFile) {
        DDLogError(@"saveFileData() - Unable to write file '%@': %@", fileURL.path, error);
        return NO;
    }

    return YES;
}

+ (BOOL)deleteFileAtPathInCache:(NSString *)filePath
{
    NSString *myPath = [self cachesBasePath];
    NSError *err = nil;
    BOOL success = NO;

    myPath = [myPath stringByAppendingPathComponent:filePath];
    DDLogDebug(@"deleting file at file path %@", myPath);
    if ([[NSFileManager defaultManager] fileExistsAtPath:myPath]) {
        NSURL *targetURL = [NSURL fileURLWithPath:myPath];
        [[NSFileManager defaultManager] removeItemAtURL:targetURL error:&err];

        if (! err) {
            success = YES;
        }
        else {
            DDLogError(@"deleteFileAtPathInCache() - ERROR: Error deleting file '%@' - '%@'", myPath, [err localizedDescription]);
            success = NO;
        }
    }

    return success;
}

+ (NSString *)escapeString:(NSString *)string
{
    if (! string) {
        return string;
    }
    NSString *espaped = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return espaped;
}

+ (NSString *)cachesBasePath
{
    NSArray *pathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *path = [pathList objectAtIndex:0];
#if TARGET_OS_MAC && ! TARGET_OS_IPHONE
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    path = [path stringByAppendingPathComponent:bundleID];
#endif
    return path;
}

@end



@implementation FileManager (ProfileImage)

+ (NSString *)createFilePath:(NSString *)string
{
    NSString *filePath = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [NSString stringWithFormat:@"%@.dat", filePath];
}

@end
