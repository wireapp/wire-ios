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

#import "Tests-Swift.h"
#import "UserProfileTests.h"
@import WireUtilities;

@implementation UserProfileTests

- (void)setUp
{
    [super setUp];
    
    [self createSelfUserAndConversation];
}

- (void)testThatWeCanChangeUsernameAndAccentColorForSelfUser
{

    NSString *name = @"My New Name";
    ZMAccentColor *accentColor = ZMAccentColor.purple;
    {
        // Create a UI context
        XCTAssertTrue([self login]);
        // Change the name & save
        ZMUser<ZMEditableUserType> *selfUser = [ZMUser selfUserInUserSession:self.userSession];

        // sanity check
        XCTAssertNotEqual(selfUser.zmAccentColor, accentColor);

        selfUser.name = name;
        selfUser.zmAccentColor = accentColor;

        [self.userSession saveOrRollbackChanges];
        // Wait for merge ui->sync to be done
        WaitForAllGroupsToBeEmpty(0.5);
        
        
        XCTAssertEqual(selfUser.zmAccentColor, accentColor);
    }
    
    // Tears down context(s) &
    // Re-create contexts
    [self destroySessionManager];
    [self deleteAuthenticationCookie];
    [self createSessionManager];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // Wait for sync to be done
    XCTAssertTrue([self login]);
    
    // Check that user is updated:
    {
        // Get the self user
        ZMUser<ZMEditableUserType> *selfUser = [ZMUser selfUserInUserSession:self.userSession];
        XCTAssertEqualObjects(selfUser.name, name);
        XCTAssertEqual(selfUser.zmAccentColor, accentColor);
    }
}

- (void)testThatItNotifiesObserverWhenWeChangeAccentColorForSelfUser
{
    ZMAccentColor *accentColor = ZMAccentColor.turquoise;

    XCTAssertTrue([self login]);

    ZMUser<ZMEditableUserType> *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertNotEqual(selfUser.zmAccentColor, accentColor);

    ZMUserObserver *observer = [[ZMUserObserver alloc] initWithUser:selfUser];
    
    // when
    selfUser.zmAccentColor = accentColor;
    [self.userSession saveOrRollbackChanges];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    NSArray *notifications = observer.notifications;
    XCTAssertEqual(notifications.count, 1u);
    
    UserChangeInfo *note = notifications.firstObject;
    XCTAssertNotNil(note);
    XCTAssertTrue(note.accentColorValueChanged);
    
    XCTAssertEqual(selfUser.zmAccentColor, accentColor);
}

- (BOOL)loginAndRemoveEmail
{
    UserEmailCredentials *credentials = [UserEmailCredentials credentialsWithEmail:IntegrationTest.SelfUserEmail
                                                                          password:IntegrationTest.SelfUserPassword];
    BOOL success = [self loginWithCredentials:credentials ignoreAuthenticationFailures:NO];

    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        NOT_USED(session);
        self.selfUser.email = nil;
        self.selfUser.password = nil;
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    return success;
}

- (void)disable_testThatItCanSetEmailAndPassword
{
    // given
    NSString *email = @"foobar@geraterwerwer.dsf.example.com";
    XCTAssert([self loginAndRemoveEmail]);
    UserEmailCredentials *credentials = [UserEmailCredentials credentialsWithEmail:email password:@"ds4rgsdg"];
    [self.mockTransportSession resetReceivedRequests];
    
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.emailAddress, nil);

    // expect
    id editUserObserver = [OCMockObject mockForProtocol:@protocol(UserProfileUpdateObserver)];
    id editUserObserverToken = [self.userSession.userProfile addObserver:editUserObserver];
    [[editUserObserver expect] didSendVerificationEmail];
    
    id userObserver = [OCMockObject mockForProtocol:@protocol(ZMUserObserving)];
    id userObserverToken = [UserChangeInfo addObserver:userObserver forUser:selfUser inManagedObjectContext:self.userSession.managedObjectContext];
    [(id<ZMUserObserving>)[userObserver expect] userDidChange:OCMOCK_ANY]; // <- DONE: when receiving this, I know that the email was set

    // when
    [self.userSession.userProfile requestSettingEmailAndPasswordWithCredentials:credentials error:nil]; // <- STEP 1
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        // simulate user click on email
        NOT_USED(session);
        self.selfUser.email = email;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 2u);
    XCTAssertEqualObjects(selfUser.emailAddress, email);
    
    // after
    editUserObserverToken = nil;
    userObserverToken = nil;
}

- (void)testThatItNotifiesWhenFailingToSetThePasswordForNetworkError
{
    // given
    NSString *email = @"foobar@geraterwerwer.dsf.example.com";
    XCTAssert([self loginAndRemoveEmail]);
    UserEmailCredentials *credentials = [UserEmailCredentials credentialsWithEmail:email password:@"ds4rgsdg"];
    [self.mockTransportSession resetReceivedRequests];
    
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.emailAddress, nil);
    
    id userObserver = [OCMockObject mockForProtocol:@protocol(UserProfileUpdateObserver)];
    id token = [self.userSession.userProfile addObserver:userObserver];
    
    // expect
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        if([request.path isEqualToString:@"/self/password"]) {
            return [ZMTransportResponse responseWithPayload:nil HTTPStatus:400 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };
    [[userObserver expect] passwordUpdateRequestDidFail];
    
    // when
    [self.userSession.userProfile requestSettingEmailAndPasswordWithCredentials:credentials error:nil];
    WaitForAllGroupsToBeEmpty(5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 1u);
    
    // after
    token = nil;
}

