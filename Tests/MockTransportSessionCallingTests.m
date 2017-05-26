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
@import WireMockTransport;

@interface MockTransportSessionCallingTests : MockTransportSessionTests

@end

@implementation MockTransportSessionCallingTests

- (NSDictionary *)responseForSelfUser:(MockUser *)selfUser
                             isJoined:(BOOL)isJoined
                       isSendingVideo:(BOOL)isSendingVideo
                                other:(MockUser*)otherUser
                        otherIsJoined:(BOOL)otherIsJoined
                  otherIsSendingVideo:(BOOL)otherIsSendingVideo
{
    NSString *selfState = isJoined ? @"joined" : @"idle";
    NSString *otherState = otherIsJoined ? @"joined" : @"idle";
    
    NSDictionary *expectedPayload = @{
                                      @"participants": @{
                                              selfUser.identifier : @{
                                                      @"state": selfState,
                                                      @"videod": @(isSendingVideo)
                                                      },
                                              otherUser.identifier : @{
                                                      @"state": otherState,
                                                      @"videod": @(otherIsSendingVideo)
                                                      }
                                              },
                                      @"self": @{
                                              @"state": selfState,
                                              @"videod": @(isSendingVideo)
                                              }
                                      };
    return expectedPayload;
}

- (void)testThatWhenSwitchingTheStateOfACallToJoinedWeSetTheStateAndReceiveTheRightPayloadBack
{
    // GIVEN
    
    
    NSUUID *conversationUUID = [NSUUID createUUID];
    __block MockConversation *oneOnOneConversation;
    __block MockUser *selfUser;
    __block MockUser *user1;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        user1 = [session insertUserWithName:@"Foo"];
        
        oneOnOneConversation = [session insertOneOnOneConversationWithSelfUser:selfUser otherUser:user1];
        oneOnOneConversation.identifier = conversationUUID.transportString;
    }];
    
    //TODO: update expected payload to contain participants
    
    NSDictionary *requestPayload = @{
                                     @"self": @{
                                             @"state": @"joined",
                                             }
                                     };
    NSDictionary *responsePayload = [self responseForSelfUser:selfUser isJoined:YES isSendingVideo:NO
                                                        other:user1 otherIsJoined:NO otherIsSendingVideo:NO];
    
    NSString *path = [NSString stringWithFormat:@"/conversations/%@/call/state", conversationUUID.transportString];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:requestPayload path:path method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(response.payload, responsePayload);
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        NOT_USED(session);
        XCTAssert([oneOnOneConversation.callParticipants containsObject:self.sut.selfUser]);
    }];
}


- (void)testThatWhenSwitchingTheStateOfACallToIdleWeReceiveTheRightPayloadBack

{
    // GIVEN
    NSUUID *conversationUUID = [NSUUID createUUID];
    __block MockConversation *oneOnOneConversation;
    __block MockUser *selfUser;
    __block MockUser *user1;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        user1 = [session insertUserWithName:@"Foo"];
        
        oneOnOneConversation = [session insertOneOnOneConversationWithSelfUser:selfUser otherUser:user1];
        oneOnOneConversation.identifier = conversationUUID.transportString;
    }];
    
    NSDictionary *requestPayload = @{
                                     @"self": @{
                                             @"state": @"idle",
                                             }
                                     };
    
    NSDictionary *responsePayload = [self responseForSelfUser:selfUser isJoined:NO isSendingVideo:NO
                                                        other:user1 otherIsJoined:NO otherIsSendingVideo:NO];

    NSString *path = [NSString stringWithFormat:@"/conversations/%@/call/state", conversationUUID.transportString];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:requestPayload path:path method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(response.payload, responsePayload);
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        NOT_USED(session);
        XCTAssertFalse([oneOnOneConversation.callParticipants containsObject:self.sut.selfUser]);
    }];
}


