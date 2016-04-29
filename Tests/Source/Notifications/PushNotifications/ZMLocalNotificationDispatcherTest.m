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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


@import ZMTransport;
@import ZMCDataModel;

#import "MessagingTest.h"
#import "ZMLocalNotificationDispatcher+Testing.h"
#import "ZMLocalNotification.h"
#import "ZMBadge.h"
#import "MessagingTest+EventFactory.h"

@interface ZMLocalNotificationDispatcherTest : MessagingTest
@property (nonatomic) ZMLocalNotificationDispatcher *sut;
@property (nonatomic) ZMConversation *conversation1;
@property (nonatomic) ZMConversation *conversation2;

@property (nonatomic) ZMUser *user1;
@property (nonatomic) ZMUser *user2;

@property (nonatomic) ZMUser *selfUser;
@property (nonatomic) id mockUISharedApplication;

@end



@implementation ZMLocalNotificationDispatcherTest

- (void)setUp
{
    [super setUp];
    
    self.mockUISharedApplication = [OCMockObject mockForClass:UIApplication.class];
    [self verifyMockLater:self.mockUISharedApplication];
    
    self.sut = [[ZMLocalNotificationDispatcher alloc] initWithManagedObjectContext:self.syncMOC sharedApplication:self.mockUISharedApplication];
    
    self.conversation1 = [self insertConversationWithRemoteID:[NSUUID createUUID] name:@"Conversation 1"];
    self.conversation2 = [self insertConversationWithRemoteID:[NSUUID createUUID] name:@"Conversation 2"];
    self.user1 = [self insertUserWithRemoteID:[NSUUID createUUID] name:@"User 1"];
    self.user2 = [self insertUserWithRemoteID:[NSUUID createUUID] name:@"User 2"];

    self.selfUser = [ZMUser selfUserInContext:self.syncMOC];
    self.selfUser.remoteIdentifier = [NSUUID createUUID];
    
    [self.conversation1 addParticipant:self.user1];
    [self.conversation2 addParticipant:self.user1];
    [self.conversation2 addParticipant:self.user2];
}

- (void)tearDown
{
    [self.syncMOC zm_tearDownCallTimer];
    [self.mockUISharedApplication stopMocking];
    self.mockUISharedApplication = nil;
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self.sut tearDown];
    self.sut = nil;
    [super tearDown];
}

- (ZMConversation *)insertConversationWithRemoteID:(NSUUID *)uuid name:(NSString *)userDefinedName {
    __block ZMConversation *conversation;
    
    [self.syncMOC performGroupedBlockAndWait:^{
        conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.remoteIdentifier = uuid;
        conversation.userDefinedName = userDefinedName;
        conversation.conversationType =  ZMConversationTypeGroup;
        [self.syncMOC saveOrRollback];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    return conversation;
}

- (ZMUser *)insertUserWithRemoteID:(NSUUID *)uuid name:(NSString *)name
{
    __block ZMUser *user;
    [self.syncMOC performGroupedBlockAndWait:^{
        user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        user.name = name;
        user.remoteIdentifier = uuid;
        
        [self.syncMOC saveOrRollback];
    }];
    
    return user;
}

- (NSMutableDictionary *)payloadForSelfUserJoiningCallInConversation:(ZMConversation *)conversation state:(NSString *)state
{
    NSUUID *convRemoteID = conversation.remoteIdentifier ?: [NSUUID createUUID];
    NSUUID *selfUserUUID = NSUUID.createUUID;
    
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.remoteIdentifier = selfUserUUID;
        [self.syncMOC saveOrRollback];
    }];
    
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    return [@{
              @"type": @"call.state",
              @"conversation": convRemoteID,
              @"self" :@{},
              @"participants": @{selfUserUUID.transportString: @{@"state": state}},
              } mutableCopy];
}

- (ZMConversation *)conversationFromNotification:(UILocalNotification *)note
{
    NSString *objectIDString = note.userInfo[ZMLocalNotificationConversationObjectURLKey];
    NSManagedObjectID *objectID = [self.syncMOC.persistentStoreCoordinator managedObjectIDForURIRepresentation:[[NSURL alloc] initWithString:objectIDString]];
    return (id) [self.syncMOC objectWithID:objectID];
}

@end

