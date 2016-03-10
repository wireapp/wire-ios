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


#import "ZMUserSession+Internal.h"
#import "BOMiniZipArchiver.h"
#import "ZMUser+Internal.h"
#import "ZMLogging.h"
#import <zmessaging/NSManagedObjectContext+zmessaging.h>

@implementation ZMUserSession (Debug)

- (NSProgress *)exportDatabaseToURL:(NSURL *)outputURL withCompletionHandler:(void(^)(NSURL *archive))handler;
{
    handler = [handler copy];
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:10];
    
    void (^setProgress)(NSProgress *p, int c) = ^(NSProgress *p, int c){
        dispatch_async(dispatch_get_main_queue(), ^{
            p.completedUnitCount = c;
        });
    };
    void (^completeProgress)(NSProgress *p) = ^(NSProgress *p){
        dispatch_async(dispatch_get_main_queue(), ^{
            p.completedUnitCount = p.totalUnitCount;
        });
    };
    
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSURL *tempDirectory = [NSURL fileURLWithPath:NSTemporaryDirectory()];
        NSString *folderName = [NSString stringWithFormat:@"database-export-%g", [NSDate timeIntervalSinceReferenceDate]];
        tempDirectory = [tempDirectory URLByAppendingPathComponent:folderName];
        
        if (! [[NSFileManager defaultManager] createDirectoryAtURL:tempDirectory withIntermediateDirectories:YES attributes:nil error:nil])
        {
            completeProgress(progress);
            handler(nil);
            return;
        }
        
        NSURL *databaseURL = [tempDirectory URLByAppendingPathComponent:@"store.wiredatabase"];
        if (![self openPersistentStoreAndCopyToURL:databaseURL]) {
            completeProgress(progress);
            handler(nil);
            return;
        }
        
        setProgress(progress, 5);
        
        [self moveFilesAndDirectoriesAtURL:tempDirectory intoZipAtOutPutURL:outputURL];
        [[NSFileManager defaultManager] removeItemAtURL:tempDirectory error:nil];
        
        completeProgress(progress);
    });
    return progress;
}

- (BOOL)openPersistentStoreAndCopyToURL:(NSURL *)databaseURL
{
    NSError *error = nil;
    NSPersistentStoreCoordinator *oldPSC = self.managedObjectContext.persistentStoreCoordinator;
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:oldPSC.managedObjectModel];
    NSURL *originalStoreURL = [oldPSC.persistentStores.firstObject URL];
    id store = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:originalStoreURL options:@{NSReadOnlyPersistentStoreOption: @YES} error:&error];
    
    if (store == nil) {
        ZMLogError(@"Unable to open the database for export \"%@\": %@", originalStoreURL.path, error);
        return NO;
    }
    
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
    moc.persistentStoreCoordinator = psc;
    NSManagedObject *selfUser = [ZMUser selfUserInContext:moc];
    
    error = nil;
    id newStore = [psc migratePersistentStore:psc.persistentStores.firstObject toURL:databaseURL options:nil withType:NSSQLiteStoreType error:&error];
    if (newStore == nil) {
        ZMLogError(@"Unable to export the database to \"%@\": %@", databaseURL.path, error);
        return NO;
    }
    
    [moc setPersistentStoreMetadata:selfUser.objectID.URIRepresentation.absoluteString forKey:@"SelfUserObjectID"];
    [moc save:nil];
    
    return YES;
}


- (void)moveFilesAndDirectoriesAtURL:(NSURL *)inputURL intoZipAtOutPutURL:(NSURL *)outputURL
{
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:inputURL includingPropertiesForKeys:nil options:0 errorHandler:nil];
    
    NSError *error = nil;
    BOMiniZipArchiver *archiver = [[BOMiniZipArchiver alloc] initWithFileURL:outputURL append:NO error:&error];
    NSAssert(archiver != nil, @"%@", error);
    
    NSURL *standardizedBasePath = [inputURL standardizedURL];
    NSUInteger pathComponentsCount = standardizedBasePath.pathComponents.count;
    
    for (NSURL *fileURL in enumerator) {
        NSNumber *isDirectory;
        if (! [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil] ||
            [isDirectory boolValue])
        {
            continue;
        }
        
        NSURL *fullURL = [fileURL URLByStandardizingPath];
        NSArray *pathComponents = fullURL.pathComponents;
        pathComponents = [pathComponents subarrayWithRange:NSMakeRange(pathComponentsCount, pathComponents.count - pathComponentsCount)];
        NSString *name = [NSString pathWithComponents:pathComponents];
        
        BOOL result = [archiver appendFileAtURL:fileURL withName:name error:&error];
        NSAssert(result, @"%@", error);
    }
    
    BOOL result = [archiver finishEncoding:&error];
    NSAssert(result, @"%@", error);
}


@end
