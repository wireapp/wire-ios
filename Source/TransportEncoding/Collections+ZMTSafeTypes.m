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


@import ZMUtilities;
#import "Collections+ZMTSafeTypes.h"
#import "ZMEventID.h"
#import "NSObject+ZMTransportEncoding.h"

static NSString *lastCallstackFrames() {
    NSArray *symbols = [NSThread callStackSymbols];
    return [[symbols subarrayWithRange:NSMakeRange(0u, MIN(7u, symbols.count))] componentsJoinedByString:@"\n"];
}

static id ObjectWhichIsKindOfClass(NSDictionary *dictionary, NSString *key, Class class, BOOL required)
{
    id object = dictionary[key];
    if ([object isKindOfClass:class]) {
        return object;
    }
    if ((object != nil) && (object != [NSNull null])) {
        ZMLogError(@"%@ is not a valid %@ in <%@ %p>. Callstack:\n%@", key, class, dictionary.class, dictionary, lastCallstackFrames());
    } else if (required) {
        ZMLogError(@"nil values for %@ in <%@ %p>. Callstack:\n%@", key,  dictionary.class, dictionary, lastCallstackFrames());
    }
    return nil;
}

static id RequiredObjectWhichIsKindOfClass(NSDictionary *dictionary, NSString *key, Class class)
{
    return ObjectWhichIsKindOfClass(dictionary, key, class, YES);
}

static id OptionalObjectWhichIsKindOfClass(NSDictionary *dictionary, NSString *key, Class class)
{
    return ObjectWhichIsKindOfClass(dictionary, key, class, NO);
}

@implementation NSDictionary (ZMSafeTypes)

- (NSString *)stringForKey:(NSString *)key
{
    return RequiredObjectWhichIsKindOfClass(self, key, NSString.class);
}

- (NSString *)optionalStringForKey:(NSString *)key;
{
    return OptionalObjectWhichIsKindOfClass(self, key, NSString.class);
}

- (NSNumber *)numberForKey:(NSString *)key;
{
    return RequiredObjectWhichIsKindOfClass(self, key, NSNumber.class);
}

- (NSNumber *)optionalNumberForKey:(NSString *)key;
{
    return OptionalObjectWhichIsKindOfClass(self, key, NSNumber.class);
}

- (NSArray *)optionalArrayForKey:(NSString *)key;
{
    return OptionalObjectWhichIsKindOfClass(self, key, NSArray.class);
}

- (NSArray *)arrayForKey:(NSString *)key;
{
    return RequiredObjectWhichIsKindOfClass(self, key, NSArray.class);
}

- (NSDictionary *)dictionaryForKey:(NSString *)key;
{
    return RequiredObjectWhichIsKindOfClass(self, key, NSDictionary.class);
}

- (NSDictionary *)optionalDictionaryForKey:(NSString *)key;
{
    return OptionalObjectWhichIsKindOfClass(self, key, NSDictionary.class);
}

- (NSData *)dataForKey:(NSString *)key;
{
    return RequiredObjectWhichIsKindOfClass(self, key, NSData.class);
}

- (NSUUID *)optionalUuidForKey:(NSString *)key;
{
    id uuid = self[key];
    if ([uuid isKindOfClass:NSUUID.class]) {
        return uuid;
    }
    if([uuid isKindOfClass:NSString.class]) {
        return [NSUUID uuidWithTransportString:uuid];
    }
    return nil;
}

- (NSUUID *)uuidForKey:(NSString *)key;
{
    id uuid = [self optionalUuidForKey:key];
    if(uuid == nil) {
        ZMLogError(@"%@ is not a valid NSUUID in <%@ %p>. Callstack:\n%@", key, self.class, self, lastCallstackFrames());
    }
    return uuid;
}

- (NSDate *)dateForKey:(NSString *)key;
{
    id date = self[key];
    if ([date isKindOfClass:NSDate.class]) {
        return date;
    }
    if ([date isKindOfClass:NSString.class]) {
        return [NSDate dateWithTransportString:date];
    }
    ZMLogError(@"%@ is not a valid NSDate in <%@ %p>. Callstack:\n%@", key, self.class, self, lastCallstackFrames());
    return nil;
}

- (ZMEventID *)optionalEventForKey:(NSString *)key;
{
    id eventId = self[key];
    if ([eventId isKindOfClass:ZMEventID.class]) {
        return eventId;
    }
    if ([eventId isKindOfClass:NSString.class]) {
        return [ZMEventID eventIDWithString:eventId];
    }
    return nil;
}

- (ZMEventID *)eventForKey:(NSString *)key;
{
    id eventId = [self optionalEventForKey:key];
    if(eventId == nil) {
        ZMLogError(@"%@ is not a valid ZMEventID in <%@ %p>. Callstack:\n%@", key, self.class, self, lastCallstackFrames());
    }
    return eventId;
}

@end



@implementation NSArray (ZMSafeTypes)

/// Returns a copy of the array where all elements are dictionaries. Non-dictionaries are filtered out
- (NSArray *)asDictionaries;
{
    // XXX OPTIMIZATION: Use NSFastENumeration
    return [self objectsOfClass:NSDictionary.class];
}
@end
