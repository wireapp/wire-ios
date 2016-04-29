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


@import ZMUtilities;
@import ZMTransport;
@import ZMCDataModel;

#import "ZMCommonContactsSearch.h"

static NSTimeInterval CacheValidityInterval = 60 * 10; // 10 minutes

@implementation ZMCommonContactsSearchCachedEntry

- (instancetype)initWithExpirationDate:(NSDate *)expirationDate userObjectsIDs:(NSOrderedSet *)userObjectsIDs;
{
    self = [super init];
    if(self) {
        _expirationDate = expirationDate;
        _userObjectIDs = [userObjectsIDs copy];
    }
    return self;
}

@end



@interface ZMCommonContactsSearch ()

@property (nonatomic) id<ZMCommonContactsSearchToken> searchToken;
@property (nonatomic) ZMTransportSession* transportSession;
@property (nonatomic) NSUUID* userID;
@property (nonatomic) NSManagedObjectContext* syncMOC;
@property (nonatomic) NSManagedObjectContext *uiMOC;
@property (nonatomic, weak) id<ZMCommonContactsSearchDelegate> delegate;
@property (nonatomic) NSCache* resultsCache;

@end


@implementation ZMCommonContactsSearch : NSObject

- (instancetype)initWithTransportSession:(ZMTransportSession *)transportSession
                                  userID:(NSUUID *)userID
                                   token:(id<ZMCommonContactsSearchToken>)token
                                 syncMOC:(NSManagedObjectContext *)syncMOC
                                   uiMOC:(NSManagedObjectContext *)uiMOC
                          searchDelegate:(id<ZMCommonContactsSearchDelegate>)delegate
                             resultsCache:(NSCache *)resultsCache;
{
    self = [super init];
    if(self) {
        self.searchToken = token;
        self.transportSession = transportSession;
        self.userID = userID;
        self.syncMOC = syncMOC;
        self.uiMOC = uiMOC;
        self.delegate = delegate;
        self.resultsCache = resultsCache;
    }
    
    return self;
}

// return false if the value is not in cache
- (BOOL)checkCacheAndNotify
{
    ZMCommonContactsSearchCachedEntry *cached = [self.resultsCache objectForKey:self.userID];
    if(cached != nil) {
        
        if(cached.expirationDate.timeIntervalSinceNow < 0) {
            [self.resultsCache removeObjectForKey:self.userID];
        }
        else {
            [self convertObjectIDsInUIUsersAndNotifyDelegate:cached.userObjectIDs];
            return YES;
        }
    }
    return NO;
}

- (void)notifyDelegateWithResult:(NSOrderedSet *)users
{
    [self.delegate didReceiveCommonContactsUsers:users forSearchToken:self.searchToken];
}

- (void)convertObjectIDsInUIUsersAndNotifyDelegate:(NSOrderedSet *)userObjectIDs
{
    NSFetchRequest *request = [ZMUser sortedFetchRequestWithPredicate:[NSPredicate predicateWithFormat:@"self in %@",userObjectIDs]];
    
    ZMCommonContactsSearchCachedEntry *entry = [[ZMCommonContactsSearchCachedEntry alloc] initWithExpirationDate:[NSDate dateWithTimeIntervalSinceNow:CacheValidityInterval] userObjectsIDs:userObjectIDs];
    [self.resultsCache setObject:entry forKey:self.userID];
    
    [self.uiMOC performGroupedBlock:^{
        (void) [self.uiMOC executeFetchRequestOrAssert:request];
        NSMutableOrderedSet *users = [NSMutableOrderedSet orderedSet];
        for(NSManagedObjectID *objectID in userObjectIDs) {
            ZMUser *user = (id)[self.uiMOC objectWithID:objectID];
            [users addObject:user];
        }
        [self notifyDelegateWithResult:users];
    }];
    
}

- (void)parseResponse:(ZMTransportResponse *)response
{
    if(response.result != ZMTransportResponseStatusSuccess) {
        return;
    }
        
    NSMutableOrderedSet *userObjIDs = [NSMutableOrderedSet orderedSet];
    for(NSDictionary *result in [[[response.payload asDictionary] arrayForKey:@"documents"] asDictionaries]) {
        NSUUID* userID = [result uuidForKey:@"id"];
        if(userID) {
            ZMUser *user = [ZMUser userWithRemoteID:userID createIfNeeded:NO inContext:self.syncMOC];
            if(user) {
                [userObjIDs addObject:user.objectID];
            }
        }
    }
    
    [self convertObjectIDsInUIUsersAndNotifyDelegate:userObjIDs];
}

- (void)startRequest
{
    ZMTransportRequest *request = [ZMTransportRequest requestWithPath:[NSString stringWithFormat:@"/search/common/%@", self.userID.transportString] method:ZMMethodGET payload:nil];
    [request addCompletionHandler:[ZMCompletionHandler handlerOnGroupQueue:self.syncMOC block:^(ZMTransportResponse *response) {
        // Do not weakify. Keep a reference to self or the delegate will not be called
        [self parseResponse:response];
    }]];
    
    [self.transportSession enqueueSearchRequest:request];
}

+ (void)startSearchWithTransportSession:(ZMTransportSession *)transportSession userID:(NSUUID *)userID token:(id<ZMCommonContactsSearchToken>)token syncMOC:(NSManagedObjectContext *)syncMoc uiMOC:(NSManagedObjectContext *)uiMOC searchDelegate:(id<ZMCommonContactsSearchDelegate>)delegate resultsCache:(NSCache *)resultsCache
{
    if(delegate == nil) {
        return;
    }
    
    ZMCommonContactsSearch *search = [[ZMCommonContactsSearch alloc] initWithTransportSession:transportSession userID:userID token:token syncMOC:syncMoc uiMOC:uiMOC searchDelegate:delegate resultsCache:resultsCache];
    
    if([search checkCacheAndNotify]) {
        return;
    }
    
    [search startRequest];
}



@end
