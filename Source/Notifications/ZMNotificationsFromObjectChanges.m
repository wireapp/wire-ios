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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


#import "ZMNotificationsFromObjectChanges.h"
#import "ZMNotifications+Internal.h"
#import "ZMNotificationDispatcher+Private.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "ZMFunctional.h"
#import "ZMConnection+Internal.h"
#import "ZMCallParticipant.h"
#import "ZMUserDisplayNameGenerator+Internal.h"
#import "ZMConversationListDirectory.h"
#import "ZMConversationList+Internal.h"
#import "ZMConversation+Internal.h"
#import "ZMManagedObject+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMVoiceChannel+Internal.h"
#import "ZMManagedObjectContext.h"
#import "ZMVoiceChannelNotifications+Internal.h"
#import "ZMEventID.h"
#import "ZMUser+Internal.h"

static ZMLogLevel_t const ZMLogLevel ZM_UNUSED = ZMLogLevelWarn;

@interface ZMNotificationsFromObjectChanges ()

@property (nonatomic) NSManagedObjectContext *moc;

@property (nonatomic) NSMutableArray *notificationsToFire;

@property (nonatomic) NSMutableSet *updatedConversations;
@property (nonatomic) NSMutableSet *updatedConnections;
@property (nonatomic) NSMutableSet *updatedUsers;
@property (nonatomic) NSMutableSet *updatedMessages;
@property (nonatomic) NSMutableSet *updatedAndInsertedConnections;
@property (nonatomic) NSMutableSet *updatedCallParticipants;
@property (nonatomic) NSMutableSet *insertedCallParticipants;
@property (nonatomic) NSMutableSet *insertedMessages;
@property (nonatomic) NSSet *usersWithUpdatedDisplayNames;
@property (nonatomic) NSSet *insertedConversations;
@property (nonatomic) NSSet *removedConversations;

@end



@implementation ZMNotificationsFromObjectChanges

- (instancetype)initWithMoc:(NSManagedObjectContext *)moc;

{
    self = [super init];
    if(self) {
        self.moc = moc;
    }
    return self;
}

+ (void)fireNotificationsForObjectDidChangeNotification:(NSNotification *)note
                                    managedObjectContext:(NSManagedObjectContext *)moc
                  previousActiveVoiceChannelConversation:(ZMConversation *)previousActiveVoiceChannelConversation;
{
    NOT_USED(previousActiveVoiceChannelConversation);
    ZMNotificationsFromObjectChanges *notificationsForChanges = [[ZMNotificationsFromObjectChanges alloc] initWithMoc:moc];

    [notificationsForChanges calculateAndFireNotificationsWithNote:note previousActiveVoiceChannelConversation:previousActiveVoiceChannelConversation];
}

- (void)calculateAndFireNotificationsWithNote:(NSNotification *)note previousActiveVoiceChannelConversation:(ZMConversation *)previousActiveVoiceChannelConversation
{
    [self calculateNotificationsFromChangeNotification:note withBlock:^NSArray *(){
        
        NSArray *voiceChannelChangeNotifications = [self createVoiceChannelChangeNotificationsWithPreviousActiveVoiceChannelConversation:previousActiveVoiceChannelConversation];
        NSArray *userChangeNotifications = [self createUserChangeNotification];
        NSArray *messageChangeNotifications = [self createMessagesChangeNotificationWithUserChangeNotifications:userChangeNotifications];
        NSArray *conversationChangeNotifications = [self createConversationChangeNotificationsWithUserChangeNotifications:userChangeNotifications
                                                                                               messageChangeNotifications:messageChangeNotifications];
        NSArray *connectionChangeNotifications = [self createConnectionChangeNotification];
        NSArray *newUnreadMessagesNotifications = [self createNewUnreadMessagesNotification];
        NSArray *updatedKnocksNotifications = [self createNewUnreadKnocksNotificationsForUpdatedKnocks];
        NSArray *conversationListChangeNotifications = [self createConversationListChangeNotificationsWithConversationChangeNotification:conversationChangeNotifications connectionChangedNotifications:connectionChangeNotifications];
        
        [ZMNotificationDispatcher notifyConversationWindowChangeTokensWithUpdatedMessages:self.updatedMessages];
        
        return [self combineArrays:@[voiceChannelChangeNotifications,
                                     userChangeNotifications,
                                     messageChangeNotifications,
                                     conversationChangeNotifications,
                                     connectionChangeNotifications,
                                     newUnreadMessagesNotifications,
                                     updatedKnocksNotifications,
                                     conversationListChangeNotifications,
                                     ]];
        
    }];
}


