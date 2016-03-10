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


@import ZMTransport;

#import "ZMConversationTests.h"
#import "ZMUser.h"
#import "ZMConversation+Internal.h"
#import "ZMUserSession+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMConversationList+Internal.h"
#import "ZMVoiceChannel+Internal.h"
#import "ZMVoiceChannel+Testing.h"
#import "ZMConversationMessageWindow.h"
#import "ZMConnection+Internal.h"
#import "ZMConversation+Internal.h"
#import "ZMConversationList+Internal.h"
#import "ZMClientMessage.h"
#import "ZMConversation+UnreadCount.h"


@interface ZMConversationTests ()

@property (nonatomic) NSMutableArray *receivedNotifications;

- (ZMConversation *)insertConversationWithParticipants:(NSArray *)participants
                                      callParticipants:(NSArray *)callParticipants
                  callStateNeedsToBeUpdatedFromBackend:(BOOL)callStateNeedsToBeUpdatedFromBackend;
- (NSDate *)timeStampForSortAppendMessageToConversation:(ZMConversation *)conversation;

- (ZMMessage *)insertDownloadedMessageAfterMessage:(ZMMessage *)previous intoConversation:(ZMConversation *)conversation;
- (ZMMessage *)insertDownloadedMessageForEventID:(ZMEventID *)eventID intoConversation:(ZMConversation *)conversation;

@end


@implementation ZMConversationTests

- (void)setUp;
{
    [super setUp];
    [self setupSelfConversation]; // when updating lastRead we are posting to the selfConversation
}

- (void)setupSelfConversation
{
    NSUUID *selfUserID =  [NSUUID UUID];
    [ZMUser selfUserInContext:self.uiMOC].remoteIdentifier = selfUserID;
    ZMConversation *selfConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    selfConversation.remoteIdentifier = selfUserID;
    selfConversation.conversationType = ZMConversationTypeSelf;
    [self.uiMOC saveOrRollback];
    
    [self.syncMOC performGroupedBlockAndWait:^{
        [self.syncMOC refreshObject:[ZMUser selfUserInContext:self.syncMOC] mergeChanges:NO];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)didReceiveWindowNotification:(NSNotification *)notification
{
    self.lastReceivedNotification = notification;
}

- (ZMUserSession *)mockUserSessionWithUIMOC;
{
    id userSession = [OCMockObject mockForClass:ZMUserSession.class];
    [[[userSession stub] andReturn:self.uiMOC] managedObjectContext];
    return userSession;
}

- (ZMUser *)createUser
{
    return [self createUserOnMoc:self.uiMOC];
}

- (ZMUser *)createUserOnMoc:(NSManagedObjectContext *)moc
{
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:moc];
    user.remoteIdentifier = [NSUUID createUUID];
    return user;
}

- (ZMConversation *)insertConversationWithParticipants:(NSArray *)participants
                                      callParticipants:(NSArray *)callParticipants
                  callStateNeedsToBeUpdatedFromBackend:(BOOL)callStateNeedsToBeUpdatedFromBackend
{
    __block NSManagedObjectID *objectID;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:participants];
        conversation.conversationType = ZMConversationTypeGroup;
        conversation.remoteIdentifier = NSUUID.createUUID;
        for (ZMUser *user in callParticipants) {
            ZMUser *syncUser = (id)[self.syncMOC objectWithID:user.objectID];
            [conversation.voiceChannel addCallParticipant:syncUser];
        }
        conversation.callStateNeedsToBeUpdatedFromBackend = callStateNeedsToBeUpdatedFromBackend;
        [self.syncMOC saveOrRollback];
        objectID = conversation.objectID;
        [conversation.voiceChannel tearDown];
    }];
    
    return (ZMConversation *)[self.uiMOC objectWithID:objectID];
}

- (NSDate *)timeStampForSortAppendMessageToConversation:(ZMConversation *)conversation
{
    if (conversation.lastServerTimeStamp == nil) {
        conversation.lastServerTimeStamp = [NSDate date];
    }
    ZMMessage *message = [ZMMessage insertNewObjectInManagedObjectContext:conversation.managedObjectContext];
    message.serverTimestamp = [conversation.lastServerTimeStamp dateByAddingTimeInterval:5];
    [conversation resortMessagesWithUpdatedMessage:message];
    conversation.lastServerTimeStamp = message.serverTimestamp;
    return message.serverTimestamp;
}


- (ZMMessage *)insertDownloadedMessageForEventID:(ZMEventID *)eventID intoConversation:(ZMConversation *)conversation
{
    NSDate *newTime = conversation.lastServerTimeStamp ? [conversation.lastServerTimeStamp dateByAddingTimeInterval:5] : [NSDate date];
    
    ZMTextMessage *message = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    message.eventID = eventID;
    message.serverTimestamp = newTime;
    conversation.lastServerTimeStamp = message.serverTimestamp;
    conversation.lastEventID = message.eventID;
    [conversation addEventToDownloadedEvents:message.eventID timeStamp:message.serverTimestamp];
    [conversation.mutableMessages addObject:message];
    return message;
}

- (ZMMessage *)insertDownloadedMessageAfterMessage:(ZMMessage *)previous intoConversation:(ZMConversation *)conversation
{
    NSDate *newTime = conversation.lastServerTimeStamp ? [conversation.lastServerTimeStamp dateByAddingTimeInterval:5] : [NSDate date];
    
    ZMEventID *eventID = [ZMEventID eventIDWithMajor:previous.eventID.major + 1 minor:previous.eventID.minor];
    ZMTextMessage *message = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    message.eventID = eventID;
    message.serverTimestamp = newTime;
    conversation.lastServerTimeStamp = message.serverTimestamp;
    conversation.lastEventID = message.eventID;
    [conversation addEventToDownloadedEvents:message.eventID timeStamp:message.serverTimestamp];
    [conversation.mutableMessages addObject:message];
    return message;
}


@end


@implementation ZMConversationTests (General)


- (void)testThatItHasLocallyModifiedDataFields
{
    XCTAssertTrue([ZMConversation hasLocallyModifiedDataFields]);
    NSEntityDescription *entity = self.uiMOC.persistentStoreCoordinator.managedObjectModel.entitiesByName[ZMConversation.entityName];
    XCTAssertNotNil(entity.attributesByName[@"modifiedDataFields"]);
}

- (void)testThatWeCanSetAttributesOnConversation
{
    [self checkConversationAttributeForKey:@"draftMessageText" value:@"It’s cold outside."];
    [self checkConversationAttributeForKey:ZMConversationUserDefinedNameKey value:@"Foo"];
    [self checkConversationAttributeForKey:@"normalizedUserDefinedName" value:@"Foo"];
    [self checkConversationAttributeForKey:@"conversationType" value:@(1)];
    [self checkConversationAttributeForKey:@"lastModifiedDate" value:[NSDate dateWithTimeIntervalSince1970:123456]];
    [self checkConversationAttributeForKey:@"lastEventID" value:[self createEventID]];
    [self checkConversationAttributeForKey:@"lastReadEventID" value:[self createEventID] ];
    [self checkConversationAttributeForKey:@"remoteIdentifier" value:[NSUUID createUUID]];
    [self checkConversationAttributeForKey:ZMConversationIsSilencedKey value:@YES];
    [self checkConversationAttributeForKey:ZMConversationIsSilencedKey value:@NO];
    [self checkConversationAttributeForKey:ZMConversationIsArchivedKey value:@YES];
    [self checkConversationAttributeForKey:ZMConversationIsArchivedKey value:@NO];
    [self checkConversationAttributeForKey:ZMConversationIsSelfAnActiveMemberKey value:@YES];
    [self checkConversationAttributeForKey:ZMConversationIsSelfAnActiveMemberKey value:@NO];
    [self checkConversationAttributeForKey:@"needsToBeUpdatedFromBackend" value:@YES];
    [self checkConversationAttributeForKey:@"needsToBeUpdatedFromBackend" value:@NO];
    [self checkConversationAttributeForKey:ZMConversationArchivedEventIDKey value:[self createEventID]];
    [self checkConversationAttributeForKey:ZMConversationLastReadServerTimeStampKey value:[NSDate date]];
    [self checkConversationAttributeForKey:ZMConversationLastServerTimeStampKey value:[NSDate date]];

}

- (void)checkConversationAttributeForKey:(NSString *)key value:(id)value;
{
    [self checkAttributeForClass:[ZMConversation class] key:key value:value];
}

- (void)testThatSpecialKeysAreNotPartOfTheLocallyModifiedKeys
{
    // given
    NSSet *expected = [NSSet setWithArray:@[
                                            ZMConversationUserDefinedNameKey,
                                            ZMConversationUnsyncedInactiveParticipantsKey,
                                            ZMConversationUnsyncedActiveParticipantsKey,
                                            ZMConversationIsArchivedKey,
                                            ZMConversationIsSilencedKey,
                                            ZMConversationIsSelfAnActiveMemberKey,
                                            ZMConversationArchivedEventIDDataKey,
                                            ZMConversationCallDeviceIsActiveKey,
                                            ZMConversationClearedEventIDDataKey,
                                            ZMConversationLastReadServerTimeStampKey,
                                            ZMConversationClearedTimeStampKey,
                                            ZMConversationIsSendingVideoKey,
                                            ZMConversationIsIgnoringCallKey
                                            ]
                       ];
    
    
    // when
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];

    // then
    XCTAssertEqualObjects([NSSet setWithArray:conversation.keysTrackedForLocalModifications], expected);
}

- (void)testThatItAddsCallDeviceIsActiveToLocallyModifiedKeysIfHasLocalModificationsForCallDeviceIsActiveIsSet
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    XCTAssertFalse(conversation.hasLocalModificationsForCallDeviceIsActive);
    XCTAssertFalse([conversation.keysThatHaveLocalModifications containsObject:ZMConversationCallDeviceIsActiveKey]);

    // when
    conversation.callDeviceIsActive = YES;
    
    // then
    XCTAssertTrue(conversation.hasLocalModificationsForCallDeviceIsActive);
    XCTAssertTrue([conversation.keysThatHaveLocalModifications containsObject:ZMConversationCallDeviceIsActiveKey]);
}


- (void)testThatItReturnsAnExistingConversationByUUID
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        
        // when
        ZMConversation *found = [ZMConversation conversationWithRemoteID:uuid createIfNeeded:NO inContext:self.syncMOC];
        
        // then
        XCTAssertEqualObjects(found.remoteIdentifier, uuid);
        XCTAssertEqualObjects(found.objectID, conversation.objectID);
    }];
}

- (void)testThatItDoesNotCreateTheSelfConversationOnTheSyncMoc
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSUUID *uuid = NSUUID.createUUID;
        [ZMUser selfUserInContext:self.syncMOC].remoteIdentifier = uuid;
        [self.syncMOC saveOrRollback];
        
        // when
        ZMConversation *conversation = [ZMConversation conversationWithRemoteID:uuid createIfNeeded:YES inContext:self.syncMOC];
        
        // then
        XCTAssertNotNil(conversation);
    }];
}


- (void)testThatItReturnsAnExistingConversationByUUIDEvenIfTheTypeIsInvalid
{
    // given
    NSUUID *uuid = NSUUID.createUUID;
    __block NSManagedObjectID *moid;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.conversationType = ZMConversationTypeInvalid;
        conversation.remoteIdentifier = uuid;
        
        [self.syncMOC saveOrRollback];
        moid = conversation.objectID;
    }];
    
    // when
    ZMConversation *found = [ZMConversation conversationWithRemoteID:uuid createIfNeeded:NO inContext:self.uiMOC];
    
    // then
    XCTAssertEqualObjects(found.remoteIdentifier, uuid);
    XCTAssertEqualObjects(found.objectID, moid);
}

- (void)testThatItDoesNotReturnANonExistingUserByUUID
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        NSUUID *secondUUID = NSUUID.createUUID;
        
        conversation.remoteIdentifier = uuid;
        
        // when
        ZMConversation *found = [ZMConversation conversationWithRemoteID:secondUUID createIfNeeded:NO inContext:self.syncMOC];
        
        // then
        XCTAssertNil(found);
    }];
}

- (void)testThatItCreatesAUserForNonExistingUUID
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSUUID *uuid = NSUUID.createUUID;
        
        // when
        ZMConversation *found = [ZMConversation conversationWithRemoteID:uuid createIfNeeded:YES inContext:self.syncMOC];
        
        // then
        XCTAssertNotNil(found);
        XCTAssertEqualObjects(uuid, found.remoteIdentifier);
    }];
}


- (void)testThatItUpdatesItselfFromTransportData
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        NSDictionary *payload = @{
                                  @"last_event_time" : @"2014-04-30T16:30:16.625Z",
                                  @"name" : [NSNull null],
                                  @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                                  @"last_event" : @"5.800112314308490f",
                                  @"members" : @{
                                          @"self" : @{
                                                  @"status" : @0,
                                                  @"muted_time" : [NSNull null],
                                                  @"status_ref" : @"0.0",
                                                  @"last_read" : @"5.800112314308490f",
                                                  @"muted" : @1,
                                                  @"archived" : @"4.8000000432403240",
                                                  @"status_time" : @"2014-03-14T16:47:37.573Z",
                                                  @"id" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9"
                                                  },
                                          @"others" : @[]
                                          },
                                  @"type" : @1,
                                  @"id" : [uuid transportString]
                                  };
        
        // when
        [conversation updateWithTransportData:payload];
        
        // then
        XCTAssertEqualObjects(conversation.remoteIdentifier, [payload[@"id"] UUID]);
        XCTAssertNil(conversation.userDefinedName);
        XCTAssertEqual(conversation.conversationType, ZMConversationTypeSelf);
        XCTAssertEqualObjects(conversation.lastModifiedDate, [NSDate dateWithTransportString:payload[@"last_event_time"]]);
        XCTAssertEqualObjects(conversation.lastEventID, [ZMEventID eventIDWithString:payload[@"last_event"]]);
        XCTAssertEqualObjects(conversation.lastServerTimeStamp, [NSDate dateWithTransportString:payload[@"last_event_time"]]);

        XCTAssertTrue(conversation.isArchived);
        XCTAssertTrue(conversation.isSilenced);
        XCTAssertEqualObjects(conversation.creator.remoteIdentifier, [payload[@"creator"] UUID]);
        XCTAssertEqual(conversation.unsyncedInactiveParticipants.count, 0u);
        XCTAssertEqual(conversation.unsyncedActiveParticipants.count, 0u);
        
    }];
}


- (void)testThatItUpdatesItselfFromTransportDataForGroupConversation
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        
        NSUUID *user1UUID = [NSUUID createUUID];
        NSUUID *user2UUID = [NSUUID createUUID];
        NSUUID *user3UUID = [NSUUID createUUID];
        
        NSDictionary *payload = @{
                                  @"last_event_time" : @"2014-04-30T16:30:16.625Z",
                                  @"name" : [NSNull null],
                                  @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                                  @"last_event" : @"5.800112314308490f",
                                  @"members" : @{
                                          @"self" : @{
                                                  @"status" : @0,
                                                  @"muted_time" : [NSNull null],
                                                  @"status_ref" : @"0.0",
                                                  @"last_read" : @"5.800112314308490f",
                                                  @"muted" : [NSNull null],
                                                  @"archived" : [NSNull null],
                                                  @"status_time" : @"2014-03-14T16:47:37.573Z",
                                                  @"id" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9"
                                                  },
                                          @"others" : @[
                                                  @{
                                                      @"status": @0,
                                                      @"id": [user1UUID transportString]
                                                      },
                                                  @{
                                                      @"status": @0,
                                                      @"id": [user2UUID transportString]
                                                      },
                                                  @{
                                                      @"status": @1,
                                                      @"id": [user3UUID transportString]
                                                      },
                                                  
                                                  ]
                                          },
                                  @"type" : @0,
                                  @"id" : [uuid transportString]
                                  };
        
        // when
        [conversation updateWithTransportData:payload];
        
        // then
        XCTAssertEqualObjects(conversation.remoteIdentifier, [payload[@"id"] UUID]);
        XCTAssertNil(conversation.userDefinedName);
        XCTAssertEqual(conversation.conversationType, ZMConversationTypeGroup);
        XCTAssertEqualObjects(conversation.lastModifiedDate, [NSDate dateWithTransportString:payload[@"last_event_time"]]);
        XCTAssertEqualObjects(conversation.lastEventID, [ZMEventID eventIDWithString:payload[@"last_event"]]);
        XCTAssertEqualObjects(conversation.creator.remoteIdentifier, [payload[@"creator"] UUID]);
        
        ZMUser *user1 = [ZMUser userWithRemoteID:user1UUID createIfNeeded:NO inContext:self.syncMOC];
        XCTAssertNotNil(user1);
        
        ZMUser *user2 = [ZMUser userWithRemoteID:user2UUID createIfNeeded:NO inContext:self.syncMOC];
        XCTAssertNotNil(user2);
        
        XCTAssertEqualObjects(conversation.otherActiveParticipants, ([NSOrderedSet orderedSetWithObjects:user1, user2, nil]) );
        
        ZMUser *user3 = [ZMUser userWithRemoteID:user3UUID createIfNeeded:NO inContext:self.syncMOC];
        XCTAssertNotNil(user3);
        
        XCTAssertEqualObjects(conversation.otherInactiveParticipants, ([NSOrderedSet orderedSetWithObjects:user3, nil]) );
        
        XCTAssertEqual(conversation.unsyncedActiveParticipants.count, 0u);
        XCTAssertEqual(conversation.unsyncedInactiveParticipants.count, 0u);
        
        XCTAssertFalse(conversation.isArchived);
        XCTAssertFalse(conversation.isSilenced);
    }];
}

