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


#import "ZMEventID.h"

#import <locale.h>
#import <xlocale.h>


typedef struct ZMEventID_s {
    uint64_t major;
    uint64_t minor;
} ZMEventID_t;



@implementation ZMEventID
{
    ZMEventID_t _identifier;
}

- (uint64_t)major
{
    return _identifier.major;
}

- (uint64_t)minor
{
    return _identifier.minor;
}


+ (instancetype)eventIDWithString:(NSString *)string;
{
    if (string == nil || ![string isKindOfClass:NSString.class]) {
        return nil;
    }
    
    locale_t l = newlocale(LC_ALL, "POSIX", NULL);
    unsigned long long v[2];
    int count = 0;
    int const result = sscanf_l([string UTF8String], l, "%llx.%llx%n", v, v+1, &count);
    freelocale(l);
    if (result != 2) {
        return nil;
    }
    if ((count < 0) || (((NSUInteger)  count) != [string length])) {
        return nil;
    }
    
    ZMEventID_t e = {};
    e.major = v[0];
    e.minor = v[1];
    
    // Check for overflow:
    if ((e.major == UINT64_MAX) || (e.minor == UINT64_MAX)) {
        return nil;
    }
    
    ZMEventID *eventID = [[ZMEventID alloc] init];
    if (eventID != nil) {
        eventID->_identifier = e;
    }
    return eventID;
}

+ (instancetype)eventIDWithMajor:(uint64_t)major minor:(uint64_t)minor;
{
    return [[ZMEventID alloc] initWithMajor:major minor:minor];
}

- (instancetype)initWithMajor:(uint64_t)major minor:(uint64_t)minor;
{
    self = [super init];
    if (self != nil) {
        self->_identifier.major = major;
        self->_identifier.minor = minor;
    }
    return self;
}

- (NSString *)transportString
{
    return [NSString stringWithFormat:@"%llx.%llx", _identifier.major, _identifier.minor];
}

- (NSString *)debugDescription;
{
    return [NSString stringWithFormat:@"<%@: %p> %llx.%llx", self.class, self, _identifier.major, _identifier.minor];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"<%llx.%llx>", _identifier.major, _identifier.minor];
}

- (void)getValue:(void *)value
{
    memcpy(value, &_identifier, sizeof(_identifier));
}

- (const char *)objCType
{
    return @encode(ZMEventID_t);
}

- (NSComparisonResult)compare:(ZMEventID *)otherEventID;
{
    if(otherEventID == nil) {
        return NSOrderedDescending;
    }
    if (_identifier.major < otherEventID->_identifier.major) {
        return NSOrderedAscending;
    } else if (_identifier.major == otherEventID->_identifier.major) {
        if (_identifier.minor < otherEventID->_identifier.minor) {
            return NSOrderedAscending;
        } else if (_identifier.minor == otherEventID->_identifier.minor) {
            return NSOrderedSame;
        } else {
            return NSOrderedDescending;
        }
    } else {
        return NSOrderedDescending;
    }
    return NSOrderedAscending;
}

- (BOOL)isEqualToEventID:(ZMEventID *)otherEventID;
{
    return [self isEqual:otherEventID];
}

+ (instancetype)earliestOfEventID:(ZMEventID *)eventID1 and:(ZMEventID *)eventID2;
{
    if (eventID1 == nil) {
        return eventID2;
    }
    if (eventID2 == nil) {
        return eventID1;
    }
    return ([eventID1 compare:eventID2] == NSOrderedAscending) ? eventID1 : eventID2;
}

+ (instancetype)latestOfEventID:(ZMEventID *)eventID1 and:(ZMEventID *)eventID2;
{
    if (eventID1 == nil) {
        return eventID2;
    }
    if (eventID2 == nil) {
        return eventID1;
    }
    return ([eventID1 compare:eventID2] == NSOrderedDescending) ? eventID1 : eventID2;
}

@end



@implementation ZMEventID (SerializingToData)

+ (ZMEventID *)decodeFromData:(NSData *)data;
{
    if (data.length != sizeof(ZMEventID_t)) {
        return nil;
    }
    ZMEventID_t e;
    [data getBytes:&e length:sizeof(e)];
    e.major = CFSwapInt64BigToHost(e.major);
    e.minor = CFSwapInt64BigToHost(e.minor);
    
    ZMEventID *eventID = [[ZMEventID alloc] init];
    if (eventID != nil) {
        eventID->_identifier = e;
    }
    return eventID;
}

- (NSData *)encodeToData;
{
    ZMEventID_t e = _identifier;
    e.major = CFSwapInt64HostToBig(e.major);
    e.minor = CFSwapInt64HostToBig(e.minor);
    return [NSData dataWithBytes:&e length:sizeof(e)];
}

@end
