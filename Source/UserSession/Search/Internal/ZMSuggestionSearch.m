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

#import "ZMSuggestionSearch.h"
#import "ZMUserSession+Internal.h"
#import "ZMUserTranscoder+Internal.h"
#import "ZMSearchResult+Internal.h"
#import "ZMSearchDirectory+Internal.h"


static NSArray *removedSearchUserRemoteIdentifiers;


@interface ZMSuggestionSearch ()

@property (nonatomic, copy) NSArray *remoteIdentifiers;
@property (nonatomic) NSMutableDictionary *results;
@property (nonatomic) NSManagedObjectContext *searchContext;
@property (nonatomic) ZMUserSession *userSession;
@property (nonatomic) NSCache *resultCache;
@property (nonatomic) BOOL tornDown;

@end



@implementation ZMSuggestionSearch

+ (ZMSearchToken)suggestionSearchToken;
{
    return (id) @"ZMSuggestedPeople";
}

ZM_EMPTY_ASSERTING_INIT();

- (instancetype)initWithSearchContext:(NSManagedObjectContext *)searchContext
                          userSession:(ZMUserSession *)userSession
                          resultCache:(NSCache *)resultCache;
{
    VerifyReturnNil(searchContext != nil);
    VerifyReturnNil(userSession != nil);
    VerifyReturnNil(resultCache != nil);
    self = [super init];
    if (self) {
        self.searchContext = searchContext;
        self.userSession = userSession;
        self.resultCache = resultCache;
        self.results = [NSMutableDictionary dictionary];
    }
    return self;
}

- (ZMSearchToken)token;
{
    return [self.class suggestionSearchToken];
}

- (void)start;
{
    [self.userSession.managedObjectContext performGroupedBlock:^{
        ZMSearchResult *result = [self.resultCache objectForKey:self.token];
        ZMSearchResultHandler resultHandler = self.resultHandler;
        if ((result != nil) && (resultHandler != nil)) {
            resultHandler(result);
        }
        else {
            BOOL isFirstSearch = (self.userSession.managedObjectContext.suggestedUsersForUser == nil);
            if (isFirstSearch) {
                return;
            }
            [self.searchContext performGroupedBlock:^{
                [self fetchLocalUsersWithCompletionHandler:^{
                    if (self.tornDown) {
                        return;
                    }
                    [self fetchRemoteUsersWithCompletionHandler:^{
                        if (self.tornDown) {
                            return;
                        }
                        [self sendResult];
                    }];
                }];
            }];
        }
    }];
    
}

- (void)tearDown;
{
    self.tornDown = YES;
    self.resultHandler = nil;
}

- (void)dealloc
{
    RequireString(self.tornDown, "Did not call -tearDown on %p", (__bridge  void *) self);
}

- (void)removeSearchUser:(ZMSearchUser *)searchUser;
{
    NSUUID *remoteID = searchUser.remoteIdentifier;
    VerifyReturn(remoteID != nil);
    [self.userSession.managedObjectContext performGroupedBlock:^{
        {
            removedSearchUserRemoteIdentifiers = ((removedSearchUserRemoteIdentifiers == nil) ?
                                                  [NSArray arrayWithObject:remoteID] :
                                                  [removedSearchUserRemoteIdentifiers arrayByAddingObject:remoteID]);
        }
        {
            ZMSearchResult *result = [[self.resultCache objectForKey:self.token] copyByRemovingUsersWithRemoteIdentifier:remoteID];
            if (result != nil) {
                [self.resultCache setObject:result forKey:self.token];
            }
        }
        {
            self.userSession.managedObjectContext.suggestedUsersForUser = self.suggestedUsersForUser;
            
            NSMutableArray *removed = [NSMutableArray arrayWithArray:self.userSession.managedObjectContext.removedSuggestedContactRemoteIdentifiers];
            [removed addObject:remoteID];
            self.userSession.managedObjectContext.removedSuggestedContactRemoteIdentifiers = removed;
            
            [self.userSession.managedObjectContext saveOrRollback];
        }
    }];
}

- (NSOrderedSet *)suggestedUsersForUser;
{
    NSOrderedSet *suggested = self.userSession.managedObjectContext.suggestedUsersForUser;
    if (removedSearchUserRemoteIdentifiers != nil) {
        NSMutableOrderedSet *a = [suggested mutableCopy];
        [a removeObjectsInArray:removedSearchUserRemoteIdentifiers];
        suggested = a;
    }
    return suggested;
}