- (void)testThatWhenJoiningAVideoCallWeGetTheCorrectPayloadBack
{
    // GIVEN
    NSUUID *conversationUUID = [NSUUID createUUID];
    __block MockConversation *oneOnOneConversation;
    __block MockUser *selfUser;
    __block MockUser *user1;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        user1 = [session insertUserWithName:@"Foo"];
        
        oneOnOneConversation = [session insertOneOnOneConversationWithSelfUser:selfUser otherUser:user1];
        oneOnOneConversation.identifier = conversationUUID.transportString;
    }];
    
    NSDictionary *requestPayload = @{
                                     @"self": @{
                                             @"state": @"joined",
                                             @"videod": @1
                                             },
                                     };
    
    NSDictionary *responsePayload = [self responseForSelfUser:selfUser isJoined:YES isSendingVideo:YES
                                                        other:user1 otherIsJoined:NO otherIsSendingVideo:NO];
    
    
    NSString *path = [NSString stringWithFormat:@"/conversations/%@/call/state", conversationUUID.transportString];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:requestPayload path:path method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(response.payload, responsePayload);
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        NOT_USED(session);
        XCTAssertTrue([oneOnOneConversation.callParticipants containsObject:self.sut.selfUser]);
    }];
}


- (void)testThatWhenSwitchingTheStateOfACallToAnInvalidStateWeReceiveA400
{
    // GIVEN
    NSUUID *conversationUUID = [NSUUID createUUID];
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        
        MockUser *selfUser = [session insertSelfUserWithName:@"Me Myself"];
        MockUser *user1 = [session insertUserWithName:@"Foo"];
        
        MockConversation *oneOnOneConversation = [session insertOneOnOneConversationWithSelfUser:selfUser otherUser:user1];
        oneOnOneConversation.identifier = conversationUUID.transportString;
    }];
    
    NSDictionary *requestPayload = @{
                                     @"self": @{
                                             @"state": @"foo",
                                             }
                                     };
    NSString *path = [NSString stringWithFormat:@"/conversations/%@/call/state", conversationUUID.transportString];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:requestPayload path:path method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 400);
    XCTAssertNil(response.payload);
}

- (void)testThatWhenSwitchingTheStateOfACallWithoutSpecifyingTheStateItReturns400
{
    // GIVEN
    NSUUID *conversationUUID = [NSUUID createUUID];
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        
        MockUser *selfUser = [session insertSelfUserWithName:@"Me Myself"];
        MockUser *user1 = [session insertUserWithName:@"Foo"];
        
        MockConversation *oneOnOneConversation = [session insertOneOnOneConversationWithSelfUser:selfUser otherUser:user1];
        oneOnOneConversation.identifier = conversationUUID.transportString;
    }];
    
    NSDictionary *requestPayload = @{
                                     @"self": @{
                                             }
                                     };
    NSString *path = [NSString stringWithFormat:@"/conversations/%@/call/state", conversationUUID.transportString];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:requestPayload path:path method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 400);
    XCTAssertNil(response.payload);
}


- (void)testThatWhenSwitchingTheStateOfAConversationThatDoesNotExistItReturns404
{
    // GIVEN
    NSUUID *conversationUUID = [NSUUID createUUID];
    
    NSDictionary *requestPayload = @{
                                     @"self": @{
                                             @"state": @"idle",
                                             }
                                     };
    NSString *path = [NSString stringWithFormat:@"/conversations/%@/call/state", conversationUUID.transportString];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:requestPayload path:path method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 404);
    XCTAssertNil(response.payload);
}

- (void)testThatWhenRequestingTheStateOfACallItReturnsIdleByDefault
{
    // GIVEN
    NSUUID *conversationUUID = [NSUUID createUUID];
    __block MockUser *selfUser;
    __block MockUser *user1;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        user1 = [session insertUserWithName:@"Foo"];
        
        MockConversation *oneOnOneConversation = [session insertOneOnOneConversationWithSelfUser:selfUser otherUser:user1];
        oneOnOneConversation.identifier = conversationUUID.transportString;
    }];
    
    NSDictionary *responsePayload = [self responseForSelfUser:selfUser isJoined:NO isSendingVideo:NO
                                                        other:user1 otherIsJoined:NO otherIsSendingVideo:NO];
    
    NSString *path = [NSString stringWithFormat:@"/conversations/%@/call/state", conversationUUID.transportString];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(response.payload, responsePayload);
}

