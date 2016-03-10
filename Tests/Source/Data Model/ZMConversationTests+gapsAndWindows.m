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


#import "ZMConversationTests.h"
#import "ZMConversationList+Internal.h"


@implementation ZMConversationTests (ConversationWindow)


- (void)testThatThereIsNoGapForAnEmptyConversation
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // then
    XCTAssertNil([conversation lastEventIDGapForVisibleWindow:nil]);
}

- (void)testThatThereIsNoGapWhenLastReadIsSetButLastEventIsNotSet
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastReadEventID = [self createEventID];
    
    // then
    XCTAssertNil([conversation lastEventIDGapForVisibleWindow:nil]);
}

- (void)testThatTheDefaultGapWindowIncludesLastReadIDAndLastEventID
{
    // given
    ZMEventID *lastEvent = [ZMEventID eventIDWithString:@"1900.a"];
    ZMEventID *lastReadEvent = [ZMEventID eventIDWithString:@"1000.b"];
    ZMEventID *expectedWindowStart = [[ZMEventID alloc] initWithMajor:(lastReadEvent.major - ZMLeadingEventIDWindowBleed) minor:0];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastEventID = lastEvent;
    conversation.lastReadEventID = lastReadEvent;
    
    // when
    ZMEventIDRange *gap = [conversation lastEventIDGapForVisibleWindow:nil];
    
    // then
    XCTAssertTrue(gap.oldestMessage.major >= 1u);
    XCTAssertTrue([gap containsEvent:lastEvent]);
    XCTAssertTrue([gap containsEvent:lastReadEvent]);
    XCTAssertTrue([gap containsEvent:expectedWindowStart]);
    XCTAssertFalse([gap containsEvent:[[ZMEventID alloc] initWithMajor:expectedWindowStart.major-1 minor:0]]);
}

- (void)testThatFirstGapIncludesAllEventIDs
{
    // given
    ZMEventID *lastEvent = [ZMEventID eventIDWithString:@"1900.a"];
    ZMEventID *expectedWindowStart = [[ZMEventID alloc] initWithMajor:1 minor:0];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastEventID = lastEvent;
    
    // when
    ZMEventIDRange *gap = [conversation lastEventIDGap];
    
    // then
    XCTAssertTrue(gap.oldestMessage.major >= 1u);
    XCTAssertTrue([gap containsEvent:lastEvent]);
    XCTAssertTrue([gap containsEvent:expectedWindowStart]);
}

- (void)testThatFirstGapReturnsNilWithNoLastEvent
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    ZMEventIDRange *gap = [conversation lastEventIDGap];
    
    // then
    XCTAssertNil(gap);
}

- (void)testThatTheGapIncludesTheVisibleWindowAndLastReadAndLastEvent
{
    // given
    ZMEventID *lastEvent = [ZMEventID eventIDWithString:@"1900.a"];
    ZMEventID *lastReadEvent = [ZMEventID eventIDWithString:@"1000.b"];
    
    ZMEventID *visibleStart = [ZMEventID eventIDWithString:@"900.a"];
    ZMEventID *visibleEnd = [ZMEventID eventIDWithString:@"940.b"];
    ZMEventIDRange *visbleRange = [[ZMEventIDRange alloc] initWithEventIDs:@[visibleStart, visibleEnd]];
    
    ZMEventID *expectedWindowStart = [[ZMEventID alloc] initWithMajor:(visibleStart.major - ZMLeadingEventIDWindowBleed) minor:0];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastEventID = lastEvent;
    conversation.lastReadEventID = lastReadEvent;
    
    // when
    ZMEventIDRange *gap = [conversation lastEventIDGapForVisibleWindow:visbleRange];
    
    // then
    XCTAssertTrue(gap.oldestMessage.major >= 1u);
    XCTAssertTrue([gap containsEvent:lastEvent]);
    XCTAssertTrue([gap containsEvent:lastReadEvent]);
    XCTAssertTrue([gap containsEvent:visibleStart]);
    XCTAssertTrue([gap containsEvent:visibleEnd]);
    XCTAssertTrue([gap containsEvent:expectedWindowStart]);
    XCTAssertFalse([gap containsEvent:[[ZMEventID alloc] initWithMajor:expectedWindowStart.major-1 minor:0]]);
}

