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


@import WireTransport;

#import "ZMBaseManagedObjectTest.h"
#import "ZMConversation+Internal.h"
#import "ZMMessage+Internal.h"


@interface ZMConversationMessageWindowTests : ZMBaseManagedObjectTest

- (ZMConversation *)createConversationWithMessages:(NSUInteger)numberOfMessages;
- (void)checkExpectedMessagesWithLastReadIndex:(NSUInteger)lastReadIndex
                              conversationSize:(NSUInteger)conversationSize
                                    windowSize:(NSUInteger)windowSize
               minExpectedMessageIndexInWindow:(NSUInteger)minExpectedMessage
                                          move:(NSInteger)move
                               failureRecorder:(ZMTFailureRecorder *)recorder;
- (NSOrderedSet *)messagesUntilEndOfConversation:(ZMConversation *)conversation fromIndex:(NSUInteger)from;

@property (nonatomic) MessageWindowChangeInfo* receivedWindowChangeNotification;


@end




@interface ZMConversationMessageWindowTests (Notifications) <ZMConversationMessageWindowObserver>
@end



@implementation ZMConversationMessageWindowTests

- (void)setUp
{
    [super setUp];
    
    self.receivedWindowChangeNotification = nil;
}

- (void)tearDown
{
    self.receivedWindowChangeNotification = nil;
    [super tearDown];
}