- (void)testThatWhenRequestingTheStateOfACallItReturns404IfTheConversationDoesNotExist
{
    // GIVEN
    NSUUID *conversationUUID = [NSUUID createUUID];
    
    NSString *path = [NSString stringWithFormat:@"/conversations/%@/call/state", conversationUUID.transportString];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 404);
    XCTAssertNil(response.payload);
}



- (void)testThatWhenSwitchingTheStateOfACallToJoinedAndRequestingTheStateWeReceiveTheRightPayloadBack
{
    // GIVEN
    NSUUID *conversationUUID = [NSUUID createUUID];
    
    __block MockUser *selfUser;
    __block MockUser *user1;
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        user1 = [session insertUserWithName:@"Foo"];
        
        MockConversation *oneOnOneConversation = [session insertOneOnOneConversationWithSelfUser:selfUser otherUser:user1];
        oneOnOneConversation.identifier = conversationUUID.transportString;
        [oneOnOneConversation addUserToCall:selfUser];
    }];
    
    NSDictionary *responsePayload = [self responseForSelfUser:selfUser isJoined:YES isSendingVideo:NO
                                                        other:user1 otherIsJoined:NO otherIsSendingVideo:NO];
    
    NSString *path = [NSString stringWithFormat:@"/conversations/%@/call/state", conversationUUID.transportString];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(response.payload, responsePayload);
}

- (void)testThatWeCanGetConversationsCall
{
    // GIVEN
    NSUUID *conversationUUID = [NSUUID createUUID];
    __block MockUser *selfUser;
    __block MockUser *user1;

    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        user1 = [session insertUserWithName:@"Foo"];
        
        MockConversation *oneOnOneConversation = [session insertOneOnOneConversationWithSelfUser:selfUser otherUser:user1];
        oneOnOneConversation.identifier = conversationUUID.transportString;
        [oneOnOneConversation addUserToCall:selfUser];
    }];
    
    NSDictionary *responsePayload = [self responseForSelfUser:selfUser isJoined:YES isSendingVideo:NO
                                                        other:user1 otherIsJoined:NO otherIsSendingVideo:NO];
    
    NSString *path = [NSString stringWithFormat:@"/conversations/%@/call", conversationUUID.transportString];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(response.payload, responsePayload);
}

- (void)testThatWeCanGetConversationsVideoCall
{
    // GIVEN
    NSUUID *conversationUUID = [NSUUID createUUID];
    __block MockUser *selfUser;
    __block MockUser *user1;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        user1 = [session insertUserWithName:@"Foo"];
        
        MockConversation *oneOnOneConversation = [session insertOneOnOneConversationWithSelfUser:selfUser otherUser:user1];
        oneOnOneConversation.identifier = conversationUUID.transportString;
        [oneOnOneConversation addUserToVideoCall:selfUser];
        selfUser.isSendingVideo = YES;
    }];
    
    NSDictionary *expectedPayload = @{
                                      @"participants": @{
                                              selfUser.identifier : @{
                                                      @"state": @"joined",
                                                      @"videod": @1
                                                      },
                                              user1.identifier : @{
                                                      @"state": @"idle",
                                                      @"videod": @0
                                                      }
                                              },
                                      @"self": @{
                                              @"state": @"joined",
                                              @"videod": @1
                                              },
                                      };
    NSString *path = [NSString stringWithFormat:@"/conversations/%@/call", conversationUUID.transportString];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(response.payload, expectedPayload);
}