@implementation ZMLocalNotificationDispatcherTest (Tests)

- (void)testThatItCreatesNotifications
{
    // given
    NSDictionary *data = @{@"content" : @"hallo"};
    ZMUpdateEvent *event = [self eventWithPayload:data inConversation:self.conversation1 type:EventConversationAdd];
    
    // expect
    __block UILocalNotification *scheduledNotification;
    [[self.mockUISharedApplication expect] scheduleLocalNotification:ZM_ARG_SAVE(scheduledNotification)];
    
    // when
    [self.sut didReceiveUpdateEvents:@[event]];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertNotNil(scheduledNotification);
    
    // after
    [[self.mockUISharedApplication stub] cancelLocalNotification:OCMOCK_ANY];
}


- (void)testThatItAddsNotificationsOfDifferentConversationsToTheList
{
    // given
    NSDictionary *data = @{@"content" : @"hallo"};
    
    ZMUpdateEvent *event1 = [self eventWithPayload:data inConversation:self.conversation1 type:EventConversationAdd];
    ZMUpdateEvent *event2 = [self eventWithPayload:data inConversation:self.conversation2 type:EventConversationAdd];

    // expect
    __block UILocalNotification *notification1;
    __block UILocalNotification *notification2;
    [[self.mockUISharedApplication expect] scheduleLocalNotification:ZM_ARG_SAVE(notification1)];
    [[self.mockUISharedApplication expect] scheduleLocalNotification:ZM_ARG_SAVE(notification2)];
    
    // when
    [self.sut didReceiveUpdateEvents:@[event1,event2]];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertNotNil(notification1);
    XCTAssertNotNil(notification2);
    XCTAssertEqualObjects([self conversationFromNotification:notification1], self.conversation1);
    XCTAssertEqualObjects([self conversationFromNotification:notification2], self.conversation2);
    
    // after (teardown)
    [[self.mockUISharedApplication stub] cancelLocalNotification:OCMOCK_ANY];
}

