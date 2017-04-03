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


@import WireSystem;

#import "NSData+ZMAdditions.h"
#import <zlib.h>
#import <CommonCrypto/CommonCrypto.h>


@implementation NSData (ZMMessageDigest)

- (NSData *)MD5Digest;
{
    __block CC_MD5_CTX ctx;
    CC_MD5_Init(&ctx);
    [self enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, __unused BOOL *stop) {
        CC_MD5_Update(&ctx, bytes, (CC_LONG) byteRange.length);
    }];
    NSMutableData *result = [NSMutableData dataWithLength:CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(result.mutableBytes, &ctx);
    return result;
}

@end
