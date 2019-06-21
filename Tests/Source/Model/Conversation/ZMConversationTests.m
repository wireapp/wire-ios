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

#import "ZMConversationTests.h"
#import "ZMUser.h"
#import "ZMConversation+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMConversationList+Internal.h"
#import "ZMConnection+Internal.h"
#import "ZMConversation+Internal.h"
#import "ZMConversationList+Internal.h"
#import "ZMClientMessage.h"
#import "ZMConversation+UnreadCount.h"
#import "ZMConversation+Transport.h"


@interface ZMConversationTestsBase ()

@property (nonatomic) NSMutableArray *receivedNotifications;

- (ZMConversation *)insertConversationWithParticipants:(NSArray *)participants;
- (NSDate *)timeStampForSortAppendMessageToConversation:(ZMConversation *)conversation;

- (ZMMessage *)insertDownloadedMessageAfterMessageIntoConversation:(ZMConversation *)conversation;
- (ZMMessage *)insertDownloadedMessageIntoConversation:(ZMConversation *)conversation;

@end


@implementation ZMConversationTestsBase

- (void)tearDown
{
    self.receivedNotifications = nil;
    [super tearDown];
}

- (void)didReceiveWindowNotification:(NSNotification *)notification
{
    self.lastReceivedNotification = notification;
}

- (id)mockUserSessionWithUIMOC;
{
    id userSession = [OCMockObject mockForProtocol:@protocol(ZMManagedObjectContextProvider)];
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
{
    __block NSManagedObjectID *objectID;
    [self.syncMOC performGroupedBlockAndWait:^{
        
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        
        NSArray *syncParticipants = [[participants mapWithBlock:^id(ZMUser *user){
            return [self.syncMOC objectWithID:user.objectID];
        }] filterWithBlock:^BOOL(ZMUser *user){
            return user != selfUser;
        }];
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:syncParticipants];
        conversation.conversationType = ZMConversationTypeGroup;
        conversation.remoteIdentifier = NSUUID.createUUID;
        [self.syncMOC saveOrRollback];
        objectID = conversation.objectID;
    }];
    
    return (ZMConversation *)[self.uiMOC objectWithID:objectID];
}

- (NSDate *)timeStampForSortAppendMessageToConversation:(ZMConversation *)conversation
{
    if (conversation.lastServerTimeStamp == nil) {
        conversation.lastServerTimeStamp = [NSDate date];
    }
    ZMMessage *message = [[ZMMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:conversation.managedObjectContext];
    message.serverTimestamp = [conversation.lastServerTimeStamp dateByAddingTimeInterval:5];
    message.visibleInConversation = conversation;
    conversation.lastServerTimeStamp = message.serverTimestamp;
    return message.serverTimestamp;
}


- (ZMMessage *)insertDownloadedMessageIntoConversation:(ZMConversation *)conversation
{
    NSDate *newTime = conversation.lastServerTimeStamp ? [conversation.lastServerTimeStamp dateByAddingTimeInterval:5] : [NSDate date];
    
    ZMTextMessage *message = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message.serverTimestamp = newTime;
    conversation.lastServerTimeStamp = message.serverTimestamp;
    [conversation.mutableMessages addObject:message];
    return message;
}

- (ZMMessage *)insertDownloadedMessageAfterMessageIntoConversation:(ZMConversation *)conversation
{
    NSDate *newTime = conversation.lastServerTimeStamp ? [conversation.lastServerTimeStamp dateByAddingTimeInterval:5] : [NSDate date];
    
    ZMTextMessage *message = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];;
    message.serverTimestamp = newTime;
    conversation.lastServerTimeStamp = message.serverTimestamp;
    [conversation.mutableMessages addObject:message];
    return message;
}

- (ZMSystemMessage *)insertNonUnreadDotGeneratingMessageIntoConversation:(ZMConversation *)conversation
{
    NSDate *newTime = conversation.lastServerTimeStamp ? [conversation.lastServerTimeStamp dateByAddingTimeInterval:5] : [NSDate date];
    
    ZMSystemMessage *systemMessage = [[ZMSystemMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:conversation.managedObjectContext];
    systemMessage.serverTimestamp = newTime;
    systemMessage.systemMessageType = ZMSystemMessageTypeNewClient;
    [conversation.mutableMessages addObject:systemMessage];
    
    return systemMessage;
}

- (ZMConversation *)insertConversationWithUnread:(BOOL)hasUnread
{
    NSDate *messageDate = [NSDate dateWithTimeIntervalSince1970:230000000];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
    conversation.conversationType = ZMConversationTypeOneOnOne;
    conversation.lastServerTimeStamp = messageDate;
    if(hasUnread) {
        ZMClientMessage *message = [[ZMClientMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.syncMOC];
        message.serverTimestamp = messageDate;
        conversation.lastReadServerTimeStamp = [messageDate dateByAddingTimeInterval:-1000];
        [conversation appendMessage:message];
    }
    [self.syncMOC saveOrRollback];
    return conversation;
}

@end




@interface ZMConversationTests : ZMConversationTestsBase

@end



@implementation ZMConversationTests

- (void)testThatItSetsTheSelfUserAsCreatorWhenCreatingAGroupConversationFromTheUI
{
    // given
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    ZMUser *otherUser1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *otherUser2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:@[otherUser1, otherUser2]];
    
    // then
    XCTAssertEqualObjects(conversation.creator, selfUser);
}

- (void)testThatItSetsReceiptModeWhenCreatingAGroupConversationInATeam
{
    // given
    ZMUser *otherUser1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *otherUser2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    Team *team = [Team insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:@[otherUser1, otherUser2] name:@"abc" inTeam:team allowGuests:NO readReceipts:YES];
    
    // then
    XCTAssertTrue(conversation.hasReadReceiptsEnabled);
}

- (void)testThatItReceiptModeIsIgnoredWhenCreatingAGroupConversationWithoutATeam
{
    // given
    ZMUser *otherUser1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *otherUser2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.uiMOC withParticipants:@[otherUser1, otherUser2] name:@"abc" inTeam:nil allowGuests:NO readReceipts:YES];
    
    // then
    XCTAssertFalse(conversation.hasReadReceiptsEnabled);
}

- (void)testThatItHasLocallyModifiedDataFields
{
    XCTAssertTrue([ZMConversation isTrackingLocalModifications]);
    NSEntityDescription *entity = self.uiMOC.persistentStoreCoordinator.managedObjectModel.entitiesByName[ZMConversation.entityName];
    XCTAssertNotNil(entity.attributesByName[@"modifiedKeys"]);
}

- (void)testThatItIgnoresModifiedDisplayNameWhenInserting
{
    // Given
    ZMConversation *sut = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    sut.userDefinedName = @"Name";
    
    // When
    XCTAssert(sut.isInserted);
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // Then
    XCTAssertFalse([sut.keysThatHaveLocalModifications containsObject:ZMConversationUserDefinedNameKey]);
}

- (void)testThatItDoesNotIgnoreAModifiedDisplayNameWhenNotInserting
{
    // Given
    ZMConversation *sut = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    XCTAssert([self.uiMOC saveOrRollback]);
    XCTAssertFalse(sut.isInserted);
    
    // When
    sut.userDefinedName = @"Name";
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // Then
    XCTAssert([sut.keysThatHaveLocalModifications containsObject:ZMConversationUserDefinedNameKey]);
}

- (void)testThatWeCanSetAttributesOnConversation
{
    [self checkConversationAttributeForKey:@"draftMessage" value:[[DraftMessage alloc] initWithText:@"My draft message text" mentions:@[] quote:nil]];
    [self checkConversationAttributeForKey:ZMConversationUserDefinedNameKey value:@"Foo"];
    [self checkConversationAttributeForKey:@"normalizedUserDefinedName" value:@"Foo"];
    [self checkConversationAttributeForKey:@"conversationType" value:@(1)];
    [self checkConversationAttributeForKey:@"lastModifiedDate" value:[NSDate dateWithTimeIntervalSince1970:123456]];
    [self checkConversationAttributeForKey:@"remoteIdentifier" value:[NSUUID createUUID]];
    [self checkConversationAttributeForKey:ZMConversationIsArchivedKey value:@YES];
    [self checkConversationAttributeForKey:ZMConversationIsArchivedKey value:@NO];
    [self checkConversationAttributeForKey:ZMConversationIsSelfAnActiveMemberKey value:@YES];
    [self checkConversationAttributeForKey:ZMConversationIsSelfAnActiveMemberKey value:@NO];
    [self checkConversationAttributeForKey:@"needsToBeUpdatedFromBackend" value:@YES];
    [self checkConversationAttributeForKey:@"needsToBeUpdatedFromBackend" value:@NO];
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
                          ZMConversationIsSelfAnActiveMemberKey,
                          ZMConversationLastReadServerTimeStampKey,
                          ZMConversationClearedTimeStampKey,
                          ZMConversationSilencedChangedTimeStampKey,
                          ZMConversationArchivedChangedTimeStampKey,
                          ]];
    
    // when
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];

    // then
    XCTAssertEqualObjects(conversation.keysTrackedForLocalModifications, expected);
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
    [conversation setLocallyModifiedKeys:[NSSet setWithObject:ZMConversationArchivedChangedTimeStampKey]];
    
    NSPredicate *predicate = [ZMConversation predicateForObjectsThatNeedToBeUpdatedUpstream];
    
    // then
    XCTAssertTrue([predicate evaluateWithObject:conversation]);
}