- (void)testThatUpdatingFromTransportDataDoesNotSetAnyLocalModifiedKey
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        
        NSUUID *user1UUID = [NSUUID createUUID];
        NSUUID *user2UUID = [NSUUID createUUID];
        NSUUID *user3UUID = [NSUUID createUUID];
        
        NSDictionary *payload = @{
                                  @"last_event_time" : @"2014-04-30T16:30:16.625Z",
                                  @"name" : @"Boo",
                                  @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                                  @"last_event" : @"5.800112314308490f",
                                  @"members" : @{
                                          @"self" : @{
                                                  @"status" : @0,
                                                  @"muted_time" : [NSNull null],
                                                  @"status_ref" : @"0.0",
                                                  @"last_read" : @"5.800112314308490f",
                                                  @"muted" : [NSNull null],
                                                  @"archived" : [NSNull null],
                                                  @"status_time" : @"2014-03-14T16:47:37.573Z",
                                                  @"id" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9"
                                                  },
                                          @"others" : @[
                                                  @{
                                                      @"status": @0,
                                                      @"id": [user1UUID transportString]
                                                      },
                                                  @{
                                                      @"status": @0,
                                                      @"id": [user2UUID transportString]
                                                      },
                                                  @{
                                                      @"status": @1,
                                                      @"id": [user3UUID transportString]
                                                      },
                                                  
                                                  ]
                                          },
                                  @"type" : @0,
                                  @"id" : [uuid transportString]
                                  };
        
        // when
        [conversation updateWithTransportData:payload];
        XCTAssertTrue([self.syncMOC saveOrRollback]);
        
        // then
        XCTAssertEqualObjects(conversation.keysThatHaveLocalModifications, [NSSet set]);
    }];
}

- (void)testThatItUpdatesWithoutCrashesFromTransportMissingFields
{
    
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    NSUUID *uuid = NSUUID.createUUID;
    conversation.remoteIdentifier = uuid;
    NSDictionary *payload = @{};
    
    // when
    [self performPretendingUiMocIsSyncMoc:^{
        [self performIgnoringZMLogError:^{
            [conversation updateWithTransportData:payload];
        }];
    }];
    
    // then
    XCTAssertNotNil(conversation);
}

- (void)testThatItUpdatesItselfFromTransportMissingOthers
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        NSDictionary *payload = @{
                                  @"last_event_time" : @"2014-04-30T16:30:16.625Z",
                                  @"name" : [NSNull null],
                                  @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                                  @"last_event" : @"5.800112314308490f",
                                  @"members" : @{
                                          @"self" : @{
                                                  @"status" : @0,
                                                  @"muted_time" : [NSNull null],
                                                  @"status_ref" : @"0.0",
                                                  @"last_read" : @"5.800112314308490f",
                                                  @"muted" : [NSNull null],
                                                  @"archived" : [NSNull null],
                                                  @"status_time" : @"2014-03-14T16:47:37.573Z",
                                                  @"id" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9"
                                                  },
                                          },
                                  @"type" : @1,
                                  @"id" : [uuid transportString]
                                  };
        
        // when
        [self performPretendingUiMocIsSyncMoc:^{
            [self performIgnoringZMLogError:^{
                [conversation updateWithTransportData:payload];
            }];
        }];
        
        // then
        XCTAssertEqualObjects(conversation.remoteIdentifier, [payload[@"id"] UUID]);
    }];
}

- (void)testThatItUpdatesItselfFromTransportMissingSelf
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        NSDictionary *payload = @{
                                  @"last_event_time" : @"2014-04-30T16:30:16.625Z",
                                  @"name" : [NSNull null],
                                  @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                                  @"last_event" : @"5.800112314308490f",
                                  @"members" : @{
                                          @"others" : @[]
                                          },
                                  @"type" : @1,
                                  @"id" : [uuid UUIDString]
                                  };
        
        // when
        [self performPretendingUiMocIsSyncMoc:^{
            [self performIgnoringZMLogError:^{
                [conversation updateWithTransportData:payload];
            }];
        }];
        
        // then
        XCTAssertEqualObjects(conversation.remoteIdentifier, [payload[@"id"] UUID]);
    }];
}

- (void)testThatItUpdatesItselfFromTransportInvalidFields
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        NSDictionary *payload = @{
                                  @"last_event_time" : @4,
                                  @"name" : @5,
                                  @"creator" : @6,
                                  @"last_event" : @7,
                                  @"members" : @8,
                                  @"type" : @"goo",
                                  @"id" : @100
                                  };
        
        // when
        [self performPretendingUiMocIsSyncMoc:^{
            [self performIgnoringZMLogError:^{
                [conversation updateWithTransportData:payload];
            }];
        }];
        
        // then
        XCTAssertNotNil(conversation);
    }];
}

- (void)testThatItUpdatesItselfFromTransportInvalidOthersMembers
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        NSDictionary *payload = @{
                                  @"last_event_time" : @"2014-04-30T16:30:16.625Z",
                                  @"name" : [NSNull null],
                                  @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                                  @"last_event" : @"5.800112314308490f",
                                  @"members" : @{
                                          @"others" : @3
                                          },
                                  @"type" : @1,
                                  @"id" : [uuid UUIDString]
                                  };
        
        // when
        [self performPretendingUiMocIsSyncMoc:^{
            [self performIgnoringZMLogError:^{
                [conversation updateWithTransportData:payload];
            }];
        }];
        
        // then
        XCTAssertNotNil(conversation);
    }];
}


- (void)testThatConversationsDoNotGetInsertedUpstreamUnlessTheyAreGroupConversations;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    NSPredicate *predicate = [ZMConversation predicateForObjectsThatNeedToBeInsertedUpstream];
    ZMConversationType types[] = {
        ZMConversationTypeSelf,
        ZMConversationTypeOneOnOne,
        ZMConversationTypeGroup,
        ZMConversationTypeConnection,
        ZMConversationTypeInvalid,
    };
    
    for (size_t i = 0; i < (sizeof(types)/sizeof(*types)); ++i) {
        // when
        conversation.conversationType = types[i];
        
        // then
        if (types[i] == ZMConversationTypeGroup) {
            XCTAssertTrue([predicate evaluateWithObject:conversation], @"type == %d", types[i]);
        } else {
            XCTAssertFalse([predicate evaluateWithObject:conversation], @"type == %d", types[i]);
        }
    }
}

- (void)testThatTheConversationListFiltersOutConversationOfInvalidType
{
    // given
    ZMConversation *oneToOneConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *invalidConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    oneToOneConversation.conversationType = ZMConversationTypeOneOnOne;
    invalidConversation.conversationType = ZMConversationTypeInvalid;
    
    // when
    NSArray *conversationsInContext = [ZMConversation conversationsIncludingArchivedInContext:self.uiMOC];
    
    // then
    XCTAssertEqualObjects(conversationsInContext, @[oneToOneConversation]);
}

- (void)testThatConversationByUUIDDoesNotFilterOutConversationsOfInvalidType
{
    // given
    ZMConversation *invalidConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    invalidConversation.conversationType = ZMConversationTypeInvalid;
    invalidConversation.remoteIdentifier = [NSUUID createUUID];
    
    // when
    ZMConversation *fetchedConversation = [ZMConversation conversationWithRemoteID:invalidConversation.remoteIdentifier createIfNeeded:NO inContext:self.uiMOC];
    
    // then
    XCTAssertEqual(fetchedConversation, invalidConversation);
}

- (void)testThatConversationsDoNotGetUpdatedUpstreamIfTheyDoNotHaveARemoteIdentifier
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    [conversation setLocallyModifiedKeys:[NSSet setWithObject:ZMConversationUserDefinedNameKey]];
    
    NSPredicate *predicate = [ZMConversation predicateForObjectsThatNeedToBeUpdatedUpstream];

    // then
    XCTAssertFalse([predicate evaluateWithObject:conversation]);
}

- (void)testThatConversationsDoNotGetUpdatedUpstreamWhenTheyAreInvalidOrConnectionConversations;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    [conversation setLocallyModifiedKeys:[NSSet setWithObject:ZMConversationUserDefinedNameKey]];
    NSPredicate *predicate = [ZMConversation predicateForObjectsThatNeedToBeUpdatedUpstream];
    ZMConversationType types[] = {
        ZMConversationTypeConnection,
        ZMConversationTypeInvalid,
    };
    
    for (size_t i = 0; i < (sizeof(types)/sizeof(*types)); ++i) {
        // when
        conversation.conversationType = types[i];
        
        // then
        if (types[i] == ZMConversationTypeGroup) {
            XCTAssertTrue([predicate evaluateWithObject:conversation], @"type == %d", types[i]);
        } else {
            XCTAssertFalse([predicate evaluateWithObject:conversation], @"type == %d", types[i]);
        }
    }
}

- (void)testThatPendingConversationsAreUpdatedUpstream;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    conversation.remoteIdentifier = NSUUID.createUUID;
    [conversation setLocallyModifiedKeys:[NSSet setWithObject:ZMConversationArchivedEventIDDataKey]];
    
    NSPredicate *predicate = [ZMConversation predicateForObjectsThatNeedToBeUpdatedUpstream];
    
    // then
    XCTAssertTrue([predicate evaluateWithObject:conversation]);
}

- (void)testThatItSortsTheConversationBasedOnServerTimestamp
{
    // given
    const NSUInteger numberOfMessages = 50;
    [self.syncMOC performGroupedBlockAndWait:^{
        
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.remoteIdentifier = [NSUUID createUUID];
        
        ZMUser *creator = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.creator = creator;
        
        for(NSUInteger i = 0; i < numberOfMessages; ++i) {
            NSString *text = [NSString stringWithFormat:@"Conversation test message %lu", (unsigned long)i];
            ZMTextMessage *message = [ZMTextMessage insertNewObjectInManagedObjectContext:self.syncMOC];
            message.text = text;
            message.visibleInConversation = conversation;
            message.sender = creator;
            uint64_t poorRandom1 = (13 + i * 98947) % 93179;
            uint64_t poorRandom2 = (13 + i * 98953) % 93179;
            message.eventID = [ZMEventID eventIDWithMajor:i+1 minor:poorRandom1];
            message.serverTimestamp = [NSDate dateWithTimeIntervalSinceReferenceDate:poorRandom2*100];
        }
        
        // when
        [conversation sortMessages];
        
        // then
        NSDate *lastFoundDate;
        for(ZMMessage *message in conversation.messages)
        {
            if(lastFoundDate != nil) {
                XCTAssertEqual([lastFoundDate compare:message.serverTimestamp], NSOrderedAscending);
            }
            lastFoundDate = message.serverTimestamp;
        }
        XCTAssertNotNil(lastFoundDate);
    }];
}

- (void)testThatItFetchesMessagesAndSetsTheUnreadCountAfterSortingMessages
{
    // given
    const NSUInteger numberOfMessages = 10;
    [self.syncMOC performGroupedBlockAndWait:^{
        
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.remoteIdentifier = [NSUUID createUUID];

        ZMUser *creator = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.creator = creator;
        
        for(NSUInteger i = 0; i < numberOfMessages; ++i) {
            NSString *text = [NSString stringWithFormat:@"Conversation test message %lu", (unsigned long)i];
            ZMTextMessage *message = [ZMTextMessage insertNewObjectInManagedObjectContext:self.syncMOC];
            message.text = text;
            message.visibleInConversation = conversation;
            message.sender = creator;
            uint64_t poorRandom1 = (13 + i * 98947) % 93179;
            uint64_t poorRandom2 = (13 + i * 98953) % 93179;
            message.eventID = [ZMEventID eventIDWithMajor:i+1 minor:poorRandom1];
            message.serverTimestamp = [NSDate dateWithTimeIntervalSinceReferenceDate:poorRandom2*100];
        }
        
        XCTAssertEqual(conversation.estimatedUnreadCount, 0u);
        
        // when
        [conversation sortMessages];
        
        // then
        XCTAssertEqual(conversation.estimatedUnreadCount, 10u);
    }];
}

- (void)testThatItDoesNotTouchTheMessagesRelationWhenItIsAlreadySorted;
{
    // If we dirty the relationship (on the sync context), changes in the UI context might
    // get rolled back.
    // We were seeing that messages would get lost when the user quickly inserts a lot
    // of messages.
    
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *mA = [conversation appendMessagesWithText:@"A"].firstObject;
    mA.serverTimestamp = [NSDate dateWithTimeIntervalSinceNow:10000];
    ZMMessage *mB = [conversation appendMessagesWithText:@"B"].firstObject;
    mB.serverTimestamp = [NSDate dateWithTimeIntervalSinceNow:20000];
    [self performIgnoringZMLogError:^{
        [conversation sortMessages];
    }];
    XCTAssert([self.uiMOC saveOrRollback]);
    XCTAssertEqual(conversation.changedValues.count, 0u);
    
    // when
    [self performIgnoringZMLogError:^{
        [conversation sortMessages];
    }];
    
    // then
    XCTAssertEqual(conversation.changedValues.count, 0u);
}

- (void)testThatItRemovesAndAppendsTheMessageWhenResortingWithUpdatedMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMTextMessage *message1 = [conversation appendMessagesWithText:@"hallo"].firstObject;
    message1.serverTimestamp = [NSDate dateWithTimeIntervalSinceNow:-50];
    ZMTextMessage *message2 = [conversation appendMessagesWithText:@"hallo"].firstObject;
    message2.serverTimestamp = [NSDate dateWithTimeIntervalSinceNow:-40];
    ZMTextMessage *message3 = [conversation appendMessagesWithText:@"hallo"].firstObject;
    message3.serverTimestamp = [NSDate dateWithTimeIntervalSinceNow:-30];

    NSOrderedSet *messages = [NSOrderedSet orderedSetWithArray:@[message1, message2, message3]];
    XCTAssertEqualObjects(messages, conversation.messages);
    
    // when
    message1.serverTimestamp = [NSDate date];
    [conversation resortMessagesWithUpdatedMessage:message1];
    
    // then
    NSOrderedSet *expectedMessages = [NSOrderedSet orderedSetWithArray:@[message2, message3, message1]];
    XCTAssertEqualObjects(expectedMessages, conversation.messages);
}

- (void)testThatItUsesServerTimestampWhenResortingWithUpdatedMessage
{
    // given
    NSDate *date1 = [NSDate dateWithTimeIntervalSinceReferenceDate:2000];
    NSDate *date2 = [NSDate dateWithTimeIntervalSinceReferenceDate:3000];
    NSDate *date3 = [NSDate dateWithTimeIntervalSinceReferenceDate:4000];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMTextMessage *message1 = [conversation appendMessagesWithText:@"hallo 1"].firstObject;
    message1.serverTimestamp = date1;
    ZMTextMessage *message2 = [conversation appendMessagesWithText:@"hallo 2"].firstObject;
    message2.serverTimestamp = date3;
    ZMTextMessage *message3 = [conversation appendMessagesWithText:@"hallo 3"].firstObject;
    
    NSOrderedSet *messages = [NSOrderedSet orderedSetWithArray:@[message1, message2, message3]];
    XCTAssertEqualObjects(messages, conversation.messages);
    
    // when
    message3.serverTimestamp = date2;
    [conversation resortMessagesWithUpdatedMessage:message3];
    
    // then
    NSOrderedSet *expectedMessages = [NSOrderedSet orderedSetWithArray:@[message1, message3, message2]];
    XCTAssertEqualObjects(expectedMessages, conversation.messages);
}

- (void)testThatLastModifiedDateOfTheConversationGetsUpdatedWhenAMessageIsInserted
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastModifiedDate = [NSDate dateWithTimeIntervalSinceReferenceDate:1000];
    
    // when
    [conversation appendMessagesWithText:@"foo"];
    
    // then
    AssertDateIsRecent(conversation.lastModifiedDate);
}

- (void)testThatItAddsToDownloadedEventIDs
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMEventID *eventID1 = [ZMEventID eventIDWithMajor:10 minor:954532];
    ZMEventID *eventID2 = [ZMEventID eventIDWithMajor:345 minor:2314345];
    XCTAssertFalse([conversation.downloadedMessageIDs containsEvent:eventID1]);
    XCTAssertFalse([conversation.downloadedMessageIDs containsEvent:eventID2]);
    
    // when
    [conversation addEventToDownloadedEvents:eventID1 timeStamp:nil];
    
    // then
    XCTAssertTrue([conversation.downloadedMessageIDs containsEvent:eventID1]);
    XCTAssertFalse([conversation.downloadedMessageIDs containsEvent:eventID2]);
    
    // when
    [conversation addEventToDownloadedEvents:eventID2 timeStamp:nil];
    XCTAssertTrue([conversation.downloadedMessageIDs containsEvent:eventID1]);
    XCTAssertTrue([conversation.downloadedMessageIDs containsEvent:eventID2]);
}

- (void)testThatWhenAddingADownloadedLastReadEventItSetsTheLastReadTimeStamp
{
    // given
    NSDate *lastReadDate = [NSDate date];
    ZMEventID *lastReadEventID = self.createEventID;
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastReadEventID = lastReadEventID;
    
    XCTAssertFalse([conversation.downloadedMessageIDs containsEvent:lastReadEventID]);
    XCTAssertNil(conversation.lastReadServerTimeStamp);
    
    // when
    [self performIgnoringZMLogError:^{
        [conversation addEventToDownloadedEvents:lastReadEventID timeStamp:lastReadDate];
    }];
    
    // then
    XCTAssertNotNil(conversation.lastReadServerTimeStamp);
    XCTAssertEqualObjects(lastReadDate, conversation.lastReadServerTimeStamp);
}


- (void)testThatWhenAddingADownloadedClearedEventItSetsTheClearedTimeStamp
{
    // given
    NSDate *clearedDate = [NSDate date];
    ZMEventID *clearedEventID = self.createEventID;
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.clearedEventID = clearedEventID;
    [conversation setDownloadedMessageIDs:[[ZMEventIDRangeSet alloc] init]];
    
    XCTAssertFalse([conversation.downloadedMessageIDs containsEvent:clearedEventID]);
    XCTAssertNil(conversation.clearedTimeStamp);
    
    // when
    [conversation addEventToDownloadedEvents:clearedEventID timeStamp:clearedDate];
    
    // then
    XCTAssertTrue([conversation.downloadedMessageIDs containsEvent:clearedEventID]);
    XCTAssertNotNil(conversation.clearedTimeStamp);
    XCTAssertEqualObjects(clearedDate, conversation.clearedTimeStamp);
}

