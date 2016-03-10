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


#import "MessagingTest.h"
#import "ZMManagedObjectContext.h"
#import "ZMUser+Internal.h"
#import "ZMConversation+Internal.h"


@interface ZMManagedObjectContextTests : MessagingTest
@end



@implementation ZMManagedObjectContextTests

- (void)testThatUpdatedKeysForRefreshIsSetInsideObjectsDidChangeAndWeCanClearIt
{
    // given
    XCTAssert([self.uiMOC isKindOfClass:[ZMManagedObjectContext class]]);
    __block NSManagedObjectID *moid;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMUser *syncUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        syncUser.name = @"Some name";
        [self.syncMOC saveOrRollback];
        moid = syncUser.objectID;
    }];
    
    __block NSNotification *saveNotification;
    [self expectationForNotification:NSManagedObjectContextDidSaveNotification object:self.syncMOC handler:^BOOL(NSNotification *notification) {
        saveNotification = notification;
        return YES;
    }];
    
    ZMUser *user = (id) [self.uiMOC objectWithID:moid];
    XCTAssertEqualObjects(user.name, @"Some name"); // This will fault in the user's data
    XCTAssertFalse(user.isFault);
    XCTAssertNil([user updatedKeysForRefresh], @"No refreshed keys outside the -mergeChanges...");
    
    // when
    [self.syncMOC performGroupedBlock:^{
        ZMUser *syncUser = (id) [self.syncMOC objectWithID:moid];
        syncUser.name = @"New name";
        [self.syncMOC saveOrRollback];
    }];
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
    
    // then
    XCTAssertNotNil(saveNotification);
    XCTAssertNotNil(saveNotification.userInfo[NSUpdatedObjectsKey]);
    NSSet *updated = saveNotification.userInfo[NSUpdatedObjectsKey];
    XCTAssertEqual(updated.count, 1u);
    
    // and then
    // (we merge the save notification)
    [self expectationForNotification:NSManagedObjectContextObjectsDidChangeNotification object:self.uiMOC handler:^BOOL(NSNotification *notification) {
        NSSet *refreshed = notification.userInfo[NSRefreshedObjectsKey];
        XCTAssertEqual(refreshed.count, 1u);
        ZMUser *refreshedUser = [refreshed anyObject];
        XCTAssertEqual(refreshedUser, user);
        NSSet *expectedSet = [NSSet setWithArray:@[@"name", @"normalizedName"]];
        XCTAssertEqualObjects(refreshedUser.updatedKeysForRefresh, expectedSet);
        [self.uiMOC clearCustomSnapshotsWithObjectChangeNotification:notification];
        return YES;
    }];
    
    [self.uiMOC mergeChangesFromContextDidSaveNotification:saveNotification];
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
    
    // then
    XCTAssertNil([user updatedKeysForRefresh]);
}

- (void)testThatUpdatedKeysForRefreshIsAnEmptySetIfTheObjectHasNoChanges
{
    // given
    XCTAssert([self.uiMOC isKindOfClass:[ZMManagedObjectContext class]]);
    __block NSManagedObjectID *moid1;
    __block NSManagedObjectID *moid2;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMUser *syncUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        syncUser.name = @"Some name 1";
        [self.syncMOC saveOrRollback];
        moid1 = syncUser.objectID;
        syncUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        syncUser.name = @"Some name 2";
        [self.syncMOC saveOrRollback];
        moid2 = syncUser.objectID;

    }];
    
    __block NSNotification *saveCotification;
    [self expectationForNotification:NSManagedObjectContextDidSaveNotification object:self.syncMOC handler:^BOOL(NSNotification *notification) {
        saveCotification = notification;
        return YES;
    }];
    
    ZMUser *user1 = (id) [self.uiMOC objectWithID:moid1];
    ZMUser *user2 = (id) [self.uiMOC objectWithID:moid2];
    // Fault them in:
    (void) user1.name;
    (void) user2.name;
    
    // when
    [self.syncMOC performGroupedBlock:^{
        ZMUser *syncUser = (id) [self.syncMOC objectWithID:moid1];
        syncUser.name = @"New name";
        [self.syncMOC saveOrRollback];
    }];
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
    
    // then
    [self expectationForNotification:NSManagedObjectContextObjectsDidChangeNotification object:self.uiMOC handler:^BOOL(NSNotification *notification) {
        NOT_USED(notification);
        XCTAssertNotNil(user1.updatedKeysForRefresh);
        XCTAssertEqual(user1.updatedKeysForRefresh.count, 2u, @"%@", user1.updatedKeysForRefresh);
        XCTAssertNotNil(user2.updatedKeysForRefresh);
        XCTAssertEqual(user2.updatedKeysForRefresh.count, 0u);
        return YES;
    }];
    
    [self.uiMOC mergeChangesFromContextDidSaveNotification:saveCotification];
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}

