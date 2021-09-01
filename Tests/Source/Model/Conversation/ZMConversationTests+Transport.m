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
#import "WireDataModelTests-Swift.h"

@implementation ZMConversationTransportTests

- (NSDictionary *)payloadForMetaDataOfConversation:(ZMConversation *)conversation
                                  conversationType:(ZMBackendConversationType)conversationType
                                        isArchived:(BOOL)isArchived
                                       archivedRef:(NSDate *)archivedRef
                                        isSilenced:(BOOL)isSilenced
                                       silencedRef:(NSDate *)silencedRef
                                    silencedStatus:(NSNumber *)silencedStatus
{
    return  [self payloadForMetaDataOfConversation:conversation
                                  conversationType:conversationType
                                     activeUserIDs:@[]
                                        isArchived:isArchived
                                       archivedRef:archivedRef
                                        isSilenced:isSilenced
                                       silencedRef:silencedRef
                                    silencedStatus:silencedStatus
                                            teamID:nil
                                        accessMode:@[]
                                        accessRole:@"non_activated"
                                       receiptMode:0];
}

- (NSDictionary *)payloadForMetaDataOfConversation:(ZMConversation *)conversation
                                     activeUserIDs:(NSArray <NSUUID *>*)activeUserIDs
{
    return  [self payloadForMetaDataOfConversation:conversation
                                  conversationType:1
                                     activeUserIDs:activeUserIDs
                                        isArchived:NO
                                       archivedRef:nil
                                        isSilenced:NO
                                       silencedRef:nil
                                    silencedStatus:@(MutedMessageOptionValueAll)
                                            teamID:nil
                                        accessMode:@[]
                                        accessRole:@"non_activated"
                                       receiptMode:0];
}

- (NSDictionary *)payloadForMetaDataOfConversation:(ZMConversation *)conversation
                                  conversationType:(ZMBackendConversationType)conversationType
                                     activeUserIDs:(NSArray <NSUUID *>*)activeUserIDs
                                        isArchived:(BOOL)isArchived
                                       archivedRef:(NSDate *)archivedRef
                                        isSilenced:(BOOL)isSilenced
                                       silencedRef:(NSDate *)silencedRef
                                    silencedStatus:(NSNumber *)silencedStatus
                                            teamID:(NSUUID *)teamID
                                        accessMode:(NSArray<NSString *> *)accessMode
                                        accessRole:(NSString *)accessRole
                                       receiptMode:(NSInteger)receiptMode
{
    NSMutableArray *others = [NSMutableArray array];
    for (NSUUID *uuid in activeUserIDs) {
        NSDictionary *userInfo = @{
                                   @"id": [uuid transportString]
                                   };
        [others addObject:userInfo];
    }
    
    NSString *selfRemoteId = [ZMUser selfUserInContext:conversation.managedObjectContext].remoteIdentifier.transportString;
    NSDictionary *payload = @{
                              @"name" : [NSNull null],
                              @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                              @"members" : @{
                                      @"self" : @{
                                              @"id" : selfRemoteId,
                                              @"otr_archived" : @(isArchived),
                                              @"otr_archived_ref" : archivedRef ? [archivedRef transportString] : [NSNull null],
                                              @"otr_muted" : @(isSilenced),
                                              @"otr_muted_ref" : silencedRef ? [silencedRef transportString] : [NSNull null],
                                              @"otr_muted_status": silencedStatus ? @([silencedStatus intValue]) : [NSNull null],
                                              },
                                      @"others" : others
                                      },
                              @"type" : @(conversationType),
                              @"id" : [conversation.remoteIdentifier transportString],
                              @"team": [teamID transportString] ?: [NSNull null],
                              @"access": accessMode,
                              @"access_role": accessRole,
                              @"receipt_mode": @(receiptMode)
                              };
    return  payload;
}

