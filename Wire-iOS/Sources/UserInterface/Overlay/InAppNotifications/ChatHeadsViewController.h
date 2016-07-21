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


@class ChatHeadsViewController;
@protocol ZMConversationMessage;

@protocol ChatHeadsViewControllerDelegate <NSObject>
@required
- (BOOL)chatHeadsViewController:(ChatHeadsViewController *)viewController shouldDisplayMessage:(id<ZMConversationMessage>)message;
- (BOOL)chatHeadsViewController:(ChatHeadsViewController *)viewController isMessageInCurrentConversation:(id<ZMConversationMessage>)message;
- (void)chatHeadsViewController:(ChatHeadsViewController *)viewController didSelectMessage:(id<ZMConversationMessage>)message;
@end

@interface ChatHeadsViewController : UIViewController
@property (nonatomic, weak) id <ChatHeadsViewControllerDelegate> delegate;
@end