- (void)testThatTheGapDoesNotIncludeMessagesThatAreDownloaded
{
    // given
    ZMEventID *lastEvent = [ZMEventID eventIDWithString:@"1900.a"];
    ZMEventID *lastReadEvent = [ZMEventID eventIDWithString:@"1000.b"];
    
    
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastEventID = lastEvent;
    conversation.lastReadEventID = lastReadEvent;
    
    ZMEventID *firstDownloadedEvent = [ZMEventID eventIDWithString:@"10.a"];
    ZMEventID *lastDownloadedEvent = [[ZMEventID alloc] initWithMajor:lastReadEvent.major+100 minor:0];
    
    ZMEventID *expectedWindowStart = [[ZMEventID alloc] initWithMajor:(lastReadEvent.major - ZMLeadingEventIDWindowBleed) minor:0];
    
    [conversation addEventRangeToDownloadedEvents:[[ZMEventIDRange alloc] initWithEventIDs:@[firstDownloadedEvent, lastDownloadedEvent]]];
    ZMEventID *expectedGapStart = lastDownloadedEvent;
    
    // when
    ZMEventIDRange *gap = [conversation lastEventIDGapForVisibleWindow:nil];
    
    // then
    XCTAssertTrue(gap.oldestMessage.major >= 1u);
    XCTAssertTrue([gap containsEvent:lastEvent]);
    XCTAssertFalse([gap containsEvent:lastReadEvent]);
    XCTAssertTrue([gap containsEvent:expectedGapStart]);
    XCTAssertFalse([gap containsEvent:[[ZMEventID alloc] initWithMajor:expectedWindowStart.major-1 minor:0]]);
}

