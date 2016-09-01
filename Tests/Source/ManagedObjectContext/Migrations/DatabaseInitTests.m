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


@import ZMCDataModel;

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>
#import <ZMTesting/ZMTesting.h>
#import <OCMock/OCMock.h>
#import "DatabaseBaseTest.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "NSManagedObjectContext+zmessaging-Internal.h"



@interface DatabaseInitTests : DatabaseBaseTest

@end



@implementation DatabaseInitTests

- (void)setUp
{
    [super setUp];
    [self performIgnoringZMLogError:^{
        [NSManagedObjectContext initPersistentStoreCoordinatorBackingUpCorrupedDatabases:NO];
    }];
}

- (void)cleanUp
{
    NSError *error;
    XCTAssertTrue([NSFileManager.defaultManager removeItemAtURL:self.sharedContainerDirectoryURL error:&error]);
    XCTAssertNil(error);
    [super cleanUp];
}

- (void)testThatItReturnsNeedsMigrationInCaseDatabaseEncrypted {
    
    // given
    id classMock = [OCMockObject mockForClass:[NSManagedObjectContext class]];
    [[classMock expect] initPersistentStoreCoordinatorBackingUpCorrupedDatabases:NO];
    [[[classMock stub] andReturnValue:@NO] databaseExistsInApplicationSupportDirectory];
    [self verifyMockLater:classMock];

    XCTAssertFalse([NSManagedObjectContext needsToPrepareLocalStoreInDirectory:self.sharedContainerDirectoryURL]);
    
    // when
    [[[classMock stub] andReturnValue:@YES] databaseExistsAndNotReadableDueToEncryption];
    
    // then
    XCTAssertTrue([NSManagedObjectContext needsToPrepareLocalStoreInDirectory:self.sharedContainerDirectoryURL]);
    [classMock stopMocking];
}

- (void)testThatItReturnsNeedsMigrationInCaseDatabaseExistsInApplicationSupportDirectory {
    
    // given
    id classMock = [OCMockObject mockForClass:[NSManagedObjectContext class]];
    [[classMock expect] initPersistentStoreCoordinatorBackingUpCorrupedDatabases:NO];
    [self verifyMockLater:classMock];
    
    XCTAssertFalse([NSManagedObjectContext needsToPrepareLocalStoreInDirectory:self.sharedContainerDirectoryURL]);
    
    // when
    [[[classMock stub] andReturnValue:@YES] databaseExistsInApplicationSupportDirectory];
    
    // then
    XCTAssertTrue([NSManagedObjectContext needsToPrepareLocalStoreInDirectory:self.sharedContainerDirectoryURL]);
    [classMock stopMocking];
}

- (void)testThatItWaitsForFileSystemUnlockBeforeDatabaseInit {
    
    // given
    id classMock = [OCMockObject mockForClass:[NSManagedObjectContext class]];
    [[[classMock stub] andReturnValue:@(YES)] databaseExistsAndNotReadableDueToEncryption];
    [[classMock expect] initPersistentStoreCoordinatorBackingUpCorrupedDatabases:NO];
    [self verifyMockLater:classMock];

    __block BOOL completionCalled = NO;
    
    // when
    [NSManagedObjectContext resetSharedPersistentStoreCoordinator];
    [NSManagedObjectContext prepareLocalStoreSync:YES inDirectory:self.sharedContainerDirectoryURL backingUpCorruptedDatabase:NO completionHandler:^{
        completionCalled = YES;
    }];
    XCTAssertFalse(completionCalled);
    
    // then
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationProtectedDataDidBecomeAvailable object:nil];
    XCTAssertTrue([self waitForAllGroupsToBeEmptyWithTimeout:0.5]);
    
    XCTAssertTrue(completionCalled);
    
    [classMock stopMocking];
}

- (void)testThatItCallsCompletionOnceInCaseFileSystemUnlock {
    
    // given
    id classMock = [OCMockObject mockForClass:[NSManagedObjectContext class]];
    [[[classMock stub] andReturnValue:@(YES)] databaseExistsAndNotReadableDueToEncryption];
    [[classMock expect] initPersistentStoreCoordinatorBackingUpCorrupedDatabases:NO];
    [self verifyMockLater:classMock];

    __block BOOL completionCalledTimes = 0;
    
    [NSManagedObjectContext resetSharedPersistentStoreCoordinator];
    
    // when
    [NSManagedObjectContext prepareLocalStoreSync:YES inDirectory:self.sharedContainerDirectoryURL backingUpCorruptedDatabase:NO completionHandler:^{
        completionCalledTimes++;
    }];
    XCTAssertEqual(completionCalledTimes, 0);
    
    // then
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationProtectedDataDidBecomeAvailable object:nil];
    XCTAssertTrue([self waitForAllGroupsToBeEmptyWithTimeout:0.5]);
    
    XCTAssertEqual(completionCalledTimes, 1);

    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationProtectedDataDidBecomeAvailable object:nil];
    XCTAssertTrue([self waitForAllGroupsToBeEmptyWithTimeout:0.5]);

    XCTAssertEqual(completionCalledTimes, 1);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationProtectedDataDidBecomeAvailable object:nil];
    XCTAssertTrue([self waitForAllGroupsToBeEmptyWithTimeout:0.5]);

    XCTAssertEqual(completionCalledTimes, 1);

    [classMock stopMocking];
}

@end
