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


@import Foundation;



/// This class provides a way to transmit analytics data
/// from app extensions to main app.
@interface SharedAnalytics : NSObject

/// Singletone instance
+ (nonnull instancetype)sharedInstance;

/// Stores event in shared container.
/// @param event - event name
/// @param context - event context
/// @param attributes - event name
- (void)storeEvent:(nonnull NSString *)event
           context:(nonnull NSString *)context
        attributes:(nullable NSDictionary *)attributes;

/// Fetches all events stored in shared container. Don't forget to call
/// -removeAllEvents after to avoid adding events to Analytics engine multiple times.
- (nonnull NSArray *)allEvents;

/// Clears all events stored in shared container
- (void)removeAllEvents;

@end
