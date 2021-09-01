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


@import WireTransport;
@import WireUtilities;
#import "MockTransportSession+users.h"
#import "MockConnection.h"
#import "MockTransportSession+internal.h"
#import "MockPreKey.h"
#import <WireMockTransport/WireMockTransport-Swift.h>


@implementation MockTransportSession (Users)

- (NSArray *)convertToLowercase:(NSArray *)userIDs
{
    NSMutableArray *lowercaseUserIDs = [NSMutableArray array];
    for (NSString *userID in userIDs) {
        [lowercaseUserIDs addObject:[userID lowercaseString]];
    }
    return lowercaseUserIDs;
}

- (BOOL)isConnectedToUser:(MockUser *)user
{
    if(user == self.selfUser) {
        return YES;
    }
    MockConnection *connection = [self fetchConnectionFrom:self.selfUser to:user];
    return connection != nil && [connection.status isEqualToString:@"accepted"];
}

/// handles /users/
- (ZMTransportResponse *)processUsersRequest:(ZMTransportRequest *)request;
{
    if ([request matchesWithPath:@"/users/*/rich-info" method:ZMMethodGET]) {
        return [self processRichProfileFetchForUser:[request RESTComponentAtIndex:1]];
    }
    else if ([request matchesWithPath:@"/users/*" method:ZMMethodGET]) {
        return [self processUserIDRequest:[request RESTComponentAtIndex:1]];
    }
    else if ([request matchesWithPath:@"/users" method:ZMMethodGET]) {
        return [self processUsersRequestWithHandles:request.queryParameters[@"handles"] orIDs:request.queryParameters[@"ids"]];
    }
    else if ([request matchesWithPath:@"/users/prekeys" method:ZMMethodPOST]) {
        return [self processUsersPreKeysRequestWithPayload:[request.payload asDictionary]];
    }
    else if ([request matchesWithPath:@"/users/handles/*" method:ZMMethodGET]
             || [request matchesWithPath:@"/users/handles/*" method:ZMMethodHEAD]) {
        return [self processUserHandleRequest:[request RESTComponentAtIndex:2] path:request.path];
    }
    else if ([request matchesWithPath:@"/users/handles" method:ZMMethodPOST]) {
        return [self processUserHandleAvailabilityRequest:request.payload];
    }
    else if ([request matchesWithPath:@"/users/by-handle/*/*" method:ZMMethodGET]) {
        return [self processFederatedUserHandleRequest:[request RESTComponentAtIndex:2]
                                                handle:[request RESTComponentAtIndex:3]
                                                  path:request.path];
    }
    else if ([request matchesWithPath:@"/users/*/prekeys" method:ZMMethodGET]) {
        return [self processSingleUserPreKeysRequest:[request RESTComponentAtIndex:1]];
    }
    else if ([request matchesWithPath:@"/users/*/prekeys/*" method:ZMMethodGET]) {
        return [self processUserPreKeysRequest:[request RESTComponentAtIndex:1] client:[request RESTComponentAtIndex:3]];
    }
    else if ([request matchesWithPath:@"/users/*/clients/*" method:ZMMethodGET]) {
        return [self getUserClient:[request RESTComponentAtIndex:3] forUser:[request RESTComponentAtIndex:1]];
    }
    else if ([request matchesWithPath:@"/users/*/clients" method:ZMMethodGET]) {
        return [self getUserClientsForUser:[request RESTComponentAtIndex:1]];
    }

    return [self errorResponseWithCode:404 reason:@"no-endpoint"];
}

- (ZMTransportResponse *)getUserClient:(NSString *)clientID forUser:(NSString *)userID {
    
    NSFetchRequest *request = [MockUser sortedFetchRequest];
    request.predicate = [NSPredicate predicateWithFormat: @"identifier == %@", userID];
    
    NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:request];
    
    // check that I got all of them
    if (users.count < 1) {
        return [self errorResponseWithCode:404 reason:@"user not found"];
    } else {
        MockUser *user = users.firstObject;

        for (MockUserClient *client in user.clients) {
            if ([client.identifier isEqualToString:clientID]) {
                return [ZMTransportResponse responseWithPayload:client.transportData HTTPStatus:200 transportSessionError:nil];
            }
        }
        
        return [self errorResponseWithCode:404 reason:@"client not found"];
    }
}

