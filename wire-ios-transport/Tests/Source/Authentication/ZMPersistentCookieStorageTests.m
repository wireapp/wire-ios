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
@import WireTransportSupport;
@import WireTransport.Testing;


@interface PersistentCookieStorageTests : XCTestCase

@property (nonatomic, readonly) NSUUID *userIdentifier;
@property (nonatomic) PersistentCookieStorage *sut;

@end

@interface PersistentCookieStorageTests (HTTPCookie)
@end

@implementation PersistentCookieStorageTests

- (void)setUp
{
    [super setUp];
    _userIdentifier = NSUUID.createUUID;
    self.sut = [[PersistentCookieStorage alloc] initWithTestingWithUserIdentifier:self.userIdentifier];
}

- (void)tearDown
{
    _userIdentifier = nil;
    [super tearDown];
    [self.sut removeCookies];
    self.sut = nil;
}

- (void)testThatItDoesNotHaveACookie;
{
    XCTAssertFalse(self.sut.hasAuthenticationCookie);
}

- (void)testThatItStoresTheCookie;
{
    XCTAssertFalse(self.sut.hasAuthenticationCookie);
    [self.sut setAuthenticationCookies:[NSHTTPCookie validCookies]];
    XCTAssertTrue(self.sut.hasAuthenticationCookie);
    XCTAssertTrue(self.sut.hasAuthenticationCookie);
}

- (void)testThatItUpdatesTheCookie;
{
    XCTAssertFalse(self.sut.hasAuthenticationCookie);

    [self.sut setAuthenticationCookies:[NSHTTPCookie validCookies]];
    XCTAssertTrue(self.sut.hasAuthenticationCookie);

    NSArray<NSHTTPCookie *> *otherCookies = [NSHTTPCookie validCookiesWithString:@"zuid=other; Path=/access; Expires=Tue, 06-Oct-2099 11:46:18 GMT; HttpOnly; Secure"];
    [self.sut setAuthenticationCookies:otherCookies];
    XCTAssertTrue(self.sut.hasAuthenticationCookie);
}

- (void)testThatItCanDeleteCookies;
{
    XCTAssertFalse(self.sut.hasAuthenticationCookie);

    [self.sut setAuthenticationCookies:[NSHTTPCookie validCookies]];
    XCTAssertTrue(self.sut.hasAuthenticationCookie);
    [self.sut removeCookies];
    XCTAssertFalse(self.sut.hasAuthenticationCookie);
}

- (void)testThatItPersistsCookies;
{
    @autoreleasepool {
        PersistentCookieStorage *sut1 = self.sut;
        [sut1 setAuthenticationCookies:[NSHTTPCookie validCookies]];
    }
    {
        PersistentCookieStorage *sut2 = self.sut;
        XCTAssertTrue(sut2.hasAuthenticationCookie);
    }
}

- (void)testThatItCanDeleteCookiesForASpecificCookieStorage
{
    // given
    NSUUID *otherUserIdentifier = NSUUID.createUUID;
    PersistentCookieStorage *sut1 = [[PersistentCookieStorage alloc] initWithTestingWithUserIdentifier:self.userIdentifier];
    PersistentCookieStorage *sut2 = [[PersistentCookieStorage alloc] initWithTestingWithUserIdentifier:otherUserIdentifier];

    [sut1 setAuthenticationCookies:[NSHTTPCookie validCookies]];
    XCTAssertTrue(sut1.hasAuthenticationCookie);
    [sut2 setAuthenticationCookies:[NSHTTPCookie validCookies]];
    XCTAssertTrue(sut2.hasAuthenticationCookie);

    // when
    [sut1 removeCookies];

    // then
    XCTAssertFalse(sut1.hasAuthenticationCookie);
    XCTAssertTrue(sut2.hasAuthenticationCookie);

    // when
    [sut2 removeCookies];
    XCTAssertFalse(sut1.hasAuthenticationCookie);
    XCTAssertFalse(sut2.hasAuthenticationCookie);
}

- (void)testThatItCanDeleteAllCookies
{
    // given
    NSUUID *otherUserIdentifier = NSUUID.createUUID;
    PersistentCookieStorage *sut1 = [[PersistentCookieStorage alloc] initWithTestingWithUserIdentifier:self.userIdentifier];
    PersistentCookieStorage *sut2 = [[PersistentCookieStorage alloc] initWithTestingWithUserIdentifier:otherUserIdentifier];

    [sut1 setAuthenticationCookies:[NSHTTPCookie validCookies]];
    XCTAssertTrue(sut1.hasAuthenticationCookie);
    [sut2 setAuthenticationCookies:[NSHTTPCookie validCookies]];
    XCTAssertTrue(sut2.hasAuthenticationCookie);

    // when
    [sut1 removeCookies];
    [sut2 removeCookies];

    // then
    XCTAssertFalse(sut1.hasAuthenticationCookie);
    XCTAssertFalse(sut2.hasAuthenticationCookie);
}

@end



@implementation PersistentCookieStorageTests (HTTPCookie)

- (void)testThatWeCanRetrieveTheCookie;
{
    // given
    XCTAssertFalse(self.sut.hasAuthenticationCookie);
    
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
    XCTAssertTrue(self.sut.hasAuthenticationCookie);
    
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
    XCTAssertFalse(self.sut.hasAuthenticationCookie);
    
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
    XCTAssertTrue(self.sut.hasAuthenticationCookie);
    
    // when
    NSISO8601DateFormatter *dateFormatter = [[NSISO8601DateFormatter alloc] init];
    XCTAssertEqualObjects([dateFormatter stringFromDate:self.sut.authenticationCookieExpirationDate], @"2024-07-21T09:06:45Z");
}

- (void)testThatItDoesNotSetACookieDataIfNewCookieIsInvalid;
{
    // given
    XCTAssertFalse(self.sut.hasAuthenticationCookie);
    [self.sut setAuthenticationCookies:[NSHTTPCookie validCookies]];

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
    XCTAssertTrue(self.sut.hasAuthenticationCookie);
}

- (void)testThatItDoesNotStoreNotAuthCookies
{
    // given
    XCTAssertFalse(self.sut.hasAuthenticationCookie);
    
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
    XCTAssertFalse(self.sut.hasAuthenticationCookie);
}

- (void)testThatItStoresAuthCookies
{
    // given
    XCTAssertFalse(self.sut.hasAuthenticationCookie);
    
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
    XCTAssertTrue(self.sut.hasAuthenticationCookie);
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
    XCTAssertFalse(self.sut.hasAuthenticationCookie);
}

- (void)testThatRemoveCookiesDoesNotFailWhenNothingIsStored
{
    [self.sut removeCookies];
    XCTAssertFalse(self.sut.hasAuthenticationCookie);
}

@end