- (NSArray *)combineArrays:(NSArray *)arrays {
    NSArray *accum = @[];
    
    for (NSArray *array in arrays) {
        accum = [accum arrayByAddingObjectsFromArray:array];
    }
    
    return accum;
    
}


- (void)calculateNotificationsFromChangeNotification:(NSNotification *)changeNotification withBlock:(NSArray *(^)())block;
{
    [self extractUpdatedObjectsFromChangeNotification:changeNotification];
    self.notificationsToFire = [NSMutableArray array];
    
    NSArray *newNotifications = block();
    
    for (NSNotification *note in newNotifications) {
        [self addNotification:note];
    }
    
    [self fireAllNotifications];
    
    self.updatedConversations = nil;
    self.updatedConnections = nil;
    self.updatedUsers = nil;
    self.updatedMessages = nil;
    self.updatedAndInsertedConnections = nil;
    self.updatedCallParticipants = nil;
    self.insertedCallParticipants = nil;
    self.insertedConversations = nil;
    self.removedConversations = nil;
    self.usersWithUpdatedDisplayNames = nil;
    self.insertedMessages = nil;
    
    NSManagedObjectContext *moc = changeNotification.object;
    [moc clearCustomSnapshotsWithObjectChangeNotification:changeNotification];
}

- (void)extractUpdatedObjectsFromChangeNotification:(NSNotification *)changeNotification;
{
    self.updatedConversations = [NSMutableSet setWithSet:[((NSSet *) changeNotification.userInfo[NSUpdatedObjectsKey]) objectsOfClass:ZMConversation.class]];
    [self.updatedConversations unionSet:[((NSSet *) changeNotification.userInfo[NSRefreshedObjectsKey]) objectsOfClass:ZMConversation.class]];
    
    self.updatedConnections = [NSMutableSet setWithSet:[((NSSet *) changeNotification.userInfo[NSUpdatedObjectsKey]) objectsOfClass:ZMConnection.class]];
    [self.updatedConnections unionSet:[((NSSet *) changeNotification.userInfo[NSRefreshedObjectsKey]) objectsOfClass:ZMConnection.class]];
    
    self.updatedUsers = [NSMutableSet setWithSet:[((NSSet *) changeNotification.userInfo[NSUpdatedObjectsKey]) objectsOfClass:ZMUser.class]];
    [self.updatedUsers unionSet:[((NSSet *) changeNotification.userInfo[NSRefreshedObjectsKey]) objectsOfClass:ZMUser.class]];
    
    self.updatedMessages = [NSMutableSet setWithSet:[((NSSet *) changeNotification.userInfo[NSUpdatedObjectsKey]) objectsOfClass:ZMMessage.class]];
    [self.updatedMessages unionSet:[((NSSet *) changeNotification.userInfo[NSRefreshedObjectsKey]) objectsOfClass:ZMMessage.class]];
    
    self.insertedMessages = [[((NSSet *) changeNotification.userInfo[NSInsertedObjectsKey]) objectsOfClass:ZMMessage.class] mutableCopy];
    
    self.updatedCallParticipants = [NSMutableSet set];
    self.updatedCallParticipants = [NSMutableSet setWithSet:[((NSSet *) changeNotification.userInfo[NSUpdatedObjectsKey]) objectsOfClass:ZMCallParticipant.class]];
    [self.updatedCallParticipants unionSet:[((NSSet *) changeNotification.userInfo[NSRefreshedObjectsKey]) objectsOfClass:ZMCallParticipant.class]];
    
    self.insertedCallParticipants = [[((NSSet *) changeNotification.userInfo[NSInsertedObjectsKey]) objectsOfClass:ZMCallParticipant.class] mutableCopy];
    self.insertedConversations = [((NSSet *) changeNotification.userInfo[NSInsertedObjectsKey]) objectsOfClass:ZMConversation.class];
    self.removedConversations = [((NSSet *) changeNotification.userInfo[NSDeletedObjectsKey]) objectsOfClass:ZMConversation.class];
    
    self.updatedAndInsertedConnections = [NSMutableSet setWithSet:[((NSSet *) changeNotification.userInfo[NSUpdatedObjectsKey]) objectsOfClass:ZMConnection.class]];
    [self.updatedAndInsertedConnections unionSet:[((NSSet *) changeNotification.userInfo[NSRefreshedObjectsKey]) objectsOfClass:ZMConnection.class]];
    [self.updatedAndInsertedConnections unionSet:[((NSSet *) changeNotification.userInfo[NSInsertedObjectsKey]) objectsOfClass:ZMConnection.class]];
    
    NSSet *insertedUsers =  [NSMutableSet setWithSet:[((NSSet *) changeNotification.userInfo[NSInsertedObjectsKey]) objectsOfClass:ZMUser.class]];
    NSSet *deletedUsers =  [NSMutableSet setWithSet:[((NSSet *) changeNotification.userInfo[NSDeletedObjectsKey]) objectsOfClass:ZMUser.class]];
    
    if (insertedUsers.count != 0 || deletedUsers.count != 0 || self.updatedUsers.count != 0) {
        self.usersWithUpdatedDisplayNames = [self.moc updateDisplayNameGeneratorWithInsertedUsers:insertedUsers  updatedUsers:self.updatedUsers deletedUsers:deletedUsers];
    }
}