- (ZMTransportResponse *)getUserClientsForUser:(NSString *)userID {
    
    NSFetchRequest *request = [MockUser sortedFetchRequest];
    request.predicate = [NSPredicate predicateWithFormat: @"identifier == %@", userID];
    
    NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:request];
    
    // check that I got all of them
    if (users.count < 1) {
        return [self errorResponseWithCode:404 reason:@"user not found"];
    } else {
        NSMutableArray *payload = [NSMutableArray array];
        for (MockUserClient *client in [users.firstObject clients]) {
            [payload addObject:client.transportData];
        }
        return [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil];
    }
}

- (ZMTransportResponse *)processUserIDRequest:(NSString *)userID {
    
    NSFetchRequest *request = [MockUser sortedFetchRequest];
    request.predicate = [NSPredicate predicateWithFormat: @"identifier == %@", userID];
    
    NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:request];
    
    // check that I got all of them
    if (users.count < 1) {
        return [self errorResponseWithCode:404 reason:@"user not found"];
    } else {
        MockUser *user = users[0];
        id<ZMTransportData> payload = [user transportData];
        return [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil];
    }
}

- (ZMTransportResponse *)processUsersRequestWithHandles:(NSString *)handles orIDs:(NSString *)IDs {
    
    // The 'ids' and 'handles' parameters are mutually exclusive, so we want to ensure at least
    // one of these parameters exist
    if (IDs.length > 0) {
        return [self processUsersIDsRequest:IDs];
    } else {
        return [self processUsersHandlesRequest:handles];
    }
}

- (ZMTransportResponse *)processUsersHandlesRequest:(NSString *)handles {

    RequireString(handles.length > 0, "Malformed query");
    
    NSArray *userHandles = [handles componentsSeparatedByString:@","];
    userHandles = [self convertToLowercase:userHandles];
    
    NSFetchRequest *request = [MockUser sortedFetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"handle IN %@", userHandles];
    
    NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:request];
    
    // check that I got all of them
    if (users.count != userHandles.count) {
        return [self errorResponseWithCode:404 reason:@"user not found"];
    }
    
    // output
    NSMutableArray *resultArray = [NSMutableArray array];
    for (MockUser *user in users) {
        
        id<ZMTransportData> payload = [user transportData];
        [resultArray addObject:payload];
    }
    return [ZMTransportResponse responseWithPayload:resultArray HTTPStatus:200 transportSessionError:nil];
}

- (ZMTransportResponse *)processUsersIDsRequest:(NSString *)IDs {
    
    // If we had a query like "ids=", justIDs would be "" and userIDs would become [""], i.e. contain
    // one empty element. The assert makes sure that that doesn't happen, because it would be Very Bad™
    RequireString(IDs.length > 0, "Malformed query");
    
    NSArray *userIDs = [IDs componentsSeparatedByString:@","];
    userIDs = [self convertToLowercase:userIDs];
    
    NSFetchRequest *request = [MockUser sortedFetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"identifier IN %@", userIDs];
    
    NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:request];
    
    // check that I got all of them
    if (users.count != userIDs.count) {
        return [self errorResponseWithCode:404 reason:@"user not found"];
    }
    
    // output
    NSMutableArray *resultArray = [NSMutableArray array];
    for (MockUser *user in users) {
        
        id<ZMTransportData> payload = [user transportData];
        [resultArray addObject:payload];
    }
    return [ZMTransportResponse responseWithPayload:resultArray HTTPStatus:200 transportSessionError:nil];
}


// MARK: - Self
/// handles /self
- (ZMTransportResponse *)processSelfUserRequest:(ZMTransportRequest *)request;
{
    if ([request matchesWithPath:@"/self" method:ZMMethodGET]) {
        return [self getSelfUser];
    }
    else if([request matchesWithPath:@"/self" method:ZMMethodPUT]) {
        return [self putSelfResponseWithPayload:[request.payload asDictionary]];
    }
    else if([request matchesWithPath:@"/self/phone" method:ZMMethodPUT]) {
        return [self putSelfPhoneWithPayload:[request.payload asDictionary]];
    }
    else if([request matchesWithPath:@"/self/email" method:ZMMethodPUT]) {
        return [self putSelfEmailWithPayload:[request.payload asDictionary]];
    }
    else if([request matchesWithPath:@"/self/password" method:ZMMethodPUT]) {
        return [self putSelfPasswordWithPayload:[request.payload asDictionary]];
    }
    else if([request matchesWithPath:@"/self/handle" method:ZMMethodPUT]) {
        return [self putSelfHandleWithPayload:[request.payload asDictionary]];
    }
    return [self errorResponseWithCode:404 reason:@"no-endpoint"];
}

