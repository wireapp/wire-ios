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

@import WireTransport;
@import WireMockTransport;
@import WireDataModel;

#import "NSError+ZMUserSessionInternal.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>
#import "Tests-Swift.h"

#import "ZMCredentials.h"
#import <WireSyncEngine/ZMAuthenticationStatus.h>

extern NSTimeInterval DebugLoginFailureTimerOverride;

@interface LoginFlowTests : IntegrationTest
@end

@implementation LoginFlowTests

- (void)setUp
{
    [super setUp];
    
    [self createSelfUserAndConversation];
}

- (void)tearDown
{
    DebugLoginFailureTimerOverride = 0;
    
    [super tearDown];
}

- (void)testThatItWaitsAfterEmailLoginToImportBackup
{
    // given
    NSString *email = @"expected@example.com";
    NSString *password = @"valid-password-837246";
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        NOT_USED(session);
        self.selfUser.name = @"Self User";
        self.selfUser.email = email;
        self.selfUser.password = password;
    }];

    // when
    ZMCredentials *credentials = [ZMEmailCredentials credentialsWithEmail:email password:password];
    [self.unauthenticatedSession loginWithCredentials:credentials];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertTrue(self.mockLoginDelegete.didCallAuthenticationReadyToImportBackup);
    XCTAssertFalse(self.userSession.isLoggedIn);
}

- (void)testThatWeCanLogInWithEmail
{
    // given
    NSString *email = @"expected@example.com";
    NSString *password = @"valid-password-837246";
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        NOT_USED(session);
        self.selfUser.name = @"Self User";
        self.selfUser.email = email;
        self.selfUser.password = password;
    }];

    // when
    ZMCredentials *credentials = [ZMEmailCredentials credentialsWithEmail:email password:password];
    [self.unauthenticatedSession loginWithCredentials:credentials];
    WaitForAllGroupsToBeEmpty(0.5);
    [self.unauthenticatedSession continueAfterBackupImportStep];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertTrue(self.userSession.isLoggedIn);
}

- (void)testThatWeCanLoginWithAValidPreExistingCookie
{
    // given
    XCTAssertTrue([self login]);

    // when
    [self recreateSessionManager];

    // then
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertNotNil([self.mockTransportSession.cookieStorage authenticationCookieData]);
    XCTAssertTrue(self.userSession.isLoggedIn);
}

- (void)testThatWeReceiveAuthenticationErrorWithWrongCredentials
{
    // given
    NSString *email = @"expected@example.com";
    NSString *password = @"valid-password-837246";
    __block MockUser *selfUser;
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        selfUser = [session insertUserWithName:@"Self User"];
        selfUser.email = email;
        selfUser.password = password;
    }];
    
    // when
    ZMCredentials *credentials = [ZMEmailCredentials credentialsWithEmail:email password:@"wrong-password"];
    [self.unauthenticatedSession loginWithCredentials:credentials];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(self.mockLoginDelegete.didCallAuthenticationDidFail);
    XCTAssertEqual(self.mockLoginDelegete.currentError.code, (long)ZMUserSessionInvalidCredentials);
}

- (void)testThatWhenTransportSessionDeletesCookieInResponseToFailedLoginWeDoNotContinueSendingMoreRequests
{
    // given
    NSString *email = @"expected@example.com";
    NSString *password = @"valid-password-837246";
    __block MockUser *selfUser;
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        selfUser = [session insertUserWithName:@"Self User"];
        selfUser.email = email;
        selfUser.password = password;
    }];
    
    // getting access token fails
    __block NSInteger numberOfRequests = 0;
    ZM_WEAK(self);
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        ZM_STRONG(self);
        NOT_USED(request);
        ++numberOfRequests;
        if (numberOfRequests == 1) {
            return nil; // allow authentication ...
        }
        //  ... but no request after it
        NSError *error = [NSError errorWithDomain:ZMTransportSessionErrorDomain code:ZMTransportSessionErrorCodeAuthenticationFailed userInfo:nil];
        [self.mockTransportSession.cookieStorage setAuthenticationCookieData:nil];
        [ZMPersistentCookieStorage deleteAllKeychainItems];
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:0 transportSessionError:error apiVersion:0];
    };
    
    // when
    ZMCredentials *credentials = [ZMEmailCredentials credentialsWithEmail:email password:password];
    [self.unauthenticatedSession loginWithCredentials:credentials];
    WaitForAllGroupsToBeEmpty(0.5);
    [self.unauthenticatedSession continueAfterBackupImportStep];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertFalse(self.userSession.isLoggedIn);
    XCTAssertTrue(self.mockLoginDelegete.didCallAuthenticationReadyToImportBackup);
    XCTAssertTrue(self.mockLoginDelegete.didCallAuthenticationDidSucceed);
}