- (void)testThatItDoesNotCreateANotificationForAnUnsupportedEventType
{
    // given
    ZMUpdateEvent *event = [self eventWithPayload:nil inConversation:self.conversation1 type:EventConversationTyping];
    XCTAssertNotNil(event);
    
    // expect
    [[self.mockUISharedApplication reject] scheduleLocalNotification:OCMOCK_ANY];
    
    // when
    [self.sut didReceiveUpdateEvents:@[event]];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatItResetsTheNotificationArrayWhenNotificationsAreCancelled
{
    // given
    NSDictionary *data = @{@"content" : @"hallo"};

    
    ZMUpdateEvent *event1 = [self eventWithPayload:data inConversation:self.conversation1 type:EventConversationAdd];
    ZMUpdateEvent *event2 = [self eventWithPayload:data inConversation:self.conversation2 type:EventConversationAdd];
    
    // expect
    __block UILocalNotification *scheduledNotification1;
    __block UILocalNotification *scheduledNotification2;
    [[self.mockUISharedApplication expect] scheduleLocalNotification:ZM_ARG_SAVE(scheduledNotification1)];
    [[self.mockUISharedApplication expect] scheduleLocalNotification:ZM_ARG_SAVE(scheduledNotification2)];
    
    // when
    [self.sut didReceiveUpdateEvents:@[event1,event2]];
    WaitForAllGroupsToBeEmpty(0.5);
    [self.mockUISharedApplication verify];
    
    // expect
    [[self.mockUISharedApplication expect] cancelLocalNotification:ZM_ARG_CHECK_IF_EQUAL(scheduledNotification1)];
    [[self.mockUISharedApplication expect] cancelLocalNotification:ZM_ARG_CHECK_IF_EQUAL(scheduledNotification2)];
    
    // when
    [self.sut cancelAllNotifications];
    
    // after (teardown)
    [[self.mockUISharedApplication stub] cancelLocalNotification:OCMOCK_ANY];


}

- (void)testThatItCancelsNotificationsOnlyForASpecificConversation
{
    // given
    NSDictionary *data = @{@"content" : @"hallo"};

    ZMUpdateEvent *event1 = [self eventWithPayload:data inConversation:self.conversation1 type:EventConversationAdd];
    ZMUpdateEvent *event2 = [self callStateEventInConversation:self.conversation1 joinedUsers:@[self.user1] videoSendingUsers:@[] sequence:nil];

    ZMUpdateEvent *event3 = [self eventWithPayload:data inConversation:self.conversation2 type:EventConversationAdd];
    ZMUpdateEvent *event4 = [self callStateEventInConversation:self.conversation2 joinedUsers:@[self.user2] videoSendingUsers:@[] sequence:nil];
    // expect
    __block UILocalNotification *scheduledNotification1;
    __block UILocalNotification *scheduledNotification2;
    __block UILocalNotification *scheduledNotification3;
    __block UILocalNotification *scheduledNotification4;
    
    __block UILocalNotification *canceledNotification1;
    __block UILocalNotification *canceledNotification2;
    
    [[self.mockUISharedApplication expect] scheduleLocalNotification:ZM_ARG_SAVE(scheduledNotification1)];
    [[self.mockUISharedApplication expect] scheduleLocalNotification:ZM_ARG_SAVE(scheduledNotification2)];
    [[self.mockUISharedApplication expect] scheduleLocalNotification:ZM_ARG_SAVE(scheduledNotification3)];
    [[self.mockUISharedApplication expect] scheduleLocalNotification:ZM_ARG_SAVE(scheduledNotification4)];
    
    // when
    [self.sut didReceiveUpdateEvents:@[event1, event2, event3, event4]];
    WaitForAllGroupsToBeEmpty(0.5);
    // when
    
    [[self.mockUISharedApplication expect] cancelLocalNotification:ZM_ARG_SAVE(canceledNotification1)];
    [[self.mockUISharedApplication expect] cancelLocalNotification:ZM_ARG_SAVE(canceledNotification2)];
    
    [self.sut cancelNotificationForConversation:self.conversation1];
    
    // then
    XCTAssertEqualObjects([self conversationFromNotification:scheduledNotification1], self.conversation1);
    XCTAssertEqualObjects([self conversationFromNotification:scheduledNotification2], self.conversation1);
    XCTAssertEqualObjects([self conversationFromNotification:scheduledNotification3], self.conversation2);
    XCTAssertEqualObjects([self conversationFromNotification:scheduledNotification4], self.conversation2);

    XCTAssertEqualObjects([self conversationFromNotification:canceledNotification1], self.conversation1);
    XCTAssertEqualObjects([self conversationFromNotification:canceledNotification2], self.conversation1);
    
    // after
    [[self.mockUISharedApplication stub] cancelLocalNotification:OCMOCK_ANY];
    [self.mockUISharedApplication verify];
}


- (void)testThatItCancelsNotificationsForCallStateSelfUserJoinedEvents
{
    // given
    ZMUpdateEvent *callEvent = [self callStateEventInConversation:self.conversation1 othersAreJoined:YES selfIsJoined:NO otherIsSendingVideo:NO selfIsSendingVideo:NO sequence:nil];
    ZMUpdateEvent *selfUserJoinsCallEvent = [self callStateEventInConversation:self.conversation1 othersAreJoined:YES selfIsJoined:YES otherIsSendingVideo:NO selfIsSendingVideo:NO sequence:nil];
    
    // expect
    __block UILocalNotification *scheduledNotification1;
    __block UILocalNotification *canceledNotification1;
    
    [[self.mockUISharedApplication expect] scheduleLocalNotification:ZM_ARG_SAVE(scheduledNotification1)];
    [[self.mockUISharedApplication expect] cancelLocalNotification:ZM_ARG_SAVE(canceledNotification1)];
    
    [self.sut didReceiveUpdateEvents:@[callEvent]];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    [self.sut didReceiveUpdateEvents:@[selfUserJoinsCallEvent]];
    WaitForAllGroupsToBeEmpty(0.5);

    [self.mockUISharedApplication verify];
    
    // then
    XCTAssertEqualObjects([self conversationFromNotification:scheduledNotification1], self.conversation1);
    XCTAssertEqualObjects([self conversationFromNotification:canceledNotification1], self.conversation1);
    
    // after
    [[self.mockUISharedApplication stub] cancelLocalNotification:OCMOCK_ANY];
}

- (void)testThatItDoesNotCancelNotificationsForCallStateSelfUserIdleEvents
{
    // given
    ZMUpdateEvent *callEvent = [self callStateEventInConversation:self.conversation2 joinedUsers:@[self.user1] videoSendingUsers:@[] sequence:nil];
    ZMUpdateEvent *selfUserDoesNotJoinCallEvent = [self callStateEventInConversation:self.conversation2 joinedUsers:@[self.user1, self.user2] videoSendingUsers:@[] sequence:nil];
    
    // expect
    __block UILocalNotification *scheduledNotification1;
    
    [[self.mockUISharedApplication expect] scheduleLocalNotification:ZM_ARG_SAVE(scheduledNotification1)];
    
    [self.sut didReceiveUpdateEvents:@[callEvent]];
    WaitForAllGroupsToBeEmpty(0.5);
    
    [[self.conversation2 mutableOrderedSetValueForKey:@"callParticipants"] addObject:self.user1];

    // when
    [self.sut didReceiveUpdateEvents:@[selfUserDoesNotJoinCallEvent]];
    WaitForAllGroupsToBeEmpty(0.5);

    [self.mockUISharedApplication verify];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqualObjects([self conversationFromNotification:scheduledNotification1], self.conversation2);
    
    // after
    [[self.mockUISharedApplication stub] cancelLocalNotification:OCMOCK_ANY];
}

- (void)testThatItCancelsNotificationsWhenReceivingANotificationThatTheCallWasIgnored
{
    // given
    ZMUpdateEvent *callEvent = [self callStateEventInConversation:self.conversation2 joinedUsers:@[self.user1] videoSendingUsers:@[] sequence:nil];
    self.conversation2.isIgnoringCall = YES;
    
    // expect
    __block UILocalNotification *scheduledNotification1;
    [[self.mockUISharedApplication expect] scheduleLocalNotification:ZM_ARG_SAVE(scheduledNotification1)];
    [[self.mockUISharedApplication expect] cancelLocalNotification:ZM_ARG_SAVE(scheduledNotification1)];

    [self.sut didReceiveUpdateEvents:@[callEvent]];
    WaitForAllGroupsToBeEmpty(0.5);
    [self expectationForNotification:ZMConversationCancelNotificationForIncomingCallNotificationName object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        return (notification.object == self.conversation2 );
    }];
    
    // when
    [[NSNotificationCenter defaultCenter] postNotificationName:ZMConversationCancelNotificationForIncomingCallNotificationName object:self.conversation2];
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
    
    [self.mockUISharedApplication verify];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects([self conversationFromNotification:scheduledNotification1], self.conversation2);
}

