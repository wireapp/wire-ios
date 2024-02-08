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


@import WireSystem;

#import "NSObject+ZMTransportEncoding.h"

// MARK: - ISO8601 Dates

/// ISO8601 (.withInternetDateTime, .withFractionalSeconds)
static NSISO8601DateFormatter* iso8601DateFormatter;
/// Covers the cases where no fractional seconds are provided.
static NSISO8601DateFormatter* alternativeISO8601DateFormatter;

@implementation NSDate (ZMTransportEncoding)

+ (instancetype)dateWithTransportString:(NSString *)transportString;
{
    NSDate *date = [[self ISO8601DateFormatter] dateFromString:transportString];
    if (date) {
        return date;
    } else {
        return [[self alternativeISO8601DateFormatter] dateFromString:transportString];
    }
}

- (NSString *)transportString;
{
    return [[NSDate ISO8601DateFormatter] stringFromDate:self];
}

+ (NSISO8601DateFormatter *)ISO8601DateFormatter
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSISO8601DateFormatter *dateFormatter = [[NSISO8601DateFormatter alloc] init];
        dateFormatter.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
        iso8601DateFormatter = dateFormatter;
    });
    return iso8601DateFormatter;
}

+ (NSISO8601DateFormatter *)alternativeISO8601DateFormatter
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSISO8601DateFormatter *alternativeDateFormatter = [[NSISO8601DateFormatter alloc] init];
        alternativeDateFormatter.formatOptions = NSISO8601DateFormatWithInternetDateTime;
        alternativeISO8601DateFormatter = alternativeDateFormatter;
    });
    return alternativeISO8601DateFormatter;
}

@end

// MARK: - UUID

@implementation NSUUID (ZMTransportEncoding)

+ (instancetype)uuidWithTransportString:(NSString *)transportString;
{
    return [[NSUUID alloc] initWithUUIDString:transportString];
}

- (NSString *)transportString;
{
    return [[self UUIDString] lowercaseString];
}

@end
