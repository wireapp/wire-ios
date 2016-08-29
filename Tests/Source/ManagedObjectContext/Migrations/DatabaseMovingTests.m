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


#import <ZMTesting/ZMTesting.h>
@import ZMCDataModel;
#import "NSManagedObjectContext+zmessaging-Internal.h"



@interface DatabaseMovingTests : ZMTBaseTest

@property (nonatomic) NSFileManager *fm;
@property (nonatomic) NSURL *cachesDirectoryStoreURL;
@property (nonatomic) NSURL *applicationSupportStoreURL;
@property (nonatomic) NSURL *testSharedDatabaseDirectory;
@property (nonatomic) NSURL *testSharedDatabaseStoreURL;

@end



@implementation DatabaseMovingTests

- (void)setUp {
    [super setUp];
    [NSManagedObjectContext setUseInMemoryStore:NO];
    [self cleanUp];
    self.fm = [NSFileManager defaultManager];
    self.cachesDirectoryStoreURL = [NSManagedObjectContext storeURLInDirectory:NSCachesDirectory];
    self.applicationSupportStoreURL = [NSManagedObjectContext storeURLInDirectory:NSApplicationSupportDirectory];
    self.testSharedDatabaseStoreURL = [NSManagedObjectContext storeURLInDirectory:NSDocumentDirectory];
    self.testSharedDatabaseDirectory = [self.fm URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
}

- (void)tearDown
{
    [self cleanUp];
    [super tearDown];
}

- (void)cleanUp
{
    NSString *supportCachesPath = self.cachesDirectoryStoreURL.URLByDeletingLastPathComponent.path;
    if([self.fm fileExistsAtPath:supportCachesPath]) {
        [self.fm removeItemAtPath:supportCachesPath error:nil];
    }
    
    NSString *supportApplicationSupportPath = self.applicationSupportStoreURL.URLByDeletingLastPathComponent.path;
    if([self.fm fileExistsAtPath:supportApplicationSupportPath]) {
        [self.fm removeItemAtPath:supportApplicationSupportPath error:nil];
    }
    
    NSString *testSharedContainerPath = self.testSharedDatabaseStoreURL.URLByDeletingLastPathComponent.path;
    if([self.fm fileExistsAtPath:testSharedContainerPath]) {
        [self.fm removeItemAtPath:testSharedContainerPath error:nil];
    }
    
    for(NSString *backupFolder in [self currentBackupFoldersInApplicationSupport]) {
        [self.fm removeItemAtPath:backupFolder error:nil];
    }
    
    [NSManagedObjectContext resetSharedPersistentStoreCoordinator];
}

- (void)testThatItMovesTheDatabaseFromCachesToSharedDirectory
{
    // given
    [self performIgnoringZMLogError:^{
        XCTAssertTrue([self moveDatabaseToCachesDirectory]);
        NSURL *dbDirectory = self.testSharedDatabaseDirectory.URLByDeletingLastPathComponent;
        XCTAssertTrue([NSManagedObjectContext needsToPrepareLocalStoreInDirectroy:dbDirectory]);
    }];
    
    for (NSString *extension in self.databaseFileExtensions) {
        NSString *fromPath = [self.cachesDirectoryStoreURL.path stringByAppendingString:extension];
        NSString *toPath = [self.testSharedDatabaseStoreURL.path stringByAppendingString:extension];
        XCTAssertFalse([self.fm fileExistsAtPath:toPath]);
        XCTAssertTrue([self.fm fileExistsAtPath:fromPath]);
    }

    // when
    [self prepareLocalStoreInSharedContainerBackingUpDatabase:NO];

    // then
    XCTAssertTrue([self.fm fileExistsAtPath:self.testSharedDatabaseDirectory.path]);

    for (NSString *extension in self.databaseFileExtensions) {
        NSString *fromPath = [self.cachesDirectoryStoreURL.path stringByAppendingString:extension];
        XCTAssertFalse([self.fm fileExistsAtPath:fromPath]);
    }

    NSString *supportURL = [self.testSharedDatabaseStoreURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@".store_SUPPORT"].path;
    XCTAssertTrue([self.fm fileExistsAtPath:supportURL]);
}

- (void)testThatItWipesTheLocalStoreWhenItIsUnreadable
{
    // given
    [self performIgnoringZMLogError:^{
        XCTAssertTrue([self createdUnredableLocalStore]);
        NSURL *dbDirectory = self.testSharedDatabaseDirectory.URLByDeletingLastPathComponent;
        XCTAssertTrue([NSManagedObjectContext needsToPrepareLocalStoreInDirectroy:dbDirectory]);
    }];
    
    NSString *storeFile = [self.testSharedDatabaseStoreURL.path stringByAppendingString:@""];
    NSData *oldStoreFileData = [NSData dataWithContentsOfFile:storeFile];
    XCTAssertNotNil(storeFile);
    XCTAssertEqualObjects(oldStoreFileData, self.invalidData);
    
    // when
    [self prepareLocalStoreInSharedContainerBackingUpDatabase:NO];
    
    // then
    NSData *newData = [NSData dataWithContentsOfFile:storeFile];
    XCTAssertNotEqualObjects(newData, oldStoreFileData);
    XCTAssertNotNil(newData);
}

- (void)testThatItCreatesACopyOfTheLocalStoreWhenItIsUnreadable
{
    // given
    [self performIgnoringZMLogError:^{
        XCTAssertTrue([self createdUnredableLocalStore]);
        NSURL *dbDirectory = self.testSharedDatabaseDirectory.URLByDeletingLastPathComponent;
        XCTAssertTrue([NSManagedObjectContext needsToPrepareLocalStoreInDirectroy:dbDirectory]);
    }];
    
    NSString *storeFile = [self.testSharedDatabaseStoreURL.path stringByAppendingString:@""];
    NSData *oldStoreFileData = [NSData dataWithContentsOfFile:storeFile];
    XCTAssertNotNil(storeFile);
    
    // when
    [self prepareLocalStoreInSharedContainerBackingUpDatabase:YES];
    
    // then
    NSURL *storeFolder;
    [[NSURL fileURLWithPath:storeFile] getResourceValue:&storeFolder forKey:NSURLParentDirectoryURLKey error:NULL];
    NSURL *parentFolder;
    [storeFolder getResourceValue:&parentFolder forKey:NSURLParentDirectoryURLKey error:NULL];
    
    NSArray *backupFolders = [self currentBackupFoldersInApplicationSupport];
    XCTAssertEqual(backupFolders.count, 1u);
    
    NSURL *firstBackupFolder = [NSURL fileURLWithPath:backupFolders.firstObject];
    NSURL *backedUpStoreFile = [firstBackupFolder URLByAppendingPathComponent:storeFile.lastPathComponent];
    
    NSData *newData = [NSData dataWithContentsOfFile:backedUpStoreFile.path];
    XCTAssertNotNil(newData);
    XCTAssertEqualObjects(newData, oldStoreFileData);
}

- (NSArray<NSString *>*)currentBackupFoldersInApplicationSupport
{
    NSURL *containerFolder = self.testSharedDatabaseStoreURL.URLByDeletingLastPathComponent.URLByDeletingLastPathComponent;
    NSArray *dirContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:containerFolder.path
                                                                              error:NULL];
    NSMutableArray *backupFolders = [NSMutableArray array];
    for(NSString *file in dirContent) {
        if([file hasPrefix:@"DB-"] && [file hasSuffix:@".bak"]) {
            [backupFolders addObject:[containerFolder URLByAppendingPathComponent:file].path];
        }
    }
    return backupFolders;
}

