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


@import WireDataModel;
#import "ZMBaseManagedObjectTest.h"
#import "ZMConversationListDirectory.h"
#import "ZMConversation+Internal.h"
#import "ZMConnection+Internal.h"
#import "ZMUser+Internal.h"
#import <WireDataModel/WireDataModel-Swift.h>

@interface ZMConversationListDirectoryTests : ZMBaseManagedObjectTest

@property (nonatomic) NSMutableArray *conversations;

@property (nonatomic) ZMConversation *archivedGroupConversation;
@property (nonatomic) ZMConversation *archivedOneToOneConversation;
@property (nonatomic) ZMConversation *incomingPendingConnectionConversation;
@property (nonatomic) ZMConversation *outgoingPendingConnectionConversation;
@property (nonatomic) ZMConversation *invalidConversation;
@property (nonatomic) ZMConversation *groupConversation;
@property (nonatomic) ZMConversation *oneToOneConversation;
@property (nonatomic) ZMConversation *clearedConversation;

@end



@implementation ZMConversationListDirectoryTests

- (ZMConversation *)createConversation
{
    ZMConversation *conv = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conv.lastServerTimeStamp = [NSDate date];
    conv.lastReadServerTimeStamp = conv.lastServerTimeStamp;
    conv.remoteIdentifier = [NSUUID createUUID];
    return conv;
}

- (void)setUp
{
    [super setUp];
    
    ZMUser *otherUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    otherUser.remoteIdentifier = [NSUUID createUUID];
    
    self.archivedGroupConversation = [self createConversation];
    self.archivedGroupConversation.conversationType = ZMConversationTypeGroup;
    self.archivedGroupConversation.isArchived = YES;
    self.archivedGroupConversation.userDefinedName = @"archivedGroupConversation";
    
    self.archivedOneToOneConversation = [self createConversation];
    self.archivedOneToOneConversation.conversationType = ZMConversationTypeOneOnOne;
    self.archivedOneToOneConversation.isArchived = YES;
    self.archivedOneToOneConversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    self.archivedOneToOneConversation.connection.status = ZMConnectionStatusAccepted;
    self.archivedOneToOneConversation.userDefinedName = @"archivedOneToOneConversation";
    
    self.incomingPendingConnectionConversation = [self createConversation];
    self.incomingPendingConnectionConversation.conversationType = ZMConversationTypeConnection;
    self.incomingPendingConnectionConversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    self.incomingPendingConnectionConversation.connection.status = ZMConnectionStatusPending;
    self.incomingPendingConnectionConversation.userDefinedName = @"incomingPendingConnectionConversation";
    
    self.outgoingPendingConnectionConversation = [self createConversation];
    self.outgoingPendingConnectionConversation.conversationType = ZMConversationTypeConnection;
    self.outgoingPendingConnectionConversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    self.outgoingPendingConnectionConversation.connection.status = ZMConnectionStatusSent;
    self.outgoingPendingConnectionConversation.userDefinedName = @"outgoingConnectionConversation";
    
    self.groupConversation = [self createConversation];
    self.groupConversation.conversationType = ZMConversationTypeGroup;
    self.groupConversation.userDefinedName = @"groupConversation";
    
    self.oneToOneConversation = [self createConversation];
    self.oneToOneConversation.conversationType = ZMConversationTypeOneOnOne;
    self.oneToOneConversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    self.oneToOneConversation.connection.status = ZMConnectionStatusAccepted;
    self.oneToOneConversation.userDefinedName = @"oneToOneConversation";
    
    self.invalidConversation = [self createConversation];
    self.invalidConversation.conversationType = ZMConversationTypeInvalid;
    self.invalidConversation.userDefinedName = @"invalidConversation";
    
    self.clearedConversation = [self createConversation];
    self.clearedConversation.conversationType = ZMConversationTypeOneOnOne;
    self.clearedConversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    self.clearedConversation.connection.status = ZMConnectionStatusAccepted;
    self.clearedConversation.userDefinedName = @"clearedConversation";
    self.clearedConversation.clearedTimeStamp = self.clearedConversation.lastServerTimeStamp;
    self.clearedConversation.isArchived = YES;

    [self.uiMOC saveOrRollback];
}

