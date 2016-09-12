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
@import CoreData;
#import "MockTransportSession+internal.h"
#import "MockTransportSession.h"
#import "MockUser.h"
#import "MockConnection.h"

@implementation MockTransportSession (ConnectionsHelper)



/// handles /connections
- (ZMTransportResponse *)processSelfConnectionsRequest:(TestTransportSessionRequest *)sessionRequest;
{
    if ((sessionRequest.method == ZMMethodGET) && (sessionRequest.pathComponents.count == 0)) {
        return [self processGetConnections:sessionRequest];
    }
    if ((sessionRequest.method == ZMMethodGET) && (sessionRequest.pathComponents.count == 1)) {
        return [self processGetSpecifiedConnection:sessionRequest];
    }
    if ((sessionRequest.method == ZMMethodPOST) && (sessionRequest.pathComponents.count == 0)) {
        return [self processPostConnection:sessionRequest];
    }
    if (sessionRequest.method == ZMMethodPUT && (sessionRequest.pathComponents.count == 1)) {
        return [self processPutConnection:sessionRequest];
    }
    
    return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
}


/// PUT /connections/to-user-id
- (ZMTransportResponse *)processPutConnection:(TestTransportSessionRequest *)sessionRequest
{
    NSString *remoteID = sessionRequest.pathComponents[0];
    MockConnection *connection = [self connectionFromUserIdentifier:self.selfUser.identifier toUserIdentifier:remoteID];
    if (connection == nil) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
    }
    
    NSDictionary *changedFields = [sessionRequest.embeddedRequest.payload asDictionary];
    if(changedFields == nil) {
        return [self errorResponseWithCode:400 reason:@"missing fields"];
    }
    
    for(NSString *key in changedFields.allKeys) {
        if([key isEqualToString:@"status"]) {
            ZMTConnectionStatus oldStatus = [MockConnection statusFromString:connection.status];
            connection.status = changedFields[key];
            ZMTConnectionStatus status = [MockConnection statusFromString:connection.status];
            
            if (status == ZMTConnectionStatusSent && oldStatus == ZMTConnectionStatusCancelled) {
                return [ZMTransportResponse responseWithPayload:nil HTTPStatus:403 transportSessionError:nil];
            }
            
            switch (status) {
                case ZMTConnectionStatusPending:
                case ZMTConnectionStatusIgnored:
                case ZMTConnectionStatusSent:
                    connection.conversation.type = ZMTConversationTypeConnection;
                    break;
                    
                case ZMTConnectionStatusAccepted:
                case ZMTConnectionStatusBlocked:
                    connection.conversation.type = ZMTConversationTypeOneOnOne;
                    break;
                    
                default:
                    connection.conversation.type = ZMTConversationTypeInvalid;
                    break;	
            }
        }
    }
    
    return [ZMTransportResponse responseWithPayload:connection.transportData HTTPStatus:200 transportSessionError:nil];
}


/// GET /connections/to-user-id
- (ZMTransportResponse *)processGetSpecifiedConnection:(TestTransportSessionRequest *)sessionRequest
{
    NSString *remoteID = sessionRequest.pathComponents[0];
    MockConnection *connection = [self connectionFromUserIdentifier:self.selfUser.identifier toUserIdentifier:remoteID];
    if (connection == nil) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
    }
    
    return [ZMTransportResponse responseWithPayload:connection.transportData HTTPStatus:200 transportSessionError:nil];
}

/// GET /connections
- (ZMTransportResponse *)processGetConnections:(TestTransportSessionRequest *)sessionRequest
{
    NSString *sizeString = [sessionRequest.query optionalStringForKey:@"size"];
    NSUUID *start = [sessionRequest.query optionalUuidForKey:@"start"];
    
    NSFetchRequest *request = [MockConnection sortedFetchRequest];
    
    NSArray *connections = [self.managedObjectContext executeFetchRequestOrAssert:request];
    
    if(start != nil) {
        NSUInteger index = [connections indexOfObjectPassingTest:^BOOL(MockConnection *obj, NSUInteger idx, BOOL *stop) {
            NOT_USED(idx);
            if([obj.to.identifier isEqualToString:start.transportString]) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        if(index != NSNotFound) {
            connections = [connections subarrayWithRange:NSMakeRange(index+1, connections.count - index-1)];
        }
    }
    
    BOOL hasMore = NO;
    if(sizeString != nil) {
        NSUInteger remainingConnections = connections.count;
        NSUInteger connectionsToFetch = (NSUInteger) sizeString.integerValue;
        hasMore = (remainingConnections > connectionsToFetch);
        NSUInteger connectionsToReturn = MIN(remainingConnections, connectionsToFetch);
        connections = [connections subarrayWithRange:NSMakeRange(0u, connectionsToReturn)];
    }

    NSMutableDictionary *resultData = [NSMutableDictionary dictionary];
    resultData[@"has_more"] = @(hasMore);
    NSMutableArray *connectionData = [NSMutableArray array];
    for (MockConnection *c in connections) {
        [connectionData addObject:c.transportData];
    }
    resultData[@"connections"] = connectionData;
    
    return [ZMTransportResponse responseWithPayload:resultData HTTPStatus:200 transportSessionError:nil];
}

/// POST /connections
- (ZMTransportResponse *)processPostConnection:(TestTransportSessionRequest *)sessionRequest
{
    NSString *userID = [[sessionRequest.payload asDictionary] stringForKey:@"user"];
    NSString *message = [[sessionRequest.payload asDictionary] stringForKey:@"message"];
    
    MockUser *user = [self fetchUserWithIdentifier:userID];
    MockConnection *connection = [self createConnectionRequestFromUser:self.selfUser toUser:user message:message];
    return [ZMTransportResponse responseWithPayload:connection.transportData HTTPStatus:201 transportSessionError:nil];
}

@end