- (void)fireAllNotifications;
{
    if (0 < self.notificationsToFire.count) {
        static int count;
        ZMLogInfo(@"%@ firing notifications (%d)", self.class, count++);
        for (NSNotification *note in self.notificationsToFire) {
            ZMLogInfo(@"    posting %@ (obj = %p)", note.name, note.object);
            [[NSNotificationCenter defaultCenter] postNotification:note];
        }
    }
    self.notificationsToFire = nil;
}

- (NSArray *)createConversationListChangeNotificationsWithConversationChangeNotification:(NSArray *)conversationNotifications
                                                          connectionChangedNotifications:(NSArray *)connectionNotifications;
{
    // These are "special" hooks for the ZMConversationList:
    
    NSSet * const allUpdatedConversationKeys = [self allUpdatedConversationKeys];
    NSSet * const allUpdatedConnectionsKeys = [self allUpdatedConnectionKeys];
    BOOL const insertedOrRemovedConversations = 0 < (self.insertedConversations.count + self.removedConversations.count);
    
    ZMLogDebug(@"allUpdatedConversationKeys: %@", [allUpdatedConversationKeys.allObjects componentsJoinedByString:@", "]);
    ZMLogDebug(@"allUpdatedConnectionsKeys: %@", [allUpdatedConnectionsKeys.allObjects componentsJoinedByString:@", "]);
    
    NSMutableArray *notifications = [NSMutableArray array];
    
    for (ZMConversationList *list in self.moc.allConversationLists) {
        BOOL const refetch = (insertedOrRemovedConversations ||
                              [list predicateIsAffectedByConversationKeys:allUpdatedConversationKeys connectionKeys:allUpdatedConnectionsKeys]);
        BOOL const resort = (refetch ||
                             [list sortingIsAffectedByConversationKeys:allUpdatedConversationKeys]);
        ZMConversationListRefresh const refreshType = (refetch ?
                                                       ZMConversationListRefreshByRefetching :
                                                       (resort ?
                                                        ZMConversationListRefreshByResorting :
                                                        ZMConversationListRefreshItemsInPlace));
        
        ZMLogDebug(@"ZMConversationListChangeNotification refresh type “%@” for %p", ZMConversationListRefreshName(refreshType), list);
        ZMConversationListChangeNotification *note = [ZMConversationListChangeNotification notificationForList:list
                                                                               conversationChangeNotifications:conversationNotifications
                                                                                 connectionChangeNotifications:connectionNotifications
                                                                                                   refreshType:refreshType];
        if (note != nil) {
            [notifications addObject:note];
        }
    }
    return notifications;
}


