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
#import "NSManagedObjectContext+zmessaging-Internal.h"

@import ZMTesting;



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
    [self cleanUp];
    [NSManagedObjectContext setUseInMemoryStore:NO];
    self.fm = [NSFileManager defaultManager];
    self.cachesDirectoryStoreURL = [NSManagedObjectContext storeURLInDirectory:NSCachesDirectory];
    self.applicationSupportDirectoryStoreURL = [NSManagedObjectContext storeURLInDirectory:NSApplicationSupportDirectory];
    self.sharedContainerStoreURL = [NSManagedObjectContext storeURLInDirectory:NSDocumentDirectory];
    self.sharedContainerDirectoryURL = [self.fm URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    [NSManagedObjectContext setDatabaseDirectoryURL:self.sharedContainerDirectoryURL];
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
}

#pragma mark - Helper

- (BOOL)moveDatabaseToSearchPathDirectory:(NSUInteger)directory
{
    NSError *error;
    NSURL *toStoreURL = [NSManagedObjectContext storeURLInDirectory:directory];
    NSURL *fromStoreURL = NSManagedObjectContext.storeURL;

    // We need to create a database before we move it.
    [NSManagedObjectContext prepareLocalStoreSync:YES inDirectory:self.sharedContainerDirectoryURL backingUpCorruptedDatabase:NO completionHandler:nil];

    for (NSString *extension in self.databaseFileExtensions) {
        NSString *toPath = [toStoreURL.path stringByAppendingString:extension];
        NSString *fromPath = [fromStoreURL.path stringByAppendingString:extension];
        XCTAssertTrue([self.fm moveItemAtPath:fromPath toPath:toPath error:&error]);
        XCTAssertNil(error);
        XCTAssertTrue([self.fm fileExistsAtPath:toPath]);
        
        if (nil != error) {
            return NO;
        }
    }

    XCTAssertTrue([self createExternalSupportFileForDatabaseAtURL:toStoreURL]);
    [NSManagedObjectContext resetSharedPersistentStoreCoordinator];
    
    return YES;
}

- (BOOL)createExternalSupportFileForDatabaseAtURL:(NSURL *)databaseURL
{
    BOOL success = YES;
    NSError *error;
    NSString *supportPath = [databaseURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@".store_SUPPORT"].path;
    success &= [self.fm createDirectoryAtPath:supportPath withIntermediateDirectories:NO attributes:nil error:&error];
    XCTAssertNil(error);
    
    NSString *path = [supportPath stringByAppendingString:@"/image.dat"];
    success &= [self.mediumJPEGData writeToFile:path atomically:YES];
    return success;
}

- (BOOL)moveDatabaseToCachesDirectory
{
    return [self moveDatabaseToSearchPathDirectory:NSCachesDirectory];
}

- (BOOL)moveDatabaseToApplicationSupportDirectory
{
    return [self moveDatabaseToSearchPathDirectory:NSApplicationSupportDirectory];
}

- (NSData *)invalidData
{
    return [@"Trollolol" dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)createdUnreadableLocalStore
{
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
        [NSManagedObjectContext prepareLocalStoreSync:YES
                                          inDirectory:self.sharedContainerDirectoryURL
                           backingUpCorruptedDatabase:backupCorruptedDatabase
                                    completionHandler:nil];
        WaitForAllGroupsToBeEmpty(0.5);
    }];
}

@end
