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

@interface ZMConversationSecurityTests : ZMConversationTestsBase

@end

@implementation ZMConversationSecurityTests

- (NSArray<ZMUser *> *)createUsersWithClientsOnSyncMOC
{
    self.selfUser = [ZMUser selfUserInContext:self.syncMOC];
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
    UserClient *user1Client = [UserClient insertNewObjectInManagedObjectContext:self.syncMOC];
    ZMConnection *user1Connection = [ZMConnection insertNewSentConnectionToUser:user1];
    user1Connection.status = ZMConnectionStatusAccepted;
    user1Client.user = user1;
    
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
    UserClient *user2Client = [UserClient insertNewObjectInManagedObjectContext:self.syncMOC];
    ZMConnection *user2Connection = [ZMConnection insertNewSentConnectionToUser:user2];
    user2Connection.status = ZMConnectionStatusAccepted;
    user2Client.user = user2;
    
    return @[user1, user2];
}

- (void)testThatConversationInitialSecurityLevelIsNotSecured
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray *users = [self createUsersWithClientsOnSyncMOC];
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        
        // then
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelNotSecure);
    }];
}

- (void)testThatItIncreasesSecurityLevelIfAllClientsInConversationAreTrusted
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray<ZMUser *> *users = [self createUsersWithClientsOnSyncMOC];
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        
        // when
        [selfClient trustClients:[NSSet setWithObjects:[[users.firstObject clients] anyObject], [[users.lastObject clients] anyObject], nil]];

        // then
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
    }];
}

- (void)testThatItDoesNotIncreaseTheSecurityLevelIfAConversationContainsUsersWithoutAConnection
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray<ZMUser *> *users = [self createUsersWithClientsOnSyncMOC];
        
        ZMUser *unconnectedUser = users.firstObject, *connectedUser = users.lastObject;
        unconnectedUser.connection.status = ZMConnectionStatusSent;
        
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        
        // when
        [selfClient trustClients:connectedUser.clients];
        
        // then
        XCTAssertFalse(conversation.allUsersTrusted);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelNotSecure);
        
        // when
        unconnectedUser.connection.status = ZMConnectionStatusAccepted;
        [selfClient trustClients:unconnectedUser.clients];
        
        // then
        XCTAssertTrue(conversation.allUsersTrusted);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
        
        ZMUser *newUnconnectedUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        UserClient *unconnectedUserClient = [UserClient insertNewObjectInManagedObjectContext:self.syncMOC];
        unconnectedUserClient.user = newUnconnectedUser;
        
        // when adding a new participant
        [conversation addParticipant:newUnconnectedUser];
        
        // then the conversation should degrade
        XCTAssertFalse(conversation.allUsersTrusted);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
        
        // when
        [conversation removeParticipant:newUnconnectedUser];
        
        // then
        XCTAssertTrue(conversation.allUsersTrusted);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
    }];
}

- (void)testThatItDoesNotIncreaseSecurityLevelIfNotAllClientsAreTrusted
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray<ZMUser *> *users = [self createUsersWithClientsOnSyncMOC];
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        
        // when
        [selfClient trustClients:[NSSet setWithObjects:[[users.firstObject clients] anyObject], nil]];

        // then
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelNotSecure);
    }];
}

- (void)testThatItDoesNotIncreaseSecurityLevelIfNotAllUsersHaveClients
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        ZMUser *userWithoutClients = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        NSArray<ZMUser *> *users = [[self createUsersWithClientsOnSyncMOC] arrayByAddingObject:userWithoutClients];
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        
        NSMutableSet *allClients = [NSMutableSet set];
        for(ZMUser *user in users) {
            for(UserClient *client in user.clients) {
                [allClients addObject:client];
            }
        }
        
        // when
        [selfClient trustClients:allClients];
        
        // then
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelNotSecure);
    }];
}

- (void)testThatItDecreaseSecurityLevelIfSomeOfTheClientsIsIgnored
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray<ZMUser *> *users = [self createUsersWithClientsOnSyncMOC];
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        
        // when
        [selfClient trustClients:[NSSet setWithObjects:[[users.firstObject clients] anyObject], [[users.lastObject clients] anyObject], nil]];
        [selfClient ignoreClients:[NSSet setWithObjects:[[users.firstObject clients] anyObject], nil]];
        
        // then
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
    }];
}

