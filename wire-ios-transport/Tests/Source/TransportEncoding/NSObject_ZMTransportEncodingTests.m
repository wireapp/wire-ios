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


@import WireTransport;
@import XCTest;

@interface NSObjectZMTransportEncodingTests : XCTestCase
@end

@interface NSObjectZMTransportEncodingTests (NSDate)
@end
@interface NSObjectZMTransportEncodingTests (NSUUID)
@end

@implementation NSObjectZMTransportEncodingTests
@end





@implementation NSObjectZMTransportEncodingTests (NSUUID)

- (void)testThatItCanParseUppercaseUUID
{
    // given
    NSString *string = @"E3F77380-A03E-45BB-A598-D361E3220001";
    NSUUID *expected = [[NSUUID alloc] initWithUUIDString:@"E3F77380-A03E-45BB-A598-D361E3220001"];
    
    // when
    NSUUID *sut = [[NSUUID alloc] initWithTransportString:string];

    // then
    XCTAssertNotNil(sut);
    XCTAssertEqualObjects(sut, expected);
}


- (void)testThatItCanParseLowercaseUUID
{
    // given
    NSString *string = [@"E3F77380-A03E-45BB-A598-D361E3220001" lowercaseString];
    NSUUID *expected = [[NSUUID alloc] initWithUUIDString:@"E3F77380-A03E-45BB-A598-D361E3220001"];
    
    // when
    NSUUID *sut = [[NSUUID alloc] initWithTransportString:string];

    // then
    XCTAssertNotNil(sut);
    XCTAssertEqualObjects(sut, expected);
}


- (void)testThatTheTransportStringIsAlwaysLowercase
{
    // given
    NSString *string = @"E3F77380-A03E-45BB-A598-D361E3220001";
    NSUUID *sut = [[NSUUID alloc] initWithTransportString:string];
    
    // when
    NSString *transportString = [sut transportString];
    
    // then
    NSString *expectedString = [string lowercaseString];
    XCTAssertEqualObjects(expectedString, transportString);
}


@end