- (void)testThatUpdatedKeysForRefreshIsAnEmptySetForInsertedObjects
{
    // given
    XCTAssert([self.uiMOC isKindOfClass:[ZMManagedObjectContext class]]);
    __block NSManagedObjectID *moid;
    [self.syncMOC performGroupedBlock:^{
        ZMUser *syncUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        conversation.lastModifiedDate = [NSDate date];
        [conversation.mutableOtherActiveParticipants addObject:syncUser];
        syncUser.name = @"Some name";
        
        [self.syncMOC saveOrRollback];
        moid = syncUser.objectID;
        XCTAssertNotNil(moid);
    }];
    __block NSNotification *saveNotification;
    [self expectationForNotification:NSManagedObjectContextDidSaveNotification object:self.syncMOC handler:^BOOL(NSNotification *notification) {
        saveNotification = notification;
        return YES;
    }];
    WaitForAllGroupsToBeEmpty(0.2);
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
    
    // expect
    ZMUser *user = (moid == nil) ? nil : (id) [self.uiMOC objectWithID:moid];
    [self expectationForNotification:NSManagedObjectContextObjectsDidChangeNotification object:self.uiMOC handler:^BOOL(NSNotification *notification) {
        NOT_USED(notification);
        XCTAssertNotNil(user.updatedKeysForRefresh);
        XCTAssertEqual(user.updatedKeysForRefresh.count, 0u);
        return YES;
    }];
    
    // when
    [self.uiMOC mergeChangesFromContextDidSaveNotification:saveNotification];
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
    
    XCTAssertNil([user updatedKeysForRefresh], @"No refreshed keys outside the -mergeChanges...");
}

- (void)testThatUpdatedKeysForChangeNotificationIsSetForLocalChanges;
{
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    [self.uiMOC saveOrRollback];
    XCTAssertEqual(user.updatedKeysForChangeNotification.count, 0u);
    user.name = @"Some name";
    NSSet *expectedSet = [NSSet setWithArray:@[@"name", @"normalizedName"]];
    XCTAssertEqualObjects(user.updatedKeysForChangeNotification, expectedSet);
}

- (void)testUpdatedKeysForRefreshPerformance;
{
    XCTAssert([self.uiMOC isKindOfClass:[ZMManagedObjectContext class]]);
    __block NSManagedObjectID *moid1;
    __block NSManagedObjectID *moid2;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMUser *syncUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        syncUser.name = @"Some name 1";
        syncUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        syncUser.name = @"Some name 2";
        [self.syncMOC saveOrRollback];
        moid1 = syncUser.objectID;
        moid2 = syncUser.objectID;
    }];
    
    __block int counter;
    [self measureMetrics:@[XCTPerformanceMetric_WallClockTime] automaticallyStartMeasuring:NO forBlock:^{
        
        ZMUser *user1 = (id) [self.uiMOC objectWithID:moid1];
        ZMUser *user2 = (id) [self.uiMOC objectWithID:moid2];
        // Fault them in:
        (void) user1.name;
        (void) user2.name;
        
        // Create a "did save" notification:
        __block NSNotification *saveCotification;
        [self expectationForNotification:NSManagedObjectContextDidSaveNotification object:self.syncMOC handler:^BOOL(NSNotification *notification) {
            saveCotification = notification;
            return YES;
        }];
        // when
        [self.syncMOC performGroupedBlock:^{
            ZMUser *syncUser = (id) [self.syncMOC objectWithID:moid1];
            syncUser.name = [NSString stringWithFormat:@"New name %d", counter++];
            syncUser = (id) [self.syncMOC objectWithID:moid2];
            syncUser.name = [NSString stringWithFormat:@"New name %d", counter++];
            [self.syncMOC saveOrRollback];
        }];
        XCTAssert([self waitForCustomExpectationsWithTimeout:1]);
        
        id token = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:self.uiMOC queue:nil usingBlock:^(NSNotification *note) {
            for (NSManagedObject *mo in note.userInfo[NSRefreshedObjectsKey]) {
                [[mo updatedKeysForChangeNotification] count];
            }
        }];
        
        [self startMeasuring];
        
        [self.uiMOC mergeChangesFromContextDidSaveNotification:saveCotification];
        [self.uiMOC processPendingChanges];
        
        [self stopMeasuring];
        
        [[NSNotificationCenter defaultCenter] removeObserver:token];
        WaitForAllGroupsToBeEmpty(0.5);
    }];
}

