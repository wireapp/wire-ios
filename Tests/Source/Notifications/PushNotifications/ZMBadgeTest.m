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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


#import "MessagingTest.h"
#import "ZMBadge+Testing.h"
#import "ZMConversation+Internal.h"
#import "BadgeApplication.h"
#import "ZMManagedObject+Internal.h"

@import UIKit;



@interface ZMBadgeTest : MessagingTest

@property (nonatomic) ZMBadge *sut;
@property (nonatomic) BadgeApplication *badgeApplication;

@end



@implementation ZMBadgeTest

- (void)setUp
{
    [super setUp];
    self.sut = [[ZMBadge alloc] init];
    self.badgeApplication = [[BadgeApplication alloc] init];
    self.sut.application = (id) self.badgeApplication;
}

- (void)tearDown
{
    self.sut = nil;
    self.badgeApplication = nil;
    [super tearDown];
}

- (void)testThatItSetsTheApplicationBadgeCount
{
    // given
    __block NSSet *objectIDs;
    [self.syncMOC performGroupedBlockAndWait:^{
        ZMConversation *c1 = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];
        ZMConversation *c2 = [ZMConversation insertNewObjectInManagedObjectContext:self.syncMOC];

        [self.syncMOC saveOrRollback];
        objectIDs = [NSSet setWithArray:@[c1.objectID, c2.objectID]];
    }];
    
    
    // when
    [self.syncMOC performGroupedBlockAndWait:^{
        [self.sut setBadgeCount:objectIDs.count];
    }];
    WaitForAllGroupsToBeEmpty(0.5);

    // then
    NSInteger badgeCount = self.badgeApplication.applicationIconBadgeNumber;
    XCTAssertEqual(badgeCount, 2);
}


- (void)testThatItDoesNotCrashWhenPassingInANilObjectID;
{
    XCTAssertNoThrow([self.sut setBadgeCount:0]);
}

@end
