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


@import ZMUtilities;

#import "ZMSharableConversations.h"
#import "ZMConversationList.h"
#import "ZMConversation+Internal.h"
#import "ZMUser+Internal.h"
#import <zmessaging/zmessaging-Swift.h>

//TODO Ilya: sharing to cleared and archived conversations (observe cleared and archived list)

@interface ZMSharableConversations() <ZMConversationListObserver, ZMUserObserver>

@property (nonatomic) ZMSDispatchGroup *privateGroup;
@property (nonatomic) dispatch_queue_t privateQueue;
@property (nonatomic) id token;
@property (nonatomic) ZMConversationList *list;
@property (nonatomic) NSSet *userObservers;
@property (nonatomic) id usersToken;
@property (nonatomic) NSSet *observedUsers;
@property (nonatomic) NSManagedObjectContext *moc;
@property (nonatomic) NSDictionary *userIdsToConversationIds;
@property (nonatomic) NSArray *sharableConversations;

@end

@protocol ZMSharingExtensionAccessible <NSObject>

- (NSDictionary *)dictionaryForSharingExtension;

@end

@interface ZMConversation(Sharing) <ZMSharingExtensionAccessible>

@end

@interface ZMUser(Sharing) <ZMSharingExtensionAccessible>

@end

@interface NSFileManager(Sharing)

+ (NSURL *)sharedContainerURL;
+ (NSURL *)fileURLForConversationImageWithFileName:(NSString *)fileName;
+ (NSURL *)fileURLForConversations;
+ (void)syncWrite:(id)dataToWrite toFileWithURL:(NSURL *)url;

@end


@implementation ZMSharableConversations

- (instancetype)initWithConversations:(NSArray *)allConversations context:(NSManagedObjectContext *)moc
{
    self = [super init];
    if (self) {
        self.moc = moc;
        self.list = [[ZMConversationList alloc] initWithAllConversations:allConversations filteringPredicate:[ZMConversation predicateForSharableConversations] moc:moc debugDescription:@"sharableConversations"];
        
        self.privateGroup = [ZMSDispatchGroup groupWithLabel:@"ZMSharableConversationsDumpGroup"];
        self.privateQueue = dispatch_queue_create("ZMSharableConversationsDumpQueue", DISPATCH_QUEUE_SERIAL);

        self.token = [moc.globalManagedObjectContextObserver addConversationListObserver:self conversationList:self.list];
        [self dumpConversations:self.list];
        [self observeInsertedConversationsUsers:self.list];
    }
    return self;
}

#pragma mark - Conversation list observer

- (void)conversationListDidChange:(ConversationListChangeInfo *)changeInfo
{
    NSAssert([[NSThread currentThread] isMainThread], @"Conversation list notification should be posted on main thread!");
    
    [self dumpConversations:changeInfo.conversationList];
    
    if (changeInfo.insertedIndexes.count > 0) {
        NSArray *insertedConversations = [changeInfo.conversationList objectsAtIndexes:changeInfo.insertedIndexes];
        [self observeInsertedConversationsUsers:insertedConversations];
    }
    if (changeInfo.deletedIndexes.count > 0) {
        NSArray *deletedConversations = [[changeInfo deletedObjects] allObjects];
        [self stopObserveConversationsUsers:deletedConversations];
    }
}

#pragma mark - User oberver

- (void)userDidChange:(UserChangeInfo *)note
{
    NSAssert([[NSThread currentThread] isMainThread], @"User change notification should be posted on main thread!");

    ZMUser *user = (ZMUser *)note.user;
    if (note.imageSmallProfileDataChanged) {
        [self dumpUserImage:user];
    }
    else if (note.nameChanged || note.accentColorValueChanged) {
        [self updateConversationsWithUser:user];
    }
}

- (void)observeInsertedConversationsUsers:(NSArray *)conversations
{
    NSSet *usersToObserve = [self oneOnOneUsers:conversations];
    self.userIdsToConversationIds = [self userIdsToConversationIdsFromConversations:conversations];
    self.observedUsers = [self.observedUsers ?: [NSSet set] setByAddingObjectsFromSet:usersToObserve];
    [ZMUser removeUserObserverForToken:self.usersToken];
    self.usersToken = [ZMUser addUserObserver:self forUsers:self.observedUsers.allObjects managedObjectContext:self.moc];
    
    for (ZMUser *user in usersToObserve) {
        [self dumpUserImage:user];
        [self updateConversationsWithUser:user];
    }
}