- (void)testThatItUpdatesItselfFromTransportData
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        [ZMUser selfUserInContext:self.syncMOC].teamIdentifier = [NSUUID UUID];
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        [conversation addParticipantAndUpdateConversationStateWithUser:[ZMUser selfUserInContext:self.syncMOC] role:nil];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        NSDate *serverTimestamp = [NSDate date];
        NSDate *archivedDate = [NSDate date];
        NSDate *silencedDate = [archivedDate dateByAddingTimeInterval:10];
        
        NSDictionary *payload = [self payloadForMetaDataOfConversation:conversation
                                                      conversationType:ZMBackendConversationTypeGroup
                                                            isArchived:YES
                                                           archivedRef:archivedDate
                                                            isSilenced:YES
                                                           silencedRef:silencedDate
                                                        silencedStatus:nil];
        
        // when
        [conversation updateWithTransportData:payload serverTimeStamp:serverTimestamp];
        
        // then
        XCTAssertEqualObjects(conversation.remoteIdentifier, [payload[@"id"] UUID]);
        XCTAssertNil(conversation.userDefinedName);
        XCTAssertEqual(conversation.conversationType, ZMConversationTypeGroup);
        XCTAssertEqualObjects(conversation.lastServerTimeStamp, serverTimestamp);
        
        XCTAssertTrue(conversation.isArchived);
        XCTAssertEqualWithAccuracy([conversation.archivedChangedTimestamp timeIntervalSince1970], [archivedDate timeIntervalSince1970], 1.0);

        XCTAssertTrue(conversation.isOnlyMentionsAndReplies);
        XCTAssertEqualWithAccuracy([conversation.silencedChangedTimestamp timeIntervalSince1970], [silencedDate timeIntervalSince1970], 1.0);

        XCTAssertEqualObjects(conversation.creator.remoteIdentifier, [payload[@"creator"] UUID]);
    }];
}

- (void)testThatItUpdatesItselfFromTransportData_mutedStatus
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        NSDate *serverTimestamp = [NSDate date];
        NSDate *archivedDate = [NSDate date];
        NSDate *silencedDate = [archivedDate dateByAddingTimeInterval:10];
        
        NSDictionary *payload = [self payloadForMetaDataOfConversation:conversation
                                                      conversationType:ZMBackendConversationTypeGroup
                                                            isArchived:YES
                                                           archivedRef:archivedDate
                                                            isSilenced:YES
                                                           silencedRef:silencedDate
                                                        silencedStatus:@(MutedMessageOptionValueAll)];
        
        // when
        [conversation updateWithTransportData:payload serverTimeStamp:serverTimestamp];
        
        // then
        XCTAssertEqualObjects(conversation.remoteIdentifier, [payload[@"id"] UUID]);
        XCTAssertNil(conversation.userDefinedName);
        XCTAssertEqual(conversation.conversationType, ZMConversationTypeGroup);
        XCTAssertEqualObjects(conversation.lastServerTimeStamp, serverTimestamp);
        
        XCTAssertTrue(conversation.isArchived);
        XCTAssertEqualWithAccuracy([conversation.archivedChangedTimestamp timeIntervalSince1970], [archivedDate timeIntervalSince1970], 1.0);
        
        XCTAssertTrue(conversation.isFullyMuted);
        XCTAssertEqualWithAccuracy([conversation.silencedChangedTimestamp timeIntervalSince1970], [silencedDate timeIntervalSince1970], 1.0);
        
        XCTAssertEqualObjects(conversation.creator.remoteIdentifier, [payload[@"creator"] UUID]);
    }];
}

