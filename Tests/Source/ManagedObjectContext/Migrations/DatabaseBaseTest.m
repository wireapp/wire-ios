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


#import "DatabaseBaseTest.h"

@import ZMTesting;
@import ZMCDataModel;


@interface DatabaseBaseTest ()

@property (nonatomic) NSFileManager *fm;
@property (nonatomic) NSURL *cachesDirectoryStoreURL;
@property (nonatomic) NSURL *applicationSupportDirectoryStoreURL;
@property (nonatomic) NSURL *sharedContainerDirectoryURL;
@property (nonatomic) NSURL *sharedContainerStoreURL;

@end


@implementation DatabaseBaseTest

- (void)setUp
{
    [super setUp];
    
    [NSManagedObjectContext setUseInMemoryStore:NO];
    self.fm = [NSFileManager defaultManager];
    self.cachesDirectoryStoreURL = [PersistentStoreRelocator storeURLInDirectory:NSCachesDirectory];
    self.applicationSupportDirectoryStoreURL = [PersistentStoreRelocator storeURLInDirectory:NSApplicationSupportDirectory];
    self.sharedContainerStoreURL = [PersistentStoreRelocator storeURLInDirectory:NSDocumentDirectory];
    self.sharedContainerDirectoryURL = [self.fm URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    
    [self cleanUp];
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
    
    NSString *supportApplicationSupportPath = self.applicationSupportDirectoryStoreURL.URLByDeletingLastPathComponent.path;
    if([self.fm fileExistsAtPath:supportApplicationSupportPath]) {
        [self.fm removeItemAtPath:supportApplicationSupportPath error:nil];
    }
    
    NSString *testSharedContainerPath = self.sharedContainerStoreURL.URLByDeletingLastPathComponent.path;
    if([self.fm fileExistsAtPath:testSharedContainerPath]) {
        [self.fm removeItemAtPath:testSharedContainerPath error:nil];
    }
 
    [NSManagedObjectContext resetSharedPersistentStoreCoordinator];
    
    [self performIgnoringZMLogError:^{
        NSError *error = nil;
        for (NSString *path in [self.fm contentsOfDirectoryAtPath:self.sharedContainerDirectoryURL.path error:&error]) {
            [self.fm removeItemAtPath:[self.sharedContainerDirectoryURL.path stringByAppendingPathComponent:path] error:&error];
            if (error) {
                ZMLogError(@"Error cleaning up %@ in %@: %@", path, self.sharedContainerDirectoryURL, error);
                error = nil;
            }
        }
        
        if (error) {
            ZMLogError(@"Error reading %@: %@", self.sharedContainerDirectoryURL, error);
        }
    }];
}

#pragma mark - Helper

- (BOOL)createDatabaseInDirectory:(NSSearchPathDirectory)directory
{
    NSURL *storeURL = [PersistentStoreRelocator storeURLInDirectory:directory];

    [NSManagedObjectContext prepareLocalStoreAtURL:storeURL backupCorruptedDatabase:NO synchronous:YES completionHandler:nil];

    XCTAssertTrue([self createExternalSupportFileForDatabaseAtURL:storeURL]);
    [NSManagedObjectContext resetSharedPersistentStoreCoordinator];
    
    return YES;
}

- (BOOL)createExternalSupportFileForDatabaseAtURL:(NSURL *)databaseURL
{
    BOOL success = YES;
    NSError *error;
    NSString *storeName = [[databaseURL URLByDeletingPathExtension] lastPathComponent];
    NSString *supportFile  = [NSString stringWithFormat:@".%@_SUPPORT", storeName];
    NSString *supportPath = [databaseURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:supportFile].path;
    success &= [self.fm createDirectoryAtPath:supportPath withIntermediateDirectories:NO attributes:nil error:&error];
    XCTAssertNil(error);
    
    NSString *path = [supportPath stringByAppendingString:@"/image.dat"];
    success &= [self.mediumJPEGData writeToFile:path atomically:YES];
    return success;
}

- (NSData *)invalidData
{
    return [@"Trollolol" dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)createdUnreadableLocalStore
{
    [self createDirectoryForStoreAtURL:self.sharedContainerStoreURL];
    
    NSData *data = self.invalidData;
    
    for (NSString *extension in self.databaseFileExtensions) {
        NSString *filePath = [self.sharedContainerStoreURL.path stringByAppendingString:extension];
        
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
        [NSManagedObjectContext prepareLocalStoreAtURL:self.sharedContainerStoreURL backupCorruptedDatabase:backupCorruptedDatabase synchronous:YES completionHandler:nil];
        WaitForAllGroupsToBeEmpty(0.5);
    }];
}

- (void)createDirectoryForStoreAtURL:(NSURL *)storeURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *directory = storeURL.URLByDeletingLastPathComponent;
    
    if (! [fileManager fileExistsAtPath:directory.path]) {
        NSError *error;
        short const permissions = 0700;
        NSDictionary *attr = @{NSFilePosixPermissions: @(permissions)};
        RequireString([fileManager createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:attr error:&error],
                      "Failed to create directory: %lu, error: %lu", (unsigned long)directory,  (unsigned long) error.code);
    }
    
    // Make sure this is not backed up:
    NSError *error;
    if (! [directory setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error]) {
        ZMLogError(@"Error excluding %@ from backup %@", directory.path, error);
    }
}

@end
