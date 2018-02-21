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


@import WireTesting;
#import "ZMConversationTests.h"
#import "ZMConversation+UnreadCount.h"

@interface ZMConversationUnreadCountTests : ZMConversationTestsBase
@end


@implementation ZMConversationUnreadCountTests


- (ZMMessage *)insertMessageIntoConversation:(ZMConversation *)conversation sender:(ZMUser *)sender  timeSinceLastRead:(NSTimeInterval)intervalSinceLastRead
{
    ZMMessage *message = (id)[conversation appendMessageWithText:@"holla"];
    message.serverTimestamp = [conversation.lastReadServerTimeStamp dateByAddingTimeInterval:intervalSinceLastRead];
    message.sender = sender;
    conversation.lastServerTimeStamp = message.serverTimestamp;
    return message;
}


- (void)testThatItSortsTimeStampsWhenFetchingMessages
{
    // given
    __block ZMConversation *conv;
    __block ZMMessage *excludedMessage;
    __block NSOrderedSet *expectedTimeStamps;
    
    [self.syncMOC performGroupedBlockAndWait:^{
        conv = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conv.lastReadServerTimeStamp = [NSDate date];
        ZMUser *sender = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        
        excludedMessage = [self insertMessageIntoConversation:conv sender:sender timeSinceLastRead:-5];
        ZMMessage *lastMessage = [self insertMessageIntoConversation:conv sender:sender timeSinceLastRead:15];
        ZMMessage *firstMessage = [self insertMessageIntoConversation:conv sender:sender timeSinceLastRead:5];
        ZMMessage *middleMessage = [self insertMessageIntoConversation:conv sender:sender timeSinceLastRead:10];
        [self.syncMOC saveOrRollback];
        
        expectedTimeStamps = [NSOrderedSet orderedSetWithArray:@[firstMessage.serverTimestamp, middleMessage.serverTimestamp, lastMessage.serverTimestamp]];
        
        // when
        [conv awakeFromFetch];
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self.syncMOC performGroupedBlockAndWait:^{
        // then
        XCTAssertEqual(conv.estimatedUnreadCount, 3u);
        XCTAssertFalse([conv.unreadTimeStamps containsObject:excludedMessage.serverTimestamp]);
        XCTAssertEqualObjects(conv.unreadTimeStamps, expectedTimeStamps);
    }];
}

- (void)testThatItAddsNewTimeStampsToTheEndIfTheyAreNewerThanTheLastUnread
{
    // given
    __block ZMConversation *conv;
    __block NSDate *newDate;
    __block NSOrderedSet *expectedTimeStamps;
    
    [self.syncMOC performGroupedBlockAndWait:^{
        conv = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conv.lastReadServerTimeStamp = [NSDate date];
        ZMUser *sender = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        
        ZMMessage *firstMessage = [self insertMessageIntoConversation:conv sender:sender timeSinceLastRead:5];
        [self.syncMOC saveOrRollback];
        
        newDate = [conv.lastReadServerTimeStamp dateByAddingTimeInterval:10];
        expectedTimeStamps = [NSOrderedSet orderedSetWithArray:@[firstMessage.serverTimestamp, newDate]];
        
        [conv awakeFromFetch];
    }];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self.syncMOC performGroupedBlockAndWait:^{
        // then #1
        XCTAssertEqual(conv.estimatedUnreadCount, 1u);
        // when
        [conv insertTimeStamp:newDate];
        
        // then #2
        XCTAssertEqual(conv.estimatedUnreadCount, 2u);
        XCTAssertEqualObjects(conv.unreadTimeStamps, expectedTimeStamps);
    }];
}

- (void)testThatItAddsTimeStamps
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        
        ZMConversation *conv = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conv.lastReadServerTimeStamp = [NSDate date];
        
        XCTAssertEqual(conv.estimatedUnreadCount, 0u);
        
        NSDate *olderDate = [conv.lastReadServerTimeStamp dateByAddingTimeInterval:-5];
        NSDate *newerDate = [conv.lastReadServerTimeStamp dateByAddingTimeInterval:5];
        NSDate *sameDate = [conv.lastReadServerTimeStamp dateByAddingTimeInterval:0];
        
        // when
        [conv insertTimeStamp:olderDate];
        // then
        XCTAssertEqual(conv.estimatedUnreadCount, 0u);
        
        // when
        [conv insertTimeStamp:sameDate];
        // then
        XCTAssertEqual(conv.estimatedUnreadCount, 0u);
        
        // when
        [conv insertTimeStamp:newerDate];
        // then
        XCTAssertEqual(conv.estimatedUnreadCount, 1u);
    }];
}