- (void)testThatItRemovesAndAppendsTheMessageWhenResortingWithUpdatedMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *message1 = (id)[conversation appendMessageWithText:@"hallo"];
    message1.serverTimestamp = [NSDate dateWithTimeIntervalSinceNow:-50];
    ZMMessage *message2 = (id)[conversation appendMessageWithText:@"hallo"];
    message2.serverTimestamp = [NSDate dateWithTimeIntervalSinceNow:-40];
    ZMMessage *message3 = (id)[conversation appendMessageWithText:@"hallo"];
    message3.serverTimestamp = [NSDate dateWithTimeIntervalSinceNow:-30];

    NSOrderedSet *messages = [NSOrderedSet orderedSetWithArray:@[message3, message2, message1]];
    XCTAssertEqualObjects(messages, [NSOrderedSet orderedSetWithArray:[conversation lastMessagesWithLimit:10]]);
    
    // when
    message1.serverTimestamp = [NSDate date];
    [self.uiMOC processPendingChanges];
    
    // then
    NSOrderedSet *expectedMessages = [NSOrderedSet orderedSetWithArray:@[message1, message3, message2]];
    XCTAssertEqualObjects(expectedMessages, [NSOrderedSet orderedSetWithArray:[conversation lastMessagesWithLimit:10]]);
}

- (void)testThatItUsesServerTimestampWhenResortingWithUpdatedMessage
{
    // given
    NSDate *date1 = [NSDate dateWithTimeIntervalSinceReferenceDate:2000];
    NSDate *date2 = [NSDate dateWithTimeIntervalSinceReferenceDate:3000];
    NSDate *date3 = [NSDate dateWithTimeIntervalSinceReferenceDate:4000];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *message1 = (id)[conversation appendMessageWithText:@"hallo 1"];
    message1.serverTimestamp = date1;
    ZMMessage *message2 = (id)[conversation appendMessageWithText:@"hallo 2"];
    message2.serverTimestamp = date3;
    ZMMessage *message3 = (id)[conversation appendMessageWithText:@"hallo 3"];
    
    NSOrderedSet *messages = [NSOrderedSet orderedSetWithArray:@[message3, message2, message1]];
    XCTAssertEqualObjects(messages, [NSOrderedSet orderedSetWithArray:[conversation lastMessagesWithLimit:10]]);
    
    // when
    message3.serverTimestamp = date2;
    [self.uiMOC processPendingChanges];

    // then
    NSOrderedSet *expectedMessages = [NSOrderedSet orderedSetWithArray:@[message2, message3, message1]];
    XCTAssertEqualObjects(expectedMessages, [NSOrderedSet orderedSetWithArray:[conversation lastMessagesWithLimit:10]]);
}

- (void)testThatLastModifiedDateOfTheConversationGetsUpdatedWhenAMessageIsInserted
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastModifiedDate = [NSDate dateWithTimeIntervalSinceReferenceDate:1000];
    
    // when
    [conversation appendMessageWithText:@"foo"];
    
    // then
    AssertDateIsRecent(conversation.lastModifiedDate);
}


- (void)testThatItCreatesAMessageWithLongText
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    NSString *longText = [@"" stringByPaddingToLength:ZMConversationMaxTextMessageLength + 1000 withString:@"😋" startingAtIndex:0];
    
    // then
    id<ZMConversationMessage> message = (id)[conversation appendMessageWithText:longText];

    XCTAssertEqualObjects(message.textMessageData.messageText, longText);
    XCTAssertEqual(conversation.allMessages.count, 1lu);
}

- (void)testThatItRejectsWhitespaceOnlyText
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    NSString *whiteSpaceString = @"      ";
    
    // when
    [self performIgnoringZMLogError:^{
        [conversation appendMessageWithText:whiteSpaceString];
    }];
    
    // then    
    XCTAssertEqual(conversation.allMessages.count, 0u);
}


- (void)testThatItDoesNotRejectNonWhitespaceOnlyText
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    NSString *someString = @"some string";
    
    // when
    [conversation appendMessageWithText:someString];
    
    // then
    XCTAssertEqual(conversation.allMessages.count, 1u);
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
    ZMMessage *message = (id)[sut appendMessageWithText:@"Quux"];

    // then
    XCTAssertNotNil(message.expirationDate);
    NSDate *expectedDate = [NSDate dateWithTimeIntervalSinceNow:[ZMMessage defaultExpirationTime]];
    XCTAssertLessThan(fabs([message.expirationDate timeIntervalSinceDate:expectedDate]), 1);
}



- (void)testThatItDeletesCachedValueForRemoteIDAfterAwakingFromSnapshotEvents
{
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    
    [conversation willAccessValueForKey:@"remoteIdentifier"];
    NSUUID *cachedRemoteID = [conversation primitiveValueForKey:@"remoteIdentifier"];
    [conversation didAccessValueForKey:@"remoteIdentifier"];
    
    XCTAssertEqualObjects(cachedRemoteID, conversation.remoteIdentifier);
    
    // when
    
    [conversation awakeFromSnapshotEvents:NSSnapshotEventUndoUpdate];
    
    [conversation willAccessValueForKey:@"remoteIdentifier"];
    NSUUID *cachedIDAfterDeleting = [conversation primitiveValueForKey:@"remoteIdentifier"];
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
    conversation.draftMessage = [[DraftMessage alloc] initWithText:mutableValue mentions:@[] quote:nil];
    [mutableValue appendString:@".uk"];
    
    // then
    XCTAssertEqualObjects(conversation.draftMessage.text, originalValue);
}

- (void)testThatItSavesQuotesNonce
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *message = (id)[conversation appendMessageWithText:@"Test"];
    
    // when
    conversation.draftMessage = [[DraftMessage alloc] initWithText:@"Draft Test" mentions:@[] quote:message];

    [self.uiMOC saveOrRollback];
    
    // then
    ZMMessage *quote = conversation.draftMessage.quote;
    NSUUID *draftNonce = quote.nonce;
    NSUUID *messageNonce = message.nonce;
    XCTAssertNotNil(draftNonce);
    XCTAssertNotNil(messageNonce);
    XCTAssertEqualObjects(draftNonce, messageNonce);
}
    
- (void)addNotification:(NSNotification *)note
{
    [self.receivedNotifications addObject:note];
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

- (void)testThatItDoesNotUpdateLastModifiedDateWithLocalSystemMessages
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastModifiedDate = [NSDate.date dateByAddingTimeInterval:-100];
    ZMMessage *firstMessage = (id)[conversation appendMessageWithText:@"Test Message"];
    
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, firstMessage.serverTimestamp);
 
    // when
    NSDate *future = [NSDate.date dateByAddingTimeInterval:100];
    [conversation appendNewPotentialGapSystemMessageWithUsers:nil timestamp:future];
    
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, firstMessage.serverTimestamp);
    XCTAssertEqual(conversation.allMessages.count, 2lu);
}

- (void)testThatItUpdatesLastModifiedDateWithMessageServerTimestamp_ClientMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastModifiedDate = [NSDate.date dateByAddingTimeInterval:-100];
    ZMClientMessage *clientMessage = (id)[conversation appendText:@"TestMessage" mentions:@[] replyingToMessage:nil fetchLinkPreview:YES nonce:NSUUID.createUUID];
    
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
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastModifiedDate = [NSDate.date dateByAddingTimeInterval:-100];
    ZMClientMessage *clientMessage = (id)[conversation appendText:@"TestMessage" mentions:@[] replyingToMessage:nil fetchLinkPreview:YES nonce:NSUUID.createUUID];
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
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastModifiedDate = [NSDate.date dateByAddingTimeInterval:-100];
    ZMMessage *firstMessage = (id)[conversation appendMessageWithText:@"Test Message"];
    
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, firstMessage.serverTimestamp);
    
    NSDate *serverDate = [firstMessage.serverTimestamp dateByAddingTimeInterval:0.2];
    // when
    [firstMessage updateWithPostPayload:@{@"time": serverDate, @"data": @{@"nonce": firstMessage.nonce}, @"type": @"conversation.message-add"} updatedKeys:[NSSet set]];
    
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, serverDate);
    XCTAssertEqualObjects(firstMessage.serverTimestamp, serverDate);
}

- (void)testThatItDoesNotUpdatesLastModifiedDateWithMessageServerTimestampIfNotNeeded_PlaintextMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastModifiedDate = [NSDate.date dateByAddingTimeInterval:-100];
    ZMMessage *firstMessage = (id)[conversation appendMessageWithText:@"Test Message"];
    
    NSDate *postingDate = firstMessage.serverTimestamp;
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, firstMessage.serverTimestamp);
    
    NSDate *serverDate = [firstMessage.serverTimestamp dateByAddingTimeInterval:-0.2];
    // when
    [firstMessage updateWithPostPayload:@{@"time": serverDate, @"data": @{@"nonce": firstMessage.nonce}, @"type": @"conversation.message-add"} updatedKeys:[NSSet set]];
    
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, postingDate);
    XCTAssertEqualObjects(firstMessage.serverTimestamp, serverDate);
}

- (void)testThatItUpdatesExpectsReadConfirmationWithMessageServerTimestamp_PlaintextMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.hasReadReceiptsEnabled = YES;
    ZMOTRMessage *firstMessage = (id)[conversation appendMessageWithText:@"Test Message"];
    
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, firstMessage.serverTimestamp);
    
    NSDate *serverDate = [firstMessage.serverTimestamp dateByAddingTimeInterval:0.2];
    // when
    [firstMessage updateWithPostPayload:@{@"time": serverDate, @"data": @{@"nonce": firstMessage.nonce}, @"type": @"conversation.message-add"} updatedKeys:[NSSet set]];
    
    // then
    XCTAssertTrue(firstMessage.expectsReadConfirmation);
}

