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


#import "MessagingTest.h"
#import "NSURL+LaunchOptions.h"

@interface NSURL_LaunchOptionsTests : MessagingTest

@end

@implementation NSURL_LaunchOptionsTests

- (NSString *)validInvitationToConnectToken
{
    return @"YjXsjDOfIEMtKPVnlNwHnzmn8J2R7Aika0LVMl1nCnM";
}

- (NSURL *)appendInvitationToConnectTokenToURLString:(NSString *)string
{
    return [NSURL URLWithString:[string stringByAppendingString:self.validInvitationToConnectToken]];
}

- (void)testThatItDetectsThatAURLIsNotAnInvitationToConnect
{
    // wrong schema
    XCTAssertFalse([[self appendInvitationToConnectTokenToURLString:@"http://connect?code="] isURLForInvitationToConnect]);
    XCTAssertFalse([[self appendInvitationToConnectTokenToURLString:@"https://connect?code="] isURLForInvitationToConnect]);
    // wrong path
    XCTAssertFalse([[self appendInvitationToConnectTokenToURLString:@"wire://something?code="] isURLForInvitationToConnect]);
    XCTAssertFalse([[self appendInvitationToConnectTokenToURLString:@"wire://connect/foo?code="] isURLForInvitationToConnect]);
    XCTAssertFalse([[self appendInvitationToConnectTokenToURLString:@"wire://connect/"] isURLForInvitationToConnect]);
    // wrong query parameters
    XCTAssertFalse([[self appendInvitationToConnectTokenToURLString:@"wire://connect?key="] isURLForInvitationToConnect]);
}

- (void)testThatItDetectsThatAURLIsAnInvitationToConnect
{
    // only required parameter
    XCTAssertTrue([[self appendInvitationToConnectTokenToURLString:@"wire://connect?code="] isURLForInvitationToConnect]);
    XCTAssertTrue([[self appendInvitationToConnectTokenToURLString:@"wire-invite://connect?code="] isURLForInvitationToConnect]);
    
    // additional parameters
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"wire://connect?foo=bar&code=%@&bar=quz", [self validInvitationToConnectToken]]];
    XCTAssertTrue([url isURLForInvitationToConnect]);
}

- (void)testThatItExtractsTheTokenFromAValidURL
{
    // given
    NSURL * url = [self appendInvitationToConnectTokenToURLString:@"wire://connect?code="];
    
    // when
    NSString *token = [url invitationToConnectToken];
    
    // then
    XCTAssertEqualObjects(token, [self validInvitationToConnectToken]);
}

- (void)testThatItExtractsTheTokenFromAValidURLWithMoreParameters
{
    // given
    NSURL * url = [self appendInvitationToConnectTokenToURLString:@"wire://connect?foo=1&code="];
    
    // when
    NSString *token = [url invitationToConnectToken];
    
    // then
    XCTAssertEqualObjects(token, [self validInvitationToConnectToken]);
}

- (void)testThatItDoesNotExtractTheTokenFromAnInvalidValidURL
{
    // given
    NSURL * url = [self appendInvitationToConnectTokenToURLString:@"http://wire?code="];
    
    // when
    NSString *token = [url invitationToConnectToken];
    
    // then
    XCTAssertNil(token);
}

- (void)testThatItDetectsValidURLForPhoneVerification
{
    XCTAssertTrue([[NSURL URLWithString:@"wire://verify-phone/123456"] isURLForPhoneVerification]);
    
}

- (void)testThatItRejectsInvalidURLForPhoneVerification
{
    // wrong schema
    XCTAssertFalse([[NSURL URLWithString:@"http://verify-phone/123456"] isURLForPhoneVerification]);
    XCTAssertFalse([[NSURL URLWithString:@"https://verify-phone/123456"] isURLForPhoneVerification]);
    
    // wrong host
    XCTAssertFalse([[NSURL URLWithString:@"wire://verify-email/123456"] isURLForPhoneVerification]);
    
    // missing code
    XCTAssertFalse([[NSURL URLWithString:@"wire://verify-phone/"] isURLForPhoneVerification]);
    XCTAssertFalse([[NSURL URLWithString:@"wire://verify-phone"] isURLForPhoneVerification]);
}

- (void)testThatItExtractsPhoneVerificationCodeFromAValidURL
{
    // given
    NSString *code = @"123456";
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"wire://verify-phone/%@", code]];
    
    // when
    NSString *extractedCode = [URL codeForPhoneVerification];
    
    // then
    XCTAssertEqualObjects(extractedCode, code);
}

- (void)testThatItExtractsPhoneVerificationCodeFromAValidURLWithQueryString
{
    // given
    NSString *code = @"123456";
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"wire://verify-phone/%@?parameter=1", code]];
    
    // when
    NSString *extractedCode = [URL codeForPhoneVerification];
    
    // then
    XCTAssertEqualObjects(extractedCode, code);
}

- (void)testThatItDoesNotExtractPhoneVerificationCodeFromAInvalidURL
{
    // given
    NSString *code = @"123456";
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"wire://verify-email/%@", code]];
    
    // when
    NSString *extractedCode = [URL codeForPhoneVerification];
    
    // then
    XCTAssertNil(extractedCode);
}

@end
