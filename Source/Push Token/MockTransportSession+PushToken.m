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
#import "MockTransportSession+PushToken.h"
#import "MockTransportSession+internal.h"
#import "MockTransportSession.h"
#import <WireMockTransport/WireMockTransport-Swift.h>
#import "MockConnection.h"
#import <WireMockTransport/WireMockTransport-Swift.h>



@implementation MockTransportSession (PushToken)

/// handles /push/tokens/
- (ZMTransportResponse *)processPushTokenRequest:(ZMTransportRequest *)sessionRequest;
{
    if ([sessionRequest matchesWithPath:@"/push/tokens" method:ZMMethodPOST]) {
        return [self processPostPushes:sessionRequest];
    }
    
    return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil];
}

- (ZMTransportResponse *)processPostPushes:(ZMTransportRequest *)sessionRequest;
{
    NSDictionary *payload = [sessionRequest.payload asDictionary];
    if (payload != nil) {
        NSString *token = [payload stringForKey:@"token"];
        NSString *app = [payload stringForKey:@"app"];
        NSString *transport = [payload stringForKey:@"transport"];
        if ((token != nil) && (0 < app.length) && ([transport isEqualToString:@"APNS"] || [transport isEqualToString:@"APNS_VOIP"])) {
            [self addPushToken:@{@"token": token, @"app": app,  @"transport" : transport}];
            return [ZMTransportResponse responseWithPayload:@{@"token": token, @"app": app, @"transport": transport} HTTPStatus:201 transportSessionError:nil];
        }
    }
    return [ZMTransportResponse responseWithPayload:@{@"code": @400} HTTPStatus:400 transportSessionError:nil];
}

@end
