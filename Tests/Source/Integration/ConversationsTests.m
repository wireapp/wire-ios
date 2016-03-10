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


@import zmessaging;
@import ZMTransport;
@import ZMCMockTransport;
@import ZMUtilities;

#import "MessagingTest.h"
#import "ZMUserSession.h"
#import "ZMUser+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "IntegrationTestBase.h"
#import "ZMMessage+Internal.h"
#import "ZMNotifications.h"
#import "ZMTestNotifications.h"
#import "ZMUserSession+Internal.h"
#import "ZMConversationList+Internal.h"
#import "ZMConversationListDirectory.h"
#import "ZMConversationMessageWindow.h"
#import "ZMConversation+Internal.h"
#import "ZMConversationTranscoder+Internal.h"
#import "MockConversationWindowObserver.h"
#import "ZMVoiceChannel+Testing.h"
#import <zmessaging/zmessaging-Swift.h>
#import "ConversationTestsBase.h"

@interface ZMConversationList (ObjectIDs)

@end

@implementation ZMConversationList (ObjectIDs)

- (NSArray <NSManagedObjectID *> *)objectIDs {
    return [self mapWithBlock:^NSManagedObjectID *(ZMConversation *conversation) {
        return conversation.objectID;
    }];
}

@end


@interface ConversationTests : ConversationTestsBase

@property (nonatomic) NSUInteger previousZMConversationTranscoderListPageSize;

@end


#pragma mark - Conversation tests
@implementation ConversationTests

- (void)testThatItCallsInitialSyncDone
{
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
}

- (void)testThatAConversationIsResyncedAfterRestartingFromScratch
{
    NSString *conversationName = @"My conversation";
    {
        // Create a UI context
        XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
        // Get the users:
        ZMUser *user1 = [self userForMockUser:self.user1];
        XCTAssertNotNil(user1);
        ZMUser *user2 = [self userForMockUser:self.user2];
        XCTAssertNotNil(user2);
        
        // Create a conversation
        __block ZMConversation *conversation;
        [self.userSession performChanges:^{
            conversation = [ZMConversation insertGroupConversationIntoUserSession:self.userSession withParticipants:@[user1, user2]];
            conversation.userDefinedName = conversationName;
        }];
        
        // Wait for merge ui->sync to be done
        WaitForEverythingToBeDone();
        XCTAssert([self waitOnMainLoopUntilBlock:^BOOL{
            return conversation.lastModifiedDate != nil;
        } timeout:0.5]);
    }
    
    // Tears down context(s) &
    // Re-create contexts
    [self recreateUserSessionAndWipeCache:YES];
    
    {
        // Wait for sync to be done
        XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
        WaitForEverythingToBeDone();
        
        // Check that conversation is there
        ZMConversation *conversation = [[ZMConversationList conversationsInUserSession:self.userSession] firstObjectMatchingWithBlock:^BOOL(ZMConversation *c) {
            return [c.userDefinedName isEqual:conversationName];
        }];
        XCTAssertNotNil(conversation);
    }
}


- (void)testThatChangeToAConversationNameIsResyncedAfterRestartingFromScratch;
{
    NSString *name = @"My New Name";
    {
        // Create a UI context
        XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
        // Get the group conversation
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        XCTAssertNotNil(conversation);
        // Change the name & save
        conversation.userDefinedName = name;
        [self.userSession saveOrRollbackChanges];
        XCTAssertFalse(conversation.hasChanges, @"Rollback?");
        XCTAssertTrue([conversation hasLocalModificationsForKey:ZMConversationUserDefinedNameKey]);
        
        // Wait for merge ui->sync to be done
        WaitForEverythingToBeDone();
        
        XCTAssertFalse([conversation hasLocalModificationsForKey:ZMConversationUserDefinedNameKey]);
    }
    
    // Tears down context(s) &
    // Re-create contexts
    [self recreateUserSessionAndWipeCache:YES];
    
    // Wait for sync to be done
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    
    // Check that conversation name is updated:
    {
        // Get the group conversation
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        XCTAssertEqualObjects(conversation.userDefinedName, name);
    }
}

- (void)testThatChangeToAConversationNameIsNotResyncedIfNil;
{
    ZMConversation *conversation = nil;
    
    NSString *name = nil;
    NSString *formerName = nil;
    {
        // Create a UI context
        XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
        // Get the group conversation
        [self.mockTransportSession resetReceivedRequests];
        conversation = [self conversationForMockConversation:self.groupConversation];
        
        XCTAssertNotNil(conversation);
        // Change the name & save
        formerName = conversation.userDefinedName;
        conversation.userDefinedName = name;
        [self.userSession saveOrRollbackChanges];
        XCTAssertFalse(conversation.hasChanges, @"Rollback?");
        XCTAssertTrue([conversation hasLocalModificationsForKey:ZMConversationUserDefinedNameKey]);
        
        // Wait for merge ui->sync to be done
        WaitForAllGroupsToBeEmpty(0.5);
        ZMConversation *syncConversation = [self.syncMOC objectWithID:conversation.objectID];
        
        XCTAssertFalse([syncConversation hasLocalModificationsForKey:ZMConversationUserDefinedNameKey]);
        XCTAssertFalse([conversation hasLocalModificationsForKey:ZMConversationUserDefinedNameKey]);
        XCTAssertEqual(self.mockTransportSession.receivedRequests.count, 0lu);
    }
    
    // Tears down context(s) &
    // Re-create contexts
    [self recreateUserSessionAndWipeCache:YES];
    
    // Wait for sync to be done
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    
    // Check that conversation name is updated:
    {
        // Get the group conversation
        conversation = [self conversationForMockConversation:self.groupConversation];
        XCTAssertEqualObjects(conversation.userDefinedName, formerName);
    }
}


- (void)testThatRemovingParticipantsFromAConversationIsSynchronizedWithBackend
{
    {
        XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
        
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        XCTAssertNotNil(conversation);
        
        ZMUser *user = [self userForMockUser:self.user3];
        
        XCTAssertTrue([conversation.activeParticipants containsObject:user]);
        [self.userSession performChanges:^{
            [conversation removeParticipant:user];

        }];
        XCTAssertFalse([conversation.activeParticipants containsObject:user]);

        // Wait for merge ui->sync to be done
        WaitForEverythingToBeDone();
    }

    // Tears down context(s) &
    // Re-create contexts
    [self recreateUserSessionAndWipeCache:YES];
    XCTAssert([self logInAndWaitForSyncToBeComplete]);
    
    // Wait for sync to be done
    WaitForEverythingToBeDone();
    
    {
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        XCTAssertNotNil(conversation);
        ZMUser *user = [self userForMockUser:self.user3];

        XCTAssertFalse([conversation.activeParticipants containsObject:user]);
        XCTAssertTrue([conversation.inactiveParticipants containsObject:user]);
    }
    
}



- (void)testThatAddingParticipantsToAConversationIsSynchronizedWithBackend
{

    __block MockUser *connectedUserNotInConv;
    {
        [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
            connectedUserNotInConv = [session insertUserWithName:@"Connected user which originally is not in conversation"];
            connectedUserNotInConv.email = @"connectedUserNotInConv@example.com";
            connectedUserNotInConv.phone = @"23498579";
            [self storeRemoteIDForObject:connectedUserNotInConv];
            
            MockConversation *selfToConnectedNotInConvConversation = [session insertOneOnOneConversationWithSelfUser:self.selfUser otherUser:connectedUserNotInConv];
            selfToConnectedNotInConvConversation.creator = self.selfUser;
            
            MockConnection *connectionSelfToConnectedUserNotInConv = [session insertConnectionWithSelfUser:self.selfUser toUser:connectedUserNotInConv];
            connectionSelfToConnectedUserNotInConv.status = @"accepted";
            connectionSelfToConnectedUserNotInConv.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-3];
            connectionSelfToConnectedUserNotInConv.conversation = selfToConnectedNotInConvConversation;
        }];
        
        XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
        
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        XCTAssertNotNil(conversation);
        
        ZMUser *user = [self userForMockUser:connectedUserNotInConv];
        
        XCTAssertFalse([conversation.activeParticipants containsObject:user]);
        [self.userSession performChanges:^{
            [conversation addParticipant:user];
        }];
        XCTAssertTrue([conversation.activeParticipants containsObject:user]);
        
        // Wait for merge ui->sync to be done
        WaitForEverythingToBeDone();
    }
    
    // Tears down context(s) &
    // Re-create contexts
    [self recreateUserSessionAndWipeCache:YES];
    XCTAssert([self logInAndWaitForSyncToBeComplete]);
    
    // Wait for sync to be done
    WaitForEverythingToBeDone();
    
    {
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        XCTAssertNotNil(conversation);
        
        ZMUser *user = [self userForMockUser:connectedUserNotInConv];
        
        XCTAssertTrue([conversation.activeParticipants containsObject:user]);
        XCTAssertFalse([conversation.inactiveParticipants containsObject:user]);
    }
    
}

@end

@implementation ConversationTests (DisplayName)

- (void)testThatReceivingAPushEventForNameChangeChangesTheConversationName
{
    
    // given

    // Create a UI context
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    // Get the group conversation
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(conversation);
    XCTAssertEqualObjects(conversation.userDefinedName, @"Group conversation");
    
    // when
    NSString *newConversationName = @"New Conversation Name";

    ConversationChangeObserver *observer = [[ConversationChangeObserver alloc] initWithConversation:conversation];
    [observer clearNotifications];
    
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> * ZM_UNUSED session) {
        [self.groupConversation changeNameByUser:self.user3 name:newConversationName];
    }];
    
    // then
    XCTAssertTrue([self waitOnMainLoopUntilBlock:^BOOL{
        return observer.notifications.count >= 1;
    } timeout:0.5]);
    
    XCTAssertEqualObjects(conversation.userDefinedName, newConversationName);
    [observer tearDown];

}

@end



@implementation ConversationTests (Messages)

- (void)testThatItAppendsMessages
{
    NSString *expectedText1 = @"The sky above the port was the color of ";
    NSString *expectedText2 = @"television, tuned to a dead channel.";
    
    NSUUID *nonce1 = [NSUUID createUUID];
    NSUUID *nonce2 = [NSUUID createUUID];
    
    [self testThatItAppendsMessageToConversation:self.groupConversation
                                        withBlock:^NSArray *(id __unused session){
                                            [self.groupConversation insertTextMessageFromUser:self.user2 text:expectedText1 nonce:nonce1];
                                            [self spinMainQueueWithTimeout:0.2];
                                            [self.groupConversation insertTextMessageFromUser:self.user3 text:expectedText2 nonce:nonce2];
                                            return @[nonce1, nonce2];
                                        } verify:^(ZMConversation *conversation){
                                            ZMTextMessage *msg1 = conversation.messages[conversation.messages.count - 2];
                                            XCTAssertEqualObjects(msg1.text, expectedText1);
                                            ZMTextMessage *msg2 = conversation.messages[conversation.messages.count - 1];
                                            XCTAssertEqualObjects(msg2.text, expectedText2);
                                        }];
}

- (void)testThatItAppendsClientMessages
{
    NSString *expectedText1 = @"The sky above the port was the color of ";
    NSString *expectedText2 = @"television, tuned to a dead channel.";

    NSUUID *nonce1 = [NSUUID createUUID];
    NSUUID *nonce2 = [NSUUID createUUID];

    ZMGenericMessage *genericMessage1 = [ZMGenericMessage messageWithText:expectedText1 nonce:nonce1.transportString];
    ZMGenericMessage *genericMessage2 = [ZMGenericMessage messageWithText:expectedText2 nonce:nonce2.transportString];
    
    [self testThatItAppendsMessageToConversation:self.groupConversation
                                        withBlock:^NSArray *(id __unused session){
                                            [self.groupConversation insertClientMessageFromUser:self.user2 data:genericMessage1.data];
                                            [self spinMainQueueWithTimeout:0.2];
                                            [self.groupConversation insertClientMessageFromUser:self.user3 data:genericMessage2.data];
                                            return @[nonce1, nonce2];
                                        } verify:^(ZMConversation *conversation) {
                                            ZMClientMessage *msg1 = conversation.messages[conversation.messages.count - 2];
                                            XCTAssertEqualObjects(msg1.nonce, nonce1);
                                            XCTAssertEqualObjects(msg1.genericMessage.text.content, expectedText1);
                                            
                                            ZMClientMessage *msg2 = conversation.messages[conversation.messages.count - 1];
                                            XCTAssertEqualObjects(msg2.nonce, nonce2);
                                            XCTAssertEqualObjects(msg2.genericMessage.text.content, expectedText2);
                                        }];
}


- (MockPushEvent *)lastEventForConversation:(MockConversation *)conversation inReceivedEvents:(NSArray *)receivedEvents
{
    __block MockPushEvent *event;
    [receivedEvents enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(MockPushEvent *anEvent, NSUInteger idx, BOOL *stop){
        NOT_USED(idx);
        if ([anEvent.payload[@"conversation"] isEqualToString:conversation.identifier]) {
            *stop = YES;
            event = anEvent;
        }
    }];
    return event;
}


