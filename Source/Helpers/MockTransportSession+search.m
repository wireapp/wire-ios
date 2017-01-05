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

@import ZMTransport;
@import ZMTesting;
@import ZMProtos;
#import "MockTransportSession+assets.h"
#import "MockTransportSession+OTR.h"
#import "MockAsset.h"
#import <ZMCMockTransport/ZMCMockTransport-Swift.h>

@implementation MockTransportSession (Search)

/// handles /search/common/xxxxxxx
- (ZMTransportResponse *)processCommonConnectionsSearchRequest:(ZMTransportRequest *)request
{
    if ([request matchesWithPath:@"/search/common/*" method:ZMMethodGET]) {
        // check that requested user exists
        {
            NSString *userID = [request RESTComponentAtIndex:2];
            
            NSFetchRequest *fetchRequest = [MockUser sortedFetchRequest];
            fetchRequest.predicate = [NSPredicate predicateWithFormat: @"identifier == %@", userID];
            
            NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
            if(users == nil || users.count != 1u) {
                return [self errorResponseWithCode:404 reason:@"uknown user"];
            }
        }
        
        // return results
        {
            NSFetchRequest *fetchRequest = [MockConnection sortedFetchRequest];
            NSArray *connections = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
            NSArray *connectionsSortedByUserName = [connections sortedArrayUsingComparator:^NSComparisonResult(MockConnection *c1, MockConnection *c2) {
                return [c1.to.name compare:c2.to.name];
            }];
            
            NSMutableArray *resultData = [NSMutableArray array];
            for (MockConnection *c in connectionsSortedByUserName) {
                [resultData addObject:@{@"id": c.to.identifier}];
            }
            
            NSDictionary *payload = @{@"documents" : resultData};
            return [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil];
        }
    }
    
    return [self errorResponseWithCode:400 reason:@"invalid-method"];
}

- (ZMTransportResponse *)processSearchForSuggestionsRequest:(ZMTransportRequest *)request;
{
    if ([request matchesWithPath:@"/search/suggestions" method:ZMMethodGET]) {
        // Find all users that are not connected to the self user:
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(self != %@) && (NOT ANY connectionsFrom.to == %@) && (NOT ANY connectionsTo.from == %@)", self.selfUser, self.selfUser, self.selfUser];
        NSFetchRequest *fetchRequest = [MockUser sortedFetchRequestWithPredicate:predicate];
        fetchRequest.fetchLimit = (NSUInteger) [request.queryParameters[@"size"] integerValue];
        NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
        
        NSArray *contacts = [users mapWithBlock:^(MockUser *user) {
            NSMutableDictionary *payload = [NSMutableDictionary dictionary];
            if (user.name != nil) {
                payload[@"name"] = user.name;
            }
            if (user.identifier != nil) {
                payload[@"id"] = user.identifier;
            }
            
            NSPredicate *commonConnectionsPredicate = [NSPredicate predicateWithFormat:@"((ANY connectionsFrom.to == %@) OR (ANY connectionsTo.from == %@)) AND ((ANY connectionsFrom.to = %@) OR (ANY connectionsTo.from = %@))", self.selfUser, self.selfUser, user, user];
            
            NSFetchRequest *fetchRequestForCommonConnections = [MockUser sortedFetchRequestWithPredicate:commonConnectionsPredicate];
            NSArray *commonConnections = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequestForCommonConnections];
            
            NSArray *commonConnectionsUUIDs = [commonConnections mapWithBlock:^id(MockUser * obj) {
                return obj.identifier;
            }];
            
            if (commonConnectionsUUIDs.count > 3) {
                commonConnectionsUUIDs = [commonConnectionsUUIDs subarrayWithRange:NSMakeRange(0, 3)];
            }
            
            payload[ZMSearchUserMutualFriendsKey] = commonConnectionsUUIDs;
            payload[ZMSearchUserTotalMutualFriendsKey] = @(commonConnections.count);
            return payload;
        }];
        
        id responsePayload = @{@"found": @(contacts.count),
                               @"returned": @(contacts.count),
                               @"documents": contacts,};
        return [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:200 transportSessionError:nil];
    }
    return [self errorResponseWithCode:400 reason:@"invalid-method"];
}

/// handles /search/contacts/
- (ZMTransportResponse *)processSearchRequest:(ZMTransportRequest *)request;
{
    if (request.method == ZMMethodGET) {
        NSString *query = request.queryParameters[@"q"];
        NSUInteger limit = (NSUInteger) [request.queryParameters[@"l"] integerValue];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(name CONTAINS[cd] %@) AND (identifier != %@)", query, self.selfUser.identifier];
        
        NSFetchRequest *fetchRequest = [MockUser sortedFetchRequestWithPredicate:predicate];
        fetchRequest.fetchLimit = limit;
        
        NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
        
        NSMutableArray *userPayload = [NSMutableArray array];
        for (MockUser *user in users) {
            
            MockConnection *connection = [self fetchConnectionFrom:self.selfUser to:user];
            
            NSMutableDictionary *payload;
            if(connection != nil) {
                payload = [(NSMutableDictionary *)user.transportData mutableCopy];
            }
            else {
                payload = [(NSMutableDictionary *)user.transportDataWhenNotConnected mutableCopy];
            }
            
            payload[@"blocked"]= @NO;
            payload[@"connected"]= @(connection != nil);
            payload[@"level"]= @1;
            [payload removeObjectForKey:@"picture"];
            
            
            [userPayload addObject:payload];
        }
        
        NSDictionary *responsePayload = @{
                                          @"documents": userPayload
                                          };
        
        return [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:200 transportSessionError:nil];
    }
    
    return [self errorResponseWithCode:400 reason:@"invalid-method"];
}

// handles /onboarding
- (ZMTransportResponse *)processOnboardingRequest:(ZMTransportRequest *)request
{
    if(request.method == ZMMethodPOST) {
        NSArray *selfEmailArray = [[request.payload asDictionary] arrayForKey:@"self"];
        if(selfEmailArray.count == 0) {
            return [self errorResponseWithCode:400 reason:@"no self email"];
        }
        NSArray *cards = [[request.payload asDictionary] arrayForKey:@"cards"];
        if(cards == nil) {
            return [self errorResponseWithCode:400 reason:@"missing contacts"];
        }
        
        NSFetchRequest *fetchRequest = [MockUser sortedFetchRequest];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"SELF != %@", self.selfUser];
        NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
        
        ZM_ALLOW_MISSING_SELECTOR(
                                  NSDictionary *responsePayload = @{
                                                                    @"results" : [users mapWithSelector:@selector(identifier)]
                                                                    };
                                  )
        
        return [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:200 transportSessionError:nil];
        
    }
    return [self errorResponseWithCode:400 reason:@"invalid-method"];
}


@end
