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



#import "ZMEventIDRangeSet.h"
#import "EventBlock.h"
#import "ZMEventID.h"



@interface ZMEventID (ZMEventIDRange)

- (instancetype)initWithEventUID:(EventUID const &)e;

@property (nonatomic, readonly) EventUID eventId;

@end



@interface ZMEventIDRange (ZMEventIDRangeContainer)

- (instancetype)initWithEventBlock:(EventBlock const&)block;

@property (nonatomic, readonly) EventBlock block;

@end



@implementation ZMEventIDRangeSet
{
    EventBlockContainer _container;
}

- (instancetype)initWithData:(NSData *)data {
    self = [super init];
    if(self) {
        _container = EventBlockContainer(data);
    }
    return self;
}

- (instancetype)initWithEvent:(ZMEventID *)event {
    self = [super init];
    if(self) {
        _container = EventBlockContainer();
        _container.add(event.eventId);
    }
    return self;
}


- (instancetype)initWithRanges:(NSArray *)ranges;
{
    self = [super init];
    if(self) {
        _container = EventBlockContainer();
        for(ZMEventIDRange *range in ranges) {
            NSAssert([range isKindOfClass:ZMEventIDRange.class], @"Wrong class for range: %@", range.class);
            _container.add([range block]);
        }
    }
    return self;
}

- (ZMEventIDRange *)rangeContainingEvent:(ZMEventID *)event;
{
    EventBlock block = _container.blockForEvent(event.eventId);
    if (block.empty()) {
        return nil;
    }
    return [[ZMEventIDRange alloc] initWithEventBlock:block];
}

- (NSString *)debugDescription;
{
    return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, _container.description()];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"%@", _container.description()];
}

- (BOOL)containsEvent:(ZMEventID *)event;
{
    return _container.hasEvent(event.eventId);
}

- (ZMEventIDRangeSet *)setByAddingEvent:(ZMEventID *)event;
{
    ZMEventIDRangeSet *newSet = [[ZMEventIDRangeSet alloc] init];
    newSet->_container = _container;
    newSet->_container.add(event.eventId);
    
    return newSet;
}

- (ZMEventIDRangeSet *)setByAddingRange:(ZMEventIDRange *)range;
{
    ZMEventIDRangeSet *newSet = [[ZMEventIDRangeSet alloc] init];
    newSet->_container = _container;
    newSet->_container.add(range.block);
    
    return newSet;
}

- (ZMEventIDRange *) firstGapWithinWindow:(ZMEventIDRange *)window;
{
    std::pair<EventUID, EventUID> oldWindow = _container.getWindow();
    
    if(window == nil) {
        _container.setWindow(EventBlockContainer::STARTING_EVENT, EventUID::UID_NONE);
    }
    else {
        _container.setWindow(window.oldestMessage.eventId, window.newestMessage.eventId);
    }
    EventBlock gap = _container.getGap(true);
    _container.setWindow(oldWindow.first, oldWindow.second);
    
    if(gap.empty()) {
        return nil;
    }
    
    EventUID lowest = gap.getLowestEvent();
    EventUID highest = gap.getHighestEvent();
    if(lowest.random == 0
       && (lowest.sequence == highest.sequence)
       && (lowest.sequence != 1)) {
        return nil;
    }
    return [[ZMEventIDRange alloc] initWithEventBlock:gap];
}

- (ZMEventIDRange *)lastGapWithinWindow:(ZMEventIDRange *)window;
{
    std::pair<EventUID, EventUID> oldWindow = _container.getWindow();
    
    if(window == nil) {
        _container.setWindow(EventBlockContainer::STARTING_EVENT, EventUID::UID_NONE);
    }
    else {
        _container.setWindow(window.oldestMessage.eventId, window.newestMessage.eventId);
    }
    EventBlock gap = _container.getGap(false);
    _container.setWindow(oldWindow.first, oldWindow.second);
    
    if(gap.empty()) {
        return nil;
    }
    
    EventUID lowest = gap.getLowestEvent();
    EventUID highest = gap.getHighestEvent();
    if(lowest.random == 0
       && (lowest.sequence == highest.sequence)
       && (lowest.sequence != 1)) {
        return nil;
    }
    return [[ZMEventIDRange alloc] initWithEventBlock:gap];
}

- (NSData *)serializeToData
{
    return _container.serialize();
}

- (BOOL)isEqual:(id)object;
{
    return [object isKindOfClass:ZMEventIDRangeSet.class] && [self isEqualToSet:object];
}

- (BOOL)isEqualToSet:(ZMEventIDRangeSet *)other
{
    return (other != nil) && (_container == other->_container);
}

@end




@implementation ZMEventIDRange
{
    EventBlock _block;
}

- (instancetype)initWithEventIDs:(NSArray *)eventIDs;
{
    self = [super init];
    if (self != nil) {
        for (ZMEventID *someID in eventIDs) {
            [self addEvent:someID];
        }
    }
    return self;
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, _block.description()];
}

- (EventBlock) block
{
    return _block;
}

- (BOOL)empty;
{
    return _block.empty();
}

- (BOOL)containsEvent:(ZMEventID *)event;
{
    return _block.containsEvent(event.eventId);
}

- (void)addEvent:(ZMEventID *)event;
{
    if (event != nil) {
        _block.addEvent(event.eventId, true);
    }
}

- (void)mergeRange:(ZMEventIDRange *)range;
{
    if (range != nil) {
        _block.merge(range->_block);
    }
}

- (ZMEventID *)oldestMessage;
{
    return [[ZMEventID alloc] initWithEventUID:_block.getLowestEvent()];
}

-(ZMEventID *)newestMessage;
{
    return [[ZMEventID alloc] initWithEventUID:_block.getHighestEvent()];
}

- (BOOL)isEqual:(id)other
{
    return [other isKindOfClass:ZMEventIDRange.class] && [self isEqualToRange:other];
}

- (BOOL)isEqualToRange:(ZMEventIDRange *)range;
{
    return range != nil && _block == range->_block;
}

@end




@implementation ZMEventID (ZMEventIDRange)

- (instancetype)initWithEventUID:(EventUID const &)event;
{
    return [self initWithMajor:(uint64_t)event.sequence minor:(uint64_t)event.random];
}

- (EventUID) eventId
{
    return EventUID((int)self.major, self.minor);
}

@end




@implementation ZMEventIDRange (ZMEventIDRangeContainer)

- (instancetype)initWithEventBlock:(EventBlock const&)block;
{
    self = [super init];
    if(self) {
        _block = block;
    }
    return self;
}

@end