- (void)testThatWhenAddingAnEventFollowingTheClearedEventItSetsTheClearedTimeStampIfNil
{
    // given
    ZMEventID *clearedEventID = self.createEventID;
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.clearedEventID = clearedEventID;
    [conversation setDownloadedMessageIDs:[[ZMEventIDRangeSet alloc] init]];
    
    XCTAssertFalse([conversation.downloadedMessageIDs containsEvent:clearedEventID]);
    XCTAssertNil(conversation.clearedTimeStamp);
    ZMEventID *eventID = [ZMEventID eventIDWithMajor:clearedEventID.major+1 minor:8];
    NSDate *eventDate = [NSDate date];

    // when
    [conversation addEventToDownloadedEvents:eventID timeStamp:eventDate];
    
    // then
    XCTAssertTrue([conversation.downloadedMessageIDs containsEvent:eventID]);
    XCTAssertNotNil(conversation.clearedTimeStamp);
    XCTAssertEqualObjects(conversation.clearedTimeStamp, [eventDate dateByAddingTimeInterval:-1]);
}

- (void)testThatWhenAddingAnEventFollowingTheClearedEventItDoesNotSetTheClearedTimeStampIfNotNil
{
    // given
    NSDate *clearedDate = [NSDate date];
    ZMEventID *clearedEventID = self.createEventID;
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.clearedEventID = clearedEventID;
    conversation.clearedTimeStamp = clearedDate;
    [conversation setDownloadedMessageIDs:[[ZMEventIDRangeSet alloc] init]];
    
    XCTAssertFalse([conversation.downloadedMessageIDs containsEvent:clearedEventID]);
    XCTAssertNotNil(conversation.clearedTimeStamp);
    
    ZMEventID *eventID = [ZMEventID eventIDWithMajor:clearedEventID.major+1 minor:8];
    NSDate *eventDate = [clearedDate dateByAddingTimeInterval:10];
    
    // when
    [conversation addEventToDownloadedEvents:eventID timeStamp:eventDate];
    
    // then
    XCTAssertTrue([conversation.downloadedMessageIDs containsEvent:eventID]);
    XCTAssertEqualObjects(conversation.clearedTimeStamp, clearedDate);
}

- (void)testThatItAddsRangeToDownloadedEventIDs
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMEventID *eventID1 = [ZMEventID eventIDWithMajor:10 minor:954532];
    ZMEventID *middleEventID = [ZMEventID eventIDWithMajor:100 minor:346366];
    ZMEventID *eventID2 = [ZMEventID eventIDWithMajor:345 minor:2314345];
    XCTAssertFalse([conversation.downloadedMessageIDs containsEvent:eventID1]);
    XCTAssertFalse([conversation.downloadedMessageIDs containsEvent:eventID2]);
    XCTAssertFalse([conversation.downloadedMessageIDs containsEvent:middleEventID]);
    
    // when
    [conversation addEventRangeToDownloadedEvents:[[ZMEventIDRange alloc] initWithEventIDs:@[eventID1, eventID2]]];
    
    // then
    XCTAssertTrue([conversation.downloadedMessageIDs containsEvent:eventID1]);
    XCTAssertTrue([conversation.downloadedMessageIDs containsEvent:eventID2]);
    XCTAssertTrue([conversation.downloadedMessageIDs containsEvent:middleEventID]);
}


- (void)testThatItSplitsMessagesIfLengthExceeded
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    NSString *longText = [@"" stringByPaddingToLength:ZMConversationMaxTextMessageLength + 1000 withString:@"😋" startingAtIndex:0];
    
    // then
    NSArray *messages = [conversation appendMessagesWithText:longText];

    XCTAssertEqual(messages.count, 4u);
    XCTAssertEqual(conversation.messages.count, 4u);
}

- (void)testThatItInsertsSplittedMessagesInTheRightOrder
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];

    // when
    NSString *firstText = [@"" stringByPaddingToLength:ZMConversationMaxTextMessageLength withString:@"A" startingAtIndex:0];
    NSString *secondText = [@"" stringByPaddingToLength:ZMConversationMaxTextMessageLength withString:@"B" startingAtIndex:0];
    NSString *longText = [firstText stringByAppendingString:secondText];

    // then
    NSArray *messages = [conversation appendMessagesWithText:longText];

    XCTAssertEqual(messages.count, 2u);
    XCTAssertEqual(conversation.messages.count, 2u);
    XCTAssertEqualObjects([(id<ZMConversationMessage>)conversation.messages.firstObject messageText], firstText);
    XCTAssertEqualObjects([(id<ZMConversationMessage>)conversation.messages.lastObject messageText], secondText);
}

- (void)testThatItSplitsMessagesAfterSpaces
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];

    // when
    NSString *firstText = [[@"" stringByPaddingToLength:ZMConversationMaxTextMessageLength - 2 withString:@"A" startingAtIndex:0] stringByAppendingString:@" "];
    NSString *secondText = [@"" stringByPaddingToLength:ZMConversationMaxTextMessageLength withString:@"C" startingAtIndex:0];
    NSString *longText = [[firstText stringByAppendingString:@"B"] stringByAppendingString:secondText];

    // then
    NSArray *messages = [conversation appendMessagesWithText:longText];

    XCTAssertEqual(messages.count, 3u);
    XCTAssertEqual(conversation.messages.count, 3u);
    XCTAssertEqualObjects([(id<ZMConversationMessage>)conversation.messages.firstObject messageText], firstText);
    NSString *expectedSecondMessageText = [@"B" stringByPaddingToLength:ZMConversationMaxTextMessageLength withString:@"C" startingAtIndex:0];
    XCTAssertEqualObjects([(id<ZMConversationMessage>)conversation.messages[1] messageText], expectedSecondMessageText);
    XCTAssertEqualObjects([(id<ZMConversationMessage>)conversation.messages.lastObject messageText], @"C");
}

- (void)testThatItRejectsWhitespaceOnlyText
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    NSString *whiteSpaceString = @"      ";
    
    // when
    [self performIgnoringZMLogError:^{
        [conversation appendMessagesWithText:whiteSpaceString];
    }];
    
    // then    
    XCTAssertEqual(conversation.messages.count, 0u);
}


- (void)testThatItDoesNotRejectNonWhitespaceOnlyText
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    NSString *someString = @"some string";
    
    // when
    [conversation appendMessagesWithText:someString];
    
    // then
    XCTAssertEqual(conversation.messages.count, 1u);
}


- (void)testThatItSetsTheLastModifiedDateToNowWhenInsertingAGroupConversationFromTheUI;
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    ZMConversation *sut = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:@[user1, user2]];
    
    // then
    AssertDateIsRecent(sut.lastModifiedDate);
}


- (void)testThatItSetsTheExpirationDateOnATextMessage
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *sut = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:@[user1, user2]];
    
    // when
    ZMTextMessage *message = [sut appendMessagesWithText:@"Quux"].firstObject;

    // then
    XCTAssertNotNil(message.expirationDate);
    NSDate *expectedDate = [NSDate dateWithTimeIntervalSinceNow:ZMTransportRequestDefaultExpirationInterval];
    XCTAssertLessThan(fabs([message.expirationDate timeIntervalSinceDate:expectedDate]), 1);
}

- (void)testThatItDeletesCachedValueForLastEventIDAfterAwakingFromSnapshotEvents
{
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastEventID = [self createEventID];
    
    [conversation willAccessValueForKey:@"lastEventID"];
    ZMEventID *cachedID = [conversation primitiveValueForKey:@"lastEventID"];
    [conversation didAccessValueForKey:@"lastEventID"];
    
    XCTAssertEqualObjects(cachedID, conversation.lastEventID);
    
    // when
    
    [conversation awakeFromSnapshotEvents:NSSnapshotEventUndoUpdate];
    
    [conversation willAccessValueForKey:@"lastEventID"];
    ZMEventID *cachedIDAfterDeleting = [conversation primitiveValueForKey:@"lastEventID"];
    [conversation didAccessValueForKey:@"lastEventID"];

    XCTAssertNil(cachedIDAfterDeleting);
}

- (void)testThatItDeletesCachedValueForLastReadEventIDAfterAwakingFromSnapshotEvents
{
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastReadEventID = [self createEventID];
    
    [conversation willAccessValueForKey:@"lastReadEventID"];
    ZMEventID *cachedID = [conversation primitiveValueForKey:@"lastReadEventID"];
    [conversation didAccessValueForKey:@"lastReadEventID"];
    
    XCTAssertEqualObjects(cachedID, conversation.lastReadEventID);
    
    // when
    
    [conversation awakeFromSnapshotEvents:NSSnapshotEventUndoUpdate];
    
    [conversation willAccessValueForKey:@"lastReadEventID"];
    ZMEventID *cachedIDAfterDeleting = [conversation primitiveValueForKey:@"lastReadEventID"];
    [conversation didAccessValueForKey:@"lastReadEventID"];
    
    XCTAssertNil(cachedIDAfterDeleting);
}


- (void)testThatItDeletesCachedValueForRemoteIDAfterAwakingFromSnapshotEvents
{
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    [conversation willAccessValueForKey:@"remoteIdentifier"];
    ZMEventID *cachedID = [conversation primitiveValueForKey:@"remoteIdentifier"];
    [conversation didAccessValueForKey:@"remoteIdentifier"];
    
    XCTAssertEqualObjects(cachedID, conversation.remoteIdentifier);
    
    // when
    
    [conversation awakeFromSnapshotEvents:NSSnapshotEventUndoUpdate];
    
    [conversation willAccessValueForKey:@"remoteIdentifier"];
    ZMEventID *cachedIDAfterDeleting = [conversation primitiveValueForKey:@"remoteIdentifier"];
    [conversation didAccessValueForKey:@"remoteIdentifier"];
    
    XCTAssertNil(cachedIDAfterDeleting);
}

- (void)testThatTheUserDefinedNameIsCopied
{
    // given
    NSString *originalValue = @"will@foo.co";
    NSMutableString *mutableValue = [originalValue mutableCopy];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    conversation.userDefinedName = mutableValue;
    [mutableValue appendString:@".uk"];
    
    // then
    XCTAssertEqualObjects(conversation.userDefinedName, originalValue);
}

- (void)testThatTheNormalizedUserDefinedNameIsCopied
{
    // given
    NSString *originalValue = @"will@foo.co";
    NSMutableString *mutableValue = [originalValue mutableCopy];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    conversation.normalizedUserDefinedName = mutableValue;
    [mutableValue appendString:@".uk"];
    
    // then
    XCTAssertEqualObjects(conversation.normalizedUserDefinedName, originalValue);
}

- (void)testThatTheDraftTextIsCopied
{
    // given
    NSString *originalValue = @"will@foo.co";
    NSMutableString *mutableValue = [originalValue mutableCopy];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    conversation.draftMessageText = mutableValue;
    [mutableValue appendString:@".uk"];
    
    // then
    XCTAssertEqualObjects(conversation.draftMessageText, originalValue);
}

- (void)addNotification:(NSNotification *)note
{
    [self.receivedNotifications addObject:note];
}

- (void)testThatItCreatesANotificationWhenCallingSetTyping
{
    // setup
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addNotification:) name:@"ZMTypingNotification" object:nil];
    self.receivedNotifications = [NSMutableArray array];
    
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    [conversation setIsTyping:YES];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqual(self.receivedNotifications.count, 1u);
    NSNotification *note = self.receivedNotifications.firstObject;
    
    XCTAssertEqual(note.object, conversation);
    XCTAssertEqual(note.userInfo[@"isTyping"], @(YES));
    
    // teardown
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.receivedNotifications = nil;
}

- (void)testThatItDetectsTheSelfConversationRemoteID;
{
    // given
    NSUUID *selfID = [NSUUID createUUID];
    [ZMUser selfUserInContext:self.uiMOC].remoteIdentifier = selfID;
    
    // then
    XCTAssertTrue([selfID isSelfConversationRemoteIdentifierInContext:self.uiMOC]);
    XCTAssertFalse([NSUUID.createUUID isSelfConversationRemoteIdentifierInContext:self.uiMOC]);
}

- (void)testThatWhenSetNotToBeUpdatedFromBackendCallStateDoesNotChangeFromTrue
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.callStateNeedsToBeUpdatedFromBackend = YES;
    
    // when
    conversation.needsToBeUpdatedFromBackend = NO;
    
    // then
    XCTAssertTrue(conversation.callStateNeedsToBeUpdatedFromBackend);
}

- (void)testThatWhenSetNotToBeUpdatedFromBackendCallStateDoesNotChangeFromFalse
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.callStateNeedsToBeUpdatedFromBackend = NO;
    
    // when
    conversation.needsToBeUpdatedFromBackend = NO;
    
    // then
    XCTAssertFalse(conversation.callStateNeedsToBeUpdatedFromBackend);
}

- (void)testThatItDoesNotUpdateLastModifiedDateWithLocalSystemMessages
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastModifiedDate = [NSDate.date dateByAddingTimeInterval:-100];
    ZMMessage *firstMessage = [conversation appendMessagesWithText:@"Test Message"].firstObject;
    
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, firstMessage.serverTimestamp);
 
    // when
    NSDate *future = [NSDate.date dateByAddingTimeInterval:100];
    [conversation appendNewPotentialGapSystemMessageWithUsers:nil timestamp:future];
    
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, firstMessage.serverTimestamp);
    XCTAssertEqual(conversation.messages.count, 2lu);
}

- (void)testThatItUpdatesLastModifiedDateWithMessageServerTimestamp_ClientMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
    conversation.lastModifiedDate = [NSDate.date dateByAddingTimeInterval:-100];
    ZMClientMessage *clientMessage = [conversation appendOTRMessageWithText:@"Test Message" nonce:[NSUUID new]];
    
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, clientMessage.serverTimestamp);
    
    NSDate *serverDate = [clientMessage.serverTimestamp dateByAddingTimeInterval:0.2];
    // when
    [clientMessage updateWithPostPayload:@{@"time": serverDate} updatedKeys:[NSSet set]];
    
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, serverDate);
    XCTAssertEqualObjects(clientMessage.serverTimestamp, serverDate);
    
    // cleanup
}

- (void)testThatItDoesNotUpdatesLastModifiedDateWithMessageServerTimestampIfNotNeeded_ClientMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
    conversation.lastModifiedDate = [NSDate.date dateByAddingTimeInterval:-100];
    ZMClientMessage *clientMessage = [conversation appendOTRMessageWithText:@"Test Message" nonce:[NSUUID new]];
    
    NSDate *postingDate = clientMessage.serverTimestamp;
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, clientMessage.serverTimestamp);
    
    NSDate *serverDate = [clientMessage.serverTimestamp dateByAddingTimeInterval:-0.2];
    // when
    [clientMessage updateWithPostPayload:@{@"time": serverDate} updatedKeys:[NSSet set]];
    
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, postingDate);
    XCTAssertEqualObjects(clientMessage.serverTimestamp, serverDate);
}

- (void)testThatItUpdatesLastModifiedDateWithMessageServerTimestamp_PlaintextMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
    conversation.lastModifiedDate = [NSDate.date dateByAddingTimeInterval:-100];
    ZMMessage *firstMessage = [conversation appendMessagesWithText:@"Test Message"].firstObject;
    
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, firstMessage.serverTimestamp);
    
    NSDate *serverDate = [firstMessage.serverTimestamp dateByAddingTimeInterval:0.2];
    // when
    [firstMessage updateWithPostPayload:@{@"time": serverDate, @"id": [ZMEventID eventIDWithMajor:1 minor:1].transportString, @"data": @{@"nonce": firstMessage.nonce}, @"type": @"conversation.message-add"} updatedKeys:[NSSet set]];
    
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, serverDate);
    XCTAssertEqualObjects(firstMessage.serverTimestamp, serverDate);
}

- (void)testThatItDoesNotUpdatesLastModifiedDateWithMessageServerTimestampIfNotNeeded_PlaintextMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
    conversation.lastModifiedDate = [NSDate.date dateByAddingTimeInterval:-100];
    ZMMessage *firstMessage = [conversation appendMessagesWithText:@"Test Message"].firstObject;
    
    NSDate *postingDate = firstMessage.serverTimestamp;
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, firstMessage.serverTimestamp);
    
    NSDate *serverDate = [firstMessage.serverTimestamp dateByAddingTimeInterval:-0.2];
    // when
    [firstMessage updateWithPostPayload:@{@"time": serverDate, @"id": [ZMEventID eventIDWithMajor:1 minor:1].transportString, @"data": @{@"nonce": firstMessage.nonce}, @"type": @"conversation.message-add"} updatedKeys:[NSSet set]];
    
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, postingDate);
    XCTAssertEqualObjects(firstMessage.serverTimestamp, serverDate);
}

@end // general



@implementation ZMConversationTests (ReadOnly)

- (void)testThatAGroupConversationWhereTheUserIsActiveIsNotReadOnly
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.isSelfAnActiveMember = YES;
    
    // then
    XCTAssertFalse(conversation.isReadOnly);
}

- (void)testThatAGroupConversationWhereTheUserIsNotActiveIsReadOnly
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.isSelfAnActiveMember = NO;
    
    // then
    XCTAssertTrue(conversation.isReadOnly);
}

- (void)testThatAOneToOneConversationIsNotReadOnly
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    
    // then
    XCTAssertFalse(conversation.isReadOnly);
}

- (void)testThatAPendingConnectionConversationIsReadOnly
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    
    // then
    XCTAssertTrue(conversation.isReadOnly);
}

