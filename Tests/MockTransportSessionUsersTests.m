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

@interface MockTransportSessionUsersTests : MockTransportSessionTests

@end

@implementation MockTransportSessionUsersTests

- (void)testCreatingAndRequestingSeveralUsers;
{
    // given
    __block MockUser *selfUser;
    __block MockUser *user1;
    __block MockUser *user2;
    __block MockUser *user3;
    
    __block MockConnection *connection1;
    __block MockConnection *connection2;
    __block MockConnection *connection3;
    
    __block NSString *user1ID;
    __block NSString *user2ID;
    __block NSString *user3ID;
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        user1 = [session insertUserWithName:@"Bar"];
        user1.email = @"";
        user1.accentID = 2;
        user1.phone = @"";
        user1ID = user1.identifier;
        
        connection1 = [session insertConnectionWithSelfUser:selfUser toUser:user1];
        connection1.status = @"accepted";
        connection1.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399920861.091];
        
        user2 = [session insertUserWithName:@"Baz"];
        user2.email = @"";
        user2.accentID = 3;
        user2.phone = @"";
        user2ID = user2.identifier;
        
        connection2 = [session insertConnectionWithSelfUser:selfUser toUser:user2];
        connection2.status = @"accepted";
        connection2.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399920870.091];
        
        user3 = [session insertUserWithName:@"Quux"];
        user3.email = @"";
        user3.accentID = 1;
        user3.phone = @"";
        user3ID = user3.identifier;
        
        connection3 = [session insertConnectionWithSelfUser:selfUser toUser:user3];
        connection3.status = @"accepted";
        connection3.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399920880.091];
        
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSString *path = [NSString stringWithFormat:@"/users/?ids=%@,%@,%@", [user1ID lowercaseString], [user2ID uppercaseString], user3ID];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // then
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    XCTAssertTrue([response.payload isKindOfClass:[NSArray class]]);
    
    NSArray *data = (id) response.payload;
    XCTAssertEqual(data.count, 3u);
    
    if (3 <= data.count) {
        [self checkThatTransportData:data[0] matchesUser:user1 isConnected:YES failureRecorder:NewFailureRecorder()];
        [self checkThatTransportData:data[1] matchesUser:user2 isConnected:YES failureRecorder:NewFailureRecorder()];
        [self checkThatTransportData:data[2] matchesUser:user3 isConnected:YES failureRecorder:NewFailureRecorder()];
    }
}

- (void)testCreatingAndRequestingSelfUser;
{
    // given
    __block MockUser *selfUser;
    __block NSString *trackingIdentifier;
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        selfUser.email = @"foo@example.com";
        selfUser.phone = @"+4555575653498";
        selfUser.accentID = 4;
        trackingIdentifier = [selfUser.trackingIdentifier copy];
        XCTAssertEqual(selfUser.trackingIdentifier.length, 36u);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSString *path = @"/self";
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // then
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    XCTAssertTrue([response.payload isKindOfClass:[NSDictionary class]]);
    NSDictionary *data = (id) response.payload;
    
    [self checkThatTransportData:data matchesUser:selfUser isConnected:YES failureRecorder:NewFailureRecorder()];
    XCTAssertEqualObjects([data stringForKey:@"tracking_id"], trackingIdentifier);
}

- (void)testThatItCreatesHandleForSelfUser
{
    // given
    __block MockUser *selfUser;
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSString *path = @"/self";
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // then
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    XCTAssertTrue([response.payload isKindOfClass:[NSDictionary class]]);
    NSDictionary *data = (id) response.payload;
    XCTAssertNotNil([data stringForKey:@"handle"]);
    XCTAssertGreaterThan([data stringForKey:@"handle"].length, 5u);
}