- (void)testThatItSortInsertsTimeStamps
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        
        ZMConversation *conv = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conv.lastReadServerTimeStamp = [NSDate date];
        
        XCTAssertEqual(conv.estimatedUnreadCount, 0u);
        
        NSDate *lastDate = [conv.lastReadServerTimeStamp dateByAddingTimeInterval:15];
        NSDate *firstDate = [conv.lastReadServerTimeStamp dateByAddingTimeInterval:5];
        NSDate *middleDate1 = [conv.lastReadServerTimeStamp dateByAddingTimeInterval:10];
        NSDate *middleDate2 = [conv.lastReadServerTimeStamp dateByAddingTimeInterval:10];
        
        NSOrderedSet *expectedTimeStamps = [NSOrderedSet orderedSetWithArray:@[firstDate, middleDate1, lastDate]];
        
        // when
        [conv insertTimeStamp:firstDate];
        [conv insertTimeStamp:lastDate];
        [conv insertTimeStamp:middleDate1];
        [conv insertTimeStamp:middleDate2];
        
        // then
        XCTAssertEqual(conv.estimatedUnreadCount, 3u);
        XCTAssertEqualObjects(conv.unreadTimeStamps, expectedTimeStamps);
    }];
}


- (void)testThatItUpdatesTheUnreadCount
{
    // given
    __block ZMConversation *conv;
    __block ZMMessage *middleMessage;
    __block ZMMessage *lastMessage;

    [self.syncMOC performGroupedBlockAndWait:^{
        conv = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conv.lastReadServerTimeStamp = [NSDate date];
        ZMUser *sender = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        
        [self insertMessageIntoConversation:conv sender:sender timeSinceLastRead:5];
        middleMessage = [self insertMessageIntoConversation:conv sender:sender timeSinceLastRead:10];
        lastMessage = [self insertMessageIntoConversation:conv sender:sender timeSinceLastRead:15];
        
        [self.syncMOC saveOrRollback];
        
        [conv awakeFromFetch];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self.syncMOC performGroupedBlockAndWait:^{
        XCTAssertEqual(conv.estimatedUnreadCount, 3u);
        // expect
        NSOrderedSet *expectedTimeStamps = [NSOrderedSet orderedSetWithArray:@[lastMessage.serverTimestamp]];
        
        // when
        conv.lastReadServerTimeStamp = middleMessage.serverTimestamp;
        [conv updateUnread]; // this is done by the conversationStatusTranscoder after merging the lastRead
        
        // then
        XCTAssertEqual(conv.estimatedUnreadCount, 1u);
        XCTAssertEqualObjects(conv.unreadTimeStamps, expectedTimeStamps);
    }];

}


@end




@implementation ZMConversationUnreadCountTests (HasUnreadMissedCall)

- (void)testThatItSetsHasUnreadMissedCallToNoWhenLastReadEqualsLastServerTime
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        ZMMessage *message1 = (id)[conversation appendMessageWithText:@"haha"];
        message1.serverTimestamp = [NSDate date];
        ZMMessage *message2 = (id)[conversation appendMessageWithText:@"huhu"];
        message2.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:10];
        
        ZMSystemMessage *missedCallMessage = [[ZMSystemMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.syncMOC];
        missedCallMessage.systemMessageType = ZMSystemMessageTypeMissedCall;
        missedCallMessage.visibleInConversation = conversation;
        missedCallMessage.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:20];
        
        conversation.lastServerTimeStamp =  [message1.serverTimestamp dateByAddingTimeInterval:30];
        
        [conversation didUpdateConversationWhileFetchingUnreadMessages];
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorMissedCall);

        // when
        conversation.lastReadServerTimeStamp = conversation.lastServerTimeStamp;
        
        // then
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorNone);
    }];
}


- (void)testThatItDoesNotClearHasUnreadMissedCallWhenMissedCallMessageIsNewerThanLastReadMessage
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{

        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        ZMMessage *message1 = (id)[conversation appendMessageWithText:@"haha"];
        message1.serverTimestamp = [NSDate date];
        ZMMessage *message2 = (id)[conversation appendMessageWithText:@"huhu"];
        message2.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:10];
        
        ZMSystemMessage *missedCallMessage = [[ZMSystemMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.syncMOC];
        missedCallMessage.systemMessageType = ZMSystemMessageTypeMissedCall;
        missedCallMessage.visibleInConversation = conversation;
        missedCallMessage.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:20];
        conversation.lastServerTimeStamp = missedCallMessage.serverTimestamp;
        
        [conversation didUpdateConversationWhileFetchingUnreadMessages];
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorMissedCall);
        XCTAssertEqual(conversation.unreadTimeStamps.count, 3UL);
        
        // when
        conversation.lastReadServerTimeStamp = message2.serverTimestamp;
        
        // then
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorMissedCall);
        XCTAssertEqual(conversation.unreadTimeStamps.count, 1UL);
    }];
}

