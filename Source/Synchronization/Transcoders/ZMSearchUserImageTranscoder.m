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


@import ZMTransport;

#import "ZMSearchUserImageTranscoder.h"
#import "ZMSearchDirectory+Internal.h"
#import "ZMSearchUser+Internal.h"
#import "ZMUserIDsForSearchDirectoryTable.h"
#import <zmessaging/NSManagedObjectContext+zmessaging.h>
#import "ZMUserImageTranscoder.h"
#import <zmessaging/zmessaging-Swift.h>

static NSString *const UsersPath = @"/users?ids=";
static NSString *const PictureTagKey = @"tag";
static NSString *const PicturesArrayKey = @"picture";
static NSString *const SmallProfilePictureTag = @"smallProfile";
static NSString *const MediumPictureTag = @"medium";

static NSString *const UserIDKey = @"id";
static NSString *const PictureIDKey = @"id";
static NSString *const PictureInfoKey = @"info";

@interface ZMSearchUserImageTranscoder ()

@property (nonatomic) NSManagedObjectContext *uiContext;
@property (nonatomic) ZMUserIDsForSearchDirectoryTable *userIDsTable;
@property (nonatomic) NSCache *imagesByUserIDCache;
@property (nonatomic) NSCache *mediumAssetIDByUserIDCache;

@property (nonatomic) NSMutableSet *userIDsBeingRequested;
@property (nonatomic) NSMutableSet *assetIDsBeingRequested;


@end


@implementation ZMSearchUserAssetIDs

- (instancetype)initWithUserImageResponse:(NSArray *)response
{
    self = [super init];
    if (self != nil) {
        for(NSDictionary *pictureData in response) {
            NSDictionary *info = [pictureData dictionaryForKey:PictureInfoKey];
            if ([[info stringForKey:PictureTagKey] isEqualToString:SmallProfilePictureTag]) {
                self.smallImageAssetID = [pictureData uuidForKey:PictureIDKey];
            }
            
            if ([[info stringForKey:PictureTagKey] isEqualToString:MediumPictureTag]) {
                self.mediumImageAssetID = [pictureData uuidForKey:PictureIDKey];
            }
        }
    }
    return self;
}

@end


@implementation ZMSearchUserImageTranscoder