- (void)testThatWhenTransportSessionDeletesCookieInResponseToFailedRenewTokenWeGoToUnathorizedState
{
    // given
    NSString *email = @"expected@example.com";
    NSString *password = @"valid-password-837246";
    __block MockUser *selfUser;
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        selfUser = [session insertUserWithName:@"Self User"];
        selfUser.email = email;
        selfUser.password = password;
    }];
    
    // getting access token fails
    __block NSInteger numberOfRequests = 0;
    ZM_WEAK(self);
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        ZM_STRONG(self);
        NOT_USED(request);
        ++numberOfRequests;
        if (numberOfRequests == 1) {
            return nil; // allow login ...
        }
        //  ... but no request after it
        NSError *error = [NSError errorWithDomain:ZMTransportSessionErrorDomain code:ZMTransportSessionErrorCodeAuthenticationFailed userInfo:nil];
        [self.mockTransportSession.cookieStorage setAuthenticationCookieData:nil];
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:0 transportSessionError:error apiVersion:0];
    };
    
    // when
    ZMCredentials *credentials = [ZMEmailCredentials credentialsWithEmail:email password:password];
    [self.unauthenticatedSession loginWithCredentials:credentials];
    WaitForAllGroupsToBeEmpty(0.5);
    [self.unauthenticatedSession continueAfterBackupImportStep];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertFalse(self.userSession.isLoggedIn);
    XCTAssertTrue(self.mockLoginDelegete.didCallAuthenticationReadyToImportBackup);
    XCTAssertTrue(self.mockLoginDelegete.didCallAuthenticationDidSucceed);
}


- (void)testThatTheLoginTimesOutOnNetworkErrors
{
    // given
    NSError *error = [NSError errorWithDomain:ZMTransportSessionErrorDomain code:ZMTransportSessionErrorCodeTryAgainLater userInfo:nil];
    ZM_WEAK(self);
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        ZM_STRONG(self);
        NOT_USED(request);
        self.mockTransportSession.disableEnqueueRequests = YES;
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:0 transportSessionError:error apiVersion:0];
    };
    DebugLoginFailureTimerOverride = 0.2;
    
    // when
    ZMCredentials *credentials = [ZMEmailCredentials credentialsWithEmail:@"janet@fo.example.com" password:@"::FsdF:#$:fgsdAG"];
    [self.unauthenticatedSession loginWithCredentials:credentials];
    
    // then
    XCTAssertTrue([self waitOnMainLoopUntilBlock:^BOOL{
        return self.mockLoginDelegete.didCallAuthenticationDidFail;
    } timeout:0.5]);
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertEqual(self.mockLoginDelegete.currentError.code, (long)ZMUserSessionNetworkError);
    XCTAssertLessThan(self.mockTransportSession.receivedRequests.count, 2u);

    // after
    DebugLoginFailureTimerOverride = 0;
}

@end

@implementation LoginFlowTests (EmailLogin)

- (void)testThatItNotifiesIfTheEmailVerificationLoginCodeCanNotBeRequested
{
    // given
    NSString *email = @"test@wire.com";

    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        if([request.path isEqualToString:@"/verification-code/send"]) {
            return [ZMTransportResponse responseWithPayload:nil HTTPStatus:403 transportSessionError:nil apiVersion:APIVersionV0];
        }
        return nil;
    };

    // when
    [self.unauthenticatedSession requestEmailVerificationCodeForLogin:email];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertTrue(self.mockLoginDelegete.didCallLoginCodeRequestDidFail);
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 1u);
}

@end


@implementation LoginFlowTests (ClientRegistration_Errors)

