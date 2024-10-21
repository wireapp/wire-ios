//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
@property (nonatomic) ZMConversation *groupConversationInFolder;
@property (nonatomic) ZMConversation *oneToOneConversation;
@property (nonatomic) ZMConversation *oneToOneConversationInFolder;
@property (nonatomic) ZMConversation *oneToOneConversationInTeam;
@property (nonatomic) ZMConversation *clearedConversation;
@property (nonatomic) ZMConversation *favoritedConversation;
@property (nonatomic) ZMConversation *serviceConversation;

@end



@implementation ZMConversationListDirectoryTests

- (ZMConversation *)createConversation
{
    ZMConversation *conv = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conv.lastServerTimeStamp = [NSDate date];
    conv.lastReadServerTimeStamp = conv.lastServerTimeStamp;
    conv.remoteIdentifier = [NSUUID new];
    return conv;
}

- (void)setUp
{
    [super setUp];

    Team *team = [Team insertNewObjectInManagedObjectContext:self.uiMOC];
    team.remoteIdentifier = [NSUUID new];

    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    selfUser.remoteIdentifier = [NSUUID new];

    Member *selfUserMembership = [Member insertNewObjectInManagedObjectContext:self.uiMOC];
    selfUserMembership.user = selfUser;
    selfUserMembership.team = team;

    ZMUser *teamUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    teamUser.remoteIdentifier = [NSUUID new];

    Member *teamUserMembership = [Member insertNewObjectInManagedObjectContext:self.uiMOC];
    teamUserMembership.user = teamUser;
    teamUserMembership.team = team;

    ZMUser *otherUser1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    otherUser1.remoteIdentifier = [NSUUID new];
    otherUser1.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    otherUser1.connection.status = ZMConnectionStatusAccepted;

    ZMUser *otherUser2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    otherUser2.remoteIdentifier = [NSUUID new];
    otherUser2.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    otherUser2.connection.status = ZMConnectionStatusAccepted;

    ZMUser *otherUser3 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    otherUser3.remoteIdentifier = [NSUUID new];
    otherUser3.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    otherUser3.connection.status = ZMConnectionStatusAccepted;

    ZMUser *otherUser4 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    otherUser4.remoteIdentifier = [NSUUID new];
    otherUser4.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    otherUser4.connection.status = ZMConnectionStatusAccepted;

    ZMUser *incomingPendingUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    incomingPendingUser.remoteIdentifier = [NSUUID new];
    incomingPendingUser.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    incomingPendingUser.connection.status = ZMConnectionStatusPending;

    ZMUser *outgoingPendingUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    outgoingPendingUser.remoteIdentifier = [NSUUID new];
    outgoingPendingUser.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    outgoingPendingUser.connection.status = ZMConnectionStatusSent;

    ZMUser *serviceUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    serviceUser.serviceIdentifier = @"serviceA";
    serviceUser.providerIdentifier = @"providerA";
    serviceUser.remoteIdentifier = [NSUUID new];

    Label *folder = [Label insertNewObjectInManagedObjectContext:self.uiMOC];
    folder.name = @"folder A";
    
    self.archivedGroupConversation = [self createConversation];
    self.archivedGroupConversation.conversationType = ZMConversationTypeGroup;
    self.archivedGroupConversation.isArchived = YES;
    self.archivedGroupConversation.userDefinedName = @"archivedGroupConversation";

    self.archivedOneToOneConversation = [self createConversation];
    self.archivedOneToOneConversation.conversationType = ZMConversationTypeOneOnOne;
    self.archivedOneToOneConversation.oneOnOneUser = otherUser1;
    self.archivedOneToOneConversation.isArchived = YES;
    self.archivedOneToOneConversation.userDefinedName = @"archivedOneToOneConversation";

    self.incomingPendingConnectionConversation = [self createConversation];
    self.incomingPendingConnectionConversation.conversationType = ZMConversationTypeConnection;
    self.incomingPendingConnectionConversation.oneOnOneUser = incomingPendingUser;
    self.incomingPendingConnectionConversation.userDefinedName = @"incomingPendingConnectionConversation";

    self.outgoingPendingConnectionConversation = [self createConversation];
    self.outgoingPendingConnectionConversation.conversationType = ZMConversationTypeConnection;
    self.outgoingPendingConnectionConversation.oneOnOneUser = outgoingPendingUser;
    self.outgoingPendingConnectionConversation.userDefinedName = @"outgoingConnectionConversation";

    self.groupConversation = [self createConversation];
    self.groupConversation.conversationType = ZMConversationTypeGroup;
    self.groupConversation.userDefinedName = @"groupConversation";

    self.groupConversationInFolder = [self createConversation];
    self.groupConversationInFolder.conversationType = ZMConversationTypeGroup;
    self.groupConversationInFolder.userDefinedName = @"groupConversationInFolder";
    self.groupConversationInFolder.labels = [NSSet setWithObject:folder];

    self.oneToOneConversation = [self createConversation];
    self.oneToOneConversation.conversationType = ZMConversationTypeOneOnOne;
    self.oneToOneConversation.oneOnOneUser = otherUser2;
    self.oneToOneConversation.userDefinedName = @"oneToOneConversation";

    self.oneToOneConversationInFolder = [self createConversation];
    self.oneToOneConversationInFolder.conversationType = ZMConversationTypeOneOnOne;
    self.oneToOneConversationInFolder.oneOnOneUser = otherUser3;
    self.oneToOneConversationInFolder.userDefinedName = @"oneToOneConversationInFolder";
    self.oneToOneConversationInFolder.labels = [NSSet setWithObject:folder];

    self.oneToOneConversationInTeam = [self createConversation];
    self.oneToOneConversationInTeam.conversationType = ZMConversationTypeGroup;
    self.oneToOneConversationInTeam.userDefinedName = nil;
    self.oneToOneConversationInTeam.team = team;
    self.oneToOneConversationInTeam.oneOnOneUser = teamUser;
    [self.oneToOneConversationInTeam addParticipantAndUpdateConversationStateWithUser:teamUser role:nil];
    [self.oneToOneConversationInTeam addParticipantAndUpdateConversationStateWithUser:selfUser role:nil];

    self.invalidConversation = [self createConversation];
    self.invalidConversation.conversationType = ZMConversationTypeInvalid;
    self.invalidConversation.userDefinedName = @"invalidConversation";

    self.clearedConversation = [self createConversation];
    self.clearedConversation.conversationType = ZMConversationTypeOneOnOne;
    self.clearedConversation.oneOnOneUser = otherUser4;
    self.clearedConversation.userDefinedName = @"clearedConversation";
    self.clearedConversation.clearedTimeStamp = self.clearedConversation.lastServerTimeStamp;
    self.clearedConversation.isArchived = YES;

    self.favoritedConversation = [self createConversation];
    self.favoritedConversation.conversationType = ZMConversationTypeGroup;
    self.favoritedConversation.userDefinedName = @"favoritedConversation";
    self.favoritedConversation.isFavorite = YES;

    self.serviceConversation = [self createConversation];
    self.serviceConversation.conversationType = ZMConversationTypeGroup;
    self.serviceConversation.userDefinedName = nil;
    self.serviceConversation.team = team;
    self.serviceConversation.oneOnOneUser = serviceUser;
    [self.serviceConversation addParticipantAndUpdateConversationStateWithUser:serviceUser role:nil];
    [self.serviceConversation addParticipantAndUpdateConversationStateWithUser:selfUser role:nil];

    [self.uiMOC saveOrRollback];
}

