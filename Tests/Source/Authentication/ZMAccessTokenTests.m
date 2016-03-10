
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

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