- (ZMConversation *)createConversationWithMessages:(NSUInteger)numberOfMessages firstIsSystemMessage:(BOOL)firstIsSystemMessage ofType:(ZMSystemMessageType)systemMessageType
{
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    for(NSUInteger i = 1; i < numberOfMessages+1; ++i)
    {
        ZMMessage *message;
        if (firstIsSystemMessage && i == 1) {
            message = [[ZMSystemMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
            ((ZMSystemMessage* )message).systemMessageType = systemMessageType;
        } else {
            message = [[ZMClientMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
        }
        [self addMessage:message toConversation:conversation];
    }
    
    return conversation;
}

- (void)addMessage:(ZMMessage *)message toConversation:(ZMConversation *)conversation
{
    NSDate *timeStamp = conversation.lastServerTimeStamp ? [conversation.lastServerTimeStamp dateByAddingTimeInterval:5] : [NSDate date];
    message.serverTimestamp = timeStamp;
    [message markAsSent];
    [conversation.mutableMessages addObject:message];
    conversation.lastServerTimeStamp = message.serverTimestamp;
}


- (ZMSystemMessage *)appendSystemMessageOfType:(ZMSystemMessageType)systemMessageType inConversation:(ZMConversation *)conversation
{
    ZMSystemMessage *message = [[ZMSystemMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    ((ZMSystemMessage* )message).systemMessageType = systemMessageType;
    [self addMessage:message toConversation:conversation];
    return message;
}

- (ZMConversation *)createConversationWithMessages:(NSUInteger)numberOfMessages
{
    return [self createConversationWithMessages:numberOfMessages firstIsSystemMessage:NO ofType:ZMSystemMessageTypeInvalid];
}

- (NSMutableOrderedSet *)messagesUntilEndOfConversation:(ZMConversation *)conversation fromIndex:(NSUInteger)from;
{
    NSMutableOrderedSet *messages = [NSMutableOrderedSet orderedSet];
    const NSUInteger size = conversation.messages.count;
    for(NSUInteger i = from; i < size; ++i) {
        [messages addObject:conversation.messages[i]];
    }
    return messages;
}

/// Generates a conversation, sets some parameter about the window and make sure that
/// the messages in the window match the expected ones
- (void)checkExpectedMessagesWithLastReadIndex:(NSUInteger)lastReadIndex
                              conversationSize:(NSUInteger)conversationSize
                                    windowSize:(NSUInteger)windowSize
               minExpectedMessageIndexInWindow:(NSUInteger)minExpectedMessage
                                          move:(NSInteger)move
                               failureRecorder:(ZMTFailureRecorder *)recorder
{
    ZMConversation *conversation = [self createConversationWithMessages:conversationSize];
    if(lastReadIndex != NSNotFound) {
        ZMMessage *lastRead = conversation.messages[lastReadIndex];
        conversation.lastReadServerTimeStamp = lastRead.serverTimestamp;
    } else {
        [conversation markAsRead];
        WaitForAllGroupsToBeEmpty(0.5);
    }
    NSOrderedSet *expectedMessages = [[self messagesUntilEndOfConversation:conversation fromIndex:minExpectedMessage] reversedOrderedSet];
    
    // when
    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:windowSize];
    if(move > 0) {
        [window moveDownByMessages:(NSUInteger) move];
    }
    else if(move < 0) {
        [window moveUpByMessages:(NSUInteger) -move];
    }
    
    // then
    FHAssertTrue(recorder, window != nil);
    FHAssertEqual(recorder, window.messages.count, expectedMessages.count);
    if(expectedMessages.count > 0u) {
        NSUInteger indexOfFirstActualMessage = [conversation.messages indexOfObject:expectedMessages[0]];
        NSString *errorMessage = [NSString stringWithFormat:@"Messages started at index %lu, vs. expected %lu", (unsigned long)indexOfFirstActualMessage, (unsigned long)minExpectedMessage];
        FHAssertEqualObjectsString(recorder,window.messages, expectedMessages,errorMessage);
    }
}

- (void)testThatAConversationWindowMatchesTheSizeIfThereIsNoLastRead
{
    for(NSNumber *size in @[@1,@45]) {
        
        // given
        const NSUInteger WINDOW_SIZE = (NSUInteger) size.integerValue;
        const NSUInteger CONVERSATION_SIZE = WINDOW_SIZE*2;
        const NSUInteger LAST_READ = NSNotFound;
        const NSUInteger MIN_EXPECTED_MESSAGE = CONVERSATION_SIZE-WINDOW_SIZE;
        const NSInteger MOVE = 0;
        
        // then
        [self checkExpectedMessagesWithLastReadIndex:LAST_READ conversationSize:CONVERSATION_SIZE windowSize:WINDOW_SIZE minExpectedMessageIndexInWindow:MIN_EXPECTED_MESSAGE move:MOVE failureRecorder:NewFailureRecorder()];
    }
}

- (void)testThatAConversationWindowMatchesTheSizeIfLastReadIsTheLastEvent
{

    // given
    const NSUInteger WINDOW_SIZE = 5;
    const NSUInteger CONVERSATION_SIZE = WINDOW_SIZE*2;
    const NSUInteger LAST_READ = CONVERSATION_SIZE - 1;
    const NSUInteger MIN_EXPECTED_MESSAGE = LAST_READ-WINDOW_SIZE+1;
    const NSInteger MOVE = 0;
    
    // then
    [self checkExpectedMessagesWithLastReadIndex:LAST_READ conversationSize:CONVERSATION_SIZE windowSize:WINDOW_SIZE minExpectedMessageIndexInWindow:MIN_EXPECTED_MESSAGE move:MOVE failureRecorder:NewFailureRecorder()];
    
}

- (void)testThatAConversationWindowMatchesTheSizeStartingFromLastRead
{
    // given
    const NSUInteger WINDOW_SIZE = 5;
    const NSUInteger CONVERSATION_SIZE = 20;
    const NSUInteger LAST_READ = 8;
    const NSUInteger MIN_EXPECTED_MESSAGE = LAST_READ-WINDOW_SIZE+1;
    const NSInteger MOVE = 0;
    
    // then
    [self checkExpectedMessagesWithLastReadIndex:LAST_READ conversationSize:CONVERSATION_SIZE windowSize:WINDOW_SIZE minExpectedMessageIndexInWindow:MIN_EXPECTED_MESSAGE move:MOVE failureRecorder:NewFailureRecorder()];
}

- (void)testThatAConversationWindowHasLessMessagesThanTheWindowSizeIfTheConversationHasLessMessages
{
    // given
    const NSUInteger WINDOW_SIZE = 45;
    const NSUInteger CONVERSATION_SIZE = 2;
    const NSUInteger LAST_READ = NSNotFound;
    const NSUInteger MIN_EXPECTED_MESSAGE = 0;
    const NSInteger MOVE = 0;
    
    // then
    [self checkExpectedMessagesWithLastReadIndex:LAST_READ conversationSize:CONVERSATION_SIZE windowSize:WINDOW_SIZE minExpectedMessageIndexInWindow:MIN_EXPECTED_MESSAGE move:MOVE failureRecorder:NewFailureRecorder()];
}

- (void)testThatAConversationWindowIsEmptyIfThereIsALastReadServerTimestampButNoMessages
{
    // given
    const NSUInteger WINDOW_SIZE = 5;
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastReadServerTimeStamp = [NSDate date];
    
    // when
    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:WINDOW_SIZE];
    
    // then
    XCTAssertNotNil(window);
    XCTAssertEqual(window.messages.count, 0u);
}

- (void)testThatAConversationWindowMatchesTheEntireConversationIsTheLastReadIsTheFirstMessage
{
    // given
    const NSUInteger WINDOW_SIZE = 5;
    const NSUInteger CONVERSATION_SIZE = 20;
    const NSUInteger LAST_READ = 0;
    const NSUInteger MIN_EXPECTED_MESSAGE = 0;
    const NSInteger MOVE = 0;
    
    // then
    [self checkExpectedMessagesWithLastReadIndex:LAST_READ conversationSize:CONVERSATION_SIZE windowSize:WINDOW_SIZE minExpectedMessageIndexInWindow:MIN_EXPECTED_MESSAGE move:MOVE failureRecorder:NewFailureRecorder()];
}

@end



@implementation ZMConversationMessageWindowTests (MovingWindow)

- (void)testThatAConversationWindowMovesDownAndNotifiesOfScrolling
{
    // given
    const NSUInteger WINDOW_SIZE = 5;
    const NSUInteger CONVERSATION_SIZE = 20;
    const NSUInteger LAST_READ = 10;
    const NSInteger MOVE = 4;
    const NSUInteger MIN_EXPECTED_MESSAGE = 10;

    // then
    [self checkExpectedMessagesWithLastReadIndex:LAST_READ conversationSize:CONVERSATION_SIZE windowSize:WINDOW_SIZE minExpectedMessageIndexInWindow:MIN_EXPECTED_MESSAGE move:MOVE failureRecorder:NewFailureRecorder()];
    
}

- (void)testThatAConversationWindowMovesUp
{
    // given
    const NSUInteger WINDOW_SIZE = 5;
    const NSUInteger CONVERSATION_SIZE = 20;
    const NSUInteger LAST_READ = 10;
    const NSInteger MOVE = -4;
    const NSUInteger MIN_EXPECTED_MESSAGE = 2;
    
    
    // then
    [self checkExpectedMessagesWithLastReadIndex:LAST_READ conversationSize:CONVERSATION_SIZE windowSize:WINDOW_SIZE minExpectedMessageIndexInWindow:MIN_EXPECTED_MESSAGE move:MOVE failureRecorder:NewFailureRecorder()];
    
}


- (void)testThatAConversationWindowDoesNotMoveUpWhenAlreadyAtTheFirst
{
    // given
    const NSUInteger WINDOW_SIZE = 5;
    const NSUInteger CONVERSATION_SIZE = 20;
    const NSUInteger LAST_READ = 4;
    const NSInteger MOVE = -4;
    const NSUInteger MIN_EXPECTED_MESSAGE = 0;
    
    
    // then
    [self checkExpectedMessagesWithLastReadIndex:LAST_READ conversationSize:CONVERSATION_SIZE windowSize:WINDOW_SIZE minExpectedMessageIndexInWindow:MIN_EXPECTED_MESSAGE move:MOVE failureRecorder:NewFailureRecorder()];
}

- (void)testThatAConversationWindowDoesMoveUpUntilTheSizeIsOneAndNoMore
{
    // given
    const NSUInteger WINDOW_SIZE = 5;
    const NSUInteger CONVERSATION_SIZE = 20;
    const NSUInteger LAST_READ = 15;
    const NSInteger MOVE = 10;
    const NSUInteger MIN_EXPECTED_MESSAGE = 19;
    
    
    // then
    [self checkExpectedMessagesWithLastReadIndex:LAST_READ conversationSize:CONVERSATION_SIZE windowSize:WINDOW_SIZE minExpectedMessageIndexInWindow:MIN_EXPECTED_MESSAGE move:MOVE failureRecorder:NewFailureRecorder()];
}


@end


@implementation ZMConversationMessageWindowTests (UpdateAfterChangeInConversation)

- (void)testThatWhenAddingAMessageBeforeTheWindowTheWindowHasTheSameMessages
{
    // given
    ZMConversation *conversation = [self createConversationWithMessages:15];
    ZMMessage *lastReadMessage = conversation.messages[7];
    conversation.lastReadServerTimeStamp = lastReadMessage.serverTimestamp;
    ZMConversationMessageWindow *sut = [conversation conversationWindowWithSize:5];
    ZMTextMessage *newMessage = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    
    // when
    [conversation.mutableMessages insertObject:newMessage atIndex:0];
    [sut recalculateMessages];
    
    
    // then
    NSOrderedSet *expectedMessages = [self messagesUntilEndOfConversation:conversation fromIndex:4];
    XCTAssertEqualObjects(sut.messages, expectedMessages.reversedOrderedSet);
}

- (void)testThatAddingAMessageAtTheEndDoesNotPopMessagesOffTheTopIfTheWindowFitsAllMessages
{
    // given
    ZMConversation *conversation = [self createConversationWithMessages:5];
    ZMMessage *lastReadMessage = conversation.messages[1];
    conversation.lastReadServerTimeStamp = lastReadMessage.serverTimestamp;
    ZMConversationMessageWindow *sut = [conversation conversationWindowWithSize:10];
    ZMTextMessage *newMessage = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    XCTAssertEqualObjects(sut.messages.reversedOrderedSet, conversation.messages);
    
    // when
    [conversation.mutableMessages addObject:newMessage];
    [sut recalculateMessages];
    
    // then
    XCTAssertEqualObjects(sut.messages.reversedOrderedSet, conversation.messages);
}

- (void)testThatWhenAddingAMessageInsideTheWindowTheWindowGrows
{
    // given
    ZMConversation *conversation = [self createConversationWithMessages:15];
    ZMMessage *lastReadMessage = conversation.messages[7];
    conversation.lastReadServerTimeStamp = lastReadMessage.serverTimestamp;
    ZMConversationMessageWindow *sut = [conversation conversationWindowWithSize:5];
    ZMTextMessage *newMessage = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    
    // when
    [conversation.mutableMessages insertObject:newMessage atIndex:5];
    [sut recalculateMessages];
    
    // then
    NSOrderedSet *expectedMessages = [self messagesUntilEndOfConversation:conversation fromIndex:4];
    XCTAssertEqualObjects(sut.messages, expectedMessages.reversedOrderedSet);
}

- (void)testThatUnsentPendingMessagesAreNotHiddenWhenTheConversationIsCleared
{
    // given
    ZMConversation *conversation = [self createConversationWithMessages:3];
    ZMMessage *lastReadMessage = conversation.messages.lastObject;
    conversation.lastReadServerTimeStamp = lastReadMessage.serverTimestamp;

    ZMConversationMessageWindow *sut = [conversation conversationWindowWithSize:30];
    ZMClientMessage *newMessage = [[ZMClientMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    [conversation.mutableMessages addObject:newMessage];

    // when
    [conversation clearMessageHistory];
    [sut recalculateMessages];
    
    // then
    XCTAssertEqualObjects(sut.messages, [NSOrderedSet orderedSetWithObject:newMessage]);
}

- (void)testThatDeletedMessagesAreHidden
{
    // given
    ZMConversation *conversation = [self createConversationWithMessages:1];
    ZMMessage *lastReadMessage = conversation.messages.lastObject;
    conversation.lastReadServerTimeStamp = lastReadMessage.serverTimestamp;

    ZMConversationMessageWindow *sut = [conversation conversationWindowWithSize:30];
    ZMClientMessage *newMessage = [[ZMClientMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    [conversation.mutableMessages addObject:newMessage];
    
    // when
    [sut recalculateMessages];
    
    
    // then
    NSOrderedSet *expected = [NSOrderedSet orderedSetWithArray:@[newMessage, lastReadMessage]];
    XCTAssertEqualObjects(sut.messages, expected);
    
    // given
    newMessage.hiddenInConversation = conversation;
    newMessage.visibleInConversation = nil;
    XCTAssert(newMessage.hasBeenDeleted);

    // when
    [sut recalculateMessages];
    
    // then
    XCTAssertEqualObjects(sut.messages, [NSOrderedSet orderedSetWithObject:lastReadMessage]);
}

@end


@implementation ZMConversationMessageWindowTests (ScrollingNotification)

- (void)testThatScrollingTheWindowUpCausesAScrollingNotification
{
    // given
    ZMConversation *conversation = [self createConversationWithMessages:20];
    [conversation markAsRead];
    WaitForAllGroupsToBeEmpty(0.5);
    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:10];
    
    // expect
    [self expectationForNotification:@"MessageWindowDidChangeNotification" object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        NOT_USED(notification);
        return YES;
    }];

    // when
    [window moveUpByMessages:10];

    // then
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}

@end


