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

@import Foundation;
@import WireSystem;
@import WireTesting;

#import "NSData+ZMAdditions.h"
#import <XCTest/XCTest.h>

@interface NSData_ZMAdditionsTests : XCTestCase

@end

@implementation NSData_ZMAdditionsTests

-(void)testThatNSDataDispatchDataEqualsString
{
    // given
    NSString *input = @"hello foobar";
    NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding];
    
    // when
    dispatch_data_t dispatchData = data.dispatchData;
    
    // then
    const void* buffer;
    size_t size;
    dispatch_data_t mappedData = dispatch_data_create_map(dispatchData, &buffer, &size);
    NOT_USED(mappedData);
    
    NSString *output = [[NSString alloc] initWithBytes:buffer length:size encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(input, output);
}

@end