- (void)testThatMessageIsSentIfNoPreviousPendingMessagesInConversation
{
    //given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);
    
    [self.userSession performChanges:^{
        [conversation appendMessagesWithText:@"lalala"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    //when
    // no pending pessages in conversation
    __block id<ZMConversationMessage> message;
    [self.userSession performChanges:^{
        message = [conversation appendMessagesWithText:@"bar"].firstObject;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    //then
    MockPushEvent *lastEvent = [self lastEventForConversation:self.selfToUser1Conversation inReceivedEvents:self.mockTransportSession.updateEvents];
    XCTAssertNotNil(lastEvent);
}

- (void)testThatAMessageIsSentAfterAnImage
{
    //given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);

    __block ZMMessage *imageMessage;
    [self.userSession performChanges:^{
        imageMessage = [conversation appendMessageWithImageData:[self verySmallJPEGData]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    //when
    __block ZMMessage *textMessage;
    [self.userSession performChanges:^{
        textMessage = [conversation appendMessagesWithText:@"lalala"].firstObject;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    
    //then
    XCTAssertEqual(imageMessage.deliveryState, ZMDeliveryStateDelivered);
    XCTAssertEqual(textMessage.deliveryState, ZMDeliveryStateDelivered);
}

- (void)testThatNextMessageIsSentAfterPreviousMessageInConversationIsDelivered
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);
    NSString *conversationID = self.selfToUser1Conversation.identifier;
    NSString *conversationMessagePath = [NSString stringWithFormat:@"/conversations/%@/otr/messages", conversationID];
    
    //when
    //there is previous pending message

    //we block first request from finishing and check that no other requests are coming in
    __block ZMTransportRequest *firstRequest;
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        //we should not receieve another request until we finish this one
        if(![request.path isEqualToString:conversationMessagePath]) {
            return nil;
        }
        XCTAssertNil(firstRequest);
        firstRequest = request;
        return ZMCustomResponseGeneratorReturnResponseNotCompleted;
    };
    __block id<ZMConversationMessage> message;
    __block id<ZMConversationMessage> secondMessage;
    [self.userSession performChanges:^{
        message = [conversation appendMessagesWithText:@"foo1"].firstObject;
        [self spinMainQueueWithTimeout:0.5];
        secondMessage = [conversation appendMessagesWithText:@"foo2"].firstObject;
    }];
    
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5f]);
    WaitForAllGroupsToBeEmpty(0.5f);

    //then
    NSArray *conversationMessageRequests = [self.mockTransportSession.receivedRequests filterWithBlock:^BOOL(ZMTransportRequest *req) {
        return [req.path isEqualToString:conversationMessagePath] && req != firstRequest;
    }];
    XCTAssertEqual(conversationMessageRequests.count, 0u);

    //when
    //finally finish request
    self.mockTransportSession.responseGeneratorBlock = nil;
    [self.mockTransportSession completePreviouslySuspendendRequest:firstRequest];
    WaitForAllGroupsToBeEmpty(0.5f);
    
    //then
    //we check that the second message is delivered
    NSArray *laterConversationMessageRequests = [self.mockTransportSession.receivedRequests filterWithBlock:^BOOL(ZMTransportRequest *req) {
        return [req.path isEqualToString:conversationMessagePath] && req != firstRequest;
    }];
    XCTAssertEqual(laterConversationMessageRequests.count, 1u);
}

- (void)testThatNextClientMessageIsSentAfterPreviousMessageInConversationIsDelivered
{
    //given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);
    [self.mockTransportSession resetReceivedRequests];
    
    //when
    //there is previous pending message
    
    //we block first request from finishing and check that no other requests are comming in
    __block ZMTransportRequest *firstRequest;
    XCTestExpectation *firstRequestRecievedExpectation = [self expectationWithDescription:@"Recieved request to add first message"];
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        //we should not recieve another request until we finish this one
        if ([request.path containsString:@"client-messages"]) {
            XCTAssertNil(firstRequest);
            firstRequest = request;
            [firstRequestRecievedExpectation fulfill];
        }
        return ZMCustomResponseGeneratorReturnResponseNotCompleted;
    };
    __block ZMMessage *message;
    __block ZMMessage *secondMessage;
    ZMGenericMessage *genericMessage = [ZMGenericMessage messageWithText:@"foo1" nonce:[NSUUID createUUID].transportString];
    ZMGenericMessage *secondGenericMessage = [ZMGenericMessage messageWithText:@"foo2" nonce:[NSUUID createUUID].transportString];
    
    [self.userSession performChanges:^{
        message = [conversation appendClientMessageWithData:genericMessage.data];
        [self spinMainQueueWithTimeout:0.1];
        secondMessage = [conversation appendClientMessageWithData:secondGenericMessage.data];
    }];
    
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5f]);
    WaitForAllGroupsToBeEmpty(0.5f);
    
    //then
    ZMTransportRequest *lastRequest = [[self.mockTransportSession receivedRequests] lastObject];
    XCTAssertEqualObjects(lastRequest, firstRequest);
    
    //when
    //finally finish request
    self.mockTransportSession.responseGeneratorBlock = nil;
    [self.mockTransportSession completePreviouslySuspendendRequest:firstRequest];
    
    WaitForAllGroupsToBeEmpty(0.5f);
    
    //then
    //we check that the second message is delivered
    NSMutableArray *lastEvents = [self.mockTransportSession.updateEvents mutableCopy];
    MockPushEvent *lastEvent = [self lastEventForConversation:self.selfToUser1Conversation inReceivedEvents:lastEvents];
    NSString *lastMessageContent = [[[lastEvent payload] asDictionary] valueForKeyPath:@"data"];
    XCTAssertEqualObjects(lastMessageContent, [secondGenericMessage.data base64EncodedStringWithOptions:0]);
    
    [lastEvents removeObject:lastEvent];
    
    MockPushEvent *beforeLastEvent = [self lastEventForConversation:self.selfToUser1Conversation inReceivedEvents:lastEvents];
    NSString *firstMessageContent = [[[beforeLastEvent payload] asDictionary] valueForKeyPath:@"data"];
    XCTAssertEqualObjects(firstMessageContent, [genericMessage.data base64EncodedStringWithOptions:0]);
}

- (void)testThatItSendsMessagesFromDifferentConversationsInParallel
{
    //given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);

    ZMConversation *anotherConversation = [self conversationForMockConversation:self.selfToUser2Conversation];
    XCTAssertNotNil(anotherConversation);

    //we block first request from finishing and check that no other requests are comming in
    __block NSInteger recievedRequests = 0;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Recieved requests for both messages"];
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(__unused ZMTransportRequest *request) {
        //we should not recieve another request untill we finish this one
        if ([request.path.lastPathComponent containsString:@"messages"]) {
            recievedRequests++;
        }
        if (recievedRequests == 2) {
            [expectation fulfill];
        }
        return ZMCustomResponseGeneratorReturnResponseNotCompleted;
    };
    
    //when
    __block ZMMessage *message;
    __block ZMMessage *secondMessage;
    [self.userSession performChanges:^{
        message = [conversation appendMessagesWithText:@"lalala"].firstObject;
        secondMessage = [anotherConversation appendMessagesWithText:@"lalala"].firstObject;
    }];
    
    //expect
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5f]);
}

- (void)testThatItSendsANotificationWhenRecievingATextMessageThroughThePushChannel
{
    NSString *expectedText = @"The sky above the port was the color of ";
    NSUUID *nonce = [NSUUID createUUID];
    
    [self testThatItSendsANotificationInConversation:self.groupConversation
                                      ignoreLastRead:NO
                           onRemoteMessageCreatedWith:^{
                               [self.groupConversation insertTextMessageFromUser:self.user2 text:expectedText nonce:nonce];
                           } verify:^(ZMConversation *conversation) {
                               ZMTextMessage *msg = conversation.messages[conversation.messages.count - 1];
                               XCTAssertEqualObjects(msg.text, expectedText);
                           }];
}

- (void)testThatItSendsANotificationWhenRecievingAClientMessageThroughThePushChannel
{
    NSString *expectedText = @"The sky above the port was the color of ";
    ZMGenericMessage *message = [ZMGenericMessage messageWithText:expectedText nonce:[NSUUID createUUID].transportString];

    [self testThatItSendsANotificationInConversation:self.groupConversation
                                      ignoreLastRead:NO
                           onRemoteMessageCreatedWith:^{
                               [self.groupConversation insertClientMessageFromUser:self.user2 data:message.data];
                           } verify:^(ZMConversation *conversation) {
                               ZMClientMessage *msg = conversation.messages[conversation.messages.count - 1];
                               XCTAssertEqualObjects(msg.genericMessage.text.content, expectedText);
                           }];
}

- (void)testThatItSendsANotificationWhenReceivingAnImageThroughThePushChannelWithoutBeingRequested
{
    [self testThatItSendsANotificationInConversation:self.groupConversation
                                      ignoreLastRead:NO
                          onRemoteMessageCreatedWith:^{
                              [self.groupConversation insertImageEventsFromUser:self.user2];
                          } verify:^(ZMConversation *conversation) {
                              ZMImageMessage *msg = conversation.messages.lastObject;
                              XCTAssertEqual(msg.deliveryState, ZMDeliveryStateDelivered);
                              XCTAssertEqual(msg.mediumData.length, (NSUInteger) 0);
                              XCTAssertEqual(msg.previewData.length, (NSUInteger) 7583);
                          }];
}

- (void)testThatItSendsANotificationWhenReceivingAnImageThroughThePushChannelWhenBeingRequested
{
    [self testThatItSendsANotificationInConversation:self.groupConversation
                                      ignoreLastRead:NO
                          onRemoteMessageCreatedWith:^{
                              [self.groupConversation insertImageEventsFromUser:self.user2];
                          } verify:^(ZMConversation *conversation) {
                              ZMImageMessage *msg = conversation.messages.lastObject;
                              [msg requestFullContent];
                              WaitForAllGroupsToBeEmpty(0.5);
                              XCTAssertEqual(msg.deliveryState, ZMDeliveryStateDelivered);
                              XCTAssertEqual(msg.mediumData.length, (NSUInteger) 419976);
                              XCTAssertEqual(msg.previewData.length, (NSUInteger) 7583);
                          }];
}

- (void)testThatItSendsANotificationWhenReceivingImageMediumAndPreviewInDifferentOrderThroughThePushChannel
{
    NSUUID *nonce = [NSUUID createUUID];
    NSUUID *correlationID = [NSUUID createUUID];
    
    [self testThatItSendsANotificationInConversation:self.groupConversation
                                     afterLoginBlock:^{
                                         [self.groupConversation insertPreviewImageEventFromUser:self.user2 correlationID:correlationID none:nonce];
                                         [self.syncMOC saveOrRollback];
                                     } onRemoteMessageCreatedWith:^{
                                         [self.groupConversation insertMediumImageEventFromUser:self.user2 correlationID:correlationID none:nonce];
                                     } verifyWithObserver:^(ZMConversation *conversation, ConversationChangeObserver *observer) {
                                         ZMImageMessage *msg = conversation.messages.lastObject;
                                         [msg requestFullContent];
                                         WaitForAllGroupsToBeEmpty(0.5);
                                         XCTAssertEqual(observer.notifications.count, 1u);
                                         XCTAssertEqual(msg.deliveryState, ZMDeliveryStateDelivered);
                                         XCTAssertEqual(msg.mediumData.length, 419976u);
                                         XCTAssertEqual(msg.previewData.length, 7583u);
                                     }];
}

- (void)testThatItSendsANotificationWhenReceivingTheImageEventsAfterOneAnotherThroughThePushChannel
{

    // given
    self.registeredOnThisDevice = YES;
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    
    // need to fault conversation and messages in order to receive notifications
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    (void) conversation.userDefinedName;
    XCTAssertEqual(conversation.messages.count, 0u);

    ConversationChangeObserver *observer = [[ConversationChangeObserver alloc] initWithConversation:conversation];
    ZMImageMessage *msg;
    NSUUID *nonce = [NSUUID createUUID];
    NSUUID *correlationID = [NSUUID createUUID];
    
    
    // when we insert a previewImage
    {
        [observer clearNotifications];
        
        [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> * ZM_UNUSED session) {
            [self.groupConversation insertPreviewImageEventFromUser:self.user2 correlationID:correlationID none:nonce];
            [self spinMainQueueWithTimeout:0.2];
        }];
        
        WaitForEverythingToBeDone();
    }
    
    
    // then we should receive a conversation change notification about the inserted message
    {
        XCTAssertEqual(observer.notifications.count, 1u);
        
        ConversationChangeInfo *note = observer.notifications.firstObject;
        XCTAssertNotNil(note);
        XCTAssertEqualObjects(note.conversation, conversation);
        
        XCTAssertTrue(note.lastModifiedDateChanged);
        XCTAssertTrue(note.unreadCountChanged);
        XCTAssertEqual(conversation.messages.count, 1u);
        
        msg = conversation.messages.lastObject;
        XCTAssertEqual(msg.deliveryState, ZMDeliveryStateDelivered);
        XCTAssertEqual(msg.mediumData.length, (NSUInteger) 0);
        XCTAssertEqual(msg.previewData.length, (NSUInteger) 7583);
    }
    
    
    // when we insert the medium image
    {
        [observer clearNotifications];
        
        [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> * ZM_UNUSED session) {
            [self.groupConversation insertMediumImageEventFromUser:self.user2 correlationID:correlationID none:nonce];
        }];
        
        WaitForEverythingToBeDone();
    }
    
    
    // then we should receive a notification. however, the message count should not change, the preexisting message should be updated
    {
        XCTAssertGreaterThanOrEqual(observer.notifications.count, 1u);
    
        ConversationChangeInfo *note = observer.notifications.firstObject;
        XCTAssertTrue(note.lastModifiedDateChanged);
        XCTAssertEqual(conversation.messages.count, 1u);
        XCTAssertEqual(msg.deliveryState, ZMDeliveryStateDelivered);
        XCTAssertEqual(msg.mediumData.length, (NSUInteger) 0);
        XCTAssertEqual(msg.previewData.length, (NSUInteger) 7583);
    }
    [observer tearDown];
}

- (void)testThatItSendsANotificationWhenSendingAnImage
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    // need to fault conversation
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    (void) conversation.displayName;
    // fault relationship
    for(ZMMessage *msg in conversation.messages) {
        (void) msg.nonce;
    }
    
    
    // when
    ConversationChangeObserver *observer = [[ConversationChangeObserver alloc] initWithConversation:conversation];
    [observer clearNotifications];
    
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> * ZM_UNUSED session) {
        [self.groupConversation insertImageEventsFromUser:self.selfUser];
    }];
    
    WaitForEverythingToBeDone();
    
    // then
    XCTAssertGreaterThanOrEqual(observer.notifications.count, 1u);
    
    ConversationChangeInfo *note = observer.notifications.firstObject;
    XCTAssertNotNil(note);
    XCTAssertTrue(note.messagesChanged);
    XCTAssertFalse(note.participantsChanged);
    XCTAssertFalse(note.nameChanged);
    XCTAssertTrue(note.lastModifiedDateChanged);
    XCTAssertTrue(note.unreadCountChanged);
    XCTAssertFalse(note.connectionStateChanged);

    void (^checkImageMessage)(ZMConversation*, ZMTFailureRecorder *) = ^(ZMConversation* conv, ZMTFailureRecorder *recorder){
        ZMImageMessage *msg = conv.messages.lastObject;
        FHAssertEqual(recorder, msg.deliveryState, ZMDeliveryStateDelivered);
        FHAssertEqual(recorder, msg.mediumData.length, (NSUInteger) 0);
        FHAssertEqual(recorder, msg.previewData.length, (NSUInteger) 7583);
    };
    
    checkImageMessage(conversation, NewFailureRecorder());
    WaitForEverythingToBeDone();
    [observer tearDown];
}


- (void)testThatInsertedConversationsArePropagatedToTheUIContext;
{
    // given
    ZMConversationList *list = [ZMConversationList conversationsInUserSession:self.userSession];
    XCTAssertEqual(list.count, 0u);
    
    ConversationListChangeObserver *observer = [[ConversationListChangeObserver alloc] initWithConversationList:list];
    
    // when
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);

    // assert
    XCTAssertEqual(list.count, 4u);
    [observer tearDown];
}

- (void)testThatSystemEventsAreAddedToAConversationWhenTheyAreGeneratedRemotely
{
    // given
    NSString *newName = @"Shiny new name";
    
    
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(groupConversation);
    XCTAssertNotEqual(groupConversation.displayName, newName);
    
    // make a copy of the current ones (since it's a relationship, it seems that [set copy] just doesn't work)
    NSOrderedSet *previousMessages = [groupConversation.messages mutableCopy];
    
    // when
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation changeNameByUser:session.selfUser name:newName];
        [self spinMainQueueWithTimeout:0.2];
        [self.groupConversation addUsersByUser:session.selfUser addedUsers:@[self.user4]];
    }];
    WaitForEverythingToBeDone();
    
    // then
    NSMutableOrderedSet *extraMessages = [groupConversation.messages mutableCopy];
    [extraMessages minusOrderedSet:previousMessages];
    
    XCTAssertEqual(extraMessages.count, 2u);
    XCTAssertEqual([extraMessages[0] systemMessageType], ZMSystemMessageTypeConversationNameChanged);
    XCTAssertEqual([extraMessages[1] systemMessageType], ZMSystemMessageTypeParticipantsAdded);
    
    ZMUser *user4 = [self userForMockUser:self.user4];
    XCTAssertEqualObjects([extraMessages[1] users],  [NSSet setWithArray:@[user4]]);
    XCTAssertTrue([groupConversation.activeParticipants containsObject:user4]);
}

