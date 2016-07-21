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


#import "ConversationContentViewController.h"



@interface ConversationContentViewController (Scrolling) <UIScrollViewDelegate>

- (void)scrollToBottomAnimated:(BOOL)animation;
- (BOOL)scrollToMessage:(id<ZMConversationMessage>)message animated:(BOOL)animated;
- (BOOL)scrollMessageToBottom:(id<ZMConversationMessage>)message withOffset:(CGFloat)offset;

@end
