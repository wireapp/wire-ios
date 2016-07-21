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


#import "MockTransportSessionTests.h"

@interface MockTransportSessionRegistrationTests : MockTransportSessionTests

@end

@implementation MockTransportSessionRegistrationTests

- (MockUser *)userForEmail:(NSString *)email
{
    __block MockUser *user;
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        
        NSFetchRequest *fetchRequest = [MockUser sortedFetchRequest];
        fetchRequest.predicate = [NSPredicate predicateWithFormat: @"email == %@", email];
        
        NSArray *users = [session.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
        
        if (users.count == 1) {
            user = users[0];
        }
    }];
    return user;
}

- (MockUser *)userForPhone:(NSString *)phone
{
    __block MockUser *user;
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        
        NSFetchRequest *fetchRequest = [MockUser sortedFetchRequest];
        fetchRequest.predicate = [NSPredicate predicateWithFormat: @"phone == %@", phone];
        
        NSArray *users = [session.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
        
        if (users.count == 1) {
            user = users[0];
        }
    }];
    return user;
}

- (void)testThatRegistrationReturns400OnWrongMethod
{
    // given
    ZMTransportRequestMethod methods[] = {ZMMethodHEAD, ZMMethodGET, ZMMethodDELETE, ZMMethodPUT};
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              };
    
    for(size_t i = 0; i < sizeof(methods)/sizeof(methods[0]); ++i) {
        // when
        ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:methods[i]];
        
        // then
        XCTAssertEqual(response.HTTPStatus, 400);
        MockUser *user = [self userForEmail:payload[@"email"]];
        XCTAssertNil(user);
    }
}

- (void)testThatRegistrationReturns200AndCreatesAUserWithEmailIfAllRequiredUserFieldWherePresentOnAPost
{
    // given
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              };
    
    // when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 200);
    MockUser *user = [self userForEmail:payload[@"email"]];
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        NOT_USED(session);
        XCTAssertNotNil(user);
        XCTAssertEqualObjects(user.password, payload[@"password"]);
        XCTAssertEqualObjects(user.name, payload[@"name"]);
        XCTAssertEqualObjects(user.email, payload[@"email"]);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatRegistrationWithEmailReturnsCookies
{
    // given
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              };
    
    // when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    NSURL *url = [NSURL URLWithString:@"/register" relativeToURL:self.sut.baseURL];
    
    // then
    NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:response.headers forURL:url];
    XCTAssertEqual(cookies.count, 1u);
    XCTAssertEqualObjects([(NSHTTPCookie *)cookies.firstObject name], @"zuid");
}

- (void)testThatRegistrationWithEmailStoresCookiesIfPolicyIsAlways
{
    // given
    [ZMPersistentCookieStorage setCookiesPolicy:NSHTTPCookieAcceptPolicyAlways];
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              };
    
    // when
    __unused ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    
    // expect
    __block NSData *cookieData;
    [[(id) self.sut.cookieStorage expect] setAuthenticationCookieData:ZM_ARG_SAVE(cookieData)];
    
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatRegistrationWithEmailDoesNotStoreCookiesIfPolicyIsNever
{
    // given
    [ZMPersistentCookieStorage setCookiesPolicy:NSHTTPCookieAcceptPolicyAlways];
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              };
    
    // when
    __unused ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    
    // expect
    __block NSData *cookieData;
    [[(id) self.sut.cookieStorage reject] setAuthenticationCookieData:ZM_ARG_SAVE(cookieData)];
    
    WaitForAllGroupsToBeEmpty(0.5);
}


- (void)testThatRegistrationCreatesAUserWithNoValidatedEmail
{
    // given
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              };
    
    // when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 200);
    MockUser *user = [self userForEmail:payload[@"email"]];
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        NOT_USED(session);
        XCTAssertFalse(user.isEmailValidated);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatRegistrationWithNotVerifiedEmailReturnsPayloadWithNoEmail
{
    // given
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              };
    
    // when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    
    // then
    XCTAssertNil([[response.payload asDictionary] optionalStringForKey:@"email"]);
}

