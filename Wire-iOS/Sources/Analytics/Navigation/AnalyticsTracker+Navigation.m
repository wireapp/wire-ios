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


#import "AnalyticsTracker+Navigation.h"

@implementation AnalyticsTracker (Navigation)

- (void)tagEnteredOSSettings
{
    [self tagNavigationViewEntered:AnalyticsEventTypeNavigationViewOSSettings];
}

- (void)tagEnteredFindFriends
{
    [self tagNavigationViewEntered:AnalyticsEventTypeNavigationViewFindFriends];
}

- (void)tagNavigationViewEntered:(NSString *)navigationView
{
    NSDictionary *attributes = [self attributesForNavigationEventView:navigationView];
    attributes = [self attributesForNavigationEventEntered:attributes];
    
    [self tagNavigationEvent:attributes];
}

- (void)tagNavigationViewExited:(NSString *)navigationView
{
    NSDictionary *attributes = [self attributesForNavigationEventView:navigationView];
    attributes = [self attributesForNavigationEventExited:attributes];
    
    [self tagNavigationEvent:attributes];
}

- (void)tagNavigationViewSkipped:(NSString *)navigationView
{
    NSDictionary *attributes = [self attributesForNavigationEventView:navigationView];
    attributes = [self attributesForNavigationEventSkipped:attributes];
    
    [self tagNavigationEvent:attributes];
}

- (NSDictionary *)attributesForNavigationEventView:(NSString *)viewId
{
    NSDictionary *localAttributes = @{
                                      AnalyticsEventTypeNavigationViewKey : viewId,
                                      };
    
    return localAttributes;
}

- (NSDictionary *)attributesForNavigationEventEntered:(NSDictionary *) attributes
{
    NSDictionary *localAttributes = @{
                                 AnalyticsEventTypeNavigationActionKey : AnalyticsEventTypeNavigationActionEntered,
                                 };
    
    NSMutableDictionary *mutableAttributes = [attributes mutableCopy];
    
    [mutableAttributes addEntriesFromDictionary:localAttributes];
    
    return [mutableAttributes copy];
}

- (NSDictionary *)attributesForNavigationEventExited:(NSDictionary *) attributes
{
    NSDictionary *localAttributes = @{
                                      AnalyticsEventTypeNavigationActionKey : AnalyticsEventTypeNavigationActionExited,
                                      };
    
    NSMutableDictionary *mutableAttributes = [attributes mutableCopy];
    
    [mutableAttributes addEntriesFromDictionary:localAttributes];
    
    return [mutableAttributes copy];
}

- (NSDictionary *)attributesForNavigationEventSkipped:(NSDictionary *) attributes
{
    NSDictionary *localAttributes = @{
                                      AnalyticsEventTypeNavigationActionKey : AnalyticsEventTypeNavigationActionSkipped,
                                      };
    
    NSMutableDictionary *mutableAttributes = [attributes mutableCopy];
    
    [mutableAttributes addEntriesFromDictionary:localAttributes];
    
    return [mutableAttributes copy];
}

- (void)tagNavigationEvent:(NSDictionary *)attributes
{
    [self tagEvent:AnalyticsEventTypeNavigation attributes:attributes];
}

@end