- (ZMLocalNotificationForExpiredMessage *)createAndFireLocalNotificationForFailedMessageInConversation:(ZMConversation *)conversation
{
    ZMMessage *message = [ZMMessage insertNewObjectInManagedObjectContext:self.syncMOC];
    [conversation.mutableMessages addObject:message];
    
    ZMLocalNotificationForExpiredMessage *customNote = [[ZMLocalNotificationForExpiredMessage alloc] initWithExpiredMessage:message];
    
    // make sure it generates the one we want
    id mockLocalNote = [OCMockObject mockForClass:ZMLocalNotificationForExpiredMessage.class];
    [[[[mockLocalNote expect] classMethod] andReturn:mockLocalNote] alloc];
    (void) [[[mockLocalNote expect] andReturn:customNote] initWithExpiredMessage:message];
    
    [[self.mockUISharedApplication expect] scheduleLocalNotification:customNote.uiNotification];
    
    // generate
    [self.sut didFailToSentMessage:message];
    
    // double check
    [mockLocalNote verify];
    [self.mockUISharedApplication verify];
    
    // stop mocking
    [mockLocalNote stopMocking];
    
    return customNote;
}

- (void)testThatWhenFailingAMessageItSchedulesANotification
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMMessage *message = [ZMMessage insertNewObjectInManagedObjectContext:self.syncMOC];
        [self.conversation1.mutableMessages addObject:message];
        UILocalNotification *note = (id) @"foo";
        
        id mockLocalNote = [OCMockObject mockForClass:ZMLocalNotificationForExpiredMessage.class];
        
        //expect
        [[[[mockLocalNote expect] classMethod] andReturn:mockLocalNote] alloc];
        (void) [[[mockLocalNote expect] andReturn:mockLocalNote] initWithExpiredMessage:message];
        [[[mockLocalNote stub] andReturn:note] uiNotification];
        [[self.mockUISharedApplication expect] scheduleLocalNotification:note];
        
        // when
        [self.sut didFailToSentMessage:message];
        
        // after
        [mockLocalNote verify];
        [mockLocalNote stopMocking];
        
    }];
    
    // after
    [[self.mockUISharedApplication stub] cancelLocalNotification:OCMOCK_ANY];
}

