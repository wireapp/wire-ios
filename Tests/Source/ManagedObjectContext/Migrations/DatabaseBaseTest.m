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

@import WireTesting;
@import WireDataModel;


@interface DatabaseBaseTest ()

@property (nonatomic) NSFileManager *fm;
@property (nonatomic) NSURL *cachesDirectoryStoreURL;
@property (nonatomic) NSURL *applicationSupportDirectoryStoreURL;
@property (nonatomic) NSURL *sharedContainerDirectoryURL;
@property (nonatomic) NSURL *sharedContainerStoreURL;
@property (nonatomic) NSUUID *accountID;

@end

@implementation NSFileManager (StoreLocation)

+ (NSURL *)storeURLInDirectory:(NSSearchPathDirectory)directory;
{
    return [[[[NSFileManager defaultManager] URLsForDirectory:directory inDomains:NSUserDomainMask] firstObject] URLByAppendingStorePath];
}

@end

@implementation DatabaseBaseTest

- (void)setUp
{
    [super setUp];
    self.accountID = [NSUUID createUUID];
    
    [StorageStack reset];
    [[StorageStack shared] setCreateStorageAsInMemory:NO];
    
    self.fm = [NSFileManager defaultManager];
    self.cachesDirectoryStoreURL = [NSFileManager storeURLInDirectory:NSCachesDirectory];
    self.applicationSupportDirectoryStoreURL = [NSFileManager storeURLInDirectory:NSApplicationSupportDirectory];
    self.sharedContainerDirectoryURL = [self.fm URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    self.sharedContainerStoreURL = [NSFileManager currentStoreURLForAccountWith:self.accountID in:self.sharedContainerDirectoryURL];
    XCTAssertTrue([self.fm fileExistsAtPath:self.sharedContainerDirectoryURL.path]);
    [self cleanUp];
}

- (void)tearDown
{
    [self cleanUp];
    self.fm = nil;
    self.accountID = nil;
    self.cachesDirectoryStoreURL = nil;
    self.applicationSupportDirectoryStoreURL = nil;
    self.sharedContainerStoreURL = nil;
    self.sharedContainerDirectoryURL = nil;
    self.contextDirectory = nil;
    
    [super tearDown];
}

- (void)cleanUp
{
    WaitForAllGroupsToBeEmpty(2.0);
    [StorageStack reset];
    [[StorageStack shared] setCreateStorageAsInMemory:NO];

    NSURL *supportCachesDir = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject;
    if([self.fm fileExistsAtPath:supportCachesDir.path]) {
        NSArray *contents = [self.fm contentsOfDirectoryAtURL:supportCachesDir includingPropertiesForKeys:nil options:0 error:nil];
        for (NSURL *url in contents) {
            NSError *error = nil;
            [self.fm removeItemAtURL:url error:&error];
            if (error) {
                ZMLogError(@"Error cleaning up %@: %@", url, error);
            }
        }
    }

    NSURL *supportApplicationSupportDir = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
    if([self.fm fileExistsAtPath:supportApplicationSupportDir.path]) {
        [self.fm removeItemAtPath:supportApplicationSupportDir.path error:nil];
    }

    for (NSString *path in [self.fm contentsOfDirectoryAtPath:self.sharedContainerDirectoryURL.path error:nil]) {
        NSError *error = nil;
        [self.fm removeItemAtPath:[self.sharedContainerDirectoryURL.path stringByAppendingPathComponent:path] error:&error];
        if (error) {
            ZMLogError(@"Error cleaning up %@ in %@: %@", path, self.sharedContainerDirectoryURL, error);
        }
    }
}

#pragma mark - Helper

- (BOOL)createDatabaseInDirectory:(NSSearchPathDirectory)directory accountIdentifier:(NSUUID *)accountIdentifier
{
    NSURL *containerURL = [[NSFileManager defaultManager] URLsForDirectory:directory inDomains:NSUserDomainMask].firstObject;
    return [self createDatabaseAtSharedContainerURL:containerURL accountIdentifier:accountIdentifier];
}

- (BOOL)createDatabaseAtSharedContainerURL:(NSURL *)sharedContainerURL accountIdentifier:(NSUUID *)accountIdentifier
{
    [StorageStack reset];
    [[StorageStack shared] setCreateStorageAsInMemory:NO];
    
    NSURL *storeURL;
    if(accountIdentifier == nil) {
        storeURL = [sharedContainerURL URLByAppendingStorePath];
        [[StorageStack shared] createManagedObjectContextFromLegacyStoreInContainerAt:sharedContainerURL startedMigrationCallback:nil completionHandler:^(ManagedObjectContextDirectory * directory) {
            self.contextDirectory = directory;
        }];
    } else {
        storeURL = [[sharedContainerURL URLByAppendingPathComponent:accountIdentifier.UUIDString isDirectory:YES] URLByAppendingStorePath];
        [[StorageStack shared] createManagedObjectContextDirectoryForAccountWith:accountIdentifier inContainerAt:sharedContainerURL startedMigrationCallback:nil completionHandler:^(ManagedObjectContextDirectory * directory) {
            self.contextDirectory = directory;
        }];
    }

    XCTAssert([self waitWithTimeout:5 verificationBlock:^BOOL{
        return nil != self.contextDirectory;
    }], @"Did not create context directory. Something might be blocking the main thread?");
    
    XCTAssertTrue([self createExternalSupportFileForDatabaseAtURL:storeURL]);
    return YES;
}

- (BOOL)createExternalSupportFileForDatabaseAtURL:(NSURL *)databaseURL
{
    BOOL success = YES;
    NSError *error;
    NSString *storeName = [[databaseURL URLByDeletingPathExtension] lastPathComponent];
    NSString *supportFile  = [NSString stringWithFormat:@".%@_SUPPORT", storeName];
    NSString *supportPath = [databaseURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:supportFile].path;
    if ([self.fm fileExistsAtPath:supportPath]) {
        [self.fm removeItemAtPath:supportPath error:nil];
    }
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