- (void)stopObserveConversationsUsers:(NSArray *)conversations
{
    NSSet *usersToStopObserve = [self oneOnOneUsers:conversations];
    NSMutableSet *mObservedUsers = [self.observedUsers mutableCopy];
    NSMutableSet *userIdsToStopObserve = [NSMutableSet new];
    for (ZMUser *user in usersToStopObserve) {
        [mObservedUsers removeObject:user];
        [userIdsToStopObserve addObject:user.remoteIdentifier.UUIDString.lowercaseString];
    }
    self.observedUsers = [mObservedUsers copy];
    [ZMUser removeUserObserverForToken:self.usersToken];
    self.usersToken = [ZMUser addUserObserver:self forUsers:self.observedUsers.allObjects managedObjectContext:self.moc];
    
    [self cleanUpImages:userIdsToStopObserve];
}

#pragma mark - Helper methods

- (void)dumpConversations:(ZMConversationList *)conversationList
{
    if ([conversationList count] > 0) {
        NSArray *sharableConversations = [self sharableConversationsFromConversationsList:conversationList];
        self.sharableConversations = sharableConversations;
        [self enqueueConversationsSave];
    }
}

- (NSArray *)sharableConversationsFromConversationsList:(ZMConversationList *)list
{
    NSArray *sharableConversations = [list mapWithBlock:^id(ZMConversation *conversation) {
        NSDictionary *conversationDict = [conversation dictionaryForSharingExtension];
        return conversationDict;
    }];
    return sharableConversations;
}

- (NSSet *)oneOnOneUsers:(NSArray *)conversations
{
    return [NSSet setWithArray:[conversations mapWithBlock:^id(ZMConversation *conversation) {
        BOOL conversationIsOneOnOne = conversation.conversationType == ZMConversationTypeOneOnOne;
        ZMUser *user = conversation.otherActiveParticipants.firstObject;
        BOOL userIsSynced = user.remoteIdentifier != nil;
        if (conversationIsOneOnOne && userIsSynced) {
            return user;
        }
        else {
            return nil;
        }
    }]];
}

- (NSDictionary *)userIdsToConversationIdsFromConversations:(NSArray *)conversations
{
    NSMutableDictionary *userIdsToConversationIds = [NSMutableDictionary new];
    for (ZMConversation *conversation in conversations) {
        ZMUser *user = conversation.otherActiveParticipants.firstObject;
        if (user.remoteIdentifier != nil) {
            NSString *userId = user.remoteIdentifier.UUIDString.lowercaseString;
            userIdsToConversationIds[userId] = conversation.remoteIdentifier.UUIDString.lowercaseString;
        }
    }
    return userIdsToConversationIds;
}

- (void)updateConversationsWithUser:(ZMUser *)user
{
    if (user.name != nil || user.accentColorValue != ZMAccentColorUndefined || user.initials != nil) {
        NSDictionary *conversationDictionary = [self dictionaryForConversationWithUser:user];
        NSMutableDictionary *changedConversationDictionary = [conversationDictionary mutableCopy];
        changedConversationDictionary[@"user_data"] = [user dictionaryForSharingExtension];
        [self updateConversation:conversationDictionary withChangedConversation:changedConversationDictionary];
        [self enqueueConversationsSave];
    }
}

- (void)updateConversation:(NSDictionary *)originalConversation withChangedConversation:(NSDictionary *)changedConversation
{
    NSMutableArray *updatedSharableConversations = [self.sharableConversations mutableCopy];
    NSUInteger index = [updatedSharableConversations indexOfObject:originalConversation];
    if (index != NSNotFound) {
        [updatedSharableConversations replaceObjectAtIndex:index withObject:changedConversation];
    }
    self.sharableConversations = updatedSharableConversations;
}

