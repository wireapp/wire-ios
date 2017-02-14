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


- (void)testThatItReturnsGivenNameForUser
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
    DisplayNameGenerator *generator = [[DisplayNameGenerator alloc] initWithManagedObjectContext:self.uiMOC];
    NSString *displayName1 = [generator givenNameFor:user1];
    NSString *displayName2 = [generator givenNameFor:user2];
    NSString *displayName3 = [generator givenNameFor:user3];

    // then
    XCTAssertEqualObjects(displayName1, @"Anna");
    XCTAssertEqualObjects(displayName2, @"Anna");
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
    DisplayNameGenerator *generator = [[DisplayNameGenerator alloc] initWithManagedObjectContext:self.uiMOC];
    NSString *initials1 = [generator initialsFor:user1];
    NSString *initials2 = [generator initialsFor:user2];
    NSString *initials3 = [generator initialsFor:user3];
    
    // then
    XCTAssertEqualObjects(initials1, @"AB");
    XCTAssertEqualObjects(initials2, @"A");
    XCTAssertEqualObjects(initials3, @"BA");
}

@end



@implementation ZMUserDisplayNameGeneratorTest (Performance)

- (void)testDisplayNamePerformanceForGivenNames_FirstAccess
{
    // average: 0.003, relative standard deviation: 203.282%, values: [0.021145, 0.000971, 0.000854, 0.000955, 0.000901, 0.000912, 0.000846, 0.000868, 0.001065, 0.001276]

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

- (void)testDisplayNamePerformanceForGivenNames_SecondAccess
{
    // average: 0.001, relative standard deviation: 4.426%, values: [0.000564, 0.000552, 0.000532, 0.000524, 0.000514, 0.000577, 0.000541, 0.000561, 0.000517, 0.000588]

    [self measureMetrics:@[XCTPerformanceMetric_WallClockTime] automaticallyStartMeasuring:NO forBlock:^{
        [self resetUIandSyncContextsAndResetPersistentStore:YES];
        NSMutableArray *users = [NSMutableArray array];
        for (size_t i = 0; i < (sizeof(UserNames)/sizeof(*UserNames)); ++i) {
            ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
            user.name = UserNames[i];
            [users addObject:user];
            XCTAssertNotNil(user.displayName);
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

- (void)testPerformanceForInitials_FirstAccess
{
    // average: 0.003, relative standard deviation: 197.335%, values: [0.022672, 0.001109, 0.001086, 0.001095, 0.001128, 0.001081, 0.001140, 0.001099, 0.001130, 0.001223],
    [self measureMetrics:@[XCTPerformanceMetric_WallClockTime] automaticallyStartMeasuring:NO forBlock:^{
        [self resetUIandSyncContextsAndResetPersistentStore:YES];

        NSMutableArray *users = [NSMutableArray array];
        for (size_t i = 0; i < (sizeof(UserNames)/sizeof(*UserNames)); ++i) {
            ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
            user.name = UserNames[i];
            [users addObject:user];
        }
        XCTAssertNotNil(users);
        XCTAssert([self.uiMOC saveOrRollback]);
        XCTAssertEqual(users.count, 198u);
        
        [self startMeasuring];
        {
            for (ZMUser *user in users) {
                XCTAssertNotNil(user.initials);
            }
        }
        [self stopMeasuring];
    }];
}

- (void)testPerformanceForInitials_SecondAccess
{
    // 0.000, relative standard deviation: 7.984%, values: [0.000499, 0.000416, 0.000427, 0.000389, 0.000486, 0.000403, 0.000434, 0.000446, 0.000439, 0.000394]
    [self measureMetrics:@[XCTPerformanceMetric_WallClockTime] automaticallyStartMeasuring:NO forBlock:^{
        [self resetUIandSyncContextsAndResetPersistentStore:YES];
        
        NSMutableArray *users = [NSMutableArray array];
        for (size_t i = 0; i < (sizeof(UserNames)/sizeof(*UserNames)); ++i) {
            ZMUser *user = [ZMUser insertNewObjectInManagedObjectContext:self.uiMOC];
            user.name = UserNames[i];
            [users addObject:user];
            XCTAssertNotNil(user.initials);
        }
        XCTAssertNotNil(users);
        XCTAssert([self.uiMOC saveOrRollback]);
        XCTAssertEqual(users.count, 198u);
        
        [self startMeasuring];
        {
            for (ZMUser *user in users) {
                XCTAssertNotNil(user.initials);
            }
        }
        [self stopMeasuring];
    }];
}



@end

