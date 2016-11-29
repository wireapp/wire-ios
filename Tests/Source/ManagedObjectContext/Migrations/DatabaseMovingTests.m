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
#import "DatabaseBaseTest.h"


static NSString * const DatabaseIdentifier = @"TestDatabase";


@interface DatabaseMovingTests : DatabaseBaseTest

@end


@implementation DatabaseMovingTests

- (void)cleanUp
{
    [super cleanUp];
    for (NSString *backupFolder in self.currentBackupFoldersInApplicationSupport) {
        [self.fm removeItemAtPath:backupFolder error:nil];
    }
}

- (void)testThatItMovesTheDatabaseFromCachesToSharedDirectory
{
    // given
    [self performIgnoringZMLogError:^{
        XCTAssertTrue([self createDatabaseInDirectory:NSCachesDirectory]);
        XCTAssertTrue([NSManagedObjectContext needsToPrepareLocalStoreAtURL:self.sharedContainerStoreURL]);
    }];
    
    for (NSString *extension in self.databaseFileExtensions) {
        NSString *fromPath = [self.cachesDirectoryStoreURL.path stringByAppendingString:extension];
        NSString *toPath = [self.sharedContainerStoreURL.path stringByAppendingString:extension];
        XCTAssertFalse([self.fm fileExistsAtPath:toPath]);
        XCTAssertTrue([self.fm fileExistsAtPath:fromPath]);
    }

    // when
    [self prepareLocalStoreInSharedContainerBackingUpDatabase:NO];

    // then
    for (NSString *extension in self.databaseFileExtensions) {
        NSString *fromPath = [self.cachesDirectoryStoreURL.path stringByAppendingString:extension];
        NSString *toPath = [self.sharedContainerStoreURL.path stringByAppendingString:extension];
        XCTAssertFalse([self.fm fileExistsAtPath:fromPath]);
        
        if ([self.fm fileExistsAtPath:fromPath]) {
            NSLog(@"%@", fromPath);
        }
        
        XCTAssertTrue([self.fm fileExistsAtPath:toPath]);
    }
    

    NSString *supportURL = [self.sharedContainerStoreURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@".store_SUPPORT"].path;
    XCTAssertTrue([self.fm fileExistsAtPath:supportURL]);
}

- (void)testThatItMovesTheDatabaseFromTheApplicationSupportDirectoryToTheSharedDirectory
{
    // given
    [self performIgnoringZMLogError:^{
        XCTAssertTrue([self createDatabaseInDirectory:NSApplicationSupportDirectory]);
        XCTAssertTrue([NSManagedObjectContext needsToPrepareLocalStoreAtURL:self.sharedContainerStoreURL]);
    }];
    
    for (NSString *extension in self.databaseFileExtensions) {
        NSString *fromPath = [self.applicationSupportDirectoryStoreURL.path stringByAppendingString:extension];
        NSString *toPath = [self.sharedContainerStoreURL.path stringByAppendingString:extension];
        XCTAssertFalse([self.fm fileExistsAtPath:toPath]);
        XCTAssertTrue([self.fm fileExistsAtPath:fromPath]);
    }
    
    // when
    [self prepareLocalStoreInSharedContainerBackingUpDatabase:NO];
    
    // then
    for (NSString *extension in self.databaseFileExtensions) {
        NSString *fromPath = [self.applicationSupportDirectoryStoreURL.path stringByAppendingString:extension];
        NSString *toPath = [self.sharedContainerStoreURL.path stringByAppendingString:extension];
        XCTAssertFalse([self.fm fileExistsAtPath:fromPath]);
        XCTAssertTrue([self.fm fileExistsAtPath:toPath]);
    }
    
    XCTAssertFalse([NSManagedObjectContext needsToPrepareLocalStoreAtURL:self.sharedContainerStoreURL]);

     NSString *supportURL = [self.sharedContainerStoreURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@".store_SUPPORT"].path;
     XCTAssertTrue([self.fm fileExistsAtPath:supportURL]);
}

