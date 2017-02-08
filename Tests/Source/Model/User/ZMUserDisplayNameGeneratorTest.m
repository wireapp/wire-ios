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


#import "ModelObjectsTests.h"
#import "ZMUser+Internal.h"


static NSString * const UserNames[] = {
    @"Adam Rivera",
    @"Alan Barnes",
    @"Albert Evans",
    @"Alice Williams",
    @"Amanda Rogers",
    @"Amy Hughes",
    @"Andrew Perez",
    @"Anna Adams",
    @"Anna Baker",
    @"Anne White",
    @"Anne Johnson",
    @"Annie Bailey",
    @"Anthony Anderson",
    @"Arthur Jenkins",
    @"Arthur Thomas",
    @"Barbara Allen",
    @"Benjamin Jones",
    @"Benjamin Wilson",
    @"Betty Carter",
    @"Billy Gonzales",
    @"Billy Robinson",
    @"Bobby Hernandez",
    @"Brandon Rodriguez",
    @"Brenda Ramirez",
    @"Brian Wood",
    @"Carl Long",
    @"Carl Morgan",
    @"Carlos Morris",
    @"Carlos Patterson",
    @"Carolyn Price",
    @"Charles Reed",
    @"Cheryl Adams",
    @"Chris Brooks",
    @"Christina Russell",
    @"Christina Phillips",
    @"Christopher Moore",
    @"Cynthia James",
    @"Daniel Cox",
    @"David Green",
    @"Deborah Roberts",
    @"Debra Carter",
    @"Debra Martinez",
    @"Dennis Ross",
    @"Diana Johnson",
    @"Diana Evans",
    @"Diane Rogers",
    @"Donald Watson",
    @"Donna Parker",
    @"Donna Simmons",
    @"Doris Bell",
    @"Douglas Wood",
    @"Earl Stewart",
    @"Edward Cooper",
    @"Emily Brown",
    @"Emily King",
    @"Eric Peterson",
    @"Ernest Sanchez",
    @"Ernest Flores",
    @"Fred Smith",
    @"Fred Gray",
    @"Gary Watson",
    @"George Gray",
    @"George Moore",
    @"Gerald Gonzales",
    @"Gloria Clark",
    @"Gregory Smith",
    @"Harold Price",
    @"Harry James",
    @"Harry Bennett",
    @"Heather Bennett",
    @"Henry Clark",
    @"Henry Morris",
    @"Howard Sanders",
    @"Irene Edwards",
    @"Jack Bell",
    @"Jack Hill",
    @"James Scott",
    @"Janet Torres",
    @"Janice Powell",
    @"Jason Parker",
    @"Jean Coleman",
    @"Jennifer Washington",
    @"Jennifer Cook",
    @"Jerry Turner",
    @"Jerry Wright",
    @"Jesse Perry",
    @"Jesse Walker",
    @"Jessica Bailey",
    @"Jimmy Roberts",
    @"Jimmy Mitchell",
    @"Joe Davis",
    @"Jonathan Thompson",
    @"Jose Hall",
    @"Joseph Taylor",
    @"Joshua Powell",
    @"Joyce Murphy",
    @"Juan Washington",
    @"Judith Martinez",
    @"Judith White",
    @"Judy Nelson",
    @"Julia Baker",
    @"Julia Anderson",
    @"Julie Simmons",
    @"Justin Morgan",
    @"Justin Jackson",
    @"Karen Nelson",
    @"Katherine Mitchell",
    @"Katherine Miller",
    @"Kathryn Gonzalez",
    @"Keith Wright",
    @"Keith Long",
    @"Kelly Sanders",
    @"Kelly Kelly",
    @"Kenneth Green",
    @"Kenneth Foster",
    @"Kevin Henderson",
    @"Kimberly Sanchez",
    @"Larry Hill",
    @"Lawrence Gonzalez",
    @"Linda Williams",
    @"Lisa Martin",
    @"Lori Lopez",
    @"Margaret Walker",
    @"Maria Murphy",
    @"Marilyn Harris",
    @"Mark Flores",
    @"Martha Hernandez",
    @"Martin Thompson",
    @"Mary Collins",
    @"Mary Lewis",
    @"Matthew Stewart",
    @"Mildred Jenkins",
    @"Nancy Perez",
    @"Nicholas Ross",
    @"Nicholas Diaz",
    @"Nicole Richardson",
    @"Nicole Lee",
    @"Norma Butler",
    @"Pamela Young",
    @"Patricia Foster",
    @"Patrick Howard",
    @"Patrick Allen",
    @"Paula Torres",
    @"Paula Henderson",
    @"Peter Cooper",
    @"Peter Taylor",
    @"Philip Miller",
    @"Phillip Peterson",
    @"Phillip Reed",
    @"Phyllis Wilson",
    @"Ralph Davis",
    @"Randy Campbell",
    @"Randy Rivera",
    @"Raymond Lee",
    @"Rebecca Richardson",
    @"Robert Kelly",
    @"Robert Brooks",
    @"Ronald Butler",
    @"Rose Coleman",
    @"Rose Hall",
    @"Roy Ward",
    @"Ruby Ramirez",
    @"Ruth Howard",
    @"Ryan Diaz",
    @"Samuel Martin",
    @"Sara Garcia",
    @"Sara Griffin",
    @"Sarah Harris",
    @"Scott Bryant",
    @"Scott Scott",
    @"Sean Robinson",
    @"Sean Young",
    @"Sharon Bryant",
    @"Shirley Alexander",
    @"Stephen Edwards",
    @"Stephen Russell",
    @"Steve King",
    @"Steven Rodriguez",
    @"Susan Patterson",
    @"Tammy Lopez",
    @"Teresa Ward",
    @"Teresa Perry",
    @"Terry Campbell",
    @"Theresa Hughes",
    @"Theresa Cox",
    @"Thomas Barnes",
    @"Timothy Lewis",
    @"Tina Thomas",
    @"Tina Collins",
    @"Todd Turner",
    @"Victor Jackson",
    @"Victor Garcia",
    @"Walter Alexander",
    @"Walter Brown",
    @"Wanda Phillips",
    @"Wayne Cook",
    @"William Griffin",
    @"Willie Jones"
};