- (void)testThatTheSelfConversationIsReadOnly
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    
    // then
    XCTAssertTrue(conversation.isReadOnly);
}

- (void)testThatAnInvalidConversationIsReadOnly
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeInvalid;
    
    // then
    XCTAssertTrue(conversation.isReadOnly);
}

- (void)testThatItRecalculatesIsReadOnlyWhenIsSelfActiveMemberChanges
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    conversation.isSelfAnActiveMember = YES;

    // expect
    [self keyValueObservingExpectationForObject:conversation keyPath:@"isReadOnly" expectedValue:nil];
    
    // when
    conversation.isSelfAnActiveMember = NO;
    
    // then
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatItRecalculatesIsReadOnlyWhenConversationTypeChanges
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    conversation.isSelfAnActiveMember = YES;
    
    // expect
    [self keyValueObservingExpectationForObject:conversation keyPath:@"isReadOnly" expectedValue:nil];
    
    // when
    conversation.conversationType = ZMConversationTypeGroup;
    
    // then
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}

@end




@implementation ZMConversationTests (Connections)

- (void)testThatItReturnsTheConnectionMessage;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.conversation = conversation;
    NSString *message = @"HELLOOOOOO!!!!";
    connection.message = message;
    
    // then
    XCTAssertEqualObjects(conversation.connectionMessage, message);
}

- (void)testThatTheConnectionConversationLastModifiedDateIsSet
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewSentConnectionToUser:user];

    // then
    AssertDateIsRecent(connection.conversation.lastModifiedDate);
}


- (void)testThatIsInvitationConversationReturnsTrueIfItHasAPendingConnection
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.conversation = conversation;
    connection.status = ZMConnectionStatusPending;
    
    // then
    XCTAssertTrue(conversation.isPendingConnectionConversation);
}

- (void)testThatIsInvitationConversationReturnsFalseIfItHasNoConnection
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];

    // then
    XCTAssertFalse(conversation.isPendingConnectionConversation);
}

- (void)testThatIsInvitationConversationReturnsFalseIfItHasTheWrongConnectionStatus
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.conversation = conversation;
    NSArray *statusesToTest = @[
                        @(ZMConnectionStatusAccepted),
                        @(ZMConnectionStatusBlocked),
                        @(ZMConnectionStatusIgnored),
                        @(ZMConnectionStatusInvalid),
                        @(ZMConnectionStatusSent)
                    ];

    for(NSNumber *status in statusesToTest) {
        connection.status = (ZMConnectionStatus) status.intValue;
        
        // then
        XCTAssertFalse(conversation.isPendingConnectionConversation);
    }
    
}

- (void)testThatExistingOneOnOneConversationWithUserReturnsNilIfNotConnected
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *SomeOtherConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    NOT_USED(SomeOtherConversation);
    
    // when
    ZMConversation *fetchedConversation = [ZMConversation existingOneOnOneConversationWithUser:user inUserSession:self.mockUserSessionWithUIMOC];
    
    // then
    XCTAssertNil(fetchedConversation);
    
}

- (void)testThatExistingOneOnOneConversationWithUserReturnsTheConnectionConversation
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *connectionConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    
    connection.to = user;
    connection.conversation = connectionConversation;
    
    // when
    ZMConversation *fetchedConversation = [ZMConversation existingOneOnOneConversationWithUser:user inUserSession:self.mockUserSessionWithUIMOC];

    // then
    XCTAssertEqual(fetchedConversation, connectionConversation);
}

- (void)testThatItRecalculatesIsPendingConnectionWhenConnectionStatusChanges
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.conversation = conversation;
    connection.status = ZMConnectionStatusPending;
    
    XCTAssertTrue(conversation.isPendingConnectionConversation);
    
    // expect
    [self keyValueObservingExpectationForObject:conversation keyPath:@"isPendingConnectionConversation" expectedValue:nil];
    
    // when
    connection.status = ZMConnectionStatusAccepted;
    
    // then
    XCTAssertFalse(conversation.isPendingConnectionConversation);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}


- (void)testThatItRecalculatesIsPendingConnectionWhenConnectionChanges
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConnection *connection1 = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection1.conversation = conversation;
    connection1.status = ZMConnectionStatusPending;
    
    XCTAssertEqualObjects(conversation.connection, connection1);
    XCTAssertTrue(conversation.isPendingConnectionConversation);

    // expect
    [self keyValueObservingExpectationForObject:conversation keyPath:@"isPendingConnectionConversation" expectedValue:nil];
    
    // when
    ZMConnection *connection2 = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection1.status = ZMConnectionStatusAccepted;
    conversation.connection = connection2;
    
    // then
    XCTAssertEqualObjects(conversation.connection, connection2);
    XCTAssertFalse(conversation.isPendingConnectionConversation);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}

@end // connections


@implementation ZMConversationTests (DisplayName)


- (void)testThatSettingTheUseDefinedNameDoesNotMakeTheNormalizedUserDefinedNameIsLocallyModified;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.userDefinedName = @"Naïve piñata talk";
    [self.uiMOC saveOrRollback];
    [conversation resetLocallyModifiedKeys:[conversation keysThatHaveLocalModifications]];
    [self.uiMOC saveOrRollback];
    XCTAssertFalse([[conversation keysThatHaveLocalModifications] containsObject:ZMConversationUserDefinedNameKey]);
    XCTAssertFalse([[conversation keysThatHaveLocalModifications] containsObject:@"normalizedUserDefinedName"]);
    
    // when
    conversation.userDefinedName = @"Fancy New Name";
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertTrue([[conversation keysThatHaveLocalModifications] containsObject:ZMConversationUserDefinedNameKey]);
    XCTAssertFalse([[conversation keysThatHaveLocalModifications] containsObject:@"normalizedUserDefinedName"]);
}

- (void)testThatTheDisplayNameIsTheConnectedUserNameWhenItIsAPendingConnectionConversation;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user = [self createUser];
    user.name = @"Foo Bar Baz";
    conversation.conversationType = ZMConversationTypeConnection;
    conversation.userDefinedName = @"JKAHJKADSKHJ";
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.conversation = conversation;
    connection.status = ZMConnectionStatusPending;
    connection.to = user;
    [self.uiMOC saveOrRollback];
    
    // when
    NSString *name = [conversation.displayName copy];
    
    // then
    XCTAssertEqualObjects(name, user.name);
}

- (void)testThatTheDisplayNameIsTheConnectedUserNameWhenItIsASentConnectionConversation;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user = [self createUser];
    user.name = @"Foo Bar Baz";
    conversation.conversationType = ZMConversationTypeConnection;
    conversation.userDefinedName = @"JKAHJKADSKHJ";
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.conversation = conversation;
    connection.status = ZMConnectionStatusSent;
    connection.to = user;
    [self.uiMOC saveOrRollback];
    
    // when
    NSString *name = [conversation.displayName copy];
    
    // then
    XCTAssertEqualObjects(name, user.name);
}

- (void)testThatTheDisplayNameIsTheConnectedUserNameWhenItIsAOneOnOneConversationWithoutOtherActiveParticipants
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user = [self createUser];
    user.name = @"Foo Bar Baz";
    conversation.conversationType = ZMConversationTypeOneOnOne;
    conversation.userDefinedName = @"JKAHJKADSKHJ";
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    connection.conversation = conversation;
    connection.status = ZMConnectionStatusPending;
    connection.to = user;
    [self.uiMOC saveOrRollback];

    // when
    NSString *name = [conversation.displayName copy];
    
    // then
    XCTAssertEqualObjects(name, user.name);
}

- (void)testThatTheDisplayNameIsTheUserDefinedNameWhenSetInAGroupConversation
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user = [self createUser];
    user.name = @"Foo 1";
    [conversation.mutableOtherActiveParticipants addObject:user];
    [conversation.mutableOtherActiveParticipants addObject:[ZMUser selfUserInContext:self.uiMOC]];
    conversation.conversationType = ZMConversationTypeGroup;
    [self.uiMOC saveOrRollback];
    NSString *name = @"My Conversation";
    
    // when
    conversation.userDefinedName = name;
    
    // then
    XCTAssertEqualObjects(conversation.displayName, name);
}

- (void)testThatTheDisplayNameIsTheUserDefinedNameWhenThereAreNoOtherParticipants
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    selfUser.name = @"Me Myself";
    [self.uiMOC saveOrRollback];
    
    // when
    conversation.userDefinedName = @"Egg";
    
    // then
    XCTAssertEqualObjects(conversation.displayName, @"Egg");
}


- (void)testThatTheDisplayNameIsTheOtherUsersNameWhenTheUserDefinedNameIsNotSet
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    user1.name = @"Foo 1";
    user2.name = @"Bar 2";
    selfUser.name = @"Me Myself";
    [conversation.mutableOtherActiveParticipants addObject:user1];
    [conversation.mutableOtherActiveParticipants addObject:user2];
    [conversation.mutableOtherActiveParticipants addObject:[ZMUser selfUserInContext:self.uiMOC]];
    [self.uiMOC saveOrRollback];
    [self updateDisplayNameGeneratorWithUsers:@[user1, user2, selfUser]];
    
    NSString *expected = @"Foo, Bar";
    
    // when
    conversation.userDefinedName = nil;
    
    // then
    XCTAssertEqualObjects(conversation.displayName, expected);
}

- (void)testThatTheDisplayNameBasedOnUserNamesDoesNotIncludeUsersWithAnEmptyName
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user3 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user4 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    user1.name = @"";
    user2.name = @"Bar 2";
    user3.name = nil;
    user4.name = @"Baz 4";
    selfUser.name = @"Me Myself";
    [conversation.mutableOtherActiveParticipants addObjectsFromArray:@[user1, user2, user3, user4]];
    [conversation.mutableOtherActiveParticipants addObject:[ZMUser selfUserInContext:self.uiMOC]];
    [self.uiMOC saveOrRollback];
    
    NSString *expected = @"Bar, Baz";
    
    // when
    conversation.userDefinedName = nil;
    [self updateDisplayNameGeneratorWithUsers:@[user1, user2, user3, user4, selfUser]];
    
    // then
    XCTAssertEqualObjects(conversation.displayName, expected);
}


- (void)testThatTheAttributedDisplayNameBasedOnUserNamesIncludesInactive
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user3 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user4 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user1.name = @"User 1bar";
    user2.name = @"User 2bar";
    user3.name = @"User 3bar";
    user4.name = @"User 4bar";
    [conversation.mutableOtherActiveParticipants addObjectsFromArray:@[user1, user2]];
    [conversation.mutableOtherInactiveParticipants addObjectsFromArray:@[user3, user4]];
    [self.uiMOC saveOrRollback];
    NSString *expected = @"User 1, User 2, User 3, User 4";
    
    // when
    conversation.userDefinedName = nil;
    [self updateDisplayNameGeneratorWithUsers:@[user1, user2, user3, user4]];
    
    // then
    XCTAssertEqualObjects(conversation.attributedDisplayName.string, expected);
}

- (void)testThatItSetsZMIsDimmedAttributeOnInactiveUsers
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.userDefinedName = nil;
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user3 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user4 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user1.name = @"User 1";
    user2.name = @"User 2";
    user3.name = @"User 3";
    user4.name = @"User 4";
    [conversation.mutableOtherActiveParticipants addObjectsFromArray:@[user1, user2]];
    [conversation.mutableOtherInactiveParticipants addObjectsFromArray:@[user3, user4]];
    [self updateDisplayNameGeneratorWithUsers:@[user1, user2, user3, user4]];
    
    // expected
    NSString *expected = @"User 1, User 2, User 3, User 4";
    NSRange attributedRange = [expected rangeOfString:@"User 3, User 4"];
    NSRange normalRange = [expected rangeOfString:@"User 1, User 2, "];
    
    // when
    NSAttributedString *displayName = conversation.attributedDisplayName;
    
    //then
    NSDictionary *attributesActive = [displayName attributesAtIndex:0 effectiveRange:&normalRange];
    NSDictionary *attributesInactive = [displayName attributesAtIndex:attributedRange.location effectiveRange:&attributedRange];

    XCTAssertFalse([attributesActive[ZMIsDimmedKey] boolValue]);
    XCTAssertTrue([attributesInactive[ZMIsDimmedKey] boolValue]);
}

- (void)testThatTheDisplayNameIsTheOtherUser;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    conversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.connection.to = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.connection.to.name = @"User 1";
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertEqualObjects(conversation.displayName, @"User 1");
}

- (void)testThatTheDisplayNameForDeletedUserIsEllipsis;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    conversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.connection.to = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.connection.to.name = nil;
    [self.uiMOC saveOrRollback];
    
    // then
    XCTAssertEqualObjects(conversation.displayName, @"…");
}

- (void)testThatTheDisplayNameOnlyContainsTheActiveUsers;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.userDefinedName = nil;
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user3 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user4 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user1.name = @"User 1foo";
    user2.name = @"User 2foo";
    user3.name = @"User 3foo";
    user4.name = @"User 4foo";
    [self updateDisplayNameGeneratorWithUsers:@[user1, user2, user3, user4]];
    
    // when
    [conversation.mutableOtherActiveParticipants addObjectsFromArray:@[user1, user2]];
    [conversation.mutableOtherInactiveParticipants addObjectsFromArray:@[user3, user4]];
    
    // then
    XCTAssertEqualObjects(conversation.displayName, @"User 1, User 2");
}

- (void)testThatTheDisplayNameIsTheOtherUsersNameForAConnectionRequest;
{
    __block NSManagedObjectID *moid;
    [self.syncMOC performGroupedBlockAndWait:^{
        // when
        ZMUser *user = [ZMUser userWithRemoteID:NSUUID.createUUID createIfNeeded:YES inContext:self.syncMOC];
        user.name = @"Skyler Saša";
        user.needsToBeUpdatedFromBackend = YES;
        ZMConnection *connection = [ZMConnection insertNewSentConnectionToUser:user];
        connection.message = @"Hey, there!";
        ZMConversation *conversation = connection.conversation;
        XCTAssert([self.syncMOC saveOrRollback]);
        moid = conversation.objectID;
    }];
    ZMConversation *conversation = (id) [self.uiMOC objectWithID:moid];
    
    // then
    XCTAssertNotNil(conversation);
    XCTAssertEqualObjects(conversation.displayName, @"Skyler Saša");
}

- (void)testThatTheDisplayNameIsEllipsisWhenTheOtherUsersNameForAConnectionRequestIsEmpty;
{
    __block NSManagedObjectID *moid;
    [self.syncMOC performGroupedBlockAndWait:^{
        // when
        ZMUser *user = [ZMUser userWithRemoteID:NSUUID.createUUID createIfNeeded:YES inContext:self.syncMOC];
        user.name = @"";
        user.needsToBeUpdatedFromBackend = YES;
        ZMConnection *connection = [ZMConnection insertNewSentConnectionToUser:user];
        connection.message = @"Hey, there!";
        ZMConversation *conversation = connection.conversation;
        XCTAssert([self.syncMOC saveOrRollback]);
        moid = conversation.objectID;
    }];
    ZMConversation *conversation = (id) [self.uiMOC objectWithID:moid];
    
    // then
    XCTAssertNotNil(conversation);
    XCTAssertEqualObjects(conversation.displayName, @"…");
}

- (void)testThatTheDisplayNameIsAlwaysTheOtherparticipantsNameInOneOnOneConversations
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    user.name = @"Hans Maisenkaiser";
    selfUser.name = @"Jan Schneidezahn";
    [conversation.mutableOtherActiveParticipants addObject:user];
    [conversation.mutableOtherActiveParticipants addObject:selfUser];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    [self.uiMOC saveOrRollback];
    
    // when
    conversation.userDefinedName = @"FAIL FAIL FAIL";
    
    // then
    XCTAssertEqualObjects(conversation.displayName, user.name);
}

- (void)testThatItSetsNormalizedNameWhenSettingName
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.userDefinedName = @"Naïve piñata talk";
    [self.uiMOC saveOrRollback];
    
    // when
    NSString *normalizedName = conversation.normalizedUserDefinedName;
    
    // then
    XCTAssertEqualObjects(normalizedName, @"naive pinata talk");
    
}

@end



@implementation ZMConversationTests (ReadingLastReadMessage)


- (void)testThatItReturnsTheLastReadMessageIfWeHaveItLocally;
{
    // given
    NSDate *serverTimeStamp = [NSDate date];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    conversation.lastReadServerTimeStamp = serverTimeStamp;
    ZMTextMessage *message = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    message.serverTimestamp = serverTimeStamp;
    [conversation.mutableMessages addObject:message];
    
    // then
    XCTAssertEqual(conversation.lastReadMessage, message);
}


- (void)testThatItReturnsThePreviousMessageIfTheLastReadServerTimeStampIsNoMessage
{
    // event ID
    //   1.1     message A
    //   2.1     message B     <--- last read message should be this
    //   3.1     (no message)  <--- last read event ID
    //   4.1     message C
    //   5.1     message D
    
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        [self timeStampForSortAppendMessageToConversation:conversation];
        [self timeStampForSortAppendMessageToConversation:conversation];
        NSDate *noMessageTimeStamp = [conversation.lastServerTimeStamp dateByAddingTimeInterval:5];
        conversation.lastServerTimeStamp = noMessageTimeStamp;
        [self timeStampForSortAppendMessageToConversation:conversation];
        [self timeStampForSortAppendMessageToConversation:conversation];
        
        ZMMessage *expectedLastReadMessage = conversation.messages[1];
        
        // when
        conversation.lastReadServerTimeStamp = noMessageTimeStamp;
        
        // then
        XCTAssertEqual(conversation.lastReadMessage, expectedLastReadMessage,
                       @"%@ == %@", conversation.lastReadMessage.serverTimestamp, expectedLastReadMessage.serverTimestamp);
    }];
}