- (void)disable_testThatItSilentlyIgnoreWhenFailingToSetThePasswordBecauseThePasswordWasAlreadyThere
{
    // given
    NSString *email = @"foobar@geraterwerwer.dsf.example.com";
    XCTAssert([self loginAndRemoveEmail]);
    UserEmailCredentials *credentials = [UserEmailCredentials credentialsWithEmail:email password:@"ds4rgsdg"];
    [self.mockTransportSession resetReceivedRequests];
    
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.emailAddress, nil);
    
    id editingObserver = [OCMockObject mockForProtocol:@protocol(UserProfileUpdateObserver)];
    id editingToken = [self.userSession.userProfile addObserver:editingObserver];
    id userObserver = [OCMockObject mockForProtocol:@protocol(ZMUserObserving)];
    id userObserverToken = [UserChangeInfo addObserver:userObserver forUser:selfUser inManagedObjectContext:self.userSession.managedObjectContext];
    [(id<ZMUserObserving>)[userObserver expect] userDidChange:OCMOCK_ANY]; // when receiving this, I know that the email was set

    // expect
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        if([request.path isEqualToString:@"/self/password"]) {
            return [ZMTransportResponse responseWithPayload:@{@"label":@"invalid-credentials"} HTTPStatus:403 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };
    [[editingObserver expect] didSendVerificationEmail];
    [[editingObserver expect] passwordUpdateRequestDidFail];
    
    // when
    [self.userSession.userProfile requestSettingEmailAndPasswordWithCredentials:credentials error:nil];
    WaitForAllGroupsToBeEmpty(5);
    
    [self.mockTransportSession performRemoteChanges:^ (id<MockTransportSessionObjectCreation>  _Nonnull __strong session) {
        // simulate user click on email
        NOT_USED(session);
        self.selfUser.email = email;
    }];
    WaitForAllGroupsToBeEmpty(5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 2u);
    XCTAssertEqualObjects(selfUser.emailAddress, email);
    
    // after
    editingToken = nil;
    userObserverToken = nil;
}

- (void)testThatItNotifiesWhenFailingToSetTheEmailBecauseOfGenericError
{
    // given
    XCTAssert([self loginAndRemoveEmail]);
    UserEmailCredentials *credentials = [UserEmailCredentials credentialsWithEmail:@"foobar@geraterwerwer.dsf.example.com"
                                                                          password:@"ds4rgsdg"];
    [self.mockTransportSession resetReceivedRequests];
    
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.emailAddress, nil);
    
    id editiongObserver = [OCMockObject mockForProtocol:@protocol(UserProfileUpdateObserver)];
    id token = [self.userSession.userProfile addObserver:editiongObserver];
    
    // expect
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        if([request.path isEqualToString:@"/self/email"]) {
            return [ZMTransportResponse responseWithPayload:nil HTTPStatus:400 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };
    [[editiongObserver expect] emailUpdateDidFail:[NSError userSessionErrorWithCode:ZMUserSessionErrorCodeUnknownError userInfo:nil]];

    // when
    [self.userSession.userProfile requestSettingEmailAndPasswordWithCredentials:credentials error:nil];
    WaitForAllGroupsToBeEmpty(5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 2u);
    
    // after
    token = nil;
    
}

- (void)disable_testThatItNotifiesWhenFailingToSetTheEmailBecauseOfInvalidEmail
{
    // given
    NSString *email = @"foobar@geraterwerwer.dsf.example.com";
    XCTAssert([self loginAndRemoveEmail]);
    UserEmailCredentials *credentials = [UserEmailCredentials credentialsWithEmail:email password:@"ds4rgsdg"];
    [self.mockTransportSession resetReceivedRequests];
    
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.emailAddress, nil);
    
    id editiongObserver = [OCMockObject mockForProtocol:@protocol(UserProfileUpdateObserver)];
    id token = [self.userSession.userProfile addObserver:editiongObserver];
    
    // expect
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        if([request.path isEqualToString:@"/self/email"]) {
            return [ZMTransportResponse responseWithPayload:@{@"label":@"invalid-email"} HTTPStatus:400 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };
    [[editiongObserver expect] emailUpdateDidFail:[NSError userSessionErrorWithCode:ZMUserSessionErrorCodeInvalidEmail userInfo:nil]];

    // when
    [self.userSession.userProfile requestSettingEmailAndPasswordWithCredentials:credentials error:nil];
    WaitForAllGroupsToBeEmpty(5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 2u);
    
    // after
    token = nil;
    
}

- (void)disable_testThatItNotifiesWhenFailingToSetTheEmailBecauseOfEmailAlreadyInUse
{
    // given
    NSString *email = @"foobar@geraterwerwer.dsf.example.com";
    XCTAssert([self loginAndRemoveEmail]);
    UserEmailCredentials *credentials = [UserEmailCredentials credentialsWithEmail:email password:@"ds4rgsdg"];
    [self.mockTransportSession resetReceivedRequests];
    
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self.userSession];
    XCTAssertEqualObjects(selfUser.emailAddress, nil);
    
    id editiongObserver = [OCMockObject mockForProtocol:@protocol(UserProfileUpdateObserver)];
    id token = [self.userSession.userProfile addObserver:editiongObserver];
    
    // expect
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse*(ZMTransportRequest *request) {
        if([request.path isEqualToString:@"/self/email"]) {
            return [ZMTransportResponse responseWithPayload:@{@"label":@"key-exists"} HTTPStatus:409 transportSessionError:nil apiVersion:0];
        }
        return nil;
    };
    [[editiongObserver expect] emailUpdateDidFail:[NSError userSessionErrorWithCode:ZMUserSessionErrorCodeEmailIsAlreadyRegistered userInfo:nil]];

    // when
    [self.userSession.userProfile requestSettingEmailAndPasswordWithCredentials:credentials error:nil];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 2u);
    
    // after
    token = nil;
}

@end
