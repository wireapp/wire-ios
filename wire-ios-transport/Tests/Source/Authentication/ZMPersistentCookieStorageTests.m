//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

@import XCTest;
@import WireTesting;
@import WireTransport;
@import WireTransport.Testing;

#import "ZMPersistentCookieStorage.h"


@interface PersistentCookieStorageTests : XCTestCase

@property (nonatomic, readonly) NSUUID *userIdentifier;
@property (nonatomic) PersistentCookieStorage *sut;

@end

@interface PersistentCookieStorageTests (HTTPCookie)
@end

@implementation PersistentCookieStorageTests

- (BOOL)shouldUseRealKeychain;
{
    return (TARGET_IPHONE_SIMULATOR) || !(TARGET_OS_IPHONE);
}

- (void)setUp
{
    [super setUp];
    [PersistentCookieStorage deleteAllKeychainItems];
    _userIdentifier = NSUUID.createUUID;
    self.sut = [PersistentCookieStorage storageForUserIdentifier:self.userIdentifier useCache:YES];
}

- (void)tearDown
{
    _userIdentifier = nil;
    [super tearDown];
    [self.sut deleteKeychainItems];
    self.sut = nil;
}

- (void)testThatItDoesNotHaveACookie;
{
    XCTAssertNil(self.sut.authenticationCookieData);
}

- (void)testThatItStoresTheCookie;
{
    XCTAssertNil(self.sut.authenticationCookieData);
    NSData *data = [NSData dataWithBytes:(char []){'a'} length:1];
    [self.sut setAuthenticationCookieData:data];
    XCTAssertNotNil(self.sut.authenticationCookieData);
    XCTAssertEqualObjects(self.sut.authenticationCookieData, data);
}

- (void)testThatItUpdatesTheCookie;
{
    XCTAssertNil(self.sut.authenticationCookieData);

    NSData *data1 = [NSData dataWithBytes:(char []){'a'} length:1];
    [self.sut setAuthenticationCookieData:data1];
    XCTAssertEqualObjects(self.sut.authenticationCookieData, data1);
    
    NSData *data2 = [NSData dataWithBytes:(char []){'B'} length:1];
    [self.sut setAuthenticationCookieData:data2];
    XCTAssertEqualObjects(self.sut.authenticationCookieData, data2);
}

- (void)testThatItCanDeleteCookies;
{
    XCTAssertNil(self.sut.authenticationCookieData);
    
    NSData *data = [NSData dataWithBytes:(char []){'a'} length:1];
    [self.sut setAuthenticationCookieData:data];
    XCTAssertNotNil(self.sut.authenticationCookieData);
    [self.sut setAuthenticationCookieData:nil];
    XCTAssertNil(self.sut.authenticationCookieData);
}

- (void)testThatItPersistsCookies;
{
    NSData *data = [NSData dataWithBytes:(char []){'a'} length:1];
    @autoreleasepool {
    PersistentCookieStorage *sut1 = self.sut;
        [sut1 setAuthenticationCookieData:data];
    }
    {
        PersistentCookieStorage *sut2 = self.sut;
        XCTAssertEqualObjects([sut2 authenticationCookieData], data);
    }
}

- (void)testThatItCachesCookies;
{
    // given
    NSData *data = [NSData dataWithBytes:(char []){'a'} length:1];
    PersistentCookieStorage *sut1 = [PersistentCookieStorage storageForUserIdentifier:self.userIdentifier useCache:YES];
    XCTAssertTrue([sut1 isCacheEmpty]);

    // when
    [sut1 setAuthenticationCookieData:data];

    // then
    XCTAssertFalse([sut1 isCacheEmpty]);
}

- (void)testThatItDoesNotCacheCookies;
{
    // given
    NSData *data = [NSData dataWithBytes:(char []){'a'} length:1];
    PersistentCookieStorage *sut1 = [PersistentCookieStorage storageForUserIdentifier:self.userIdentifier useCache:NO];
    XCTAssertTrue([sut1 isCacheEmpty]);

    // when
    [sut1 setAuthenticationCookieData:data];

    // then
    XCTAssertTrue([sut1 isCacheEmpty]);
}