- (void)testThatItUpdatesItselfFromTransportData_mutedStatusToLegacy
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        conversation.mutedStatus = 3;
        [conversation addParticipantAndUpdateConversationStateWithUser:[ZMUser selfUserInContext:self.syncMOC] role:nil];
        NSDate *serverTimestamp = [NSDate date];
        NSDate *archivedDate = [NSDate date];
        NSDate *silencedDate = [archivedDate dateByAddingTimeInterval:10];
        
        NSDictionary *payload = [self payloadForMetaDataOfConversation:conversation
                                                      conversationType:ZMBackendConversationTypeGroup
                                                            isArchived:YES
                                                           archivedRef:archivedDate
                                                            isSilenced:NO
                                                           silencedRef:silencedDate
                                                        silencedStatus:nil];
        
        // when
        [conversation updateWithTransportData:payload serverTimeStamp:serverTimestamp];
        
        // then
        XCTAssertEqualObjects(conversation.remoteIdentifier, [payload[@"id"] UUID]);
        XCTAssertNil(conversation.userDefinedName);
        XCTAssertEqual(conversation.conversationType, ZMConversationTypeGroup);
        XCTAssertEqualObjects(conversation.lastServerTimeStamp, serverTimestamp);
        
        XCTAssertTrue(conversation.isArchived);
        XCTAssertEqualWithAccuracy([conversation.archivedChangedTimestamp timeIntervalSince1970], [archivedDate timeIntervalSince1970], 1.0);
        
        XCTAssertFalse(conversation.isFullyMuted);
        XCTAssertEqualWithAccuracy([conversation.silencedChangedTimestamp timeIntervalSince1970], [silencedDate timeIntervalSince1970], 1.0);
        
        XCTAssertEqualObjects(conversation.creator.remoteIdentifier, [payload[@"creator"] UUID]);
    }];
}


- (void)testThatItUpdatesItselfFromTransportData_mutedStatus_onlyMentions
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        [ZMUser selfUserInContext:self.syncMOC].teamIdentifier = [NSUUID UUID];
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        NSDate *serverTimestamp = [NSDate date];
        NSDate *archivedDate = [NSDate date];
        NSDate *silencedDate = [archivedDate dateByAddingTimeInterval:10];
        
        NSDictionary *payload = [self payloadForMetaDataOfConversation:conversation
                                                      conversationType:ZMBackendConversationTypeGroup
                                                            isArchived:YES
                                                           archivedRef:archivedDate
                                                            isSilenced:YES
                                                           silencedRef:silencedDate
                                                        silencedStatus:@(1)];
        
        // when
        [conversation updateWithTransportData:payload serverTimeStamp:serverTimestamp];
        
        // then
        XCTAssertEqualObjects(conversation.remoteIdentifier, [payload[@"id"] UUID]);
        XCTAssertNil(conversation.userDefinedName);
        XCTAssertEqual(conversation.conversationType, ZMConversationTypeGroup);
        XCTAssertEqualObjects(conversation.lastServerTimeStamp, serverTimestamp);
        
        XCTAssertTrue(conversation.isArchived);
        XCTAssertEqualWithAccuracy([conversation.archivedChangedTimestamp timeIntervalSince1970], [archivedDate timeIntervalSince1970], 1.0);
        
        XCTAssertTrue(conversation.isOnlyMentionsAndReplies);
        XCTAssertEqualWithAccuracy([conversation.silencedChangedTimestamp timeIntervalSince1970], [silencedDate timeIntervalSince1970], 1.0);
        
        XCTAssertEqualObjects(conversation.creator.remoteIdentifier, [payload[@"creator"] UUID]);
    }];
}

- (void)testThatItUpdatesItselfFromTransportData_keepsNonMutedMentions
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        [ZMUser selfUserInContext:self.syncMOC].teamIdentifier = [NSUUID UUID];
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        conversation.mutedStatus = 1;
        NSDate *serverTimestamp = [NSDate date];
        NSDate *archivedDate = [NSDate date];
        NSDate *silencedDate = [archivedDate dateByAddingTimeInterval:10];
        
        NSDictionary *payload = [self payloadForMetaDataOfConversation:conversation
                                                      conversationType:ZMBackendConversationTypeGroup
                                                            isArchived:YES
                                                           archivedRef:archivedDate
                                                            isSilenced:YES
                                                           silencedRef:silencedDate
                                                        silencedStatus:@(1)];
        
        // when
        [conversation updateWithTransportData:payload serverTimeStamp:serverTimestamp];
        
        // then
        XCTAssertEqualObjects(conversation.remoteIdentifier, [payload[@"id"] UUID]);
        XCTAssertNil(conversation.userDefinedName);
        XCTAssertEqual(conversation.conversationType, ZMConversationTypeGroup);
        XCTAssertEqualObjects(conversation.lastServerTimeStamp, serverTimestamp);
        
        XCTAssertTrue(conversation.isArchived);
        XCTAssertEqualWithAccuracy([conversation.archivedChangedTimestamp timeIntervalSince1970], [archivedDate timeIntervalSince1970], 1.0);
        
        XCTAssertTrue(conversation.isOnlyMentionsAndReplies);
        XCTAssertEqualWithAccuracy([conversation.silencedChangedTimestamp timeIntervalSince1970], [silencedDate timeIntervalSince1970], 1.0);
        
        XCTAssertEqualObjects(conversation.creator.remoteIdentifier, [payload[@"creator"] UUID]);
    }];
}

