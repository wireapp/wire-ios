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


#import <UIKit/UIKit.h>



@class AnalyticsTracker;
@class ZMConversation;



@interface GiphyViewController : UIViewController

@property (nonatomic) AnalyticsTracker *analyticsTracker;

@property (nonatomic, strong, readonly) NSData *imageData;
@property (nonatomic, copy, readonly) NSString *searchTerm;

@property (nonatomic) ZMConversation *conversation;

@property (nonatomic, copy) void (^onConfirm)();
@property (nonatomic, copy) void (^onCancel)();

- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

- (instancetype)initWithSearchTerm:(NSString *)searchTerm NS_DESIGNATED_INITIALIZER;

@end