ZM_EMPTY_ASSERTING_INIT();

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc;
{
    NOT_USED(moc);
    Require(NO);
    return nil;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
                                   uiContext:(NSManagedObjectContext *)uiContext
             userIDsWithoutProfileImageTable:(ZMUserIDsForSearchDirectoryTable *)userIDsTable
                         imagesByUserIDCache:(NSCache *)imagesCache
                  mediumAssetIDByUserIDCache:(NSCache *)mediumAssetIDByUserIDCache
{
    self = [super initWithManagedObjectContext:moc];
    if(self != nil) {
        self.uiContext = uiContext;
        self.userIDsTable = userIDsTable;
        self.imagesByUserIDCache = imagesCache;
        self.mediumAssetIDByUserIDCache = mediumAssetIDByUserIDCache;
        self.userIDsBeingRequested = [NSMutableSet set];
        self.assetIDsBeingRequested = [NSMutableSet set];
    }
    return self;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc uiContext:(NSManagedObjectContext *)uiContext
{
    return [self initWithManagedObjectContext:moc
                                    uiContext:uiContext
              userIDsWithoutProfileImageTable:[ZMSearchDirectory userIDsMissingProfileImage]
                          imagesByUserIDCache:[ZMSearchUser searchUserToSmallProfileImageCache]
                   mediumAssetIDByUserIDCache:[ZMSearchUser searchUserToMediumAssetIDCache]];
}

- (void)setNeedsSlowSync
{
    // no op
}

- (BOOL)isSlowSyncDone
{
    return YES;
}

- (NSArray *)contextChangeTrackers
{
    return @[];
}

- (void)processEvents:(NSArray<ZMUpdateEvent *> __unused *)events
           liveEvents:(BOOL __unused)liveEvents
       prefetchResult:(__unused ZMFetchRequestBatchResult *)prefetchResult;
{
    // no-op
}

- (NSArray *)requestGenerators;
{
    return @[self];
}

- (ZMTransportRequest *)nextRequest
{
    ZMTransportRequest *request = [self fetchUsersRequest];
    
    if(request == nil) {
        request = [self fetchAssetRequest];
    }
    [request setDebugInformationTranscoder:self];

    return request;
}

- (ZMTransportRequest *)fetchAssetRequest {
    
    NSMutableSet *assetIDsToDownload = [[self.userIDsTable allAssetIDs] mutableCopy];
    [assetIDsToDownload minusSet:self.assetIDsBeingRequested];
    
    ZMSearchUserAndAssetID *userAssetID = assetIDsToDownload.anyObject;
    if(userAssetID != nil) {
        
        [self.assetIDsBeingRequested addObject:userAssetID];
        
        ZMTransportRequest *request = [ZMUserImageTranscoder requestForFetchingAssetWithID:userAssetID.assetID forUserWithID:userAssetID.userID];
        ZM_WEAK(self);
        [request addCompletionHandler:[ZMCompletionHandler handlerOnGroupQueue:self.managedObjectContext block:^(ZMTransportResponse *response) {
            ZM_STRONG(self);
            [self processAssetResponse:response forUserAssetID:userAssetID];
        }]];
        return request;
    }
    
    return nil;
    
}

- (void)processAssetResponse:(ZMTransportResponse *)response forUserAssetID:(ZMSearchUserAndAssetID *)userAssetID
{
    [self.assetIDsBeingRequested removeObject:userAssetID];
    
    if(response.result == ZMTransportResponseStatusSuccess) {
        if(response.imageData != 0) {
            [self.imagesByUserIDCache setObject:response.imageData forKey:userAssetID.userID];
            
            [self.uiContext performGroupedBlock:^{
                [userAssetID.searchUser notifyNewSmallImageData:response.imageData managedObjectContextObserver:self.uiContext.globalManagedObjectContextObserver];
            }];
        }
        
        [self.userIDsTable removeAllEntriesWithUserIDs:[NSSet setWithObject:userAssetID.userID]];
    }
    else if (response.result == ZMTransportResponseStatusPermanentError) {
        [self.userIDsTable removeAllEntriesWithUserIDs:[NSSet setWithObject:userAssetID.userID]];
    }
}


- (ZMTransportRequest *)fetchUsersRequest
{
    NSMutableSet *userIDsToDownload = [[self.userIDsTable allUserIDs] mutableCopy];
    [userIDsToDownload minusSet:self.userIDsBeingRequested];
    
    if(userIDsToDownload.count > 0u) {
        [self.userIDsBeingRequested unionSet:userIDsToDownload];
        ZMCompletionHandler *completionHandler = [ZMCompletionHandler handlerOnGroupQueue:self.managedObjectContext block:^(ZMTransportResponse *response) {
            [self processUserProfileResponse:response forUserIDs:userIDsToDownload];
        }];
        return [ZMSearchUserImageTranscoder fetchAssetsForUsersWithIDs:userIDsToDownload completionHandler:completionHandler];
    }
    return nil;
}


+ (ZMTransportRequest *)fetchAssetsForUsersWithIDs:(NSSet *)userIDsToDownload completionHandler:(ZMCompletionHandler *)completionHandler
{
    NSString *usersList;
    ZM_ALLOW_MISSING_SELECTOR(usersList = [[userIDsToDownload.allObjects mapWithSelector:@selector(transportString)] componentsJoinedByString:@","];)
    ZMTransportRequest *request = [ZMTransportRequest requestGetFromPath:[UsersPath stringByAppendingString:usersList]];
    [request addCompletionHandler:completionHandler];
    
    return request;
}

- (void)processUserProfileResponse:(ZMTransportResponse *)response forUserIDs:(NSSet *)userIDs
{
    [self.userIDsBeingRequested minusSet:userIDs];
    
    if(response.result == ZMTransportResponseStatusSuccess) {
        
        NSArray *usersList = [[response.payload asArray] asDictionaries];
        
        for(NSDictionary *userData in usersList) {
            
            NSUUID *userID = [userData uuidForKey:UserIDKey];
            NSArray *pictures = [[userData arrayForKey:PicturesArrayKey] asDictionaries];
            if (userID != nil) {
                ZMSearchUserAssetIDs *assetIDs = [[ZMSearchUserAssetIDs alloc] initWithUserImageResponse:pictures];
                
                if (assetIDs.smallImageAssetID != nil) {
                    [self.userIDsTable replaceUserIDToDownload:userID withAssetIDToDownload:assetIDs.smallImageAssetID];
                } else {
                    [self.userIDsTable removeAllEntriesWithUserIDs:[NSSet setWithObject:userID]];
                }
                
                if (assetIDs.mediumImageAssetID != nil) {
                    [self.mediumAssetIDByUserIDCache setObject:assetIDs.mediumImageAssetID forKey:userID];
                }
            }
        }
    }
    else if(response.result == ZMTransportResponseStatusPermanentError) {
        [self.userIDsTable removeAllEntriesWithUserIDs:userIDs];
    }
}


+ (void)processSingleUserProfileResponse:(ZMTransportResponse *)response forUserID:(NSUUID *)userID mediumAssetIDCache:(NSCache *)mediumAssetIDCache
{
    if (userID == nil) {
        return;
    }
    
    if(response.result == ZMTransportResponseStatusSuccess) {
        NSArray *usersList = [[response.payload asArray] asDictionaries];
        for(NSDictionary *userData in usersList) {
            
            NSUUID *receivedUserID = [userData uuidForKey:UserIDKey];
            if (![userID isEqual:receivedUserID]) {
                return;
            }
            
            NSArray *pictures = [[userData arrayForKey:PicturesArrayKey] asDictionaries];
            if (userID != nil) {
                ZMSearchUserAssetIDs *assetIDs = [[ZMSearchUserAssetIDs alloc] initWithUserImageResponse:pictures];
                if (assetIDs.mediumImageAssetID != nil) {
                    [mediumAssetIDCache setObject:assetIDs.mediumImageAssetID forKey:userID];
                }
            }
        }
    }
}

@end




