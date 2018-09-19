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


#import "ZMConversationTests.h"
#import "ZMConversationList+Internal.h"


@interface ZMConversationGapsAndWindowTests : ZMConversationTestsBase
@end

@implementation ZMConversationGapsAndWindowTests


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
    XCTAssertEqualObjects(expectedParticipants, conversation.lastServerSyncedActiveParticipants);
    
}

- (void)testThatItInsertsANewConversationInUserSession
{
    // given
    id session = [OCMockObject mockForProtocol:@protocol(ZMManagedObjectContextProvider)];
    [[[session stub] andReturn:self.uiMOC] managedObjectContext];
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    
    // when
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoUserSession:session
                                                                         withParticipants:@[user1, user2, user3]
                                                                                   inTeam:nil];
    
    // then
    NSFetchRequest *fetchRequest = [ZMConversation sortedFetchRequest];
    NSArray *conversations = [self.uiMOC executeFetchRequestOrAssert:fetchRequest];
    
    XCTAssertEqual(conversations.count, 1u);
    ZMConversation *fetchedConversation = conversations[0];
    XCTAssertEqual(fetchedConversation.conversationType, ZMConversationTypeGroup);
    XCTAssertEqualObjects(conversation.objectID, fetchedConversation.objectID);
    
    NSOrderedSet *expectedParticipants = [NSOrderedSet orderedSetWithObjects:user1, user2, user3, nil];
    XCTAssertEqualObjects(expectedParticipants, conversation.lastServerSyncedActiveParticipants);
    
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
    XCTAssertEqualObjects(expectedParticipants, conversation.lastServerSyncedActiveParticipants);
    
}

- (void)testThatItReturnsTheListOfAllConversationsInTheUserSession;
{
    // given
    ZMConversation *conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation1.conversationType = ZMConversationTypeOneOnOne;
    [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC]; // this is used to make sure it doesn't return all objects
    id session = [OCMockObject mockForProtocol:@protocol(ZMManagedObjectContextProvider)];
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
    
    id session = [OCMockObject mockForProtocol:@protocol(ZMManagedObjectContextProvider)];
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
    
    id session = [OCMockObject mockForProtocol:@protocol(ZMManagedObjectContextProvider)];
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
    
    id session = [OCMockObject mockForProtocol:@protocol(ZMManagedObjectContextProvider)];
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
    conversation.draftMessage = [[DraftMessage alloc] initWithText:@"" mentions:@[]];
    
    // then
    XCTAssertFalse(conversation.hasDraftMessage);
    
    // when
    conversation.draftMessage = nil;
    
    // then
    XCTAssertFalse(conversation.hasDraftMessage);
}

- (void)testThatHasDraftMessageTextReturnsYESWhenNotEmpty;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    conversation.draftMessage = [[DraftMessage alloc] initWithText:@"A" mentions:@[]];
    
    // then
    XCTAssertTrue(conversation.hasDraftMessage);
    
    // when
    conversation.draftMessage =[[DraftMessage alloc] initWithText: @"Once upon a time" mentions:@[]];
    
    // then
    XCTAssertTrue(conversation.hasDraftMessage);
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


@end


