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


@class ZMConversation, Button;


@interface GroupConversationHeader : UIView

@property (nonatomic, readonly, nonnull) Button *inviteButton;

- (nonnull instancetype)initWithCoder:(NSCoder * __nullable)aDecoder NS_UNAVAILABLE;
- (nonnull instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (nonnull instancetype)initWithConversation:(ZMConversation * __nonnull)conversation NS_DESIGNATED_INITIALIZER;

@end