- (void)testThatSystemMessageIsAddedIfClientWasInactiveAndCantFetchAnyNotifications
{
    // given
    self.registeredOnThisDevice = YES;
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    NSUUID *firstMessageNonce = NSUUID.createUUID;
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> session __unused) {
        [self.groupConversation insertTextMessageFromUser:self.user1 text:@"Message Text" nonce:firstMessageNonce];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversation];
    NSSet *previousMessagesIDs = [groupConversation.messages.set mapWithBlock:^NSManagedObjectID *(ZMManagedObject *managedObject) {
        return managedObject.objectID;
    }];
    XCTAssertNotNil(groupConversation);
    
    // when
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        if ([request.path containsString:@"/notifications"]) {
            return [ZMTransportResponse responseWithPayload:nil HTTPstatus:404 transportSessionError:nil];
        }
        return nil;
    };
    
    [self recreateUserSessionAndWipeCache:NO];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSPredicate *objectIDPredicate = [NSPredicate predicateWithFormat:@"! (%@ CONTAINS objectID)", previousMessagesIDs];
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    NSOrderedSet <ZMMessage *>*allMessages = conversation.messages;
    NSUInteger addedMessageCount = [conversation.messages filteredOrderedSetUsingPredicate:objectIDPredicate].count;
    
    // then
    XCTAssertEqual(allMessages.count, 2lu);
    XCTAssertEqualObjects(allMessages.firstObject.nonce.transportString, firstMessageNonce.transportString);
    XCTAssertEqual([allMessages.firstObject.serverTimestamp compare:allMessages.lastObject.serverTimestamp], NSOrderedAscending);
    XCTAssertEqual([(ZMSystemMessage *)allMessages.lastObject systemMessageType], ZMSystemMessageTypePotentialGap);
    XCTAssertEqual(addedMessageCount, 1lu); // One system message should have been added
}

- (void)testThatSystemMessageIsAddedIfClientWasInactiveAndCantFetchAllNotifications
{
    // given
    self.registeredOnThisDevice = YES;
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    NSUUID *firstMessageNonce = NSUUID.createUUID;
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> session __unused) {
        [self.groupConversation insertTextMessageFromUser:self.user1 text:@"Message Text" nonce:firstMessageNonce];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversation];
    NSSet *previousMessagesIDs = [groupConversation.messages.set mapWithBlock:^NSManagedObjectID *(ZMManagedObject *managedObject) {
        return managedObject.objectID;
    }];
    XCTAssertNotNil(groupConversation);
    
    ZMUser *otherUser = [self userForMockUser:self.user2];
    NSUUID *payloadNotificationID = NSUUID.createUUID;
    ZMEventID *firstEventID = self.createEventID;
    NSUUID *lastMessageNonce = NSUUID.createUUID;
    NSDate *messageTimeStamp = [[NSDate date] dateByAddingTimeInterval:1000];
    
    // when
    NSDictionary *payload = @{
                              @"notifications" :@[ @{
                                          @"id" : payloadNotificationID.transportString,
                                          @"payload" : @[
                                                  @{
                                                      @"id": firstEventID.transportString,
                                                      @"conversation" : groupConversation.remoteIdentifier.transportString,
                                                      @"type" : @"conversation.message-add",
                                                      // We use a later date to simulate the time between the last message
                                                      @"time": messageTimeStamp.transportString,
                                                      @"data" : @{
                                                              @"sender": otherUser.remoteIdentifier.transportString,
                                                              @"nonce" : lastMessageNonce.transportString,
                                                              @"content" : @"this should be inserted after the system message"
                                                              },
                                                      },
                                                  ]
                                          }]
                              };
    
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        if ([request.path hasPrefix:@"/notifications?"]) {
            return [ZMTransportResponse responseWithPayload:payload HTTPstatus:404 transportSessionError:nil];
        }
        return nil;
    };
    
    [self recreateUserSessionAndWipeCache:NO];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSPredicate *objectIDPredicate = [NSPredicate predicateWithFormat:@"! (%@ CONTAINS objectID)", previousMessagesIDs];
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    NSOrderedSet <ZMMessage *>*allMessages = conversation.messages;
    NSOrderedSet <ZMMessage *>*addedMessages = [conversation.messages filteredOrderedSetUsingPredicate:objectIDPredicate];
    XCTAssertNotNil(addedMessages);
    
    // then
    XCTAssertEqual(allMessages.count, 3lu);
    XCTAssertEqualObjects(allMessages.firstObject.nonce.transportString, firstMessageNonce.transportString);
    
    XCTAssertEqual(addedMessages.count, 2lu); // One Text and one system message should have been added
    XCTAssertEqual([addedMessages.firstObject.serverTimestamp compare:addedMessages.lastObject.serverTimestamp], NSOrderedAscending);
    XCTAssertEqual([(ZMSystemMessage *)addedMessages.firstObject systemMessageType], ZMSystemMessageTypePotentialGap);
    XCTAssertEqualObjects(addedMessages.lastObject.nonce.transportString, lastMessageNonce.transportString);
}

- (void)testThatPotentialGapSystemMessageContainsAddedAndRemovedUsers
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    [self.userSession performChanges:^{
        [self.groupConversation removeUsersByUser:self.user2 removedUser:self.user3];
    }];
    
    NSUUID *firstMessageNonce = NSUUID.createUUID;
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> session __unused) {
        [self.groupConversation insertTextMessageFromUser:self.user1 text:@"Message Text" nonce:firstMessageNonce];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    [self recreateUserSessionAndWipeCache:NO];
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> session __unused) {
        [session simulatePushChannelClosed];
        [self.groupConversation removeUsersByUser:self.user2 removedUser:self.user1];
        [self.groupConversation addUsersByUser:self.user2 addedUsers:@[self.user4]];
    }];
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> session __unused) {
        [session clearNotifications];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    ZMSystemMessage *systemMessage = [conversation.messages lastObject];
    
    ZMUser *addedUser = [self userForMockUser:self.user4];
    ZMUser *removedUser = [self userForMockUser:self.user1];
    
    // then
    XCTAssertEqual(conversation.inactiveParticipants.count, 2lu); // because we removed user3 and user1
    XCTAssertEqual(conversation.activeParticipants.count, 3lu);
    XCTAssertEqual(systemMessage.users.count, 3lu);
    XCTAssertEqual(systemMessage.addedUsers.count, 1lu);
    XCTAssertEqual(systemMessage.removedUsers.count, 1u);
    XCTAssertEqualObjects([systemMessage.addedUsers.anyObject objectID], addedUser.objectID);
    XCTAssertEqualObjects([systemMessage.removedUsers.anyObject objectID], removedUser.objectID);
    XCTAssertEqual(systemMessage.systemMessageType, ZMSystemMessageTypePotentialGap);
    XCTAssertFalse(systemMessage.needsUpdatingUsers);
}

- (void)testThatPreviousPotentialGapSystemMessageGetsDeletedAndNewOneUpdatesWithOldUsers
{
    // given
    self.registeredOnThisDevice = YES;
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    NSUUID *firstMessageNonce = NSUUID.createUUID;
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> session __unused) {
        [self.groupConversation insertTextMessageFromUser:self.user1 text:@"Message Text" nonce:firstMessageNonce];
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertEqual(conversation.messages.count, 1lu);
    
    // when
    [self recreateUserSessionAndWipeCache:NO];
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> session __unused) {
        [session simulatePushChannelClosed];
        [self.groupConversation removeUsersByUser:self.user2 removedUser:self.user1];
        [self.groupConversation addUsersByUser:self.user2 addedUsers:@[self.user4]];
    }];
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> session __unused) {
        [session clearNotifications];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    conversation = [self conversationForMockConversation:self.groupConversation];
    NSOrderedSet<ZMMessage *> *allMessages = conversation.messages;
    ZMSystemMessage *systemMessage = (ZMSystemMessage *)allMessages.lastObject;
    
    // then
    XCTAssertEqual(conversation.messages.count, 2lu);
    XCTAssertEqual(systemMessage.users.count, 4lu);
    XCTAssertFalse(systemMessage.needsUpdatingUsers);
    
    // when
    [self recreateUserSessionAndWipeCache:NO];
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> session __unused) {
        [session simulatePushChannelClosed];
        [self.groupConversation removeUsersByUser:self.user2 removedUser:self.user3];
        [self.groupConversation addUsersByUser:self.user2 addedUsers:@[self.user1, self.user5]];
    }];
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> session __unused) {
        [session clearNotifications];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    conversation = [self conversationForMockConversation:self.groupConversation];
    ZMSystemMessage *secondSystemMessage = (ZMSystemMessage *)conversation.messages.lastObject;
    
    NSSet <ZMUser *>*addedUsers = [NSSet setWithObjects:[self userForMockUser:self.user4], [self userForMockUser:self.user5], nil];
    NSSet <ZMUser *>*initialUsers = [NSSet setWithObjects:[self userForMockUser:self.selfUser],
                                     [self userForMockUser:self.user3],
                                     [self userForMockUser:self.user2],
                                     [self userForMockUser:self.user1], nil];
    ZMUser *removedUser = [self userForMockUser:self.user3];
    
    // then
    XCTAssertEqual(conversation.messages.count, 2lu);
    XCTAssertEqual(conversation.activeParticipants.count, 5lu);
    XCTAssertEqualObjects(secondSystemMessage.users, initialUsers);
    XCTAssertEqual(secondSystemMessage.addedUsers.count, 2lu);
    XCTAssertEqual(secondSystemMessage.removedUsers.count, 1lu);
    XCTAssertEqualObjects(secondSystemMessage.addedUsers, addedUsers);
    XCTAssertEqualObjects(secondSystemMessage.removedUsers.anyObject.objectID, removedUser.objectID);
    XCTAssertEqual(secondSystemMessage.systemMessageType, ZMSystemMessageTypePotentialGap);
    XCTAssertFalse(secondSystemMessage.needsUpdatingUsers);
}

- (void)testThatPotentialGapSystemMessageGetsUpdatedWithAddedUserWhenUserNameIsFetched
{
    // given
    self.registeredOnThisDevice = YES;
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();

    NSUUID *firstMessageNonce = NSUUID.createUUID;
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> session __unused) {
        [self.groupConversation insertTextMessageFromUser:self.user1 text:@"Hello" nonce:firstMessageNonce];
    }];

    WaitForAllGroupsToBeEmpty(0.5);
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertEqual(conversation.messages.count, 1lu);

    // when we simulate an inactive period and a user was added in the meantime
    [self recreateUserSessionAndWipeCache:NO];
    WaitForAllGroupsToBeEmpty(0.5);

    __block MockUser *newMockUser;

    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> session __unused) {
        [session simulatePushChannelClosed];
        newMockUser = [session insertUserWithName:@"Brüno"];
        [self storeRemoteIDForObject:newMockUser];
    }];
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> session __unused) {
        [session clearNotifications];
    }];

    WaitForAllGroupsToBeEmpty(0.5);
    XCTestExpectation *updatingUsersExpectation = [self expectationWithDescription:@"It should update the users"];

    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request) {
        if ([request.path containsString:newMockUser.identifier]) {
            ZMConversation *innerConversation = [self conversationForMockConversation:self.groupConversation];
            NSOrderedSet<ZMMessage *> *allMessages = innerConversation.messages;
            id <ZMSystemMessageData> systemMessageData = allMessages.lastObject.systemMessageData;
            
            // then we should insert a system message which needs updating users
            XCTAssertNotNil(systemMessageData);
            XCTAssertEqual(systemMessageData.systemMessageType, ZMSystemMessageTypePotentialGap);
            XCTAssertTrue(systemMessageData.needsUpdatingUsers);
            [updatingUsersExpectation fulfill];
        }
        return nil;
    };

    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> session __unused) {
        [session simulatePushChannelClosed];
        [self.groupConversation addUsersByUser:self.user2 addedUsers:@[newMockUser]];
    }];
    [self.mockTransportSession performRemoteChanges:^(id<MockTransportSessionObjectCreation> session __unused) {
        [session clearNotifications];
    }];

    WaitForAllGroupsToBeEmpty(0.5);

    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:5]);

    conversation = [self conversationForMockConversation:self.groupConversation];
    NSOrderedSet<ZMMessage *> *allMessages = conversation.messages;
    ZMSystemMessage *systemMessage = (ZMSystemMessage *)allMessages.lastObject;

    ZMUser *addedUser = systemMessage.addedUsers.anyObject;

    // then after fetching it should contain the full users
    XCTAssertEqual(conversation.messages.count, 2lu);
    XCTAssertEqual(systemMessage.users.count, 4lu);
    XCTAssertEqual(systemMessage.removedUsers.count, 0lu);
    XCTAssertEqual(systemMessage.addedUsers.count, 1lu);
    XCTAssertNotNil(addedUser);
    XCTAssertEqualObjects(addedUser.name, @"Brüno");
    XCTAssertFalse(systemMessage.needsUpdatingUsers);
}

- (void)testThatConversationNameChangedSystemMessagesContainTheConversationTitle
{
    // given
    NSString *newName1 = @"Shiny new name";
    NSString *newName2 = @"Even shinier new name";

    
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(groupConversation);
    XCTAssertNotEqual(groupConversation.displayName, newName1);
    
    // make a copy of the current ones (since it's a relationship, it seems that [set copy] just doesn't work)
    NSOrderedSet *previousMessages = [groupConversation.messages mutableCopy];
    
    // when
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation changeNameByUser:session.selfUser name:newName1];
    }];
    WaitForEverythingToBeDone();
    
    
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation changeNameByUser:session.selfUser name:newName2];
    }];
    WaitForEverythingToBeDone();
    
    // then
    NSMutableOrderedSet *extraMessages = [groupConversation.messages mutableCopy];
    [extraMessages minusOrderedSet:previousMessages];
    
    XCTAssertEqual(extraMessages.count, 2u);
    XCTAssertEqual([extraMessages[0] systemMessageType], ZMSystemMessageTypeConversationNameChanged);
    XCTAssertEqual([extraMessages[1] systemMessageType], ZMSystemMessageTypeConversationNameChanged);
    
    XCTAssertEqualObjects([(ZMTextMessage *)extraMessages[0] text],  newName1);
    XCTAssertEqualObjects([(ZMTextMessage *)extraMessages[1] text],  newName2);
}


- (void)testThatItExpiresAMessage
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(groupConversation);

    self.mockTransportSession.doNotRespondToRequests = YES;
    [ZMMessage setDefaultExpirationTime:0.1]; //We don't want to wait 60 seconds
    __block ZMMessage *message;
    [self.userSession performChanges:^{
        message = [groupConversation appendMessagesWithText:@"lalala"].firstObject;
    }];
    XCTAssertTrue([groupConversation.managedObjectContext saveOrRollback]);
    
    // when
    WaitForEverythingToBeDone();
    XCTAssertTrue([self waitOnMainLoopUntilBlock:^BOOL{
        return message.isExpired;
    } timeout:0.5]);
    
    
    //then
    XCTAssertTrue(message.isExpired);
    XCTAssertEqual(message.deliveryState, ZMDeliveryStateFailedToSend);

    
    // finally
    [ZMMessage resetDefaultExpirationTime];
}