- (void)testThatItReturnsTheLastMessageIfTheLastReadServerTimeStampIsBiggerThanTheLastMessageServerTimeStamp
{
    // event ID
    //   1.1     message A
    //   2.1     message B
    //  -------------------
    //   					last read event ID is 3.1

    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        [self timeStampForSortAppendMessageToConversation:conversation];
        [self timeStampForSortAppendMessageToConversation:conversation];
        NSDate *noMessageTimeStamp = [conversation.lastServerTimeStamp dateByAddingTimeInterval:5];
        conversation.lastServerTimeStamp = noMessageTimeStamp;
        ZMMessage *expectedLastReadMessage = conversation.messages[1];
        
        // when
        conversation.lastReadServerTimeStamp = noMessageTimeStamp;
        
        // then
        XCTAssertEqual(conversation.lastReadMessage, expectedLastReadMessage,
                       @"%@ == %@", conversation.lastReadMessage.serverTimestamp, expectedLastReadMessage.serverTimestamp);
    }];
    
}


- (void)testThatItReturnsNilIfTheLastReadEventIsOlderThanTheFirstMessageServerTimeStamp
{
    // event ID
    //   					last read event ID is 1.1
    //  -------------------
    //   2.1     message A
    //   3.1     message B

    
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSDate *noMessageTimeStamp = [NSDate date];
        conversation.lastServerTimeStamp = noMessageTimeStamp;
        [self timeStampForSortAppendMessageToConversation:conversation];
        [self timeStampForSortAppendMessageToConversation:conversation];
        
        // when
        conversation.lastReadServerTimeStamp = noMessageTimeStamp;
        
        // then
        XCTAssertNil(conversation.lastReadMessage);
    }];
}

- (ZMMessage *)insertMessageForEventID:(ZMEventID *)eventID intoConversation:(ZMConversation *)conversation
{
    ZMTextMessage *message = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    message.eventID = eventID;
    message.serverTimestamp = [NSDate date];
    message.text = [NSString stringWithFormat:@"Text %@", eventID];
    [conversation.mutableMessages addObject:message];
    return message;
}

- (ZMConversation *)createConversationWithManyMessages;
{
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    
    for (size_t i = 1; i < 5000; ++i) {
        ZMEventID *eventID = [ZMEventID eventIDWithMajor:i minor:self.createEventID.minor];
        [self insertMessageForEventID:eventID intoConversation:conversation];
    }
    
    ZMMessage *lastMessage = conversation.messages.lastObject;
    conversation.lastEventID = lastMessage.eventID;
    conversation.lastServerTimeStamp = lastMessage.serverTimestamp;
    return conversation;
}

- (void)testPerformanceOfLastReadMessage_IsOneOfLast;
{
    // given
    ZMConversation *conversation = [self createConversationWithManyMessages];
    XCTAssert([self.uiMOC saveOrRollback]);
    NSMutableArray *timeStamps = [NSMutableArray array];
    NSUInteger const count = 10;
    for (size_t i = 0; i < count; ++i) {
        ZMMessage *message = conversation.messages[conversation.messages.count - 1 - i * 10];
        [timeStamps addObject:message.serverTimestamp];
    }
    
    // measure:
    [self measureBlock:^{
        for (size_t i = 0; i < count; ++i) {
            conversation.lastReadServerTimeStamp = timeStamps[i];
            XCTAssertNotNil(conversation.lastReadMessage);
        }
    }];
}

- (void)testPerformanceOfLastReadMessage_IsOneOfFirst;
{
    // given
    ZMConversation *conversation = [self createConversationWithManyMessages];
    XCTAssert([self.uiMOC saveOrRollback]);
    NSMutableArray *timeStamps = [NSMutableArray array];
    NSUInteger const count = 10;
    for (size_t i = 0; i < count; ++i) {
        ZMMessage *message = conversation.messages[i * 10];
        [timeStamps addObject:message.serverTimestamp];
    }
    
    // measure:
    [self measureBlock:^{
        for (size_t i = 0; i < count; ++i) {
            conversation.lastReadServerTimeStamp = timeStamps[i];
            XCTAssertNotNil(conversation.lastReadMessage);
        }
        [NSThread sleepForTimeInterval:0.00145];
    }];
}

- (void)testPerformanceOfLastReadMessage_Middle;
{
    // given
    ZMConversation *conversation = [self createConversationWithManyMessages];
    XCTAssert([self.uiMOC saveOrRollback]);
    NSMutableArray *timeStamps = [NSMutableArray array];
    NSUInteger const count = 10;
    for (size_t i = 0; i < count; ++i) {
        ZMMessage *message = conversation.messages[(conversation.messages.count - count * 10) / 2 + i * 10];
        [timeStamps addObject:message.serverTimestamp];
    }
    
    // measure:
    [self measureBlock:^{
        for (size_t i = 0; i < count; ++i) {
            conversation.lastReadServerTimeStamp = timeStamps[i];
            XCTAssertNotNil(conversation.lastReadMessage);
        }
    }];
}

@end


@implementation ZMConversationTests (SettingLastReadMessage)

- (void)testThatItSetsTheLastReadServerTimeStampToTheLastReadMessageInTheVisibleRange;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastReadEventIDSaveDelay = 0.1;
    ZMMessage *message = [self insertDownloadedMessageForEventID:[self createEventID] intoConversation:conversation];
    for (int i = 0; i < 10; ++i) {
        message = [self insertDownloadedMessageAfterMessage:message intoConversation:conversation];
    }
    
    // when
    [conversation setVisibleWindowFromMessage:conversation.messages[2] toMessage:conversation.messages[4]];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(conversation.lastReadServerTimeStamp, ((ZMMessage *) conversation.messages[4]).serverTimestamp);
}

- (void)testThatItDoesNotUpdateTheLastReadMessageToAnOlderMessage;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastReadEventIDSaveDelay = 0.1;
    
    ZMMessage *message = [self insertDownloadedMessageForEventID:[self createEventID] intoConversation:conversation];
    for (int i = 0; i < 10; ++i) {
        message = [self insertDownloadedMessageAfterMessage:message intoConversation:conversation];
    }
    
    NSDate *originalLastReadTimeStamp = ((ZMMessage *)conversation.messages[9]).serverTimestamp;
    conversation.lastReadServerTimeStamp = originalLastReadTimeStamp;
    
    // when
    [conversation setVisibleWindowFromMessage:conversation.messages[2] toMessage:conversation.messages[4]];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqualObjects(conversation.lastReadServerTimeStamp, originalLastReadTimeStamp);
}

- (void)testThatItDoesNotUpdateTheLastReadMessageIfTheVisibleWindowIsNil;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastReadEventIDSaveDelay = 0.1;
    
    ZMMessage *message = [self insertDownloadedMessageForEventID:[self createEventID] intoConversation:conversation];
    for (int i = 0; i < 10; ++i) {
        message = [self insertDownloadedMessageAfterMessage:message intoConversation:conversation];
    }
    
    NSDate *originalLastReadTimeStamp = ((ZMMessage *)conversation.messages[9]).serverTimestamp;
    conversation.lastReadServerTimeStamp = originalLastReadTimeStamp;

    // when
    [conversation setVisibleWindowFromMessage:nil toMessage:nil];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqualObjects(conversation.lastReadServerTimeStamp, originalLastReadTimeStamp);
}



- (void)testThatItSetsTheLastReadServerTimeStampToTheLastEventAfterTheLastMessage
{
    //  "downloaded"
    //  event 1.1    message       <-\
    //  event 2.1    message         |--- visible range
    //  event 3.1    message         |
    //  event 4.1    message       <-/
    //  event 5.1    (no message)
    //  event 6.1    (no message)  <--- this should be the last read event ID
    //
    
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastReadEventIDSaveDelay = 0.1;
    
    ZMMessage *message = [self insertDownloadedMessageForEventID:[self createEventID] intoConversation:conversation];
    for (int i = 0; i < 3; ++i) {
        message = [self insertDownloadedMessageAfterMessage:message intoConversation:conversation];
    }
    NSDate *serverTimeStamp = message.serverTimestamp;
    for (int i = 0; i < 2; ++i) {
        serverTimeStamp = [serverTimeStamp dateByAddingTimeInterval:1];
        conversation.lastServerTimeStamp = serverTimeStamp;
    }
    
    // when
    [conversation setVisibleWindowFromMessage:conversation.messages.firstObject toMessage:conversation.messages.lastObject];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqualObjects(conversation.lastReadServerTimeStamp, serverTimeStamp);
}

@end

@implementation ZMConversationTests (Participants)

- (void)testThatAddingParticipantsSetsTheModifiedKeys
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    XCTAssertTrue([self.uiMOC saveOrRollback]);
    
    // when
    [conversation addParticipant:user1];
    XCTAssertTrue([self.uiMOC saveOrRollback]);
    
    // then
    XCTAssertEqualObjects(conversation.keysThatHaveLocalModifications, [NSSet setWithObject:ZMConversationUnsyncedActiveParticipantsKey]);
}

- (void)testThatRemovingParticipantsSetsTheModifiedKeys
{
    // given
    NSUUID *convID = [NSUUID createUUID];
    NSUUID *userID = [NSUUID createUUID];
    [self.syncMOC performBlockAndWait:^{
    
        
        
        ZMConversation *conversation = [ZMConversation conversationWithRemoteID:convID createIfNeeded:YES inContext:self.syncMOC];
        XCTAssertNotNil(conversation);
        NSDictionary *payload = @{
                                  @"creator" : userID.transportString,
                                  @"id" : convID.transportString,
                                  @"last_event" : @"10.aabb",
                                  @"last_event_time" : @"2014-08-08T18:08:17.723Z",
                                  @"type" : @0,
                                  @"name" : @"Boo",
                                  @"members" :
                                      @{
                                          @"others" : @[
                                                  @{
                                                      @"id" : userID.transportString,
                                                      @"status" : @0
                                                      }
                                                  ],
                                          @"self" : @{
                                                  @"archived" : [NSNull null],
                                                  @"id" : @"90c74fe0-cef7-446a-affb-6cba0e75d5da",
                                                  @"last_read" : @"5a4.800122000a64d6bf",
                                                  @"muted" : [NSNull null],
                                                  @"muted_time" : [NSNull null],
                                                  @"status" : @0,
                                                  @"status_ref" : @"0.0",
                                                  @"status_time" : @"2014-06-18T12:08:44.428Z"
                                                  }
                                          },
                                  };
        
        [conversation updateWithTransportData:payload];
        [self.syncMOC saveOrRollback];
    }];
    
    ZMConversation *conversation = [ZMConversation conversationWithRemoteID:convID createIfNeeded:NO inContext:self.uiMOC];
    XCTAssertNotNil(conversation);
    ZMUser *user = conversation.otherActiveParticipants.firstObject;
    XCTAssertNotNil(user);
    
    // when
    [conversation removeParticipant:user];
    XCTAssertTrue([self.uiMOC saveOrRollback]);
    
    // then
    XCTAssertEqualObjects(conversation.keysThatHaveLocalModifications, [NSSet setWithObject:ZMConversationUnsyncedInactiveParticipantsKey]);
}

- (void)testThatItDoesNotAddTheSelfUserToServerSyncedActiveParticipants
{
    // given
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    [conversation synchronizeAddedUser:selfUser];
    
    // then
    XCTAssertFalse([conversation.unsyncedActiveParticipants containsObject:selfUser]);
    XCTAssertFalse([conversation.unsyncedInactiveParticipants containsObject:selfUser]);
}


- (void)testThatItRecalculatesActiveParticipantsWhenOtherActiveParticipantsKeyChanges
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.isSelfAnActiveMember = YES;

    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    [conversation addParticipant:user1];
    [conversation addParticipant:user2];
    
    XCTAssertTrue(conversation.isSelfAnActiveMember);
    XCTAssertEqual(conversation.otherActiveParticipants.count, 2u);
    XCTAssertEqual(conversation.activeParticipants.count, 3u);
    
    // expect
    [self keyValueObservingExpectationForObject:conversation keyPath:@"activeParticipants" expectedValue:nil];
    
    // when

    [conversation removeParticipant:user2];
    
    // then
    XCTAssertTrue(conversation.isSelfAnActiveMember);
    XCTAssertEqual(conversation.otherActiveParticipants.count, 1u);
    XCTAssertEqual(conversation.activeParticipants.count, 2u);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatItRecalculatesActiveParticipantsWhenIsSelfActiveUserKeyChanges
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.isSelfAnActiveMember = YES;
    
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    [conversation addParticipant:user1];
    [conversation addParticipant:user2];
    
    XCTAssertTrue(conversation.isSelfAnActiveMember);
    XCTAssertEqual(conversation.otherActiveParticipants.count, 2u);
    XCTAssertEqual(conversation.activeParticipants.count, 3u);
    
    // expect
    [self keyValueObservingExpectationForObject:conversation keyPath:@"activeParticipants" expectedValue:nil];
    
    // when
    conversation.isSelfAnActiveMember = NO;
    
    // then
    XCTAssertFalse(conversation.isSelfAnActiveMember);
    XCTAssertEqual(conversation.otherActiveParticipants.count, 2u);
    XCTAssertEqual(conversation.activeParticipants.count, 2u);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}


- (void)testThatItRecalculatesInactiveParticipantsWhenIsSelfActiveUserKeyChanges
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.isSelfAnActiveMember = YES;
    
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    [conversation addParticipant:user1];
    [conversation addParticipant:user2];
    
    XCTAssertTrue(conversation.isSelfAnActiveMember);
    XCTAssertEqual(conversation.otherInactiveParticipants.count, 0u);
    XCTAssertEqual(conversation.inactiveParticipants.count, 0u);
    
    // expect
    [self keyValueObservingExpectationForObject:conversation keyPath:@"inactiveParticipants" expectedValue:nil];
    
    // when
    conversation.isSelfAnActiveMember = NO;
    
    // then
    XCTAssertFalse(conversation.isSelfAnActiveMember);
    XCTAssertEqual(conversation.otherInactiveParticipants.count, 0u);
    XCTAssertEqual(conversation.inactiveParticipants.count, 1u);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatItRecalculatesInactiveParticipantsWhenOtherActiveParticipantsChanges
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.isSelfAnActiveMember = YES;
    
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    [conversation addParticipant:user1];
    [conversation addParticipant:user2];
    
    XCTAssertTrue(conversation.isSelfAnActiveMember);
    XCTAssertEqual(conversation.otherInactiveParticipants.count, 0u);
    XCTAssertEqual(conversation.inactiveParticipants.count, 0u);
    
    // expect
    [self keyValueObservingExpectationForObject:conversation keyPath:@"inactiveParticipants" expectedValue:nil];
    
    // when
    [conversation removeParticipant:user1];
    
    // then
    XCTAssertTrue(conversation.isSelfAnActiveMember);
    XCTAssertEqual(conversation.otherInactiveParticipants.count, 1u);
    XCTAssertEqual(conversation.inactiveParticipants.count, 1u);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}


- (void)testThatItResetsModificationsToActiveParticipants
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *newUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    [conversation addParticipant:user1];
    [conversation addParticipant:user2];
    
    [conversation synchronizeAddedUser:user1];
    [conversation synchronizeAddedUser:user2];
    
    
    XCTAssertTrue(conversation.isSelfAnActiveMember);
    XCTAssertEqual(conversation.activeParticipants.count, 3u);
    [conversation setLocallyModifiedKeys:[NSSet setWithObject:@"unsyncedActiveParticipants"]];
    
    // when
    [conversation addParticipant:newUser];
    XCTAssertEqual(conversation.unsyncedActiveParticipants.count, 1u);
    [conversation resetParticipantsBackToLastServerSync];
    
    // then
    XCTAssertEqual(conversation.activeParticipants.count, 3u);
    XCTAssertTrue([conversation.activeParticipants containsObject:user1]);
    XCTAssertTrue([conversation.activeParticipants containsObject:user2]);
    XCTAssertFalse([conversation.activeParticipants containsObject:newUser]);
    
    XCTAssertEqual(conversation.unsyncedActiveParticipants.count, 0u);
    XCTAssertFalse([conversation.keysThatHaveLocalModifications containsObject:@"unsyncedActiveParticipants"]);
}



- (void)testThatItResetsModificationsToInactiveParticipants
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *newUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    [conversation addParticipant:user1];
    [conversation addParticipant:user2];
    [conversation addParticipant:newUser];
    
    [conversation synchronizeAddedUser:user1];
    [conversation synchronizeAddedUser:user2];
    [conversation synchronizeAddedUser:newUser];
    
    
    XCTAssertTrue(conversation.isSelfAnActiveMember);
    XCTAssertEqual(conversation.activeParticipants.count, 4u);
    
    // when
    [conversation removeParticipant:newUser];
    [conversation setLocallyModifiedKeys:[NSSet setWithObject:@"unsyncedInactiveParticipants"]];
    XCTAssertEqual(conversation.unsyncedInactiveParticipants.count, 1u);
    
    [conversation resetParticipantsBackToLastServerSync];
    
    // then
    XCTAssertEqual(conversation.activeParticipants.count, 4u);
    XCTAssertTrue([conversation.activeParticipants containsObject:user1]);
    XCTAssertTrue([conversation.activeParticipants containsObject:user2]);
    XCTAssertTrue([conversation.activeParticipants containsObject:newUser]);
    
    XCTAssertEqual(conversation.unsyncedInactiveParticipants.count, 0u);
    XCTAssertFalse([conversation.keysThatHaveLocalModifications containsObject:@"unsyncedInactiveParticipants"]);
}


@end

@implementation ZMConversationTests (KeyValueObserving)

- (void)testThatItRecalculatesHasDraftMessageWhenDraftMessageTextChanges
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.draftMessageText = @"This is a test";
    
    XCTAssertTrue(conversation.hasDraftMessageText);
    
    // expect
    [self keyValueObservingExpectationForObject:conversation keyPath:@"hasDraftMessageText" expectedValue:nil];
    
    // when
    conversation.draftMessageText = @"";
    
    // then
    XCTAssertFalse(conversation.hasDraftMessageText);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}