- (void)testThatItCreatesHandleForAnyUser
{
    // given
    __block MockUser *user;
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        user = [session insertUserWithName:@"Foo"];
        user.identifier = [NSUUID createUUID].transportString;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSString *path = [@"/users/" stringByAppendingPathComponent:user.identifier];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // then
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    XCTAssertTrue([response.payload isKindOfClass:[NSDictionary class]]);
    NSDictionary *data = (id) response.payload;
    XCTAssertNotNil([data stringForKey:@"handle"]);
    XCTAssertGreaterThan([data stringForKey:@"handle"].length, 5u);
}


- (void)testCreatingAndRequestingConnectedUser;
{
    // given
    __block MockUser *selfUser;
    __block MockUser *user1;
    
    __block MockConnection *connection1;
    __block NSString *user1ID;
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        user1 = [session insertUserWithName:@"Bar"];
        user1.email = @"barfooz@example.com";
        user1.accentID = 7;
        user1.phone = @"+4954334535345345345";
        [session addProfilePictureToUser:user1];
        [user1.managedObjectContext obtainPermanentIDsForObjects:@[user1] error:NULL];
        user1ID = user1.identifier;
        
        connection1 = [session insertConnectionWithSelfUser:selfUser toUser:user1];
        connection1.status = @"accepted";
        connection1.lastUpdate = [NSDate dateWithTimeIntervalSince1970:1399920861.091];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSString *path = [@"/users/" stringByAppendingPathComponent:user1ID];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // then
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    XCTAssertTrue([response.payload isKindOfClass:[NSDictionary class]]);
    NSDictionary *data = (id) response.payload;
    
    [self checkThatTransportData:data matchesUser:user1 isConnected:YES failureRecorder:NewFailureRecorder()];
}

- (void)testCreatingAndRequestingNonConnectedUser;
{
    // given
    __block MockUser *selfUser;
    __block MockUser *user1;
    
    __block NSString *user1ID;
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        user1 = [session insertUserWithName:@"Bar"];
        user1.email = @"barfooz@example.com";
        user1.accentID = 7;
        user1.phone = @"+4954334535345345345";
        [session addProfilePictureToUser:user1];
        [user1.managedObjectContext obtainPermanentIDsForObjects:@[user1] error:NULL];
        user1ID = user1.identifier;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSString *path = [@"/users/" stringByAppendingPathComponent:user1ID];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // then
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.transportSessionError);
    XCTAssertTrue([response.payload isKindOfClass:[NSDictionary class]]);
    NSDictionary *data = (id) response.payload;
    
    [self checkThatTransportData:data matchesUser:user1 isConnected:NO failureRecorder:NewFailureRecorder()];
}

- (void)testThatItUpdatesTheSelfUserOnPUT
{
    // given
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        selfUser.accentID = 8;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDictionary *payload = @{
                              @"name" : @"This is the new name",
                              @"accent_id" : @"4"
                              };
    
    // when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/self" method:ZMMethodPUT];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(response.payload);
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        NOT_USED(session);
        XCTAssertEqualObjects(selfUser.name, payload[@"name"]);
        XCTAssertEqual(selfUser.accentID, [payload[@"accent_id"] integerValue] );
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

@end



@implementation MockTransportSessionUsersTests (UserProfileUpdate)

- (void)testThatItPutsTheEmail
{
    // given
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
    }];
    NSString *email = @"foo@bar.bar";
    
    // when
    ZMTransportResponse *response = [self responseForPayload:@{@"email":email} path:@"/self/email" method:ZMMethodPUT];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 200);
    // this will send out a validation email, not set the email directly, so we can't test that the email changed on the user
    XCTAssertNil(self.sut.selfUser.email);
}

- (void)testThatDoesNotPutTheEmailAndReturns400IfTheEmailIsMissing
{
    // given
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
    }];
    
    // when
    ZMTransportResponse *response = [self responseForPayload:@{} path:@"/self/email" method:ZMMethodPUT];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 400);
    XCTAssertNil(self.sut.selfUser.email);
}

