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

@interface ZMConversationParticipantsTests : ZMConversationTestsBase
@end

@implementation ZMConversationParticipantsTests

- (void)testThatUpdatingUsersFromTransportDataPreservesUnsyncedInactiveAndActiveParticipants
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.conversationType = ZMConversationTypeGroup;
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        
        NSUUID *user1UUID = [NSUUID createUUID];
        NSUUID *user2UUID = [NSUUID createUUID];
        
        ZMUser *user4 = [self createUserOnMoc:self.syncMOC];
        ZMUser *user5 = [self createUserOnMoc:self.syncMOC];
        ZMUser *user6 = [self createUserOnMoc:self.syncMOC];
        
        [conversation addParticipant:user4];
        [conversation addParticipant:user5];
        [conversation addParticipant:user6];
        
        [conversation synchronizeAddedUser:user6];
        [conversation removeParticipant:user6];
        
        XCTAssertEqualObjects(conversation.unsyncedActiveParticipants, ([NSMutableOrderedSet orderedSetWithObjects:user4, user5, nil]));
        XCTAssertEqualObjects(conversation.unsyncedInactiveParticipants, ([NSMutableOrderedSet orderedSetWithObjects:user6, nil]));
        
        NSDictionary *payload = @{
                                  @"name" : [NSNull null],
                                  @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                                  @"members" : @{
                                          @"self" : @{
                                                  @"id" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9"
                                                  },
                                          @"others" : @[
                                                  @{
                                                      @"id": [user1UUID transportString]
                                                      },
                                                  @{
                                                      @"id": [user2UUID transportString]
                                                      }
                                                  ]
                                          },
                                  @"type" : @0,
                                  @"id" : [uuid transportString]
                                  };
        
        // when
        [conversation updateWithTransportData:payload serverTimeStamp:nil];
        
        // then
        XCTAssertEqualObjects(conversation.unsyncedActiveParticipants, ([NSMutableOrderedSet orderedSetWithObjects:user4, user5, nil]));
        XCTAssertEqualObjects(conversation.unsyncedInactiveParticipants, [NSMutableOrderedSet orderedSet]);
    }];
}

- (void)testThatItDoesNotAllowAddingParticipantsToAOneOnOneConversation;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    [self performIgnoringZMLogError:^{
        [conversation addParticipant:user];
    }];
    
    // then
    XCTAssertEqual(conversation.otherActiveParticipants.count, 0u);
}

- (void)testThatItDoesNotAllowRemovingPaticipantsFromAOneOnOneConversation;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    [conversation.mutableOtherActiveParticipants addObject:user];
    XCTAssertEqual(conversation.otherActiveParticipants.count, 1u);
    
    // when
    [self performIgnoringZMLogError:^{
        [conversation removeParticipant:user];
    }];
    
    // then
    XCTAssertEqual(conversation.otherActiveParticipants.count, 1u);
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


- (void)testThatWhenAParticipantHasBeenAddedOnTheClientAndTheServerWeDoNotSyncItAnymore
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    NSUUID *uuid = NSUUID.createUUID;
    conversation.remoteIdentifier = uuid;
    
    
    NSUUID *user1UUID = [NSUUID createUUID];
    NSUUID *user2UUID = [NSUUID createUUID];
    
    ZMUser *user4 = [self createUser];
    ZMUser *user5 = [self createUser]; // will also added by the server
    ZMUser *user6 = [self createUser];
    
    [conversation addParticipant:user4];
    [conversation addParticipant:user5];
    [conversation addParticipant:user6];
    
    [conversation synchronizeAddedUser:user6];
    [conversation removeParticipant:user6];
    
    XCTAssertEqualObjects(conversation.unsyncedActiveParticipants, ([NSMutableOrderedSet orderedSetWithObjects:user4, user5, nil]));
    XCTAssertEqualObjects(conversation.unsyncedInactiveParticipants, ([NSMutableOrderedSet orderedSetWithObjects:user6, nil]));
    
    NSDictionary *payload = @{
                              @"name" : [NSNull null],
                              @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                              @"members" : @{
                                      @"self" : @{
                                              @"id" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9"
                                              },
                                      @"others" : @[
                                              @{
                                                  @"id": [user1UUID transportString]
                                                  },
                                              @{
                                                  @"id": [user2UUID transportString]
                                                  },
                                              @{
                                                  @"id": [user5.remoteIdentifier transportString]
                                                  },
                                              
                                              ]
                                      },
                              @"type" : @0,
                              @"id" : [uuid transportString]
                              };
    
    // when
    XCTAssert([self.uiMOC saveOrRollback]);
    NSManagedObjectID *moid = conversation.objectID;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *syncConversation = (id) [self.syncMOC objectWithID:moid];
        [syncConversation updateWithTransportData:payload serverTimeStamp:nil];
        XCTAssert([self.syncMOC saveOrRollback]);
    }];
    [self.uiMOC refreshObject:conversation mergeChanges:NO];
    
    // then
    XCTAssertEqualObjects(conversation.unsyncedActiveParticipants, ([NSMutableOrderedSet orderedSetWithObjects:user4, nil]));
    XCTAssertEqualObjects(conversation.unsyncedInactiveParticipants, [NSMutableOrderedSet orderedSet]);
}


