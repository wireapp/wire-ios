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


@import ZMCDataModel;
#import "ZMBaseManagedObjectTest.h"
#import "ZMConversationListDirectory.h"
#import "ZMConversation+Internal.h"
#import "ZMConnection+Internal.h"
#import "ZMVoiceChannel+Internal.h"
#import "ZMVoiceChannel+Testing.h"
#import "ZMUser+Internal.h"
#import <ZMCDataModel/ZMCDataModel-Swift.h>

@interface ZMConversationListDirectoryTests : ZMBaseManagedObjectTest

@property (nonatomic) NSMutableArray *conversations;

@property (nonatomic) ZMConversation *archivedGroupConversation;
@property (nonatomic) ZMConversation *archivedOneToOneConversation;
@property (nonatomic) ZMConversation *pendingConnectionConversation;
@property (nonatomic) ZMConversation *invalidConversation;
@property (nonatomic) ZMConversation *groupConversation;
@property (nonatomic) ZMConversation *oneToOneConversation;
@property (nonatomic) ZMConversation *oneToOneConversationWithActiveCall;
@property (nonatomic) ZMConversation *groupConversationWithIncomingCall;
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
    
    self.pendingConnectionConversation = [self createConversation];
    self.pendingConnectionConversation.conversationType = ZMConversationTypeConnection;
    self.pendingConnectionConversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    self.pendingConnectionConversation.connection.status = ZMConnectionStatusPending;
    self.pendingConnectionConversation.userDefinedName = @"pendingConnectionConversation";
    
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
    
    self.oneToOneConversationWithActiveCall = [self createConversation];
    self.oneToOneConversationWithActiveCall.conversationType = ZMConversationTypeOneOnOne;
    self.oneToOneConversationWithActiveCall.userDefinedName = @"oneToOneConversationWithActiveCall";
    self.oneToOneConversationWithActiveCall.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    self.oneToOneConversationWithActiveCall.connection.status = ZMConnectionStatusAccepted;
    self.oneToOneConversationWithActiveCall.callDeviceIsActive = YES;
    
    self.groupConversationWithIncomingCall = [self createConversation];
    self.groupConversationWithIncomingCall.conversationType = ZMConversationTypeOneOnOne;
    self.groupConversationWithIncomingCall.userDefinedName = @"groupConversationWithIncomingCall";
    self.groupConversationWithIncomingCall.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    self.groupConversationWithIncomingCall.connection.status = ZMConnectionStatusAccepted;
    [self.groupConversationWithIncomingCall.mutableOtherActiveParticipants addObject:otherUser];
    
    self.clearedConversation = [self createConversation];
    self.clearedConversation.conversationType = ZMConversationTypeOneOnOne;
    self.clearedConversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    self.clearedConversation.connection.status = ZMConnectionStatusAccepted;
    self.clearedConversation.userDefinedName = @"clearedConversation";
    self.clearedConversation.clearedTimeStamp = self.clearedConversation.lastServerTimeStamp;
    self.clearedConversation.isArchived = YES;

    [self.uiMOC saveOrRollback];
    ZMCallState *callStateFromUIMOC = [self.uiMOC.zm_callState createCopyAndResetHasChanges];
    [self.syncMOC performGroupedBlockAndWait:^{
        [self.syncMOC mergeCallStateChanges:callStateFromUIMOC];

        ZMConversation *oneToOneConv = (id)[self.syncMOC objectWithID:self.oneToOneConversationWithActiveCall.objectID];
        
        oneToOneConv.activeFlowParticipants = [NSOrderedSet orderedSetWithObject:otherUser];
        [oneToOneConv.mutableOtherActiveParticipants addObject:otherUser];
        [[oneToOneConv mutableOrderedSetValueForKey:ZMConversationCallParticipantsKey] addObject:otherUser];
        oneToOneConv.isFlowActive = YES;
        
        ZMConversation *groupConv = (id)[self.syncMOC objectWithID:self.groupConversationWithIncomingCall.objectID];
        [[groupConv mutableOrderedSetValueForKey:ZMConversationCallParticipantsKey] addObject:otherUser];

        [self.syncMOC saveOrRollback];
        [self.uiMOC mergeCallStateChanges:[self.syncMOC.zm_callState createCopyAndResetHasChanges]];
    }];
    
    [self.uiMOC refreshObject:self.oneToOneConversationWithActiveCall mergeChanges:NO];
    [self.uiMOC refreshObject:self.groupConversationWithIncomingCall mergeChanges:NO];

    XCTAssertEqual(self.oneToOneConversationWithActiveCall.voiceChannelState, ZMVoiceChannelStateSelfConnectedToActiveChannel);
    XCTAssertEqual(self.groupConversationWithIncomingCall.voiceChannelState, ZMVoiceChannelStateIncomingCall);
    
}