- (void)testThatItUpdatesItselfFromTransportData_keepsFullMutedMentions
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        conversation.mutedStatus = 3;
        NSDate *serverTimestamp = [NSDate date];
        NSDate *archivedDate = [NSDate date];
        NSDate *silencedDate = [archivedDate dateByAddingTimeInterval:10];
        
        NSDictionary *payload = [self payloadForMetaDataOfConversation:conversation
                                                      conversationType:ZMBackendConversationTypeGroup
                                                            isArchived:YES
                                                           archivedRef:archivedDate
                                                            isSilenced:YES
                                                           silencedRef:silencedDate
                                                        silencedStatus:@(MutedMessageOptionValueAll)];
        
        // when
        [conversation updateWithTransportData:payload serverTimeStamp:serverTimestamp];
        
        // then
        XCTAssertEqualObjects(conversation.remoteIdentifier, [payload[@"id"] UUID]);
        XCTAssertNil(conversation.userDefinedName);
        XCTAssertEqual(conversation.conversationType, ZMConversationTypeGroup);
        XCTAssertEqualObjects(conversation.lastServerTimeStamp, serverTimestamp);
        
        XCTAssertTrue(conversation.isArchived);
        XCTAssertEqualWithAccuracy([conversation.archivedChangedTimestamp timeIntervalSince1970], [archivedDate timeIntervalSince1970], 1.0);
        
        XCTAssertTrue(conversation.isFullyMuted);
        XCTAssertEqualWithAccuracy([conversation.silencedChangedTimestamp timeIntervalSince1970], [silencedDate timeIntervalSince1970], 1.0);
        
        XCTAssertEqualObjects(conversation.creator.remoteIdentifier, [payload[@"creator"] UUID]);
    }];
}

- (void)testThatItUpdatesItselfFromTransportDataForGroupConversation
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSDate *serverTimestamp = [NSDate date];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        
        NSUUID *user1UUID = [NSUUID createUUID];
        NSUUID *user2UUID = [NSUUID createUUID];
        
        NSDictionary *payload = [self payloadForMetaDataOfConversation:conversation activeUserIDs:@[user1UUID, user2UUID]];
        
        // when
        [conversation updateWithTransportData:payload serverTimeStamp:serverTimestamp];
        
        // then
        XCTAssertEqualObjects(conversation.remoteIdentifier, [payload[@"id"] UUID]);
        XCTAssertNil(conversation.userDefinedName);
        XCTAssertEqual(conversation.conversationType, ZMConversationTypeSelf);
        XCTAssertEqualObjects(conversation.lastServerTimeStamp, serverTimestamp);
        XCTAssertEqualObjects(conversation.creator.remoteIdentifier, [payload[@"creator"] UUID]);


        ZMUser *user1 = [ZMUser fetchWith:user1UUID in:self.syncMOC];
        XCTAssertNotNil(user1);
        
        ZMUser *user2 = [ZMUser fetchWith:user2UUID in:self.syncMOC];
        XCTAssertNotNil(user2);
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        
        XCTAssertEqualObjects(conversation.localParticipants, ([NSSet setWithObjects:user1, user2, selfUser, nil]) );
        
        XCTAssertFalse(conversation.isArchived);
        XCTAssertFalse(conversation.isFullyMuted);
        XCTAssertFalse(conversation.isOnlyMentionsAndReplies);
    }];
}

