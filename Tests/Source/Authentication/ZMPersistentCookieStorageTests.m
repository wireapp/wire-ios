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


@import XCTest;

#import "ZMPersistentCookieStorage.h"



@interface ZMPersistentCookieStorageTests : XCTestCase
@end



@implementation ZMPersistentCookieStorageTests

- (BOOL)shouldUseRealKeychain;
{
    return (TARGET_IPHONE_SIMULATOR) || !(TARGET_OS_IPHONE);
}

- (void)setUp
{
    [super setUp];
    [ZMPersistentCookieStorage deleteAllKeychainItems];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testThatItDoesNotHaveACookie;
{
    ZMPersistentCookieStorage *sut = [ZMPersistentCookieStorage storageForServerName:@"1.example.com"];
    XCTAssertNil(sut.authenticationCookieData);
}

- (void)testThatItStoresTheCookie;
{
    ZMPersistentCookieStorage *sut = [ZMPersistentCookieStorage storageForServerName:@"1.example.com"];
    XCTAssertNil(sut.authenticationCookieData);
    NSData *data = [NSData dataWithBytes:(char []){'a'} length:1];
    [sut setAuthenticationCookieData:data];
    XCTAssertNotNil(sut.authenticationCookieData);
    XCTAssertEqualObjects(sut.authenticationCookieData, data);
}

- (void)testThatItUpdatesTheCookie;
{
    ZMPersistentCookieStorage *sut = [ZMPersistentCookieStorage storageForServerName:@"1.example.com"];
    XCTAssertNil(sut.authenticationCookieData);

    NSData *data1 = [NSData dataWithBytes:(char []){'a'} length:1];
    [sut setAuthenticationCookieData:data1];
    XCTAssertEqualObjects(sut.authenticationCookieData, data1);
    
    NSData *data2 = [NSData dataWithBytes:(char []){'B'} length:1];
    [sut setAuthenticationCookieData:data2];
    XCTAssertEqualObjects(sut.authenticationCookieData, data2);
}

- (void)testThatItIsUniqueForServerName;
{
    ZMPersistentCookieStorage *sut1 = [ZMPersistentCookieStorage storageForServerName:@"1.example.com"];
    ZMPersistentCookieStorage *sut2 = [ZMPersistentCookieStorage storageForServerName:@"2.example.com"];
    XCTAssertNil([sut1 authenticationCookieData]);
    XCTAssertNil([sut2 authenticationCookieData]);
    
    NSData *data1 = [NSData dataWithBytes:(char []){'a'} length:1];
    [sut1 setAuthenticationCookieData:data1];
    NSData *data2 = [NSData dataWithBytes:(char []){'b'} length:1];
    [sut2 setAuthenticationCookieData:data2];
    
    XCTAssertEqualObjects([sut1 authenticationCookieData], data1);
    XCTAssertEqualObjects([sut2 authenticationCookieData], data2);
}

- (void)testThatItCanDeleteCookies;
{
    ZMPersistentCookieStorage *sut = [ZMPersistentCookieStorage storageForServerName:@"1.example.com"];
    XCTAssertNil(sut.authenticationCookieData);
    
    NSData *data = [NSData dataWithBytes:(char []){'a'} length:1];
    [sut setAuthenticationCookieData:data];
    XCTAssertNotNil(sut.authenticationCookieData);
    [sut setAuthenticationCookieData:nil];
    XCTAssertNil(sut.authenticationCookieData);
}

- (void)testThatItPersistsCookies;
{
    NSData *data = [NSData dataWithBytes:(char []){'a'} length:1];
    @autoreleasepool {
        ZMPersistentCookieStorage *sut1 = [ZMPersistentCookieStorage storageForServerName:@"1.example.com"];
        [sut1 setAuthenticationCookieData:data];
    }
    {
        ZMPersistentCookieStorage *sut2 = [ZMPersistentCookieStorage storageForServerName:@"1.example.com"];
        XCTAssertEqualObjects([sut2 authenticationCookieData], data);
    }
}

- (void)testThatItCanDeleteAllCookies
{
    // given
    ZMPersistentCookieStorage *sut1 = [ZMPersistentCookieStorage storageForServerName:@"z1.example.com"];
    ZMPersistentCookieStorage *sut2 = [ZMPersistentCookieStorage storageForServerName:@"z2.example.com"];
    NSData *data = [@"This is cookie data" dataUsingEncoding:NSUTF8StringEncoding];
    [sut1 setAuthenticationCookieData:data];
    XCTAssertNotNil(sut1.authenticationCookieData);
    [sut2 setAuthenticationCookieData:data];
    XCTAssertNotNil(sut2.authenticationCookieData);
    
    // when
    [ZMPersistentCookieStorage deleteAllKeychainItems];
    
    // then
    XCTAssertEqualObjects(sut1.authenticationCookieData, nil);
    XCTAssertEqualObjects(sut2.authenticationCookieData, nil);
}

@end



@implementation ZMPersistentCookieStorageTests (HTTPCookie)

- (void)testThatWeCanRetrieveTheCookie;
{
    // given
    ZMPersistentCookieStorage *sut = [ZMPersistentCookieStorage storageForServerName:@"1.example.com"];
    XCTAssertNil(sut.authenticationCookieData);
    
    NSDictionary *headerFields = @{@"Date": @"Thu, 24 Jul 2014 09:06:45 GMT",
                                   @"Content-Encoding": @"gzip",
                                   @"Server": @"nginx",
                                   @"Content-Type": @"application/json",
                                   @"Access-Control-Allow-Origin": @"file://",
                                   @"Connection": @"keep-alive",
                                   @"Set-Cookie": @"zuid=wjCWn1Y1pBgYrFCwuU7WK2eHpAVY8Ocu-rUAWIpSzOcvDVmYVc9Xd6Ovyy-PktFkamLushbfKgBlIWJh6ZtbAA==.1721442805.u.7eaaa023.08326f5e-3c0f-4247-a235-2b4d93f921a4; Expires=Sun, 21-Jul-2024 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure",
                                   @"Content-Length": @"214"};
    NSURL *URL = [NSURL URLWithString:@"http://zeta.example.com/login"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headerFields];
    [sut setCookieDataFromResponse:response forURL:URL];
    XCTAssertNotNil(sut.authenticationCookieData);
    
    // when
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:URL];
    [sut setRequestHeaderFieldsOnRequest:request];
    
    // then
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Cookie"],
                          @"zuid=wjCWn1Y1pBgYrFCwuU7WK2eHpAVY8Ocu-rUAWIpSzOcvDVmYVc9Xd6Ovyy-PktFkamLushbfKgBlIWJh6ZtbAA==.1721442805.u.7eaaa023.08326f5e-3c0f-4247-a235-2b4d93f921a4");
}