- (ZMTransportResponse *)getSelfUser
{
    NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithDictionary:(id) [self.selfUser selfUserTransportData]];
    return [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil];
}

- (ZMTransportResponse *)putSelfPhoneWithPayload:(NSDictionary *)payload
{
    NSString *phone = [payload asDictionary][@"phone"];
    if(phone == nil) {
        return [self errorResponseWithCode:400 reason:@"missing-key"];
    }
    
    NSFetchRequest *fetchRequest = [MockUser sortedFetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"phone == %@", phone];
    NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
    
    if(users.count > 0) {
        return [self errorResponseWithCode:409 reason:@"key-exist"];
    }
    else {
        [self.phoneNumbersWaitingForVerificationForProfile addObject:phone];
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil];
    }
}

- (ZMTransportResponse *)putSelfEmailWithPayload:(NSDictionary *)payload
{
    NSString *email = [payload asDictionary][@"email"];
    if(email == nil) {
        return [self errorResponseWithCode:400 reason:@"missing-key"];
    }
    
    NSFetchRequest *fetchRequest = [MockUser sortedFetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"email == %@", email];
    NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
    
    if(users.count > 0) {
        return [self errorResponseWithCode:409 reason:@"key-exist"];
    }
    else {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil];
    }
    
}

- (ZMTransportResponse *)putSelfPasswordWithPayload:(NSDictionary *)payload
{
    NSString *old_password = [payload asDictionary][@"old_password"];
    NSString *new_password = [payload asDictionary][@"new_password"];

    if(new_password == nil) {
        return [self errorResponseWithCode:400 reason:@"missing-key"];
    }
    
    if(self.selfUser.password != nil && ![self.selfUser.password isEqualToString:old_password]) {
        return [self errorResponseWithCode:403 reason:@"invalid-credentials"];
    }
    else {
        self.selfUser.password = new_password;
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil];
    }
}

- (ZMTransportResponse *)putSelfHandleWithPayload:(NSDictionary *)payload
{
    NSString *handle = [payload asDictionary][@"handle"];
    if(handle == nil) {
        return [self errorResponseWithCode:400 reason:@"missing-key"];
    }
    
    NSFetchRequest *fetchRequest = [MockUser sortedFetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"handle == %@", handle];
    NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
    
    if(users.count > 0) {
        return [self errorResponseWithCode:409 reason:@"key-exists"];
    }
    else {
        self.selfUser.handle = handle;
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil];
    }
    
}

- (ZMTransportResponse *)putSelfResponseWithPayload:(NSDictionary *)changedFields
{
    if(changedFields == nil) {
        return [self errorResponseWithCode:400 reason:@"missing-key"];
    }
    
    for(NSString *key in changedFields.allKeys) {
        if([key isEqualToString:@"name"]) {
            self.selfUser.name = changedFields[key];
        }
        else if([key isEqualToString:@"accent_id"]) {
            self.selfUser.accentID = (int16_t) [changedFields[key] integerValue];
        } else if([key isEqualToString:@"assets"]) {
            for (NSDictionary *data in changedFields[key]) {
                NSString *assetKey = data[@"key"];
                if ([data[@"size"] isEqualToString:@"preview"]) {
                    self.selfUser.previewProfileAssetIdentifier = assetKey;
                } else if ([data[@"size"] isEqualToString:@"complete"]) {
                    self.selfUser.completeProfileAssetIdentifier = assetKey;
                }
            }
        }
    }
    return [ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil];
}

// MARK: - /users/prekeys

- (ZMTransportResponse *)processUsersPreKeysRequestWithPayload:(NSDictionary *)clientsMap;
{
    NSFetchRequest *usersRequest = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    usersRequest.predicate = [NSPredicate predicateWithFormat:@"identifier IN %@", clientsMap.allKeys];
    NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:usersRequest];
    
    if (clientsMap.count < 128) {
        
        NSMutableDictionary *payload = [NSMutableDictionary new];
        
        for (NSString *userId in clientsMap) {
            MockUser *user = [users filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", userId]].firstObject;
            if (user == nil) {
                continue;
            }
            
            NSDictionary *userClientsKeys = [self userClientsKeys:user clientIds:clientsMap[userId]];
            if (userClientsKeys.count > 0) {
                payload[userId] = userClientsKeys;
            }
        }
        
        return [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil];
    }
    else {
        return [self errorResponseWithCode:403 reason:@"too-many-clients"];
    }
}