- (void)testThatItDoesNotUpdatesExpectsReadConfirmationWithMessageServerTimestampIfNotNeeded_PlaintextMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.hasReadReceiptsEnabled = NO;
    ZMOTRMessage *firstMessage = (id)[conversation appendMessageWithText:@"Test Message"];
    
    // then
    XCTAssertEqualObjects(conversation.lastModifiedDate, firstMessage.serverTimestamp);
    
    NSDate *serverDate = [firstMessage.serverTimestamp dateByAddingTimeInterval:-0.2];
    // when
    [firstMessage updateWithPostPayload:@{@"time": serverDate, @"data": @{@"nonce": firstMessage.nonce}, @"type": @"conversation.message-add"} updatedKeys:[NSSet set]];
    
    // then
    XCTAssertFalse(firstMessage.expectsReadConfirmation);
}

@end // general


@implementation ZMConversationTests (GroupOneToOne)

- (void)testThatGroupConversationInTeamWithOnlyTwoParticipantsIsConsideredOneToOne
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.teamRemoteIdentifier = [NSUUID createUUID];
    [conversation internalAddParticipants:@[user1]];
    
    // then
    XCTAssertEqual(conversation.conversationType, ZMConversationTypeOneOnOne);
}

- (void)testThatGroupConversationInTeamWithOnlyBotIsConsideredGroup
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user1.providerIdentifier = [[NSUUID createUUID] transportString];
    user1.serviceIdentifier = [[NSUUID createUUID] transportString];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.teamRemoteIdentifier = [NSUUID createUUID];
    [conversation internalAddParticipants:@[user1]];
    
    // then
    XCTAssertEqual(conversation.conversationType, ZMConversationTypeGroup);
}

- (void)testThatGroupConversationWithNameInTeamWithOnlyTwoParticipantsIsNotConsideredOneToOne
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.userDefinedName = @"Some conversation";
    conversation.teamRemoteIdentifier = [NSUUID createUUID];
    [conversation internalAddParticipants:@[user1]];
    
    // then
    XCTAssertEqual(conversation.conversationType, ZMConversationTypeGroup);
}

- (void)testThatGroupConversationInTeamWithMoreThanTwoParticipantsIsNotConsideredOneToOne
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.teamRemoteIdentifier = [NSUUID createUUID];
    [conversation internalAddParticipants:@[user1, user2]];
    
    // then
    XCTAssertEqual(conversation.conversationType, ZMConversationTypeGroup);
}

- (void)testThatGroupConversationInPersonalSpaceWithOnlyTwoParticipantsIsNotConsideredOneToOne
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    [conversation internalAddParticipants:@[user1]];
    
    // then
    XCTAssertEqual(conversation.conversationType, ZMConversationTypeGroup);
}

- (void)testThatOneToOneConversationInTeamReturnsAConnectedUser
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.teamRemoteIdentifier = [NSUUID createUUID];
    [conversation internalAddParticipants:@[user1]];
    
    // then
    XCTAssertEqual(conversation.connectedUser, user1);
}

- (void)testThatGroupConversationWithOnlyTwoParticipantsDoesNotReturnAConnectedUser
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    [conversation internalAddParticipants:@[user1]];
    
    // then
    XCTAssertNil(conversation.connectedUser);
}

@end



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
    [conversation.mutableLastServerSyncedActiveParticipants addObject:user];
    [conversation.mutableLastServerSyncedActiveParticipants addObject:[ZMUser selfUserInContext:self.uiMOC]];
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
    [conversation.mutableLastServerSyncedActiveParticipants addObject:user1];
    [conversation.mutableLastServerSyncedActiveParticipants addObject:user2];
    [conversation.mutableLastServerSyncedActiveParticipants addObject:[ZMUser selfUserInContext:self.uiMOC]];
    [self.uiMOC saveOrRollback];
    
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
    [conversation.mutableLastServerSyncedActiveParticipants addObjectsFromArray:@[user1, user2, user3, user4]];
    [conversation.mutableLastServerSyncedActiveParticipants addObject:[ZMUser selfUserInContext:self.uiMOC]];
    [self.uiMOC saveOrRollback];
    
    NSString *expected = @"Bar, Baz";
    
    // when
    conversation.userDefinedName = nil;
    
    // then
    XCTAssertEqualObjects(conversation.displayName, expected);
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

- (void)testThatTheDisplayNameForGroupConversationWithoutParticipantsIsTheEmptyGroupConversationName;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    [self.uiMOC saveOrRollback];

    // then
    XCTAssertEqualObjects(conversation.displayName, @"conversation.displayname.emptygroup");
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
    [conversation.mutableLastServerSyncedActiveParticipants addObject:user];
    [conversation.mutableLastServerSyncedActiveParticipants addObject:selfUser];
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

- (void)testThatExtremeCombiningCharactersAreRemovedFromTheName
{
    // GIVEN
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    [self.uiMOC saveOrRollback];
    
    // WHEN
    conversation.userDefinedName = @"ť̹̱͉̥̬̪̝ͭ͗͊̕e͇̺̳̦̫̣͕ͫͤ̅s͇͎̟͈̮͎̊̾̌͛ͭ́͜t̗̻̟̙͑ͮ͊ͫ̂";

    // THEN
    XCTAssertEqualObjects(conversation.userDefinedName, @"test̻̟̙");
}

@end


@implementation ZMConversationTests (SettingLastReadMessage)

- (void)testThatItSetsTheLastReadServerTimeStampToTheLastReadMessageInTheVisibleRange;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastReadTimestampSaveDelay = 0.1;
    ZMMessage *message = [self insertDownloadedMessageIntoConversation:conversation];
    ZMMessage *messageToBeMarkedAsRead;
    for (int i = 0; i < 10; ++i) {
        message = [self insertDownloadedMessageAfterMessageIntoConversation:conversation];
        
        if (i == 4) {
            messageToBeMarkedAsRead = message;
        }
    }
    
    // when
    [conversation markMessagesAsReadUntil:messageToBeMarkedAsRead];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(conversation.lastReadServerTimeStamp, messageToBeMarkedAsRead.serverTimestamp);
}

- (void)testThatItSetsTheLastReadServerTimestampToTheLastReadMessageInTheVisibleRangeEvenIfSystemMessage;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastReadTimestampSaveDelay = 0.1;
    ZMMessage *message = [self insertDownloadedMessageIntoConversation:conversation];
    for (int i = 0; i < 10; ++i) {
        message = [self insertDownloadedMessageAfterMessageIntoConversation:conversation];
    }
    
    message = [self insertNonUnreadDotGeneratingMessageIntoConversation:conversation];
    conversation.lastServerTimeStamp = message.serverTimestamp;
    
    // when
    [conversation markMessagesAsReadUntil:message];
    
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(conversation.lastReadServerTimeStamp, message.serverTimestamp);
}


- (void)testThatItSavesTheLastReadServerTimeStampBeforeDelayedDispatchEnds;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastReadTimestampSaveDelay = 2.0;
    ZMMessage *message = [self insertDownloadedMessageIntoConversation:conversation];
    ZMMessage *messageToBeMarkedAsRead;
    for (int i = 0; i < 10; ++i) {
        message = [self insertDownloadedMessageAfterMessageIntoConversation:conversation];
        
        if (i == 4) {
            messageToBeMarkedAsRead = message;
        }
    }
    
    // when
    [conversation markMessagesAsReadUntil:messageToBeMarkedAsRead];
    [conversation savePendingLastRead];
    
    // then
    XCTAssertEqualObjects(conversation.lastReadServerTimeStamp, messageToBeMarkedAsRead.serverTimestamp);
}

- (void)testThatItDoesNotUpdateTheLastReadMessageToAnOlderMessage;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastReadTimestampSaveDelay = 0.1;
    
    ZMMessage *message = [self insertDownloadedMessageIntoConversation:conversation];
    ZMMessage *messageToBeMarkedAsRead;
    for (int i = 0; i < 10; ++i) {
        message = [self insertDownloadedMessageAfterMessageIntoConversation:conversation];
        
        if (i == 4) {
            messageToBeMarkedAsRead = message;
        }
    }
    
    NSDate *originalLastReadTimeStamp = message.serverTimestamp;
    conversation.lastReadServerTimeStamp = originalLastReadTimeStamp;
    
    // when
    [conversation markMessagesAsReadUntil:messageToBeMarkedAsRead];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqualObjects(conversation.lastReadServerTimeStamp, originalLastReadTimeStamp);
}

- (void)testThatItSetsTheLastReadServerTimeStampToTheTimestampOfTheLastMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastReadTimestampSaveDelay = 0.1;

    ZMMessage *message = [self insertDownloadedMessageIntoConversation:conversation];
    for (int i = 0; i < 3; ++i) {
        message = [self insertDownloadedMessageAfterMessageIntoConversation:conversation];
    }

    // when
    [conversation markMessagesAsReadUntil:conversation.lastMessage];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqualObjects(conversation.lastReadServerTimeStamp, message.serverTimestamp);
}

- (void)testThatItCannotMarkAsUnreadEmptyConversation;
{
    // GIVEN
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    conversation.remoteIdentifier = NSUUID.createUUID;
    // WHEN & THEN
    XCTAssertFalse([conversation canMarkAsUnread]);
}

- (void)testThatItCanMarkAsUnreadAConversation;
{
    // GIVEN
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    conversation.remoteIdentifier = NSUUID.createUUID;
    ZMMessage *message = [self insertDownloadedMessageAfterMessageIntoConversation:conversation];
    message.sender = self.createUser;
    [conversation markAsRead];
    // WHEN & THEN
    XCTAssertTrue([conversation canMarkAsUnread]);
}

- (void)testThatItMarksTheMessagesAsUnread;
{
    // GIVEN
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeConnection;
    conversation.remoteIdentifier = NSUUID.createUUID;

    [self.uiMOC saveOrRollback];

    ZMMessage* unreadMessage = [self insertDownloadedMessageAfterMessageIntoConversation:conversation];
    unreadMessage.sender = self.createUser;
    [conversation markAsRead];
    XCTAssertTrue([self waitForAllGroupsToBeEmptyWithTimeout:0.5]);
    XCTAssertEqual(conversation.firstUnreadMessage, nil);

    // WHEN
    [conversation markAsUnread];
    XCTAssertTrue([self waitForAllGroupsToBeEmptyWithTimeout:0.5]);
    
    // THEN
    XCTAssertEqual(conversation.firstUnreadMessage, unreadMessage);
}

- (void)testThatItResetsHasUnreadUnsentMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMMessage *message1 = (id)[conversation appendMessageWithText:@"haha"];
    ZMMessage *message2 = (id)[conversation appendMessageWithText:@"haha"];
    [message2 expire];
    
    XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorExpiredMessage);
    [self.uiMOC saveOrRollback];
    
    conversation.lastServerTimeStamp = message1.serverTimestamp;
    
    // when
    [conversation markMessagesAsReadUntil:message2];
    WaitForAllGroupsToBeEmpty(1.0);
    
    // then
    XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorNone);
}

- (void)testThatItResetsHasUnreadUnsentMessageWhenThereAreAdditionalSentMessages
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    [conversation appendMessageWithText:@"haha"];
    ZMMessage *message2 = (id)[conversation appendMessageWithText:@"haha"];
    [message2 expire];
    ZMMessage *message3 = (id)[conversation appendMessageWithText:@"haha"];
    
    XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorExpiredMessage);
    [self.uiMOC saveOrRollback];
    
    conversation.lastServerTimeStamp = message3.serverTimestamp;
    
    // when
    [conversation markMessagesAsReadUntil:message2];
    WaitForAllGroupsToBeEmpty(1.0);
    
    // then
    XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorNone);
}

@end

@implementation ZMConversationTests (LastEditableMessage)

- (void)testThatItReturnsNilIfConversationHasNoMessages;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    // No messages
    
    // then
    XCTAssertNil(conversation.lastEditableMessage);
}

- (void)testThatItReturnsNilIfLastMessageIsNotTextAndSentBySelfUser;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    [conversation appendKnock];

    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertNil(conversation.lastEditableMessage);
}

- (void)testThatItReturnsNilIfLastMessageIsTextAndNotSentBySelfUser;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMUser *sender = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    sender.remoteIdentifier = [NSUUID createUUID];

    // when
    ZMMessage *message = (id)[conversation appendMessageWithText:@"Test Message"];
    message.sender = sender;
    [message markAsSent];

    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertNil(conversation.lastEditableMessage);
}

- (void)testThatItReturnsNilIfLastMessageIsEditedTextAndNotSentBySelfUser;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = [NSUUID createUUID];
    ZMUser *sender = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    sender.remoteIdentifier = [NSUUID createUUID];
    
    // when
    ZMMessage *message = (id)[conversation appendMessageWithText:@"Test Message"];
    message.sender = sender;
    [message markAsSent];
    
    ZMGenericMessage *genericMessage = [ZMGenericMessage messageWithContent:[ZMMessageEdit editWith:[ZMText textWith:@"Edited Test Message" mentions:@[] linkPreviews:@[] replyingTo:nil] replacingMessageId:message.nonce] nonce:NSUUID.createUUID];
    NSDictionary *payload = @{
                              @"conversation": conversation.remoteIdentifier.transportString,
                              @"from": message.sender.remoteIdentifier.transportString,
                              @"time": [NSDate date].transportString,
                              @"data": @{
                                      @"text": genericMessage.data.base64String
                                      },
                              @"type": @"conversation.otr-message-add"
                              };
    ZMUpdateEvent *updateEvent =  [ZMUpdateEvent eventFromEventStreamPayload:payload uuid:[NSUUID createUUID]];

    __block ZMClientMessage *newMessage;
    
    [self performPretendingUiMocIsSyncMoc:^{
        newMessage = [ZMClientMessage createOrUpdateMessageFromUpdateEvent:updateEvent inManagedObjectContext:self.uiMOC prefetchResult:nil];
    }];

    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertNil(conversation.lastEditableMessage);
    XCTAssertNotNil(newMessage);
}

- (void)testThatItReturnsMessageIfLastMessageIsEditedTextAndSentBySelfUser;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    ZMMessage *message = (id)[conversation appendMessageWithText:@"Test Message"];
    message.sender = self.selfUser;
    [message markAsSent];
    [message.textMessageData editText:@"Edited Test Message" mentions:@[] fetchLinkPreview:YES];

    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(conversation.lastEditableMessage, message);
}

- (void)testThatItReturnsMessageIfLastMessageIsTextAndSentBySelfUser;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];

    // when
    ZMMessage *message = (id)[conversation appendMessageWithText:@"Test Message"];
    message.sender = self.selfUser;
    [message markAsSent];

    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(conversation.lastEditableMessage, message);
}

- (void)testThatItReturnsMessageIfLastMessagesAreTextWithPingAndSentBySelfUser;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];

    // when
    ZMMessage *message = (id)[conversation appendMessageWithText:@"Test Message"];
    message.sender = self.selfUser;
    [message markAsSent];
    [conversation appendKnock];

    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqualObjects(conversation.lastEditableMessage, message);
}

- (void)testThatItReturnsLastMessageIfLastMessagesAreTextsAndSentBySelfUser;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    ZMMessage *message = (id)[conversation appendMessageWithText:@"Test Message"];
    message.sender = self.selfUser;
    [message markAsSent];
    ZMMessage *nextMessage = (id)[conversation appendMessageWithText:@"Next Test Message"];
    nextMessage.sender = self.selfUser;
    [nextMessage markAsSent];

    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqualObjects(conversation.lastEditableMessage, nextMessage);
}

- (void)testThatItReturnsMessageIfLastMessagesAreTextAndEphemeral;
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];

    // when
    ZMMessage *message = (id)[conversation appendMessageWithText:@"Test Message"];
    message.sender = self.selfUser;
    [message markAsSent];
    [conversation setLocalMessageDestructionTimeout:15];
    ZMMessage *ephemeralMessage = (id)[conversation appendMessageWithText:@"Ephemeral Test Message"];
    ephemeralMessage.sender = self.selfUser;
    [ephemeralMessage markAsSent];

    WaitForAllGroupsToBeEmpty(0.5);

    // then
    XCTAssertEqualObjects(conversation.lastEditableMessage, message);
}

- (void)testThatItReturnsMessageIfLastMessageIsTextRead
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    ZMMessage *message = (id)[conversation appendMessageWithText:@"Test Message"];
    message.sender = self.selfUser;
    [message markAsSent];

    ZMMessageConfirmation *confirmation = [[ZMMessageConfirmation alloc] initWithContext:self.uiMOC];
    confirmation.type = MessageConfirmationTypeRead;
    
    [[message mutableSetValueForKey:@"confirmations"] addObject:confirmation];
    
    XCTAssertEqual(message.deliveryState, ZMDeliveryStateRead);
    
    // then
    XCTAssertEqualObjects(conversation.lastEditableMessage, message);
}
@end

@implementation ZMConversationTests (Participants)

- (void)testThatItRecalculatesActiveParticipantsWhenOtherActiveParticipantsKeyChanges
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.isSelfAnActiveMember = YES;

    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    [conversation internalAddParticipants:@[user1, user2]];
    
    XCTAssertTrue(conversation.isSelfAnActiveMember);
    XCTAssertEqual(conversation.lastServerSyncedActiveParticipants.count, 2u);
    XCTAssertEqual(conversation.activeParticipants.count, 3u);
    
    // expect
    [self keyValueObservingExpectationForObject:conversation keyPath:@"activeParticipants" expectedValue:nil];
    
    // when

    [conversation internalRemoveParticipants:@[user2] sender:user1];
    
    // then
    XCTAssertTrue(conversation.isSelfAnActiveMember);
    XCTAssertEqual(conversation.lastServerSyncedActiveParticipants.count, 1u);
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
    
    [conversation internalAddParticipants:@[user1, user2]];
    
    XCTAssertTrue(conversation.isSelfAnActiveMember);
    XCTAssertEqual(conversation.lastServerSyncedActiveParticipants.count, 2u);
    XCTAssertEqual(conversation.activeParticipants.count, 3u);
    
    // expect
    [self keyValueObservingExpectationForObject:conversation keyPath:@"activeParticipants" expectedValue:nil];
    
    // when
    conversation.isSelfAnActiveMember = NO;
    
    // then
    XCTAssertFalse(conversation.isSelfAnActiveMember);
    XCTAssertEqual(conversation.lastServerSyncedActiveParticipants.count, 2u);
    XCTAssertEqual(conversation.activeParticipants.count, 2u);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}

@end

@implementation ZMConversationTests (KeyValueObserving)