- (void)testThatItRecalculatesLastReadMessageWhenLastReadServerTimeStampChanges
{
    // given
    ZMTextMessage *message1 = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    message1.serverTimestamp = [NSDate date];
    
    ZMTextMessage *message2 = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    message2.serverTimestamp = [NSDate date];
    
    ZMTextMessage *message3 = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    message3.serverTimestamp = [NSDate date];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    [conversation.mutableMessages addObject:message1];
    [conversation.mutableMessages addObject:message2];
    [conversation.mutableMessages addObject:message3];

    conversation.lastReadServerTimeStamp = message2.serverTimestamp;
    
    XCTAssertEqualObjects(conversation.lastReadMessage, message2);
    
    // expect
    [self keyValueObservingExpectationForObject:conversation keyPath:@"lastReadMessage" expectedValue:nil];
    
    // when
    conversation.lastReadServerTimeStamp = message3.serverTimestamp;

    // then
    XCTAssertEqualObjects(conversation.lastReadMessage, message3);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}


- (void)testThatItRecalculatesLastReadMessageWhenMessagesChanges
{
    // given
    ZMTextMessage *message1 = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    message1.serverTimestamp = [NSDate date];
    
    ZMTextMessage *message2 = [ZMTextMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    message2.serverTimestamp = [NSDate date];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    [conversation.mutableMessages addObject:message1];
    
    conversation.lastReadServerTimeStamp = message2.serverTimestamp;
    
    
    XCTAssertEqualObjects(conversation.lastReadMessage, message1);
    
    // expect
    [self keyValueObservingExpectationForObject:conversation keyPath:@"lastReadMessage" expectedValue:nil];
    
    // when
    [conversation.mutableMessages addObject:message2];
    
    // then
    XCTAssertEqualObjects(conversation.lastReadMessage, message2);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}


- (void)testThatTheSelfConversationHasTheSameRemoteIdentifierAsTheSelfUser
{
    // given
    NSUUID *selfUserID = [NSUUID createUUID];
    
    [self.syncMOC performBlockAndWait:^{
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.remoteIdentifier = selfUserID;
    }];
    
    // when
    NSUUID *selfConversationID = [ZMConversation selfConversationIdentifierInContext:self.syncMOC];
    
    // then
    XCTAssertEqualObjects(selfConversationID, selfUserID);
}

@end



@implementation ZMConversationTests (Clearing)

- (void)testThatGettingRemovedIsNotMovingConversationToClearedList
{
    // given
    ZMUser *user0 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user0.remoteIdentifier = [NSUUID createUUID];
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user1.remoteIdentifier = [NSUUID createUUID];
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    
    [self.uiMOC saveOrRollback];
    NSArray *users = @[user0, user1, selfUser];
    ZMConversation *conversation = [self insertConversationWithParticipants:users callParticipants:users callStateNeedsToBeUpdatedFromBackend:NO];
    ZMEventID *clearedEventID = self.createEventID;
    ZMMessage *message = [conversation appendMessagesWithText:@"0"].firstObject;
    message.eventID = clearedEventID;
    
    ZMConversationList *activeList = [ZMConversationList conversationsInUserSession:self.mockUserSessionWithUIMOC];
    ZMConversationList *archivedList = [ZMConversationList archivedConversationsInUserSession:self.mockUserSessionWithUIMOC];
    ZMConversationList *clearedList = [ZMConversationList clearedConversationsInUserSession:self.mockUserSessionWithUIMOC];
    
    // when
    [conversation internalRemoveParticipant:selfUser sender:user0];
    
    // then
    XCTAssertNil(conversation.clearedEventID);
    XCTAssertTrue([activeList predicateMatchesConversation:conversation]);
    XCTAssertFalse([archivedList predicateMatchesConversation:conversation]);
    XCTAssertFalse([clearedList predicateMatchesConversation:conversation]);
}


- (void)testThatClearingMessageHistoryDeletesAllMessages
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMEventID *clearedEventID = [self createEventID];
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.lastEventID = clearedEventID;
        
        ZMMessage *message1 = [conversation appendMessagesWithText:@"B"].firstObject;
        [message1 expire];
        
        ZMMessage *message2 = [conversation appendMessagesWithText:@"A"].firstObject;
        message2.eventID = clearedEventID;
        
        ZMMessage *message3 = [conversation appendMessagesWithText:@"B"].firstObject;
        [message3 expire];
        conversation.lastServerTimeStamp = message3.serverTimestamp;
        
        // when
        conversation.clearedTimeStamp = conversation.lastServerTimeStamp;
        
        // then
        for (ZMMessage *message in conversation.messages) {
            XCTAssertTrue(message.isDeleted);
        }
    }];
}

- (void)testThatSettingClearedTimeStampDueToRemoteChangeDoesNotDeleteUnsentMessages
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        
        ZMMessage *message1 = [conversation appendMessagesWithText:@"A"].firstObject;
        [message1 expire];
        
        NSDate *clearedTimestamp = [NSDate date];
        ZMMessage *message2 = [conversation appendMessagesWithText:@"B"].firstObject;
        message2.serverTimestamp = clearedTimestamp;
        conversation.lastServerTimeStamp = clearedTimestamp;
        
        [self spinMainQueueWithTimeout:1];
        
        ZMMessage *message3 = [conversation appendMessagesWithText:@"C"].firstObject;
        [message3 expire];
        
        // when
        conversation.clearedTimeStamp = clearedTimestamp;
        
        // then
        XCTAssertTrue(message1.isDeleted);
        XCTAssertTrue(message2.isDeleted);
        XCTAssertFalse(message3.isDeleted);

    }];
}

- (void)testThatSettingClearedTimeStampDueToRemoteChangeOnlyDeletesOlderMessages_EventIsNotMessage
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        
        ZMMessage *message1 = [conversation appendMessagesWithText:@"A"].firstObject;
        message1.serverTimestamp = [NSDate date];
        
        NSDate *clearedTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:10];
        
        ZMMessage *message2 = [conversation appendMessagesWithText:@"B"].firstObject;
        message2.serverTimestamp = [clearedTimestamp dateByAddingTimeInterval:10];
        
        // when
        conversation.clearedTimeStamp = clearedTimestamp;
        
        // then
        XCTAssertTrue(message1.isDeleted);
        XCTAssertFalse(message2.isDeleted);
    }];
}

- (void)testThatClearingMessageHistorySetsLastReadServerTimeStampToLastServerTimeStamp
{
    // given
    NSDate *clearedTimeStamp = [NSDate date];

    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastServerTimeStamp = clearedTimeStamp;

    ZMMessage *message1 = [conversation appendMessagesWithText:@"B"].firstObject;
    message1.serverTimestamp = clearedTimeStamp;
    
    XCTAssertNil(conversation.lastReadServerTimeStamp);
    
    // when
    [conversation clearMessageHistory];
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(conversation.lastReadServerTimeStamp, clearedTimeStamp);
}

- (void)testThatClearingMessageHistorySetsClearedTimeStampToLastServerTimeStamp
{
    // given
    NSDate *clearedTimeStamp = [NSDate date];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastServerTimeStamp = clearedTimeStamp;
    ZMMessage *message1 = [conversation appendMessagesWithText:@"B"].firstObject;
    message1.serverTimestamp = clearedTimeStamp;
    
    XCTAssertNil(conversation.clearedTimeStamp);
    
    // when
    [conversation clearMessageHistory];
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(conversation.clearedTimeStamp, clearedTimeStamp);
}


- (void)testThatRemovingOthersInConversationDoesntClearsMessages
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    [self.uiMOC saveOrRollback];
    NSArray *users = @[user1, user2, selfUser];
    ZMConversation *conversation = [self insertConversationWithParticipants:users callParticipants:users callStateNeedsToBeUpdatedFromBackend:NO];
    
    ZMMessage *message1 = [conversation appendMessagesWithText:@"1"].firstObject;
    message1.eventID = self.createEventID;
    message1.serverTimestamp = [NSDate date];
    
    ZMMessage *message2 = [conversation appendMessagesWithText:@"2"].firstObject;
    message2.eventID = self.createEventID;
    message2.serverTimestamp = [NSDate date];
    
    // when
    [conversation removeParticipant:user1];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertFalse(conversation.isArchived);
    XCTAssertNil(conversation.clearedEventID);
    XCTAssertNil(conversation.clearedTimeStamp);

    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:2];
    XCTAssertEqual(window.messages.count, 2u);
}


- (void)testThatClearingMessageHistorySetsIsArchived
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    XCTAssertFalse(conversation.isArchived);
    
    // when
    [conversation clearMessageHistory];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertTrue(conversation.isArchived);
}

- (void)testThatClearingMessageHistorySetsLastReadToLastEventID
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *message1 = [conversation appendMessagesWithText:@"B"].firstObject;
    message1.eventID = self.createEventID;
    conversation.lastEventID = message1.eventID;
    
    XCTAssertNil(conversation.lastReadEventID);
    
    // when
    [conversation clearMessageHistory];
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(conversation.lastReadEventID, conversation.lastEventID);
}

- (void)testThatClearingMessageHistorySetsClearedEventID
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *message1 = [conversation appendMessagesWithText:@"A"].firstObject;
    message1.eventID = self.createEventID;
    
    conversation.lastEventID = message1.eventID;
    conversation.lastServerTimeStamp = message1.serverTimestamp;
    
    // when
    [conversation clearMessageHistory];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    ZMConversationMessageWindow *window = [conversation conversationWindowWithSize:2];
    XCTAssertEqual(window.messages.count, 0u);
    
    XCTAssertEqual(conversation.clearedEventID, conversation.lastEventID);
}

- (void)testThatClearingMessageHistoryAddsAllPreviousEventsToDownloadedEvents
{
    // given
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *message1 = [conversation appendMessagesWithText:@"A"].firstObject;
    message1.eventID = [ZMEventID eventIDWithMajor:100 minor:0];
    
    conversation.lastEventID = message1.eventID;
    conversation.lastServerTimeStamp = message1.serverTimestamp;
    
    for (uint64_t i = 1; i <= 100; i++) {
        XCTAssertFalse([conversation.downloadedMessageIDs containsEvent:[ZMEventID eventIDWithMajor:i minor:0]]);
    }
    
    // when
    [conversation clearMessageHistory];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    for (uint64_t i = 1; i <= 100; i++) {
        XCTAssertTrue([conversation.downloadedMessageIDs containsEvent:[ZMEventID eventIDWithMajor:i minor:0]]);
    }
}

@end



@implementation ZMConversationTests (Archiving)

- (void)testThatLeavingAConversationMarksItAsArchived
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    selfUser.remoteIdentifier = NSUUID.createUUID;
    ZMUser *otherUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    [conversation.mutableOtherActiveParticipants addObject:otherUser];
    XCTAssertFalse(conversation.isArchived);
    
    // when
    [conversation removeParticipant:selfUser];
    WaitForAllGroupsToBeEmpty(0.5f);
    
    // then
    XCTAssertTrue(conversation.isArchived);
}

- (void)testThat_UnarchiveConversationFromEvent_unarchivesAConversationAndSetsLocallyModifications;
{

    // given
    ZMEventID* oldEventID = [ZMEventID eventIDWithMajor:3 minor:30];
    ZMEventID* newEventID = [ZMEventID eventIDWithMajor:10 minor:30];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    conversation.lastEventID = oldEventID;
    conversation.isArchived = YES;
    
    NSDictionary *payload = @{@"conversation" : conversation.remoteIdentifier.transportString,
                              @"time" : @"2014-06-18T12:36:51.755Z",
                              @"data" : @{},
                              @"from" : @"f76c1c7a-7278-4b70-9df7-eca7980f3a5d",
                              @"id" : newEventID.transportString,
                              @"type": @"conversation.message-add"
                              };
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:(id)payload  uuid:nil];
    
    // when
    [conversation unarchiveConversationFromEvent:event];
    
    // then
    XCTAssertFalse(conversation.isArchived);
    XCTAssertTrue([conversation.keysThatHaveLocalModifications containsObject:ZMConversationIsArchivedKey]);

}

- (void)testThat_UnarchiveConversationFromEvent_DoesNotUnarchive_AConversation_WhenItIsSilenced
{
    // given
    ZMEventID* oldEventID = [ZMEventID eventIDWithMajor:3 minor:30];
    ZMEventID* newEventID = [ZMEventID eventIDWithMajor:10 minor:30];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    conversation.lastEventID = oldEventID;
    conversation.isArchived = YES;
    conversation.isSilenced = YES;
    
    NSDictionary *payload = @{@"conversation" : conversation.remoteIdentifier.transportString,
                              @"time" : @"2014-06-18T12:36:51.755Z",
                              @"data" : @{},
                              @"from" : @"f76c1c7a-7278-4b70-9df7-eca7980f3a5d",
                              @"id" : newEventID.transportString,
                              @"type": @"conversation.message-add"
                              };
    ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:(id)payload  uuid:nil];
    
    // when
    [conversation unarchiveConversationFromEvent:event];
    
    // then
    XCTAssertTrue(conversation.isArchived);
    XCTAssertFalse([conversation.keysThatHaveLocalModifications containsObject:ZMConversationIsArchivedKey]);
    
}

- (void)testThatArchivingAConversationSetsTheArchivedEventID
{
    // given
    ZMEventID *archivedEventID = [ZMEventID eventIDWithMajor:8 minor:12];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastEventID = archivedEventID;
    
    // when
    conversation.isArchived = YES;
    
    // then
    XCTAssertEqualObjects(conversation.archivedEventID, archivedEventID);
}

- (void)testThatUnarchivingAConversationSetsTheArchivedEventIDToNil
{
    // given
    ZMEventID *archivedEventID = [ZMEventID eventIDWithMajor:8 minor:12];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastEventID = archivedEventID;
    conversation.isArchived = YES;
    XCTAssertNotNil(conversation.archivedEventID);
    
    // when
    conversation.isArchived = NO;
    
    // then
    XCTAssertNil(conversation.archivedEventID);
}

@end



@implementation ZMConversationTests (Knocking)

- (ZMConversation *)createConversationWithMessages;
{
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    for (NSString *text in @[@"A", @"B", @"C", @"D", @"E"]) {
        [conversation appendMessagesWithText:text];
    }
    XCTAssert([self.syncMOC saveOrRollback]);
    return conversation;
}

- (void)testThatItCanInsertAKnock;
{
    [self.syncMOC performBlockAndWait:^{
        
        // given
        ZMConversation *conversation = [self createConversationWithMessages];
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        
        // when
        id<ZMConversationMessage> knock = [conversation appendKnock];
        id<ZMConversationMessage> msg = [conversation.messages lastObject];
        
        // then
        XCTAssertEqual(knock, msg);
        XCTAssertNotNil(knock.knockMessageData);
        XCTAssertEqual(knock.sender, selfUser);
    }];

}

- (void)waitForInterval:(NSTimeInterval)interval {
    [self spinMainQueueWithTimeout:interval];
}

- (ZMKnockMessage *)appendKnockFromOtherUser:(ZMUser *)user inConversation:(ZMConversation *)conversation {
    ZMKnockMessage *knockMessage = [ZMKnockMessage insertNewObjectInManagedObjectContext:self.syncMOC];
    knockMessage.sender = user;
    knockMessage.visibleInConversation = conversation;
    return knockMessage;
}

@end


@implementation ZMConversationTests (ObjectIds)

- (ZMConversation *)insertConversationWithUnread:(BOOL)hasUnread
{
    NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:230000000];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    conversation.lastServerTimeStamp = messageDate;
    if(hasUnread) {
        ZMClientMessage *message = [ZMClientMessage insertNewObjectInManagedObjectContext:self.syncMOC];
        message.serverTimestamp = messageDate;
        conversation.lastReadServerTimeStamp = [messageDate dateByAddingTimeInterval:-1000];
        [conversation sortedAppendMessage:message];
        [conversation resortMessagesWithUpdatedMessage:message];
    }
    [self.syncMOC saveOrRollback];
    return conversation;
}

- (void)testThatItCountsConversationsWithUnreadMessagesAsUnread_IfItHasUnread
{
    // given
    XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);
    [self insertConversationWithUnread:YES];
    
    // when
    XCTAssert([self.syncMOC saveOrRollback]);
    
    //then
    XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 1lu);
}


- (void)testThatItDoesNotCountConversationsWithUnreadMessagesAsUnread_IfItHasNoUnread
{
    // give
    XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);
    [self insertConversationWithUnread:NO];
    
    // when
    XCTAssert([self.syncMOC saveOrRollback]);
    
    //then
    XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);
}

- (void)testThatItCountsConversationsWithPendingConnectionAsUnread
{
    // given
    XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);

    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
    connection.conversation = conversation;
    connection.status = ZMConnectionStatusPending;

    // when
    XCTAssert([self.syncMOC saveOrRollback]);
    
    // then
    XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 1lu);
}

- (void)testThatItDoesNotCountConversationsWithSentConnectionAsUnread
{
    // given
    XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);

    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
    connection.conversation = conversation;
    connection.status = ZMConnectionStatusSent;

    // when
    XCTAssert([self.syncMOC saveOrRollback]);
    
    // then
    XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);
}

- (void)testThatItDoesNotCountBlockedConversationsAsUnread
{
    // given
    XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);

    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
    connection.conversation = conversation;
    connection.status = ZMConnectionStatusBlocked;
 
    // when
    XCTAssert([self.syncMOC saveOrRollback]);
    
    // then
    XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);
}

- (void)testThatItDoesNotCountIgnoredConversationsAsUnread
{
    // given
    XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);

    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    ZMConnection *connection = [ZMConnection insertNewObjectInManagedObjectContext:self.syncMOC];
    connection.conversation = conversation;
    connection.status = ZMConnectionStatusIgnored;

    // when
    XCTAssert([self.syncMOC saveOrRollback]);
    
    // then
    XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);
}

