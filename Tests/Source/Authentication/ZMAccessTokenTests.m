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



@import OCMock;
@import XCTest;
#import "ZMAccessToken.h"



@interface ZMAccessTokenTests : XCTestCase
@end

@implementation ZMAccessTokenTests

- (void)testThatItStoresTokenAndType
{
    // given
    NSString *token = @"MyVeryUniqueToken23423540899874";
    NSString *type = @"TestTypew930847923874982374";

    // when
    ZMAccessToken *accessToken = [[ZMAccessToken alloc] initWithToken:token type:type expiresInSeconds:0];

    // then
    XCTAssertEqualObjects(accessToken.token, token);
    XCTAssertEqualObjects(accessToken.type, type);
}


- (void)testThatItCalculatesExpirationDate
{
    // given
    NSUInteger expiresIn = 15162342;


    // when
    ZMAccessToken *accessToken = [[ZMAccessToken alloc] initWithToken:nil type:nil expiresInSeconds:expiresIn];


    // then
    NSDate *expiration = [NSDate dateWithTimeIntervalSinceNow:expiresIn];
    XCTAssertEqualWithAccuracy([accessToken.expirationDate timeIntervalSinceReferenceDate],
        [expiration timeIntervalSinceReferenceDate], 0.1);

}

- (void)testThatItReturnsHTTPHeaders
{
    // given
    NSString *token = @"34rfsdfwe3242";
    NSString *type = @"secret-token";
    ZMAccessToken *accessToken = [[ZMAccessToken alloc] initWithToken:token type:type expiresInSeconds:0];
    
    NSDictionary *expected = @{ @"Authorization": [@[type, token] componentsJoinedByString:@" "]};
    
    // when
    NSDictionary *header = accessToken.httpHeaders;
    
    // then
    XCTAssertEqualObjects(expected, header);
}

@end