- (void)testThatWhenAParticipantHasBeenRemovedOnTheClientAndTheServerWeDoNotSyncItAnymore
{
    
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    NSUUID *uuid = NSUUID.createUUID;
    conversation.remoteIdentifier = uuid;
    
    
    NSUUID *user1UUID = [NSUUID createUUID];
    NSUUID *user2UUID = [NSUUID createUUID];
    
    
    ZMUser *user4 = [self createUser];
    ZMUser *user5 = [self createUser];
    ZMUser *user6 = [self createUser];
    
    [conversation addParticipant:user4];
    [conversation addParticipant:user5];
    [conversation addParticipant:user6];
    
    [conversation synchronizeAddedUser:user6];
    [conversation removeParticipant:user6]; // // will also removed by the server
    
    XCTAssertEqualObjects(conversation.unsyncedActiveParticipants, ([NSMutableOrderedSet orderedSetWithObjects:user4, user5, nil]));
    XCTAssertEqualObjects(conversation.unsyncedInactiveParticipants, ([NSMutableOrderedSet orderedSetWithObjects:user6, nil]));
    
    NSDictionary *payload = @{
                              @"name" : [NSNull null],
                              @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                              @"members" : @{
                                      @"self" : @{
                                              @"id" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9"
                                              },
                                      @"others" : @[
                                              @{
                                                  @"id": [user1UUID transportString]
                                                  },
                                              @{
                                                  @"id": [user2UUID transportString]
                                                  }
                                              ]
                                      },
                              @"type" : @0,
                              @"id" : [uuid transportString]
                              };
    
    // when
    XCTAssert([self.uiMOC saveOrRollback]);
    NSManagedObjectID *moid = conversation.objectID;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *syncConversation = (id) [self.syncMOC objectWithID:moid];
        [syncConversation updateWithTransportData:payload serverTimeStamp:nil];
        XCTAssert([self.syncMOC saveOrRollback]);
    }];
    [self.uiMOC refreshObject:conversation mergeChanges:NO];
    
    // then
    XCTAssertEqualObjects(conversation.unsyncedActiveParticipants, ([NSMutableOrderedSet orderedSetWithObjects:user4, user5, nil]));
    XCTAssertEqualObjects(conversation.unsyncedInactiveParticipants, [NSMutableOrderedSet orderedSet]);
}