- (void)testThatItResendsAMessage
{
    
    // given

    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(groupConversation);
    
    
    self.mockTransportSession.doNotRespondToRequests = YES;
    [ZMMessage setDefaultExpirationTime:0.1]; //We don't want to wait 60 seconds
    __block ZMMessage *message;
    [self.userSession performChanges:^{
        message = [groupConversation appendMessagesWithText:@"lalala"].firstObject;
    }];
    XCTAssertTrue([groupConversation.managedObjectContext saveOrRollback]);
    
    WaitForEverythingToBeDone();
    XCTAssertTrue([self waitOnMainLoopUntilBlock:^BOOL{
        return message.isExpired;
    } timeout:0.5]);
    
    XCTAssertTrue(message.isExpired);
    XCTAssertEqual(message.deliveryState, ZMDeliveryStateFailedToSend);
    
    
    // when
    self.mockTransportSession.doNotRespondToRequests = NO;
    [self.userSession performChanges:^{
        [message resend];
    }];

    
    // then
    WaitForEverythingToBeDone();
    XCTAssertFalse(message.isExpired);
    XCTAssertNotEqual(message.deliveryState, ZMDeliveryStateFailedToSend);
    
    
    // finally
    [ZMMessage resetDefaultExpirationTime];
}


- (void)testThatWhenResendingAMessageChangesTheStateToPending
{
    
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(groupConversation);
    
    
    self.mockTransportSession.doNotRespondToRequests = YES;
    [ZMMessage setDefaultExpirationTime:0.1]; //We don't want to wait 60 seconds
    __block ZMMessage *message;
    [self.userSession performChanges:^{
        message = [groupConversation appendMessagesWithText:@"lalala"].firstObject;
    }];
    XCTAssertTrue([groupConversation.managedObjectContext saveOrRollback]);
    
    WaitForEverythingToBeDone();
    XCTAssertTrue([self waitOnMainLoopUntilBlock:^BOOL{
        return message.isExpired;
    } timeout:0.5]);
    
    XCTAssertTrue(message.isExpired);
    XCTAssertEqual(message.deliveryState, ZMDeliveryStateFailedToSend);
    
    
    // when
    self.mockTransportSession.doNotRespondToRequests = YES;
    [ZMMessage setDefaultExpirationTime:0.3];
    [self.userSession performChanges:^{
        [message resend];
    }];

    
    // then
    XCTAssertFalse(message.isExpired);
    XCTAssertEqual(message.deliveryState, ZMDeliveryStatePending);
    
    
    // finally
    WaitForEverythingToBeDoneWithTimeout(0.5);
    [ZMMessage resetDefaultExpirationTime];
}



- (void)testThatIfWeExpireAMessageButStillGetAResponseThatWeUseIt
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(groupConversation);
    
    self.mockTransportSession.doNotRespondToRequests = NO;
    [ZMMessage setDefaultExpirationTime:0.1]; //We don't want to wait 60 seconds
    __block id<ZMConversationMessage> message;
    [self.userSession performChanges:^{
        message = [groupConversation appendMessagesWithText:@"lalala"].firstObject;
    }];
    XCTAssertTrue([groupConversation.managedObjectContext saveOrRollback]);
    
    // when
    WaitForEverythingToBeDone();
    
    
    //then
    XCTAssertEqual(message.deliveryState, ZMDeliveryStateDelivered);
    
    // finally
    [ZMMessage resetDefaultExpirationTime];
}


- (void)testThatWhenResendingAMessageWeOnlyGetANotificationForStateChangingToPending
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(groupConversation);
    
    
    self.mockTransportSession.doNotRespondToRequests = YES;
    [ZMMessage setDefaultExpirationTime:0.1]; //We don't want to wait 60 seconds
    
    __block ZMMessage *message;
    [self.userSession performChanges:^{
        message = [groupConversation appendMessagesWithText:@"lalala"].firstObject;
    }];
    XCTAssertTrue([groupConversation.managedObjectContext saveOrRollback]);
    
    WaitForEverythingToBeDone();
    XCTAssertTrue([self waitOnMainLoopUntilBlock:^BOOL{
        return message.isExpired;
    } timeout:0.5]);
    
    XCTAssertTrue(message.isExpired);
    XCTAssertEqual(message.deliveryState, ZMDeliveryStateFailedToSend);
    
    MessageChangeObserver *observer = [[MessageChangeObserver alloc] initWithMessage:message];
    
    // when
    self.mockTransportSession.doNotRespondToRequests = YES;
    [ZMMessage setDefaultExpirationTime:0.3];
    
    [self.userSession performChanges:^{
        [message resend];
    }];
    

    
    // then
    XCTAssertEqual(observer.notifications.count, 1u);
    if (observer.notifications.count > 0 ) {
        MessageChangeInfo *note = observer.notifications.firstObject;
        XCTAssertTrue(note.deliveryStateChanged);
        XCTAssertFalse(note.imageChanged);
        XCTAssertFalse(note.knockChanged);
        XCTAssertFalse(note.senderChanged);
        
        XCTAssertEqual(message.deliveryState, ZMDeliveryStatePending);
    }
    
    // finally
    WaitForEverythingToBeDoneWithTimeout(0.5);
    [ZMMessage resetDefaultExpirationTime];
    [observer tearDown];
}


- (void)testThatItResendsMessages
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(groupConversation);
    
    
    self.mockTransportSession.doNotRespondToRequests = YES;
    [ZMMessage setDefaultExpirationTime:0.2]; //We don't want to wait 60 seconds
    
    __block id<ZMConversationMessage> message;
    [self.userSession performChanges:^{
        message = [groupConversation appendMessagesWithText:@"lalala"].firstObject;
    }];
    XCTAssertTrue([groupConversation.managedObjectContext saveOrRollback]);
    
    XCTAssertTrue([self waitOnMainLoopUntilBlock:^BOOL{
        return message.deliveryState == ZMDeliveryStateFailedToSend;
    } timeout:0.5]);
    
    // when
    self.mockTransportSession.doNotRespondToRequests = NO;
    [ZMMessage setDefaultExpirationTime:60];
    
    WaitForEverythingToBeDone();
    
    [self.userSession performChanges:^{
        [message resend];
    }];
    
    WaitForEverythingToBeDone();
    
    // then
    XCTAssertTrue([self waitOnMainLoopUntilBlock:^BOOL{
        return message.deliveryState == ZMDeliveryStateDelivered;
    } timeout:0.5]);
    
    // finally
    [ZMMessage resetDefaultExpirationTime];
}

@end



@implementation ConversationTests (Participants)

- (void)testThatParticipantsAreAddedToAConversationWhenTheyAreAddedRemotely
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(groupConversation);
    
    // when
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation addUsersByUser:session.selfUser addedUsers:@[self.user4]];
    }];
    WaitForEverythingToBeDone();
    
    // then
    ZMUser *user4 = [self userForMockUser:self.user4];
    XCTAssertTrue([groupConversation.activeParticipants containsObject:user4]);
    XCTAssertFalse([groupConversation.inactiveParticipants containsObject:user4]);
    XCTAssertEqual(groupConversation.keysThatHaveLocalModifications.count, 0u);
}

- (void)testThatParticipantsAreRemovedFromAConversationWhenTheyAreRemovedRemotely
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    ZMUser *user3 = [self userForMockUser:self.user3];
    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(groupConversation);
    XCTAssertTrue([groupConversation.activeParticipants containsObject:user3]);
    
    // when
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation removeUsersByUser:session.selfUser removedUser:self.user3];
    }];
    WaitForEverythingToBeDone();
    
    // then
    XCTAssertFalse([groupConversation.activeParticipants containsObject:user3]);
    XCTAssertTrue([groupConversation.inactiveParticipants containsObject:user3]);
    XCTAssertEqual(groupConversation.keysThatHaveLocalModifications.count, 0u);
}


- (void)testThatAddingAndRemovingAParticipantToAConversationSendsOutChangeNotifications
{
    __block MockUser *connectedUserNotInConv;
    {
        [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
            connectedUserNotInConv = [session insertUserWithName:@"Connected user which originally is not in conversation"];
            connectedUserNotInConv.email = @"connectedUserNotInConv@example.com";
            connectedUserNotInConv.phone = @"23498579";
            [self storeRemoteIDForObject:connectedUserNotInConv];
            
            MockConversation *selfToConnectedNotInConvConversation = [session insertOneOnOneConversationWithSelfUser:self.selfUser otherUser:connectedUserNotInConv];
            selfToConnectedNotInConvConversation.creator = self.selfUser;
            
            MockConnection *connectionSelfToConnectedUserNotInConv = [session insertConnectionWithSelfUser:self.selfUser toUser:connectedUserNotInConv];
            connectionSelfToConnectedUserNotInConv.status = @"accepted";
            connectionSelfToConnectedUserNotInConv.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-3];
            connectionSelfToConnectedUserNotInConv.conversation = selfToConnectedNotInConvConversation;
        }];
        
        XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
        
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        XCTAssertNotNil(conversation);
        
        ZMUser *user = [self userForMockUser:connectedUserNotInConv];
        
        ConversationChangeObserver *observer = [[ConversationChangeObserver alloc] initWithConversation:conversation];
        [observer clearNotifications];
        
        [self.userSession performChanges:^{
            XCTAssertFalse([conversation.activeParticipants containsObject:user]);
            [conversation addParticipant:user];
            XCTAssertTrue([conversation.activeParticipants containsObject:user]);
        }];
        XCTAssertFalse(conversation.hasChanges, @"Rollback?");
        
        XCTAssertEqual(observer.notifications.count, 1u);
        ConversationChangeInfo *note1 = observer.notifications.firstObject;
        XCTAssertEqual(note1.conversation, conversation);
        XCTAssertTrue(note1.participantsChanged);
        [observer.notifications removeAllObjects];
        
        [self.userSession performChanges:^{
            XCTAssertTrue([conversation.activeParticipants containsObject:user]);
            [conversation removeParticipant:user];
            XCTAssertFalse([conversation.activeParticipants containsObject:user]);
        }];
        XCTAssertFalse(conversation.hasChanges, @"Rollback?");
        
        XCTAssertEqual(observer.notifications.count, 1u);
        ConversationChangeInfo *note2 = observer.notifications.firstObject;
        XCTAssertEqual(note2.conversation, conversation);
        XCTAssertTrue(note2.participantsChanged);
        [observer.notifications removeAllObjects];
        
        // Wait for merge ui->sync to be done
        WaitForEverythingToBeDone();
        
        XCTAssertFalse([conversation hasLocalModificationsForKey:ZMConversationUnsyncedActiveParticipantsKey]);
        [observer tearDown];
    }
}


- (void)testThatWhenLeavingAConversationWeSetAndSynchronizeTheLastReadEventID
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(conversation);
    
    ZMUser *user = [self userForMockUser:self.selfUser];
    
    [self.mockTransportSession resetReceivedRequests];
    
    
    // when
    [self.userSession performChanges:^{
        XCTAssertTrue(conversation.isSelfAnActiveMember);
        [conversation removeParticipant:user];
        XCTAssertFalse(conversation.isSelfAnActiveMember);
    }];

    XCTAssertTrue([conversation hasLocalModificationsForKey:ZMConversationIsSelfAnActiveMemberKey]);
    WaitForEverythingToBeDone();
    
    // then
    XCTAssertNotNil(conversation.lastReadEventID);
    XCTAssertNotNil(conversation.lastReadServerTimeStamp);

    NSMutableArray *receivedRequests = [self.mockTransportSession.receivedRequests mutableCopy];

    ZMTransportRequest *selfConversationRequest = [receivedRequests lastObject];
    XCTAssertNotNil(selfConversationRequest);
    NSString *expectedSelfPath = [NSString stringWithFormat:@"/conversations/%@/otr/messages", user.remoteIdentifier.transportString];
    XCTAssertEqualObjects(selfConversationRequest.path, expectedSelfPath);
    XCTAssertEqual(selfConversationRequest.method, ZMMethodPOST);
    
    [receivedRequests removeLastObject];
    
    ZMTransportRequest *previousRequest = [receivedRequests lastObject];
    XCTAssertNotNil(previousRequest);
    NSString *expectedPreviousPath = [NSString stringWithFormat:@"/conversations/%@/members/%@", conversation.remoteIdentifier.transportString, user.remoteIdentifier.transportString];
    XCTAssertEqualObjects(previousRequest.path, expectedPreviousPath);
    XCTAssertEqual(previousRequest.method, ZMMethodDELETE);
    
    XCTAssertFalse([conversation hasLocalModificationsForKey:ZMConversationIsSelfAnActiveMemberKey]);
    
    NSUInteger unreadCount = conversation.estimatedUnreadCount;
    
    // and when logging in and out again lastRead is still set
    [self recreateUserSessionAndWipeCache:YES];
    
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    
    conversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(conversation);
    XCTAssertEqual(conversation.estimatedUnreadCount, unreadCount);
}


- (void)testThatRemovingAndAddingAParticipantToAConversationSendsOutChangeNotifications
{
    
    __block MockUser *connectedUserNotInConv;
    {
        [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
            connectedUserNotInConv = [session insertUserWithName:@"Connected user which originally is not in conversation"];
            connectedUserNotInConv.email = @"connectedUserNotInConv@example.com";
            connectedUserNotInConv.phone = @"23498579";
            [self storeRemoteIDForObject:connectedUserNotInConv];
            
            MockConversation *selfToConnectedNotInConvConversation = [session insertOneOnOneConversationWithSelfUser:self.selfUser otherUser:connectedUserNotInConv];
            selfToConnectedNotInConvConversation.creator = self.selfUser;
            
            MockConnection *connectionSelfToConnectedUserNotInConv = [session insertConnectionWithSelfUser:self.selfUser toUser:connectedUserNotInConv];
            connectionSelfToConnectedUserNotInConv.status = @"accepted";
            connectionSelfToConnectedUserNotInConv.lastUpdate = [NSDate dateWithTimeIntervalSinceNow:-3];
            connectionSelfToConnectedUserNotInConv.conversation = selfToConnectedNotInConvConversation;
        }];
        
        XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
        
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        XCTAssertNotNil(conversation);
        
        ZMUser *user = [self userForMockUser:self.user1];
        
        ConversationChangeObserver *observer = [[ConversationChangeObserver alloc] initWithConversation:conversation];
        [observer clearNotifications];
        
        [self.userSession performChanges:^{
            XCTAssertTrue([conversation.activeParticipants containsObject:user]);
            [conversation removeParticipant:user];
            XCTAssertFalse([conversation.activeParticipants containsObject:user]);
        }];
        XCTAssertFalse(conversation.hasChanges, @"Rollback?");
        
        XCTAssertEqual(observer.notifications.count, 1u);
        ConversationChangeInfo *note1 = observer.notifications.firstObject;
        XCTAssertEqual(note1.conversation, conversation);
        XCTAssertTrue(note1.participantsChanged);
        [observer.notifications removeAllObjects];
        
        [self.userSession performChanges:^{
            XCTAssertFalse([conversation.activeParticipants containsObject:user]);
            [conversation addParticipant:user];
            XCTAssertTrue([conversation.activeParticipants containsObject:user]);
        }];
        XCTAssertFalse(conversation.hasChanges, @"Rollback?");
        
        XCTAssertEqual(observer.notifications.count, 1u);
        ConversationChangeInfo *note2 = observer.notifications.firstObject;
        XCTAssertEqual(note2.conversation, conversation);
        XCTAssertTrue(note2.participantsChanged);
        [observer.notifications removeAllObjects];
        
        // Wait for merge ui->sync to be done
        WaitForEverythingToBeDone();
        
        XCTAssertFalse([conversation hasLocalModificationsForKey:ZMConversationUnsyncedActiveParticipantsKey]);
        [observer tearDown];
    }
}


