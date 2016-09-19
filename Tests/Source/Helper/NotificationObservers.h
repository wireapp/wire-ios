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


#import "ZMNotifications+Internal.h"

typedef void(^ObserverCallback)( NSObject * _Nonnull  note);



@interface ChangeObserver : NSObject

@property (nonatomic, readonly, nonnull) NSMutableArray *notifications;
@property (nonatomic, copy, nullable) ObserverCallback notificationCallback;
@property (nonatomic) BOOL tornDown;

- (void)clearNotifications;
- (void)tearDown;

@end



@interface ConversationChangeObserver : ChangeObserver <ZMConversationObserver>
- (nonnull instancetype)initWithConversation:(nonnull ZMConversation *)conversation;

@end



@interface ConversationListChangeObserver : ChangeObserver <ZMConversationListObserver>
- (nonnull instancetype)initWithConversationList:(nonnull ZMConversationList *)conversationList;

@end



@interface UserChangeObserver : ChangeObserver <ZMUserObserver>
- (nonnull instancetype)initWithUser:(nonnull ZMUser *)user;

@end



@interface MessageChangeObserver : ChangeObserver <ZMMessageObserver>
- (nonnull instancetype)initWithMessage:(nonnull ZMMessage *)message;

@end



@interface MessageWindowChangeObserver : ChangeObserver <ZMConversationMessageWindowObserver>
- (nonnull instancetype)initWithMessageWindow:(nonnull ZMConversationMessageWindow *)window;

@end

