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
@import ZMCMockTransport;

#import "IntegrationTestBase.h"
#import "ZMUserSession+Internal.h"
#import "ZMConversation.h"

#import "NSManagedObjectContext+zmessaging.h"
#import "ZMMessage.h"
#import "ZMConversation.h"
#import "ZMNotifications.h"
#import "ZMConversationMessageWindow.h"

@interface TestConversationObserver : NSObject <ZMConversationObserver>

@property (nonatomic) NSMutableArray* conversationChangeNotifications;

@end




@implementation TestConversationObserver

-(instancetype)init
{
    self = [super init];
    if(self) {
        self.conversationChangeNotifications = [NSMutableArray array];
    }
    return self;
}

- (void)conversationDidChange:(ConversationChangeInfo *)note;
{
    [self.conversationChangeNotifications addObject:note];
}

@end



@interface SendAndReceiveMessagesTests : IntegrationTestBase
@end




@implementation SendAndReceiveMessagesTests

- (NSString *)uniqueText
{
    return [NSString stringWithFormat:@"This is a test for %@: %@", self.name, NSUUID.createUUID.transportString];
}

- (void)testThatAfterSendingALongMessageAllMessagesGetSentAndReceived
{
    // given
    NSString *firstMessageText = [[@"BEGIN\n" stringByPaddingToLength:2000 withString:@"A" startingAtIndex:0] stringByAppendingString:@"\nEND"];
    NSString *secondMessageText = @"other message";

    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();

    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(groupConversation);

    [self.mockTransportSession resetReceivedRequests];

    // when
    __block id<ZMConversationMessage> firstMessage, secondMessage;
    [self.userSession performChanges:^{
        firstMessage = [groupConversation appendMessageWithText:firstMessageText];
        secondMessage = [groupConversation appendMessageWithText:secondMessageText];
    }];

    WaitForAllGroupsToBeEmpty(0.5);
    XCTAssertEqual(firstMessage.deliveryState, ZMDeliveryStateDelivered);
    XCTAssertEqual(secondMessage.deliveryState, ZMDeliveryStateDelivered);

    NSUInteger otrResponseCount = 0;
    NSString *otrConversationPath = [NSString stringWithFormat:@"/conversations/%@/otr/messages", self.groupConversation.identifier];

    for (ZMTransportRequest *request in self.mockTransportSession.receivedRequests) {
        if (request.method == ZMMethodPOST && [request.path isEqualToString:otrConversationPath]) {
            otrResponseCount++;
        }
    }

    // then
    XCTAssertEqual(otrResponseCount, 2lu);
    XCTAssertEqualObjects(firstMessage.messageText, firstMessageText);
    XCTAssertEqualObjects(secondMessage.messageText, secondMessageText);
}

