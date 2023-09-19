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


@import WireUtilities;
@import WireTransport;

#import "ZMRequestGenerator.h"


@implementation NSArray (ZMRequestGeneratorSource)

- (ZMTransportRequest *)nextRequestForAPIVersion:(APIVersion)apiVersion;
{
    __block ZMTransportRequest *returnedRequest = nil;
    NSAssert(![NSThread isMainThread], @"should not run on main Thread");
    NSLog(@"Running on thread %@", NSThread.currentThread);

    dispatch_group_t group = dispatch_group_create();

    for (uint i = 0; i < self.count; i++) {
        dispatch_group_enter(group);
        NSLog(@"🕵🏽 object %@", [[self objectAtIndex:i] class]);
        [[self objectAtIndex:i] nextRequestForAPIVersion:apiVersion completion:^(ZMTransportRequest * _Nullable request) {
            returnedRequest = request;
            dispatch_group_leave(group);
        }];
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        if (returnedRequest != nil) {
            break;
        }
    }


    return returnedRequest;
}

@end