- (void)testThatItReturnsTheSnapshotValueForInContextChanges;
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSString *originalName = @"Name A";
    NSString *newName = @"Name B";
    user.name = originalName;
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // when
    user.name = newName;
    
    // then
    XCTAssertEqualObjects(user.name, newName);
    XCTAssertEqualObjects([user snapshotValueForKey:@"name"], originalName);
}

- (void)testThatItReturnsTheSnapshotValueForInContextSaves;
{
    // given
    ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    NSString *originalName = @"Name A";
    NSString *newName = @"Name B";
    user.name = originalName;
    XCTAssert([self.uiMOC saveOrRollback]);
    
    __block NSString *snapshotName;
    [self expectationForNotification:NSManagedObjectContextObjectsDidChangeNotification object:self.uiMOC handler:^BOOL(NSNotification *notification) {
        (void) notification;
        XCTAssertEqualObjects(user.name, newName);
        snapshotName = (id) [user snapshotValueForKey:@"name"];
        return YES;
    }];
    
    // when
    user.name = newName;
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // then
    XCTAssertEqualObjects(snapshotName, originalName);
}

- (void)testThatItReturnsTheSnapshotValueWhenMergingASave
{
    // given
    NSString *initialName = @"Some name";
    NSString *finalName = @"New name";
    XCTAssert([self.uiMOC isKindOfClass:[ZMManagedObjectContext class]]);
    __block NSManagedObjectID *moid;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMUser *syncUser = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        syncUser.name = initialName;
        [self.syncMOC saveOrRollback];
        moid = syncUser.objectID;
    }];
    
    __block NSNotification *saveNotification;
    [self expectationForNotification:NSManagedObjectContextDidSaveNotification object:self.syncMOC handler:^BOOL(NSNotification *notification) {
        saveNotification = notification;
        return YES;
    }];
    
    ZMUser *user = (id) [self.uiMOC objectWithID:moid];
    XCTAssertEqualObjects(user.name, initialName); // This will fault in the user's data
    XCTAssertFalse(user.isFault);
    XCTAssertNil([user updatedKeysForRefresh], @"No refreshed keys outside the -mergeChanges...");
    
    // when
    [self.syncMOC performGroupedBlock:^{
        ZMUser *syncUser = (id) [self.syncMOC objectWithID:moid];
        syncUser.name = finalName;
        [self.syncMOC saveOrRollback];
    }];
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
    
    // then
    XCTAssertNotNil(saveNotification);
    XCTAssertNotNil(saveNotification.userInfo[NSUpdatedObjectsKey]);
    NSSet *updated = saveNotification.userInfo[NSUpdatedObjectsKey];
    XCTAssertEqual(updated.count, 1u);
    
    // and then
    // (we merge the save notification)
    [self expectationForNotification:NSManagedObjectContextObjectsDidChangeNotification object:self.uiMOC handler:^BOOL(NSNotification *notification) {
        NSSet *refreshed = notification.userInfo[NSRefreshedObjectsKey];
        XCTAssertEqual(refreshed.count, 1u);
        ZMUser *refreshedUser = [refreshed anyObject];
        XCTAssertEqual(refreshedUser, user);
        XCTAssertEqualObjects([refreshedUser name], finalName);
        XCTAssertEqualObjects([refreshedUser snapshotValueForKey:@"name"], initialName);
        return YES;
    }];
    
    [self.uiMOC mergeChangesFromContextDidSaveNotification:saveNotification];
    XCTAssert([self waitForCustomExpectationsWithTimeout:0.5]);
}