- (void)testThatItDoesNotPutTheEmailAndReturns409IfThereIsAlreadyAUserWithThatEmail
{
    // given
    __block MockUser *selfUser;
    NSString *email = @"foo@bar.bar";
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        MockUser *otherUser = [session insertUserWithName:@"Beth"];
        otherUser.email = email;
    }];
    
    // when
    ZMTransportResponse *response = [self responseForPayload:@{@"email":email} path:@"/self/email" method:ZMMethodPUT];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 409);
    XCTAssertNil(self.sut.selfUser.email);
}

- (void)testThatItPutsThePassword
{
    // given
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
    }];
    NSString *password = @"12%$#%";
    
    // when
    ZMTransportResponse *response = [self responseForPayload:@{@"new_password":password} path:@"/self/password" method:ZMMethodPUT];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(self.sut.selfUser.password, password);
}

- (void)testThatDoesNotPutThePasswordAndReturns400IfThePasswordlIsMissing
{
    // given
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
    }];
    
    // when
    ZMTransportResponse *response = [self responseForPayload:@{} path:@"/self/passwprd" method:ZMMethodPUT];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 400);
}

- (void)testThatItDoesNotPutThePasswordIfthePasswordIsAlreadyThereAndTheOldPasswordDoesNotMatch
{
    // given
    __block MockUser *selfUser;
    NSString *formerPassword = @"324324234";
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        selfUser.password = formerPassword;
    }];
    NSString *password = @"12%$#%";
    
    // when
    ZMTransportResponse *response = [self responseForPayload:@{@"old_password":password, @"new_password":password} path:@"/self/password" method:ZMMethodPUT];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 403);
    XCTAssertEqualObjects(self.sut.selfUser.password, formerPassword);
}

- (void)testThatItDoesPutThePasswordIfthePasswordIsAlreadyAndTheOldPasswordMatches
{
    // given
    __block MockUser *selfUser;
    NSString *formerPassword = @"324324234";
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        selfUser.password = formerPassword;
    }];
    NSString *password = @"12%$#%";
    
    // when
    ZMTransportResponse *response = [self responseForPayload:@{@"old_password":formerPassword, @"new_password":password} path:@"/self/password" method:ZMMethodPUT];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(self.sut.selfUser.password, password);
}

- (void)testThatItPostsARequestToGetTheProfilePhoneCodeAndUsesItToActivateThePhone
{
    // given
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
    }];
    NSString *phone = @"+99123245";
    
    // when
    ZMTransportResponse *response = [self responseForPayload:@{@"phone":phone} path:@"/self/phone" method:ZMMethodPUT];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertTrue([self.sut.phoneNumbersWaitingForVerificationForProfile containsObject:phone]);
    
    // and when
    response = [self responseForPayload:@{@"phone":phone, @"code":self.sut.phoneVerificationCodeForUpdatingProfile} path:@"/activate" method:ZMMethodPOST];

    // then
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertFalse([self.sut.phoneNumbersWaitingForVerificationForProfile containsObject:phone]);

}

- (void)testThatItPostsARequestToGetTheProfilePhoneCodeAndReturns409IfDuplicated
{
    // given
    __block MockUser *selfUser;
    NSString *phone = @"+99123245";
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        MockUser *otherUser = [session insertUserWithName:@"Gabrielle"];
        otherUser.phone = phone;
    }];
    
    // when
    ZMTransportResponse *response = [self responseForPayload:@{@"phone":phone} path:@"/self/phone" method:ZMMethodPUT];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 409);
    XCTAssertFalse([self.sut.phoneNumbersWaitingForVerificationForProfile containsObject:phone]);
}

- (void)testThatDoesNotPutThePhoneAndReturns400IfThePhonelIsMissing
{
    // given
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
    }];
    
    // when
    ZMTransportResponse *response = [self responseForPayload:@{} path:@"/self/phone" method:ZMMethodPUT];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 400);
}

- (void)testThatItPutsTheHandle
{
    // given
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
    }];
    NSString *handle = @"aaa12";
    
    // when
    ZMTransportResponse *response = [self responseForPayload:@{@"handle":handle} path:@"/self/handle" method:ZMMethodPUT];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(selfUser.handle, handle);
}

