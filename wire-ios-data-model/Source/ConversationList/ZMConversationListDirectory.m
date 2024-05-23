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

#import "ZMConversationListDirectory.h"
#import "ZMConversation+Internal.h"
#import "ZMConversationList+Internal.h"
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
@property (nonatomic) ZMConversationList* favoriteConversations;

@property (nonatomic) ConversationPredicateFactory *factory;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;

@end



@implementation ZMConversationListDirectory

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc
{
    self = [super init];
    if (self) {
        self.managedObjectContext = moc;

        NSArray *allConversations = [self fetchAllConversations:moc];

        ZMUser *selfUser = [ZMUser selfUserInContext:moc];
        Team *selfTeam = selfUser.team;
        self.factory = [[ConversationPredicateFactory alloc] initWithSelfTeam:selfTeam];

        self.unarchivedConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                         filteringPredicate:[self.factory predicateForConversationsExcludingArchived]
                                                                                        moc:moc
                                                                                description:@"unarchivedConversations"];
        self.archivedConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                       filteringPredicate:[self.factory predicateForArchivedConversations]
                                                                                      moc:moc
                                                                              description:@"archivedConversations"];
        self.conversationsIncludingArchived = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                                filteringPredicate:[self.factory predicateForConversationsIncludingArchived]
                                                                                               moc:moc
                                                                                       description:@"conversationsIncludingArchived"];
        self.pendingConnectionConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                                filteringPredicate:[self.factory predicateForPendingConversations]
                                                                                               moc:moc
                                                                                       description:@"pendingConnectionConversations"];
        self.clearedConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                      filteringPredicate:[self.factory predicateForClearedConversations]
                                                                                     moc:moc
                                                                             description:@"clearedConversations"];

        self.oneToOneConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                       filteringPredicate:[self.factory predicateForOneToOneConversations]
                                                                                      moc:moc
                                                                              description:@"oneToOneConversations"];

        self.groupConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                    filteringPredicate:[self.factory predicateForGroupConversations]
                                                                                   moc:moc
                                                                           description:@"groupConversations"];

        self.favoriteConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                       filteringPredicate:[self.factory predicateForLabeledConversations:[Label fetchFavoriteLabelIn:moc]]
                                                                                      moc:moc description:@"favorites"];
    }
    return self;
}

- (NSArray *)fetchAllConversations:(NSManagedObjectContext *)context
{
    NSFetchRequest *allConversationsRequest = [ZMConversation sortedFetchRequest];
    // Since this is extremely likely to trigger the "participantRoles" and "connection" relationships, we make sure these gets prefetched:
    NSMutableArray *keyPaths = [NSMutableArray arrayWithArray:allConversationsRequest.relationshipKeyPathsForPrefetching];
    [keyPaths addObject:ZMConversationParticipantRolesKey];
    [keyPaths addObject:[NSString stringWithFormat:@"%@.connection", ZMConversationOneOnOneUserKey]];
    allConversationsRequest.relationshipKeyPathsForPrefetching = keyPaths;

    NSError *error;
    return [context executeFetchRequest:allConversationsRequest error:&error];
    NSAssert(error != nil, @"Failed to fetch");
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

    NSArray *allConversations = [self fetchAllConversations:moc];

    [self.pendingConnectionConversations recreateWithAllConversations:allConversations predicate:[self.factory predicateForPendingConversations]];
    [self.archivedConversations recreateWithAllConversations:allConversations predicate:[self.factory predicateForArchivedConversations]];
    [self.conversationsIncludingArchived recreateWithAllConversations:allConversations predicate:[self.factory predicateForConversationsIncludingArchived]];
    [self.unarchivedConversations recreateWithAllConversations:allConversations predicate:[self.factory predicateForConversationsExcludingArchived]];
    [self.clearedConversations recreateWithAllConversations:allConversations predicate:[self.factory predicateForClearedConversations]];
    [self.oneToOneConversations recreateWithAllConversations:allConversations predicate:[self.factory predicateForOneToOneConversations]];
    [self.groupConversations recreateWithAllConversations:allConversations predicate:[self.factory predicateForGroupConversations]];
    [self.favoriteConversations recreateWithAllConversations:allConversations predicate:[self.factory predicateForLabeledConversations:[Label fetchFavoriteLabelIn:self.managedObjectContext]]];
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