- (void)testThatItSetsTheServerTimeStamp
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        
        NSDictionary *payload = [self payloadForMetaDataOfConversation:conversation conversationType:1 isArchived:NO archivedRef:nil isSilenced:NO silencedRef:nil silencedStatus:@(MutedMessageOptionValueAll)];

        // when
        NSDate *serverTimeStamp = [NSDate date];
        [conversation updateWithTransportData:payload serverTimeStamp:serverTimeStamp];

        // then
        XCTAssertEqualObjects(conversation.remoteIdentifier, [payload[@"id"] UUID]);
        XCTAssertNil(conversation.userDefinedName);
        XCTAssertEqual(conversation.conversationType, ZMConversationTypeSelf);
        XCTAssertEqualObjects(conversation.lastServerTimeStamp, serverTimeStamp);
        XCTAssertEqualObjects(conversation.creator.remoteIdentifier, [payload[@"creator"] UUID]);
    }];
}

- (void)testThatItUpdatesItselfFromTransportDataForTeamConversation
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSDate *serverTimestamp = [NSDate date];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;

        NSUUID *user1UUID = [NSUUID createUUID];
        NSUUID *user2UUID = [NSUUID createUUID];
        NSUUID *teamID = [NSUUID createUUID];

        NSDictionary *payload = [self payloadForMetaDataOfConversation:conversation
                                                      conversationType:ZMBackendConversationTypeGroup
                                                         activeUserIDs:@[user1UUID, user2UUID]
                                                            isArchived:NO
                                                           archivedRef:nil
                                                            isSilenced:NO
                                                           silencedRef:nil
                                                        silencedStatus:@(MutedMessageOptionValueAll)
                                                                teamID:teamID
                                                            accessMode:@[]
                                                            accessRole:@"non_activated"
                                                           receiptMode:0];

        // when
        [conversation updateWithTransportData:payload serverTimeStamp:serverTimestamp];

        // then
        XCTAssertEqualObjects(conversation.remoteIdentifier, [payload[@"id"] UUID]);
        XCTAssertNil(conversation.userDefinedName);
        XCTAssertEqual(conversation.conversationType, ZMConversationTypeGroup);
        XCTAssertEqualObjects(conversation.lastServerTimeStamp, serverTimestamp);
        XCTAssertEqualObjects(conversation.creator.remoteIdentifier, [payload[@"creator"] UUID]);


        ZMUser *user1 = [ZMUser fetchWith:user1UUID in:self.syncMOC];
        XCTAssertNotNil(user1);

        ZMUser *user2 = [ZMUser fetchWith:user2UUID in:self.syncMOC];
        XCTAssertNotNil(user2);
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];

        XCTAssertEqualObjects(conversation.localParticipants, ([NSSet setWithObjects:user1, user2, selfUser, nil]) );
        XCTAssertNil(conversation.team);
        XCTAssertEqualObjects(conversation.teamRemoteIdentifier, teamID);
        
        XCTAssertFalse(conversation.isArchived);
        XCTAssertFalse(conversation.isFullyMuted);
        XCTAssertFalse(conversation.isOnlyMentionsAndReplies);
    }];
}