- (void)testThatRegistrationCreatesAUserWithValidatedEmailIfItsWhitelisted
{
    // given
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              };
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [session whiteListEmail:payload[@"email"]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    XCTAssertEqualObjects([[response.payload asDictionary] optionalStringForKey:@"email"], payload[@"email"]);

    // then
    XCTAssertEqual(response.HTTPStatus, 200);
    MockUser *user = [self userForEmail:payload[@"email"]];
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        NOT_USED(session);
        XCTAssertTrue(user.isEmailValidated);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThattestThatARegisterEmailUserPendingValidationIsValidatedWhenWhitelisted
{
    // given
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              };
    
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    XCTAssertNotNil(response);
    
    // when
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [session whiteListEmail:payload[@"email"]];
    }];
    
    // then
    MockUser *user = [self userForEmail:payload[@"email"]];
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        NOT_USED(session);
        XCTAssertTrue(user.isEmailValidated);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatRegistrationWithEmailReturns200AndCreatesAUserWithallFieldsOnAPost
{
    // given
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"someone@example.com",
                              @"password" : @"supersecure",
                              @"accent_id" : @(2)
                              };
    
    // when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 200);
    MockUser *user = [self userForEmail:payload[@"email"]];
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        NOT_USED(session);
        XCTAssertNotNil(user);
        XCTAssertEqualObjects(user.password, payload[@"password"]);
        XCTAssertEqualObjects(user.name, payload[@"name"]);
        XCTAssertEqualObjects(user.email, payload[@"email"]);
        XCTAssertEqualObjects(user.phone, payload[@"phone"]);
        XCTAssertEqual(user.accentID, [payload[@"accent_id"] integerValue]);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatRegistrationReturns400IfSomeRequiredFieldAreMissing
{
    // given
    NSDictionary *originalPayload = @{
                                      @"name" : @"Someone someone",
                                      @"email" : @"someone@example.com",
                                      @"password" : @"supersecure",
                                      };
    
    for(NSString *key in originalPayload.allKeys) {
        NSMutableDictionary *dictionaryWithoutAKey = [dictionaryWithoutAKey mutableCopy];
        [dictionaryWithoutAKey removeObjectForKey:key];
        
        // when
        ZMTransportResponse *response = [self responseForPayload:dictionaryWithoutAKey path:@"/register" method:ZMMethodPOST];
        
        // then
        XCTAssertEqual(response.HTTPStatus, 400);
        MockUser *user = [self userForEmail:originalPayload[@"email"]];
        XCTAssertNil(user);
    }
}

- (void)testThatRegistrationReturns409IfTheEmailIsAlreadyRegistered
{
    // given
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"email" : @"xxx-someone@example.com",
                              @"password" : @"supersecure",
                              };
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        MockUser *user = [session insertUserWithName:payload[@"name"]];
        user.email = payload[@"email"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 409);
    XCTAssertEqualObjects([response payloadLabel], @"key-exists");
}

- (void)requestVerificationCodeForPhone:(NSString *)phone {
    NSDictionary *requestPayload = @{@"phone":phone};
    NSString *path = [NSString pathWithComponents:@[@"/", @"activate", @"send"]];
    [self responseForPayload:requestPayload path:path method:ZMMethodPOST];
}

- (void)testThatRegistrationWithPhoneNumberReturns201AndCreatesAUserIfItHasAValidPhoneVerificationCode
{
    // given
    NSString *phone = @"+490000000";
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"phone" : phone,
                              @"phone_code" : self.sut.phoneVerificationCodeForRegistration,
                              };
    [self requestVerificationCodeForPhone:phone];
    
    // when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 200);
    MockUser *user = [self userForPhone:phone];
    XCTAssertNotNil(user);
    XCTAssertEqualObjects(user.name, payload[@"name"]);
    XCTAssertEqualObjects(user.phone, payload[@"phone"]);
}

- (void)testThatRegistrationWithPhoneNumberReturns201AndSetsTheCookie
{
    // given
    NSString *phone = @"+490000000";
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"phone" : phone,
                              @"phone_code" : self.sut.phoneVerificationCodeForRegistration,
                              };
    [self requestVerificationCodeForPhone:phone];
    
    // expect
    __block NSData *cookieData;
    [[(id) self.sut.cookieStorage expect] setAuthenticationCookieData:ZM_ARG_SAVE(cookieData)];
    
    // when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNotNil(cookieData);
}