- (void)testThatActiveParticipantsInOneOnOneConversationsAreAllParticipants
{
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);
    
    [self.userSession saveOrRollbackChanges];
    
    XCTAssertEqual(conversation.activeParticipants.count, 2u);
    XCTAssertEqual(conversation.inactiveParticipants.count, 0u);
}

- (void)testThatActiveParticipantsInOneOnOneConversationWithABlockedUserAreAllParticipants
{
    // given
    
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotNil(conversation);
    
    [self.userSession saveOrRollbackChanges];
    
    XCTAssertEqual(conversation.activeParticipants.count, 2u);
    XCTAssertEqual(conversation.inactiveParticipants.count, 0u);
    
    // when
    ZMUser *user1 = [self userForMockUser:self.user1];
    XCTAssertFalse(user1.isBlocked);

    [self.userSession performChanges:^{
        [user1 block];
    }];
    
    XCTAssertTrue(user1.isBlocked);
    XCTAssertEqual(conversation.activeParticipants.count, 2u);
    XCTAssertEqual(conversation.inactiveParticipants.count, 0u);
}

- (NSArray *)movedIndexPairsForChangeSet:(ConversationListChangeInfo *)note
{
    NSMutableArray *indexes = [NSMutableArray array];
    [note enumerateMovedIndexes:^(NSUInteger from, NSUInteger to) {
        ZMMovedIndex *index = [ZMMovedIndex movedIndexFrom:from to:to];
        [indexes addObject:index];
    }];
    
    return indexes;
}

- (void)testThatNotificationsAreReceivedWhenConversationsAreFaulted
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    ZMConversation *conversation1 = [self conversationForMockConversation:self.selfToUser1Conversation];
    ZMConversation *conversation2 = [self conversationForMockConversation:self.selfToUser2Conversation];
    ZMConversation *conversation3 = [self conversationForMockConversation:self.groupConversation];
    ZMConversation *conversation4 = [self conversationForMockConversation:self.groupConversationWithOnlyConnected];
    
    // I am faulting conversation, will maintain the "message" relations as faulted
    ZMConversationList *conversationList = [ZMConversationList conversationsInUserSession:self.userSession];
    
    NSArray *expectedList1 = @[conversation4, conversation3, conversation2, conversation1];
    XCTAssertEqualObjects(conversationList, expectedList1);
    XCTAssertEqual(conversationList.count, 4u);
    
    ConversationListChangeObserver *observer = [[ConversationListChangeObserver alloc] initWithConversationList:conversationList];

    // when
    {
        [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> ZM_UNUSED *session) {
            [self.selfToUser1Conversation insertTextMessageFromUser:self.user1 text:@"some message" nonce:NSUUID.createUUID];
        }];
        WaitForEverythingToBeDone();
        
        // then
        NSArray *expectedList2 = @[conversation1, conversation4, conversation3, conversation2];
        NSIndexSet *updatedIndexes2 = [NSIndexSet indexSetWithIndex:0];
        NSArray *movedIndexes2 = @[[ZMMovedIndex movedIndexFrom:3 to:0]];
        
        XCTAssertEqualObjects(conversationList, expectedList2);
        
        XCTAssertEqual(observer.notifications.count, 1u);
        ConversationListChangeInfo *note1 = observer.notifications.lastObject;
        XCTAssertEqualObjects(note1.updatedIndexes, updatedIndexes2);
        XCTAssertEqualObjects([self movedIndexPairsForChangeSet:note1], movedIndexes2);
    }
    [observer tearDown];
}

- (void)testThatSelfUserSeesConversationWhenItIsAddedToConversationByOtherUser
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();

    __block MockConversation *groupConversation;
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        groupConversation = [session insertConversationWithCreator:self.user3 otherUsers:@[self.user1, self.user2] type:ZMTConversationTypeGroup];
        [self storeRemoteIDForObject:groupConversation];
        [groupConversation changeNameByUser:self.selfUser name:@"Group conversation 2"];
    }];
    WaitForAllGroupsToBeEmpty(50.0f);
    
    ZMConversationList *conversationList = [ZMConversationList conversationsInUserSession:self.userSession];
    
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> ZM_UNUSED *session) {
        [groupConversation addUsersByUser:self.user1 addedUsers:@[self.selfUser]];
    }];
    WaitForAllGroupsToBeEmpty(50.0f);

    //By this moment new conversation should be created and self user should be it's member
    ZMConversation *newConv = [self conversationForMockConversation:groupConversation];
    ZMUser *user = [self userForMockUser:self.selfUser];

    XCTAssertEqualObjects(conversationList.firstObject, newConv);
    XCTAssertTrue([[newConv allParticipants] containsObject:user]);
}


@end


@implementation  ConversationTests (ConversationWindow)


- (NSString *)text
{
    return @"";
}

- (void)conversationWindowDidChange:(MessageWindowChangeInfo *)note;
{
    [self.receivedConversationWindowChangeNotifications addObject:note];
}

- (void)testThatItSendsAConversationWindowChangeNotificationsIfAConversationIsChanged
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        NOT_USED(session);
        
        for (NSUInteger i=0; i<20; ++i) {
            [self.groupConversation insertTextMessageFromUser:self.user2 text:[NSString stringWithFormat:@"Message %ld", (unsigned long)i] nonce:[NSUUID createUUID]];
            [NSThread sleepForTimeInterval:0.002]; // SE has milisecond precision
        }
        
        self.groupConversation.lastRead = ((MockEvent *)self.groupConversation.events.lastObject).identifier;
    }];
    WaitForEverythingToBeDone();
    
    
    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(groupConversation);
    
    ZMConversationMessageWindow *conversationWindow = [groupConversation conversationWindowWithSize:5];
    id token = [conversationWindow addConversationWindowObserver:self];
    
    // correct window?
    XCTAssertEqual(conversationWindow.messages.count, 5u);
    {
        ZMTextMessage *lastMessage = (ZMTextMessage *)conversationWindow.messages.lastObject;
        XCTAssertEqualObjects(lastMessage.text, @"Message 19");
    }
    
    // when
    NSString *extraMessageText = @"This is an extra message at the end of the window";
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        NOT_USED(session);
        [self.groupConversation insertTextMessageFromUser:self.user2 text:extraMessageText nonce:[NSUUID createUUID]];
    }];
    WaitForEverythingToBeDone();

    // then
    XCTAssertEqual(self.receivedConversationWindowChangeNotifications.count, 1u);
    MessageWindowChangeInfo *note = self.receivedConversationWindowChangeNotifications.firstObject;
    NSIndexSet *expectedInsertedIndexes = [[NSIndexSet alloc] initWithIndex:4];
    NSIndexSet *expectedDeletedIndexes = [[NSIndexSet alloc] initWithIndex:0];
    XCTAssertEqualObjects(note.insertedIndexes, expectedInsertedIndexes);
    XCTAssertEqualObjects(note.deletedIndexes, expectedDeletedIndexes);
    {
        ZMTextMessage *lastMessage = (ZMTextMessage *)conversationWindow.messages.lastObject;
        XCTAssertEqualObjects(lastMessage.text, extraMessageText);
    }
    
    // finally
    [conversationWindow removeConversationWindowObserverToken:token];
}

- (void)testThatTheMessageWindowIsUpdatedProperlyWithLocalMessages
{
    // given
    NSString *expectedText = @"Last text!";
    MockConversationWindowObserver *observer = [self windowObserverAfterLogginInAndInsertingMessagesInMockConversation:self.groupConversation];
    
    NSOrderedSet *initialMessageSet = observer.computedMessages;
    
    // when
    __block ZMMessage *newMessage;
    [self.userSession performChanges:^{
        newMessage = [observer.window.conversation appendMessagesWithText:expectedText].firstObject;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    NSMutableOrderedSet *expectedMessages = [initialMessageSet mutableCopy];
    [expectedMessages removeObjectAtIndex:0];
    [expectedMessages addObject:newMessage];
    
    NSOrderedSet *currentMessageSet = observer.computedMessages;
    NSOrderedSet *windowMessageSet = observer.window.messages;
    
    XCTAssertEqualObjects(currentMessageSet, windowMessageSet);
    XCTAssertEqualObjects(currentMessageSet, expectedMessages);
}


- (void)testThatTheMessageWindowIsUpdatedProperlyWithRemoteMessages
{
    // given
    NSString *expectedText = @"Last text!";
    MockConversationWindowObserver *observer = [self windowObserverAfterLogginInAndInsertingMessagesInMockConversation:self.groupConversation];
    
    NSOrderedSet *initialMessageSet = observer.computedMessages;
    
    // when
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session ZM_UNUSED) {
        [self.groupConversation insertTextMessageFromUser:self.user1 text:expectedText nonce:[NSUUID createUUID]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    NSOrderedSet *currentMessageSet = observer.computedMessages;
    NSOrderedSet *windowMessageSet = observer.window.messages;
    
    XCTAssertEqualObjects(currentMessageSet, windowMessageSet);
    
    for(NSUInteger i = 0; i < observer.window.size; ++ i) {
        if(i == observer.window.size -1) {
            XCTAssertEqual([(ZMTextMessage *)currentMessageSet[i] text], expectedText);
        }
        else {
            XCTAssertEqual(currentMessageSet[i], initialMessageSet[i+1]);
        }
    }
}

- (void)testThatTheMessageWindowIsUpdatedProperlyWhenThereAreConflictingChangesOnLocalAndRemote_SavingRemoteFirst
{
    // given
    NSString *expectedTextRemote = @"Last text REMOTE";
    NSString *expectedTextLocal = @"Last text LOCAL";
    MockConversationWindowObserver *observer = [self windowObserverAfterLogginInAndInsertingMessagesInMockConversation:self.groupConversation];
    
    NSOrderedSet *initialMessageSet = observer.computedMessages;
    
    // when
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    [conversation appendMessagesWithText:expectedTextLocal];
    
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *syncConversation = [ZMConversation conversationWithRemoteID:[NSUUID uuidWithTransportString:self.groupConversation.identifier] createIfNeeded:NO inContext:self.syncMOC];
        [syncConversation appendMessagesWithText:expectedTextRemote];
        [self.syncMOC saveOrRollback];
    }];
    
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    NSArray *currentMessageSet = observer.computedMessages.array;
    NSArray *windowMessageSet = observer.window.messages.array ;
    
    NSArray *currentTexts = [currentMessageSet mapWithBlock:^id(id<ZMConversationMessage> obj) {
        return [obj messageText];
    }];
    NSArray *windowTexts = [windowMessageSet mapWithBlock:^id(id<ZMConversationMessage> obj) {
        return [obj messageText];
    }];    
    
    XCTAssertEqualObjects(currentTexts, windowTexts);
    
    
    
    NSArray *originalFirstPart = [initialMessageSet.array subarrayWithRange:NSMakeRange(2, observer.window.size - 2)];
    NSArray *currentFirstPart = [currentMessageSet subarrayWithRange:NSMakeRange(0, observer.window.size - 2)];
    
    XCTAssertEqualObjects(originalFirstPart, currentFirstPart);
    XCTAssertEqualObjects([(id<ZMConversationMessage>)currentMessageSet[observer.window.size -1] messageText], expectedTextLocal);
    XCTAssertEqualObjects([(id<ZMConversationMessage> )currentMessageSet[observer.window.size -2] messageText], expectedTextRemote);

}

@end


@implementation ConversationTests (ConversationStatusAndOrder)

- (void)testThatTheConversationListOrderIsUpdatedAsWeReceiveMessages
{
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);

    // given
    __block MockConversation *mockExtraConversation;
    
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        mockExtraConversation = [session insertGroupConversationWithSelfUser:self.selfUser otherUsers:@[self.user1, self.user2]];
        [self storeRemoteIDForObject:mockExtraConversation];
        [mockExtraConversation changeNameByUser:self.selfUser name:@"Extra conversation"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        NOT_USED(session);
        [self setDate:[NSDate dateWithTimeInterval:1000 sinceDate:self.groupConversation.lastEventTime] forAllEventsInMockConversation:mockExtraConversation];
    }];
    
    
    // when
    ZMConversation *extraConversation = [self conversationForMockConversation:mockExtraConversation];
    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversation];

    // then
    ZMConversationList *conversations = [ZMConversationList conversationsInUserSession:self.userSession];
    XCTAssertEqual(conversations.firstObject, extraConversation);
    
    ConversationListChangeObserver *observer = [[ConversationListChangeObserver alloc] initWithConversationList:conversations];
    
    // when
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        NOT_USED(session);
        [self.groupConversation insertTextMessageFromUser:self.selfUser text:@"Bla bla bla" nonce:[NSUUID createUUID]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(conversations.firstObject, groupConversation);

    XCTAssertGreaterThanOrEqual(observer.notifications.count, 1u);
    
    NSInteger updatesCount = 0;
    NSMutableArray *moves = [@[] mutableCopy];
    for (ConversationListChangeInfo *note in observer.notifications) {
        updatesCount += note.updatedIndexes.count;
        //should be no deletions
        XCTAssertEqual(note.deletedIndexes.count, 0u);
        [moves addObjectsFromArray:note.movedIndexPairs];
        
    }
    XCTAssertEqual(updatesCount, 1);
    XCTAssertEqual(moves.count, 1u);
    XCTAssertEqual([(ZMMovedIndex *)moves.firstObject from], 2u);
    XCTAssertEqual([(ZMMovedIndex *)moves.firstObject to], 0u);
    [observer tearDown];
}

- (void)testThatAConversationListListenerOnlyReceivesNotificationsForTheSpecificListItSignedUpFor
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    ZMConversationList *convList1 = [ZMConversationList conversationsInUserSession:self.userSession];
    ZMConversationList *convList2 = [ZMConversationList archivedConversationsInUserSession:self.userSession];
    
    ConversationListChangeObserver *convListener1 = [[ConversationListChangeObserver alloc] initWithConversationList:convList1];
    ConversationListChangeObserver *convListener2 = [[ConversationListChangeObserver alloc] initWithConversationList:convList2];
    
    // when
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        NOT_USED(session);
        [session insertConversationWithSelfUser:self.selfUser creator:self.selfUser otherUsers:@[self.user1, self.user2] type:ZMTConversationTypeGroup];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    [self spinMainQueueWithTimeout:0.1];
    
    // then
    XCTAssertGreaterThanOrEqual(convListener1.notifications.count, 0u);
    XCTAssertEqual(convListener2.notifications.count, 0u);
    [convListener1 tearDown];
    [convListener2 tearDown];

}