- (void)testThatItRecalculatesHasDraftMessageWhenDraftMessageTextChanges
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.draftMessage = [[DraftMessage alloc] initWithText:@"This is a test" mentions:@[] quote:nil];
    
    XCTAssertTrue(conversation.hasDraftMessage);
    
    // expect
    [self keyValueObservingExpectationForObject:conversation keyPath:@"hasDraftMessage" expectedValue:nil];
    
    // when
    conversation.draftMessage = nil;
    
    // then
    XCTAssertFalse(conversation.hasDraftMessage);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatItRecalculatesFirstUnreadMessageWhenLastReadServerTimeStampChanges
{
    // given
    ZMTextMessage *message1 = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message1.serverTimestamp = [NSDate date];

    ZMTextMessage *message2 = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message2.serverTimestamp = [NSDate date];

    ZMTextMessage *message3 = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message3.serverTimestamp = [NSDate date];

    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    [conversation.mutableMessages addObject:message1];
    [conversation.mutableMessages addObject:message2];
    [conversation.mutableMessages addObject:message3];

    conversation.lastReadServerTimeStamp = message1.serverTimestamp;

    XCTAssertEqualObjects(conversation.firstUnreadMessage, message2);

    // expect
    [self keyValueObservingExpectationForObject:conversation keyPath:@"firstUnreadMessage" expectedValue:nil];

    // when
    conversation.lastReadServerTimeStamp = message2.serverTimestamp;

    // then
    XCTAssertEqualObjects(conversation.firstUnreadMessage, message3);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatItRecalculatesFirstUnreadMessageWhenMessagesChanges
{
    // given
    ZMTextMessage *message1 = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message1.serverTimestamp = [NSDate date];

    ZMTextMessage *message2 = [[ZMTextMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message2.serverTimestamp = [NSDate date];

    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    [conversation.mutableMessages addObject:message1];

    conversation.lastReadServerTimeStamp = message1.serverTimestamp;


    XCTAssertNil(conversation.firstUnreadMessage);

    // expect
    [self keyValueObservingExpectationForObject:conversation keyPath:@"firstUnreadMessage" expectedValue:nil];

    // when
    [conversation.mutableMessages addObject:message2];

    // then
    XCTAssertEqualObjects(conversation.firstUnreadMessage, message2);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatTheSelfConversationHasTheSameRemoteIdentifierAsTheSelfUser
{
    // given
    NSUUID *selfUserID = [NSUUID createUUID];
    
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        selfUser.remoteIdentifier = selfUserID;
    }];
    
    // when
    __block NSUUID *selfConversationID = nil;
    [self.syncMOC performGroupedBlockAndWait:^{
        selfConversationID = [ZMConversation selfConversationIdentifierInContext:self.syncMOC];
    }];
    
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
    WaitForAllGroupsToBeEmpty(0.5);
    
    NSArray *users = @[user0, user1, selfUser];
    ZMConversation *conversation = [self insertConversationWithParticipants:users];
    [conversation appendMessageWithText:@"0"];
    
    ZMConversationList *activeList = [ZMConversationList conversationsInUserSession:self.mockUserSessionWithUIMOC];
    ZMConversationList *archivedList = [ZMConversationList archivedConversationsInUserSession:self.mockUserSessionWithUIMOC];
    ZMConversationList *clearedList = [ZMConversationList clearedConversationsInUserSession:self.mockUserSessionWithUIMOC];
    
    // when
    [conversation internalRemoveParticipants:@[selfUser] sender:user0];
    
    // then
    XCTAssertTrue([activeList predicateMatchesConversation:conversation]);
    XCTAssertFalse([archivedList predicateMatchesConversation:conversation]);
    XCTAssertFalse([clearedList predicateMatchesConversation:conversation]);
}


- (void)testThatClearingMessageHistorySetsLastReadServerTimeStampToLastServerTimeStamp
{
    // given
    NSDate *clearedTimeStamp = [NSDate date];
    
    ZMUser *otherUser = [self createUser];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastServerTimeStamp = clearedTimeStamp;

    ZMClientMessage *message1 = [[ZMClientMessage alloc] initWithNonce:NSUUID.createUUID managedObjectContext:self.uiMOC];
    message1.serverTimestamp = clearedTimeStamp;
    message1.sender = otherUser;
    message1.visibleInConversation = conversation;
    
    XCTAssertNil(conversation.lastReadServerTimeStamp);
    
    // when
    [conversation clearMessageHistory];
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(conversation.lastReadServerTimeStamp, clearedTimeStamp);
}

- (void)testThatSettingClearedTimeStampDueToRemoteChangeDoesNotDeleteUnsentMessages
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        
        ZMMessage *message1 = (id)[conversation appendMessageWithText:@"A"];
        [message1 expire];
        
        NSDate *clearedTimestamp = [NSDate date];
        ZMMessage *message2 = (id)[conversation appendMessageWithText:@"B"];
        message2.serverTimestamp = clearedTimestamp;
        conversation.lastServerTimeStamp = clearedTimestamp;
        
        [self spinMainQueueWithTimeout:1];
        
        ZMMessage *message3 = (id)[conversation appendMessageWithText:@"C"];
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
        
        ZMMessage *message1 = (id)[conversation appendMessageWithText:@"A"];
        message1.serverTimestamp = [NSDate date];
        
        NSDate *clearedTimestamp = [message1.serverTimestamp dateByAddingTimeInterval:10];
        
        ZMMessage *message2 = (id)[conversation appendMessageWithText:@"B"];
        message2.serverTimestamp = [clearedTimestamp dateByAddingTimeInterval:10];
        
        // when
        conversation.clearedTimeStamp = clearedTimestamp;
        
        // then
        XCTAssertTrue(message1.isDeleted);
        XCTAssertFalse(message2.isDeleted);
    }];
}

- (void)testThatClearingMessageHistorySetsClearedTimeStampToLastServerTimeStamp
{
    // given
    NSDate *clearedTimeStamp = [NSDate date];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastServerTimeStamp = clearedTimeStamp;
    ZMMessage *message1 = (id)[conversation appendMessageWithText:@"B"];
    message1.serverTimestamp = clearedTimeStamp;
    
    XCTAssertNil(conversation.clearedTimeStamp);
    
    // when
    [conversation clearMessageHistory];
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualObjects(conversation.clearedTimeStamp, clearedTimeStamp);
}


- (void)testThatRemovingOthersInConversationDoesntClearMessages
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    [self.uiMOC saveOrRollback];
    NSArray *users = @[user1, user2, selfUser];
    ZMConversation *conversation = [self insertConversationWithParticipants:users];
    
    ZMMessage *message1 = (id)[conversation appendMessageWithText:@"1"];
    message1.serverTimestamp = [NSDate date];
    
    ZMMessage *message2 = (id)[conversation appendMessageWithText:@"2"];
    message2.serverTimestamp = [NSDate date];
    
    // when
    [conversation internalRemoveParticipants:@[user1] sender:self.selfUser];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertFalse(conversation.isArchived);
    XCTAssertNil(conversation.clearedTimeStamp);
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
    [conversation.mutableLastServerSyncedActiveParticipants addObject:otherUser];
    XCTAssertFalse(conversation.isArchived);
    
    // when
    [conversation internalRemoveParticipants:@[selfUser] sender:selfUser];
    WaitForAllGroupsToBeEmpty(0.5f);
    
    // then
    XCTAssertTrue(conversation.isArchived);
}

- (void)testThatAppendingATextMessageInAnArchivedConversationUnarchivesIt
{
    [self assertThatAppendingAMessageUnarchivesAConversation:^(ZMConversation *conversation) {
        [conversation appendMessageWithText:@"Text"];
    }];
}

- (void)testThatAppendingAnImageMessageInAnArchivedConversationUnarchivesIt
{
    [self assertThatAppendingAMessageUnarchivesAConversation:^(ZMConversation *conversation) {
        [conversation appendMessageWithImageData:self.verySmallJPEGData];
    }];
}

- (void)testThatAppendingALocationMessageInAnArchivedConversationUnarchivesIt
{
    [self assertThatAppendingAMessageUnarchivesAConversation:^(ZMConversation *conversation) {
        ZMLocationData *location = [ZMLocationData locationDataWithLatitude:42 longitude:8 name:@"Mars" zoomLevel:9000];
        [conversation appendMessageWithLocationData:location];
    }];
}

- (void)assertThatAppendingAMessageUnarchivesAConversation:(void (^)(ZMConversation *))insertBlock
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    selfUser.remoteIdentifier = NSUUID.createUUID;
    ZMUser *otherUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    [conversation.mutableLastServerSyncedActiveParticipants addObject:otherUser];
    conversation.isArchived = YES;
    XCTAssertTrue(conversation.isArchived);

    // when
    insertBlock(conversation);
    WaitForAllGroupsToBeEmpty(0.5f);

    // then
    XCTAssertFalse(conversation.isArchived);
}

- (void)testThatArchivingAConversationSetsTheArchivedTimestamp
{
    // given
    NSDate *archivedTimestamp = [NSDate date];
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastServerTimeStamp = archivedTimestamp;
    
    // when
    conversation.isArchived = YES;
    
    // then
    XCTAssertEqualObjects(conversation.archivedChangedTimestamp, archivedTimestamp);
}

- (void)testThatUnarchivingAConversationSetsTheArchivedChangedTimestamp
{
    // given
    NSDate *archivedTimestamp = [NSDate date];
    NSDate *unarchivedTimestamp = [archivedTimestamp dateByAddingTimeInterval:100];

    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.lastServerTimeStamp = archivedTimestamp;
    conversation.isArchived = YES;
    XCTAssertNotNil(conversation.archivedChangedTimestamp);
    XCTAssertEqual([conversation.archivedChangedTimestamp timeIntervalSince1970], [conversation.lastServerTimeStamp timeIntervalSince1970]);

    // when
    conversation.lastServerTimeStamp = unarchivedTimestamp;
    conversation.isArchived = NO;
    
    // then
    XCTAssertNotNil(conversation.archivedChangedTimestamp);
    XCTAssertEqual([conversation.archivedChangedTimestamp timeIntervalSince1970], [conversation.lastServerTimeStamp timeIntervalSince1970]);
}

@end



@implementation ZMConversationTests (Knocking)

- (ZMConversation *)createConversationWithMessages;
{
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    for (NSString *text in @[@"A", @"B", @"C", @"D", @"E"]) {
        [conversation appendMessageWithText:text];
    }
    XCTAssert([self.syncMOC saveOrRollback]);
    return conversation;
}

- (void)testThatItCanInsertAKnock;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // given
        ZMConversation *conversation = [self createConversationWithMessages];
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        
        // when
        id<ZMConversationMessage> knock = [conversation appendKnock];
        id<ZMConversationMessage> msg = conversation.lastMessage;
        
        // then
        XCTAssertEqual(knock, msg);
        XCTAssertNotNil(knock.knockMessageData);
        XCTAssertEqual(knock.sender, selfUser);
    }];

}