- (void)testThatWhenMovingAParticipantFromInactiveToActiveWeDoNotRemoveItAgain
{
    
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    NSUUID *uuid = NSUUID.createUUID;
    conversation.remoteIdentifier = uuid;
    
    
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    
    [conversation addParticipant:user1]; [conversation synchronizeAddedUser:user1];
    [conversation addParticipant:user2]; [conversation synchronizeAddedUser:user2];
    [conversation addParticipant:user3]; [conversation synchronizeAddedUser:user3];
    [conversation removeParticipant:user3]; [conversation synchronizeRemovedUser:user3];
    
    [self.uiMOC saveOrRollback];
    
    XCTAssertEqualObjects(conversation.unsyncedActiveParticipants, ([NSMutableOrderedSet orderedSet]));
    XCTAssertEqualObjects(conversation.unsyncedInactiveParticipants, ([NSMutableOrderedSet orderedSet]));
    
    XCTAssertFalse([conversation.keysThatHaveLocalModifications containsObject:ZMConversationUnsyncedInactiveParticipantsKey]);
    XCTAssertFalse([conversation.keysThatHaveLocalModifications containsObject:ZMConversationUnsyncedActiveParticipantsKey]);
    
    
    NSDictionary *payload = @{
                              @"name" : [NSNull null],
                              @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                              @"members" : @{
                                      @"self" : @{
                                              @"id" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9"
                                              },
                                      @"others" : @[
                                              @{
                                                  @"id": [user1.remoteIdentifier transportString]
                                                  },
                                              @{
                                                  @"id": [user2.remoteIdentifier transportString]
                                                  },
                                              @{
                                                  @"id": [user3.remoteIdentifier transportString]
                                                  }
                                              
                                              ]
                                      },
                              @"type" : @0,
                              @"id" : [uuid transportString]
                              };
    
    // when
    XCTAssert([self.uiMOC saveOrRollback]);
    NSManagedObjectID *moid = conversation.objectID;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *syncConversation = (id) [self.syncMOC objectWithID:moid];
        [syncConversation updateWithTransportData:payload serverTimeStamp:nil];
        XCTAssert([self.syncMOC saveOrRollback]);
    }];
    [self.uiMOC refreshObject:conversation mergeChanges:NO];
    
    // then
    XCTAssertEqualObjects(conversation.unsyncedActiveParticipants, ([NSMutableOrderedSet orderedSet]));
    XCTAssertEqualObjects(conversation.unsyncedInactiveParticipants, ([NSMutableOrderedSet orderedSet]));
    
    XCTAssertEqualObjects(conversation.otherActiveParticipants, ([NSMutableOrderedSet orderedSetWithObjects:user1, user2, user3, nil]));
    
    
    XCTAssertFalse([conversation.keysThatHaveLocalModifications containsObject:ZMConversationUnsyncedActiveParticipantsKey]);
    XCTAssertFalse([conversation.keysThatHaveLocalModifications containsObject:ZMConversationUnsyncedInactiveParticipantsKey]);
}

- (void)testThatItAddsParticipants
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    
    // when
    [conversation addParticipant:user1];
    [conversation addParticipant:user2];
    
    // then
    NSOrderedSet *expectedActiveParticipants = [NSOrderedSet orderedSetWithObjects:user1, user2, nil];
    XCTAssertEqualObjects(expectedActiveParticipants, conversation.otherActiveParticipants);
}

- (void)testThatItCanRemoveTheSelfUser
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user1 = [self createUser];
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    selfUser.remoteIdentifier = [NSUUID createUUID];
    
    [conversation addParticipant:user1];
    [conversation internalAddParticipants:[NSSet setWithObject:selfUser] isAuthoritative:YES];
    
    XCTAssertTrue(conversation.isSelfAnActiveMember);
    
    // when
    [conversation removeParticipant:selfUser];
    WaitForAllGroupsToBeEmpty(0.5f);
    
    // then
    XCTAssertFalse(conversation.isSelfAnActiveMember);
}

- (void)testThatWhenAddingAParticipantItIsAddedToTheListOfUnsyncedActiveParticipants
{
    // given
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    ZMUser *user4 = [self createUser];
    
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:
                                    @[
                                      user1, user2, user3
                                      ]];
    
    [conversation synchronizeAddedUser:user1];
    [conversation synchronizeAddedUser:user2];
    [conversation synchronizeAddedUser:user3];
    
    XCTAssertEqualObjects(conversation.unsyncedActiveParticipants, [NSOrderedSet orderedSet]);
    
    // when
    [conversation addParticipant:user4];
    
    // then
    XCTAssertEqualObjects(conversation.unsyncedActiveParticipants, [NSOrderedSet orderedSetWithObject:user4]);
}


- (void)testThatWhenResettingAnUnsyncedAddedUserItIsNotUnsyncedAnymore
{
    // given
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    ZMUser *user4 = [self createUser];
    
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:
                                    @[
                                      user1, user2, user3
                                      ]];
    
    [conversation synchronizeAddedUser:user1];
    [conversation synchronizeAddedUser:user2];
    [conversation synchronizeAddedUser:user3];
    
    [conversation addParticipant:user4];
    
    XCTAssertEqualObjects(conversation.unsyncedActiveParticipants, [NSOrderedSet orderedSetWithObject:user4]);
    
    // when
    [conversation synchronizeAddedUser:user4];
    
    // then
    XCTAssertEqualObjects(conversation.unsyncedActiveParticipants, [NSOrderedSet orderedSet]);
}

- (void)testThatItPersistsUnsyncedActiveParticipants
{
    // given
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:
                                    @[
                                      user1, user2
                                      ]];
    [conversation synchronizeAddedUser:user1];
    [conversation synchronizeAddedUser:user2];
    
    [conversation addParticipant:user3];
    NSManagedObjectID *objectID = conversation.objectID;
    
    // when
    ZMConversation *conversation2 = (ZMConversation *) [self.uiMOC objectWithID:objectID];
    
    // then
    XCTAssertEqualObjects(conversation2.unsyncedActiveParticipants, [NSOrderedSet orderedSetWithObject:user3]);
}