- (void)testThatItFetchesSelfUserBeforeRegisteringSelfClient
{
    // expect
    __block BOOL didCreateSelfClient = NO;
    __block BOOL didFetchSelfUser = NO;
    ZM_WEAK(self);
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        ZM_STRONG(self);
        
        if([request.path isEqualToString:@"/clients"] && request.method == ZMTransportRequestMethodPost) {
            XCTAssertTrue(didFetchSelfUser);
            didCreateSelfClient = YES;
        }
        if (!didFetchSelfUser && [request.path isEqualToString:@"/self"] && request.method == ZMTransportRequestMethodGet) {
            XCTAssertFalse(didCreateSelfClient);
            didFetchSelfUser = YES;
        }
        return nil;
    };
    
    // and when
    XCTAssertTrue([self login]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(didCreateSelfClient);
    XCTAssertTrue(didFetchSelfUser);
}

- (void)testThatWeCanLoginAfterRegisteringAnEmailAddressAndClient
{
    // given
    NSString *phone = @"+4912345678900";
    NSString *email = @"email@example.com";
    NSString *password = @"newPassword";
    
    self.selfUser.phone = phone;
    
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        [session whiteListPhone:phone];
        self.selfUser.email = nil;
        self.selfUser.password = nil;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    ZMEmailCredentials *credentials = [ZMEmailCredentials credentialsWithEmail:email password:password];
    [self.userSession performChanges:^{
        [self.userSession.userProfile requestSettingEmailAndPasswordWithCredentials:credentials error:nil];
    }];

    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        // simulate user click on email
        NOT_USED(session);
        self.selfUser.email = email;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    __block BOOL didRun = NO;
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        // when trying to register without email credentials, the BE tells us we need credentials
        if(!didRun && [request.path isEqualToString:@"/clients"] && request.method == ZMTransportRequestMethodPost) {
            didRun = YES;
        }
        // the user updates the email address (currently does not work in MockTransportsession for some reason)
        if ([request.path isEqualToString:@"/self/email"]) {
            return [ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };
    

    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.name, self.selfUser.name);
    XCTAssertEqualObjects(selfUser.emailAddress, email);
}

- (void)testThatItCanRegisterNewClientAfterDeletingSelfClient
{
    // given
    XCTAssertTrue([self login]);
    
    // when we delete self client
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        MockUserClient *selfClient = self.selfUser.clients.anyObject;
        [session deleteUserClientWithIdentifier:selfClient.identifier forUser:self.selfUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when login 2nd time
    XCTAssertTrue([self login]);
    
    // then
    XCTAssertTrue(self.mockLoginDelegete.didCallClientRegistrationDidSucceed);
}

- (void)testThatItCanRegisterANewClientAfterDeletingClients
{
    // given
    __block NSString *idToDelete;
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        MockUserClient *client = [session registerClientForUser:self.selfUser];
        idToDelete = client.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self.userSession performChanges:^{
        ZMUser *selfUser = [self userForMockUser:self.selfUser];
        [selfUser.managedObjectContext saveOrRollback];
        UserClient *clientToDelete = [selfUser.clients.allObjects firstObjectMatchingWithBlock:^BOOL(UserClient *client) {
            return [client.remoteIdentifier isEqualToString:idToDelete];
        }];
        XCTAssertNotNil(clientToDelete);
        [self.userSession deleteClient:clientToDelete withCredentials:nil];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    __block BOOL didTryToRegister = NO;
    __block BOOL didDeleteClient = NO;

    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        NSString *clientsPath = @"/clients";
        // BE tells us to select one of the clients to delete
        if(!didTryToRegister && [request.path isEqualToString:clientsPath] && request.method == ZMTransportRequestMethodPost) {
            didTryToRegister = YES;
            NSDictionary *tooManyClients = @{@"label" : @"too-many-clients"};
            return [ZMTransportResponse responseWithPayload:tooManyClients HTTPStatus:400 transportSessionError:nil apiVersion:0];
        }
        // we successfully delete the selected client (currently not working with MocktransportSession)
        if(!didDeleteClient && [request.path isEqualToString:[NSString stringWithFormat:@"%@/%@",clientsPath, idToDelete]] && request.method == ZMTransportRequestMethodDelete) {
            didDeleteClient = YES;
            return [ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };
    
    // and when
    XCTAssertTrue([self loginAndIgnoreAuthenticationFailures:YES]);
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssert(didTryToRegister);
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.name, self.selfUser.name);
}

@end