- (void)testThatRegistrationWithPhoneNumberReturns409ItThereIsAlreadyAUserWithThatPhone
{
    // given
    NSString *phone = @"+490000000";
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"phone" : phone,
                              @"phone_code" : self.sut.phoneVerificationCodeForRegistration,
                              };
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        MockUser *user = [session insertUserWithName:payload[@"name"]];
        user.phone = payload[@"phone"];
    }];
    
    // when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 409);
    XCTAssertEqualObjects([response payloadLabel], @"key-exists");
}

- (void)testThatRegistrationWithPhoneNumberReturns404IfThereIsNoPhoneWithPendingVerificationCode
{
    // given
    NSString *phone = @"+490000000";
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"phone" : phone,
                              @"phone_code" : self.sut.phoneVerificationCodeForRegistration,
                              };
    
    // when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 404);
}

- (void)testThatRegistrationWithPhoneNumberReturns404IfTheVerificationCodeIsWrong
{
    // given
    NSString *phone = @"+490000000";
    NSDictionary *payload = @{
                              @"name" : @"Someone someone",
                              @"phone" : phone,
                              @"phone_code" : self.sut.invalidPhoneVerificationCode,
                              };
    [self requestVerificationCodeForPhone:phone];
    
    // when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 404);
}

- (void)testThatRegisteringWithInvitationCodeReturns200WithEmailRegistration;
{
    // given
    NSString *email = @"volgaar@vicking.com";
    NSString *password = @"i.am.a.vicking.";
    NSString *inviteeName = @"Volgaar";
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        MockUser *selfUser = [session insertSelfUserWithName:@"Louis-Émile"];
        [session insertInvitationForSelfUser:selfUser inviteeName:inviteeName mail:email];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDictionary *payload = @{
                              @"name" : inviteeName,
                              @"email" : email,
                              @"password" : password,
                              @"invitation_code" : self.sut.invitationCode,
                              };
    
    
    // when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 200);
}

- (void)testThatRegisteringWithInvalidInvitationCodeReturns404CodeForEmailRegistration;
{
    // given
    NSString *email = @"volgaar@vicking.com";
    NSString *password = @"i.am.a.vicking.";
    NSString *inviteeName = @"Volgaar";
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        MockUser *selfUser = [session insertSelfUserWithName:@"Louis-Émile"];
        [session insertInvitationForSelfUser:selfUser inviteeName:inviteeName mail:email];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDictionary *payload = @{
                              @"name" : inviteeName,
                              @"email" : email,
                              @"password" : password,
                              @"invitation_code" : self.sut.invalidInvitationCode,
                              };
    
    // when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 400);
}

- (void)testThatRegisteringWithValidInvitationCodeReturns404CodeIfInvitationDoesNotExist;
{
    // given
    NSString *email = @"volgaar@vicking.com";
    NSString *password = @"i.am.a.vicking.";
    NSString *inviteeName = @"Volgaar";
    
    
    NSDictionary *payload = @{
                              @"name" : inviteeName,
                              @"email" : email,
                              @"password" : password,
                              @"invitation_code" : self.sut.invitationCode,
                              };
    
    // when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 404);
}


- (void)testThatRegisteringWithInvitationCodeReturns200WithoutPhoneCode;
{
    // given
    NSString *phone = @"+490000000";
    NSString *inviteeName = @"Volgaar";

    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        MockUser *selfUser = [session insertSelfUserWithName:@"Louis-Émile"];
        [session insertInvitationForSelfUser:selfUser inviteeName:inviteeName phone:phone];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDictionary *payload = @{
                              @"name" : inviteeName,
                              @"phone" : phone,
                              @"invitation_code" : self.sut.invitationCode,
                              };
    
    
    // when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 200);
}

- (void)testThatRegisteringWithInvalidInvitationCodeReturns400Code;
{
    // given
    NSString *phone = @"+490000000";
    NSString *inviteeName = @"Volgaar";
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        MockUser *selfUser = [session insertSelfUserWithName:@"Louis-Émile"];
        [session insertInvitationForSelfUser:selfUser inviteeName:inviteeName phone:phone];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDictionary *payload = @{
                              @"name" : inviteeName,
                              @"phone" : phone,
                              @"invitation_code" : self.sut.invalidInvitationCode,
                              };
    
    // when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/register" method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 400);
}

@end
