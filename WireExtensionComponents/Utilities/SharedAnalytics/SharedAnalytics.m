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


#import "SharedAnalytics.h"
#import "SharedAnalyticsEvent.h"

@import ZMUtilities;



static NSString * const SharedAnalyticsEventsKey = @"SharedAnalyticsEvents";



@implementation SharedAnalytics

+ (nonnull instancetype)sharedInstance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)storeEvent:(nonnull NSString *)event
           context:(nonnull NSString *)context
        attributes:(nullable NSDictionary *)attributes
{
    SharedAnalyticsEvent *newEvent = [[SharedAnalyticsEvent alloc] initWithName:event
                                                                        context:context
                                                                     attributes:attributes];
    NSMutableArray *events = [[self fetchAllEvents] mutableCopy];
    [events addObject:[newEvent dictionaryRepresentation]];
    [self.defaults setObject:events forKey:SharedAnalyticsEventsKey];
    [self.defaults synchronize];
}

- (nonnull NSArray *)fetchAllEvents
{
    NSArray *events = [self.defaults objectForKey:SharedAnalyticsEventsKey];
    if (events == nil || ! [events isKindOfClass:[NSArray class]]) {
        events = @[];
    }
    return events;
}

- (nonnull NSArray *)allEvents
{
    NSArray *eventObjects = [self fetchAllEvents];
    NSMutableArray *events = [@[] mutableCopy];
    for (NSDictionary *eventObject in eventObjects) {
        SharedAnalyticsEvent *event = [[SharedAnalyticsEvent alloc] initWithDictionary:eventObject];
        [events addObject:event];
    }
    return events;
}

- (void)removeAllEvents
{
    [self.defaults setObject:@[] forKey:SharedAnalyticsEventsKey];
    [self.defaults synchronize];
}

- (NSUserDefaults *)defaults
{
    return [NSUserDefaults sharedUserDefaults];
}

@end
