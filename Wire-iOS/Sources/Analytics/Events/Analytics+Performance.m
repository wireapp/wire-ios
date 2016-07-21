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


#import "Analytics+Performance.h"

@implementation Analytics (Performance)

// These are the different launch times we use to change the bracketing,
// under 5 seconds we bracket in 250ms steps, from 5 to 10 seconds we user
// half a second steps and beyond that we only track full seconds.
// Launch times equal to or longer than 15 seconds will be tracked as 15 seconds.
static NSUInteger const TrackingIntervalFast = 5000;
static NSUInteger const TrackingIntervalLong = 10000;
static NSUInteger const TrackingIntervalMax = 15000;

static NSUInteger const BracketingTimeShort = 250;
static NSUInteger const BracketingTimeMedium = 500;
static NSUInteger const BracketingTimeLarge = 1000;


// The input is in milliseconds, but we only want to bracket it
// in order to make the number of different values manageable
static NSUInteger bracketingForLaunchTime(NSUInteger launchTime) {
    if (launchTime <= TrackingIntervalFast) {
        return BracketingTimeShort;
    } else if (launchTime <= TrackingIntervalLong) {
        return BracketingTimeMedium;
    } else {
        return BracketingTimeLarge;
    }
}

static NSNumber * rangedLaunchTime(NSUInteger launchTime) {
    if (launchTime >= TrackingIntervalMax) {
        return @(TrackingIntervalMax);
    }
    NSUInteger bracketingInterval = bracketingForLaunchTime(launchTime);
    NSUInteger quarterSeconds = launchTime / bracketingInterval;
    return @(quarterSeconds * bracketingInterval);
}

- (void)tagApplicationLaunchTime:(NSUInteger)launchTime
{
    NSDictionary *attributes = @{ @"launch_time": rangedLaunchTime(launchTime) };
    [self tagEvent:@"performance.application_start" attributes:attributes];
}

@end
