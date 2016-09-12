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

#import "MockTransportSession+Clients.h"
#import "MockTransportSession+internal.h"
#import "MockUserClient.h"

@implementation MockTransportSession (Clients)

// /clients
- (ZMTransportResponse *)processClientsRequest:(TestTransportSessionRequest *)sessionRequest;
{
    // POST /clients
    if (sessionRequest.method == ZMMethodPOST && sessionRequest.pathComponents.count == 0) {
        return [self processRegisterClientRequest:sessionRequest];
    }
    // GET /clients
    else if (sessionRequest.method == ZMMethodGET && sessionRequest.pathComponents.count == 0) {
        return [self processGetClientsListRequest:sessionRequest];
    }
    // GET /clients/id
    else if (sessionRequest.method == ZMMethodGET && sessionRequest.pathComponents.count == 1) {
        return [self processGetClientByIdRequest:sessionRequest];
    }
    // PUT /clients/id
    else if (sessionRequest.method == ZMMethodPUT && sessionRequest.pathComponents.count == 1) {
        return [self processUpdateClientRequest:sessionRequest];
    }
    // DELETE /clients/id
    else if (sessionRequest.method == ZMMethodDELETE && sessionRequest.pathComponents.count == 1) {
        return [self processDeleteClientRequest:sessionRequest];
    }
    // GET /clients/id/prekeys
    else if (sessionRequest.method == ZMMethodGET && sessionRequest.pathComponents.count == 2) {
        return [self processClientPreKeysRequest:sessionRequest];
    }
    return [self errorResponseWithCode:400 reason:@"invalid method"];
}

static NSInteger const MaxUserClientsAllowed = 2;

// POST /clients
- (ZMTransportResponse *)processRegisterClientRequest:(TestTransportSessionRequest *)sessionRequest;
{
    ZMTransportResponse *invalidRequestResponse = [self errorResponseWithCode:400 reason:@"invalid method"];
    ZMTransportResponse *toManyClientsRespone = [self errorResponseWithCode:403 reason:@"too-many-clients"];
    ZMTransportResponse *passwordRequiredRespone = [self errorResponseWithCode:403 reason:@"missing-auth"];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"UserClient"];
    NSArray *existingClients = [self.managedObjectContext executeFetchRequestOrAssert:request];
    if (existingClients.count == MaxUserClientsAllowed) {
        return toManyClientsRespone;
    }
    
    BOOL selfClientExists = nil != [existingClients firstObjectMatchingWithBlock:^BOOL(MockUserClient *userClient){
        return userClient.user == self.selfUser;
    }];
    
    NSDictionary *paylod = sessionRequest.payload.asDictionary;
    
    NSString *password = [paylod optionalStringForKey:@"password"];
    if (selfClientExists &&
        !(password != nil && [password isEqualToString:self.selfUser.password])) {
        return passwordRequiredRespone;
    }
    
    MockUserClient *newClient = [MockUserClient insertClientWithPayload:paylod contenxt:self.managedObjectContext];
    newClient.user = self.selfUser;
    
    if (newClient != nil) {
        return [ZMTransportResponse responseWithPayload:[newClient transportData] HTTPStatus:200 transportSessionError:nil];
    }
    
    return invalidRequestResponse;
}

- (MockUserClient *)userClientByIdentifier:(NSString *)identifier
{
    NSFetchRequest *request = [MockUserClient fetchRequestWithPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", identifier]];
    
    NSArray *userClients = [self.managedObjectContext executeFetchRequestOrAssert:request];
    RequireString(userClients.count <= 1, "Too many user clients with one identifier");
    
    return userClients.firstObject;
}

// GET /clients
- (ZMTransportResponse *)processGetClientsListRequest:(TestTransportSessionRequest *__unused)sessionRequest;
{
    NSArray *payload = [self.selfUser.clients mapWithBlock:^id(MockUserClient *client) {
        return [client transportData];
    }].allObjects;
    return [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil];
}

// GET /clients/id
- (ZMTransportResponse *)processGetClientByIdRequest:(TestTransportSessionRequest *__unused)sessionRequest;
{
    MockUserClient *userClient = [self userClientByIdentifier:sessionRequest.pathComponents[0]];
    if (userClient == nil) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
    }
    
    return [ZMTransportResponse responseWithPayload:userClient.transportData HTTPStatus:200 transportSessionError:nil];
}

// GET /clients/id/prekeys
- (ZMTransportResponse *)processClientPreKeysRequest:(TestTransportSessionRequest *__unused)sessionRequest;
{
    return [self errorResponseWithCode:418 reason:@"Not implemented"];
}

// PUT /clients/id
- (ZMTransportResponse *)processUpdateClientRequest:(TestTransportSessionRequest *__unused)sessionRequest;
{
    return [self errorResponseWithCode:418 reason:@"Not implemented"];
}

// DELETE /clients/id
- (ZMTransportResponse *)processDeleteClientRequest:(TestTransportSessionRequest *__unused)sessionRequest;
{
    MockUserClient *userClient = [self userClientByIdentifier:sessionRequest.pathComponents[0]];
    if (userClient == nil) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
    }
    [self.managedObjectContext deleteObject:userClient];
    
    return [ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil];    
}


@end