- (void)tearDown
{
    WaitForAllGroupsToBeEmpty(0.5);
    
    self.invalidConversation = nil;
    self.groupConversation = nil;
    self.groupConversationInFolder = nil;
    self.groupConversationInFolder.labels = [NSSet set];
    self.incomingPendingConnectionConversation = nil;
    self.outgoingPendingConnectionConversation = nil;
    self.archivedOneToOneConversation = nil;
    self.archivedGroupConversation = nil;
    self.oneToOneConversation = nil;
    self.oneToOneConversationInTeam = nil;
    self.oneToOneConversationInFolder = nil;
    self.clearedConversation = nil;
    self.favoritedConversation = nil;
    self.serviceConversation = nil;
    self.conversations = nil;

    [super tearDown];


}

- (void)testThatItReturnsAllConversations;
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.conversationsIncludingArchived;
    NSSet *expected = [NSSet setWithArray:@[self.archivedGroupConversation,
                                            self.archivedOneToOneConversation,
                                            self.groupConversation,
                                            self.groupConversationInFolder,
                                            self.oneToOneConversation,
                                            self.oneToOneConversationInFolder,
                                            self.oneToOneConversationInTeam,
                                            self.outgoingPendingConnectionConversation,
                                            self.favoritedConversation,
                                            self.serviceConversation]];
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list.items], expected);
}

- (void)testThatItReturnsUnarchivedConversations;
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.unarchivedConversations;
    NSSet *expected = [NSSet setWithArray:@[self.groupConversation,
                                            self.oneToOneConversation,
                                            self.outgoingPendingConnectionConversation,
                                            self.favoritedConversation,
                                            self.groupConversationInFolder,
                                            self.oneToOneConversationInFolder,
                                            self.oneToOneConversationInTeam,
                                            self.serviceConversation]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list.items], expected);
}

- (void)testThatItReturnsArchivedConversations;
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.archivedConversations;
    NSSet *expected = [NSSet setWithArray:@[self.archivedGroupConversation, self.archivedOneToOneConversation]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list.items], expected);
}

- (void)testThatItReturnsPendingConversations;
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.pendingConnectionConversations;
    NSSet *expected = [NSSet setWithArray:@[self.incomingPendingConnectionConversation]];
    
    // then
    XCTAssertEqualObjects([NSSet setWithArray:list.items], expected);
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
    XCTAssertEqualObjects([NSSet setWithArray:list.items], expected);
}

- (void)testThatItNotReturnsClearedConversationsIn_ConversationsIncludingArchived
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.conversationsIncludingArchived;
    NSSet *expected = [NSSet setWithArray:@[self.clearedConversation]];
    
    // then
    // cleared conversations should not be included in conversationsIncludingArchived
    XCTAssertFalse([[NSSet setWithArray:list.items] intersectsSet:expected]);
}

- (void)testThatItsReturnsGroupConversations
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.groupConversations;
    NSSet *expected = [NSSet setWithArray:@[self.groupConversation,
                                            self.favoritedConversation,
                                            self.groupConversationInFolder]];

    // then
    XCTAssertEqualObjects([NSSet setWithArray:list.items], expected);
}

- (void)testThatItsReturnsOneToOneConversations
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.oneToOneConversations;
    NSSet *expected = [NSSet setWithArray:@[self.oneToOneConversation,
                                            self.oneToOneConversationInTeam,
                                            self.outgoingPendingConnectionConversation,
                                            self.serviceConversation,
                                            self.oneToOneConversationInFolder]];

    // then
    XCTAssertEqualObjects([NSSet setWithArray:list.items], expected);
}

- (void)testThatItReturnsFavoritedConveration
{
    // when
    ZMConversationList *list = self.uiMOC.conversationListDirectory.favoriteConversations;
    NSSet *expected = [NSSet setWithArray:@[self.favoritedConversation]];

    // then
    XCTAssertEqualObjects([NSSet setWithArray:list.items], expected);
}

@end
