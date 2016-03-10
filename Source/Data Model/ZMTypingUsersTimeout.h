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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


@import Foundation;
@class ZMUser;
@class ZMConversation;



@interface ZMTypingUsersTimeout : NSObject

- (void)addUser:(ZMUser *)user conversation:(ZMConversation *)conversation withTimeout:(NSDate *)timeout;
- (void)removeUser:(ZMUser *)user conversation:(ZMConversation *)conversation;

- (BOOL)containsUser:(ZMUser *)user conversation:(ZMConversation *)conversation;

@property (nonatomic, readonly) NSDate *firstTimeout;

- (NSSet *)userIDsInConversation:(ZMConversation *)conversation;

/// Removed the set of user & conversations that have a time-out before the given date, and returns the object IDs of those conversations.
- (NSSet *)pruneConversationsThatHaveTimedOutAfter:(NSDate *)pruneDate;

@end