/// Keys that have changed in any conversation:
- (NSSet *)allUpdatedConversationKeys;
{
    NSMutableSet *allKeys = [NSMutableSet set];
    for (ZMConversation *conversation in self.updatedConversations) {
        [allKeys unionSet:[conversation updatedKeysForChangeNotification]];
    }
    return allKeys;
}

- (NSSet *)allUpdatedConnectionKeys;
{
    NSMutableSet *allKeys = [NSMutableSet set];
    for (ZMConnection *connection in self.updatedConnections) {
        [allKeys unionSet:[connection updatedKeysForChangeNotification]];
    }
    return allKeys;
}

- (void)addNotification:(NSNotification *)note;
{
    if (note != nil) {
        [self.notificationsToFire addObject:note];
    }
}

- (void)addNotificationWithTopPriority:(NSNotification *)note;
{
    if (note != nil) {
        [self.notificationsToFire insertObject:note atIndex:0];
    }
}

- (ZMNotification *)createActiveVoiceChannelNotificationWithPreviousActiveVoiceChannelConversation:(ZMConversation *)previousActiveVoiceChannelConversation
{
    NSSet * const allUpdatedConversationKeys = [self allUpdatedConversationKeys];
    NSSet * const keysOfInterest = [NSSet setWithObjects:ZMConversationCallDeviceIsActiveKey, ZMConversationFlowManagerCategoryKey, nil];
    
    if ((self.updatedCallParticipants.count == 0) &&
        (self.insertedCallParticipants.count == 0) &&
        ! [allUpdatedConversationKeys intersectsSet:keysOfInterest])
    {
        return nil;
    }
    
    // active channel
    ZMVoiceChannel *activeVoiceChannel = [ZMVoiceChannel activeVoiceChannelInManagedObjectContext:self.moc];
    ZMConversation *strongConversation = activeVoiceChannel.conversation;
    
    if(strongConversation == previousActiveVoiceChannelConversation) {
        return nil;
    }
    
    ZMVoiceChannelActiveChannelChangedNotification *activeChannelNotification = [ZMVoiceChannelActiveChannelChangedNotification notificationWithActiveVoiceChannel:activeVoiceChannel];
    activeChannelNotification.currentActiveVoiceChannel = activeVoiceChannel;
    activeChannelNotification.previousActiveVoiceChannel = previousActiveVoiceChannelConversation.voiceChannel;
    
    return activeChannelNotification;
}

- (NSArray *)createNewUnreadMessagesNotification {
    
    NSMutableArray *newUnreadMessages = [NSMutableArray array];
    NSMutableArray *newUnreadKnocks = [NSMutableArray array];
    
    for(ZMMessage *msg in self.insertedMessages) {
        if(msg.conversation.lastReadEventID != nil && msg.eventID != nil && [msg.eventID compare:msg.conversation.lastReadEventID] == NSOrderedDescending) {
            if ([msg isKindOfClass:[ZMKnockMessage class]]) {
                [newUnreadKnocks addObject:msg];;
            }
            else {
                [newUnreadMessages addObject:msg];
            }
        }
    }
    
    NSMutableArray *notifications = [NSMutableArray array];
    if (newUnreadMessages.count > 0) {
        ZMNewUnreadMessagesNotification *messageNote = [ZMNewUnreadMessagesNotification notificationWithMessages:newUnreadMessages];
        if (messageNote != nil) {
            [notifications addObject:messageNote];
        }
    }
    if (newUnreadKnocks.count > 0) {
        ZMNewUnreadKnocksNotification *knockNote = [ZMNewUnreadKnocksNotification notificationWithKnockMessages:newUnreadKnocks];
        if (knockNote != nil) {
            [notifications addObject:knockNote];
        }
    }
    
    return notifications;
}

