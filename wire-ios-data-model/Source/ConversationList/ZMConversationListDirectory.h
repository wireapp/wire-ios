//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
@import CoreData;

@protocol LabelType;

@class Label;
@class ZMConversationContainer;
@class ZMSharableConversations;
@class NSManagedObjectContext;


@interface ZMConversationListDirectory : NSObject

@property (nonatomic, readonly, nonnull) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, readonly, nonnull) ZMConversationContainer* unarchivedConversations; ///< archived, not pending
@property (nonatomic, readonly, nonnull) ZMConversationContainer* conversationsIncludingArchived; ///< unarchived, not pending,
@property (nonatomic, readonly, nonnull) ZMConversationContainer* archivedConversations; ///< archived, not pending
@property (nonatomic, readonly, nonnull) ZMConversationContainer* pendingConnectionConversations; ///< pending
@property (nonatomic, readonly, nonnull) ZMConversationContainer* clearedConversations; /// conversations with deleted messages (clearedTimestamp is set)
@property (nonatomic, readonly, nonnull) ZMConversationContainer* oneToOneConversations;
@property (nonatomic, readonly, nonnull) ZMConversationContainer* groupConversations;
@property (nonatomic, readonly, nonnull) ZMConversationContainer* favoriteConversations;

@property (nonatomic, readonly, nonnull) NSMutableDictionary<NSManagedObjectID *, ZMConversationContainer *> *listsByFolder;
@property (nonatomic, readonly, nonnull) NSArray<id<LabelType>> *allFolders;


/// Refetches all conversation lists and resets the snapshots
/// Call this when the app re-enters the foreground
- (void)refetchAllListsInManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc;
- (void)insertFolders:(NSArray<Label *> * _Nonnull)labels;
- (void)deleteFolders:(NSArray<Label *> * _Nonnull)labels;

@end



@interface NSManagedObjectContext (ZMConversationListDirectory)

- (nonnull ZMConversationListDirectory *)conversationListDirectory;

@end
