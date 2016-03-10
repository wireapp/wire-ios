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


@import ZMTesting;
#import "NSData+ZMAdditions.h"


@interface NSDataZMMessageDigestTests : ZMTBaseTest
@end



@implementation NSDataZMMessageDigestTests

- (void)testThatItCalculatesMD5;
{
    NSData *jpegData = [self dataForResource:@"tiny" extension:@"jpg"];
    NSData *expectedData = [NSData dataWithBytes:((uint8_t const []){0x8c, 0xfc, 0x44, 0xc4, 0x2f, 0xc9, 0xf8, 0xc7, 0x2f, 0x41, 0xdc, 0xb2, 0x91, 0x65, 0x98, 0xc7}) length:16];
    AssertEqualData([jpegData MD5Digest], expectedData);
}

- (void)testThatItCalculatesMD5FromEmptyData;
{
    NSData *emptyData = [NSData data];
    NSData *expectedData = [NSData dataWithBytes:((uint8_t const []){0xd4, 0x1d, 0x8c, 0xd9, 0x8f, 0x00, 0xb2, 0x04, 0xe9, 0x80, 0x09, 0x98, 0xec, 0xf8, 0x42, 0x7e}) length:16];
    AssertEqualData([emptyData MD5Digest], expectedData);
}

@end