- (void)testThatItCanDeleteCookiesForASpecificCookieStorage
{
    // given
    NSUUID *otherUserIdentifier = NSUUID.createUUID;
    PersistentCookieStorage *sut1 = [PersistentCookieStorage storageForUserIdentifier:self.userIdentifier useCache:YES];
    PersistentCookieStorage *sut2 = [PersistentCookieStorage storageForUserIdentifier:otherUserIdentifier  useCache:YES];

    NSData *data1 = [@"This is the first cookie data" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *data2 = [@"This is the second cookie data" dataUsingEncoding:NSUTF8StringEncoding];
    [sut1 setAuthenticationCookieData:data1];
    XCTAssertNotNil(sut1.authenticationCookieData);
    [sut2 setAuthenticationCookieData:data2];
    XCTAssertNotNil(sut2.authenticationCookieData);

    // when
    [sut1 deleteKeychainItems];

    // then
    XCTAssertNil(sut1.authenticationCookieData);
    XCTAssertEqualObjects(sut2.authenticationCookieData, data2);

    // when
    [sut2 deleteKeychainItems];
    XCTAssertNil(sut1.authenticationCookieData);
    XCTAssertNil(sut2.authenticationCookieData);
}

- (void)testThatItCanDeleteAllCookies
{
    // given
    NSUUID *otherUserIdentifier = NSUUID.createUUID;
    PersistentCookieStorage *sut1 = [PersistentCookieStorage storageForUserIdentifier:self.userIdentifier useCache:YES];
    PersistentCookieStorage *sut2 = [PersistentCookieStorage storageForUserIdentifier:otherUserIdentifier useCache:YES];

    NSData *data1 = [@"This is the first cookie data" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *data2 = [@"This is the second cookie data" dataUsingEncoding:NSUTF8StringEncoding];
    [sut1 setAuthenticationCookieData:data1];
    XCTAssertNotNil(sut1.authenticationCookieData);
    [sut2 setAuthenticationCookieData:data2];
    XCTAssertNotNil(sut2.authenticationCookieData);
    
    // when
    [sut1 deleteKeychainItems];
    [sut2 deleteKeychainItems];
    
    // then
    XCTAssertNil(sut1.authenticationCookieData);
    XCTAssertNil(sut2.authenticationCookieData);
}

- (void)testThatItHasAccessibleAuthenticationCookieData_WhenAuthenticationCookieDataIsAvailable
{
    // given
    PersistentCookieStorage *sut = [PersistentCookieStorage storageForUserIdentifier:self.userIdentifier useCache:YES];
    [sut setAuthenticationCookieData:[@"This is a cookie" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // then
    XCTAssertTrue([PersistentCookieStorage hasAccessibleAuthenticationCookieData]);
}

- (void)testThatItDoesNotHaveAccessibleAuthenticationCookieData_WhenAuthenticationCookieDataIsNotAvailable
{
    XCTAssertFalse([PersistentCookieStorage hasAccessibleAuthenticationCookieData]);
}

@end



@implementation PersistentCookieStorageTests (HTTPCookie)

- (void)testThatWeCanRetrieveTheCookie;
{
    // given
    XCTAssertNil(self.sut.authenticationCookieData);
    
    NSDictionary *headerFields = @{@"Date": @"Thu, 24 Jul 2014 09:06:45 GMT",
                                   @"Content-Encoding": @"gzip",
                                   @"Server": @"nginx",
                                   @"Content-Type": @"application/json",
                                   @"Access-Control-Allow-Origin": @"file://",
                                   @"Connection": @"keep-alive",
                                   @"Set-Cookie": @"zuid=wjCWn1Y1pBgYrFCwuU7WK2eHpAVY8Ocu-rUAWIpSzOcvDVmYVc9Xd6Ovyy-PktFkamLushbfKgBlIWJh6ZtbAA==.1721442805.u.7eaaa023.08326f5e-3c0f-4247-a235-2b4d93f921a4; Expires=Sun, 21-Jul-2024 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure",
                                   @"Content-Length": @"214"};
    NSURL *URL = [NSURL URLWithString:@"https://zeta.example.com/login"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headerFields];
    [self.sut setCookieDataFromResponse:response forURL:URL];
    XCTAssertNotNil(self.sut.authenticationCookieData);
    
    // when
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:URL];
    [self.sut setRequestHeaderFieldsOnRequest:request];
    
    // then
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Cookie"],
                          @"zuid=wjCWn1Y1pBgYrFCwuU7WK2eHpAVY8Ocu-rUAWIpSzOcvDVmYVc9Xd6Ovyy-PktFkamLushbfKgBlIWJh6ZtbAA==.1721442805.u.7eaaa023.08326f5e-3c0f-4247-a235-2b4d93f921a4");
}
    
- (void)testThatWeRetrieveCookieExpirationDate
{
    // given
    XCTAssertNil(self.sut.authenticationCookieData);
    
    NSDictionary *headerFields = @{@"Date": @"Thu, 24 Jul 2014 09:06:45 GMT",
                                   @"Content-Encoding": @"gzip",
                                   @"Server": @"nginx",
                                   @"Content-Type": @"application/json",
                                   @"Access-Control-Allow-Origin": @"file://",
                                   @"Connection": @"keep-alive",
                                   @"Set-Cookie": @"zuid=wjCWn1Y1pBgYrFCwuU7WK2eHpAVY8Ocu-rUAWIpSzOcvDVmYVc9Xd6Ovyy-PktFkamLushbfKgBlIWJh6ZtbAA==.1721442805.u.7eaaa023.08326f5e-3c0f-4247-a235-2b4d93f921a4; Expires=Sun, 21-Jul-2024 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure",
                                   @"Content-Length": @"214"};
    NSURL *URL = [NSURL URLWithString:@"https://zeta.example.com/login"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headerFields];
    [self.sut setCookieDataFromResponse:response forURL:URL];
    XCTAssertNotNil(self.sut.authenticationCookieData);
    
    // when
    NSISO8601DateFormatter *dateFormatter = [[NSISO8601DateFormatter alloc] init];
    XCTAssertEqualObjects([dateFormatter stringFromDate:self.sut.authenticationCookieExpirationDate], @"2024-07-21T09:06:45Z");
}

- (void)testThatItDoesNotSetACookieDataIfNewCookieIsInvalid;
{
    // given
    XCTAssertNil(self.sut.authenticationCookieData);
    self.sut.authenticationCookieData = [@"previous-cookie" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *headerFields = @{@"Date": @"Thu, 24 Jul 2014 09:06:45 GMT",
                                   @"Content-Encoding": @"gzip",
                                   @"Server": @"nginx",
                                   @"Content-Type": @"application/json",
                                   @"Access-Control-Allow-Origin": @"file://",
                                   @"Connection": @"keep-alive",
                                   @"Set-Cookie": @"UTTER GARBAGE",
                                   @"Content-Length": @"214"};
    NSURL *URL = [NSURL URLWithString:@"https://zeta.example.com/login"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headerFields];
    
    // when
    [self.sut setCookieDataFromResponse:response forURL:URL];
    
    // then
    XCTAssertNotNil(self.sut.authenticationCookieData);
}

- (void)testThatItDoesNotStoreNotAuthCookies
{
    // given
    XCTAssertNil(self.sut.authenticationCookieData);
    
    NSDictionary *headerFields = @{@"Date": @"Thu, 24 Jul 2014 09:06:45 GMT",
                                   @"Content-Encoding": @"gzip",
                                   @"Server": @"nginx",
                                   @"Content-Type": @"application/json",
                                   @"Access-Control-Allow-Origin": @"file://",
                                   @"Connection": @"keep-alive",
                                   @"Set-Cookie": @"zuid.challenge=wjCWn1Y1pBgYrFCwuU7WK2eHpAVY8Ocu-rUAWIpSzOcvDVmYVc9Xd6Ovyy-PktFkamLushbfKgBlIWJh6ZtbAA==.1721442805.u.7eaaa023.08326f5e-3c0f-4247-a235-2b4d93f921a4; Expires=Sun, 21-Jul-2024 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure",
                                   @"Content-Length": @"214"};
    NSURL *URL = [NSURL URLWithString:@"https://zeta.example.com/login"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headerFields];

    // when
    [self.sut setCookieDataFromResponse:response forURL:URL];

    // then
    XCTAssertNil(self.sut.authenticationCookieData);
}

- (void)testThatItStoresAuthCookies
{
    // given
    XCTAssertNil(self.sut.authenticationCookieData);
    
    NSDictionary *headerFields = @{@"Date": @"Thu, 24 Jul 2014 09:06:45 GMT",
                                   @"Content-Encoding": @"gzip",
                                   @"Server": @"nginx",
                                   @"Content-Type": @"application/json",
                                   @"Access-Control-Allow-Origin": @"file://",
                                   @"Connection": @"keep-alive",
                                   @"Set-Cookie": @"zuid=wjCWn1Y1pBgYrFCwuU7WK2eHpAVY8Ocu-rUAWIpSzOcvDVmYVc9Xd6Ovyy-PktFkamLushbfKgBlIWJh6ZtbAA==.1721442805.u.7eaaa023.08326f5e-3c0f-4247-a235-2b4d93f921a4; Expires=Sun, 21-Jul-2024 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure",
                                   @"Content-Length": @"214"};
    NSURL *URL = [NSURL URLWithString:@"https://zeta.example.com/login"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headerFields];
    
    // when
    [self.sut setCookieDataFromResponse:response forURL:URL];
    
    // then
    XCTAssertNotNil(self.sut.authenticationCookieData);
}

@end

@interface PersistentCookieStorageTests (RefactorSafety)
@end

@implementation PersistentCookieStorageTests (RefactorSafety)

- (void)testThatExpirationDateIsNilWhenNoCookieIsStored
{
    XCTAssertNil(self.sut.authenticationCookieExpirationDate);
}

- (void)testThatHasAuthenticationCookieIsTrueWhenCookieIsStored
{
    // given
    NSDictionary *headerFields = @{@"Set-Cookie": @"zuid=abc123; Expires=Sun, 21-Jul-2030 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure"};
    NSURL *URL = [NSURL URLWithString:@"https://example.com/login"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headerFields];
    [self.sut setCookieDataFromResponse:response forURL:URL];

    // then
    XCTAssertTrue(self.sut.hasAuthenticationCookie);
}

- (void)testThatHasAuthenticationCookieIsFalseWhenNoCookieIsStored
{
    XCTAssertFalse(self.sut.hasAuthenticationCookie);
}

- (void)testThatSetRequestHeaderFieldsDoesNothingWhenNoCookieIsStored
{
    // given
    NSURL *URL = [NSURL URLWithString:@"https://example.com/api"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:URL];

    // when
    [self.sut setRequestHeaderFieldsOnRequest:request];

    // then
    XCTAssertNil([request valueForHTTPHeaderField:@"Cookie"]);
}

- (void)testThatSetCookieDataFromResponseDoesNothingWhenNoCookieHeader
{
    // given
    NSDictionary *headerFields = @{@"Content-Type": @"application/json"};
    NSURL *URL = [NSURL URLWithString:@"https://example.com/login"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headerFields];

    // when
    [self.sut setCookieDataFromResponse:response forURL:URL];

    // then
    XCTAssertNil(self.sut.authenticationCookieData);
}

- (void)testThatSetCookieDataFromResponseDoesNothingWhenPolicyIsNever
{
    // given
    [PersistentCookieStorage setCookiesPolicy:NSHTTPCookieAcceptPolicyNever];
    NSDictionary *headerFields = @{@"Set-Cookie": @"zuid=abc123; Expires=Sun, 21-Jul-2030 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure"};
    NSURL *URL = [NSURL URLWithString:@"https://example.com/login"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headerFields];

    // when
    [self.sut setCookieDataFromResponse:response forURL:URL];

    // then
    XCTAssertNil(self.sut.authenticationCookieData);

    // cleanup
    [PersistentCookieStorage setCookiesPolicy:NSHTTPCookieAcceptPolicyAlways];
}

- (void)testThatDeleteKeychainItemsDoesNotFailWhenNothingIsStored
{
    [self.sut deleteKeychainItems];
    XCTAssertNil(self.sut.authenticationCookieData);
}

@end