- (NSArray *)createVoiceChannelChangeNotificationsWithPreviousActiveVoiceChannelConversation:(ZMConversation *)previousActiveVoiceChannelConversation;
{
    NSMutableSet *conversations = [self.updatedConversations mutableCopy];
    [conversations unionSet:self.conversationsWithChangesForCallParticipants];
    
    NSMutableArray *notifications = [NSMutableArray array];
    for (ZMConversation *conversation in conversations) {
        ZMVoiceChannelStateChangedNotification *channelNotification = [ZMVoiceChannelStateChangedNotification notificationWithConversation:conversation insertedParticipants:self.insertedCallParticipants];
        if (channelNotification != nil) {
            [notifications addObject:channelNotification];
        }
        
        for(ZMCallParticipant *participant in conversation.mutableCallParticipants) {
            
            BOOL isInserted = [self.insertedCallParticipants containsObject:participant];
            ZMVoiceChannelParticipantStateChangedNotification *participantNotification =
            [ZMVoiceChannelParticipantStateChangedNotification notificationWithConversation:conversation callParticipant:participant isInserted:isInserted];
            if(participantNotification != nil) {
                [notifications addObject:participantNotification];
            }
        }
    }
    
    ZMNotification *activeChannelNotification = [self createActiveVoiceChannelNotificationWithPreviousActiveVoiceChannelConversation:previousActiveVoiceChannelConversation];
    if(activeChannelNotification != nil) {
        [notifications addObject:activeChannelNotification];
    }
    
    return notifications;
}

- (NSSet *)conversationsWithChangesForCallParticipants;
{
    NSMutableSet *conversations = [NSMutableSet set];
    
    for (ZMCallParticipant *participant in self.updatedCallParticipants) {
        if ([participant.updatedKeysForChangeNotification containsObject:ZMCallParticipantIsJoinedKey]) {
            [conversations addObject:participant.conversation];
        }
    }
    
    for (ZMCallParticipant *participant in self.insertedCallParticipants) {
        [conversations addObject:participant.conversation];
    }
    return conversations;
}

- (NSArray *)createMessagesChangeNotificationWithUserChangeNotifications:(NSArray *)userChangeNotifications;
{
    NSMutableArray *notifications = [NSMutableArray array];
    [self.updatedMessages unionSet:[self messagesWithChangedSendersForUserChangeNotifications:userChangeNotifications]];
    
    for (ZMMessage *message in self.updatedMessages) {
        ZMMessageChangeNotification *notification = [ZMMessageChangeNotification notificationWithMessage:message userChangeNotifications:userChangeNotifications];
        
        if (notification) {
            [notifications addObject:notification];
        }
    }
    return notifications;
}

- (NSArray *)createNewUnreadKnocksNotificationsForUpdatedKnocks
{
    NSMutableArray *updatedKnocks = [NSMutableArray array];
    
    for (ZMMessage *message in self.updatedMessages) {
        if (![message isKindOfClass:[ZMKnockMessage class]]){
            continue;
        }
        if ((message.conversation.lastReadEventID != nil && message.eventID != nil) &&
            [message.eventID compare:message.conversation.lastReadEventID] == NSOrderedDescending){
            [updatedKnocks addObject:message];
        }
    }
    
    ZMNewUnreadKnocksNotification *note;
    if (updatedKnocks.count != 0u) {
        note = [ZMNewUnreadKnocksNotification notificationWithKnockMessages:updatedKnocks];
    }
    if (note == nil) {
        return @[];
    }
    
    return @[note];
}

- (NSMutableSet *)messagesWithChangedSendersForUserChangeNotifications:(NSArray *)userChangeNotifications;
{
    NSMutableSet *messages = [NSMutableSet set];
    for (ZMUserChangeNotification *note in userChangeNotifications) {
        // For performance, we'll have to put some logic here.
        
        if (! (note.mediumProfileImageChanged || note.smallProfileImageChanged || note.nameChanged || note.accentChanged)) {
            continue;
        }
        for (ZMMessage *message in self.moc.registeredObjects) {
            if (! [message isKindOfClass:[ZMMessage class]]) {
                continue;
            }
            if (message.sender == note.user) {
                [messages addObject:message];
            }
        }
    }
    return messages;
}

