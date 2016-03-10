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


#import <Foundation/Foundation.h>

@class ZMEventID;

@interface ZMEventIDRange : NSObject

- (instancetype)initWithEventIDs:(NSArray *)eventIDs;

@property (nonatomic, readonly) ZMEventID *oldestMessage;
@property (nonatomic, readonly) ZMEventID *newestMessage;
@property (nonatomic, readonly) BOOL empty;

- (BOOL)containsEvent:(ZMEventID *)event;

- (void)addEvent:(ZMEventID *)event;

- (void)mergeRange:(ZMEventIDRange *)range;

- (BOOL)isEqualToRange:(ZMEventIDRange *)range;

@end




@interface ZMEventIDRangeSet : NSObject

- (ZMEventIDRange *)firstGapWithinWindow:(ZMEventIDRange *)window;
- (ZMEventIDRange *)lastGapWithinWindow:(ZMEventIDRange *)window;

- (BOOL)containsEvent:(ZMEventID *)event;

- (ZMEventIDRangeSet *)setByAddingEvent:(ZMEventID *)event;

- (ZMEventIDRangeSet *)setByAddingRange:(ZMEventIDRange *)range;

- (NSData *)serializeToData;

- (instancetype)initWithData:(NSData *)data;

- (instancetype)initWithEvent:(ZMEventID *)event;

- (instancetype)initWithRanges:(NSArray *)ranges;

- (ZMEventIDRange *)rangeContainingEvent:(ZMEventID *)event;

@end
