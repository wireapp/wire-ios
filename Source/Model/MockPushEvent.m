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
#import "MockPushEvent.h"
#import <ZMCMockTransport/ZMCMockTransport-Swift.h>

@implementation MockPushEvent

+(instancetype)eventWithPayload:(id<ZMTransportData>)payload uuid:(NSUUID *)uuid fromUser:(MockUser *)user isTransient:(BOOL)isTransient;
{
    return [[MockPushEvent alloc] initWithPayload:payload uuid:uuid fromUser:user isTransient:isTransient];
}

-(instancetype)initWithPayload:(id<ZMTransportData>)payload uuid:(NSUUID *)uuid fromUser:(MockUser *)user isTransient:(BOOL)isTransient;
{
    self = [super init];
    if(self) {
        _payload = payload;
        _uuid = uuid;
        _timestamp = [NSDate date];
        _fromUser = user;
        _isTransient = isTransient;
    }
    return self;
}

-(id<ZMTransportData>)transportData
{
    return @{
             @"id" : self.uuid.transportString,
             @"payload" : @[ self.payload ],
             @"transient" : @(self.isTransient),
             };
}

-(id<ZMTransportData>)transportDataForConversationEvent
{
    return @{
             @"id" : self.uuid.transportString,
             @"payload" : @[ self.payload ],
             @"time" : self.timestamp.transportString,
             @"from" : self.fromUser.identifier,
             @"transient" : @(self.isTransient),
             };
}

- (NSString *)description;
{
    return [(NSObject *)self.payload description];
}

- (NSString *)debugDescription;
{
    return [NSString stringWithFormat:@"<%@: %p> payload = %@", self.class, self, self.payload];
}

@end