- (void)testThatItDoesNotDecreaseSecurityLevelIfItIsInPartialSecureLevel
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray<ZMUser *> *users = [self createUsersWithClientsOnSyncMOC];
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        
        // when
        [selfClient trustClients:[NSSet setWithObjects:[[users.firstObject clients] anyObject], [[users.lastObject clients] anyObject], nil]];
        [selfClient ignoreClient:users.firstObject.clients.anyObject];
        
        // then
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
        
        // and when
        [selfClient ignoreClient:users.lastObject.clients.anyObject];
        
        // then we should not change the security level as we were already ignored
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
    }];
}

- (void)testThatItCorrectlySetsNeedUpdatingUsersFlagOnPotentialGapSystemMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.remoteIdentifier = NSUUID.createUUID;
    [conversation appendNewPotentialGapSystemMessageWithUsers:nil timestamp:[NSDate date]];

    // then
    ZMSystemMessage *fetchedMessage = [ZMSystemMessage fetchLatestPotentialGapSystemMessageInConversation:conversation];
    XCTAssertEqual(conversation.messages.count, 1lu);
    XCTAssertNotNil(fetchedMessage);
    XCTAssertTrue(fetchedMessage.needsUpdatingUsers);
    
    // when
    [conversation updatePotentialGapSystemMessagesIfNeededWithUsers:nil];
    
    // then
    XCTAssertFalse(fetchedMessage.needsUpdatingUsers);
    fetchedMessage = [ZMSystemMessage fetchLatestPotentialGapSystemMessageInConversation:conversation];
    XCTAssertEqual(conversation.messages.count, 1lu);
    XCTAssertNil(fetchedMessage);
}

- (void)testThatItNotifiesWhenAllClientAreVerified;
{
    XCTestExpectation *expectation = [self expectationForNotification:ZMConversationIsVerifiedNotificationName object:nil handler:^BOOL(NSNotification * _Nonnull notification __unused) {
        [expectation fulfill];
        return YES;
    }];
    
    __block NSManagedObjectID *conversationObjectID = nil;
    
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray<ZMUser *> *users = [self createUsersWithClientsOnSyncMOC];
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        
        // when
        XCTAssertNotEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
        [selfClient trustClients:[NSSet setWithObjects:[[users.firstObject clients] anyObject], [[users.lastObject clients] anyObject], nil]];
        
        conversationObjectID = conversation.objectID;
        [self.syncMOC saveOrRollback];
    }];

    // then
    ZMConversation *uiConversation = [self.uiMOC existingObjectWithID:conversationObjectID error:nil];
    XCTAssertEqual(uiConversation.securityLevel, ZMConversationSecurityLevelSecure);
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatIncreasesSecurityLevelOfCreatedGroupConversationWithAllParticipantsAlreadyTrusted
{
    
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray <ZMUser *> *users = [self createUsersWithClientsOnSyncMOC];
        NSSet *clients = [users.firstObject.clients setByAddingObjectsFromSet:users.lastObject.clients];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        [selfClient trustClients:clients];
        
        // when
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];

        // then
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecure);
        XCTAssertEqual(conversation.messages.count, 2lu);
        ZMMessage *message = conversation.messages.lastObject;
        XCTAssertNotNil(message);
        XCTAssertTrue([message isKindOfClass:[ZMSystemMessage class]]);
        XCTAssertEqual(message.systemMessageData.systemMessageType, ZMSystemMessageTypeConversationIsSecure);
        XCTAssertEqualObjects(message.systemMessageData.clients, [clients setByAddingObject:selfClient]);
    }];
    
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatItDoesNotIncreaseSecurityLevelOfCreatedGroupConversationWithAllParticipantsIfNotAlreadyTrusted
{
    [self.syncMOC performGroupedBlockAndWait:^{
        // given
        NSArray <ZMUser *> *users = [self createUsersWithClientsOnSyncMOC];
        UserClient *selfClient = [self createSelfClientOnMOC:self.syncMOC];
        [selfClient trustClients:users.firstObject.clients];
        
        // when
        ZMConversation *conversation = [ZMConversation insertGroupConversationIntoManagedObjectContext:self.syncMOC withParticipants:users];
        
        // then
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelNotSecure);
        XCTAssertEqual(conversation.messages.count, 1lu);
        ZMSystemMessage *message = conversation.messages.lastObject;
        XCTAssertNotEqual(message.systemMessageType, ZMSystemMessageTypeConversationIsSecure);
    }];
    
    XCTAssertTrue([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (ZMUser *)insertUserInConversation:(ZMConversation *)conversation userIsTrusted:(BOOL)trusted managedObjectContext:(NSManagedObjectContext *)moc
{
    [self createSelfClient];
    [self.uiMOC refreshAllObjects];
    
    UserClient *selfClient = [ZMUser selfUserInContext:moc].selfClient;
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:moc];
    [[conversation mutableOtherActiveParticipants] addObject:user];
    UserClient *client = [UserClient insertNewObjectInManagedObjectContext:moc];
    client.user  = user;
    if (trusted) {
        [selfClient trustClient:client];
    } else {
        [selfClient ignoreClient:client];
    }
    return user;
}

- (void)testThatItReturns_HasUntrustedClients_YES_ifThereAreUntrustedClients
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;

    // when
    [self insertUserInConversation:conversation userIsTrusted:NO managedObjectContext:self.uiMOC];
    BOOL hasUntrustedClients = conversation.hasUntrustedClients;
    
    // then
    XCTAssertTrue(hasUntrustedClients);

}