- (void)testThatItDoesNotCountSilencedConversationsEvenWithUnreadContentAsUnread;
{
    // given
    XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);

    ZMConversation *conversation = [self insertConversationWithUnread:YES];
    conversation.isSilenced = YES;

    // when
    XCTAssert([self.syncMOC saveOrRollback]);
    
    // then
    XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);
}

- (void)testThatItCountsArchivedConversationsWithUnreadMessagesAsUnread;
{
    // given
    XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);

    ZMConversation *conversation = [self insertConversationWithUnread:YES];
    conversation.isArchived = YES;

    // when
    XCTAssert([self.syncMOC saveOrRollback]);
    
    // then
    XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 1lu);
}

- (void)testThatItDoesNotCountConversationsThatAreClearedAsUnread;
{
    // given
    XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);

    ZMConversation *conversation = [self insertConversationWithUnread:YES];
    conversation.isArchived = YES;
    [conversation clearMessageHistory];
    
    // when
    XCTAssert([self.syncMOC saveOrRollback]);
    
    // then
    XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);

}

@end



@implementation ZMConversationTests (ConversaitonListIndicator)

- (void)setConversationAsHavingKnock:(ZMConversation *)conversation
{
    [self simulateUnreadMissedKnockInConversation:conversation];
}

- (void)setConversationAsHavingMissedCall:(ZMConversation *)conversation
{
    [self simulateUnreadMissedCallInConversation:conversation];
}


- (void)setConversationAsHavingActiveCall:(ZMConversation *)conversation
{
    conversation.callDeviceIsActive = YES;
}

- (void)setConversationAsBeingPending:(ZMConversation *)conversation inContext:(NSManagedObjectContext *)context
{
    conversation.conversationType = ZMConversationTypeConnection;
    conversation.connection = [ZMConnection insertNewObjectInManagedObjectContext:context];
    conversation.connection.to = [ZMUser insertNewObjectInManagedObjectContext:context];
    conversation.connection.status = ZMConnectionStatusSent;
}


- (void)testThatConversationListIndicatorIsNoneByDefault
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // then
    XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorNone);
}

- (void)testThatConversationListIndicatorIsUnreadMessageWhenItHasUnread
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        [self simulateUnreadCount:2 forConversation:conversation];
        
        // then
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorUnreadMessages);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}


- (void)testThatConversationListIndicatorIsKnockWhenItHasUnreadAndKnock
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        [self simulateUnreadCount:1 forConversation:conversation];
        [self simulateUnreadMissedKnockInConversation:conversation];
        
        // then
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorKnock);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}


- (void)testThatConversationListIndicatorIsMissedCallWhenItHasMissedCallAndLowerPriorityEvents
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        [self simulateUnreadCount:1 forConversation:conversation];
        [self simulateUnreadMissedKnockInConversation:conversation];
        [self simulateUnreadMissedCallInConversation:conversation];
        
        // then
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorMissedCall);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}


- (void)testThatConversationListIndicatorIsExpiredMessageWhenItHasExpiredMessageAndLowerPriorityEvents
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        [self simulateUnreadCount:1 forConversation:conversation];
        [self simulateUnreadMissedKnockInConversation:conversation];
        [self simulateUnreadMissedCallInConversation:conversation];
        [conversation setHasUnreadUnsentMessage:YES];
        
        // then
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorExpiredMessage);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}


- (void)testThatConversationListIndicatorIsVoiceActiveWhenItHasActiveVoiceChannelAndLowerPriorityEvents
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        [self simulateUnreadCount:1 forConversation:conversation];
        [self simulateUnreadMissedKnockInConversation:conversation];
        [self simulateUnreadMissedCallInConversation:conversation];
        [conversation setHasUnreadUnsentMessage:YES];
        [self setConversationAsHavingActiveCall:conversation];
        
        // then
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorActiveCall);
        [conversation.voiceChannel tearDown];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}


- (void)testThatConversationListIndicatorIsPendingConversationWhenItIsAPendingConnectionAndItHasLowerPriorityEvents
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        [self simulateUnreadCount:1 forConversation:conversation];
        [self simulateUnreadMissedKnockInConversation:conversation];
        [self simulateUnreadMissedCallInConversation:conversation];
        [conversation setHasUnreadUnsentMessage:YES];
        [self setConversationAsHavingActiveCall:conversation];
        [self setConversationAsBeingPending:conversation inContext:self.syncMOC];
        
        // then
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorPending);
        [conversation.voiceChannel tearDown];

    }];
    WaitForAllGroupsToBeEmpty(0.5);
}


@end


@implementation ZMConversationTests (SearchQuerys)

- (void)testThatItFindsConversationsWithUserDefinedNameByParticipantName
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user1.name = @"User1";
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user2.name = @"User2";
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    [conversation.mutableOtherActiveParticipants addObjectsFromArray:@[user1, user2]];
    conversation.userDefinedName = @"Conversation";
    conversation.conversationType = ZMConversationTypeGroup;
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
    request.predicate = [ZMConversation predicateForSearchString:@"User1"];
    
    NSArray *result = [self.uiMOC executeFetchRequestOrAssert:request];
    
    // then
    XCTAssertEqual(result.count, 1u);
    XCTAssertEqualObjects(result.firstObject, conversation);
}

- (void)testThatItFindsConversationsWithUserDefinedNameByParticipantName_SecondSearchComponent
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user1.name = @"Foo 1";
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user2.name = @"Bar 2";
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    [conversation.mutableOtherActiveParticipants addObjectsFromArray:@[user1, user2]];
    conversation.userDefinedName = @"Conversation";
    conversation.conversationType = ZMConversationTypeGroup;
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
    request.predicate = [ZMConversation predicateForSearchString:@"Foo Bar"];
    
    NSArray *result = [self.uiMOC executeFetchRequestOrAssert:request];
    
    // then
    XCTAssertEqual(result.count, 1u);
    XCTAssertEqualObjects(result.firstObject, conversation);
}


- (void)testThatItFindsConversationByUserDefinedName
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.userDefinedName = @"The Wire Club";
    conversation.conversationType = ZMConversationTypeGroup;
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
    request.predicate = [ZMConversation userDefinedNamePredicateForSearchString:@"The Wire"];
    
    NSArray *result = [self.uiMOC executeFetchRequestOrAssert:request];
    
    // then
    XCTAssertEqual(result.count, 1u);
    XCTAssertEqualObjects(result.firstObject, conversation);
}

- (void)testThatItOnlyFindsConversationsWithAllComponents
{
    // given
    ZMConversation *conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation1.userDefinedName = @"The Wire";
    conversation1.conversationType = ZMConversationTypeGroup;
    ZMConversation *conversation2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation2.userDefinedName = @"The Club";
    conversation2.conversationType = ZMConversationTypeGroup;
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
    request.predicate = [ZMConversation userDefinedNamePredicateForSearchString:@"The Wire"];
    
    NSArray *result = [self.uiMOC executeFetchRequestOrAssert:request];
    
    // then
    XCTAssertEqual(result.count, 1u);
    XCTAssertEqualObjects(result.firstObject, conversation1);
}


- (void)testThatItFindsConversationsWithMatchingUserNameOrMatchingUserDefinedName
{
    // given
    ZMConversation *conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation1.userDefinedName = @"Bine in da Haus";
    conversation1.conversationType = ZMConversationTypeGroup;
    
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user1.name = @"Bine hallo";
    ZMConversation *conversation2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation2.userDefinedName = @"The Club";
    conversation2.conversationType = ZMConversationTypeGroup;
    [conversation2.mutableOtherActiveParticipants addObject:user1];
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
    request.predicate = [ZMConversation predicateForSearchString:@"Bine"];
    
    NSArray *result = [self.uiMOC executeFetchRequestOrAssert:request];
    
    // then
    XCTAssertEqual(result.count, 2u);
}


- (void)testThatItDoesNotFindAOneOnOneConversationByUserDefinedName
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user1.name = @"Foo";
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];

    [conversation.mutableOtherActiveParticipants addObjectsFromArray:@[user1]];
    conversation.userDefinedName = @"Conversation";
    conversation.conversationType = ZMConversationTypeOneOnOne;
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
    request.predicate = [ZMConversation userDefinedNamePredicateForSearchString:@"Find Conversation"];
    
    NSArray *result = [self.uiMOC executeFetchRequestOrAssert:request];
    
    // then
    XCTAssertEqual(result.count, 0u);
}


- (void)testThatItDoesNotFindAConversationThatDoesNotStartWithButContainsTheSearchString
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.userDefinedName = @"FindTheString";
    conversation.conversationType = ZMConversationTypeGroup;
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
    request.predicate = [ZMConversation userDefinedNamePredicateForSearchString:@"TheString"];
    
    NSArray *result = [self.uiMOC executeFetchRequestOrAssert:request];
    
    // then
    XCTAssertEqual(result.count, 0u);
}

@end



@implementation ZMConversationTests (Predicates)



- (void)testThatItFetchesConversationsWithCallStateNeededToBeSynced
{
    //given
    ZMUser *otherUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *secondUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    [self.uiMOC saveOrRollback];
    
    NSArray *users = @[otherUser,secondUser];
    
    ZMConversation *conversationWithCallParticipants = [self insertConversationWithParticipants:users callParticipants:users callStateNeedsToBeUpdatedFromBackend:NO];
    ZMConversation *alreadyMarkedConversation = [self insertConversationWithParticipants:users callParticipants:users callStateNeedsToBeUpdatedFromBackend:YES];
    ZMConversation *conversationWithNoCallParticipants = [self insertConversationWithParticipants:users callParticipants:@[] callStateNeedsToBeUpdatedFromBackend:NO];
    
    //when
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ZMConversation entityName]];
    request.predicate = [ZMConversation predicateForUpdatingCallStateDuringSlowSync];
    
    // when
    NSArray *result = [self.uiMOC executeFetchRequestOrAssert:request];
    XCTAssertTrue([result containsObject:conversationWithCallParticipants]);
    XCTAssertFalse([result containsObject:alreadyMarkedConversation]);
    XCTAssertFalse([result containsObject:conversationWithNoCallParticipants]);
    
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatItFiltersOut_SelfConversation
{
    // given
    NSUUID *selfUserID = [NSUUID UUID];
    [ZMUser selfUserInContext:self.uiMOC].remoteIdentifier = selfUserID;
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeSelf;
    conversation.remoteIdentifier = selfUserID;
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSPredicate *sut = [ZMConversation predicateForConversationsIncludingArchived];
    
    // then
    XCTAssertFalse([sut evaluateWithObject:conversation]);
}

- (void)testThatItDoesNotFilterOut_NotCleared_Archived_Conversations_IncludingArchivedPredicate
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    [self performIgnoringZMLogError:^{
        [self timeStampForSortAppendMessageToConversation:conversation];
    }];
    conversation.isArchived = YES;
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertTrue(conversation.isArchived);
    XCTAssertNil(conversation.clearedTimeStamp);
    
    // when
    NSPredicate *sut = [ZMConversation predicateForConversationsIncludingArchived];
    
    // then
    XCTAssertTrue([sut evaluateWithObject:conversation]);
}

- (void)testThatItDoesNotFilterOut_Cleared_Archived_Conversations_WithNewMessages_IncludingArchivedPredicate
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    __block NSDate *clearedTimeStamp;
    [self performIgnoringZMLogError:^{
        clearedTimeStamp = [self timeStampForSortAppendMessageToConversation:conversation];
    }];

    [conversation clearMessageHistory];
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self performIgnoringZMLogError:^{
        [self timeStampForSortAppendMessageToConversation:conversation];
    }];
    XCTAssertTrue(conversation.isArchived);
    XCTAssertEqualObjects(conversation.clearedTimeStamp, clearedTimeStamp);
    
    // when
    NSPredicate *sut = [ZMConversation predicateForConversationsIncludingArchived];
    
    // then
    XCTAssertTrue([sut evaluateWithObject:conversation]);
}


- (void)testThatItFiltersOutArchivedAndClearedConversations_IncludingArchivedPredicate
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    __block NSDate *clearedTimeStamp;
    [self performIgnoringZMLogError:^{
        clearedTimeStamp = [self timeStampForSortAppendMessageToConversation:conversation];
    }];

    [conversation clearMessageHistory];
    WaitForAllGroupsToBeEmpty(0.5);

    XCTAssertTrue(conversation.isArchived);
    XCTAssertEqualObjects(conversation.clearedTimeStamp, clearedTimeStamp);

    // when
    NSPredicate *sut = [ZMConversation predicateForConversationsIncludingArchived];
    
    // then
    XCTAssertFalse([sut evaluateWithObject:conversation]);
}

- (void)testThatItDoesNotFilterClearedConversationsThatAreNotArchived_IncludingArchivedPredicate
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    __block NSDate *clearedTimeStamp;
    [self performIgnoringZMLogError:^{
        clearedTimeStamp = [self timeStampForSortAppendMessageToConversation:conversation];
    }];
    
    [conversation clearMessageHistory];
    WaitForAllGroupsToBeEmpty(0.5);
    
    conversation.isArchived = NO;
    XCTAssertFalse(conversation.isArchived);
    XCTAssertEqualObjects(conversation.clearedTimeStamp, clearedTimeStamp);
    
    // when
    NSPredicate *sut = [ZMConversation predicateForConversationsIncludingArchived];
    
    // then
    XCTAssertTrue([sut evaluateWithObject:conversation]);
}

- (void)testThatItReturnsClearedConversationsInWhichSelfIsActiveMember_SearchStringPredicate
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.userDefinedName = @"lala";
    conversation.conversationType = ZMConversationTypeGroup;
    __block NSDate *clearedTimeStamp;
    [self performIgnoringZMLogError:^{
        clearedTimeStamp = [self timeStampForSortAppendMessageToConversation:conversation];
    }];
    [self.uiMOC saveOrRollback];
    
    [conversation clearMessageHistory];
    conversation.isSelfAnActiveMember = YES;
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertTrue(conversation.isArchived);
    XCTAssertTrue(conversation.isSelfAnActiveMember);
    XCTAssertEqualObjects(conversation.clearedTimeStamp, clearedTimeStamp);
    
    // when
    NSPredicate *sut = [ZMConversation predicateForSearchString:@"lala"];
    
    // then
    XCTAssertTrue([sut evaluateWithObject:conversation]);
}

- (void)testThatIt_DoesNot_ReturnClearedConversationsInWhichSelfIs_Not_ActiveMember_SearchStringPredicate
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.userDefinedName = @"lala";
    conversation.conversationType = ZMConversationTypeGroup;
    __block NSDate *clearedTimeStamp;
    [self performIgnoringZMLogError:^{
        clearedTimeStamp = [self timeStampForSortAppendMessageToConversation:conversation];
    }];

    [self.uiMOC saveOrRollback];
    
    [conversation clearMessageHistory];
    conversation.isSelfAnActiveMember = NO;
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertTrue(conversation.isArchived);
    XCTAssertFalse(conversation.isSelfAnActiveMember);
    XCTAssertEqualObjects(conversation.clearedTimeStamp, clearedTimeStamp);
    
    // when
    NSPredicate *sut = [ZMConversation predicateForSearchString:@"lala"];
    
    // then
    XCTAssertFalse([sut evaluateWithObject:conversation]);
}

- (void)testThatItReturnsConversationsInWhichSelfIs_Not_ActiveMember_NotCleared_SearchStringPredicate
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.userDefinedName = @"lala";
    conversation.conversationType = ZMConversationTypeGroup;
    [self performIgnoringZMLogError:^{
        [self timeStampForSortAppendMessageToConversation:conversation];
    }];
    conversation.isSelfAnActiveMember = NO;
    WaitForAllGroupsToBeEmpty(0.5);
    
    XCTAssertFalse(conversation.isSelfAnActiveMember);
    XCTAssertNil(conversation.clearedTimeStamp);
    
    // when
    NSPredicate *sut = [ZMConversation predicateForSearchString:@"lala"];
    
    // then
    XCTAssertTrue([sut evaluateWithObject:conversation]);
}

//TODO: test all other predicates