- (NSDictionary *)userClientsKeys:(MockUser *)user clientIds:(NSArray *)clientIds
{
    NSMutableDictionary *userClientsKeys = [NSMutableDictionary new];

    for (NSString *clientID in clientIds) {
        MockUserClient *client = [user.clients.allObjects firstObjectMatchingWithBlock:^BOOL(MockUserClient *userClient) {
            return [userClient.identifier isEqual:clientID];
        }];

        MockPreKey *key = client.prekeys.anyObject;
        if (key == nil) {
            key = client.lastPrekey;
        } else {
            [[client mutableSetValueForKey:@"prekeys"] removeObject:key];
        }

        if (key != nil) {
            userClientsKeys[clientID] = @{
                @"id": @(key.identifier),
                @"key": key.value
            };
        } else {
            userClientsKeys[clientID] = [NSNull null];
        }
    }

    return userClientsKeys;
}

- (ZMTransportResponse *)processSingleUserPreKeysRequest:(NSString *__unused)userID;
{
    return [self errorResponseWithCode:400 reason:@"invalid method"];
}

- (ZMTransportResponse *)processUserPreKeysRequest:(NSString *__unused)userID client:(NSString *__unused)clientID;
{
    return [self errorResponseWithCode:400 reason:@"invalid method"];
}

// MARK: - Handles

- (ZMTransportResponse *)processUserHandleRequest:(NSString *)handle path:(NSString *)path;
{
    NSFetchRequest *fetchRequest = [MockUser sortedFetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"handle == %@", handle];
    NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
    NSData *payloadData;
    NSInteger statusCode;

    if(users.count > 0) {
        statusCode = 200;
        MockUser *user = users[0];
        id <ZMTransportData> payload = [user transportData];
        payloadData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    }
    else {
        statusCode = 404;
    }

    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:path] statusCode:statusCode HTTPVersion:nil headerFields:@{@"Content-Type": @"application/json"}];
    return [[ZMTransportResponse alloc] initWithHTTPURLResponse:urlResponse data:payloadData error:nil];;
}

- (ZMTransportResponse *)processFederatedUserHandleRequest:(NSString *)domain
                                                    handle:(NSString *)handle
                                                      path:(NSString *)path;
{
    NSFetchRequest *fetchRequest = [MockUser sortedFetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"handle == %@ AND domain == %@", handle, domain];
    NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
    NSData *payloadData;
    NSInteger statusCode;

    if (![self.federatedDomains containsObject:domain]) {
        statusCode = 422;
    }
    else if (users.count > 0) {
        statusCode = 200;
        MockUser *user = users[0];
        id <ZMTransportData> payload = [user transportData];
        payloadData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    }
    else {
        statusCode = 404;
    }

    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:path] statusCode:statusCode HTTPVersion:nil headerFields:@{@"Content-Type": @"application/json"}];
    return [[ZMTransportResponse alloc] initWithHTTPURLResponse:urlResponse data:payloadData error:nil];;
}

- (ZMTransportResponse *)processUserHandleAvailabilityRequest:(id<ZMTransportData>)payload
{
    NSDictionary *dictionary = [payload asDictionary];
    if (dictionary == nil) {
        return [self errorResponseWithCode:400 reason:@"bad request"];
    }
    
    NSArray *handles = [dictionary optionalArrayForKey:@"handles"];
    if (handles == nil) {
        return [self errorResponseWithCode:400 reason:@"bad request"];
    }
    
    NSNumber *returnNumber = [dictionary optionalNumberForKey:@"return"];
    if (returnNumber.intValue < 1) {
        return [self errorResponseWithCode:400 reason:@"bad request"];
    }
    
    NSMutableArray *selectedHandles = [NSMutableArray array];
    for (NSString *handle in handles) {
        if (![handle isKindOfClass:NSString.class]) {
            return [self errorResponseWithCode:400 reason:@"bad request"];
        }
        NSFetchRequest *fetchRequest = [MockUser sortedFetchRequest];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"handle == %@", handle];
        NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
        
        if(users.count == 0) {
            [selectedHandles addObject:handle];
        }
        if(selectedHandles.count == (NSUInteger)returnNumber.integerValue) {
            break;
        }
    }
    return [ZMTransportResponse responseWithPayload:selectedHandles HTTPStatus:200 transportSessionError:nil];
}

@end

