//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

@implementation MockTransportSession (FeatureConfigs)

// handles /feature-configs

- (ZMTransportResponse *)processFeatureConfigsRequest:(ZMTransportRequest *)request;
{
    if ([request matchesWithPath:@"/feature-configs" method:ZMTransportRequestMethodGet]) {
        return [self processGetFeatureConfigsRequest: request];
    } else {
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:404 transportSessionError:nil apiVersion:request.apiVersion];
    }
}

@end