- (void)testThatItUpdatesItselfFromTransportDataForTeamConversation_ExistingTeam
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSDate *serverTimestamp = [NSDate date];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;

        NSUUID *user1UUID = [NSUUID createUUID];
        NSUUID *user2UUID = [NSUUID createUUID];
        Team *team = [Team fetchOrCreateTeamWithRemoteIdentifier:NSUUID.createUUID createIfNeeded:YES inContext:self.syncMOC created:nil];

        NSDictionary *payload = [self payloadForMetaDataOfConversation:conversation
                                                      conversationType:ZMBackendConversationTypeGroup
                                                         activeUserIDs:@[user1UUID, user2UUID]
                                                            isArchived:NO
                                                           archivedRef:nil
                                                            isSilenced:NO
                                                           silencedRef:nil
                                                        silencedStatus:@(MutedMessageOptionValueAll)
                                                                teamID:team.remoteIdentifier
                                                            accessMode:@[]
                                                            accessRole:@"non_activated"
                                                           receiptMode:0];

        // when
        [conversation updateWithTransportData:payload serverTimeStamp:serverTimestamp];

        // then
        XCTAssertEqualObjects(conversation.remoteIdentifier, [payload[@"id"] UUID]);
        XCTAssertNil(conversation.userDefinedName);
        XCTAssertEqual(conversation.conversationType, ZMConversationTypeGroup);
        XCTAssertEqualObjects(conversation.lastServerTimeStamp, serverTimestamp);
        XCTAssertEqualObjects(conversation.creator.remoteIdentifier, [payload[@"creator"] UUID]);


        ZMUser *user1 = [ZMUser fetchWith:user1UUID in:self.syncMOC];
        XCTAssertNotNil(user1);

        ZMUser *user2 = [ZMUser fetchWith:user2UUID in:self.syncMOC];
        XCTAssertNotNil(user2);
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];

        XCTAssertEqualObjects(conversation.localParticipants, ([NSSet setWithObjects:user1, user2, selfUser, nil]) );
        XCTAssertNotNil(conversation.team);
        XCTAssertFalse(conversation.team.needsToBeUpdatedFromBackend);
        XCTAssertFalse(conversation.team.needsToRedownloadMembers);
        XCTAssertEqualObjects(conversation.team.remoteIdentifier, team.remoteIdentifier);
        
        XCTAssertFalse(conversation.isArchived);
        XCTAssertFalse(conversation.isFullyMuted);
        XCTAssertFalse(conversation.isOnlyMentionsAndReplies);
    }];
}

- (void)testThatItUpdatesItselfFromTransportDataWithMissingTeamInfo
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSDate *serverTimestamp = [NSDate date];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;

        NSUUID *user1UUID = [NSUUID createUUID];
        NSUUID *user2UUID = [NSUUID createUUID];

        NSDictionary *payload = [self payloadForMetaDataOfConversation:conversation
                                                      conversationType:ZMBackendConversationTypeGroup
                                                         activeUserIDs:@[user1UUID, user2UUID]
                                                            isArchived:NO
                                                           archivedRef:nil
                                                            isSilenced:NO
                                                           silencedRef:nil
                                                        silencedStatus:@(MutedMessageOptionValueAll)
                                                                teamID:nil
                                                            accessMode:@[]
                                                            accessRole:@"non_activated"
                                                           receiptMode:0];

        // when
        [conversation updateWithTransportData:payload serverTimeStamp:serverTimestamp];

        // then
        XCTAssertEqualObjects(conversation.remoteIdentifier, [payload[@"id"] UUID]);
        XCTAssertNil(conversation.userDefinedName);
        XCTAssertEqual(conversation.conversationType, ZMConversationTypeGroup);
        XCTAssertEqualObjects(conversation.lastServerTimeStamp, serverTimestamp);
        XCTAssertEqualObjects(conversation.creator.remoteIdentifier, [payload[@"creator"] UUID]);

        ZMUser *user1 = [ZMUser fetchWith:user1UUID in:self.syncMOC];
        XCTAssertNotNil(user1);

        ZMUser *user2 = [ZMUser fetchWith:user2UUID in:self.syncMOC];
        XCTAssertNotNil(user2);
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];

        XCTAssertEqualObjects(conversation.localParticipants, ([NSSet setWithObjects:user1, user2, selfUser, nil]) );
        XCTAssertNil(conversation.team);
        XCTAssertFalse(conversation.isArchived);
        XCTAssertFalse(conversation.isFullyMuted);
        XCTAssertFalse(conversation.isOnlyMentionsAndReplies);
    }];
}

- (void)testThatItUpdatesItselfFromTransportDataWithAccessModeSet_AllowGuests
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSDate *serverTimestamp = [NSDate date];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        
        NSUUID *user1UUID = [NSUUID createUUID];
        
        NSDictionary *payload = [self payloadForMetaDataOfConversation:conversation
                                                      conversationType:ZMBackendConversationTypeGroup
                                                         activeUserIDs:@[user1UUID]
                                                            isArchived:NO
                                                           archivedRef:nil
                                                            isSilenced:NO
                                                           silencedRef:nil
                                                        silencedStatus:@(MutedMessageOptionValueAll)
                                                                teamID:nil
                                                            accessMode:@[@"invite", @"code"]
                                                            accessRole:@"non_activated"
                                                           receiptMode:0];
        
        // when
        [conversation updateWithTransportData:payload serverTimeStamp:serverTimestamp];
        
        // then
        XCTAssertTrue(conversation.allowGuests);
        XCTAssertEqual(conversation.accessRoleString, @"non_activated");
        BOOL arraysEqual = [conversation.accessModeStrings isEqual:@[@"invite", @"code"]];
        XCTAssertTrue(arraysEqual);
    }];
}

