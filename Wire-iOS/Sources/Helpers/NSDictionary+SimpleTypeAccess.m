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



#import "NSDictionary+SimpleTypeAccess.h"

static NSArray *kKnownStringYESBoolValues = nil;

@implementation NSDictionary (SimpleTypeAccess)

- (CGFloat)floatForKey:(id)key
{
    id value = [self objectForKey:key];
    if (! [value isKindOfClass:[NSNumber class]]) {
        return 0.0;
    }
    NSNumber *number = (NSNumber *)value;

    return [number floatValue];
}

- (BOOL)boolForKey:(id)key
{
    id value = [self objectForKey:key];
    if (!value) {
        return NO;
    }
    if ([value isKindOfClass:[NSString class]]) {
        if (nil == kKnownStringYESBoolValues) {
            kKnownStringYESBoolValues = [NSArray arrayWithObjects:@"yes", @"true", @"1", nil];
        }

        NSString *string = (NSString *)value;
        if ([kKnownStringYESBoolValues containsObject:[string lowercaseString]]) {
            return YES;
        }
        return NO;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)value;
        return [number boolValue];
    }
    return NO;
}

@end
