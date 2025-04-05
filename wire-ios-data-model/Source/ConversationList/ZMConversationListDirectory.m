//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

#import "ZMConversationListDirectory.h"
#import "ZMConversation+Internal.h"
#import <WireDataModel/WireDataModel-Swift.h>

static NSString * const ConversationListDirectoryKey = @"ZMConversationListDirectoryMap";

static NSString * const AllKey = @"All";
static NSString * const UnarchivedKey = @"Unarchived";
static NSString * const ArchivedKey = @"Archived";
static NSString * const PendingKey = @"Pending";


@interface ZMConversationListDirectory ()

@property (nonatomic) ZMConversationList* unarchivedConversations;
@property (nonatomic) ZMConversationList* conversationsIncludingArchived;
@property (nonatomic) ZMConversationList* archivedConversations;
@property (nonatomic) ZMConversationList* pendingConnectionConversations;
@property (nonatomic) ZMConversationList* clearedConversations;
@property (nonatomic) ZMConversationList* oneToOneConversations;
@property (nonatomic) ZMConversationList* groupConversations;
@property (nonatomic) ZMConversationList* channelConversations;
@property (nonatomic) ZMConversationList* favoriteConversations;

@property (nonatomic, readwrite) NSMutableDictionary<NSManagedObjectID *, ZMConversationList *> *listsByFolder;
@property (nonatomic) FolderList *folderList;

@property (nonatomic) ConversationPredicateFactory *factory;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;

@end


@implementation ZMConversationListDirectory

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [super init];
    if (self) {
        self.managedObjectContext = managedObjectContext;
        
        NSArray *allFolders = [self fetchAllFolders:managedObjectContext];
        
        ZMUser *selfUser = [ZMUser selfUserInContext:managedObjectContext];
        Team *selfTeam = selfUser.team;
        self.factory = [[ConversationPredicateFactory alloc] initWithSelfTeam:selfTeam];
        
        self.folderList = [[FolderList alloc] initWithLabels:allFolders];
        self.listsByFolder = [self createListsFromFolders:allFolders];
        
        self.unarchivedConversations = [[ZMConversationList alloc] initWithFilteringPredicate:[self.factory predicateForConversationsExcludingArchived]
                                                                         managedObjectContext:managedObjectContext
                                                                                  description:@"unarchivedConversations"];
        self.archivedConversations = [[ZMConversationList alloc] initWithFilteringPredicate:[self.factory predicateForArchivedConversations]
                                                                       managedObjectContext:managedObjectContext
                                                                                description:@"archivedConversations"];
        self.conversationsIncludingArchived = [[ZMConversationList alloc] initWithFilteringPredicate:[self.factory predicateForConversationsIncludingArchived]
                                                                                managedObjectContext:managedObjectContext
                                                                                         description:@"conversationsIncludingArchived"];
        self.pendingConnectionConversations = [[ZMConversationList alloc] initWithFilteringPredicate:[self.factory predicateForPendingConversations]
                                                                                managedObjectContext:managedObjectContext
                                                                                         description:@"pendingConnectionConversations"];
        self.clearedConversations = [[ZMConversationList alloc] initWithFilteringPredicate:[self.factory predicateForClearedConversations]
                                                                      managedObjectContext:managedObjectContext
                                                                               description:@"clearedConversations"];
        
        self.oneToOneConversations = [[ZMConversationList alloc] initWithFilteringPredicate:[self.factory predicateForOneToOneConversations]
                                                                       managedObjectContext:managedObjectContext
                                                                                description:@"oneToOneConversations"];
        
        self.groupConversations = [[ZMConversationList alloc] initWithFilteringPredicate:[self.factory predicateForGroupConversations]
                                                                    managedObjectContext:managedObjectContext
                                                                             description:@"groupConversations"];
        
        self.channelConversations = [[ZMConversationList alloc] initWithFilteringPredicate:[self.factory predicateForChannelConversations]
                                                                      managedObjectContext:managedObjectContext
                                                                               description:@"channelConversations"];
        
        self.favoriteConversations = [[ZMConversationList alloc] initWithFilteringPredicate:[self.factory predicateForLabeledConversations:[Label fetchFavoriteLabelIn:managedObjectContext]]
                                                                       managedObjectContext:managedObjectContext
                                                                                description:@"favorites"];
    }
    return self;
}