- (void)testThatWeReceiveAMessageSentRemotely
{
    // given
    NSString *messageText = [self uniqueText];
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    ZMConversation *conversation = [self conversationForMockConversation:self.groupConversation];
    
    // when
    [self.mockTransportSession performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        NOT_USED(session);
        [self.groupConversation insertTextMessageFromUser:self.user1 text:messageText nonce:[NSUUID createUUID]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    id<ZMConversationMessage> lastMessage = conversation.messages.lastObject;
    XCTAssertEqualObjects(lastMessage.messageText, messageText);
}

- (ZMConversation *)setUpStateAndConversation {
    
    XCTAssertTrue([self logInAndWaitForSyncToBeComplete]);
    WaitForEverythingToBeDone();
    
    
    ZMConversation *groupConversation = [self conversationForMockConversation:self.groupConversation];
    XCTAssertNotNil(groupConversation);
    
    return groupConversation;
}


- (void)testThatItDoesNotSyncTheLastReadOfMessagesThatHaveNotBeenDeliveredYet
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeCompleteWithTimeout:0.6]);
    [self.mockTransportSession performRemoteChanges:^(ZM_UNUSED id session) {
        [self.groupConversation insertTextMessageFromUser:self.user1 text:@"text 1" nonce:[NSUUID UUID]];
        [self.groupConversation insertTextMessageFromUser:self.user1 text:@"text 2" nonce:[NSUUID UUID]];
        [self.groupConversation insertTextMessageFromUser:self.user1 text:@"text 3" nonce:[NSUUID UUID]];
        [self.groupConversation insertTextMessageFromUser:self.user1 text:@"text 4" nonce:[NSUUID UUID]];
        [self spinMainQueueWithTimeout:1.0];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation =  [self conversationForMockConversation:self.groupConversation];
    NSString *convIDString = conversation.remoteIdentifier.transportString;
    
    NSDate *pastDate = [[NSDate date] dateByAddingTimeInterval:-100];
    XCTAssertEqual(conversation.messages.count, 5u);
    
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request){
        if ([request.path containsString:@"messages"] && request.method == ZMMethodPOST) {
            if ([request.path containsString:convIDString]) {
                return [ZMTransportResponse responseWithTransportSessionError:[NSError requestExpiredError]];
            }
        }
        return nil;
    };
    
    // when
    ZMMessage *previousMessage =  conversation.messages.lastObject;
    
    __block ZMMessage *message;
    [self.userSession performChanges:^{
        message = [conversation appendMessageWithText:@"test"];
        [message setServerTimestamp:pastDate];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self.mockTransportSession performRemoteChanges:^(ZM_UNUSED id session) {
        [self.groupConversation insertTextMessageFromUser:self.user1 text:@"text 5" nonce:[NSUUID UUID]];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertEqualObjects(message.serverTimestamp, pastDate);
    XCTAssertEqual(message.deliveryState, ZMDeliveryStateFailedToSend);
    
    [self.userSession performChanges:^{
        [conversation setVisibleWindowFromMessage:nil toMessage:message];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertNotNil(conversation.lastReadServerTimeStamp);
    XCTAssertNotEqualWithAccuracy([conversation.lastReadServerTimeStamp timeIntervalSince1970], [message.serverTimestamp timeIntervalSince1970], 0.5);
    XCTAssertEqualWithAccuracy([conversation.lastReadServerTimeStamp timeIntervalSince1970], [previousMessage.serverTimestamp timeIntervalSince1970], 0.5);
}

- (void)testThatItSetsTheLastReadWhenInsertingAnImage
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeCompleteWithTimeout:0.6]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation =  [self conversationForMockConversation:self.groupConversation];
    NSString *convIDString = conversation.remoteIdentifier.transportString;
    
    NSDate *pastDate = [[NSDate date] dateByAddingTimeInterval:-100];
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertNil(conversation.lastReadServerTimeStamp);

    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request){
        if ([request.path containsString:@"assets"] && request.method == ZMMethodPOST && [request.path containsString:convIDString]) {
            // set the date to a previous date to make sure we see if the serverTimeStamp changes
            [self.userSession performChanges:^{
                [conversation.messages.lastObject setServerTimestamp:pastDate];
            }];
            return nil;
        }
        return nil;
    };
    
    // when
    __block ZMMessage *message;
    [self.userSession performChanges:^{
        message = [conversation appendMessageWithImageData:self.verySmallJPEGData];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertNotNil(conversation.lastReadServerTimeStamp);
    XCTAssertNotEqualWithAccuracy([conversation.lastReadServerTimeStamp timeIntervalSince1970], [pastDate timeIntervalSince1970], 1.0);
}

- (void)testThatItSetsTheLastReadWhenInsertingAText
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeCompleteWithTimeout:0.6]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation =  [self conversationForMockConversation:self.groupConversation];
    NSString *convIDString = conversation.remoteIdentifier.transportString;
    
    NSDate *pastDate = [[NSDate date] dateByAddingTimeInterval:-100];
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertNil(conversation.lastReadServerTimeStamp);
    
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request){
        if ([request.path containsString:@"assets"] && request.method == ZMMethodPOST && [request.path containsString:convIDString]) {
            // set the date to a previous date to make sure we see if the serverTimeStamp changes
            [self.userSession performChanges:^{
                [conversation.messages.lastObject setServerTimestamp:pastDate];
            }];
            return nil;
        }
        return nil;
    };
    
    // when
    __block ZMMessage *message;
    [self.userSession performChanges:^{
        message = [conversation appendMessageWithText:@"oh hallo"];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertNotNil(conversation.lastReadServerTimeStamp);
    XCTAssertNotEqualWithAccuracy([conversation.lastReadServerTimeStamp timeIntervalSince1970], [pastDate timeIntervalSince1970], 1.0);
}

- (void)testThatItSetsTheLastReadWhenInsertingAKnock
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeCompleteWithTimeout:0.6]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation =  [self conversationForMockConversation:self.groupConversation];
    NSString *convIDString = conversation.remoteIdentifier.transportString;
    
    NSDate *pastDate = [[NSDate date] dateByAddingTimeInterval:-100];
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertNil(conversation.lastReadServerTimeStamp);
    
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request){
        if ([request.path containsString:@"assets"] && request.method == ZMMethodPOST && [request.path containsString:convIDString]) {
            // set the date to a previous date to make sure we see if the serverTimeStamp changes
            [self.userSession performChanges:^{
                [conversation.messages.lastObject setServerTimestamp:pastDate];
            }];
            return nil;
        }
        return nil;
    };
    
    // when
    __block ZMMessage *message;
    [self.userSession performChanges:^{
        message = [conversation appendKnock];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertNotNil(conversation.lastReadServerTimeStamp);
    XCTAssertNotEqualWithAccuracy([conversation.lastReadServerTimeStamp timeIntervalSince1970], [pastDate timeIntervalSince1970], 1.0);
}

- (void)testThatItSetsTheLastReadWhenInsertingAMessageWithURL
{
    // given
    XCTAssertTrue([self logInAndWaitForSyncToBeCompleteWithTimeout:0.6]);
    WaitForAllGroupsToBeEmpty(0.5);
    
    ZMConversation *conversation =  [self conversationForMockConversation:self.groupConversation];
    NSString *convIDString = conversation.remoteIdentifier.transportString;
    
    NSDate *pastDate = [NSDate dateWithTimeIntervalSince1970:12333333];
    XCTAssertEqual(conversation.messages.count, 1u);
    XCTAssertNil(conversation.lastReadServerTimeStamp);
    
    self.mockTransportSession.responseGeneratorBlock = ^ZMTransportResponse *(ZMTransportRequest *request){
        if ([request.path containsString:@"assets"] && request.method == ZMMethodPOST && [request.path containsString:convIDString]) {
            // set the date to a previous date to make sure we see if the serverTimeStamp changes
            [self.userSession performChanges:^{
                [conversation.messages.lastObject setServerTimestamp:pastDate];
            }];
            return nil;
        }
        return nil;
    };
    
    // when
    __block ZMMessage *message;
    [self.userSession performChanges:^{
        NSURL *imageFileURL = [self fileURLForResource:@"1900x1500" extension:@"jpg"];
        message = [conversation appendMessageWithImageAtURL:imageFileURL];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertNotNil(conversation.lastReadServerTimeStamp);
    XCTAssertNotEqualWithAccuracy([conversation.lastReadServerTimeStamp timeIntervalSince1970], [pastDate timeIntervalSince1970], 1.0);
}

@end
