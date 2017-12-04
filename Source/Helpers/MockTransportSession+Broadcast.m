//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

#import <WireMockTransport/WireMockTransport-Swift.h>
#import "MockTransportSession+Broadcast.h"
#import "MockTransportSession+OTR.h"

@implementation MockTransportSession (Broadcast)

- (ZMTransportResponse *)processBroadcastRequest:(ZMTransportRequest *)request
{
    if ([request matchesWithPath:@"/broadcast/otr/messages" method:ZMMethodPOST])
    {
        if (request.binaryData != nil) {
            return [self processBroascastOTRMessageToConversationWithProtobuffData:request.binaryData
                                                                             query:request.queryParameters];
        }
        else {
            return [self processBroadcastOTRMessageWithPayload:[request.payload asDictionary]
                                                         query:request.queryParameters];
        }
    }
    
    return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
}

// POST /broadcast/otr/messages
- (ZMTransportResponse *)processBroadcastOTRMessageWithPayload:(NSDictionary *)payload query:(NSDictionary *)query
{
    NSAssert(self.selfUser != nil, @"No self user in mock transport session");
    
    NSDictionary *recipients = payload[@"recipients"];
    MockUserClient *senderClient = [self otrMessageSender:payload];
    if (senderClient == nil) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
    }
    
    NSString *onlyForUser = query[@"report_missing"];
    NSDictionary *missedClients = [self missedClients:recipients sender:senderClient onlyForUserId:onlyForUser];
    NSDictionary *redundantClients = [self redundantClients:recipients];
    
    NSDictionary *responsePayload = @{@"missing": missedClients, @"redundant": redundantClients, @"time": [NSDate date].transportString};
    
    NSInteger statusCode = 412;
    if (missedClients.count == 0) {
        statusCode = 201;
    }
    
    return [ZMTransportResponse responseWithPayload:responsePayload HTTPStatus:statusCode transportSessionError:nil];
}

// POST /broadcast/otr/messages
- (ZMTransportResponse *)processBroascastOTRMessageToConversationWithProtobuffData:(NSData *)binaryData query:(NSDictionary *)query
{
    NSAssert(self.selfUser != nil, @"No self user in mock transport session");
    
    ZMNewOtrMessage *otrMetaData = (ZMNewOtrMessage *)[[[ZMNewOtrMessage builder] mergeFromData:binaryData] build];
    if (otrMetaData == nil) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
    }
    
    MockUserClient *senderClient = [self otrMessageSenderFromClientId:otrMetaData.sender];
    if (senderClient == nil) {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
    }
    
    NSString *onlyForUser = query[@"report_missing"];
    NSDictionary *missedClients = [self missedClientsFromRecipients:otrMetaData.recipients sender:senderClient onlyForUserId:onlyForUser];
    NSDictionary *redundantClients = [self redundantClientsFromRecipients:otrMetaData.recipients];
    
    NSDictionary *payload = @{@"missing": missedClients, @"redundant": redundantClients, @"time": [NSDate date].transportString};
    
    NSInteger statusCode = 412;
    if (missedClients.count == 0) {
        statusCode = 201;
    }
    
    return [ZMTransportResponse responseWithPayload:payload HTTPStatus:statusCode transportSessionError:nil];
}

@end