- (void)testThatItDoesNotSetHasUnreadWhenTheSystemMessageTypeIsNotOfMissedCall
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        ZMMessage *message1 = (id)[conversation appendMessageWithText:@"haha"];
        message1.serverTimestamp = [NSDate date];
        ZMMessage *message2 = (id)[conversation appendMessageWithText:@"huhu"];
        message2.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:10];
        
        ZMSystemMessage *systemMessage = [[ZMSystemMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.syncMOC];
        systemMessage.systemMessageType = ZMSystemMessageTypeConversationNameChanged;
        systemMessage.visibleInConversation = conversation;
        systemMessage.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:20];
        
        // when
        conversation.lastReadServerTimeStamp = message2.serverTimestamp;
        conversation.lastServerTimeStamp = systemMessage.serverTimestamp;
        [conversation didUpdateConversationWhileFetchingUnreadMessages];
        
        // then
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorNone);
        XCTAssertEqual(conversation.unreadTimeStamps.count, 0UL);
    }];
}

@end



@implementation ZMConversationUnreadCountTests (HasUnreadKnock)

- (void)testThatItSetsHasUnreadKnockToNoWhenLastReadEqualsLastTimestamp
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        ZMMessage *message1 = (id)[conversation appendMessageWithText:@"haha"];
        message1.serverTimestamp = [NSDate date];
        ZMMessage *message2 = (id)[conversation appendMessageWithText:@"huhu"];
        message2.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:10];
        
        ZMKnockMessage *knockMessage = [[ZMKnockMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.syncMOC];
        knockMessage.visibleInConversation = conversation;
        message2.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:20];
        
        conversation.lastServerTimeStamp = [message1.serverTimestamp dateByAddingTimeInterval:30];
        
        [conversation didUpdateConversationWhileFetchingUnreadMessages];
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorKnock);
        
        // when
        conversation.lastReadServerTimeStamp = conversation.lastServerTimeStamp;
        
        // then
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorNone);
    }];
}


- (void)testThatItDoesNotClearHasUnreadKnockWhenKnockMessageIsNewerThanLastReadMessage
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        ZMMessage *message1 = (id)[conversation appendMessageWithText:@"haha"];
        message1.serverTimestamp = [NSDate date];
        ZMMessage *message2 = (id)[conversation appendMessageWithText:@"huhu"];
        message2.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:10];
        
        ZMKnockMessage *knockMessage = [[ZMKnockMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.syncMOC];
        knockMessage.visibleInConversation = conversation;
        knockMessage.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:20];
        conversation.lastServerTimeStamp = knockMessage.serverTimestamp;
        
        [conversation didUpdateConversationWhileFetchingUnreadMessages];
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorKnock);
        
        // when
        conversation.lastReadServerTimeStamp = message2.serverTimestamp;
        
        // then
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorKnock);
    }];
}

@end



@implementation ZMConversationUnreadCountTests (HasUnreadUnsentMessage)

- (void)testThatItResetsHasUnreadUnsentMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *message1 = (id)[conversation appendMessageWithText:@"haha"];
    ZMMessage *message2 = (id)[conversation appendMessageWithText:@"haha"];
    [message2 expire];
    
    XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorExpiredMessage);
    [self.uiMOC saveOrRollback];
    
    conversation.lastServerTimeStamp = message1.serverTimestamp;
    
    // when
    [conversation setVisibleWindowFromMessage:message1 toMessage:message2];
    WaitForAllGroupsToBeEmpty(1.0);
    
    // then
    XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorNone);
}

- (void)testThatItResetsHasUnreadUnsentMessageWhenThereAreAdditionalSentMessages
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *message1 = (id)[conversation appendMessageWithText:@"haha"];
    ZMMessage *message2 = (id)[conversation appendMessageWithText:@"haha"];
    [message2 expire];
    ZMMessage *message3 = (id)[conversation appendMessageWithText:@"haha"];
    
    XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorExpiredMessage);
    [self.uiMOC saveOrRollback];
    
    conversation.lastServerTimeStamp = message3.serverTimestamp;
    
    // when
    [conversation setVisibleWindowFromMessage:message1 toMessage:message2];
    WaitForAllGroupsToBeEmpty(1.0);
    
    // then
    XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorNone);
}

@end