- (void)testThatItCancelsAllNotificationsForFailingMessagesWhenCancelingAllNotifications
{
    // given
    ZMLocalNotificationForExpiredMessage *note1 = [self createAndFireLocalNotificationForFailedMessageInConversation:self.conversation1];
    ZMLocalNotificationForExpiredMessage *note2 = [self createAndFireLocalNotificationForFailedMessageInConversation:self.conversation2];

    // expect
    [[self.mockUISharedApplication expect] cancelLocalNotification:note1.uiNotification];
    [[self.mockUISharedApplication expect] cancelLocalNotification:note2.uiNotification];
    
    // when
    [self.sut cancelAllNotifications];
    
    // then
    [self.mockUISharedApplication verify];
}


- (void)testThatItCancelsNotificationsForFailingMessagesWhenCancelingNotificationsForASpecificConversation
{
    // given
    ZMLocalNotificationForExpiredMessage *note1 = [self createAndFireLocalNotificationForFailedMessageInConversation:self.conversation1];
    ZMLocalNotificationForExpiredMessage *note2 = [self createAndFireLocalNotificationForFailedMessageInConversation:self.conversation2];
    
    // expect
    [[self.mockUISharedApplication expect] cancelLocalNotification:note1.uiNotification];
    
    // when
    [self.sut cancelNotificationForConversation:self.conversation1];
    
    // then
    [self.mockUISharedApplication verify];
    
    // after
    [[self.mockUISharedApplication stub] cancelLocalNotification:note2.uiNotification];
}

- (NSDictionary *)payloadForEncryptedOTRMessageWithText:(NSString *)text nonce:(NSUUID *)nonce
{
    ZMGenericMessage *message = [ZMGenericMessage messageWithText:text nonce:nonce.transportString];
    NSString *base64EncodedString = message.data.base64String;
    return @{@"data": base64EncodedString,
             @"conversation" : self.conversation1.remoteIdentifier.transportString,
             @"type": EventConversationAddOTRMessage,
             @"from": self.user1.remoteIdentifier.transportString
             };
}

- (void)testThatItCanParseGenericMessages
{
    // given
    NSDictionary *payload = [self payloadForEncryptedOTRMessageWithText:@"Hallo" nonce:[NSUUID UUID]];
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:nil];
    
    // expect
    __block UILocalNotification *scheduledNotification;
    [[self.mockUISharedApplication expect] scheduleLocalNotification:ZM_ARG_SAVE(scheduledNotification)];
    
    // when
    [self.sut didReceiveUpdateEvents:@[event]];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertNotNil(scheduledNotification);
    
    // after
    [[self.mockUISharedApplication stub] cancelLocalNotification:OCMOCK_ANY];
}


- (void)testThatItDoesNotAddMessageAddEventsWithANonceThatAlreadyExists
{
    // given
    NSDictionary *data = @{@"content" : @"hallo", @"nonce": [NSUUID UUID].transportString };
    ZMUpdateEvent *event = [self eventWithPayload:data inConversation:self.conversation1 type:EventConversationAdd];
    
    __block BOOL didScheduleOnce = NO;
    // expect
    [[self.mockUISharedApplication stub] scheduleLocalNotification:[OCMArg checkWithBlock:^BOOL(id obj) {
        NOT_USED(obj);
        if (didScheduleOnce) {
            return NO;
        }
        didScheduleOnce = YES;
        return YES;
    }]];

    // when receiving the first time, it schedules
    [self.sut didReceiveUpdateEvents:@[event]];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when receiving a second time it doesn't
    [self.sut didReceiveUpdateEvents:@[event]];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    [[self.mockUISharedApplication stub] cancelLocalNotification:OCMOCK_ANY];
}

@end
