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


@class ZMUserSession;

/// Use @c ZMConversationListChangeNotification to get notified about changes.
@interface ZMConversationList : NSArray

/// Returns an auto-updating array of all unarchived conversations in the @c session .
+ (ZMConversationList *)conversationsInUserSession:(ZMUserSession *)session;

/// Returns an auto-updating array of ALL conversations in the @c session .
+ (ZMConversationList *)conversationsIncludingArchivedInUserSession:(ZMUserSession *)session;

/// Returns an auto-updating array of all archived conversations in the @c session .
+ (ZMConversationList *)archivedConversationsInUserSession:(ZMUserSession *)session;

/// Returns an auto-updating array of all conversation where the voice channel is not idle
+ (ZMConversationList *)nonIdleVoiceChannelConversationsInUserSession:(ZMUserSession *)session;

/// Returns an auto-updating array of all conversation where the voice channel is active (i.e. ongoing call). Typically should be no more than one conversation.
+ (ZMConversationList *)activeCallConversationsInUserSession:(ZMUserSession *)session;

/// Returns an array of all peding connection conversations in the @c session .
+ (ZMConversationList *)pendingConnectionConversationsInUserSession:(ZMUserSession *)session;

+ (ZMConversationList *)clearedConversationsInUserSession:(ZMUserSession *)session;

@end
