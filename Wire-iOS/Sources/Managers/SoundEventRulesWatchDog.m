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


#import "SoundEventRulesWatchDog.h"



@implementation SoundEventRulesWatchDog

- (instancetype)initWithIgnoreTime:(NSTimeInterval)ignoreTime
{
    self = [super init];
    if (self) {
        self.ignoreTime = ignoreTime;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithIgnoreTime:0.0];
}

- (BOOL)outputAllowed
{
    if (self.muted) {
        return NO;
    }
    // Otherwise check if we passed the @c ignoreTime starting from @c watchTime
    NSDate *currentTime = [NSDate date];
    NSDate *stayQuiteTillTime = [self.startIgnoreDate dateByAddingTimeInterval:self.ignoreTime];
    if ([currentTime compare:stayQuiteTillTime] == NSOrderedDescending) {
        return YES;
    }
    return NO;
}

@end