- (void)testThatLatestConversationIsAlwyaysOnTop
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    ZMConversationList *conversationList = [ZMConversationList conversationsInUserSession:self.userSession];
    ZMConversation *conversation1 = [self conversationForMockConversation:self.selfToUser1Conversation];
    (void) conversation1.messages; // Make sure we've faulted in the messages
    ZMConversation *conversation2 = [self conversationForMockConversation:self.selfToUser2Conversation];
    (void) conversation2.messages; // Make sure we've faulted in the messages
    ZMConversation *conversation3 = [self conversationForMockConversation:self.groupConversation];
    ZMConversation *conversation4 = [self conversationForMockConversation:self.groupConversationWithOnlyConnected];

    XCTAssertNotNil(conversation1);
    XCTAssertNotNil(conversation2);
    
    NSArray *expectedList1 = @[conversation4, conversation3, conversation2, conversation1];
    XCTAssertEqualObjects(conversationList, expectedList1);
    
    NSString *messageText1 = @"some message";
    NSString *messageText2 = @"some other message";
    NSString *messageText3 = @"some third message";
    
    
    NSUUID *nonce1 = [NSUUID createUUID];
    NSUUID *nonce2 = [NSUUID createUUID];
    NSUUID *nonce3 = [NSUUID createUUID];
    
    
    // when
    ConversationListChangeObserver *observer = [[ConversationListChangeObserver alloc] initWithConversationList:conversationList];
    [observer clearNotifications];
    
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> ZM_UNUSED *session) {
        [self.selfToUser1Conversation insertTextMessageFromUser:self.user1 text:messageText1 nonce:nonce1];
    }];
    WaitForEverythingToBeDone();
    
    // then
    NSArray *expectedList2 = @[conversation1, conversation4, conversation3, conversation2];
    NSIndexSet *expectedIndexes2 = [NSIndexSet indexSetWithIndex:0];
    
    XCTAssertEqualObjects(conversationList, expectedList2);
    XCTAssertEqual(conversationList[0], conversation1);
    
    XCTAssertGreaterThanOrEqual(observer.notifications.count, 1u);
    ConversationListChangeInfo *note1 = observer.notifications.lastObject;
    XCTAssertNotNil(note1);
    XCTAssertEqualObjects(note1.updatedIndexes, expectedIndexes2);
    
    ZMTextMessage *receivedMessage1 = conversation1.messages.lastObject;
    XCTAssertEqual(receivedMessage1.text, messageText1);
    
    // send second message
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> ZM_UNUSED *session) {
        [self.selfToUser2Conversation insertTextMessageFromUser:self.user1 text:messageText2 nonce:nonce2];
    }];
    WaitForEverythingToBeDone();
    
    // then
    NSArray *expectedList3 = @[conversation2, conversation1, conversation4, conversation3];
    NSIndexSet *expectedIndexes3 = [NSIndexSet indexSetWithIndex:0];
    
    XCTAssertEqualObjects(conversationList, expectedList3);
    XCTAssertEqual(conversationList[0], conversation2);
    
    XCTAssertGreaterThanOrEqual(observer.notifications.count, 2u);
    ConversationListChangeInfo *note2 = observer.notifications.lastObject;
    XCTAssertNotNil(note2);
    XCTAssertEqualObjects(note2.updatedIndexes, expectedIndexes3);
    
    ZMTextMessage *receivedMessage2 = conversation2.messages.lastObject;
    XCTAssertEqual(receivedMessage2.text, messageText2);
    
    // send first message again
    
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> ZM_UNUSED *session) {
        [self.selfToUser1Conversation insertTextMessageFromUser:self.user1 text:messageText3 nonce:nonce3];
    }];
    WaitForEverythingToBeDone();
    
    // then
    NSArray *expectedList4 = @[conversation1, conversation2, conversation4, conversation3];
    NSIndexSet *expectedIndexes4 = [NSIndexSet indexSetWithIndex:0];
    
    XCTAssertEqualObjects(conversationList, expectedList4);
    XCTAssertEqual(conversationList[0], conversation1);
    XCTAssertGreaterThanOrEqual(observer.notifications.count, 3u);
    
    ConversationListChangeInfo *note3 = observer.notifications.lastObject;
    XCTAssertNotNil(note3);
    XCTAssertEqualObjects(note3.updatedIndexes, expectedIndexes4);
    
    ZMTextMessage *receivedMessage3 = conversation1.messages.lastObject;
    XCTAssertEqual(receivedMessage3.text, messageText3);
    [observer tearDown];
}

- (void)testThatReceivingAPingInAConversationThatIsNotAtTheTopBringsItToTheTop
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    
    ZMConversationList *conversationList = [ZMConversationList conversationsInUserSession:self.userSession];
    ConversationListChangeObserver *conversationListChangeObserver = [[ConversationListChangeObserver alloc] initWithConversationList:conversationList];
    
    ZMConversation *oneToOneConversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertNotEqual(oneToOneConversation, conversationList[0]); // make sure conversation is not on top
    
    NSUInteger oneToOneIndex = [conversationList indexOfObject:oneToOneConversation];
    
    // when
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        NOT_USED(session);
        [self.selfToUser1Conversation insertKnockFromUser:self.user1 nonce:[NSUUID createUUID]];
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    ConversationListChangeInfo *note = conversationListChangeObserver.notifications.firstObject;
    XCTAssertTrue(note);
    
    NSMutableArray *moves = [NSMutableArray array];
    [note enumerateMovedIndexes:^(NSUInteger from, NSUInteger to) {
        [moves addObject:@[@(from), @(to)]];
    }];
    
    NSArray *expectedArray = @[@[@(oneToOneIndex), @0]];
    
    XCTAssertEqualObjects(moves, expectedArray);
    [conversationListChangeObserver tearDown];

}

- (void)testThatConversationGoesOnTopAfterARemoteUserAcceptsOurConnectionRequest
{
    //given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);

    ZMConversation *oneToOneConversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    MockUser *mockUser = [self createSentConnectionToUserWithName:@"Hans" uuid:NSUUID.createUUID];

    ZMConversationList *conversationList = [ZMConversationList conversationsInUserSession:self.userSession];
    ZMConversation *sentConversation = conversationList.firstObject;

    [self.mockTransportSession performRemoteChanges:^(__unused MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.selfToUser1Conversation insertTextMessageFromUser:self.selfUser text:@"some message" nonce:[NSUUID createUUID]];
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSUInteger from = [conversationList indexOfObject:sentConversation];
    XCTAssertEqualObjects(oneToOneConversation, conversationList[0]);
    NSUInteger pendingIndex = [conversationList indexOfObject:sentConversation];
    pendingIndex = conversationList.count;
    
    ConversationListChangeObserver *conversationListChangeObserver = [[ConversationListChangeObserver alloc] initWithConversationList:conversationList];
    
    //when
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [session remotelyAcceptConnectionToUser:mockUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    //then
    XCTAssertGreaterThanOrEqual(conversationListChangeObserver.notifications.count, 1u);

    NSInteger updatesCount = 0;
    __block NSMutableArray *moves = [@[] mutableCopy];
    for (ConversationListChangeInfo *note in conversationListChangeObserver.notifications) {
        updatesCount += note.updatedIndexes.count;
        [moves addObjectsFromArray:note.movedIndexPairs];
        XCTAssertTrue([note.updatedIndexes containsIndex:0]);
        //should be no deletions or insertions
        XCTAssertEqual(note.deletedIndexes.count, 0u);
        XCTAssertEqual(note.insertedIndexes.count, 0u);
    }
    XCTAssertEqual(updatesCount, 1);
    XCTAssertEqual(moves.count, 1u);
    XCTAssertEqual([(ZMMovedIndex *)moves.firstObject from], from);
    XCTAssertEqual([(ZMMovedIndex *)moves.firstObject to], 0u);

    
    XCTAssertEqualObjects(sentConversation, conversationList.firstObject);
    XCTAssertEqualObjects(oneToOneConversation, conversationList[1]);
    [conversationListChangeObserver tearDown];
}

- (void)testThatConversationGoesOnTopAfterWeAcceptIncommingConnectionRequest
{
    //given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);

    MockUser *mockUser = [self createPendingConnectionFromUserWithName:@"Hans" uuid:NSUUID.createUUID];
    ZMUser *realUser = [self userForMockUser:mockUser];
    
    ZMConversationList *pending = [ZMConversationList pendingConnectionConversationsInUserSession:self.userSession];
    XCTAssertEqual(pending.count, 1u);
    ZMConversation *pendingConnversation = pending.lastObject;

    ZMConversationList *activeConversations = [ZMConversationList conversationsInUserSession:self.userSession];
    NSUInteger activeCount = activeConversations.count;
    ConversationListChangeObserver *activeObserver = [[ConversationListChangeObserver alloc] initWithConversationList:activeConversations];
    ConversationListChangeObserver *pendingObserver = [[ConversationListChangeObserver alloc] initWithConversationList:pending];
    
    // when
    [self.userSession performChanges:^{
        [realUser accept];
    }];
    WaitForEverythingToBeDoneWithTimeout(0.5f);

    //then
    XCTAssertEqual(pending.count, 0u);
    XCTAssertEqual(activeConversations.count, activeCount + 1u);
    XCTAssertTrue([activeConversations containsObject:pendingConnversation]);
    XCTAssertEqualObjects(activeConversations.firstObject, pendingConnversation);
    
    NSInteger deletionsCount = 0;
    for (ConversationListChangeInfo *note in pendingObserver.notifications) {
        deletionsCount += note.deletedIndexes.count;
        //should be no updates, insertions, moves in pending list
        XCTAssertEqual(note.insertedIndexes.count, 0u);
        XCTAssertEqual(note.updatedIndexes.count, 0u);
        XCTAssertEqual(note.movedIndexPairs.count, 0u);
    }
    XCTAssertEqual(deletionsCount, 1);
    
    NSInteger insertionsCount = 0;
    for (ConversationListChangeInfo *note in activeObserver.notifications) {
        insertionsCount += note.insertedIndexes.count;
        //should be no deletions in active list
        XCTAssertEqual(note.deletedIndexes.count, 0u);
    }
    XCTAssertEqual(insertionsCount, 1);
    [activeObserver tearDown];
    [pendingObserver tearDown];
}

@end



@implementation ConversationTests (ArchivingAndSilencing)

- (void)testThatArchivingAConversationIsSynchronizedToTheBackend
{
    {
        // given
        [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
            // set last read
            NOT_USED(session);
            MockEvent *lastEvent = self.groupConversation.events.lastObject;
            self.groupConversation.lastRead = lastEvent.identifier;
        }];
        
        XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
        WaitForEverythingToBeDone();
        [self.mockTransportSession resetReceivedRequests];
        
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        
        // when
        [self.userSession performChanges:^{
            conversation.isArchived = YES;
        }];
        WaitForEverythingToBeDone();
        
        // then
        ZMTransportRequest *request = self.mockTransportSession.receivedRequests.firstObject;
        NSString *expectedPath = [NSString stringWithFormat:@"/conversations/%@/self", self.groupConversation.identifier];
        XCTAssertEqualObjects(request.path, expectedPath);
        XCTAssertEqual(request.method, ZMMethodPUT);
        MockEvent *lastEvent = self.groupConversation.events.lastObject;
        XCTAssertEqualObjects(request.payload[@"archived"], lastEvent.identifier);
    }
    
    // Tears down context(s) &
    // Re-create contexts
    [self recreateUserSessionAndWipeCache:YES];
    
    {
        // Wait for sync to be done
        XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
        WaitForEverythingToBeDone();
        
        // then
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        XCTAssertTrue(conversation.isArchived);
    }
    
}

- (void)testThatUnarchivingAConversationIsSynchronizedToTheBackend
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    [self.userSession performChanges:^{
        conversation.isArchived = YES;
    }];
    
    WaitForEverythingToBeDone();
    [self.mockTransportSession resetReceivedRequests];
    
    // when
    [self.userSession performChanges:^{
        conversation.isArchived = NO;
    }];
    WaitForEverythingToBeDone();
    
    // then
    ZMTransportRequest *request = self.mockTransportSession.receivedRequests.firstObject;
    NSString *expectedPath = [NSString stringWithFormat:@"/conversations/%@/self", self.groupConversation.identifier];
    XCTAssertEqualObjects(request.path, expectedPath);
    XCTAssertEqual(request.method, ZMMethodPUT);
    XCTAssertEqualObjects(request.payload[@"archived"], @"false");
}

- (void)testThatSilencingAConversationIsSynchronizedToTheBackend
{
    {
        // given
        XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
        WaitForEverythingToBeDone();
        [self.mockTransportSession resetReceivedRequests];
        
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        
        // when
        [self.userSession performChanges:^{
            conversation.isSilenced = YES;
        }];
        WaitForEverythingToBeDone();
        
        // then
        ZMTransportRequest *request = self.mockTransportSession.receivedRequests.firstObject;
        NSString *expectedPath = [NSString stringWithFormat:@"/conversations/%@/self", self.groupConversation.identifier];
        XCTAssertEqualObjects(request.path, expectedPath);
        XCTAssertEqual(request.method, ZMMethodPUT);
        XCTAssertEqualObjects(request.payload[@"muted"], @1);
    }
    
    // Tears down context(s) &
    // Re-create contexts
    [self recreateUserSessionAndWipeCache:YES];
    
    {
        // Wait for sync to be done
        XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
        WaitForEverythingToBeDone();
        
        // then
        ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
        XCTAssertTrue(conversation.isSilenced);
    }

}

- (void)testThatUnsilencingAConversationIsSynchronizedToTheBackend
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    [self.userSession performChanges:^{
        conversation.isSilenced = YES;
    }];
    
    WaitForEverythingToBeDone();
    [self.mockTransportSession resetReceivedRequests];
    
    // when
    [self.userSession performChanges:^{
        conversation.isSilenced = NO;
    }];
    WaitForEverythingToBeDone();
    
    // then
    ZMTransportRequest *request = self.mockTransportSession.receivedRequests.firstObject;
    NSString *expectedPath = [NSString stringWithFormat:@"/conversations/%@/self", self.groupConversation.identifier];
    XCTAssertEqualObjects(request.path, expectedPath);
    XCTAssertEqual(request.method, ZMMethodPUT);
    XCTAssertEqualObjects(request.payload[@"muted"], @0);
    
}

- (void)testThatWhenBlockingAUserTheOneOnOneConversationIsRemovedFromTheConversationList
{
    // login
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    // given
    
    ZMUser *user1 = [self userForMockUser:self.user1];
    (void) user1.name;
    XCTAssertFalse(user1.isBlocked);

    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    (void) conversation.messages; // Make sure we've faulted in the messages
    XCTAssertNotNil(conversation);
    XCTAssertEqualObjects(conversation.connectedUser, user1);
    XCTAssertEqual(conversation.conversationType, ZMConversationTypeOneOnOne);

    ZMConversationList *active = [ZMConversationList conversationsInUserSession:self.userSession];
    XCTAssertEqual(active.count, 4u);
    XCTAssertTrue([active containsObject:conversation]);

    ConversationListChangeObserver *observer = [[ConversationListChangeObserver alloc] initWithConversationList:active];
    
    // when blocking user 1
    
    [self.userSession performChanges:^{
        [user1 block];
    }];
    WaitForEverythingToBeDone();
    
    // then the conversation should not be in the active list anymore
    XCTAssertTrue(user1.isBlocked);
    XCTAssertEqual(conversation.connection.status, ZMConnectionStatusBlocked);

    XCTAssertEqual(active.count, 3u);
    XCTAssertFalse([active containsObject:conversation]);
    [observer tearDown];
}


- (void)checkThatItUnarchives:(BOOL)shouldUnarchive silenced:(BOOL)isSilenced mockConversation:(MockConversation *)mockConversation withBlock:(void (^)(MockTransportSession<MockTransportSessionObjectCreation> *session))block
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    ZMConversation *conversation = [self conversationForMockConversation:mockConversation];
    [self.userSession performChanges:^{
        conversation.isArchived = YES;
        if (isSilenced) {
            conversation.isSilenced = YES;
        }
    }];
    WaitForEverythingToBeDone();
    XCTAssertTrue(conversation.isArchived);
    if (isSilenced) {
        XCTAssertTrue(conversation.isSilenced);
    }
    
    // when
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        block(session);
    }];
    WaitForEverythingToBeDone();
    
    // then
    if (shouldUnarchive) {
        XCTAssertFalse(conversation.isArchived);
    } else {
        XCTAssertTrue(conversation.isArchived);
    }
}

