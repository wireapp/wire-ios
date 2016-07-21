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


#import "CBTestCase.h"

#import "Cryptobox.h"

NSURL *__nullable CBCreateTemporaryDirectoryAndReturnURL(NSString *directorySeed, NSString *name)
{
    NSError *error = nil;
    NSURL *directoryURL = [NSURL fileURLWithPath:[[NSTemporaryDirectory() stringByAppendingPathComponent:directorySeed] stringByAppendingPathComponent:name] isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        return nil;
    }
    
    return directoryURL;
}

@implementation CBTestCase

- (void)setUp;
{
    [super setUp];
    _directorySeed = [[NSProcessInfo processInfo] globallyUniqueString];
}

- (void)tearDown;
{
    _directorySeed = nil;
    [super tearDown];
}

- (nullable CBCryptoBox *)createBoxAndCheckAsserts:(NSString *__nonnull)userName
{
    NSURL *url = CBCreateTemporaryDirectoryAndReturnURL(self.directorySeed, userName);
    NSError *error = nil;
    CBCryptoBox *box = [CBCryptoBox cryptoBoxWithPathURL:url error:&error];
    XCTAssertNil(error, @"");
    XCTAssertNotNil(box, @"Failed to create alice box");
    
    return box;
}


- (NSArray *)generatePreKeysAndCheckAssertsWithRange:(NSRange)range box:(CBCryptoBox *)box
{
    NSError *error = nil;
    NSArray *keys = [box generatePreKeys:range error:&error];
    XCTAssertNotNil(keys);
    XCTAssertTrue(keys.count == range.length);
    return keys;
}

- (CBPreKey *)generatePreKeyAndCheckAssertsWithLocation:(NSUInteger)location box:(CBCryptoBox *)box
{
    NSArray *keys = [self generatePreKeysAndCheckAssertsWithRange:(NSRange){location, 1} box:box];
    XCTAssertTrue(keys.count == 1, @"Wrong amount of keys generated");
    CBPreKey *preKey = keys[0];
    XCTAssertNotNil(preKey);
    return preKey;
}

@end