- (void)testThatDoesNotPutTheHandleIfItExistsAlready
{
    // given
    __block MockUser *selfUser;
    __block MockUser *otherUser;
    NSString *initialHandle = @"initial33";
    NSString *handle = @"foobar22222";
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Foo"];
        selfUser.handle = initialHandle;
        otherUser = [session insertUserWithName:@"The other"];
        otherUser.handle = handle;
    }];
    
    // when
    ZMTransportResponse *response = [self responseForPayload:@{@"handle":handle} path:@"/self/handle" method:ZMMethodPUT];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 409);
    XCTAssertEqualObjects(response.payloadLabel, @"key-exists");
    XCTAssertEqualObjects(selfUser.handle, initialHandle);
    XCTAssertEqualObjects(otherUser.handle, handle);

}

- (void)testThatItFindsAnExhistingHandle_GET
{
    // given
    NSString *handle = @"foobar22222";
    __block MockUser *user;
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        user = [session insertUserWithName:@"The other"];
        user.handle = handle;
    }];
    
    // when
    NSString *path = [@"/users/handles/" stringByAppendingPathComponent:handle];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 200);
    [self checkThatTransportData:response.payload matchesUser:user isConnected:NO failureRecorder:NewFailureRecorder()];
}

- (void)testThatItFindsAnExhistingHandle_HEAD
{
    // given
    NSString *handle = @"foobar22222";
    __block MockUser *user;
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        user = [session insertUserWithName:@"The other"];
        user.handle = handle;
    }];
    
    // when
    NSString *path = [@"/users/handles/" stringByAppendingPathComponent:handle];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodHEAD];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(response.rawResponse.URL.path, path);
    [self checkThatTransportData:response.payload matchesUser:user isConnected:NO failureRecorder:NewFailureRecorder()];
}

- (void)testThatItDoesNotFindANonExhistingHandle
{
    // given
    NSString *handle = @"foobar22222";
    
    // when
    NSString *path = [@"/users/handles/" stringByAppendingPathComponent:handle];
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 404);
    XCTAssertEqualObjects(response.rawResponse.URL.path, path);
}

@end

@implementation MockTransportSessionUsersTests (OTR)

- (void)testThatItReturnsUserClientsKeys
{
    __block MockUser *selfUser;
    __block MockUser *otherUser;
    __block MockUser *thirdUser;
    __block MockUserClient *selfClient;
    __block MockUserClient *otherUserClient;
    __block MockUserClient *secondOtherUserClient;
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"foo"];
        otherUser = [session insertUserWithName:@"bar"];
        thirdUser = [session insertUserWithName:@"foobar"];
        selfClient = [session registerClientForUser:selfUser label:@"self1" type:@"permanent"];
        otherUserClient = [session registerClientForUser:otherUser label:@"other1" type:@"permanent"];
        secondOtherUserClient = [session registerClientForUser:otherUser label:@"other2" type:@"permanent"];
    }];
    
    NSString *redunduntClientId = [NSString createAlphanumericalString];
    NSDictionary *payload = @{selfUser.identifier: @[selfClient.identifier, redunduntClientId], otherUser.identifier: @[otherUserClient.identifier, secondOtherUserClient.identifier], thirdUser.identifier: @[redunduntClientId]};
    
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/users/prekeys" method:ZMMethodPOST];
    XCTAssertEqual(response.HTTPStatus, 200);

    NSArray *exepctedUsers = @[selfUser.identifier, otherUser.identifier];
    AssertDictionaryHasKeys(response.payload.asDictionary, exepctedUsers);
    NSArray *expectedClients = @[selfClient.identifier];
    AssertDictionaryHasKeys(response.payload.asDictionary[selfUser.identifier], expectedClients);
    expectedClients = @[otherUserClient.identifier, secondOtherUserClient.identifier];
    AssertDictionaryHasKeys(response.payload.asDictionary[otherUser.identifier], expectedClients);
}

@end