- (void)testThatAddingAMessageToAnArchivedConversation_Unarchives_ThisConversation
{
    // expect
    BOOL shouldUnarchive = YES;
    
    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:NO mockConversation:self.groupConversation withBlock:^(ZM_UNUSED id session) {
        [self.groupConversation insertTextMessageFromUser:self.selfUser text:@"Some text" nonce:[NSUUID createUUID]];
    }];
}

- (void)testThatAddingAMessageToAnArchived_AndSilenced_Conversation_DoesNotUnarchive_ThisConversation
{
    // expect
    BOOL shouldUnarchive = NO;
    
    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:YES mockConversation:self.groupConversation withBlock:^(ZM_UNUSED id session) {
        [self.groupConversation insertTextMessageFromUser:self.selfUser text:@"Some text" nonce:[NSUUID createUUID]];
    }];
}

- (void)testThatAddingAnImageToAnArchivedConversation_Unarchives_ThisConversation
{
    // expect
    BOOL shouldUnarchive = YES;
    
    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:NO mockConversation:self.groupConversation withBlock:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation insertImageEventsFromUser:session.selfUser];
    }];
}

- (void)testThatAddingAnImageToAnArchived_AndSilenced_Conversation_DoesNotUnarchive_ThisConversation
{
    // expect
    BOOL shouldUnarchive = NO;
    
    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:YES mockConversation:self.groupConversation withBlock:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation insertImageEventsFromUser:session.selfUser];
    }];
}

- (void)testThatAddingAnKnockToAnArchivedConversation_Unarchives_ThisConversation
{
    // expect
    BOOL shouldUnarchive = YES;
    
    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:NO mockConversation:self.groupConversation withBlock:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation insertKnockFromUser:session.selfUser nonce:NSUUID.createUUID];
    }];
}

- (void)testThatAddingAnKnockToAnArchived_AndSilenced_Conversation_DoesNotUnarchive_ThisConversation
{
    // expect
    BOOL shouldUnarchive = NO;
    
    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:YES mockConversation:self.groupConversation withBlock:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation insertKnockFromUser:session.selfUser nonce:NSUUID.createUUID];
    }];
}

- (void)testThatAddingUsersToAnArchivedConversation_Unarchives_ThisConversation
{
    // expect
    BOOL shouldUnarchive = YES;
    
    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:NO mockConversation:self.groupConversation withBlock:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation addUsersByUser:session.selfUser addedUsers:@[self.user5]];
    }];
}

- (void)testThatAddingUsersToAnArchived_AndSilenced_Conversation_DoesNotUnarchive_ThisConversation
{
    // expect
    BOOL shouldUnarchive = NO;
    
    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:YES mockConversation:self.groupConversation withBlock:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation addUsersByUser:session.selfUser addedUsers:@[self.user5]];
    }];
}

- (void)testThatRemovingUsersFromAnArchivedConversation_Unarchives_ThisConversation
{
    // expect
    BOOL shouldUnarchive = YES;
    
    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:NO mockConversation:self.groupConversation withBlock:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation removeUsersByUser:session.selfUser removedUser:self.user2];
    }];
}

- (void)testThatRemovingUsersFromAnArchived_AndSilenced_Conversation_DoesNotUnarchive_ThisConversation
{
    // expect
    BOOL shouldUnarchive = NO;
    
    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:YES mockConversation:self.groupConversation withBlock:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation removeUsersByUser:session.selfUser removedUser:self.user2];
    }];
}

- (void)testThatRemovingSelfUserFromAnArchivedConversation_DoesNotUnarchive_ThisConversation
{
    // expect
    BOOL shouldUnarchive = NO;

    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:NO mockConversation:self.groupConversation withBlock:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation removeUsersByUser:session.selfUser removedUser:session.selfUser];
    }];
}

- (void)testThatRemovingSelfUserFromAnArchived_AndSilenced_Conversation_DoesNotUnarchive_ThisConversation
{
    // expect
    BOOL shouldUnarchive = NO;
    
    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:YES mockConversation:self.groupConversation withBlock:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [self.groupConversation removeUsersByUser:session.selfUser removedUser:session.selfUser];
    }];
}

- (void)testThatCallingAnArchived_AndSilenced_Conversation_Unarchives_ThisConversation
{
    // expect
    BOOL shouldUnarchive = YES;
    
    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:YES mockConversation:self.selfToUser1Conversation withBlock:^(MockTransportSession *session ZM_UNUSED) {
        [self.selfToUser1Conversation addUserToCall:self.user1];
    }];
    
    ZMConversation *syncConv = (id)[self.userSession.syncManagedObjectContext objectWithID:[self conversationForMockConversation:self.selfToUser1Conversation].objectID];
    [syncConv.voiceChannel tearDown];
}

- (void)testThatCallingAnArchivedConversation_Unarchives_ThisConversation
{
    // expect
    BOOL shouldUnarchive = YES;
    
    // when
    [self checkThatItUnarchives:shouldUnarchive silenced:NO mockConversation:self.selfToUser1Conversation withBlock:^(MockTransportSession *session ZM_UNUSED) {
        [self.selfToUser1Conversation addUserToCall:self.user1];
    }];
    ZMConversation *syncConv = (id)[self.userSession.syncManagedObjectContext objectWithID:[self conversationForMockConversation:self.selfToUser1Conversation].objectID];
    [syncConv.voiceChannel tearDown];
}

- (void)testThatAcceptingArchivedOutgoingRequest_Unarchives_ThisConversation
{
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);

    MockUser *mockUser = [self createSentConnectionToUserWithName:@"Hans" uuid:NSUUID.createUUID];
    ZMConversationList *conversations = [ZMConversationList conversationsInUserSession:self.userSession];
    ZMConversation *conversation = conversations.firstObject;
    // expect
    
    BOOL shouldUnarchive = YES;
    
    // when
    [self.userSession performChanges:^{
        conversation.isArchived = YES;
    }];
    WaitForEverythingToBeDone();
    XCTAssertTrue(conversation.isArchived);
    
    // when
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        [session remotelyAcceptConnectionToUser:mockUser];
    }];
    WaitForEverythingToBeDone();
    
    // then
    if (shouldUnarchive) {
        XCTAssertFalse(conversation.isArchived);
    } else {
        XCTAssertTrue(conversation.isArchived);
    }
}

@end



@implementation ConversationTests (LastRead)

- (void)testThatEstimatedUnreadCountIsIncreasedAfterRecevingATextMessage
{
    // given
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        NOT_USED(session);
        [self.selfToUser1Conversation insertTextMessageFromUser:self.user1 text:@"Will insert this to have a message to read" nonce:[NSUUID createUUID]];
        MockEvent *lastEvent = self.selfToUser1Conversation.events.lastObject;
        self.selfToUser1Conversation.lastRead = lastEvent.identifier;
    }];
    
    // login
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertEqual(conversation.estimatedUnreadCount, 0u);
    
    // when
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        NOT_USED(session);
        [self.selfToUser1Conversation insertTextMessageFromUser:self.user1 text:@"This should increase the unread count" nonce:[NSUUID createUUID]];
    }];
    WaitForEverythingToBeDone();
    
    // then
    XCTAssertEqual(conversation.estimatedUnreadCount, 1u);
}


- (void)testThatLastReadIsAutomaticallyIncreasedInCaseOfCallEvents
{
    // given
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        NOT_USED(session);
        [self.selfToUser1Conversation insertTextMessageFromUser:self.user1 text:@"Will insert this to have a message to read" nonce:[NSUUID createUUID]];
        MockEvent *lastEvent = self.selfToUser1Conversation.events.lastObject;
        self.selfToUser1Conversation.lastRead = lastEvent.identifier;
    }];
    
    // login
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    XCTAssertEqual(conversation.estimatedUnreadCount, 0u);
    
    // when
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        NOT_USED(session);
        [self.selfToUser1Conversation addUserToCall:self.user1];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(conversation.estimatedUnreadCount, 0u);

    // when
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        NOT_USED(session);
        [self.selfToUser1Conversation callEndedEventFromUser:self.user1 selfUser:self.selfUser];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqual(conversation.estimatedUnreadCount, 1u);

    ZMConversation *syncConv = (id)[self.userSession.syncManagedObjectContext objectWithID:[self conversationForMockConversation:self.selfToUser1Conversation].objectID];
    [syncConv.voiceChannel tearDown];
}

@end


@implementation ConversationTests (Pagination)

- (void)setupTestThatItPaginatesConversationIDsRequests
{
    self.previousZMConversationTranscoderListPageSize = ZMConversationTranscoderListPageSize;
    ZMConversationTranscoderListPageSize = 3;
}

- (void)testThatItPaginatesConversationIDsRequests
{
    // given
    XCTAssertEqual(ZMConversationTranscoderListPageSize, 3u);
    
    __block NSUInteger numberOfConversations;
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        for(int i = 0; i < 10; ++i) {
            [session insertGroupConversationWithSelfUser:self.selfUser otherUsers:@[self.user1, self.user2]];
        }
        
        NSFetchRequest *request = [MockConversation sortedFetchRequest];
        NSArray *conversations = [self.mockTransportSession.managedObjectContext executeFetchRequestOrAssert:request];
        numberOfConversations = conversations.count;
    }];
    
    // when
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();

    NSArray *activeConversations = [ZMConversationList conversationsInUserSession:self.userSession];
    NSArray *pendingConversations = [ZMConversationList pendingConnectionConversationsInUserSession:self.userSession];

    // then
    NSUInteger expectedRequests = (NSUInteger)(numberOfConversations * 1.f / ZMConversationTranscoderListPageSize + 0.5f);
    NSUInteger foundRequests = 0;
    for(ZMTransportRequest *request in self.mockTransportSession.receivedRequests) {
        if([request.path hasPrefix:@"/conversations/ids?size=3"]) {
            ++foundRequests;
        }
    }
    
    XCTAssertEqual(expectedRequests, foundRequests);
    XCTAssertEqual(1 + activeConversations.count + pendingConversations.count, numberOfConversations); // +1 is the self, which we don't return to UI
    
    // then
    ZMConversationTranscoderListPageSize = self.previousZMConversationTranscoderListPageSize;
}

@end


@implementation ConversationTests (ClearingHistory)

- (void)loginAndFillConversationWithMessages:(MockConversation *)mockConversation messagesCount:(NSUInteger)messagesCount
{
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    ZMConversation *conversation = [self conversationForMockConversation:mockConversation];
    
    // given
    [self.mockTransportSession performRemoteChanges:^(ZM_UNUSED id session) {
        // If the client is not registered yet we need to account for the added System Message
        for (NSUInteger i = 0; i < messagesCount - conversation.messages.count; i++) {
            [mockConversation insertTextMessageFromUser:self.selfUser text:[NSString stringWithFormat:@"foo %lu", (unsigned long)i] nonce:NSUUID.createUUID];
        }
    }];
    WaitForEverythingToBeDone();
    
    conversation = [self conversationForMockConversation:mockConversation];
    XCTAssertEqual(conversation.messages.count, messagesCount);
    
    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:5];
    XCTAssertEqual(window.messages.count, window.size);
}

- (void)testThatItNotifiesTheObserverWhenTheHistoryIsClearedAndSyncsWithTheBackend
{
    //given
    const NSUInteger messagesCount = 5;
    self.registeredOnThisDevice = YES;
    [self loginAndFillConversationWithMessages:self.groupConversation messagesCount:messagesCount];
    ZMConversationListDirectory *conversationDirectory = [self.uiMOC conversationListDirectory];
    
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    {
        ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:messagesCount];
        MessageWindowChangeToken *token = (id)[window addConversationWindowObserver:self];
        [self.mockTransportSession resetReceivedRequests];
        [self.receivedConversationWindowChangeNotifications removeAllObjects];
        
        // when
    
        [self.userSession performChanges:^{
            [conversation clearMessageHistory];
        }];
        WaitForEverythingToBeDone();
        
        // then
        XCTAssertEqual(window.messages.count, 0u);
        XCTAssertFalse([conversationDirectory.conversationsIncludingArchived containsObject:conversation]);
        
        XCTAssertEqual(self.receivedConversationWindowChangeNotifications.count, 1u);
        MessageWindowChangeInfo *info = self.receivedConversationWindowChangeNotifications[0];
        XCTAssertEqualObjects([info deletedIndexes], [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 5)]);
        
        ZMTransportRequest *firstRequest = self.mockTransportSession.receivedRequests.firstObject;
        NSString *expectedPath = [NSString stringWithFormat:@"/conversations/%@/self", conversation.remoteIdentifier.transportString];
        XCTAssertEqualObjects(firstRequest.payload[@"cleared"], conversation.lastEventID.transportString);
        XCTAssertEqualObjects(firstRequest.payload[@"archived"], conversation.lastEventID.transportString);
        XCTAssertNil(firstRequest.payload[@"last_read"]);
        XCTAssertEqualObjects(firstRequest.path, expectedPath);
        XCTAssertEqual(firstRequest.method, ZMMethodPUT);
        
        ZMUser *selfUser = [self userForMockUser:self.selfUser];
        ZMTransportRequest *lastRequest = self.mockTransportSession.receivedRequests.lastObject;
        NSString *selfConversationPath = [NSString stringWithFormat:@"/conversations/%@/otr/messages", selfUser.remoteIdentifier.transportString];
        XCTAssertNotNil(lastRequest.binaryData);
        XCTAssertEqualObjects(lastRequest.path, selfConversationPath);
        XCTAssertEqual(lastRequest.method, ZMMethodPOST);
        
        [window removeConversationWindowObserverToken:(id)token];
    }
    
    [self recreateUserSessionAndWipeCache:YES];
    WaitForEverythingToBeDone();

    {
        // Wait for sync to be done
        XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
        WaitForEverythingToBeDone();
    

        // then
        conversation = [self conversationForMockConversation:self.groupConversation];
        [conversation startFetchingMessages];
        WaitForEverythingToBeDone();

        ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:5];
        XCTAssertEqual(window.messages.count, 0u);
        XCTAssertEqual(conversation.messages.count, 0u);
        XCTAssertTrue(conversation.isArchived);
        XCTAssertFalse([conversationDirectory.conversationsIncludingArchived containsObject:conversation]);
    }
}

// TODO: test for conversations that starts with connection request