- (void)testThatItReportsDatabaseExistsInCachesDirectoryAfterMovingIt
{
    // given
    XCTAssertTrue([self moveDatabaseToCachesDirectory]);
    
    // then
    XCTAssertTrue([NSManagedObjectContext databaseExistsInCachesDirectory]);
}

- (void)testThatItReportsDatabaseDoesNotExistsInCachesDirectoryWhenItIsNotThere
{
    XCTAssertFalse([NSManagedObjectContext databaseExistsInCachesDirectory]);
}

- (void)testThatItConstructsTheStoreURLUsingThePassedSearchPathDirectory
{
    XCTAssertTrue([self.cachesDirectoryStoreURL.path containsString:@"Caches"]);
    XCTAssertTrue([self.applicationSupportStoreURL.path containsString:@"Application Support"]);
}

#pragma mark - Helper

- (BOOL)moveDatabaseToCachesDirectory
{
    NSError *error;
    NSURL *cachesStoreURL = [NSManagedObjectContext storeURLInDirectory:NSCachesDirectory];
    NSURL *applicationDirectoryStoreURL = [NSManagedObjectContext storeURLInDirectory:NSDocumentDirectory];
    
    for (NSString *extension in self.databaseFileExtensions) {
        NSString *fromPath = [cachesStoreURL.path stringByAppendingString:extension];
        NSString *toPath = [applicationDirectoryStoreURL.path stringByAppendingString:extension];

        if (! [self.fm createFileAtPath:fromPath contents:nil attributes:nil]) {
            XCTFail();
            return NO;
        }
        if ([self.fm fileExistsAtPath:toPath isDirectory:nil]) {
            [self.fm removeItemAtPath:toPath error:&error];
            XCTAssertNil(error);
            
            if (nil != error) {
                return NO;
            }
        }
    }
    
    NSString *supportPath = [cachesStoreURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@".store_SUPPORT"].path;
    XCTAssertTrue([self.fm createDirectoryAtPath:supportPath withIntermediateDirectories:NO attributes:nil error:&error]);
    XCTAssertNil(error);
    
    return YES;
}

- (NSData *)invalidData
{
    return [@"Trollolol" dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)createdUnredableLocalStore
{
    NSData *data = self.invalidData;

    for (NSString *extension in self.databaseFileExtensions) {
        NSString *filePath = [self.testSharedDatabaseStoreURL.path stringByAppendingString:extension];

        if (! [self.fm createFileAtPath:filePath contents:data attributes:nil]) {
            XCTFail();
            return NO;
        }
    }
    return YES;
}

- (NSArray <NSString *>*)databaseFileExtensions
{
    return @[@"", @"-wal", @"-shm"];
}

- (void)prepareLocalStoreInSharedContainerBackingUpDatabase:(BOOL)backupCorruptedDatabase
{
    [self performIgnoringZMLogError:^{
        [NSManagedObjectContext prepareLocalStoreSync:YES
                                          inDirectory:self.testSharedDatabaseDirectory
                           backingUpCorruptedDatabase:backupCorruptedDatabase
                                    completionHandler:nil];
         WaitForAllGroupsToBeEmpty(0.5);
    }];
}

@end
