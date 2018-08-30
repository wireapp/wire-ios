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
#import "ZMConversation+Transport.h"
#import "WireDataModelTests-Swift.h"
#import <WireDataModel/WireDataModel-Swift.h>

@interface ZMConversationParticipantsTests : ZMConversationTestsBase
@end

@implementation ZMConversationParticipantsTests

- (void)testThatItAddsMissingParticipantInGroup
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    
    // when
    [conversation addParticipantIfMissing:user date:[NSDate date]];
    
    // then
    [conversation.activeParticipants containsObject:user];
    ZMSystemMessage *systemMessage =  conversation.messages.lastObject;
    XCTAssertEqual(systemMessage.systemMessageType, ZMSystemMessageTypeParticipantsAdded);
}

- (void)testThatItDoesntAddParticipantsAddedSystemMessageIfUserIsNotMissing
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    [conversation internalAddParticipants:[NSSet setWithObject:user]];
    
    // when
    [conversation addParticipantIfMissing:user date:[NSDate date]];
    
    // then
    [conversation.activeParticipants containsObject:user];
    XCTAssertEqual(conversation.messages.count, 0lu);
}

- (void)testThatItAddsMissingParticipantInOneToOne
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    
    // when
    [conversation addParticipantIfMissing:user date:[NSDate date]];
    
    // then
    [conversation.activeParticipants containsObject:user];
}

- (void)testThatItReturnsAllParticipantsAsActiveParticipantsInOneOnOneConversations
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.status = ZMConnectionStatusAccepted;
    connection.to = user;
    connection.conversation = conversation;
    
    [self.uiMOC saveOrRollback];

    // then
    XCTAssertEqual(conversation.activeParticipants.count, 2u);
}


- (void)testThatItReturnsAllParticipantsAsActiveParticipantsInConnectionConversations
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.status = ZMConnectionStatusPending;
    connection.to = user;
    connection.conversation = conversation;
    
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertEqual(conversation.activeParticipants.count, 2u);
}

- (void)testThatItReturnsSelfUserAsActiveParticipantsInSelfConversations
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeSelf;
    
    // then
    XCTAssertEqual(conversation.activeParticipants.count, 1u);
}

- (void)testThatItAddsParticipants
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    
    // when
    [conversation internalAddParticipants:[NSSet setWithObject:user1]];
    [conversation internalAddParticipants:[NSSet setWithObject:user2]];
    
    // then
    NSOrderedSet *expectedActiveParticipants = [NSOrderedSet orderedSetWithObjects:user1, user2, nil];
    XCTAssertEqualObjects(expectedActiveParticipants, conversation.lastServerSyncedActiveParticipants);
}

- (void)testThatItCanRemoveTheSelfUser
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user1 = [self createUser];
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    selfUser.remoteIdentifier = [NSUUID createUUID];
    
//    [conversation addParticipant:user1];
    [conversation internalAddParticipants:[NSSet setWithObjects:selfUser, user1, nil]];
    
    XCTAssertTrue(conversation.isSelfAnActiveMember);
    
    // when
    [conversation internalRemoveParticipants:[NSSet setWithObject:selfUser] sender:user1];
    WaitForAllGroupsToBeEmpty(0.5f);
    
    // then
    XCTAssertFalse(conversation.isSelfAnActiveMember);
}

- (void)testThatItDoesNothingForUnknownParticipants
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    ZMUser *unknownUser = [self createUser];
    
    [conversation internalAddParticipants:[NSSet setWithObjects:user1, user2, user3, nil]];
    
    // when
    [conversation internalRemoveParticipants:[NSSet setWithObject:unknownUser] sender:user1];
    
    // then
    NSSet *expectedActiveParticipants = [NSSet setWithObjects:user1, user2, user3, nil];
    XCTAssertEqualObjects(expectedActiveParticipants, conversation.lastServerSyncedActiveParticipants.set);
}

- (void)testThatActiveParticipantsContainsSelf
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    
    // when
    conversation.isSelfAnActiveMember = YES;
    
    // then
    XCTAssertTrue([conversation.activeParticipants containsObject:selfUser]);
    
    // when
    conversation.isSelfAnActiveMember = NO;
    
    // then
    XCTAssertFalse([conversation.activeParticipants containsObject:selfUser]);
}

- (void)testThatOtherActiveParticipantsDoesNotContainSelf
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    
    // when
    conversation.isSelfAnActiveMember = YES;
    
    // then
    XCTAssertFalse([conversation.lastServerSyncedActiveParticipants containsObject:selfUser]);
}

@end



@implementation ZMConversationParticipantsTests (ConnectedUser)

- (void)testThatTheConnectedUserIsNilForGroupConversation
{
    // when
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    [conversation.mutableLastServerSyncedActiveParticipants addObject:[ZMUser insertNewObjectInManagedObjectContext:self.uiMOC]];
    [conversation.mutableLastServerSyncedActiveParticipants addObject:[ZMUser insertNewObjectInManagedObjectContext:self.uiMOC]];
    
    // then
    XCTAssertNil(conversation.connectedUser);
}

- (void)testThatTheConnectedUserIsNilForSelfconversation
{
    // when
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeSelf;
    
    // then
    XCTAssertNil(conversation.connectedUser);
}

- (void)testThatWeHaveAConnectedUserForOneOnOneConversation
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    ZMUser* user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.to = user;
    
    // when
    connection.conversation = conversation;
    
    // then
    XCTAssertEqual(conversation.connectedUser, user);
}

- (void)testThatWeHaveAConnectedUserForConnectionConversation
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    ZMUser* user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.to = user;
    
    // when
    connection.conversation = conversation;
    
    // then
    XCTAssertEqual(conversation.connectedUser, user);
}

@end


@implementation ZMConversationParticipantsTests (Sorting)

- (void)testThatItSortsParticipantsByFullName
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    NSUUID *uuid = NSUUID.createUUID;
    conversation.remoteIdentifier = uuid;
    
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    ZMUser *user4 = [self createUser];

    selfUser.name = @"Super User";
    user1.name = @"Hans im Glueck";
    user2.name = @"Anna Blume";
    user3.name = @"Susi Super";
    user4.name = @"Super Susann";
    
    [conversation internalAddParticipants:[NSSet setWithObjects:user1, user2, user3, user4, nil]];
    [self.uiMOC saveOrRollback];
    
    NSOrderedSet *expectedSet = [NSOrderedSet orderedSetWithArray:@[user2, user1, user4, selfUser, user3]];
    
    XCTAssertEqualObjects(conversation.activeParticipants, expectedSet);
}

@end