- (void)testThatItFetchesSharableConversations
{
    //given
    ZMUser *otherUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *secondUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    ZMConversation *conversationWithOtherUser = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversationWithOtherUser.conversationType = ZMConversationTypeOneOnOne;
    conversationWithOtherUser.remoteIdentifier = [NSUUID createUUID];
    [conversationWithOtherUser.mutableOtherActiveParticipants addObject:otherUser];

    ZMConversation *notSyncedConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    notSyncedConversation.conversationType = ZMConversationTypeOneOnOne;
    [notSyncedConversation.mutableOtherActiveParticipants addObject:otherUser];

    ZMConversation *conversationWithSecondUser = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversationWithSecondUser.conversationType = ZMConversationTypeOneOnOne;
    conversationWithSecondUser.remoteIdentifier = [NSUUID createUUID];
    [conversationWithSecondUser.mutableOtherActiveParticipants addObject:secondUser];
    
    ZMConversation *emptyConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    emptyConversation.conversationType = ZMConversationTypeOneOnOne;
    
    ZMConversation *conversationWithSentRequest = [ZMConnection insertNewSentConnectionToUser:otherUser].conversation;
    
    ZMConversation *conversationWithIncommingRequest = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversationWithIncommingRequest.connection = [ZMConnection insertNewObjectInManagedObjectContext:self.uiMOC];
    conversationWithIncommingRequest.conversationType = ZMConversationTypeConnection;
    conversationWithIncommingRequest.connection.status = ZMConnectionStatusPending;
    conversationWithIncommingRequest.remoteIdentifier = [NSUUID createUUID];
    
    ZMConversation *groupConversationWithSelf = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:@[otherUser, secondUser]];
    groupConversationWithSelf.isSelfAnActiveMember = YES;
    groupConversationWithSelf.remoteIdentifier = [NSUUID createUUID];
    
    ZMConversation *groupConversationWithoutSelf = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:@[otherUser, secondUser]];
    groupConversationWithoutSelf.isSelfAnActiveMember = NO;
    groupConversationWithSelf.remoteIdentifier = [NSUUID createUUID];
    
    ZMConversation *groupConversationWithNoOtherParticipants = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:@[otherUser, secondUser]];
    [groupConversationWithNoOtherParticipants removeParticipant:otherUser];
    [groupConversationWithNoOtherParticipants removeParticipant:secondUser];
    groupConversationWithNoOtherParticipants.isSelfAnActiveMember = YES;
    
    ZMConversation *archived = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    [archived.mutableOtherActiveParticipants addObject:otherUser];
    archived.conversationType = ZMConversationTypeOneOnOne;
    archived.isArchived = YES;
    archived.remoteIdentifier = [NSUUID createUUID];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ZMConversation entityName]];
    request.predicate = [ZMConversation predicateForSharableConversations];
    
    //when
    NSArray *result = [self.uiMOC executeFetchRequestOrAssert:request];
    
    //then
    XCTAssertEqual(result.count, 4u);
    XCTAssertTrue([result containsObject:conversationWithOtherUser]);
    XCTAssertTrue([result containsObject:conversationWithSecondUser]);
    XCTAssertTrue([result containsObject:groupConversationWithSelf]);
    XCTAssertTrue([result containsObject:archived]);
    
    XCTAssertFalse([result containsObject:emptyConversation]);
    XCTAssertFalse([result containsObject:conversationWithSentRequest]);
    XCTAssertFalse([result containsObject:conversationWithIncommingRequest]);
    XCTAssertFalse([result containsObject:groupConversationWithoutSelf]);
    XCTAssertFalse([result containsObject:groupConversationWithNoOtherParticipants]);
    XCTAssertFalse([result containsObject:notSyncedConversation]);
}

@end



@implementation ZMConversationTests (SelfConversationSync)

- (void)testThatItSetsHasLocalModificationsForLastReadServerTimeStampWhenSettingLastRead
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.remoteIdentifier = [NSUUID createUUID];
        conversation.lastReadServerTimeStamp = [NSDate date];
        NSDate *newLastRead = [conversation.lastReadServerTimeStamp dateByAddingTimeInterval:5];
        
        NSDictionary *payload = @{@"conversation" : conversation.remoteIdentifier.transportString,
                                  @"time" : newLastRead.transportString,
                                  @"data" : @{},
                                  @"from" : @"f76c1c7a-7278-4b70-9df7-eca7980f3a5d",
                                  @"id" : self.createEventID.transportString,
                                  @"type": @"conversation.message-add"
                                  };
        ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:(id)payload uuid:nil];
        
        // when
        [conversation updateLastReadFromPostPayloadEvent:event];
        [self.syncMOC saveOrRollback];
        
        // then
        XCTAssertTrue([conversation hasLocalModificationsForKey:ZMConversationLastReadServerTimeStampKey]);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatItUpdatesTheConversationWhenItReceivesAZMLastReadInTheSelfConversation
{
    // given
    __block ZMConversation *updatedConversation;
    NSDate *oldLastRead = [NSDate date];
    NSDate *newLastRead = [oldLastRead dateByAddingTimeInterval:100];

    [self.syncMOC performGroupedBlockAndWait:^{
        NSUUID *selfUserID = [ZMUser selfUserInContext:self.syncMOC].remoteIdentifier;
        XCTAssertNotNil(selfUserID);
        
        updatedConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        updatedConversation.remoteIdentifier = [NSUUID createUUID];
        updatedConversation.lastReadServerTimeStamp = oldLastRead;
        
        ZMGenericMessage *message = [ZMGenericMessage messageWithLastRead:newLastRead ofConversationWithID:updatedConversation.remoteIdentifier.transportString nonce:[NSUUID UUID].transportString];
        NSData *contentData = message.data;
        NSString *data = [contentData base64EncodedStringWithOptions:0];
        
        NSDictionary *payload = @{@"conversation" : selfUserID.transportString,
                                  @"time" : newLastRead.transportString,
                                  @"data" : data,
                                  @"from" : selfUserID.transportString,
                                  @"id" : self.createEventID.transportString,
                                  @"type": @"conversation.client-message-add"
                                  };
        ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:(id)payload uuid:nil];
        
        // when
        [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.syncMOC prefetchResult:nil];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualWithAccuracy([updatedConversation.lastReadServerTimeStamp timeIntervalSince1970], [newLastRead timeIntervalSince1970], 1.5);
}

@end





@implementation ZMConversationTests (ConversationMetaData)

- (void)testThatItUpdatesTheLastReadServerTimeStampWhenUpdatingTheEventIDConversationMetaData_LastReadIsLastEvent
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.lastReadServerTimeStamp = [NSDate dateWithTimeIntervalSinceNow:-10];
        
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        ZMMessage *message1 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message1.eventID = self.createEventID;
        ZMMessage *message2 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message2.eventID = self.createEventID;
        message2.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:20];
        
        conversation.lastReadEventID = message1.eventID;
        
        NSDictionary *payload = @{
                                  @"last_event_time" : message2.serverTimestamp.transportString,
                                  @"name" : [NSNull null],
                                  @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                                  @"last_event" : message2.eventID.transportString,
                                  @"members" : @{
                                          @"self" : @{
                                                  @"status" : @0,
                                                  @"muted_time" : [NSNull null],
                                                  @"status_ref" : @"0.0",
                                                  @"last_read" : message2.eventID.transportString,
                                                  @"muted" : @1,
                                                  @"archived" : @"false",
                                                  @"status_time" : @"2014-03-14T16:47:37.573Z",
                                                  @"id" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9"
                                                  },
                                          @"others" : @[]
                                          },
                                  @"type" : @1,
                                  @"id" : [uuid transportString]
                                  };
        
        // when
        [conversation updateWithTransportData:payload];
        
        // then
        XCTAssertEqualObjects(conversation.lastReadEventID, message2.eventID);
        XCTAssertEqualObjects(conversation.lastReadServerTimeStamp, message2.serverTimestamp);
    }];
}

- (void)testThatItDoesNotUpdateTheLastReadServerTimeStampWhenUpdatingTheEventIDConversationMetaData_LastRead_IsNOT_LastEvent
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSDate *lastReadDate = [NSDate dateWithTimeIntervalSinceNow:-10];
        conversation.lastReadServerTimeStamp = lastReadDate;
        
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        ZMMessage *message1 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message1.eventID = self.createEventID;
        ZMMessage *message2 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message2.eventID = self.createEventID;
        message2.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:20];
        
        conversation.lastReadEventID = message1.eventID;
        
        NSDictionary *payload = @{
                                  @"last_event_time" : message2.serverTimestamp.transportString,
                                  @"name" : [NSNull null],
                                  @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                                  @"last_event" : message2.eventID.transportString,
                                  @"members" : @{
                                          @"self" : @{
                                                  @"status" : @0,
                                                  @"muted_time" : [NSNull null],
                                                  @"status_ref" : @"0.0",
                                                  @"last_read" : message1.eventID.transportString,
                                                  @"muted" : @1,
                                                  @"archived" : @"false",
                                                  @"status_time" : @"2014-03-14T16:47:37.573Z",
                                                  @"id" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9"
                                                  },
                                          @"others" : @[]
                                          },
                                  @"type" : @1,
                                  @"id" : [uuid transportString]
                                  };
        
        // when
        [conversation updateWithTransportData:payload];
        
        // then
        XCTAssertEqualObjects(conversation.lastReadEventID, message1.eventID);
        XCTAssertEqualObjects(conversation.lastReadServerTimeStamp, lastReadDate);
    }];
}

- (void)testThatItUpdatesTheClearedTimeStampWhenUpdatingTheEventIDConversationMetaData_ClearedIsLastEvent
{
    __block ZMConversation *conversation;
    __block ZMEventID *clearedEventID;
    __block NSDate *clearedDate;
    
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        ZMMessage *message1 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message1.eventID = self.createEventID;
        ZMMessage *message2 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message2.eventID = self.createEventID;
        message2.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:20];
        
        clearedEventID = message2.eventID;
        clearedDate = message2.serverTimestamp;
        
        NSDictionary *payload = @{
                                  @"last_event_time" : message2.serverTimestamp.transportString,
                                  @"name" : [NSNull null],
                                  @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                                  @"last_event" : message2.eventID.transportString,
                                  @"members" : @{
                                          @"self" : @{
                                                  @"status" : @0,
                                                  @"muted_time" : [NSNull null],
                                                  @"status_ref" : @"0.0",
                                                  @"last_read" : message2.eventID.transportString,
                                                  @"muted" : @1,
                                                  @"archived" : @"false",
                                                  @"status_time" : @"2014-03-14T16:47:37.573Z",
                                                  @"id" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                                                  @"cleared" : message2.eventID.transportString
                                                  },
                                          @"others" : @[]
                                          },
                                  @"type" : @1,
                                  @"id" : [uuid transportString]
                                  };
        
        // when
        [conversation updateWithTransportData:payload];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    [self.syncMOC performGroupedBlockAndWait:^{
        // then
        XCTAssertEqualObjects(conversation.clearedEventID, clearedEventID);
        XCTAssertEqualObjects(conversation.clearedTimeStamp, clearedDate);
        XCTAssertEqual(conversation.messages.count, 0u);
    }];
}

- (void)testThatItDoesNotUpdateTheClearedTimeStampWhenUpdatingTheEventIDConversationMetaData_ClearedIsNOTLastEvent
{
    __block ZMConversation *conversation;
    __block ZMEventID *clearedEventID;
    __block NSDate *clearedDate;
    
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        ZMMessage *message1 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message1.eventID = self.createEventID;
        ZMMessage *message2 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message2.eventID = self.createEventID;
        message2.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:20];
        
        clearedEventID = message1.eventID;
        clearedDate = message1.serverTimestamp;
        
        NSDictionary *payload = @{
                                  @"last_event_time" : message2.serverTimestamp.transportString,
                                  @"name" : [NSNull null],
                                  @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                                  @"last_event" : message2.eventID.transportString,
                                  @"members" : @{
                                          @"self" : @{
                                                  @"status" : @0,
                                                  @"muted_time" : [NSNull null],
                                                  @"status_ref" : @"0.0",
                                                  @"last_read" : message1.eventID.transportString,
                                                  @"muted" : @1,
                                                  @"archived" : @"false",
                                                  @"status_time" : @"2014-03-14T16:47:37.573Z",
                                                  @"id" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                                                  @"cleared" : message1.eventID.transportString
                                                  },
                                          @"others" : @[]
                                          },
                                  @"type" : @1,
                                  @"id" : [uuid transportString]
                                  };
        
        // when
        [conversation updateWithTransportData:payload];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self.syncMOC performGroupedBlockAndWait:^{
        // then
        XCTAssertEqualObjects(conversation.clearedEventID, clearedEventID);
        XCTAssertNil(conversation.clearedTimeStamp);
        XCTAssertEqual(conversation.messages.count, 2u);
    }];
}

@end


@implementation ZMConversationTests (MemberUpdateEvent)

- (void)testThatItUpdatesTheLastReadServerTimeStampWhenUpdatingTheEventIDByMemberUpdateEvent_PassedTimeStamp
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.lastReadServerTimeStamp = [NSDate dateWithTimeIntervalSinceNow:-10];
        
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        ZMMessage *message1 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message1.eventID = self.createEventID;
        ZMMessage *message2 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message2.eventID = self.createEventID;
        message2.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:20];
        
        conversation.lastReadEventID = message1.eventID;
        
        NSDictionary *payload =  @{
                                   @"last_read" : message2.eventID.transportString,
                                   };
        // when
        [conversation updateSelfStatusFromDictionary:payload timeStamp:message2.serverTimestamp];
        
        // then
        XCTAssertEqualObjects(conversation.lastReadEventID, message2.eventID);
        XCTAssertEqualObjects(conversation.lastReadServerTimeStamp, message2.serverTimestamp);
    }];
}

- (void)testThatItUpdatesTheLastReadServerTimeStampWhenUpdatingTheEventIDByMemberUpdateEvent_LastRead_Is_LastEvent
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.lastReadServerTimeStamp = [NSDate dateWithTimeIntervalSinceNow:-10];
        
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        ZMMessage *message1 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message1.eventID = self.createEventID;
        ZMMessage *message2 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message2.eventID = self.createEventID;
        message2.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:20];
        
        conversation.lastReadEventID = message1.eventID;
        conversation.lastEventID = message2.eventID;
        
        NSDictionary *payload =  @{
                                   @"last_read" : message2.eventID.transportString,
                                   };
        // when
        [conversation updateSelfStatusFromDictionary:payload timeStamp:message2.serverTimestamp];
        
        // then
        XCTAssertEqualObjects(conversation.lastReadEventID, message2.eventID);
        XCTAssertEqualObjects(conversation.lastReadServerTimeStamp, message2.serverTimestamp);
    }];
}

- (void)testThatItDoesNotUpdateLastReadTimeStampWhenUpdatingTheEventIDByMemberUpdateEvent_LastRead_IsNOT_LastEvent_NoTimeStamp
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        ZMMessage *message1 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message1.eventID = self.createEventID;
        ZMMessage *message2 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message2.eventID = self.createEventID;
        message2.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:20];
        
        conversation.lastReadEventID = message1.eventID;
        
        NSDictionary *payload =  @{
                                   @"last_read" : message2.eventID.transportString,
                                   };
        // when
        [conversation updateSelfStatusFromDictionary:payload timeStamp:nil];
        
        // then
        XCTAssertEqualObjects(conversation.lastReadEventID, message2.eventID);
        XCTAssertNil(conversation.lastReadServerTimeStamp);
    }];
}

- (void)testThatItUpdatesTheClearedTimeStampWhenUpdatingTheEventIDByMemberUpdateEvent_PassedTimeStamp
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.lastReadServerTimeStamp = [NSDate dateWithTimeIntervalSinceNow:-10];
        
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        ZMMessage *message1 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message1.eventID = self.createEventID;
        ZMMessage *message2 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message2.eventID = self.createEventID;
        message2.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:20];
        
        conversation.lastReadEventID = message1.eventID;
        
        NSDictionary *payload =  @{
                                   @"cleared" : message2.eventID.transportString,
                                   };
        // when
        [conversation updateSelfStatusFromDictionary:payload timeStamp:message2.serverTimestamp];
        
        // then
        XCTAssertEqualObjects(conversation.clearedEventID, message2.eventID);
        XCTAssertEqualObjects(conversation.clearedTimeStamp, message2.serverTimestamp);
    }];
}

- (void)testThatItUpdatesClearedTimeStampWhenUpdatingTheEventIDByMemberUpdateEvent_LastRead_Is_LastEvent
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.lastReadServerTimeStamp = [NSDate dateWithTimeIntervalSinceNow:-10];
        
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        ZMMessage *message1 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message1.eventID = self.createEventID;
        ZMMessage *message2 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message2.eventID = self.createEventID;
        message2.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:20];
        
        conversation.lastReadEventID = message1.eventID;
        conversation.lastEventID = message2.eventID;
        
        NSDictionary *payload =  @{
                                   @"cleared" : message2.eventID.transportString,
                                   };
        // when
        [conversation updateSelfStatusFromDictionary:payload timeStamp:message2.serverTimestamp];
        
        // then
        XCTAssertEqualObjects(conversation.clearedEventID, message2.eventID);
        XCTAssertEqualObjects(conversation.clearedTimeStamp, message2.serverTimestamp);
    }];
}

- (void)testThatItDoesNotUpdateClearedTimeStampWhenUpdatingTheEventIDByMemberUpdateEvent_LastRead_IsNOT_LastEvent_NoTimeStamp
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.lastReadServerTimeStamp = [NSDate dateWithTimeIntervalSinceNow:-10];
        
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        ZMMessage *message1 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message1.eventID = self.createEventID;
        ZMMessage *message2 = [conversation appendMessagesWithText:@"hello"].firstObject;
        message2.eventID = self.createEventID;
        message2.serverTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:20];
        
        conversation.lastReadEventID = message1.eventID;
        
        NSDictionary *payload =  @{
                                   @"cleared" : message2.eventID.transportString,
                                   };
        // when
        [conversation updateSelfStatusFromDictionary:payload timeStamp:nil];
        
        // then
        XCTAssertEqualObjects(conversation.clearedEventID, message2.eventID);
        XCTAssertNil(conversation.clearedTimeStamp);
    }];
}

@end


@implementation ZMConversationTests (SendOnlyEncryptedMessages)

- (void)testThatItInsertsEncryptedTextMessages
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    [conversation appendMessagesWithText:@"hello"];
    
    // then
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ZMMessage entityName]];
    NSArray *result = [self.uiMOC executeFetchRequestOrAssert:request];
    
    XCTAssertEqual(result.count, 1u);
    XCTAssertTrue([result.firstObject isKindOfClass:[ZMClientMessage class]]);
}



- (void)testThatItInsertsEncryptedImageMessages
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    [conversation appendMessageWithImageData:self.verySmallJPEGData];
    
    // then
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ZMMessage entityName]];
    NSArray *result = [self.uiMOC executeFetchRequestOrAssert:request];
    
    XCTAssertEqual(result.count, 1u);
    XCTAssertTrue([result.firstObject isKindOfClass:[ZMAssetClientMessage class]]);
}

- (void)testThatItInsertsEncryptedKnockMessages
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    [conversation appendKnock];
    
    // then
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[ZMMessage entityName]];
    NSArray *result = [self.uiMOC executeFetchRequestOrAssert:request];
    
    XCTAssertEqual(result.count, 1u);
    XCTAssertTrue([result.firstObject isKindOfClass:[ZMClientMessage class]]);
}

@end