@interface ZMUserDisplayNameGeneratorTest : ZMBaseManagedObjectTest

- (NSNotification *)notificationForInsertedObject:(NSSet *)insertedObjects updatedObjects:(NSSet *)updatedObjects deletedObjects:(NSSet *)deletedObjects;

@end

@implementation ZMUserDisplayNameGeneratorTest

- (NSNotification *)notificationForInsertedObject:(NSSet *)insertedObjects updatedObjects:(NSSet *)updatedObjects deletedObjects:(NSSet *)deletedObjects
{
    return [NSNotification notificationWithName:@"TestNotification" object:nil userInfo:@{
                                                                                          NSInsertedObjectsKey : insertedObjects ?: [NSSet set],
                                                                                          NSUpdatedObjectsKey : updatedObjects ?: [NSSet set],
                                                                                          NSDeletedObjectsKey : deletedObjects ?: [NSSet set]
                                                                                          }];
}

- (void)testThatItFetchesAllUsers
{
    // given
    ZMUser *selfUser = [ZMUser selfUserInContext:self.uiMOC];
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user1.name = @"User 1";
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user2.name = @"User 2";
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // when
    DisplayNameGenerator *generator = [[DisplayNameGenerator alloc] initWithManagedObjectContext:self.uiMOC allUsers:nil];
    [generator fetchAllUsersIfNeeded];
    
    // then
    NSSet *expectedUsers = [NSSet setWithObjects:selfUser, user1, user2, nil];
    XCTAssertEqualObjects(generator.allUsers, expectedUsers);
}