- (void)testThatItUpdatesItselfFromTransportDataWithAccessModeSet_ForbidGuests
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSDate *serverTimestamp = [NSDate date];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        
        NSUUID *user1UUID = [NSUUID createUUID];
        
        NSDictionary *payload = [self payloadForMetaDataOfConversation:conversation
                                                      conversationType:ZMBackendConversationTypeGroup
                                                         activeUserIDs:@[user1UUID]
                                                            isArchived:NO
                                                           archivedRef:nil
                                                            isSilenced:NO
                                                           silencedRef:nil
                                                        silencedStatus:@(MutedMessageOptionValueAll)
                                                                teamID:nil
                                                            accessMode:@[]
                                                            accessRole:@"team"
                                                           receiptMode:0];
        
        // when
        [conversation updateWithTransportData:payload serverTimeStamp:serverTimestamp];
        
        // then
        XCTAssertFalse(conversation.allowGuests);
        XCTAssertEqual(conversation.accessRoleString, @"team");
        BOOL arraysEqual = [conversation.accessModeStrings isEqual:@[]];
        XCTAssertTrue(arraysEqual);
    }];
}

- (void)testThatItUpdatesItselfFromTransportDataWithReceiptMode
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSDate *serverTimestamp = [NSDate date];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        
        NSUUID *user1UUID = [NSUUID createUUID];
        
        NSDictionary *payload = [self payloadForMetaDataOfConversation:conversation
                                                      conversationType:ZMBackendConversationTypeGroup
                                                         activeUserIDs:@[user1UUID]
                                                            isArchived:NO
                                                           archivedRef:nil
                                                            isSilenced:NO
                                                           silencedRef:nil
                                                        silencedStatus:@(MutedMessageOptionValueAll)
                                                                teamID:nil
                                                            accessMode:@[]
                                                            accessRole:@"team"
                                                           receiptMode:1];
        
        // when
        [conversation updateWithTransportData:payload serverTimeStamp:serverTimestamp];
        
        // then
        XCTAssertTrue(conversation.hasReadReceiptsEnabled);
    }];
}

- (void)testThatItDoesntInsertReadReceiptSystemMessageTransportDataWithReceiptModeForNewConversation
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSDate *serverTimestamp = [NSDate date];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        
        NSUUID *user1UUID = [NSUUID createUUID];
        
        NSDictionary *payload = [self payloadForMetaDataOfConversation:conversation
                                                      conversationType:ZMBackendConversationTypeGroup
                                                         activeUserIDs:@[user1UUID]
                                                            isArchived:NO
                                                           archivedRef:nil
                                                            isSilenced:NO
                                                           silencedRef:nil
                                                        silencedStatus:@(MutedMessageOptionValueAll)
                                                                teamID:nil
                                                            accessMode:@[]
                                                            accessRole:@"team"
                                                           receiptMode:1];
        
        // when
        [conversation updateWithTransportData:payload serverTimeStamp:serverTimestamp];
        
        // then
        XCTAssertEqual(conversation.allMessages.count, 0);
    }];
}

- (void)testThatItInsertReadReceiptSystemMessageTransportDataWithReceiptModeForExistingConversation
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSDate *serverTimestamp = [NSDate date];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        [conversation appendMessageWithText:@"hello"];
        
        NSUUID *user1UUID = [NSUUID createUUID];
        
        NSDictionary *payload = [self payloadForMetaDataOfConversation:conversation
                                                      conversationType:ZMBackendConversationTypeGroup
                                                         activeUserIDs:@[user1UUID]
                                                            isArchived:NO
                                                           archivedRef:nil
                                                            isSilenced:NO
                                                           silencedRef:nil
                                                        silencedStatus:@(MutedMessageOptionValueAll)
                                                                teamID:nil
                                                            accessMode:@[]
                                                            accessRole:@"team"
                                                           receiptMode:1];
        
        // when
        [conversation updateWithTransportData:payload serverTimeStamp:serverTimestamp];
        
        // then
        ZMSystemMessage *systemMessage = (ZMSystemMessage *)conversation.lastMessage;
        XCTAssertEqual(systemMessage.systemMessageType, ZMSystemMessageTypeReadReceiptsOn);
    }];
}

