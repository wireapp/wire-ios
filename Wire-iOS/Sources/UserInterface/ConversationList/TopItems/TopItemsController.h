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

@class ZMConversation;
@class TopItemsController;



@protocol TopItemsDelegate <NSObject>

- (void)topItemsControllerPlusButtonPressed:(TopItemsController *)controller;

- (void)topItemsControllerDidSelectActiveVoiceConversation:(TopItemsController *)controller focusOnView:(BOOL)focus completion:(dispatch_block_t)completion;

- (void)topItemsController:(TopItemsController *)controller activeVoiceConversationChanged:(ZMConversation *)conversation;

@end



@interface TopItemsController : UIViewController

@property (nonatomic, readonly) ZMConversation *activeVoiceConversation;
@property (nonatomic, weak) id<TopItemsDelegate>delegate;

/// Selects the active voice conv if any, and calls topItemsControllerDidSelectActiveVoiceConversation:focusOnView:
/// on the delegate if it succeeds
- (void)selectActiveVoiceConversationAndFocusOnView:(BOOL)focus;
- (void)selectActiveVoiceConversationAndFocusOnView:(BOOL)focus completion:(dispatch_block_t)completion;

/// Deselect all items
- (void)deselectAll;

@end