@end


@implementation ZMManagedObjectContextTests (CleanUp)

- (void)testThatOlderMessagesInAConversationAreRefreshedAfterASave
{
    static const NSUInteger MessagesToKeep = 3;
    static const NSUInteger MessagesToCreate = MessagesToKeep + 10;
    
    
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // given
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        for(NSUInteger i = 0; i < MessagesToCreate; ++ i) {
            ZMTextMessage *message = [ZMTextMessage insertNewObjectInManagedObjectContext:self.syncMOC];
            [conversation.mutableMessages addObject:message];
        }
        
        // when
        [self.syncMOC saveOrRollback];
        
        // then
        NSUInteger faultNumber = 0;
        for(ZMMessage *message in conversation.messages) {
            if(message.isFault) {
                ++faultNumber;
            }
        }
        XCTAssertEqual(faultNumber, MessagesToCreate - MessagesToKeep -1);
        
    }];
}

- (void)testThatOnlyConversationsOlderThanTwoDaysAreRefreshedAfterASave
{
    static const int HOUR_IN_SEC = 60 * 60;
    static const int STALENESS = 48 * HOUR_IN_SEC;
    
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // given
        ZMConversation *oldConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        oldConversation.lastModifiedDate = [NSDate dateWithTimeIntervalSinceNow:-STALENESS];
        
        ZMConversation *freshConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        freshConversation.lastModifiedDate = [NSDate dateWithTimeIntervalSinceNow:-30];
        
        ZMConversation *undatedConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        undatedConversation.lastModifiedDate = nil;
        
        // when
        [self.syncMOC saveOrRollback];
        
        // then
        XCTAssertTrue(oldConversation.isFault);
        XCTAssertFalse(freshConversation.isFault);
        XCTAssertFalse(undatedConversation.isFault);
    }];
}


- (void)testThatOnlyUsersThatAreNotInConversationsOlderThanTwoDaysAreRefreshedAfterASave
{
    static const int HOUR_IN_SEC = 60 * 60;
    static const int STALENESS = 48 * HOUR_IN_SEC;
    
    [self.syncMOC performGroupedBlockAndWait:^{
        
        // given
        ZMUser *selfUser = [ZMUser selfUserInContext:self.syncMOC];
        ZMUser *userInRecentConversation = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        ZMUser *userInOldConversation = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        ZMUser *inactiveUserInRecentConversation = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        ZMUser *inactiveUserInOldConversation = [ZMUser insertNewObjectInManagedObjectContext:self.syncMOC];
        
        ZMConversation *oldConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        oldConversation.lastModifiedDate = [NSDate dateWithTimeIntervalSinceNow:-STALENESS];
        [oldConversation.mutableOtherActiveParticipants addObject:userInOldConversation];
        [oldConversation.mutableOtherInactiveParticipants addObject:inactiveUserInOldConversation];
        
        ZMConversation *freshConversation = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        freshConversation.lastModifiedDate = [NSDate dateWithTimeIntervalSinceNow:-30];
        [freshConversation.mutableOtherActiveParticipants addObject:userInRecentConversation];
        [freshConversation.mutableOtherInactiveParticipants addObject:inactiveUserInRecentConversation];
        
        // when
        [self.syncMOC saveOrRollback];
        
        // then
        XCTAssertTrue(userInOldConversation.isFault);
        XCTAssertFalse(userInRecentConversation.isFault);
        XCTAssertFalse(selfUser.isFault);
        XCTAssertTrue(inactiveUserInOldConversation.isFault);
        XCTAssertTrue(inactiveUserInRecentConversation.isFault);

    }];
}



@end


