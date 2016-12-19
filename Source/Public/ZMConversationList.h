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


@class ZMUserSession;
@protocol ZMManagedObjectContextProvider;

/// Use @c ZMConversationListChangeNotification to get notified about changes.
@interface ZMConversationList : NSArray

@property (nonatomic, readonly, nonnull) NSString *identifier;

- (void)resort;

@end


@interface ZMConversationList (UserSession)

+ (nonnull ZMConversationList *)conversationsIncludingArchivedInUserSession:(nonnull id<ZMManagedObjectContextProvider>)session;
+ (nonnull ZMConversationList *)conversationsInUserSession:(nonnull id<ZMManagedObjectContextProvider>)session;
+ (nonnull ZMConversationList *)archivedConversationsInUserSession:(nonnull id<ZMManagedObjectContextProvider>)session;

+ (nonnull ZMConversationList *)nonIdleVoiceChannelConversationsInUserSession:(nonnull id<ZMManagedObjectContextProvider>)session;
+ (nonnull ZMConversationList *)activeCallConversationsInUserSession:(nonnull id<ZMManagedObjectContextProvider>)session;

+ (nonnull ZMConversationList *)pendingConnectionConversationsInUserSession:(nonnull id<ZMManagedObjectContextProvider>)session;
+ (nonnull ZMConversationList *)clearedConversationsInUserSession:(nonnull id<ZMManagedObjectContextProvider>)session;



@end