- (void)testThatItMovesRemainingDatabaseFilesFromTheApplicationSupportDirectoryToTheSharedDirectory
{
    // given
    XCTAssertTrue([self createDatabaseInDirectory:NSApplicationSupportDirectory]);
    XCTAssertTrue([NSManagedObjectContext needsToPrepareLocalStoreAtURL:self.sharedContainerStoreURL]);

    // We simulate that we already moved the main database file previously
    [self createDirectoryForStoreAtURL:self.sharedContainerStoreURL];
    NSError *error;
    XCTAssertTrue([self.fm moveItemAtPath:self.applicationSupportDirectoryStoreURL.path toPath:self.sharedContainerStoreURL.path error:&error]);
    XCTAssertNil(error);

    XCTAssertFalse([self.fm fileExistsAtPath:self.applicationSupportDirectoryStoreURL.path]);

    NSArray *journalingExtensions = [self.databaseFileExtensions subarrayWithRange:NSMakeRange(1, self.databaseFileExtensions.count - 1)];
    
    for (NSString *extension in journalingExtensions) {
        NSString *fromPath = [self.applicationSupportDirectoryStoreURL.path stringByAppendingString:extension];
        NSString *toPath = [self.sharedContainerStoreURL.path stringByAppendingString:extension];
        XCTAssertFalse([self.fm fileExistsAtPath:toPath]);
        XCTAssertTrue([self.fm fileExistsAtPath:fromPath]);
    }
    
    // when
    [self prepareLocalStoreInSharedContainerBackingUpDatabase:NO];
    
    // then
    for (NSString *extension in self.databaseFileExtensions) {
        NSString *fromPath = [self.applicationSupportDirectoryStoreURL.path stringByAppendingString:extension];
        NSString *toPath = [self.sharedContainerStoreURL.path stringByAppendingString:extension];
        XCTAssertFalse([self.fm fileExistsAtPath:fromPath]);
        XCTAssertTrue([self.fm fileExistsAtPath:toPath]);
    }
    
    XCTAssertFalse([NSManagedObjectContext needsToPrepareLocalStoreAtURL:self.sharedContainerStoreURL]);
    
    NSString *supportURL = [self.sharedContainerStoreURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@".store_SUPPORT"].path;
    XCTAssertTrue([self.fm fileExistsAtPath:supportURL]);
}

- (void)testThatItMovesRemainingExternalDatabaseFilesFromTheApplicationSupportDirectoryToTheSharedDirectory
{
    // given: we simulate that we already moved all main database files expect the .store_SUPPORT file
    [self createDatabaseInDirectory:NSDocumentDirectory];
    NSString *supportFileInSharedContainer = [self.sharedContainerStoreURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@".store_SUPPORT"].path;
    XCTAssertTrue([self.fm removeItemAtPath:supportFileInSharedContainer error:nil]);
    
    // Create remaining support file in the previous location
    [self createDirectoryForStoreAtURL:self.applicationSupportDirectoryStoreURL];
    XCTAssertTrue([self createExternalSupportFileForDatabaseAtURL:self.applicationSupportDirectoryStoreURL]);
    
    for (NSString *extension in self.databaseFileExtensions) {
        NSString *fromPath = [self.applicationSupportDirectoryStoreURL.path stringByAppendingString:extension];
        NSString *toPath = [self.sharedContainerStoreURL.path stringByAppendingString:extension];
        XCTAssertTrue([self.fm fileExistsAtPath:toPath]);
        XCTAssertFalse([self.fm fileExistsAtPath:fromPath]);
    }

    // when
    [NSManagedObjectContext resetSharedPersistentStoreCoordinator];
    [self prepareLocalStoreInSharedContainerBackingUpDatabase:NO];

    // then
    for (NSString *extension in self.databaseFileExtensions) {
        NSString *fromPath = [self.applicationSupportDirectoryStoreURL.path stringByAppendingString:extension];
        NSString *toPath = [self.sharedContainerStoreURL.path stringByAppendingString:extension];
        XCTAssertFalse([self.fm fileExistsAtPath:fromPath]);
        XCTAssertTrue([self.fm fileExistsAtPath:toPath]);
    }
    
    XCTAssertFalse([NSManagedObjectContext needsToPrepareLocalStoreAtURL:self.sharedContainerStoreURL]);
    XCTAssertTrue([self.fm fileExistsAtPath:supportFileInSharedContainer]);
}

- (void)testThatItWipesTheLocalStoreWhenItIsUnreadable
{
    // given
    [self performIgnoringZMLogError:^{
        XCTAssertTrue([self createdUnreadableLocalStore]);
        XCTAssertFalse([NSManagedObjectContext needsToPrepareLocalStoreAtURL:self.sharedContainerStoreURL]);
    }];
    
    NSString *storeFile = [self.sharedContainerStoreURL.path stringByAppendingString:@""];
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
        XCTAssertTrue([self createdUnreadableLocalStore]);
        XCTAssertFalse([NSManagedObjectContext needsToPrepareLocalStoreAtURL:self.sharedContainerStoreURL]);
    }];
    
    NSString *storeFile = [self.sharedContainerStoreURL.path stringByAppendingString:@""];
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
    NSURL *dbDirectory = self.sharedContainerDirectoryURL;
    NSArray *dirContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dbDirectory.path
                                                                              error:NULL];
    NSMutableArray *backupFolders = [NSMutableArray array];
    for(NSString *file in dirContent) {
        if([file hasPrefix:@"DB-"] && [file hasSuffix:@".bak"]) {
            [backupFolders addObject:[dbDirectory URLByAppendingPathComponent:file].path];
        }
    }
    return backupFolders;
}

@end