- (void)testThatWhenAddingAParticipantThe_unsyncedActiveParticipants_propertyHasLocalModifications
{
    // given
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    ZMUser *user4 = [self createUser];
    
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:
                                    @[
                                      user1, user2, user3
                                      ]];
    [conversation synchronizeAddedUser:user1];
    [conversation synchronizeAddedUser:user2];
    [conversation synchronizeAddedUser:user3];
    
    [conversation addParticipant:user4];
    
    XCTAssertFalse([conversation.keysThatHaveLocalModifications containsObject:ZMConversationUnsyncedActiveParticipantsKey]);
    
    // when
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertTrue([conversation.keysThatHaveLocalModifications containsObject:ZMConversationUnsyncedActiveParticipantsKey]);
}



- (void)testThatRemovingAParticipantDoesNotSetThe_unsyncedActiveParticipants_flag
{
    // given
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    ZMUser *user4 = [self createUser];
    
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:
                                    @[
                                      user1, user2, user3, user4
                                      ]];
    [conversation synchronizeAddedUser:user1];
    [conversation synchronizeAddedUser:user2];
    [conversation synchronizeAddedUser:user3];
    [conversation synchronizeAddedUser:user4];
    
    [conversation removeParticipant:user4];
    
    // when
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    XCTAssertFalse([conversation.keysThatHaveLocalModifications containsObject:ZMConversationUnsyncedActiveParticipantsKey]);
}


- (void)testThatWhenSynchronizingAllAddedUsersThe_unsyncedActiveParticipants_changeFlagIsReset
{
    // given
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    ZMUser *user4 = [self createUser];
    
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:
                                    @[
                                      user1, user2, user3
                                      ]];
    [conversation synchronizeAddedUser:user1];
    [conversation synchronizeAddedUser:user2];
    [conversation synchronizeAddedUser:user3];
    
    [conversation addParticipant:user4];
    
    [self.uiMOC saveOrRollback];
    XCTAssertTrue([conversation.keysThatHaveLocalModifications containsObject:ZMConversationUnsyncedActiveParticipantsKey]);
    
    // when
    [conversation synchronizeAddedUser:user4];
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertFalse([conversation.keysThatHaveLocalModifications containsObject:ZMConversationUnsyncedActiveParticipantsKey]);
}



- (void)testThatItMovesAParticipantFromActiveToInactive
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    
    [conversation addParticipant:user1];
    [conversation addParticipant:user2];
    [conversation addParticipant:user3];
    
    // when
    [conversation removeParticipant:user2];
    
    // then
    NSOrderedSet *expectedActiveParticipants = [NSOrderedSet orderedSetWithObjects:user1, user3, nil];
    XCTAssertEqualObjects(expectedActiveParticipants, conversation.otherActiveParticipants);
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
    
    [conversation addParticipant:user1];
    [conversation addParticipant:user2];
    [conversation addParticipant:user3];
    
    // when
    [conversation removeParticipant:unknownUser];
    
    // then
    NSOrderedSet *expectedActiveParticipants = [NSOrderedSet orderedSetWithObjects:user1, user2, user3, nil];
    XCTAssertEqualObjects(expectedActiveParticipants, conversation.otherActiveParticipants);
}

- (void)testThatWhenRemovingAParticipantItIsAddedToTheListOfUnsyncedInactiveParticipants
{
    // given
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    ZMUser *user4 = [self createUser];
    
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:
                                    @[
                                      user1, user2, user3, user4
                                      ]];
    
    [conversation synchronizeAddedUser:user1];
    [conversation synchronizeAddedUser:user2];
    [conversation synchronizeAddedUser:user3];
    [conversation synchronizeAddedUser:user4];
    
    XCTAssertEqualObjects(conversation.unsyncedInactiveParticipants, [NSOrderedSet orderedSet]);
    
    // when
    [conversation removeParticipant:user4];
    
    // then
    XCTAssertEqualObjects(conversation.unsyncedInactiveParticipants, [NSOrderedSet orderedSetWithObject:user4]);
}


