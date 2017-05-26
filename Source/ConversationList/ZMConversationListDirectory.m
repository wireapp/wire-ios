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

@property (nonatomic) Team *team;

@end



@implementation ZMConversationListDirectory

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)moc team:(Team *)team
{
    self = [super init];
    if (self) {
        self.team = team;
        NSArray *allConversations = [self fetchAllConversations:moc team:team];
        self.unarchivedConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                         filteringPredicate:[ZMConversation predicateForConversationsExcludingArchivedInTeam:team]
                                                                                        moc:moc
                                                                           debugDescription:@"unarchivedConversations"];
        self.archivedConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                       filteringPredicate:[ZMConversation predicateForArchivedConversationsInTeam:team]
                                                                                      moc:moc
                                                                         debugDescription:@"archivedConversations"];
        self.conversationsIncludingArchived = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                                filteringPredicate:[ZMConversation predicateForConversationsIncludingArchivedInTeam:team]
                                                                                               moc:moc
                                                                                  debugDescription:@"conversationsIncludingArchived"];

        // There are no connection requests inside of a team, we need
        // to ensure that we won't show the private ones
        NSPredicate *pendingConnectionsPredicate = team ? [NSPredicate predicateWithValue:NO] : ZMConversation.predicateForPendingConversations;
        self.pendingConnectionConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                                filteringPredicate:pendingConnectionsPredicate
                                                                                               moc:moc
                                                                                  debugDescription:@"pendingConnectionConversations"];
        self.clearedConversations = [[ZMConversationList alloc] initWithAllConversations:allConversations
                                                                      filteringPredicate:[ZMConversation predicateForClearedConversationsInTeam:team]
                                                                                     moc:moc
                                                                        debugDescription:@"clearedConversations"];
    }
    return self;
}

- (NSArray *)fetchAllConversations:(NSManagedObjectContext *)context team:(Team *)team
{
    NSFetchRequest *allConversationsRequest = [ZMConversation sortedFetchRequestWithPredicate:[ZMConversation predicateForConversationsInTeam:team]];
    // Since this is extremely likely to trigger the "otherActiveParticipants" and "connection" relationships, we make sure these gets prefetched:
    NSMutableArray *keyPaths = [NSMutableArray arrayWithArray:allConversationsRequest.relationshipKeyPathsForPrefetching];
    [keyPaths addObject:ZMConversationOtherActiveParticipantsKey];
    [keyPaths addObject:ZMConversationConnectionKey];
    allConversationsRequest.relationshipKeyPathsForPrefetching = keyPaths;
    
    NSError *error;
    return [context executeFetchRequest:allConversationsRequest error:&error];
    NSAssert(error != nil, @"Failed to fetch");
}

- (void)refetchAllListsInManagedObjectContext:(NSManagedObjectContext *)moc
{
    NSArray *allConversations = [self fetchAllConversations:moc team:self.team];
    for (ZMConversationList* list in self.allConversationLists){
        [list recreateWithAllConversations:allConversations];
    }
}

- (NSArray *)allConversationLists;
{
    return @[
             self.pendingConnectionConversations,
             self.archivedConversations,
             self.conversationsIncludingArchived,
             self.unarchivedConversations,
             ];
}

@end



@implementation NSManagedObjectContext (ZMConversationListDirectory)

- (ZMConversationListDirectory *)conversationListDirectoryForTeam:(Team *)team;
{
    NSString *key = team ? [ConversationListDirectoryKey stringByAppendingString:team.remoteIdentifier.transportString] : ConversationListDirectoryKey;
    ZMConversationListDirectory *directory = self.userInfo[key];
    if (directory == nil) {
        directory = [[ZMConversationListDirectory alloc] initWithManagedObjectContext:self team:team];
        self.userInfo[key] = directory;
    }
    return directory;
}

@end


