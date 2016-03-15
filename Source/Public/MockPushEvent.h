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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


@import ZMTransport;

@class MockUser;

@interface MockPushEvent : NSObject

@property (nonatomic, readonly, copy) id<ZMTransportData> payload;
@property (nonatomic, readonly) NSUUID *uuid;
@property (nonatomic, readonly) NSDate *timestamp;
@property (nonatomic, readonly) MockUser *fromUser;
@property (nonatomic, readonly) BOOL isTransient;

+(instancetype)eventWithPayload:(id<ZMTransportData>)payload uuid:(NSUUID *)uuid fromUser:(MockUser *)user isTransient:(BOOL)isTransient;
- (id<ZMTransportData>)transportData;
- (id<ZMTransportData>)transportDataForConversationEvent;

@end