- (NSMutableDictionary *)dictionaryForConversationWithUser:(ZMUser *)user
{
    NSString *userId = user.remoteIdentifier.UUIDString.lowercaseString;
    NSString *conversationId = self.userIdsToConversationIds[userId];
    NSPredicate *conversaionPredicate = [NSPredicate predicateWithFormat:@"remoteIdentifier == %@", conversationId.uppercaseString];
    NSMutableDictionary *conversation = [[self.sharableConversations filteredArrayUsingPredicate:conversaionPredicate] firstObject];
    return conversation;
}

#pragma mark - File IO operations

- (void)dumpUserImage:(ZMUser *)user
{
    NSString *userId = user.remoteIdentifier.UUIDString.lowercaseString;
    if (user.imageSmallProfileData != nil) {
        NSData *dataToWrite = user.imageSmallProfileData;
        NSString *fileName = [self fileNameForImageForConversationWithUserWithId:userId];
        NSURL *url = [NSFileManager fileURLForConversationImageWithFileName:fileName];
        [self.privateGroup asyncOnQueue:self.privateQueue block:^{
            [NSFileManager syncWrite:dataToWrite toFileWithURL:url];
        }];
    }
}

- (void)cleanUpImages:(NSSet *)userIdsToRemove
{
    [self.privateGroup asyncOnQueue:self.privateQueue block:^{
        for (NSString *userId in userIdsToRemove) {
            NSString *fileName = [self fileNameForImageForConversationWithUserWithId:userId];
            NSURL *url = [NSFileManager fileURLForConversationImageWithFileName:fileName];
            if (url != nil) {
                [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
            }
        }
    }];
}

- (void)enqueueConversationsSave
{
    static BOOL saveEnqueued = NO;
    if (!saveEnqueued) {
        saveEnqueued = YES;
        NSURL *url = [NSFileManager fileURLForConversations];
        NSArray *conversationsToWrite = [self.sharableConversations copy];
        [self.privateGroup notifyOnQueue:self.privateQueue block:^{
            [NSFileManager syncWrite:conversationsToWrite toFileWithURL:url];
            saveEnqueued = NO;
        }];
    }
}

- (NSString *)fileNameForImageForConversationWithUserWithId:(NSString *)userId
{
    return [self.userIdsToConversationIds[userId] lowercaseString];
}

- (void)dealloc
{
    [self.list removeConversationListObserverForToken:self.token];
    [ZMUser removeUserObserverForToken:self.usersToken];
}

@end

@implementation NSFileManager(Sharing)

+ (NSURL *)sharedContainerURL
{
    return [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:[NSUserDefaults groupName]];
}

+ (NSURL *)fileURLForConversationImageWithFileName:(NSString *)fileName
{
    if (fileName == nil) {
        return nil;
    }
    NSURL *url = [self sharedContainerURL];
    url = [url URLByAppendingPathComponent:@"profile_images"];
    if (url != nil) {
        [[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:nil];
    }
    url = [url URLByAppendingPathComponent:fileName];
    return url;
}

+ (NSURL *)fileURLForConversations
{
    NSURL *url = [self sharedContainerURL];
    url = [url URLByAppendingPathComponent:@"conversations"];
    return url;
}

+ (void)syncWrite:(id)dataToWrite toFileWithURL:(NSURL *)url
{
    if (url != nil && dataToWrite != nil) {
        BOOL success = [dataToWrite writeToURL:url atomically:YES];
        VerifyReturn(success);
    }
}

@end

#pragma mark - ZMSharingExtensionAccessible

@implementation ZMConversation(Sharing)

- (NSDictionary *)dictionaryForSharingExtension
{
    return @{
             @"remoteIdentifier" : self.remoteIdentifier.UUIDString,
             @"name": self.displayName,
             @"type": self.conversationType == ZMConversationTypeOneOnOne ? @2 : @0,
             @"archived": @(self.isArchived),
             @"user_data": [self.otherActiveParticipants.firstObject dictionaryForSharingExtension] ?: @{}
             };
}

@end

@implementation ZMUser(Sharing)

- (NSDictionary *)dictionaryForSharingExtension
{
    return @{
             @"name": self.displayName ?: @"",
             @"accent_id": @(self.accentColorValue),
             @"initials" : self.initials ?: @"",
             };
}

@end

