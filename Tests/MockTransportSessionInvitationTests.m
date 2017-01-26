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

@interface MockTransportSessionInvitationTests : MockTransportSessionTests

@end

@implementation MockTransportSessionInvitationTests

- (void)testThatPostingAnInvitationCreatesIt;
{
    //given
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Jean-Nobert"];
        selfUser.identifier = [[NSUUID createUUID] transportString];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDictionary *payload = @{@"inviter_name" : selfUser.name, @"message": @"Norbette je t'aime", @"invitee_name" : @"Norbette", @"email": @"norbette@wire.com"};
    
    //when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/invitations" method:ZMMethodPOST];
    
    //then
    XCTAssertNotNil(response);
    if (!response) {
        return;
    }
    
    XCTAssertEqual(response.HTTPStatus, 201);
    
    NSDictionary *responsePayload = [response.payload asDictionary];
    
    XCTAssertNotNil(responsePayload[@"id"]);
    XCTAssertNotNil(responsePayload[@"created_at"]);
    XCTAssertEqualObjects(responsePayload[@"inviter"], selfUser.identifier);
    XCTAssertEqualObjects(responsePayload[@"name"], payload[@"invitee_name"]);
    XCTAssertEqualObjects([responsePayload stringForKey:@"email"], [payload stringForKey:@"email"]);
}

- (void)testThatPostingAnInvitationWithoutEmailNorPhoneFails;
{
    //given
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Jean-Nobert"];
        selfUser.identifier = [[NSUUID createUUID] transportString];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDictionary *payload = @{@"inviter_name" : selfUser.name, @"message": @"Norbette je t'aime", @"invitee_name" : @"Norbette"};
    
    //when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/invitations" method:ZMMethodPOST];
    
    //then
    XCTAssertNotNil(response);
    if (!response) return;
    
    XCTAssertEqual(response.HTTPStatus, 400);
}

- (void)testThatPostingAnInvitationWithExistingUserAndNonExistingConnectionReturnsACreatedConnectionInHeader;
{
    //given
    __block MockUser *selfUser;
    __block MockUser *existingUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Jean-Nobert"];
        selfUser.identifier = [[NSUUID createUUID] transportString];
        
        existingUser = [session insertUserWithName:@"Barbie"];
        existingUser.identifier = [[NSUUID createUUID] transportString];
        existingUser.email = @"barbie@wire.com";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDictionary *payload = @{@"inviter_name" : selfUser.name, @"message": @"Barbie je t'aime", @"invitee_name" : existingUser.name, @"email" : existingUser.email};
    
    //when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/invitations" method:ZMMethodPOST];
    
    //then
    XCTAssertNotNil(response);
    if (!response) return;
    
    XCTAssertEqual(response.HTTPStatus, 201);
    XCTAssertNil(response.payload);
    XCTAssertNotNil(response.headers[@"Location"]);
}

- (void)testThatPostingAnInvitationWithExistingUserAndExistingConnectionReturnsConnectionLocationInHeader;
{
    //given
    __block MockUser *selfUser;
    __block MockUser *existingUser;
    __block MockConnection *connection;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Jean-Nobert"];
        selfUser.identifier = [[NSUUID createUUID] transportString];
        
        existingUser = [session insertUserWithName:@"Barbie"];
        existingUser.identifier = [[NSUUID createUUID] transportString];
        existingUser.email = @"barbie@wire.com";
        
        connection = [session insertConnectionWithSelfUser:selfUser toUser:existingUser];
        
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSDictionary *payload = @{@"inviter_name" : selfUser.name, @"message": @"Barbie je t'aime", @"invitee_name" : existingUser.name, @"email" : existingUser.email};
    
    //when
    ZMTransportResponse *response = [self responseForPayload:payload path:@"/invitations" method:ZMMethodPOST];
    
    //then
    XCTAssertNotNil(response);
    if (!response) return;
    
    XCTAssertEqual(response.HTTPStatus, 303);
    XCTAssertNil(response.payload);
    XCTAssertTrue([response.headers[@"Location"] containsString:connection.to.identifier]);
}

- (void)testThatDeletingNonExistingInvitationFails;
{
    //given
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Jean-Nobert"];
        selfUser.identifier = [[NSUUID createUUID] transportString];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    //when
    ZMTransportResponse *response = [self responseForPayload:nil path:@"invitations/someid" method:ZMMethodDELETE];
    
    //then
    XCTAssertNotNil(response);
    if (!response) return;
    
    XCTAssertEqual(response.HTTPStatus, 404);
}