- (void)testThatItReturnsDisplayNameForUser
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user1.name = @"Anna Blume";
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user2.name = @"Anna Sturm";
    ZMUser *user3 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user3.name = @"Ben Affleck";
    XCTAssert([self.uiMOC saveOrRollback]);
    
    // when
    DisplayNameGenerator *generator = [[DisplayNameGenerator alloc] initWithManagedObjectContext:self.uiMOC allUsers:nil];
    NSString *displayName1 = [generator displayNameFor:user1];
    NSString *displayName2 = [generator displayNameFor:user2];
    NSString *displayName3 = [generator displayNameFor:user3];

    // then
    XCTAssertEqualObjects(displayName1, @"Anna Blume");
    XCTAssertEqualObjects(displayName2, @"Anna Sturm");
    XCTAssertEqualObjects(displayName3, @"Ben");
}

- (void)testThatItReturnsInitialsForUser
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user1.name = @"Anna Blume";
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user2.name = @"Anna";
    ZMUser *user3 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user3.name = @"Ben Sexy Affleck";
    XCTAssert([self.uiMOC saveOrRollback]);

    // when
    DisplayNameGenerator *generator = [[DisplayNameGenerator alloc] initWithManagedObjectContext:self.uiMOC allUsers:nil];
    NSString *initials1 = [generator initialsFor:user1];
    NSString *initials2 = [generator initialsFor:user2];
    NSString *initials3 = [generator initialsFor:user3];
    
    // then
    XCTAssertEqualObjects(initials1, @"AB");
    XCTAssertEqualObjects(initials2, @"A");
    XCTAssertEqualObjects(initials3, @"BA");
}

@end



@implementation ZMUserDisplayNameGeneratorTest (ManagedObjectContext)

- (void)testThatItDoesNotUpdateDisplayNameGeneratorIfItIsNotSetInitially
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user1.name = @"Anna Blume";
    
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user2.name = @"Anna SuperDuper";
    [self updateDisplayNameGeneratorWithUsers:@[user1, user2]];

    XCTAssertEqualObjects(user1.displayName, user1.name);
    XCTAssertEqualObjects(user2.displayName, user2.name);
    
    // when
    self.uiMOC.nameGenerator = nil;
    NSSet *updatedSet = [self.uiMOC updateNameGeneratorWithUpdatedUsers:[NSSet set] insertedUsers:[NSSet set] deletedUsers:[NSSet setWithObject:user2]];
    
    // then
    XCTAssertEqual(updatedSet.count, 0u);
}

- (void)testThatItReturnsTheCorrectSetForChangedNamesWhenAUserIsRemovedFromTheContext
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user1.name = @"Anna Blume";
    
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user2.name = @"Ben SuperDuper";
    
    ZMUser *user3 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user3.name = @"Anna";
    [self updateDisplayNameGeneratorWithUsers:@[user1, user2, user3]];

    XCTAssertEqualObjects(user1.displayName, @"Anna Blume");
    XCTAssertEqualObjects(user2.displayName, @"Ben");
    XCTAssertEqualObjects(user3.displayName, @"Anna");

    // when
    NSSet *updatedSet = [self.uiMOC updateNameGeneratorWithUpdatedUsers:[NSSet set] insertedUsers:[NSSet set] deletedUsers:[NSSet setWithObject:user3]];
    
    // then
    NSSet *expectedSet = [NSSet setWithObject:user1];
    XCTAssertEqual(updatedSet.count, 1u);
    XCTAssertEqualObjects(updatedSet, expectedSet);
    
    XCTAssertEqualObjects(user1.displayName, @"Anna");
    XCTAssertEqualObjects(user2.displayName, @"Ben");
}