- (void)testThatUpdatingFromTransportDataDoesNotSetAnyLocalModifiedKey
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        conversation.archivedChangedTimestamp = [NSDate date];
        conversation.silencedChangedTimestamp = [NSDate date];

        NSUUID *user1UUID = [NSUUID createUUID];
        NSUUID *user2UUID = [NSUUID createUUID];
        NSUUID *user3UUID = [NSUUID createUUID];
        
        NSDictionary *payload = [self payloadForMetaDataOfConversation:conversation activeUserIDs:@[user1UUID, user2UUID, user3UUID]];
        // when
        [conversation updateWithTransportData:payload serverTimeStamp:nil];
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
            [conversation updateWithTransportData:payload serverTimeStamp:nil];
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
        NSString *selfRemoteId = [ZMUser selfUserInContext:conversation.managedObjectContext].remoteIdentifier.transportString;
        NSDictionary *payload = @{
                                  @"name" : [NSNull null],
                                  @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                                  @"members" : @{
                                          @"self" : @{
                                                  @"id" : selfRemoteId
                                                  },
                                          },
                                  @"type" : @1,
                                  @"id" : [uuid transportString]
                                  };
        
        // when
        [self performPretendingUiMocIsSyncMoc:^{
            [self performIgnoringZMLogError:^{
                [conversation updateWithTransportData:payload serverTimeStamp:nil];
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
                                  @"name" : [NSNull null],
                                  @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                                  @"members" : @{
                                          @"others" : @[]
                                          },
                                  @"type" : @1,
                                  @"id" : [uuid UUIDString]
                                  };
        
        // when
        [self performPretendingUiMocIsSyncMoc:^{
            [self performIgnoringZMLogError:^{
                [conversation updateWithTransportData:payload serverTimeStamp:nil];
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
                                  @"name" : @5,
                                  @"creator" : @6,
                                  @"members" : @8,
                                  @"type" : @"goo",
                                  @"id" : @100
                                  };
        
        // when
        [self performPretendingUiMocIsSyncMoc:^{
            [self performIgnoringZMLogError:^{
                [conversation updateWithTransportData:payload serverTimeStamp:nil];
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
                                  @"name" : [NSNull null],
                                  @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                                  @"members" : @{
                                          @"others" : @3
                                          },
                                  @"type" : @1,
                                  @"id" : [uuid UUIDString]
                                  };
        
        // when
        [self performPretendingUiMocIsSyncMoc:^{
            [self performIgnoringZMLogError:^{
                [conversation updateWithTransportData:payload serverTimeStamp:nil];
            }];
        }];
        
        // then
        XCTAssertNotNil(conversation);
    }];
}

- (void)testThatItParsesTheMessageTimer
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSUUID *uuid = NSUUID.createUUID;
        conversation.remoteIdentifier = uuid;
        NSDictionary *payload = @{
                                  @"name" : [NSNull null],
                                  @"creator" : @"3bc5750a-b965-40f8-aff2-831e9b5ac2e9",
                                  @"members" : @{
                                          @"others" : @3
                                          },
                                  @"message_timer": @31536000000,
                                  @"type" : @1,
                                  @"id" : [uuid UUIDString]
                                  };
        
        // when
        [self performPretendingUiMocIsSyncMoc:^{
            [self performIgnoringZMLogError:^{
                [conversation updateWithTransportData:payload serverTimeStamp:nil];
            }];
        }];
        
        // then
        XCTAssertNotNil(conversation);
        XCTAssertEqual(conversation.messageDestructionTimeoutValue, 31536000);
    }];
}

@end