- (void)tearDown
{
    WaitForAllGroupsToBeEmpty(0.5);
    
    self.invalidConversation = nil;
    self.groupConversation = nil;
    self.pendingConnectionConversation = nil;
    self.archivedOneToOneConversation = nil;
    self.archivedGroupConversation = nil;
    self.oneToOneConversation = nil;
    self.groupConversationWithIncomingCall = nil;
    self.oneToOneConversationWithActiveCall = nil;
    [super tearDown];
}

- (void)testThatItReturnsAllConversations;
{
    // when
    ZMConversationList *list = [self.uiMOC.conversationListDirectory conversationsIncludingArchived];
    NSSet *exepected = [NSSet setWithArray:@[self.archivedGroupConversation, self.archivedOneToOneConversation, self.groupConversation, self.oneToOneConversation, self.oneToOneConversationWithActiveCall, self.groupConversationWithIncomingCall]];
    // then
    
    XCTAssertEqualObjects([NSSet setWithArray:list], exepected);
}

- (void)testThatItReturnsUnarchivedConversations;
{
    // when
    ZMConversationList *list = [self.uiMOC.conversationListDirectory unarchivedAndNotCallingConversations];
    NSSet *exepected = [NSSet setWithArray:@[self.groupConversation, self.oneToOneConversation, self.groupConversationWithIncomingCall]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list], exepected);
}

- (void)testThatItReturnsArchivedConversations;
{
    // when
    ZMConversationList *list = [self.uiMOC.conversationListDirectory archivedConversations];
    NSSet *exepected = [NSSet setWithArray:@[self.archivedGroupConversation, self.archivedOneToOneConversation]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list], exepected);
}

- (void)testThatItReturnsPendingConversations;
{
    // when
    ZMConversationList *list = [self.uiMOC.conversationListDirectory pendingConnectionConversations];
    NSSet *exepected = [NSSet setWithArray:@[self.pendingConnectionConversation]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list], exepected);
}

- (void)testThatItKeepsReturningTheSameObject
{
    // when
    ZMConversationList * list1 = [self.uiMOC.conversationListDirectory conversationsIncludingArchived];
    ZMConversationList * list2 = [self.uiMOC.conversationListDirectory conversationsIncludingArchived];
    
    //then
    XCTAssertEqual(list1, list2);
}

- (void)testThatItReturnsNonIdleVoiceChannelConversations
{
    // when
    ZMConversationList *list = [self.uiMOC.conversationListDirectory nonIdleVoiceChannelConversations];
    NSSet *exepected = [NSSet setWithArray:@[self.groupConversationWithIncomingCall, self.oneToOneConversationWithActiveCall]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list], exepected);
}

- (void)testThatItReturnsActiveCallConversations
{
    // when
    ZMConversationList *list = [self.uiMOC.conversationListDirectory activeCallConversations];
    NSSet *exepected = [NSSet setWithArray:@[self.oneToOneConversationWithActiveCall]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list], exepected);
}

- (void)testThatItReturnsClearedConversations
{
    // when
    ZMConversationList *list = [self.uiMOC.conversationListDirectory clearedConversations];
    NSSet *exepected = [NSSet setWithArray:@[self.clearedConversation]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list], exepected);
}

- (void)testThatItNotReturnsClearedConversationsIn_ConversationsIncludingArchived
{
    // when
    ZMConversationList *list = [self.uiMOC.conversationListDirectory conversationsIncludingArchived];
    NSSet *exepected = [NSSet setWithArray:@[self.clearedConversation]];
    
    // then
    // cleared conversations should not be included in conversationsIncludingArchived
    XCTAssertFalse([[NSSet setWithArray:list] intersectsSet:exepected]);
}

@end