- (void)testThatItReturnsTheCorrectSetForChangedNamesWhenAUserChangesHisName
{
    // given
    ZMUser *user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user1.name = @"Anna Blume";
    
    ZMUser *user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
    user2.name = @"Ben SuperDuper";
    [self updateDisplayNameGeneratorWithUsers:@[user1, user2]];

    XCTAssertEqualObjects(user1.displayName, @"Anna");
    XCTAssertEqualObjects(user2.displayName, @"Ben");
    
    // when
    user2.name = @"Anna";
    NSSet *updatedSet =  [self.uiMOC updateNameGeneratorWithUpdatedUsers:[NSSet setWithObject:user2] insertedUsers:[NSSet set] deletedUsers:[NSSet set]];
    
    // then
    NSSet *expectedSet = [NSSet setWithObjects:user2, user1, nil];
    XCTAssertEqual(updatedSet.count, 2u);
    XCTAssertEqualObjects(updatedSet, expectedSet);
    
    XCTAssertEqualObjects(user1.displayName, @"Anna Blume");
    XCTAssertEqualObjects(user2.displayName, @"Anna");
}

- (void)testThatItKeepsAStrongRefereneToAllUsers;
{
    // given
    ZMUser *user1;
    ZMUser *user2;
    {
        user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
        user1.name = @"Anna Blume";
        
        user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
        user2.name = @"Ben SuperDuper";
        
        XCTAssert([self.uiMOC saveOrRollback]);
        
        // when
        //
        // Ask for the display names to trigger changes and make the generator have a strong reference.
        // If we never ask for the name, we can't expect to get notifications about changes.
        XCTAssertNotNil(user1.displayName);
        XCTAssertNotNil(user2.displayName);
    }
    
    // Turn everything into a fault:
    for (NSManagedObject *mo in self.uiMOC.registeredObjects) {
        [self.uiMOC refreshObject:mo mergeChanges:NO];
    }
    [self.uiMOC processPendingChanges];
    
    
    // then
    //
    // The users should still be around
    NSMutableArray *registeredUsers = [NSMutableArray array];
    for (NSManagedObject *mo in self.uiMOC.registeredObjects) {
        if ([mo.entity.name isEqual:ZMUser.entityName]) {
            [registeredUsers addObject:mo];
        }
    }
    NSSet *user1and2 = [NSSet setWithObjects:user1, user2, nil];
    XCTAssertTrue([user1and2 isSubsetOfSet:[NSSet setWithArray:registeredUsers]]);
}

- (void)testThatItMakesSureNoneOfTheUsersAreFaultsWhenItProcessesChanges;
{
    // given
    ZMUser *user1;
    ZMUser *user2;
    {
        user1 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
        user1.name = @"Anna Blume";
        
        user2 = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
        user2.name = @"Ben SuperDuper";
        
        XCTAssert([self.uiMOC saveOrRollback]);
        
        // when
        //
        // Ask for the display names to trigger changes and make the generator have a strong reference.
        // If we never ask for the name, we can't expect to get notifications about changes.
        XCTAssertNotNil(user1.displayName);
        XCTAssertNotNil(user2.displayName);
    }
    
    // Turn everything into a fault:
    for (NSManagedObject *mo in self.uiMOC.registeredObjects) {
        [self.uiMOC refreshObject:mo mergeChanges:NO];
    }
    [self.uiMOC processPendingChanges];
    [self.uiMOC updateNameGeneratorWithUpdatedUsers:[NSSet setWithObject:user1] insertedUsers:[NSSet set] deletedUsers:[NSSet set]];
    
    // then
    XCTAssertFalse(user1.isFault);
    XCTAssertFalse(user2.isFault);
}

@end


@implementation ZMUserDisplayNameGeneratorTest (Performance)