- (void)testThatDeletingWihoutAnIDFails;
{
    //given
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Jean-Nobert"];
        selfUser.identifier = [[NSUUID createUUID] transportString];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    //when
    ZMTransportResponse *response = [self responseForPayload:nil path:@"/invitations/" method:ZMMethodDELETE];
    
    //then
    XCTAssertNotNil(response);
    if (!response) return;
    
    XCTAssertEqual(response.HTTPStatus, 404);
}

- (void)testThatDeletingInvitationSucceedWithExistingInvitation;
{
    //given
    __block MockUser *selfUser;
    __block MockPersonalInvitation *invitation;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Jean-Nobert"];
        selfUser.identifier = [[NSUUID createUUID] transportString];
        NSString *inviteeName = [[NSUUID createUUID] transportString];
        invitation = [MockPersonalInvitation invitationInMOC:self.sut.managedObjectContext fromUser:selfUser toInviteeWithName:inviteeName email:[inviteeName stringByAppendingString:@"@wire.com"] phoneNumber:nil];
        
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertNotNil(invitation.identifier); //invitation exist
    
    //when
    ZMTransportResponse *response = [self responseForPayload:nil path:[NSString stringWithFormat:@"/invitations/%@", invitation.identifier] method:ZMMethodDELETE];
    
    //then
    XCTAssertNotNil(response);
    if (!response) return;
    
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNil(invitation.identifier); // invitation's deleted
}

- (void)testThatGroupedGetRequestReturnsAllInvitation;
{
    //given
    __block MockUser *selfUser;
    __block NSMutableArray *invitations = [NSMutableArray array];
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        
        selfUser = [session insertSelfUserWithName:@"Jean-Nobert"];
        selfUser.identifier = [[NSUUID createUUID] transportString];
        
        for (int i = 0; i < 10; ++i) {
            NSString *name = [NSUUID createUUID].transportString;
            MockPersonalInvitation *invitation = [session insertInvitationForSelfUser:selfUser inviteeName:name mail:[name stringByAppendingString:@"@wire.com"] phone:nil];
            [invitations addObject:invitation];
        }
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    //when
    ZMTransportResponse *response = [self responseForPayload:nil path:@"/invitations" method:ZMMethodGET];
    
    //then
    XCTAssertNotNil(response);
    if (!response) return;
    
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqual([response.payload asArray].count, invitations.count);
}

- (void)testThatGroupedGetReturnAnEmptyListIfNoInvitations;
{
    //given
    
    //when
    ZMTransportResponse *response = [self responseForPayload:nil path:@"/invitations" method:ZMMethodGET];
    
    //then
    XCTAssertNotNil(response);
    if (!response) return;
    
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqual([response.payload asArray].count, 0lu);
}

- (void)testThatGettingInvitationWithNotExistingIDFails;
{
    //given
    __block MockUser *selfUser;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Jean-Nobert"];
        selfUser.identifier = [[NSUUID createUUID] transportString];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    //when
    ZMTransportResponse *response = [self responseForPayload:nil path:[NSString stringWithFormat:@"/invitations/someid"] method:ZMMethodGET];
    
    //then
    XCTAssertNotNil(response);
    if (!response) return;
    
    XCTAssertEqual(response.HTTPStatus, 404);
}

- (void)testThatGettingSingleInvitationWithCorrectIDReturnsData;
{
    //given
    __block MockUser *selfUser;
    __block MockPersonalInvitation *invitation;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        selfUser = [session insertSelfUserWithName:@"Jean-Nobert"];
        selfUser.identifier = [[NSUUID createUUID] transportString];
        NSString *inviteeName = [[NSUUID createUUID] transportString];
        invitation = [MockPersonalInvitation invitationInMOC:self.sut.managedObjectContext fromUser:selfUser toInviteeWithName:inviteeName email:[inviteeName stringByAppendingString:@"@wire.com"] phoneNumber:nil];
        
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertNotNil(invitation.identifier); //invitation exist
    
    //when
    ZMTransportResponse *response = [self responseForPayload:nil path:[NSString stringWithFormat:@"/invitations/%@", invitation.identifier] method:ZMMethodGET];
    
    //then
    XCTAssertNotNil(response);
    if (!response) return;
    
    NSDictionary *payload = [response.payload asDictionary];
    
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(invitation.identifier, payload[@"id"]); // invitation's deleted
    XCTAssertEqualObjects(selfUser.identifier, payload[@"inviter"]); // invitation's deleted
    XCTAssertEqualObjects(invitation.inviteeName, payload[@"name"]); // invitation's deleted
    XCTAssertEqualObjects(invitation.inviteeEmail, payload[@"email"]); // invitation's deleted
    XCTAssertEqualObjects([invitation.creationDate transportString], payload[@"created_at"]); // invitation's deleted
    XCTAssertEqualObjects(payload[@"phone"], [NSNull null]); // invitation's deleted
}


@end
