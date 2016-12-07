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
@import ZMUtilities;
#import "MockTransportSession+users.h"
#import "MockConnection.h"
#import "MockTransportSession+internal.h"
#import "MockUserClient.h"
#import "MockPreKey.h"

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
- (ZMTransportResponse *)processUsersRequest:(TestTransportSessionRequest *)sessionRequest;
{
    if ((sessionRequest.method == ZMMethodGET) && (sessionRequest.pathComponents.count == 1) && ![sessionRequest.pathComponents.lastObject isEqualToString:@"prekeys"]) {
        NSString *userID = sessionRequest.pathComponents[0];
        
        NSFetchRequest *request = [MockUser sortedFetchRequest];
        request.predicate = [NSPredicate predicateWithFormat: @"identifier == %@", userID];
        
        NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:request];
        
        // check that I got all of them
        if (users.count < 1) {
            return [self errorResponseWithCode:404 reason:@"user not found"];
        } else {
            MockUser *user = users[0];
            id<ZMTransportData> payload = [self isConnectedToUser:user] ? [user transportData] : [user transportDataWhenNotConnected];
            return [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil];
        }
    } else if ((sessionRequest.method == ZMMethodGET) && (sessionRequest.pathComponents.count == 0)) {
        NSString *justIDs = [sessionRequest.URL.query componentsSeparatedByString:@"="][1];
        
        // If we had a query like "ids=", justIDs would be "" and userIDs would become [""], i.e. contain
        // one empty element. The assert makes sure that that doesn't happen, because it would be Very Bad™
        RequireString(justIDs.length > 0, "Malformed query");
        
        NSArray *userIDs = [justIDs componentsSeparatedByString:@","];
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
            
            id<ZMTransportData> payload = [self isConnectedToUser:user] ? [user transportData] : [user transportDataWhenNotConnected];
            [resultArray addObject:payload];
        }
        return [ZMTransportResponse responseWithPayload:resultArray HTTPStatus:200 transportSessionError:nil];
    }
    else if (sessionRequest.method == ZMMethodPOST && sessionRequest.pathComponents.count == 1 && [sessionRequest.pathComponents.lastObject isEqualToString:@"prekeys"]) {
        return [self processUsersPreKeysRequest:sessionRequest];
    }
    else if ((sessionRequest.method == ZMMethodGET || sessionRequest.method == ZMMethodHEAD)
             && sessionRequest.pathComponents.count == 2
             && [sessionRequest.pathComponents[0] isEqualToString:@"handles"] ) {
        return [self processUserHandleRequest:sessionRequest.pathComponents[1] requestPath:sessionRequest.embeddedRequest.path];
    }
    else if (sessionRequest.method == ZMMethodPOST && sessionRequest.pathComponents.count == 1 && [sessionRequest.pathComponents[0] isEqualToString:@"handles"]) {
        return [self processUserHandleAvailabilityRequest:sessionRequest.payload];
    }

    else if (sessionRequest.method == ZMMethodGET && sessionRequest.pathComponents.count == 2) {
        return [self processSingleUserPreKeysRequest:sessionRequest];
    }
    else if (sessionRequest.method == ZMMethodGET && sessionRequest.pathComponents.count == 3) {
        return [self processUserClientPreKeysRequest:sessionRequest];
    }
    else {
        return [self errorResponseWithCode:400 reason:@"invalid-method"];
    }
}

// MARK: - Self
/// handles /self
- (ZMTransportResponse *)processSelfUserRequest:(TestTransportSessionRequest *)sessionRequest;
{
    if ((sessionRequest.method == ZMMethodGET)) {
        NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithDictionary:(id) [self.selfUser transportData]];
        if (self.selfUser.trackingIdentifier != nil) {
            payload[@"tracking_id"] = self.selfUser.trackingIdentifier;
        }
        return [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil];
    }
    else if(sessionRequest.method == ZMMethodPUT) {
        if(sessionRequest.pathComponents.count == 0) {
            return [self putSelfResponseForRequest:sessionRequest];
        }
        else if([@"phone" isEqualToString:sessionRequest.pathComponents.firstObject]) {
            return [self putSelfPhone:sessionRequest];
        }
        else if([@"email" isEqualToString:sessionRequest.pathComponents.firstObject]) {
            return [self putSelfEmail:sessionRequest];
        }
        else if([@"password" isEqualToString:sessionRequest.pathComponents.firstObject]) {
            return [self putSelfPassword:sessionRequest];
        }
        else if([@"handle" isEqualToString:sessionRequest.pathComponents.firstObject]) {
            return [self putSelfHandle:sessionRequest];
        }
    }
    return [self errorResponseWithCode:400 reason:@"invalid method"];
}