- (void)testThatSetVisibleWindowFiresANotification
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *msg1 = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    msg1.eventID = [ZMEventID eventIDWithString:@"10.a"];
    ZMMessage *msg2 = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    msg2.eventID = [ZMEventID eventIDWithString:@"20.b"];
    

    ZM_ALLOW_MISSING_SELECTOR([[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveWindowNotification:) name:ZMConversationDidChangeVisibleWindowNotification object:nil]);

    // when
    [conversation setVisibleWindowFromMessage:msg1 toMessage:msg2];
    
    // then
    XCTAssertNotNil(self.lastReceivedNotification);
    XCTAssertEqualObjects(conversation, self.lastReceivedNotification.object);
    
    NSDictionary *expectedUserInfo = @{
                                       ZMVisibleWindowLowerKey: msg1.eventID,
                                       ZMVisibleWindowUpperKey: msg2.eventID
                                       };
    XCTAssertEqualObjects(self.lastReceivedNotification.userInfo, expectedUserInfo);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)testThatSetVisibleWindowFiresANotificationWithInvertedMessageOrder
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *msg1 = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    msg1.eventID = [ZMEventID eventIDWithString:@"10.a"];
    ZMMessage *msg2 = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    msg2.eventID = [ZMEventID eventIDWithString:@"20.b"];
    msg2.serverTimestamp = [msg1.serverTimestamp dateByAddingTimeInterval:1];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveWindowNotification:) name:ZMConversationDidChangeVisibleWindowNotification object:nil];
    
    // when
    [conversation setVisibleWindowFromMessage:msg2 toMessage:msg1];
    
    // then
    XCTAssertNotNil(self.lastReceivedNotification);
    XCTAssertEqualObjects(conversation, self.lastReceivedNotification.object);
    
    NSDictionary *expectedUserInfo = @{
                                       ZMVisibleWindowLowerKey: msg1.eventID,
                                       ZMVisibleWindowUpperKey: msg2.eventID
                                       };
    XCTAssertEqualObjects(self.lastReceivedNotification.userInfo, expectedUserInfo);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)testThatSetVisibleWindowFiresANotificationWithMissingLowerEvent
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *msg2 = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    msg2.eventID = [ZMEventID eventIDWithString:@"20.b"];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveWindowNotification:) name:ZMConversationDidChangeVisibleWindowNotification object:nil];
    
    // when
    [conversation setVisibleWindowFromMessage:nil toMessage:msg2];
    
    // then
    XCTAssertNotNil(self.lastReceivedNotification);
    XCTAssertEqualObjects(conversation, self.lastReceivedNotification.object);
    
    NSDictionary *expectedUserInfo = @{
                                       ZMVisibleWindowUpperKey: msg2.eventID
                                       };
    XCTAssertEqualObjects(self.lastReceivedNotification.userInfo, expectedUserInfo);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)testThatSetVisibleWindowFiresANotificationWithMissingUpperEvent
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *msg1 = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    msg1.eventID = [ZMEventID eventIDWithString:@"10.a"];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveWindowNotification:) name:ZMConversationDidChangeVisibleWindowNotification object:nil];
    
    // when
    [conversation setVisibleWindowFromMessage:msg1 toMessage:nil];
    
    // then
    XCTAssertNotNil(self.lastReceivedNotification);
    XCTAssertEqualObjects(conversation, self.lastReceivedNotification.object);
    
    NSDictionary *expectedUserInfo = @{
                                       ZMVisibleWindowLowerKey: msg1.eventID,
                                       };
    XCTAssertEqualObjects(self.lastReceivedNotification.userInfo, expectedUserInfo);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)testThatSetVisibleWindowFiresANotificationWithEvent1WithoutEventID
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *msg1 = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *msg2 = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    msg2.eventID = [ZMEventID eventIDWithString:@"20.b"];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveWindowNotification:) name:ZMConversationDidChangeVisibleWindowNotification object:nil];
    
    // when
    [conversation setVisibleWindowFromMessage:msg1 toMessage:msg2];
    
    // then
    XCTAssertNotNil(self.lastReceivedNotification);
    XCTAssertEqualObjects(conversation, self.lastReceivedNotification.object);
    
    NSDictionary *expectedUserInfo = @{
                                       ZMVisibleWindowUpperKey: msg2.eventID
                                       };
    XCTAssertEqualObjects(self.lastReceivedNotification.userInfo, expectedUserInfo);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)testThatSetVisibleWindowFiresANotificationWithEvent2WithoutEventID
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *msg1 = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    msg1.eventID = [ZMEventID eventIDWithString:@"10.a"];
    ZMMessage *msg2 = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveWindowNotification:) name:ZMConversationDidChangeVisibleWindowNotification object:nil];
    
    // when
    [conversation setVisibleWindowFromMessage:msg1 toMessage:msg2];
    
    // then
    XCTAssertNotNil(self.lastReceivedNotification);
    XCTAssertEqualObjects(conversation, self.lastReceivedNotification.object);
    
    NSDictionary *expectedUserInfo = @{
                                       ZMVisibleWindowLowerKey: msg1.eventID,
                                       };
    XCTAssertEqualObjects(self.lastReceivedNotification.userInfo, expectedUserInfo);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)testThatItInsertsANewConversation
{
    // given
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    
    // when
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:@[
                                                                                                                user1, user2, user3
                                                                                                                ]];
    
    // then
    NSArray *conversations = [ZMConversation conversationsIncludingArchivedInContext:self.uiMOC];
    
    XCTAssertEqual(conversations.count, 1u);
    ZMConversation *fetchedConversation = conversations[0];
    XCTAssertEqual(fetchedConversation.conversationType, ZMConversationTypeGroup);
    XCTAssertEqualObjects(conversation.objectID, fetchedConversation.objectID);
    
    NSOrderedSet *expectedParticipants = [NSOrderedSet orderedSetWithObjects:user1, user2, user3, nil];
    XCTAssertEqualObjects(expectedParticipants, conversation.otherActiveParticipants);
    
}