- (void)testThatSettingTheSelfStateOnAGroupConversationReturns200
{
    // GIVEN
    
    NSUUID *conversationUUID = [NSUUID createUUID];
    __block MockUser *selfUser;
    __block MockUser *user1;
    __block MockUser *user2;

    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        user1 = [session insertUserWithName:@"Foo"];
        user2 = [session insertUserWithName:@"Bar"];

        MockConversation *groupConversation = [session insertGroupConversationWithSelfUser:selfUser otherUsers:@[user1, user2]];
        groupConversation.identifier = conversationUUID.transportString;
    }];
    
    NSString *path = [NSString stringWithFormat:@"/conversations/%@/call/state", conversationUUID.transportString];
    NSDictionary *expectedPayload = @{
                              @"self": @{
                                      @"state": @"joined",
                                      @"videod": @0
                                      },
                              @"participants": @{
                                      selfUser.identifier : @{
                                              @"state": @"joined",
                                              @"videod": @0
                                              },
                                      user1.identifier : @{
                                              @"state": @"idle",
                                              @"videod": @0
                                              },
                                      user2.identifier : @{
                                              @"state": @"idle",
                                              @"videod": @0
                                              }
                                      },
                              };
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:expectedPayload path:path method:ZMMethodPUT];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(response.payload, expectedPayload);
}

- (void)testThatGettingTheSelfStateOnAGroupConversationReturns200
{
    // GIVEN
    
    NSUUID *conversationUUID = [NSUUID createUUID];
    __block MockUser *selfUser;
    __block MockUser *user1;
    __block MockUser *user2;
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        
        selfUser = [session insertSelfUserWithName:@"Me Myself"];
        user1 = [session insertUserWithName:@"Foo"];
        user2 = [session insertUserWithName:@"Bar"];
        
        MockConversation *groupConversation = [session insertGroupConversationWithSelfUser:selfUser otherUsers:@[user1, user2]];
        groupConversation.identifier = conversationUUID.transportString;
    }];
    
    NSString *path = [NSString stringWithFormat:@"/conversations/%@/call/state", conversationUUID.transportString];
    NSDictionary *expectedPayload = @{
                                      @"self": @{
                                              @"state": @"idle",
                                              @"videod": @0
                                              },
                                      @"participants": @{
                                              selfUser.identifier : @{
                                                      @"state": @"idle",
                                                      @"videod": @0
                                                      },
                                              user1.identifier : @{
                                                      @"state": @"idle",
                                                      @"videod": @0
                                                      },
                                              user2.identifier : @{
                                                      @"state": @"idle",
                                                      @"videod": @0
                                                      }
                                              },
                                      };
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertEqualObjects(response.payload, expectedPayload);
}

- (void)testThatGettingTheStateOnAGroupConversationDoesNotReturns400
{
    // GIVEN
    
    NSUUID *conversationUUID = [NSUUID createUUID];
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        
        MockUser *selfUser = [session insertSelfUserWithName:@"Me Myself"];
        MockUser *user1 = [session insertUserWithName:@"Foo"];
        
        MockConversation *oneOnOneConversation = [session insertGroupConversationWithSelfUser:selfUser otherUsers:@[user1]];
        oneOnOneConversation.identifier = conversationUUID.transportString;
    }];
    
    NSString *path = [NSString stringWithFormat:@"/conversations/%@/call", conversationUUID.transportString];
    
    // WHEN
    ZMTransportResponse *response = [self responseForPayload:nil path:path method:ZMMethodGET];
    
    // THEN
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertNotNil(response.payload);
}