- (void)testThatWhenResettingAnUnsyncedUserItIsNotUnsyncedAnymore
{
    // given
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    ZMUser *user4 = [self createUser];
    
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:
                                    @[
                                      user1, user2, user3, user4
                                      ]];
    
    [conversation removeParticipant:user4];
    
    // when
    [conversation synchronizeRemovedUser:user4];
    
    // then
    XCTAssertEqualObjects(conversation.unsyncedInactiveParticipants, [NSOrderedSet orderedSet]);
}

- (void)testThatItPersistsUnsyncedInactiveParticipants
{
    // given
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:
                                    @[
                                      user1, user2, user3
                                      ]];
    [conversation synchronizeAddedUser:user1];
    [conversation synchronizeAddedUser:user2];
    [conversation synchronizeAddedUser:user3];
    
    [conversation removeParticipant:user3];
    NSManagedObjectID *objectID = conversation.objectID;
    
    // when
    ZMConversation *conversation2 = (ZMConversation *) [self.uiMOC objectWithID:objectID];
    
    // then
    XCTAssertEqualObjects(conversation2.unsyncedInactiveParticipants, [NSOrderedSet orderedSetWithObject:user3]);
}


- (void)testThatWhenRemovingAParticipantThe_unsyncedInactiveParticipants_propertyHasLocalModifications
{
    // given
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    ZMUser *user4 = [self createUser];
    
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:
                                    @[
                                      user1, user2, user3, user4
                                      ]];
    [conversation synchronizeAddedUser:user1];
    [conversation synchronizeAddedUser:user2];
    [conversation synchronizeAddedUser:user3];
    [conversation synchronizeAddedUser:user4];
    
    [conversation removeParticipant:user4];
    
    // when
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertTrue([conversation.keysThatHaveLocalModifications containsObject:ZMConversationUnsyncedInactiveParticipantsKey]);
}



- (void)testThatAddingAParticipantDoesNotSetThe_unsyncedInactiveParticipants_flag
{
    // given
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    ZMUser *user4 = [self createUser];
    
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:
                                    @[
                                      user1, user2, user3
                                      ]];
    [conversation addParticipant:user4];
    
    // when
    XCTAssertTrue([self.uiMOC saveOrRollback]);
    
    // then
    XCTAssertFalse([conversation.keysThatHaveLocalModifications containsObject:ZMConversationUnsyncedInactiveParticipantsKey]);
}


- (void)testThatWhenSynchronizingAllRemovedUsersThe_unsyncedInactiveParticipants_changeFlagIsReset
{
    // given
    ZMUser *user1 = [self createUser];
    ZMUser *user2 = [self createUser];
    ZMUser *user3 = [self createUser];
    ZMUser *user4 = [self createUser];
    
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:
                                    @[
                                      user1, user2, user3, user4
                                      ]];
    [conversation synchronizeAddedUser:user1];
    [conversation synchronizeAddedUser:user2];
    [conversation synchronizeAddedUser:user3];
    [conversation synchronizeAddedUser:user4];
    
    [conversation removeParticipant:user4];
    
    [self.uiMOC saveOrRollback];
    XCTAssertTrue([conversation.keysThatHaveLocalModifications containsObject:ZMConversationUnsyncedInactiveParticipantsKey]);
    
    // when
    [conversation synchronizeRemovedUser:user4];
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertFalse([conversation.keysThatHaveLocalModifications containsObject:ZMConversationUnsyncedInactiveParticipantsKey]);
}

- (void)testThatItCanSet_unsyncedInactiveParticipants_withoutThrowingAnException
{
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    XCTAssertNoThrow([conversation setLocallyModifiedKeys:[NSSet setWithObject:ZMConversationUnsyncedInactiveParticipantsKey]]);
    
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
    XCTAssertFalse([conversation.otherActiveParticipants containsObject:selfUser]);
}


@end



@implementation ZMConversationParticipantsTests (ConnectedUser)

- (void)testThatTheConnectedUserIsNilForGroupConversation
{
    // when
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    [conversation.mutableOtherActiveParticipants addObject:[ZMUser insertNewObjectInManagedObjectContext:self.uiMOC]];
    [conversation.mutableOtherActiveParticipants addObject:[ZMUser insertNewObjectInManagedObjectContext:self.uiMOC]];
    
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
    
    [conversation addParticipant:user1];
    [conversation addParticipant:user2];
    [conversation addParticipant:user3];
    [conversation addParticipant:user4];

    [self.uiMOC saveOrRollback];
    
    NSOrderedSet *expectedSet = [NSOrderedSet orderedSetWithArray:@[user2, user1, user4, selfUser, user3]];
    
    XCTAssertEqualObjects(conversation.activeParticipants, expectedSet);
}

@end