- (NSArray *)fetchAllFolders:(NSManagedObjectContext *)context
{
    return [context executeFetchRequestOrAssert:[Label sortedFetchRequest]];
}

- (NSMutableDictionary *)createListsFromFolders:(NSArray<Label *> *)folders
{
    NSMutableDictionary *listsByFolder = [NSMutableDictionary new];
    
    for (Label *folder in folders) {
        listsByFolder[folder.objectID] = [self createListForFolder:folder];
    }
    
    return listsByFolder;
}

- (ZMConversationList *)createListForFolder:(Label *)folder
{
    NSPredicate* predicate = [self.factory predicateForLabeledConversations:folder];
    return [[ZMConversationList alloc] initWithFilteringPredicate:predicate
                                             managedObjectContext:self.managedObjectContext
                                                      description:folder.objectIDURLString
                                                            label:folder];
}

- (void)insertFolders:(NSArray<Label *> *)labels
{
    if (labels.count == 0) {
        return;
    }
    
    for (Label *label in labels) {
        ZMConversationList *folderList = [self createListForFolder:label];
        self.listsByFolder[label.objectID] = folderList;
        [self.folderList insertLabel:label];
    }
}

- (void)deleteFolders:(NSArray<Label *> *)labels
{
    if (labels.count == 0) {
        return;
    }
    
    for (Label *label in labels) {
        [self.listsByFolder removeObjectForKey:label.objectID];
        [self.folderList removeLabel:label];
    }
}

- (void)refetchAllListsInManagedObjectContext:(NSManagedObjectContext *)moc
{
    // Some of the predicates used to filter the conversations lists rely on the self user's team,
    // which was nil at the time of initialization, so we need to recreate them now that the team is available.
    //
    // Note: `ZMConversationListDirectory` is created before slow sync. i.e: before we have fetched the self user's team.
    
    ZMUser *selfUser = [ZMUser selfUserInContext:moc];
    Team *selfTeam = selfUser.team;
    self.factory = [[ConversationPredicateFactory alloc] initWithSelfTeam:selfTeam];
    
    [self.pendingConnectionConversations recreateConversationsWithPredicate:[self.factory predicateForPendingConversations] managedContext:moc];
    [self.archivedConversations recreateConversationsWithPredicate:[self.factory predicateForArchivedConversations] managedContext:moc];
    [self.conversationsIncludingArchived recreateConversationsWithPredicate:[self.factory predicateForConversationsIncludingArchived] managedContext:moc];
    [self.unarchivedConversations recreateConversationsWithPredicate:[self.factory predicateForConversationsExcludingArchived] managedContext:moc];
    [self.clearedConversations recreateConversationsWithPredicate:[self.factory predicateForClearedConversations] managedContext:moc];
    [self.oneToOneConversations recreateConversationsWithPredicate:[self.factory predicateForOneToOneConversations] managedContext:moc];
    [self.groupConversations recreateConversationsWithPredicate:[self.factory predicateForGroupConversations] managedContext:moc];
    [self.channelConversations recreateConversationsWithPredicate:[self.factory predicateForChannelConversations] managedContext:moc];
    [self.favoriteConversations recreateConversationsWithPredicate:[self.factory predicateForLabeledConversations:[Label fetchFavoriteLabelIn:self.managedObjectContext]] managedContext:moc];
    
    NSArray *allFolders = [self fetchAllFolders:moc];
    self.folderList = [[FolderList alloc] initWithLabels:allFolders];
    self.listsByFolder = nil;
    self.listsByFolder = [self createListsFromFolders:allFolders];
}

- (NSArray<id<LabelType>> *)allFolders
{
    return self.folderList.backingList;
}

- (NSArray<id<LabelType>> *)nonDeletedFolders
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"markedForDeletion == NO"];
    return [self.folderList.backingList filteredArrayUsingPredicate:predicate];
}

@end



@implementation NSManagedObjectContext (ZMConversationListDirectory)

- (ZMConversationListDirectory *)conversationListDirectory;
{
    ZMConversationListDirectory *directory = self.userInfo[ConversationListDirectoryKey];
    if (directory == nil) {
        directory = [[ZMConversationListDirectory alloc] initWithManagedObjectContext:self];
        self.userInfo[ConversationListDirectoryKey] = directory;
    }
    return directory;
}

@end