- (void)fetchLocalUsersWithCompletionHandler:(dispatch_block_t)handler;
{
    [self.userSession.managedObjectContext performGroupedBlock:^{
        self.remoteIdentifiers = self.suggestedUsersForUser.array;
        NSArray *identifierData = [self.remoteIdentifiers mapWithBlock:^id(NSUUID *uuid) {
            return [uuid data];
        }];
        NSFetchRequest *request = [ZMUser sortedFetchRequestWithPredicateFormat:@"remoteIdentifier_data IN %@", identifierData];
        request.relationshipKeyPathsForPrefetching = @[@"connection"];
        NSArray *users = [self.userSession.managedObjectContext executeFetchRequestOrAssert:request];
        NSArray <ZMSearchUser *> *searchUsers = [ZMSearchUser usersWithUsers:users userSession:self.userSession];
        
        for (ZMUser *searchUser in searchUsers) {
            self.results[searchUser.remoteIdentifier] = searchUser;
        }
        handler();
    }];
}

- (void)fetchRemoteUsersWithCompletionHandler:(dispatch_block_t)handler;
{
    [self.searchContext performGroupedBlock:^{
        NSSet *localIdentifiers = [NSSet setWithArray:self.results.allKeys];
        NSArray *nonLocal = [self.remoteIdentifiers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSUUID *uuid, NSDictionary * ZM_UNUSED bindings) {
            return ! [localIdentifiers containsObject:uuid];
        }]];
        
        // There's a maximum limit to how many users we can request at once. Here we'll simply limit the number of users to be smaller than that.
        if (ZMUserTranscoderNumberOfUUIDsPerRequest < nonLocal.count) {
            nonLocal = [nonLocal subarrayWithRange:NSMakeRange(0, ZMUserTranscoderNumberOfUUIDsPerRequest)];
        }
        
        if (0 < nonLocal.count) {
            ZMTransportRequest *request = [ZMUserTranscoder requestForRemoteIdentifiers:nonLocal];
            ZM_WEAK(self);
            [request addCompletionHandler:[ZMCompletionHandler handlerOnGroupQueue:self.searchContext block:^(ZMTransportResponse *response) {
                ZM_STRONG(self);
                [self addResultsFromTransportResponse:response];
                handler();
            }]];
            [self enqueueSearchRequest:request];
        } else {
            handler();
        }
    }];
}

- (void)sendResult;
{
    [self.searchContext performGroupedBlock:^{
        NSMutableArray *users = [NSMutableArray array];
        
        NSArray *remoteIdentifiers = [self.remoteIdentifiers copy];
        NSDictionary *results = [self.results copy];
        
        [self.userSession.managedObjectContext performGroupedBlock:^{
            
            for (NSUUID *remoteID in remoteIdentifiers) {
                ZMSearchUser *u = results[remoteID];
                if (u != nil) {
                    if (u.user.connection != nil) {
                        switch (u.user.connection.status) {
                            case ZMConnectionStatusAccepted:
                            case ZMConnectionStatusPending:
                            case ZMConnectionStatusIgnored:
                            case ZMConnectionStatusBlocked:
                            case ZMConnectionStatusSent:
                                // Don't include users that are contacts, pending contacts, ignored, or blocked.
                                continue;
                            default:
                                break;
                        }
                    }
                    [users addObject:u];
                }
            }
            ZMSearchResult *finalResult = [[ZMSearchResult alloc] init];
            [finalResult addUsersInDirectory:users];
            
            [self.resultCache setObject:finalResult forKey:self.token];
            
            ZMSearchResultHandler resultHandler = self.resultHandler;
            if (resultHandler != nil) {
                resultHandler(finalResult);
            }
        }];
    }];
}

- (void)enqueueSearchRequest:(ZMTransportRequest *)request;
{
    ZMTransportSession *session = self.userSession.transportSession;
    Require(session != nil);
    [self.userSession.transportSession enqueueSearchRequest:request];
}

- (void)addResultsFromTransportResponse:(ZMTransportResponse *)response;
{
    if (response.result == ZMTransportResponseStatusSuccess) {
        NSArray *payload = [response.payload asArray];
        NSArray <ZMSearchUser *> *seachUsers = [ZMSearchUser usersWithPayloadArray:payload userSession:self.userSession];
        for (ZMSearchUser *user in seachUsers) {
            self.results[user.remoteIdentifier] = user;
        }
    }
}

@end
