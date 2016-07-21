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


#import "AppDelegate+ExtensionAnalytics.h"
#import <WireExtensionComponents/SharedAnalytics.h>
#import <WireExtensionComponents/SharedAnalyticsEvent.h>
#import "AnalyticsTracker.h"

@implementation AppDelegate (ExtensionAnalytics)

- (void)uploadExtensionAnalytics
{
    NSArray *events = [[SharedAnalytics sharedInstance] allEvents];
    
    NSMutableDictionary *analyticsTrackerPull = [@{} mutableCopy];
    for (SharedAnalyticsEvent *event in events) {
        AnalyticsTracker *tracker = analyticsTrackerPull[event.context];
        if (tracker == nil) {
            tracker = [AnalyticsTracker analyticsTrackerWithContext:event.context];
            analyticsTrackerPull[event.context] = tracker;
        }
        
        if (event.attributes) {
            [tracker tagEvent:event.eventName attributes:event.attributes];
        } else {
            [tracker tagEvent:event.eventName];
        }
    }
    [[SharedAnalytics sharedInstance] removeAllEvents];
}

@end