- (void)tearDown
{
    WaitForAllGroupsToBeEmpty(0.5);
    
    self.invalidConversation = nil;
    self.groupConversation = nil;
    self.incomingPendingConnectionConversation = nil;
    self.outgoingPendingConnectionConversation = nil;
    self.archivedOneToOneConversation = nil;
    self.archivedGroupConversation = nil;
    self.oneToOneConversation = nil;
    self.clearedConversation = nil;
    self.conversations = nil;
    
    [super tearDown];
}

- (void)testThatItReturnsAllConversations;
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.conversationsIncludingArchived;
    NSSet *expected = [NSSet setWithArray:@[self.archivedGroupConversation, self.archivedOneToOneConversation, self.groupConversation, self.oneToOneConversation, self.outgoingPendingConnectionConversation]];
    // then
    
    XCTAssertEqualObjects([NSSet setWithArray:list], expected);
}

- (void)testThatItReturnsUnarchivedConversations;
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.unarchivedConversations;
    NSSet *expected = [NSSet setWithArray:@[self.groupConversation, self.oneToOneConversation, self.outgoingPendingConnectionConversation]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list], expected);
}

- (void)testThatItReturnsArchivedConversations;
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.archivedConversations;
    NSSet *expected = [NSSet setWithArray:@[self.archivedGroupConversation, self.archivedOneToOneConversation]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list], expected);
}

- (void)testThatItReturnsPendingConversations;
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.pendingConnectionConversations;
    NSSet *expected = [NSSet setWithArray:@[self.incomingPendingConnectionConversation]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list], expected);
}

- (void)testThatItKeepsReturningTheSameObject
{
    // when
    ZMConversationList * list1 = self.uiMOC.conversationListDirectory.conversationsIncludingArchived;
    ZMConversationList * list2 = self.uiMOC.conversationListDirectory.conversationsIncludingArchived;
    
    //then
    XCTAssertEqual(list1, list2);
}

- (void)testThatItReturnsClearedConversations
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.clearedConversations;
    NSSet *expected = [NSSet setWithArray:@[self.clearedConversation]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list], expected);
}

- (void)testThatItNotReturnsClearedConversationsIn_ConversationsIncludingArchived
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.conversationsIncludingArchived;
    NSSet *expected = [NSSet setWithArray:@[self.clearedConversation]];
    
    // then
    // cleared conversations should not be included in conversationsIncludingArchived
    XCTAssertFalse([[NSSet setWithArray:list] intersectsSet:expected]);
}

- (void)testThatItsReturnsGroupConversations
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.groupConversations;
    NSSet *expected = [NSSet setWithArray:@[self.groupConversation]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list], expected);
}

- (void)testThatItsReturnsOneToOneConversations
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.oneToOneConversations;
    NSSet *expected = [NSSet setWithArray:@[self.oneToOneConversation, self.outgoingPendingConnectionConversation]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list], expected);
}

- (void)testThatAllListsAreIncluded
{
    ZMConversationListDirectory *directory = self.uiMOC.conversationListDirectory;
    // when & then
    XCTAssertTrue([directory.allConversationLists containsObject:directory.unarchivedConversations]);
    XCTAssertTrue([directory.allConversationLists containsObject:directory.conversationsIncludingArchived]);
    XCTAssertTrue([directory.allConversationLists containsObject:directory.archivedConversations]);
    XCTAssertTrue([directory.allConversationLists containsObject:directory.pendingConnectionConversations]);
    XCTAssertTrue([directory.allConversationLists containsObject:directory.clearedConversations]);
    XCTAssertTrue([directory.allConversationLists containsObject:directory.oneToOneConversations]);
    XCTAssertTrue([directory.allConversationLists containsObject:directory.groupConversations]);
}

@end