- (void)testThatItRemovesMessagesAfterReceivingAPushEventToClearHistory
{
    //given
    const NSUInteger messagesCount = 5;
    self.registeredOnThisDevice = YES;
    [self loginAndFillConversationWithMessages:self.groupConversation messagesCount:messagesCount];
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    
    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:messagesCount];
    MessageWindowChangeToken *token = (id)[window addConversationWindowObserver:self];
    
    ZMConversationListDirectory *conversationDirectory = [self.uiMOC conversationListDirectory];
    NSManagedObjectID *conversationID = conversation.objectID;
    
    // when removing messages remotely
    {
        [self.mockTransportSession performRemoteChanges:^(ZM_UNUSED id session) {
            [self.groupConversation remotelyClearHistoryFromUser:self.selfUser];
        }];
        WaitForEverythingToBeDone();
        
        // then
        XCTAssertEqual(window.messages.count, 0u);
        
        XCTAssertEqual(self.receivedConversationWindowChangeNotifications.count, 1u);
        MessageWindowChangeInfo *info = self.receivedConversationWindowChangeNotifications.firstObject;
        XCTAssertEqualObjects([info deletedIndexes], [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 5)]);
        [self.receivedConversationWindowChangeNotifications removeAllObjects];
    }
    
    // when adding new messages
    
    [self.userSession performChanges:^{
        [self spinMainQueueWithTimeout:1]; // if the message is sent within the same second of clearing the window, it will not be added when resyncing
        [conversation appendMessagesWithText:@"lalala"];
        [conversation setVisibleWindowFromMessage:conversation.messages.lastObject toMessage:conversation.messages.lastObject];
    }];
    WaitForEverythingToBeDone();

    // then
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertEqual(window.messages.count, 1u); // new message
    
    [window removeConversationWindowObserverToken:(id)token];
    
    [self recreateUserSessionAndWipeCache:YES];
    WaitForEverythingToBeDone();
    
    {
        // Wait for sync to be done
        XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
        WaitForEverythingToBeDone();
        
        // then
        conversation = [self conversationForMockConversation:self.groupConversation];
        [conversation startFetchingMessages];
        WaitForEverythingToBeDone();
        
        window = [conversation conversationWindowWithSize:messagesCount];
        XCTAssertTrue([conversationDirectory.conversationsIncludingArchived.objectIDs containsObject:conversationID]);
    }
}

- (void)testThatDeletedConversationsStayDeletedAfterResyncing
{
    //given
    const NSUInteger messagesCount = 5;
    self.registeredOnThisDevice = YES;
    [self loginAndFillConversationWithMessages:self.groupConversation messagesCount:messagesCount];
    
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertEqual(conversation.messages.count, 5lu);
    
    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:messagesCount];
    MessageWindowChangeToken *token = (id)[window addConversationWindowObserver:self];
    
    ZMConversationListDirectory *conversationDirectory = [self.uiMOC conversationListDirectory];
    NSManagedObjectID *conversationID = conversation.objectID;
    
    // when deleting the conversation remotely
    {
        [self.mockTransportSession performRemoteChanges:^(ZM_UNUSED id session) {
            [self.groupConversation remotelyDeleteFromUser:self.selfUser];
        }];
        WaitForEverythingToBeDone();
        
        // then
        XCTAssertEqual(window.messages.count, 0u);
        XCTAssertFalse([conversationDirectory.conversationsIncludingArchived containsObject:conversation]);
        
        XCTAssertEqual(self.receivedConversationWindowChangeNotifications.count, 1u);
        MessageWindowChangeInfo *info = self.receivedConversationWindowChangeNotifications.firstObject;
        XCTAssertEqualObjects([info deletedIndexes], [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 5)]);
        [self.receivedConversationWindowChangeNotifications removeAllObjects];
    }
    
    [window removeConversationWindowObserverToken:(id)token];
    [self recreateUserSessionAndWipeCache:YES];
    WaitForEverythingToBeDone();
    
    {
        // Wait for sync to be done
        XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
        WaitForEverythingToBeDone();
        
        // then
        conversation = [self conversationForMockConversation:self.groupConversation];
        [conversation startFetchingMessages];
        WaitForEverythingToBeDone();
        
        window = [conversation conversationWindowWithSize:messagesCount];
        XCTAssertEqual(window.messages.count, 0u);
        XCTAssertEqual(conversation.messages.count, 0u);
        
        XCTAssertFalse([conversationDirectory.conversationsIncludingArchived.objectIDs containsObject:conversationID]);
        XCTAssertFalse([conversationDirectory.archivedConversations.objectIDs containsObject:conversationID]);
        XCTAssertTrue([conversationDirectory.clearedConversations.objectIDs containsObject:conversationID]);
    }
}

- (void)testFirstArchivingThenClearingRemotelyShouldDeleteConversation
{
    //given
    const NSUInteger messagesCount = 5;
    [self loginAndFillConversationWithMessages:self.groupConversation messagesCount:messagesCount];
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    
    ZMConversationListDirectory *conversationDirectory = [self.uiMOC conversationListDirectory];
    NSManagedObjectID *conversationID = conversation.objectID;
    
    [self.mockTransportSession performRemoteChanges:^(ZM_UNUSED id session) {
        [self.groupConversation remotelyArchiveFromUser:self.selfUser];
    }];
    WaitForEverythingToBeDone();
    
    [self.mockTransportSession performRemoteChanges:^(ZM_UNUSED id session) {
        [self.groupConversation remotelyClearHistoryFromUser:self.selfUser];
    }];
    WaitForEverythingToBeDone();
    
    // then
    XCTAssertFalse([conversationDirectory.conversationsIncludingArchived.objectIDs containsObject:conversationID]);
}

- (void)testFirstClearingThenArchivingRemotelyShouldDeleteConversation
{
    //given
    const NSUInteger messagesCount = 5;
    [self loginAndFillConversationWithMessages:self.groupConversation messagesCount:messagesCount];
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    
    ZMConversationListDirectory *conversationDirectory = [self.uiMOC conversationListDirectory];
    NSManagedObjectID *conversationID = conversation.objectID;
    
    [self.mockTransportSession performRemoteChanges:^(ZM_UNUSED id session) {
        [self.groupConversation remotelyClearHistoryFromUser:self.selfUser];
    }];
    WaitForEverythingToBeDone();
    
    [self.mockTransportSession performRemoteChanges:^(ZM_UNUSED id session) {
        [self.groupConversation remotelyArchiveFromUser:self.selfUser];
        
    }];
    WaitForEverythingToBeDone();
    
    // then
    XCTAssertFalse([conversationDirectory.conversationsIncludingArchived.objectIDs containsObject:conversationID]);
}

- (void)testThatRemotelyArchivedConversationIsIncludedInTheCorrectConversationLists
{
    // given
    const NSUInteger messagesCount = 5;
    [self loginAndFillConversationWithMessages:self.groupConversation messagesCount:messagesCount];
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    
    ZMConversationListDirectory *conversationDirectory = [self.uiMOC conversationListDirectory];
    
    // when archiving the conversation remotely
    [self.mockTransportSession performRemoteChanges:^(ZM_UNUSED id session) {
        [self.groupConversation remotelyArchiveFromUser:self.selfUser];
    }];
    WaitForEverythingToBeDone();
    
    // then
    XCTAssertTrue([conversationDirectory.conversationsIncludingArchived containsObject:conversation]);
    XCTAssertTrue([conversationDirectory.archivedConversations containsObject:conversation]);
    XCTAssertFalse([conversationDirectory.clearedConversations containsObject:conversation]);
}

- (void)testThatRemotelyArchivedConversationIsIncludedInTheCorrectConversationListsAfterResyncing
{
    // given
    const NSUInteger messagesCount = 5;
    [self loginAndFillConversationWithMessages:self.groupConversation messagesCount:messagesCount];
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    ZMConversationListDirectory *conversationDirectory = [self.uiMOC conversationListDirectory];
    NSManagedObjectID *conversationID = conversation.objectID;
    
    // when deleting the conversation remotely, whiping the cache and resyncing
    {
        [self.mockTransportSession performRemoteChanges:^(ZM_UNUSED id session) {
            [self.groupConversation remotelyArchiveFromUser:self.selfUser];
        }];
        WaitForEverythingToBeDone();
        
        [self recreateUserSessionAndWipeCache:YES];
        WaitForEverythingToBeDone();
        XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
        WaitForAllGroupsToBeEmpty(0.5);
    }
    
    // then
    conversation = [self conversationForMockConversation:self.groupConversation];
    [conversation startFetchingMessages];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertTrue([conversationDirectory.conversationsIncludingArchived.objectIDs containsObject:conversationID]);
    XCTAssertTrue([conversationDirectory.archivedConversations.objectIDs containsObject:conversationID]);
    XCTAssertFalse([conversationDirectory.clearedConversations.objectIDs containsObject:conversationID]);
}

- (void)testThatReceivingRemoteTextMessageRevealsClearedConversation
{
    //given
    const NSUInteger messagesCount = 5;
    [self loginAndFillConversationWithMessages:self.groupConversation messagesCount:messagesCount];
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];

    [self.userSession performChanges:^{
        [conversation clearMessageHistory];
    }];
    WaitForEverythingToBeDone();
    
    XCTAssertEqual(conversation.messages.count, 0u);
    
    // when
    
    [self.mockTransportSession performRemoteChanges:^(ZM_UNUSED id session) {
        [self spinMainQueueWithTimeout:1]; // if the action happens within the same second the user clears the history, the event is not added
        [self.groupConversation insertTextMessageFromUser:self.user2 text:@"foo" nonce:NSUUID.createUUID];
    }];
    WaitForEverythingToBeDone();
    
    // then
    conversation = [self conversationForMockConversation:self.groupConversation];
    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:messagesCount];
    XCTAssertEqual(window.messages.count, 1u);
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertFalse(conversation.isArchived);
}

- (void)testThatReceivingRemoteSystemMessageRevealsClearedConversation
{
    //given
    const NSUInteger messagesCount = 5;
    [self loginAndFillConversationWithMessages:self.groupConversation messagesCount:messagesCount];
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    
    [self.userSession performChanges:^{
        [conversation clearMessageHistory];
    }];
    WaitForEverythingToBeDone();
    XCTAssertEqual(conversation.messages.count, 0u);
    // when
    
    [self.mockTransportSession performRemoteChanges:^(ZM_UNUSED id session) {
        [self spinMainQueueWithTimeout:1]; // if the action happens within the same second the user clears the history, the event is not added
        [self.groupConversation removeUsersByUser:self.user2 removedUser:self.user3];
    }];
    WaitForEverythingToBeDone();

    // then
    conversation = [self conversationForMockConversation:self.groupConversation];
    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:messagesCount];
    XCTAssertEqual(window.messages.count, 1u);
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertFalse(conversation.isArchived);
}

- (void)testThatReceivingRemoteKnockMessageRevealsClearedConversation
{
    //given
    const NSUInteger messagesCount = 5;
    [self loginAndFillConversationWithMessages:self.groupConversation messagesCount:messagesCount];
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    
    [self.userSession performChanges:^{
        [conversation clearMessageHistory];
    }];
    WaitForEverythingToBeDone();
    XCTAssertEqual(conversation.messages.count, 0u);
    // when
    
    [self.mockTransportSession performRemoteChanges:^(ZM_UNUSED id session) {
        [self spinMainQueueWithTimeout:1]; // if the action happens within the same second the user clears the history, the event is not added
        [self.groupConversation insertKnockFromUser:self.user2 nonce:[NSUUID createUUID]];
    }];
    WaitForEverythingToBeDone();
    
    // then
    conversation = [self conversationForMockConversation:self.groupConversation];
    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:messagesCount];
    XCTAssertEqual(window.messages.count, 1u);
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertFalse(conversation.isArchived);
}

- (void)testThatReceivingRemoteImageMessageRevealsClearedConversation
{
    //given
    const NSUInteger messagesCount = 5;
    [self loginAndFillConversationWithMessages:self.groupConversation messagesCount:messagesCount];
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    
    [self.userSession performChanges:^{
        [conversation clearMessageHistory];
    }];
    WaitForEverythingToBeDone();
    XCTAssertEqual(conversation.messages.count, 0u);

    // when
    
    [self.mockTransportSession performRemoteChanges:^(ZM_UNUSED id session) {
        [self spinMainQueueWithTimeout:1]; // if the action happens within the same second the user clears the history, the event is not added
        [self.groupConversation insertPreviewImageEventFromUser:self.user2 correlationID:[NSUUID createUUID] none:[NSUUID createUUID]];
    }];
    WaitForEverythingToBeDone();
    
    // then
    conversation = [self conversationForMockConversation:self.groupConversation];
    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:messagesCount];
    XCTAssertEqual(window.messages.count, 1u);
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertFalse(conversation.isArchived);
}


- (void)testThatOpeningClearedConversationRevealsIt
{
    //given
    const NSUInteger messagesCount = 5;
    [self loginAndFillConversationWithMessages:self.groupConversation messagesCount:messagesCount];
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];

    [self.userSession performChanges:^{
        [conversation clearMessageHistory];
    }];
    WaitForEverythingToBeDone();
    XCTAssertEqual(conversation.messages.count, 0u);

    // when
    
    [self.userSession performChanges:^{
        [conversation revealClearedConversation];
    }];
    WaitForEverythingToBeDone();
    
    // then
    conversation = [self conversationForMockConversation:self.groupConversation];
    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:5];
    XCTAssertEqual(window.messages.count, 0u);
    XCTAssertEqual(conversation.messages.count, 0u);
    XCTAssertFalse(conversation.isArchived);
}


- (void)testThatItSetsTheLastReadWhenReceivingARemoteLastReadThroughTheSelfConversation
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    [self.userSession performChanges:^{
        ZMMessage *message = [conversation appendMessagesWithText:@"lalala"].firstObject;
        conversation.lastReadServerTimeStamp = message.serverTimestamp;
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    NSDate *newLastRead = [conversation.lastReadServerTimeStamp dateByAddingTimeInterval:500];
    
    // when
    [self remotelyAppendSelfConversationWithZMLastReadForMockConversation:self.selfToUser1Conversation atTime:newLastRead];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual([conversation.lastReadServerTimeStamp timeIntervalSince1970], [newLastRead timeIntervalSince1970]);
}


- (void)testThatItClearsMessagesWhenReceivingARemoteClearedThroughTheSelfConversation
{
    // given
    self.registeredOnThisDevice = YES;
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    
    ZMConversation *conversation = [self conversationForMockConversation:self.selfToUser1Conversation];
    __block ZMMessage *message1;
    __block ZMMessage *message2;
    __block ZMMessage *message3;

    [self.userSession performChanges:^{
        [conversation appendMessagesWithText:@"lalala"];
        [self spinMainQueueWithTimeout:0.1]; // this is needed so the timeStamps are at least a millisecond appart
        [conversation appendMessagesWithText:@"boohoohoo"];
        [self spinMainQueueWithTimeout:0.1]; // this is needed so the timeStamps are at least a millisecond appart
        message1 = [conversation appendMessagesWithText:@"hehehe"].firstObject;
        [NSThread sleepForTimeInterval:0.2]; // this is needed so the timeStamps are at least a millisecond appart
        message2 = [conversation appendMessagesWithText:@"I will not go away"].firstObject;
        [self spinMainQueueWithTimeout:0.1]; // this is needed so the timeStamps are at least a millisecond appart
        message3 = [conversation appendMessagesWithText:@"I will stay for sure"].firstObject;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertEqual(conversation.messages.count, 5u);

    NSArray *remainingMessages = @[message2, message3];
    NSDate *cleared = message1.serverTimestamp;
    
    // when
    [self remotelyAppendSelfConversationWithZMClearedForMockConversation:self.selfToUser1Conversation atTime:cleared];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual([conversation.clearedTimeStamp timeIntervalSince1970], [cleared timeIntervalSince1970]);
    XCTAssertEqual(conversation.messages.count, 2u);
    AssertArraysContainsSameObjects(conversation.messages.array, remainingMessages);
}

@end