- (void)testThatItReturns_HasUntrustedClients_NO_ifThereAreNoUntrustedClients
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    
    // when
    [self insertUserInConversation:conversation userIsTrusted:YES managedObjectContext:self.uiMOC];
    BOOL hasUntrustedClients = conversation.hasUntrustedClients;
    
    // then
    XCTAssertFalse(hasUntrustedClients);
}

- (void)testThatItReturns_HasUntrustedClients_NO_ifThereAreNoOtherClients
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    [[conversation mutableOtherActiveParticipants] addObject:user];
    
    // when
    BOOL hasUntrustedClients = conversation.hasUntrustedClients;
    
    // then
    XCTAssertFalse(hasUntrustedClients);
}


- (void)testThatItReturns_HasUntrustedClients_NO_ifThereAreNoOtherUsers
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    
    // when
    BOOL hasUntrustedClients = conversation.hasUntrustedClients;
    
    // then
    XCTAssertFalse(hasUntrustedClients);
}

- (void)testThatSystemMessageAppendedToAEmptyConversationStillHasATimestamp
{
    // given
    [self createSelfClient];
    [self.uiMOC refreshAllObjects];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.lastModifiedDate = [NSDate new];
    
    // when
    [conversation appendStartedUsingThisDeviceMessage];
    
    // then
    ZMSystemMessage *message = conversation.messages.lastObject;
    XCTAssertNotNil(message.serverTimestamp);
}


- (void)testThatItAppendsASystemMessageOfTypeRemoteIDChangedForCBErrorCodeRemoteIdentityChanged
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.name = @"Fancy One";
    
    // when
    [conversation appendDecryptionFailedSystemMessageAtTime:[NSDate date] sender:user client:nil errorCode:CBOX_REMOTE_IDENTITY_CHANGED];
    
    // then
    ZMSystemMessage *lastMessage = conversation.messages.lastObject;
    XCTAssertEqual(lastMessage.systemMessageType, ZMSystemMessageTypeDecryptionFailed_RemoteIdentityChanged);
}

- (void)testThatItAppendsASystemMessageOfGeneralTypeForCBErrorCodeInvalidMessage
{
    // given
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user.name = @"Fancy One";
    
    // when
    [conversation appendDecryptionFailedSystemMessageAtTime:[NSDate date] sender:user client:nil errorCode:CBOX_INVALID_MESSAGE];
    
    // then
    ZMSystemMessage *lastMessage = conversation.messages.lastObject;
    XCTAssertEqual(lastMessage.systemMessageType, ZMSystemMessageTypeDecryptionFailed);
}

- (void)testThatContinuedUsingDeviceSystemMessageAppendedAfterLastMessage
{
    // given
    [self createSelfClient];
    [self.uiMOC refreshAllObjects];
    
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.lastModifiedDate = [NSDate new];
    ZMMessage *previousMessage = (id)[conversation appendMessageWithText:@"test"];
    
    // when
    [conversation appendContinuedUsingThisDeviceMessage];
    
    // then
    ZMSystemMessage *message = conversation.messages.lastObject;
    XCTAssertNotNil(message.serverTimestamp);
    XCTAssertLessThan([previousMessage.serverTimestamp timeIntervalSince1970], [message.serverTimestamp timeIntervalSince1970]);
    XCTAssertEqualWithAccuracy([[NSDate date] timeIntervalSince1970], [message.serverTimestamp timeIntervalSince1970], 1.0);

}

- (void)testThatAConversationIsNotTrustedIfItHasNoOtherParticipants
{
    // GIVEN
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    
    // THEN
    XCTAssertFalse(conversation.allUsersTrusted);
}