- (void)testThatItDoesNotSetACookieDataIfNewCookieIsInvalid;
{
    // given
    ZMPersistentCookieStorage *sut = [ZMPersistentCookieStorage storageForServerName:@"1.example.com"];
    XCTAssertNil(sut.authenticationCookieData);
    sut.authenticationCookieData = [@"previous-cookie" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *headerFields = @{@"Date": @"Thu, 24 Jul 2014 09:06:45 GMT",
                                   @"Content-Encoding": @"gzip",
                                   @"Server": @"nginx",
                                   @"Content-Type": @"application/json",
                                   @"Access-Control-Allow-Origin": @"file://",
                                   @"Connection": @"keep-alive",
                                   @"Set-Cookie": @"UTTER GARBAGE",
                                   @"Content-Length": @"214"};
    NSURL *URL = [NSURL URLWithString:@"http://zeta.example.com/login"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headerFields];
    
    // when
    [sut setCookieDataFromResponse:response forURL:URL];
    
    // then
    XCTAssertNotNil(sut.authenticationCookieData);
}

- (void)testThatItDoesNotStoreNotAuthCookies
{
    // given
    ZMPersistentCookieStorage *sut = [ZMPersistentCookieStorage storageForServerName:@"1.example.com"];
    XCTAssertNil(sut.authenticationCookieData);
    
    NSDictionary *headerFields = @{@"Date": @"Thu, 24 Jul 2014 09:06:45 GMT",
                                   @"Content-Encoding": @"gzip",
                                   @"Server": @"nginx",
                                   @"Content-Type": @"application/json",
                                   @"Access-Control-Allow-Origin": @"file://",
                                   @"Connection": @"keep-alive",
                                   @"Set-Cookie": @"zuid.challenge=wjCWn1Y1pBgYrFCwuU7WK2eHpAVY8Ocu-rUAWIpSzOcvDVmYVc9Xd6Ovyy-PktFkamLushbfKgBlIWJh6ZtbAA==.1721442805.u.7eaaa023.08326f5e-3c0f-4247-a235-2b4d93f921a4; Expires=Sun, 21-Jul-2024 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure",
                                   @"Content-Length": @"214"};
    NSURL *URL = [NSURL URLWithString:@"http://zeta.example.com/login"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headerFields];

    // when
    [sut setCookieDataFromResponse:response forURL:URL];

    // then
    XCTAssertNil(sut.authenticationCookieData);
}

- (void)testThatItStoresAuthCookies
{
    // given
    ZMPersistentCookieStorage *sut = [ZMPersistentCookieStorage storageForServerName:@"1.example.com"];
    XCTAssertNil(sut.authenticationCookieData);
    
    NSDictionary *headerFields = @{@"Date": @"Thu, 24 Jul 2014 09:06:45 GMT",
                                   @"Content-Encoding": @"gzip",
                                   @"Server": @"nginx",
                                   @"Content-Type": @"application/json",
                                   @"Access-Control-Allow-Origin": @"file://",
                                   @"Connection": @"keep-alive",
                                   @"Set-Cookie": @"zuid=wjCWn1Y1pBgYrFCwuU7WK2eHpAVY8Ocu-rUAWIpSzOcvDVmYVc9Xd6Ovyy-PktFkamLushbfKgBlIWJh6ZtbAA==.1721442805.u.7eaaa023.08326f5e-3c0f-4247-a235-2b4d93f921a4; Expires=Sun, 21-Jul-2024 09:06:45 GMT; Domain=wire.com; HttpOnly; Secure",
                                   @"Content-Length": @"214"};
    NSURL *URL = [NSURL URLWithString:@"http://zeta.example.com/login"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:headerFields];
    
    // when
    [sut setCookieDataFromResponse:response forURL:URL];
    
    // then
    XCTAssertNotNil(sut.authenticationCookieData);
}

@end