- (NSArray *)createConversationChangeNotificationsWithUserChangeNotifications:(NSArray *)userChangeNotifications
                                                   messageChangeNotifications:(NSArray *)messageChangeNotifications;
{
    NSMutableArray *notifications = [NSMutableArray array];
    
    NSMutableSet *conversationsWithChangedMessages = [NSMutableSet set];
    for(ZMMessageChangeNotification *note in messageChangeNotifications) {
        if(note.message.conversation != nil) {
            [conversationsWithChangedMessages addObject:note.message.conversation];
        }
    }
    NSMutableSet *conversationsWithInsertedMessages = [NSMutableSet set];
    for (ZMMessage *insertedMessage in self.insertedMessages) {
        if (insertedMessage.conversation != nil) {
            [conversationsWithInsertedMessages addObject:insertedMessage.conversation];
        }
    }
    
    [self.updatedConversations unionSet:[self conversationsWithChangedUsers:userChangeNotifications]];
    [self.updatedConversations unionSet:conversationsWithChangedMessages];
    
    for (ZMConversation *conversation in self.updatedConversations) {
        BOOL const hasUpdatedMessages = [conversationsWithChangedMessages containsObject:conversation];
        BOOL const hasInsertedMessages = [conversationsWithInsertedMessages containsObject:conversation];
        ZMConversationChangeNotification *notification = [ZMConversationChangeNotification notificationWithConversation:conversation userChangeNotifications:userChangeNotifications hasUpdatedMessages:hasUpdatedMessages hasInsertedMessages:hasInsertedMessages];
        if (notification != nil) {
            [notifications addObject:notification];
        }
    }
    return notifications;
}

- (NSMutableSet *)conversationsWithChangedUsers:(NSArray *)userChangeNotifications;
{
    NSMutableSet *conversations = [NSMutableSet set];
    for (ZMUserChangeNotification *note in userChangeNotifications) {
        if(note.completeUser != nil) {
            [conversations unionSet:note.completeUser.activeConversations];
            ZMConversation *oneOnOneConversation = note.completeUser.connection.conversation;
            if (oneOnOneConversation != nil) {
                [conversations addObject:oneOnOneConversation];
            }
        }
    }
    return conversations;
}


- (NSArray *)createUserChangeNotification
{
    NSMutableArray *notifications = [NSMutableArray array];
    
    for (NSManagedObjectID *objectID in self.usersWithUpdatedDisplayNames){
        ZMUser *user = (ZMUser *)[self.moc objectWithID:objectID];
        if ([self.updatedUsers containsObject:user]) {
            [self.updatedUsers removeObject:user];
        }
        ZMUserChangeNotification *note = [ZMUserChangeNotification notificationWithUser:user displayNameChanged:YES];
        if (note) {
            [notifications addObject:note];
        }
    }
    
    for (ZMUser *user in self.updatedUsers) {
        ZMUserChangeNotification *note = [ZMUserChangeNotification notificationWithUser:user displayNameChanged:NO];
        if (note) {
            [notifications addObject:note];
        }
        
    }
    return notifications;
}

- (NSArray *)createConnectionChangeNotification
{
    NSMutableArray *notifications = [NSMutableArray array];
    
    for (ZMConnection *connection in self.updatedAndInsertedConnections) {
        if (connection.updatedKeysForChangeNotification.count == 0) {
            // We shouldn't spam the UI if nothing appears to have changed.
            continue;
        }
        if (connection.to != nil) {
            NSNotification *userNote = [ZMUserChangeNotification notificationForChangedConnectionToUser:connection.to];
            if (userNote) {
                [notifications addObject:userNote];
            }
            
            ZMConversationChangeNotification *connectionNote = [ZMConversationChangeNotification notificationForUpdatedConnectionInConversation:connection.conversation];
            if (connectionNote) {
                [notifications addObject:connectionNote];
            }
        }
    }
    return notifications;
}



@end
