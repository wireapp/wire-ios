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


@import ZMTesting;
#import "NSData+ZMAdditions.h"


@interface NSDataZMMessageDigestTests : ZMTBaseTest
@end



@implementation NSDataZMMessageDigestTests

- (void)testThatItCalculatesMD5;
{
    // given
    NSData *jpegData = [self dataForResource:@"unsplash_medium" extension:@"jpg"];
    uint8_t bytes[] = {0x70, 0x9a, 0x50, 0xd6, 0x1f, 0x23, 0x36, 0x02, 0xbd, 0x97, 0x00, 0x40, 0x6a, 0x34, 0x35, 0x00};
    NSData *expectedData = [NSData dataWithBytes:bytes length:16];

    // when
    NSData *md5 = jpegData.MD5Digest;
    
    // then
    AssertEqualData(md5, expectedData);
}

- (void)testThatItCalculatesMD5FromEmptyData;
{
    // given
    NSData *emptyData = [NSData data];
    uint8_t bytes[] = {0xd4, 0x1d, 0x8c, 0xd9, 0x8f, 0x00, 0xb2, 0x04, 0xe9, 0x80, 0x09, 0x98, 0xec, 0xf8, 0x42, 0x7e};
    NSData *expectedData = [NSData dataWithBytes:bytes length:16];
    
    // when
    NSData *md5 = emptyData.MD5Digest;
    
    // then
    AssertEqualData(md5, expectedData);
}

@end