- (void)testThatItInsertsANewConversationInUserSession
{
    // given
    id session = [OCMockObject mockForClass:ZMUserSession.class];
    [[[session stub] andReturn:self.uiMOC] managedObjectContext];
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    
    // when
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoUserSession:session
                                                                         withParticipants:@[user1, user2, user3]];
    
    // then
    NSFetchRequest *fetchRequest = [ZMConversation sortedFetchRequest];
    NSArray *conversations = [self.uiMOC executeFetchRequestOrAssert:fetchRequest];
    
    XCTAssertEqual(conversations.count, 1u);
    ZMConversation *fetchedConversation = conversations[0];
    XCTAssertEqual(fetchedConversation.conversationType, ZMConversationTypeGroup);
    XCTAssertEqualObjects(conversation.objectID, fetchedConversation.objectID);
    
    NSOrderedSet *expectedParticipants = [NSOrderedSet orderedSetWithObjects:user1, user2, user3, nil];
    XCTAssertEqualObjects(expectedParticipants, conversation.otherActiveParticipants);
    
}

- (void)testThatItInsertsANewConversationInUIContext
{
    // given
    
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user3 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:@[
                                                                                                                user1, user2, user3
                                                                                                                ]];
    
    NSError *error;
    XCTAssertTrue([self.uiMOC save:&error], @"Error: %@", error);
    
    
    // then
    XCTAssertNotNil(conversation);
    
    NSFetchRequest *fetchRequest = [ZMConversation sortedFetchRequest];
    NSArray *conversations = [self.uiMOC executeFetchRequestOrAssert:fetchRequest];
    
    XCTAssertEqual(conversations.count, 1u);
    ZMConversation *fetchedConversation = conversations[0];
    XCTAssertEqualObjects(conversation.objectID, fetchedConversation.objectID);
    
    NSOrderedSet *expectedParticipants = [NSOrderedSet orderedSetWithObjects:user1, user2, user3, nil];
    XCTAssertEqualObjects(expectedParticipants, conversation.otherActiveParticipants);
    
}

- (void)testThatItReturnsTheListOfAllConversationsInTheUserSession;
{
    // given
    ZMConversation *conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation1.conversationType = ZMConversationTypeOneOnOne;
    [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC]; // this is used to make sure it doesn't return all objects
    id session = [OCMockObject mockForClass:ZMUserSession.class];
    [[[session stub] andReturn:self.uiMOC] managedObjectContext];
    
    [self.uiMOC processPendingChanges];
    
    // when
    NSArray *fetchedConversations = [ZMConversationList conversationsInUserSession:session];
    
    // then
    XCTAssertNotNil(fetchedConversations);
    XCTAssertEqual(1u, fetchedConversations.count);
    XCTAssertNotEqual([fetchedConversations indexOfObjectIdenticalTo:conversation1], (NSUInteger) NSNotFound);
}


- (void)testThatItReturnsTheListOfAllincomingConnectionConversationsConnectionsInTheUserSession;
{
    // given
    ZMConversation *nonPendingConnectionConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    nonPendingConnectionConversation.conversationType = ZMConversationTypeOneOnOne;
    ZMConnection *nonPendingConnection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    nonPendingConnection.status = ZMConnectionStatusAccepted;
    nonPendingConnection.conversation = nonPendingConnectionConversation;
    
    ZMConversation *pendingConnectionConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    pendingConnectionConversation.conversationType = ZMConversationTypeConnection;
    ZMConnection *pendingConnection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    pendingConnection.status = ZMConnectionStatusPending;
    pendingConnection.conversation = pendingConnectionConversation;
    
    id session = [OCMockObject mockForClass:ZMUserSession.class];
    [[[session stub] andReturn:self.uiMOC] managedObjectContext];
    
    [self.uiMOC processPendingChanges];
    
    // when
    NSArray *fetchedConversations = [ZMConversationList pendingConnectionConversationsInUserSession:session];
    
    // then
    XCTAssertNotNil(fetchedConversations);
    XCTAssertEqual(1u, fetchedConversations.count);
    XCTAssertNotEqual([fetchedConversations indexOfObjectIdenticalTo:pendingConnectionConversation], (NSUInteger) NSNotFound);
}


