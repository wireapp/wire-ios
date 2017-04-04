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

@class MockUser;

@interface MockPushEvent : NSObject

@property (nonatomic, readonly, copy, nonnull) id<ZMTransportData> payload;
@property (nonatomic, readonly, nonnull) NSUUID *uuid;
@property (nonatomic, readonly, nonnull) NSDate *timestamp;
@property (nonatomic, readonly, nonnull) MockUser *fromUser;
@property (nonatomic, readonly) BOOL isTransient;

+(nonnull instancetype)eventWithPayload:(nonnull id<ZMTransportData>)payload uuid:(nonnull NSUUID *)uuid fromUser:(nonnull MockUser *)user isTransient:(BOOL)isTransient;
- (nonnull id<ZMTransportData>)transportData;
- (nonnull id<ZMTransportData>)transportDataForConversationEvent;

@end