- (void)testDisplayNamePerformanceForDisplayNames
{
    // before: average: 0.000, relative standard deviation: 15.034%, values: [0.000149, 0.000135, 0.000134, 0.000107, 0.000125, 0.000115, 0.000177, 0.000113, 0.000118, 0.000123]
    // after: average: 0.000, relative standard deviation: 9.364%, values: [0.000300, 0.000228, 0.000221, 0.000244, 0.000244, 0.000228, 0.000221, 0.000245, 0.000222, 0.000243]
    [self measureMetrics:@[XCTPerformanceMetric_WallClockTime] automaticallyStartMeasuring:NO forBlock:^{
        [self resetUIandSyncContextsAndResetPersistentStore:YES];
        NSMutableArray *users = [NSMutableArray array];
        for (size_t i = 0; i < (sizeof(UserNames)/sizeof(*UserNames)); ++i) {
            ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
            user.name = UserNames[i];
            [users addObject:user];
        }
        XCTAssertNotNil(users);
        XCTAssertEqual(users.count, 198u);
        XCTAssert([self.uiMOC saveOrRollback]);
        
        WaitForAllGroupsToBeEmpty(0.5);
        
        [self startMeasuring];
        {
            for (ZMUser *user in users) {
                XCTAssertNotNil(user.displayName);
            }
        }
        [self stopMeasuring];
    }];
}

- (void)testPerformanceForInitials
{
    // average: 0.000, relative standard deviation: 106.904%, values: [0.000149, 0.000104, 0.000096, 0.000757, 0.000117, 0.000097, 0.000154, 0.000098, 0.000111, 0.000123],
    // average: 0.000, relative standard deviation: 24.868%, values: [0.000795, 0.000297, 0.000362, 0.000302, 0.000334, 0.000328, 0.000361, 0.000309, 0.000306, 0.000392],
    [self measureMetrics:@[XCTPerformanceMetric_WallClockTime] automaticallyStartMeasuring:NO forBlock:^{
        [self resetUIandSyncContextsAndResetPersistentStore:YES];

        NSMutableArray *users = [NSMutableArray array];
        for (size_t i = 0; i < (sizeof(UserNames)/sizeof(*UserNames)); ++i) {
            ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
            user.name = UserNames[i];
            [users addObject:user];
        }
        XCTAssertNotNil(users);
        XCTAssertEqual(users.count, 198u);
        [self updateDisplayNameGeneratorWithUsers:users];
        
        [self startMeasuring];
        {
            for (ZMUser *user in users) {
                XCTAssertNotNil(user.initials);
            }
        }
        [self stopMeasuring];
    }];
}

- (void)testDisplayNamePerformanceWhenChangingAUserName
{
    // old system: average: 0.001, relative standard deviation: 10.917%, values: [0.001375, 0.001146, 0.001141, 0.001142, 0.001551, 0.001360, 0.001423, 0.001230, 0.001197, 0.001144]
    // average: 0.006, relative standard deviation: 109.292%, values: [0.024821, 0.003850, 0.003629, 0.003675, 0.003652, 0.003567, 0.003655, 0.004051, 0.003516, 0.003606
    [self measureMetrics:@[XCTPerformanceMetric_WallClockTime] automaticallyStartMeasuring:NO forBlock:^{
        [self resetUIandSyncContextsAndResetPersistentStore:YES];
        
        NSMutableArray *users = [NSMutableArray array];
        for (size_t i = 0; i < (sizeof(UserNames)/sizeof(*UserNames)); ++i) {
            ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
            user.name = UserNames[i];
            [users addObject:user];
        }
        XCTAssertNotNil(users);
        XCTAssertEqual(users.count, 198u);
        XCTAssert([self.uiMOC saveOrRollback]);
        
        ZMUser *existingUser = users[0];
        (void) existingUser.displayName;
        NSString *newName = @"Brian WhoKnows";
        XCTAssertNotEqualObjects(existingUser.name, newName);
        
        existingUser.name = newName;
        [self.uiMOC saveOrRollback];
        
        [self startMeasuring];
        {
            [self.uiMOC updateNameGeneratorWithUpdatedUsers:[NSSet setWithObject:existingUser] insertedUsers:[NSSet set] deletedUsers:[NSSet set]];
            for (ZMUser *user in users) {
                XCTAssertNotNil(user.displayName);
            }
        }
        [self stopMeasuring];
        
        XCTAssertEqualObjects(existingUser.displayName, newName);
    }];

}