- (void)waitForInterval:(NSTimeInterval)interval {
    [self spinMainQueueWithTimeout:interval];
}

@end

@implementation ZMConversationTests (UnreadCount)

- (void)testThatItDoesNotCountExcludedConversationWithUnreadMessagesAsUnread
{
    // given
    
    [self.syncMOC performGroupedBlockAndWait:^{
        XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);
        ZMConversation *conversation = [self insertConversationWithUnread:YES];
        
        // when
        XCTAssert([self.syncMOC saveOrRollback]);
        
        //then
        XCTAssertEqual([ZMConversation unreadConversationCountExcludingSilencedInContext:self.syncMOC excluding:conversation], 0lu);
    }];
}

- (void)testThatItDoesCountsNonSilencedNonExcludedConversationsUnreadContentAsUnread;
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);

        [self insertConversationWithUnread:YES];

        // when
        XCTAssert([self.syncMOC saveOrRollback]);

        // then
        XCTAssertEqual([ZMConversation unreadConversationCountExcludingSilencedInContext:self.syncMOC excluding:nil], 1lu);
    }];
}

- (void)testThatItCountsConversationsWithUnreadMessagesAsUnread_IfItHasUnread
{
    // given
    
    [self.syncMOC performGroupedBlockAndWait:^{
        XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);
        [self insertConversationWithUnread:YES];
        
        // when
        XCTAssert([self.syncMOC saveOrRollback]);
        
        //then
        XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 1lu);
    }];
}

- (void)testThatItDoesNotCountConversationsWithUnreadMessagesAsUnread_IfItHasNoUnread
{
    // give
    
    [self.syncMOC performGroupedBlockAndWait:^{
        XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);
        [self insertConversationWithUnread:NO];
        
        // when
        XCTAssert([self.syncMOC saveOrRollback]);
        
        //then
        XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);
    }];
}

- (void)testThatItCountsConversationsWithPendingConnectionAsUnread
{
    // given

    [self.syncMOC performGroupedBlockAndWait:^{
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
    }];
}

- (void)testThatItDoesNotCountConversationsWithSentConnectionAsUnread
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
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
    }];
}

- (void)testThatItDoesNotCountBlockedConversationsAsUnread
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
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
    }];
}

- (void)testThatItDoesNotCountIgnoredConversationsAsUnread
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
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
    }];
}

- (void)testThatItCountsArchivedConversationsWithUnreadMessagesAsUnread;
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);

        ZMConversation *conversation = [self insertConversationWithUnread:YES];
        conversation.isArchived = YES;
        
        // when
        XCTAssert([self.syncMOC saveOrRollback]);
        
        // then
        XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 1lu);
    }];
}

- (void)testThatItDoesNotCountConversationsThatAreClearedAsUnread;
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);

        ZMConversation *conversation = [self insertConversationWithUnread:YES];
        conversation.isArchived = YES;
        [conversation clearMessageHistory];
        
        // when
        XCTAssert([self.syncMOC saveOrRollback]);
        
        // then
        XCTAssertEqual([ZMConversation unreadConversationCountInContext:self.syncMOC], 0lu);
    }];
}


@end



@implementation ZMConversationTests (ConversationListIndicator)

- (void)setConversationAsHavingKnock:(ZMConversation *)conversation
{
    [self simulateUnreadMissedKnockInConversation:conversation];
}

- (void)setConversationAsHavingMissedCall:(ZMConversation *)conversation
{
    [self simulateUnreadMissedCallInConversation:conversation];
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

- (void)testThatConversationListIndicatorIsUnreadMentionWhenItHasUnreadSelfMention
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        [self simulateUnreadSelfMentionCount:2 forConversation:conversation];
        
        // then
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorUnreadSelfMention);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatConversationListIndicatorIsUnreadReplyWhenItHasUnreadSelfReply
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        [self simulateUnreadSelfReplyCount:2 forConversation:conversation];

        // then
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorUnreadSelfReply);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
}

- (void)testThatConversationListIndicatorIsUnreadMentionWhenItHasUnreadSelfMentionAndUnreadSelfReply
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        [self simulateUnreadSelfMentionCount:2 forConversation:conversation];
        [self simulateUnreadSelfReplyCount:2 forConversation:conversation];

        // then
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorUnreadSelfMention);
    }];
    WaitForAllGroupsToBeEmpty(0.5);
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


- (void)testThatConversationListIndicatorIsVoiceInactiveWhenItHasIgnoredActiveVoiceChannelAndLowerPriorityEvents
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        [self simulateUnreadCount:1 forConversation:conversation];
        [self simulateUnreadMissedKnockInConversation:conversation];
        [self simulateUnreadMissedCallInConversation:conversation];
        [conversation setHasUnreadUnsentMessage:YES];
        [conversation setIsIgnoringCall:YES];
        
        // then
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorInactiveCall);
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
        [self setConversationAsBeingPending:conversation inContext:self.syncMOC];
        
        // then
        XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorPending);

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
    [conversation.mutableLastServerSyncedActiveParticipants addObjectsFromArray:@[user1, user2]];
    conversation.userDefinedName = @"Conversation";
    conversation.conversationType = ZMConversationTypeGroup;
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
    request.predicate = [ZMConversation predicateForSearchQuery:@"User1" team:nil];
    
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
    [conversation.mutableLastServerSyncedActiveParticipants addObjectsFromArray:@[user1, user2]];
    conversation.userDefinedName = @"Conversation";
    conversation.conversationType = ZMConversationTypeGroup;
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
    request.predicate = [ZMConversation predicateForSearchQuery:@"Foo Bar" team:nil];
    
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
    [conversation2.mutableLastServerSyncedActiveParticipants addObject:user1];
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
    request.predicate = [ZMConversation predicateForSearchQuery:@"Bine" team:nil];
    
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

    [conversation.mutableLastServerSyncedActiveParticipants addObjectsFromArray:@[user1]];
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

- (void)testThatItDoesNotFindAConversationBelongingToTeamWhenSearchingForPersonalConversations
{
    // given
    Team *team = [Team insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation1.userDefinedName = @"The Wire Club";
    conversation1.conversationType = ZMConversationTypeGroup;
    conversation1.team = team;
    
    ZMConversation *conversation2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation2.userDefinedName = @"The Wire Club";
    conversation2.conversationType = ZMConversationTypeGroup;
    
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
    request.predicate = [ZMConversation predicateForSearchQuery:@"Club" team:nil];
    
    NSArray *result = [self.uiMOC executeFetchRequestOrAssert:request];
    
    // then
    XCTAssertEqual(result.count, 1u);
    XCTAssertEqualObjects(result.firstObject, conversation2);
}


- (void)testThatResultsCanBeFilteredByTeam
{
    // given
    Team *team = [Team insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMConversation *conversation1 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation1.userDefinedName = @"The Wire Club";
    conversation1.conversationType = ZMConversationTypeGroup;
    conversation1.team = team;
    
    ZMConversation *conversation2 = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation2.userDefinedName = @"The Wire Club";
    conversation2.conversationType = ZMConversationTypeGroup;
    
    [self.uiMOC saveOrRollback];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Conversation"];
    request.predicate = [ZMConversation predicateForSearchQuery:@"Club" team:team];
    
    NSArray *result = [self.uiMOC executeFetchRequestOrAssert:request];
    
    // then
    XCTAssertEqual(result.count, 1u);
    XCTAssertEqualObjects(result.firstObject, conversation1);
}

@end



@implementation ZMConversationTests (Predicates)

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
    NSPredicate *sut = [ZMConversation predicateForSearchQuery:@"lala" team:nil];
    
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
    NSPredicate *sut = [ZMConversation predicateForSearchQuery:@"lala" team:nil];
    
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
    NSPredicate *sut = [ZMConversation predicateForSearchQuery:@"lala" team:nil];
    
    // then
    XCTAssertTrue([sut evaluateWithObject:conversation]);
}

- (void)testThatItFetchesSharableConversations
{
    //given
    ZMUser *otherUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    ZMUser *secondUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    
    ZMConversation *conversationWithOtherUser = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversationWithOtherUser.conversationType = ZMConversationTypeOneOnOne;
    conversationWithOtherUser.remoteIdentifier = [NSUUID createUUID];
    [conversationWithOtherUser.mutableLastServerSyncedActiveParticipants addObject:otherUser];

    ZMConversation *notSyncedConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    notSyncedConversation.conversationType = ZMConversationTypeOneOnOne;
    [notSyncedConversation.mutableLastServerSyncedActiveParticipants addObject:otherUser];

    ZMConversation *conversationWithSecondUser = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversationWithSecondUser.conversationType = ZMConversationTypeOneOnOne;
    conversationWithSecondUser.remoteIdentifier = [NSUUID createUUID];
    [conversationWithSecondUser.mutableLastServerSyncedActiveParticipants addObject:secondUser];
    
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
    [groupConversationWithNoOtherParticipants internalRemoveParticipants:@[otherUser, secondUser] sender:self.selfUser];
    groupConversationWithNoOtherParticipants.isSelfAnActiveMember = YES;
    
    ZMConversation *archived = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    [archived.mutableLastServerSyncedActiveParticipants addObject:otherUser];
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

- (void)testThatItUpdatesTheConversationWhenItReceivesALastReadMessage
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
        
        ZMGenericMessage *message = [ZMGenericMessage messageWithContent:[ZMLastRead lastReadWithTimestamp:newLastRead conversationRemoteID:updatedConversation.remoteIdentifier] nonce:NSUUID.createUUID];
        NSData *contentData = message.data;
        NSString *data = [contentData base64EncodedStringWithOptions:0];
        
        NSDictionary *payload = @{@"conversation" : selfUserID.transportString,
                                  @"time" : newLastRead.transportString,
                                  @"data" : data,
                                  @"from" : selfUserID.transportString,
                                  @"type": @"conversation.client-message-add"
                                  };
        ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:(id)payload uuid:nil];
        
        // when
        [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.syncMOC prefetchResult:nil];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    [self.syncMOC performGroupedBlockAndWait:^{
        // then
        XCTAssertEqualWithAccuracy([updatedConversation.lastReadServerTimeStamp timeIntervalSince1970], [newLastRead timeIntervalSince1970], 1.5);
    }];
}

