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
        [NSManagedObjectContext initPersistentStoreCoordinatorAtURL:self.sharedContainerStoreURL backupCorrupedDatabase:NO];
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

    XCTAssertFalse([NSManagedObjectContext needsToPrepareLocalStoreAtURL:self.sharedContainerStoreURL]);
    
    // when
    [[[classMock stub] andReturnValue:@YES] databaseExistsButIsNotReadableDueToEncryptionAtURL:OCMOCK_ANY];
    
    // then
    XCTAssertTrue([NSManagedObjectContext needsToPrepareLocalStoreAtURL:self.sharedContainerStoreURL]);
    [classMock stopMocking];
}

- (void)testThatItWaitsForFileSystemUnlockBeforeDatabaseInit {
    
    // given
    id classMock = [OCMockObject mockForClass:[NSManagedObjectContext class]];
    [[[classMock stub] andReturnValue:@YES] databaseExistsButIsNotReadableDueToEncryptionAtURL:OCMOCK_ANY];
    [self verifyMockLater:classMock];

    __block BOOL completionCalled = NO;
    
    // when
    [NSManagedObjectContext resetSharedPersistentStoreCoordinator];
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    [NSManagedObjectContext prepareLocalStoreAtURL:self.sharedContainerStoreURL backupCorruptedDatabase:NO synchronous:YES completionHandler:^{
        completionCalled = YES;
        dispatch_semaphore_signal(sem);
    }];
    XCTAssertFalse(completionCalled);
    
    // then
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationProtectedDataDidBecomeAvailable object:nil];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    XCTAssertTrue([self waitForAllGroupsToBeEmptyWithTimeout:0.5]);
    
    XCTAssertTrue(completionCalled);
    
    [classMock stopMocking];
}

- (void)testThatItCallsCompletionOnceInCaseFileSystemUnlock {
    
    // given
    id classMock = [OCMockObject mockForClass:[NSManagedObjectContext class]];
    [[[classMock stub] andReturnValue:@YES] databaseExistsButIsNotReadableDueToEncryptionAtURL:OCMOCK_ANY];
    [self verifyMockLater:classMock];

    __block BOOL completionCalledTimes = 0;
    
    [NSManagedObjectContext resetSharedPersistentStoreCoordinator];
    
    // when
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    [NSManagedObjectContext prepareLocalStoreAtURL:self.sharedContainerStoreURL backupCorruptedDatabase:NO synchronous:YES completionHandler:^{
        completionCalledTimes++;
        dispatch_semaphore_signal(sem);
    }];
    XCTAssertEqual(completionCalledTimes, 0);
    
    // then
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationProtectedDataDidBecomeAvailable object:nil];
    XCTAssertTrue([self waitForAllGroupsToBeEmptyWithTimeout:0.5]);
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
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