- (ZMTransportResponse *)putSelfPhone:(TestTransportSessionRequest *)sessionRequest;
{
    NSString *phone = [sessionRequest.payload asDictionary][@"phone"];
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

- (ZMTransportResponse *)putSelfEmail:(TestTransportSessionRequest *)sessionRequest;
{
    NSString *email = [sessionRequest.payload asDictionary][@"email"];
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

- (ZMTransportResponse *)putSelfPassword:(TestTransportSessionRequest *)sessionRequest;
{
    NSString *old_password = [sessionRequest.payload asDictionary][@"old_password"];
    NSString *new_password = [sessionRequest.payload asDictionary][@"new_password"];

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

- (ZMTransportResponse *)putSelfHandle:(TestTransportSessionRequest *)sessionRequest;
{
    NSString *handle = [sessionRequest.payload asDictionary][@"handle"];
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

- (ZMTransportResponse *)putSelfResponseForRequest:(TestTransportSessionRequest *)sessionRequest
{
    NSDictionary *changedFields = [sessionRequest.embeddedRequest.payload asDictionary];
    if(changedFields == nil) {
        return [self errorResponseWithCode:400 reason:@"missing-key"];
    }
    
    for(NSString *key in changedFields.allKeys) {
        if([key isEqualToString:@"name"]) {
            self.selfUser.name = changedFields[key];
        }
        else if([key isEqualToString:@"accent_id"]) {
            self.selfUser.accentID = (int16_t) [changedFields[key] integerValue];
        }
    }
    return [ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil];
}

// MARK: - /users/prekeys

- (ZMTransportResponse *)processUsersPreKeysRequest:(TestTransportSessionRequest *__unused)sessionRequest;
{
    NSDictionary *clientsMap = sessionRequest.embeddedRequest.payload.asDictionary;
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
    NSArray *userClients = [user.clients.allObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier IN %@", clientIds]];
    NSMutableDictionary *userClientsKeys = [NSMutableDictionary new];
    
    for (MockUserClient *client in userClients) {
        NSDictionary *keyPayload;
        MockPreKey *key = client.prekeys.anyObject;
        if (key == nil) {
            key = client.lastPrekey;
        }
        else {
            [[client mutableSetValueForKey:@"prekeys"] removeObject:key];
        }
        keyPayload = @{
                       @"id": @(key.identifier),
                       @"key": key.value
                       };
        userClientsKeys[client.identifier] = keyPayload;
    }
    return userClientsKeys;
}

// /users/id/prekeys

- (ZMTransportResponse *)processSingleUserPreKeysRequest:(TestTransportSessionRequest *__unused)sessionRequest;
{
    return [self errorResponseWithCode:400 reason:@"invalid method"];
}

// /users/id/prekeys/clientid

- (ZMTransportResponse *)processUserClientPreKeysRequest:(TestTransportSessionRequest *__unused)sessionRequest;
{
    return [self errorResponseWithCode:400 reason:@"invalid method"];
}

// MARK: - Handles
- (ZMTransportResponse *)processUserHandleRequest:(NSString *)handle requestPath:(NSString *)path;
{
    NSFetchRequest *fetchRequest = [MockUser sortedFetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"handle == %@", handle];
    NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
    NSData *payloadData;
    NSInteger statusCode;

    if(users.count > 0) {
        statusCode = 200;
        MockUser *user = users[0];
        id <ZMTransportData> payload = [self isConnectedToUser:user] ? [user transportData] : [user transportDataWhenNotConnected];
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