- (void)testThatAConversationIsNotTrustedIfNotAMemberAnymore
{
    // GIVEN
    ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conversation.conversationType = ZMConversationTypeGroup;
    ZMUser *otherUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    [conversation addParticipant:otherUser];
    UserClient *client = [UserClient insertNewObjectInManagedObjectContext:self.uiMOC];
    client.user = otherUser;
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    [[selfUser selfClient] trustClient:client];
    
    // WHEN
    [conversation removeParticipant:selfUser];
    
    // THEN
    XCTAssertFalse(conversation.allUsersTrusted);
}

@end

#pragma mark - Resending / cancelling messages in degraded conversation
@implementation ZMConversationSecurityTests (ResendingMessages)

- (void)testItExpiresAllMessagesAfterTheCurrentOneWhenAMessageCausesDegradation
{
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // GIVEN
        [self createSelfClient];
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.conversationType = ZMConversationTypeGroup;
        ZMUser *user = [self insertUserInConversation:conversation userIsTrusted:YES managedObjectContext:self.syncMOC];
        conversation.securityLevel = ZMConversationSecurityLevelSecure;

        ZMOTRMessage *message1 = (ZMOTRMessage *)[conversation appendMessageWithImageData:[self verySmallJPEGData]];
        [NSThread sleepForTimeInterval:0.05]; // cause system time to advance
        ZMOTRMessage *message2 = (ZMOTRMessage *)[conversation appendMessageWithText:@"foo 2" fetchLinkPreview:NO];
        [NSThread sleepForTimeInterval:0.05]; // cause system time to advance
        ZMOTRMessage *message3 = (ZMOTRMessage *)[conversation appendMessageWithText:@"foo 3" fetchLinkPreview:NO];
        [NSThread sleepForTimeInterval:0.05]; // cause system time to advance
        ZMOTRMessage *message4 = (ZMOTRMessage *)[conversation appendMessageWithText:@"foo 4" fetchLinkPreview:NO];
        [NSThread sleepForTimeInterval:0.05]; // cause system time to advance
        ZMOTRMessage *message5 = (ZMOTRMessage *)[conversation appendMessageWithImageData:[self verySmallJPEGData]];
        
        
        UserClient *client = [UserClient insertNewObjectInManagedObjectContext:self.syncMOC];
        client.remoteIdentifier = @"aabbccdd";
        client.user = user;
        
        // WHEN
        [conversation decreaseSecurityLevelIfNeededAfterDiscoveringClients:[NSSet setWithObject:client] causedByMessage:message3];
        
        // THEN
        XCTAssertFalse(message1.isExpired);
        XCTAssertFalse(message1.causedSecurityLevelDegradation);
        XCTAssertFalse(message2.isExpired);
        XCTAssertFalse(message2.causedSecurityLevelDegradation);
        XCTAssertTrue(message3.isExpired);
        XCTAssertTrue(message3.causedSecurityLevelDegradation);
        XCTAssertTrue(message4.isExpired);
        XCTAssertTrue(message4.causedSecurityLevelDegradation);
        XCTAssertTrue(message5.isExpired);
        XCTAssertTrue(message5.causedSecurityLevelDegradation);
        XCTAssertFalse(conversation.allUsersTrusted);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
    }];
}

- (void)testItResendsAllMessagesThatCausedDegradation
{
    __block ZMConversation *conversation;
    __block ZMOTRMessage *message1;
    __block ZMOTRMessage *message2;
    __block ZMOTRMessage *message3;
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // GIVEN
        [self createSelfClient];
        conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.conversationType = ZMConversationTypeGroup;
        ZMUser *user = [self insertUserInConversation:conversation userIsTrusted:YES managedObjectContext:self.syncMOC];
        conversation.securityLevel = ZMConversationSecurityLevelSecure;
        
        message1 = (ZMOTRMessage *)[conversation appendMessageWithText:@"foo 2" fetchLinkPreview:NO];
        [NSThread sleepForTimeInterval:0.05]; // cause system time to advance
        message2 = (ZMOTRMessage *)[conversation appendMessageWithText:@"foo 3" fetchLinkPreview:NO];
        [NSThread sleepForTimeInterval:0.05]; // cause system time to advance
        message3 = (ZMOTRMessage *)[conversation appendMessageWithImageData:[self verySmallJPEGData]];
        
        
        UserClient *client = [UserClient insertNewObjectInManagedObjectContext:self.syncMOC];
        client.remoteIdentifier = @"aabbccdd";
        client.user = user;
        [conversation decreaseSecurityLevelIfNeededAfterDiscoveringClients:[NSSet setWithObject:client] causedByMessage:message2];
        [self.syncMOC saveOrRollback];
    }];
    
    // WHEN
    ZMConversation *uiConversation = (ZMConversation *)[self.uiMOC existingObjectWithID:conversation.objectID error:nil];
    [uiConversation resendMessagesThatCausedConversationSecurityDegradation];
    
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // THEN
        XCTAssertFalse(message1.isExpired);
        XCTAssertFalse(message1.causedSecurityLevelDegradation);
        XCTAssertFalse(message2.isExpired);
        XCTAssertFalse(message3.causedSecurityLevelDegradation);
        XCTAssertEqual(message2.deliveryState, ZMDeliveryStatePending);
        XCTAssertFalse(message3.isExpired);
        XCTAssertFalse(message3.causedSecurityLevelDegradation);
        XCTAssertEqual(message3.deliveryState, ZMDeliveryStatePending);
        XCTAssertFalse(conversation.allUsersTrusted);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
    }];
}