- (void)testThatItRemovesTheMessageWhenItReceivesAHidingMessage;
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // given
        NSUUID *messageID = [NSUUID createUUID];
        NSUUID *selfUserID = [ZMUser selfUserInContext:self.syncMOC].remoteIdentifier;
        XCTAssertNotNil(selfUserID);
        
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.remoteIdentifier = [NSUUID createUUID];
        [conversation appendText:@"Le fromage c'est delicieux" mentions:@[] replyingToMessage:nil fetchLinkPreview:YES nonce:messageID];
        
        ZMGenericMessage *message = [ZMGenericMessage messageWithContent:[ZMMessageHide hideWithConversationId:conversation.remoteIdentifier messageId:messageID] nonce:NSUUID.createUUID];
        NSData *contentData = message.data;
        NSString *data = [contentData base64EncodedStringWithOptions:0];
        
        NSDictionary *payload = @{@"conversation" : selfUserID.transportString,
                                  @"time" : [NSDate date].transportString,
                                  @"data" : data,
                                  @"from" : selfUserID.transportString,
                                  @"type": @"conversation.client-message-add"
                                  };
        ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:(id)payload uuid:nil];
        
        // when
        [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.syncMOC prefetchResult:nil];
        [self.syncMOC saveOrRollback];
        
        // then
        ZMMessage *fetchedMessage = [ZMMessage fetchMessageWithNonce:messageID forConversation:conversation inManagedObjectContext:self.syncMOC];
        XCTAssertNil(fetchedMessage);
    }];
}

- (void)testThatItRemovesImageAssetsWhenItReceivesADeletionMessage;
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // given
        NSUUID *messageID = [NSUUID createUUID];
        NSUUID *selfUserID = [ZMUser selfUserInContext:self.syncMOC].remoteIdentifier;
        NSData *imageData = [NSData secureRandomDataOfLength:100];
        XCTAssertNotNil(selfUserID);
        
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.remoteIdentifier = [NSUUID createUUID];
        id<ZMConversationMessage> message = [conversation appendImageFromData:self.verySmallJPEGData nonce:messageID];
        
        // store asset data
        [self.syncMOC.zm_fileAssetCache storeAssetData:message format:ZMImageFormatOriginal encrypted:NO data:imageData];
        [self.syncMOC.zm_fileAssetCache storeAssetData:message format:ZMImageFormatPreview encrypted:NO data:imageData];
        [self.syncMOC.zm_fileAssetCache storeAssetData:message format:ZMImageFormatMedium encrypted:NO data:imageData];
        [self.syncMOC.zm_fileAssetCache storeAssetData:message format:ZMImageFormatPreview encrypted:YES data:imageData];
        [self.syncMOC.zm_fileAssetCache storeAssetData:message format:ZMImageFormatMedium encrypted:YES data:imageData];
        
        // delete
        ZMGenericMessage *deleteMessage = [ZMGenericMessage messageWithContent:[ZMMessageHide hideWithConversationId:conversation.remoteIdentifier messageId:messageID] nonce:NSUUID.createUUID];
        NSData *contentData = deleteMessage.data;
        NSString *data = [contentData base64EncodedStringWithOptions:0];
        
        NSDictionary *payload = @{@"conversation" : selfUserID.transportString,
                                  @"time" : [NSDate date].transportString,
                                  @"data" : data,
                                  @"from" : selfUserID.transportString,
                                  @"type": @"conversation.client-message-add"
                                  };
        ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:(id)payload uuid:nil];
        
        // when
        [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.syncMOC prefetchResult:nil];
        [self.syncMOC saveOrRollback];
        
        // then
        XCTAssertNil([self.syncMOC.zm_fileAssetCache assetData:message format:ZMImageFormatOriginal encrypted:NO]);
        XCTAssertNil([self.syncMOC.zm_fileAssetCache assetData:message format:ZMImageFormatPreview encrypted:NO]);
        XCTAssertNil([self.syncMOC.zm_fileAssetCache assetData:message format:ZMImageFormatMedium encrypted:NO]);
        XCTAssertNil([self.syncMOC.zm_fileAssetCache assetData:message format:ZMImageFormatPreview encrypted:YES]);
        XCTAssertNil([self.syncMOC.zm_fileAssetCache assetData:message format:ZMImageFormatMedium encrypted:YES]);
    }];
}

- (void)testThatItRemovesFileAssetsWhenItReceivesADeletionMessage;
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // given
        NSUUID *messageID = [NSUUID createUUID];
        NSUUID *selfUserID = [ZMUser selfUserInContext:self.syncMOC].remoteIdentifier;
        NSData *fileData = [NSData secureRandomDataOfLength:100];
        NSString *fileName = @"foo.bar";
        
        NSString *documentsURL = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSURL *fileURL = [[NSURL fileURLWithPath:documentsURL] URLByAppendingPathComponent:fileName];
        [fileData writeToURL:fileURL atomically:NO];
        
        XCTAssertNotNil(selfUserID);
        
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.remoteIdentifier = [NSUUID createUUID];
        ZMFileMetadata *fileMetadata = [[ZMFileMetadata alloc] initWithFileURL:fileURL thumbnail:nil];
        id<ZMConversationMessage> message = [conversation appendFile:fileMetadata nonce:messageID];
        
        // store asset data
        [self.syncMOC.zm_fileAssetCache storeAssetData:message encrypted:NO data:fileData];
        [self.syncMOC.zm_fileAssetCache storeAssetData:message encrypted:YES data:fileData];
        
        // delete
        ZMGenericMessage *deleteMessage = [ZMGenericMessage messageWithContent:[ZMMessageHide hideWithConversationId:conversation.remoteIdentifier messageId:messageID] nonce:NSUUID.createUUID];
        NSData *contentData = deleteMessage.data;
        NSString *data = [contentData base64EncodedStringWithOptions:0];
        
        NSDictionary *payload = @{@"conversation" : selfUserID.transportString,
                                  @"time" : [NSDate date].transportString,
                                  @"data" : data,
                                  @"from" : selfUserID.transportString,
                                  @"type": @"conversation.client-message-add"
                                  };
        ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:(id)payload uuid:nil];
        
        // when
        [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.syncMOC prefetchResult:nil];
        [self.syncMOC saveOrRollback];
        
        // re-create message with same nonce to access the cache
        id<ZMConversationMessage> lookupMessage = [conversation appendMessageWithText:@"123"];
        
        // then
        XCTAssertNil([self.syncMOC.zm_fileAssetCache assetData:lookupMessage encrypted:NO]);
        XCTAssertNil([self.syncMOC.zm_fileAssetCache assetData:lookupMessage encrypted:YES]);
    }];
}

- (void)testThatItDoesNotRemovesANonExistingMessageWhenItReceivesADeletionMessage;
{
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // given
        NSUUID *selfUserID = [ZMUser selfUserInContext:self.syncMOC].remoteIdentifier;
        XCTAssertNotNil(selfUserID);
        
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.remoteIdentifier = [NSUUID createUUID];
        
        [conversation appendText:@"Le fromage c'est delicieux" mentions:@[] replyingToMessage:nil fetchLinkPreview:YES nonce:[NSUUID createUUID]];
        NSUInteger previusMessagesCount = conversation.allMessages.count;
        
        ZMGenericMessage *message = [ZMGenericMessage messageWithContent:[ZMMessageHide hideWithConversationId:conversation.remoteIdentifier messageId:NSUUID.createUUID] nonce:NSUUID.createUUID];
        NSData *contentData = message.data;
        NSString *data = [contentData base64EncodedStringWithOptions:0];
        
        NSDictionary *payload = @{@"conversation" : selfUserID.transportString,
                                  @"time" : [NSDate date].transportString,
                                  @"data" : data,
                                  @"from" : selfUserID.transportString,
                                  @"type": @"conversation.client-message-add"
                                  };
        ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:(id)payload uuid:nil];
        
        // when
        [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.syncMOC prefetchResult:nil];
        [self.syncMOC saveOrRollback];
        
        // then
        XCTAssertEqual(previusMessagesCount, conversation.allMessages.count);
    }];
}

- (void)testThatItDoesNotRemovesAMessageWhenItReceivesADeletionMessageNotFromSelfUser;
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // given
        NSUUID *messageID = [NSUUID createUUID];
        NSUUID *selfUserID = [ZMUser selfUserInContext:self.syncMOC].remoteIdentifier;
        XCTAssertNotNil(selfUserID);
        
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.remoteIdentifier = [NSUUID createUUID];

        [conversation appendText:@"Le fromage c'est delicieux" mentions:@[] replyingToMessage:nil fetchLinkPreview:YES nonce:messageID];
        NSUInteger previusMessagesCount = conversation.allMessages.count;
        
        ZMGenericMessage *message = [ZMGenericMessage messageWithContent:[ZMMessageHide hideWithConversationId:conversation.remoteIdentifier messageId:messageID] nonce:NSUUID.createUUID];
        NSData *contentData = message.data;
        NSString *data = [contentData base64EncodedStringWithOptions:0];
        
        NSDictionary *payload = @{@"conversation" : selfUserID.transportString,
                                  @"time" : [NSDate date].transportString,
                                  @"data" : data,
                                  @"from" : [NSUUID createUUID].transportString,
                                  @"type": @"conversation.client-message-add"
                                  };
        ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:(id)payload uuid:nil];
        
        // when
        [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.syncMOC prefetchResult:nil];
        [self.syncMOC saveOrRollback];
        
        // then
        XCTAssertEqual(previusMessagesCount, conversation.allMessages.count);
    }];
}