- (void)testThatAPushEventIsSentWhenSelfUserJoinsVoiceChannel
{
    // GIVEN
    NSUUID *conversationUUID = [NSUUID createUUID];
    
    __block NSString *selfUserID;
    __block NSString *user1ID;
    __block MockConversation *oneOnOneConversation;
    
    
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        
        MockUser *selfUser = [session insertSelfUserWithName:@"Self user"];
        selfUserID = selfUser.identifier;
        MockUser *user1 = [session insertUserWithName:@"Foo"];
        user1ID = user1.identifier;
        
        oneOnOneConversation = [session insertOneOnOneConversationWithSelfUser:self.sut.selfUser otherUser:user1];
        oneOnOneConversation.identifier = conversationUUID.transportString;
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    [self createAndOpenPushChannelAndCreateSelfUser:NO];
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        NOT_USED(session);
        [oneOnOneConversation addUserToCall:self.sut.selfUser];
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    NSDictionary *expectedParticipantsPayload =
    @{
      selfUserID : @{
              @"state": @"joined",
              @"videod": @0
              },
      user1ID : @{
              @"state": @"idle",
              @"videod": @0
              }
      };
    
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 2u);
    TestPushChannelEvent *channelJoinEvent = self.pushChannelReceivedEvents.firstObject;
    XCTAssertEqual(channelJoinEvent.type, ZMTUpdateEventCallState);
    XCTAssertEqualObjects(channelJoinEvent.payload[@"participants"], expectedParticipantsPayload);
    XCTAssertEqualObjects(channelJoinEvent.payload[@"conversation"], conversationUUID.transportString);
    
    TestPushChannelEvent *channelActivatedEvent = self.pushChannelReceivedEvents.lastObject;
    XCTAssertEqual(channelActivatedEvent.type, ZMTUpdateEventConversationVoiceChannelActivate);
    XCTAssertEqualObjects(channelActivatedEvent.payload[@"conversation"], conversationUUID.UUIDString.lowercaseString);
    XCTAssertEqualObjects(channelActivatedEvent.payload[@"from"], selfUserID);
}



- (void)testThatAPushEventIsSentWhenOtherUserJoinsVoiceChannel
{
    // GIVEN
    NSUUID *conversationUUID = [NSUUID createUUID];
    
    __block NSString *selfUserID;
    __block NSString *user1ID;
    __block MockConversation *oneOnOneConversation;
    __block MockUser *user1;
    
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        
        MockUser *selfUser = [session insertSelfUserWithName:@"Self user"];
        selfUserID = selfUser.identifier;
        user1 = [session insertUserWithName:@"Foo"];
        user1ID = user1.identifier;
        
        oneOnOneConversation = [session insertOneOnOneConversationWithSelfUser:self.sut.selfUser otherUser:user1];
        oneOnOneConversation.identifier = conversationUUID.transportString;
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // WHEN
    [self createAndOpenPushChannelAndCreateSelfUser:NO];
    
    [self.sut performRemoteChanges:^(id<MockTransportSessionObjectCreation> session) {
        NOT_USED(session);
        [oneOnOneConversation addUserToCall:user1];
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // THEN
    NSDictionary *expectedParticipantsPayload =
    @{
      selfUserID : @{
              @"state": @"idle",
              @"videod": @0
              },
      user1ID : @{
              @"state": @"joined",
              @"videod": @0
              }
      };
    
    XCTAssertEqual(self.pushChannelReceivedEvents.count, 2u);
    TestPushChannelEvent *channelJoinEvent = self.pushChannelReceivedEvents.firstObject;
    XCTAssertEqual(channelJoinEvent.type, ZMTUpdateEventCallState);
    XCTAssertEqualObjects(channelJoinEvent.payload[@"participants"], expectedParticipantsPayload);
    XCTAssertEqualObjects(channelJoinEvent.payload[@"conversation"], conversationUUID.transportString);
    
    TestPushChannelEvent *channelActivatedEvent = self.pushChannelReceivedEvents.lastObject;
    XCTAssertEqual(channelActivatedEvent.type, ZMTUpdateEventConversationVoiceChannelActivate);
    XCTAssertEqualObjects(channelActivatedEvent.payload[@"conversation"], conversationUUID.UUIDString.lowercaseString);
    XCTAssertEqualObjects(channelActivatedEvent.payload[@"from"], user1ID);
}

@end