- (void)testThatItReturnsTheListOfAllConversationWithoutASave
{
    // given
    ZMConversation *conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation1.userDefinedName = @"Foo++";
    conversation1.conversationType = ZMConversationTypeOneOnOne;
    ZMConversation *conversation2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation2.userDefinedName = @"Bar--";
    conversation2.conversationType = ZMConversationTypeGroup;
    
    [self.uiMOC processPendingChanges];
    
    id session = [OCMockObject mockForClass:ZMUserSession.class];
    [[[session stub] andReturn:self.uiMOC] managedObjectContext];
    
    // when
    NSArray *fetchedConversations = [ZMConversationList conversationsIncludingArchivedInUserSession:session];
    
    // then
    XCTAssertNotNil(fetchedConversations);
    XCTAssertEqual(2u, fetchedConversations.count);
    XCTAssertNotEqual([fetchedConversations indexOfObjectIdenticalTo:conversation1], (NSUInteger) NSNotFound);
    XCTAssertNotEqual([fetchedConversations indexOfObjectIdenticalTo:conversation2], (NSUInteger) NSNotFound);
}

- (void)testThatItReturnsTheListOfAllConversationWithASave
{
    // given
    ZMConversation *conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation1.userDefinedName = @"Foo++";
    conversation1.conversationType = ZMConversationTypeOneOnOne;
    ZMConversation *conversation2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation2.userDefinedName = @"Bar--";
    conversation2.conversationType = ZMConversationTypeGroup;
    
    XCTAssertTrue([self.uiMOC saveOrRollback]);
    
    id session = [OCMockObject mockForClass:ZMUserSession.class];
    [[[session stub] andReturn:self.uiMOC] managedObjectContext];
    
    // when
    NSArray *fetchedConversations = [ZMConversationList conversationsIncludingArchivedInUserSession:session];
    
    // then
    XCTAssertNotNil(fetchedConversations);
    XCTAssertEqual(2u, fetchedConversations.count);
    XCTAssertNotEqual([fetchedConversations indexOfObjectIdenticalTo:conversation1], (NSUInteger) NSNotFound);
    XCTAssertNotEqual([fetchedConversations indexOfObjectIdenticalTo:conversation2], (NSUInteger) NSNotFound);
}

- (void)testThatHasDraftMessageTextReturnsNOWhenEmpty;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    conversation.draftMessageText = @"";
    
    // then
    XCTAssertFalse(conversation.hasDraftMessageText);
    
    // when
    conversation.draftMessageText = nil;
    
    // then
    XCTAssertFalse(conversation.hasDraftMessageText);
}

- (void)testThatHasDraftMessageTextReturnsYESWhenNotEmpty;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    conversation.draftMessageText = @"A";
    
    // then
    XCTAssertTrue(conversation.hasDraftMessageText);
    
    // when
    conversation.draftMessageText = @"Once upon a time";
    
    // then
    XCTAssertTrue(conversation.hasDraftMessageText);
}


- (void)testThatTheConversationIsNotSilencedByDefault
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // then
    XCTAssertFalse(conversation.isSilenced);
}

- (void)testThatTheConversationIsNotArchivedByDefault
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // then
    XCTAssertFalse(conversation.isArchived);
}

// We were seeing dowload requests for gap "6e.0 - 6e.800112314201e38b", where 6 was "lastEvent - LeadingEventIDWindowBleed"
// test that we don't later consider 6e.0 as an actual message to be downloaded
- (void)testThatTheEventCalculatedWithTheLeadingWindowBleedIsNotActuallyExpectedToBeDownloaded
{
    // given
    ZMEventID *lastEvent = [ZMEventID eventIDWithString:@"90a.800112314201e38b"];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastEventID = lastEvent;
    conversation.lastReadEventID = lastEvent;
    
    ZMEventIDRange *gap = [conversation lastEventIDGapForVisibleWindow:nil];
    
    // when
    ZMEventID *lowestDowloadedMessage = [ZMEventID eventIDWithMajor:gap.oldestMessage.major  minor:3535234];
    ZMEventID *highestDowloadedMessage = gap.newestMessage;
    
    [conversation addEventRangeToDownloadedEvents:[[ZMEventIDRange alloc] initWithEventIDs:@[lowestDowloadedMessage, highestDowloadedMessage]]];
    
    // then
    ZMEventIDRange *gap2 = [conversation lastEventIDGapForVisibleWindow:nil];
    XCTAssertNil(gap2);
}


@end