- (void)testPerformanceWhenInsertingAUserWithAnExistingUserName
{
    // average: 0.001, relative standard deviation: 12.563%, values: [0.001146, 0.001109, 0.001155, 0.001154, 0.001117, 0.001075, 0.001109, 0.001086, 0.001596, 0.001095]
    // average: 0.002, relative standard deviation: 2.371%, values: [0.001641, 0.001630, 0.001646, 0.001566, 0.001544, 0.001579, 0.001647, 0.001559, 0.001580, 0.001572]
    
    [self measureMetrics:@[XCTPerformanceMetric_WallClockTime] automaticallyStartMeasuring:NO forBlock:^{
        [self resetUIandSyncContextsAndResetPersistentStore:YES];
        
        NSMutableArray *users = [NSMutableArray array];
        for (size_t i = 0; i < (sizeof(UserNames)/sizeof(*UserNames)); ++i) {
            ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
            user.name = UserNames[i];
            [users addObject:user];
        }
        XCTAssertNotNil(users);
        XCTAssertEqual(users.count, 198u);
        [self updateDisplayNameGeneratorWithUsers:users];
        
        ZMUser *existingUser = users[0];
        XCTAssertEqualObjects(existingUser.name, @"Adam Rivera");
        XCTAssertEqualObjects(existingUser.displayName, @"Adam");
        
        for (ZMUser *user in users) {
            XCTAssertNotNil(user.displayName);
        }
        
        ZMUser *newUser = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
        newUser.name = existingUser.name;
        [users addObject:newUser];
        
        XCTAssert([self.uiMOC saveOrRollback]);
        [self startMeasuring];
        {
            [self.uiMOC updateNameGeneratorWithUpdatedUsers:[NSSet set] insertedUsers:[NSSet setWithObject:newUser] deletedUsers:[NSSet set]];
            for (ZMUser *user in users) {
                XCTAssertNotNil(user.displayName);
            }
        }
        [self stopMeasuring];
        
        XCTAssertEqualObjects(existingUser.displayName, @"Adam Rivera");
    }];
}

- (void)testDisplayNamePerformanceWhenRemovingAUserWithAnExistingUserName
{
    // average: 0.001, relative standard deviation: 2.793%, values: [0.001145, 0.001081, 0.001156, 0.001155, 0.001091, 0.001085, 0.001130, 0.001088, 0.001088, 0.001078],
    // average: 0.002, relative standard deviation: 4.928%, values: [0.001804, 0.001729, 0.001585, 0.001650, 0.001536, 0.001557, 0.001637, 0.001586, 0.001680, 0.001722]
    
    [self measureMetrics:@[XCTPerformanceMetric_WallClockTime] automaticallyStartMeasuring:NO forBlock:^{
        [self resetUIandSyncContextsAndResetPersistentStore:YES];
        NSMutableArray *users = [NSMutableArray array];
        for (size_t i = 0; i < (sizeof(UserNames)/sizeof(*UserNames)); ++i) {
            ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
            user.name = UserNames[i];
            [users addObject:user];
        }
        XCTAssertNotNil(users);
        XCTAssertEqual(users.count, 198u);
        [self updateDisplayNameGeneratorWithUsers:users];
        
        ZMUser *existingUser1 = users[13];
        XCTAssertEqualObjects(existingUser1.name, @"Arthur Jenkins");
        
        ZMUser *existingUser2 = users[14];
        XCTAssertEqualObjects(existingUser2.name, @"Arthur Thomas");
        XCTAssertEqualObjects(existingUser2.displayName, @"Arthur Thomas");
        
        [users removeObject:existingUser1];
        
        XCTAssert([self.uiMOC saveOrRollback]);
        
        [self startMeasuring];
        {
            [self.uiMOC updateNameGeneratorWithUpdatedUsers:[NSSet set] insertedUsers:[NSSet set] deletedUsers:[NSSet setWithObject:existingUser1]];
            for (ZMUser *user in users) {
                XCTAssertNotNil(user.displayName);
            }
        }
        [self stopMeasuring];
        
        XCTAssertEqualObjects(existingUser2.displayName, @"Arthur");
    }];
}

@end