- (void)testThatItDoesNotRemovesAMessageWhenItReceivesADeletionMessageNotInTheSelfConversation;
{
    // given
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // given
        NSUUID *messageID = [NSUUID createUUID];
        NSUUID *selfUserID = [ZMUser selfUserInContext:self.syncMOC].remoteIdentifier;
        XCTAssertNotNil(selfUserID);
        
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.remoteIdentifier = [NSUUID createUUID];

        [conversation appendText:@"Le fromage c'est delicieux" mentions:@[] replyingToMessage:nil fetchLinkPreview:YES nonce:messageID];
        NSUInteger previusMessagesCount = conversation.allMessages.count;
        
        ZMGenericMessage *message = [ZMGenericMessage messageWithContent:[ZMMessageHide hideWithConversationId:conversation.remoteIdentifier messageId:messageID] nonce:NSUUID.createUUID];
        NSData *contentData = message.data;
        NSString *data = [contentData base64EncodedStringWithOptions:0];
        
        NSDictionary *payload = @{@"conversation" : [NSUUID createUUID].transportString,
                                  @"time" : [NSDate date].transportString,
                                  @"data" : data,
                                  @"from" : selfUserID.transportString,
                                  @"type": @"conversation.client-message-add"
                                  };
        ZMUpdateEvent *event = [ZMUpdateEvent eventFromEventStreamPayload:(id)payload uuid:nil];
        
        // when
        [ZMClientMessage createOrUpdateMessageFromUpdateEvent:event inManagedObjectContext:self.syncMOC prefetchResult:nil];
        [self.syncMOC saveOrRollback];
        
        // then
        XCTAssertEqual(previusMessagesCount, conversation.allMessages.count);
    }];
}

@end


@implementation ZMConversationTests (SendOnlyEncryptedMessages)

- (void)testThatItInsertsEncryptedTextMessages
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    
    // when
    [conversation appendMessageWithText:@"hello"];
    
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


@implementation ZMConversationTests (SystemMessags)

- (void)testThatItSetsHasUnreadMissedCallForMissedCallMessages
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        NSDate *originalDate = [NSDate dateWithTimeIntervalSinceNow:-20];
        conversation.lastReadServerTimeStamp = originalDate;
        conversation.lastServerTimeStamp = originalDate;
        [conversation calculateLastUnreadMessages];
        
        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        
        XCTAssertFalse(conversation.hasUnreadMissedCall);
        
        // when
        [conversation appendMissedCallMessageFromUser:user at:[NSDate date] relevantForStatus:YES];
        
        // then
        XCTAssertTrue(conversation.hasUnreadMissedCall);
    }];
}

- (void)testThatItUnarchivesWhenAppendingAMissedCall
{
    [self.syncMOC performGroupedBlock:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.isArchived = YES;

        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        XCTAssertTrue(conversation.isArchived);

        // when
        [conversation appendMissedCallMessageFromUser:user at:[NSDate date] relevantForStatus:YES];

        // then
        XCTAssertFalse(conversation.isArchived);
    }];

    XCTAssert([self waitForAllGroupsToBeEmptyWithTimeout:0.5]);
}

- (void)testThatItUnarchivesWhenAppendingAPerformedCall
{
    [self.syncMOC performGroupedBlock:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.isArchived = YES;

        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        XCTAssertTrue(conversation.isArchived);

        // when
        [conversation appendPerformedCallMessageWith:42 caller:user];

        // then
        XCTAssertFalse(conversation.isArchived);
    }];

    XCTAssert([self waitForAllGroupsToBeEmptyWithTimeout:0.5]);

}

- (void)testThatItUpdatesTheLastReadTimestampForMissedCallChildMessages
{
    // given
    NSDate *orginalDate = [NSDate dateWithTimeIntervalSinceNow:-20];
    NSDate *firstCallDate = [orginalDate dateByAddingTimeInterval:50];
    NSDate *secondCallDate = [orginalDate dateByAddingTimeInterval:100];

    __block ZMMessage *message;
    __block ZMConversation *conversation;
    __block ZMUser *user;
    
    [self.syncMOC performGroupedBlockAndWait:^{
        conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.lastReadServerTimeStamp = orginalDate;
        conversation.lastServerTimeStamp = orginalDate;
        
        user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        XCTAssertFalse(conversation.hasUnreadMissedCall);
        
        // when
        // (1) append first missed call
        message = [conversation appendMissedCallMessageFromUser:user at:firstCallDate relevantForStatus:YES];
        [self.syncMOC saveOrRollback];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // (2) set first call as read
    ZMConversation *uiConv = [self.uiMOC objectWithID:conversation.objectID];
    ZMMessage *uiMessage = [self.uiMOC objectWithID:message.objectID];
    [uiConv markMessagesAsReadUntil:uiMessage];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualWithAccuracy([uiConv.lastReadServerTimeStamp timeIntervalSince1970], [firstCallDate timeIntervalSince1970], 0.5);
    
    [self.syncMOC performGroupedBlockAndWait:^{
        // and when
        // (3) append second missed call (as childMessage)
        [conversation appendMissedCallMessageFromUser:user at:secondCallDate relevantForStatus:YES];
        [self.syncMOC saveOrRollback];
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    [self.uiMOC refreshObject:uiMessage mergeChanges:YES];
    [self.uiMOC refreshObject:uiConv mergeChanges:YES];

    // (4) set second call as read
    [uiConv markMessagesAsReadUntil:uiMessage];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // then
    XCTAssertEqualWithAccuracy([uiConv.lastReadServerTimeStamp timeIntervalSince1970], [secondCallDate timeIntervalSince1970], 0.5);
}

- (void)testThatItDoesReturnTheMissedCallMessageAsFirstUnreadMessageWhenItHasUnreadChildren
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSDate *orginalDate = [NSDate dateWithTimeIntervalSinceNow:-20];
        NSDate *firstCallDate = [orginalDate dateByAddingTimeInterval:50];
        NSDate *secondCallDate = [orginalDate dateByAddingTimeInterval:100];

        ZMConversation * conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.lastReadServerTimeStamp = orginalDate;
        conversation.lastServerTimeStamp = orginalDate;

        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        XCTAssertFalse(conversation.hasUnreadMissedCall);

        ZMMessage *textMessage = (id)[conversation appendMessageWithText:@"Foo"];

        // (1) append first missed call
        ZMMessage *message1 = [conversation appendMissedCallMessageFromUser:user at:firstCallDate relevantForStatus:YES];
        conversation.lastReadServerTimeStamp = message1.serverTimestamp;

        // (2) append first second call
        [conversation appendMissedCallMessageFromUser:user at:secondCallDate relevantForStatus:YES];

        // when
        id<ZMConversationMessage> firstUnreadMessage = [conversation firstUnreadMessage];

        // then
        XCTAssertNotEqualObjects(textMessage, firstUnreadMessage);
        XCTAssertEqualObjects(message1, firstUnreadMessage);
    }];
}

- (void)testThatItDoesNotReturnsTheMissedCallMessageAsFirstUnreadMessageWhenNoUnreadChildren
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSDate *orginalDate = [NSDate dateWithTimeIntervalSinceNow:-20];
        NSDate *firstCallDate = [orginalDate dateByAddingTimeInterval:50];
        NSDate *secondCallDate = [orginalDate dateByAddingTimeInterval:100];

        ZMConversation * conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.lastReadServerTimeStamp = orginalDate;
        conversation.lastServerTimeStamp = orginalDate;

        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        XCTAssertFalse(conversation.hasUnreadMissedCall);

        [conversation appendMessageWithText:@"Foo"];

        // (1) append first missed call
        ZMMessage *message1 = [conversation appendMissedCallMessageFromUser:user at:firstCallDate relevantForStatus:YES];
        conversation.lastReadServerTimeStamp = message1.serverTimestamp;
        
        // (2) append first second call
        ZMMessage *message2 = [conversation appendMissedCallMessageFromUser:user at:secondCallDate relevantForStatus:YES];
        conversation.lastReadServerTimeStamp = message2.serverTimestamp;

        // when
        id<ZMConversationMessage> firstUnreadMessage = [conversation firstUnreadMessage];

        // then
        XCTAssertNil(firstUnreadMessage);
    }];
}

- (void)testThatStoresRelevantForConversationStatusOnSystemMessages
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        
        XCTAssertFalse(conversation.hasUnreadMissedCall);
        
        // when
        ZMSystemMessage *message1 = [conversation appendMissedCallMessageFromUser:user at:[NSDate date] relevantForStatus:YES];
        ZMSystemMessage *message2 = [conversation appendMissedCallMessageFromUser:user at:[NSDate date] relevantForStatus:NO];
        
        // then
        XCTAssertTrue(message1.relevantForConversationStatus);
        XCTAssertFalse(message2.relevantForConversationStatus);
        XCTAssertTrue(conversation.hasUnreadMissedCall);
    }];
}

@end


@implementation ZMConversationTests (GroupCallingV3)

- (void)testThatItReturnsActiveCall_isCallDeviceActive
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    XCTAssertNotEqual(conversation.conversationListIndicator, ZMConversationListIndicatorActiveCall);

    // when
    conversation.isCallDeviceActive = YES;

    // then
    XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorActiveCall);
}

- (void)testThatItReturnsInactiveCall_isIgnoringCall
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    XCTAssertNotEqual(conversation.conversationListIndicator, ZMConversationListIndicatorInactiveCall);

    // when
    conversation.isIgnoringCall = YES;
    
    // then
    XCTAssertEqual(conversation.conversationListIndicator, ZMConversationListIndicatorInactiveCall);
}

@end