- (void)testItCancelsAllMessagesThatCausedDegradation
{
    __block ZMConversation *conversation;
    __block ZMOTRMessage *message1;
    __block ZMOTRMessage *message2;
    __block ZMOTRMessage *message3;
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // GIVEN
        [self createSelfClient];
        conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.conversationType = ZMConversationTypeGroup;
        ZMUser *user = [self insertUserInConversation:conversation userIsTrusted:YES managedObjectContext:self.syncMOC];
        conversation.securityLevel = ZMConversationSecurityLevelSecure;
        
        message1 = (ZMOTRMessage *)[conversation appendMessageWithText:@"foo 2" fetchLinkPreview:NO];
        [NSThread sleepForTimeInterval:0.05]; // cause system time to advance
        message2 = (ZMOTRMessage *)[conversation appendMessageWithText:@"foo 3" fetchLinkPreview:NO];
        [NSThread sleepForTimeInterval:0.05]; // cause system time to advance
        message3 = (ZMOTRMessage *)[conversation appendMessageWithImageData:[self verySmallJPEGData]];
        
        
        UserClient *client = [UserClient insertNewObjectInManagedObjectContext:self.syncMOC];
        client.remoteIdentifier = @"aabbccdd";
        client.user = user;
        [conversation decreaseSecurityLevelIfNeededAfterDiscoveringClients:[NSSet setWithObject:client] causedByMessage:message2];
        [self.syncMOC saveOrRollback];
    }];
    
    // WHEN
    ZMConversation *uiConversation = (ZMConversation *)[self.uiMOC existingObjectWithID:conversation.objectID error:nil];
    [uiConversation doNotResendMessagesThatCausedDegradation];
    
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // THEN
        XCTAssertFalse(message1.isExpired);
        XCTAssertFalse(message1.causedSecurityLevelDegradation);
        XCTAssertTrue(message2.isExpired);
        XCTAssertFalse(message2.causedSecurityLevelDegradation);
        XCTAssertEqual(message2.deliveryState, ZMDeliveryStateFailedToSend);
        XCTAssertTrue(message3.isExpired);
        XCTAssertFalse(message3.causedSecurityLevelDegradation);
        XCTAssertEqual(message3.deliveryState, ZMDeliveryStateFailedToSend);
        XCTAssertFalse(conversation.allUsersTrusted);
        XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevelSecureWithIgnored);
    }];
}

@end

#pragma mark - Hotfix
@implementation ZMConversationSecurityTests (HotFix)

- (void)testThatItUpdatesFirstNewClientSystemMessage
{
    // given
    [self createSelfClient];
    [self.uiMOC refreshAllObjects];
    
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    UserClient *selfClient = selfUser.selfClient;
    XCTAssertNotNil(selfClient);
    
    ZMConversation *conv = [ZMConversation insertNewObjectInManagedObjectContext:self.uiMOC];
    conv.conversationType = ZMConversationTypeOneOnOne;
    
    ZMSystemMessage *systemMessage = [ZMSystemMessage insertNewObjectInManagedObjectContext:self.uiMOC];
    systemMessage.visibleInConversation = conv;
    systemMessage.systemMessageType = ZMSystemMessageTypeNewClient;
    systemMessage.sender = selfUser;
    systemMessage.clients = [NSSet setWithObject:selfClient];
    systemMessage.serverTimestamp = [NSDate date];
    
    // when
    [conv replaceNewClientMessageIfNeededWithNewDeviceMesssage];
    
    // then
    XCTAssertEqual(systemMessage.systemMessageType, ZMSystemMessageTypeUsingNewDevice);
}

@end
