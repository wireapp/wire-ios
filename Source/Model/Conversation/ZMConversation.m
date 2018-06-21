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


@import Foundation;
@import WireImages;
@import WireUtilities;
@import WireTransport;
@import WireCryptobox;
@import MobileCoreServices;
@import WireImages;

#import "ZMManagedObject+Internal.h"
#import "ZMManagedObjectContextProvider.h"
#import "ZMConversation+Internal.h"
#import "ZMConversation+Timestamps.h"
#import "ZMConversation+UnreadCount.h"

#import "ZMUser+Internal.h"

#import "ZMMessage+Internal.h"
#import "ZMClientMessage.h"

#import "NSManagedObjectContext+zmessaging.h"
#import "ZMConnection+Internal.h"

#import "ZMConversationList+Internal.h"

#import "ZMConversationListDirectory.h"
#import <WireDataModel/WireDataModel-Swift.h>
#import "NSPredicate+ZMSearch.h"

static NSString* ZMLogTag ZM_UNUSED = @"Conversations";

NSString *const ZMConversationConnectionKey = @"connection";
NSString *const ZMConversationHasUnreadMissedCallKey = @"hasUnreadMissedCall";
NSString *const ZMConversationHasUnreadUnsentMessageKey = @"hasUnreadUnsentMessage";
NSString *const ZMConversationIsArchivedKey = @"internalIsArchived";
NSString *const ZMConversationIsSelfAnActiveMemberKey = @"isSelfAnActiveMember";
NSString *const ZMConversationIsSilencedKey = @"isSilenced";
NSString *const ZMConversationMessagesKey = @"messages";
NSString *const ZMConversationHiddenMessagesKey = @"hiddenMessages";
NSString *const ZMConversationLastServerSyncedActiveParticipantsKey = @"lastServerSyncedActiveParticipants";
NSString *const ZMConversationHasUnreadKnock = @"hasUnreadKnock";
NSString *const ZMConversationUserDefinedNameKey = @"userDefinedName";
NSString *const ZMIsDimmedKey = @"zmIsDimmed";
NSString *const ZMNormalizedUserDefinedNameKey = @"normalizedUserDefinedName";
NSString *const ZMConversationListIndicatorKey = @"conversationListIndicator";
NSString *const ZMConversationConversationTypeKey = @"conversationType";
NSString *const ZMConversationLastServerTimeStampKey = @"lastServerTimeStamp";
NSString *const ZMConversationLastReadServerTimeStampKey = @"lastReadServerTimeStamp";
NSString *const ZMConversationClearedTimeStampKey = @"clearedTimeStamp";
NSString *const ZMConversationArchivedChangedTimeStampKey = @"archivedChangedTimestamp";
NSString *const ZMConversationSilencedChangedTimeStampKey = @"silencedChangedTimestamp";

NSString *const ZMNotificationConversationKey = @"ZMNotificationConversationKey";

NSString *const ZMConversationEstimatedUnreadCountKey = @"estimatedUnreadCount";
NSString *const ZMConversationRemoteIdentifierDataKey = @"remoteIdentifier_data";

NSString *const SecurityLevelKey = @"securityLevel";

static NSString *const ConnectedUserKey = @"connectedUser";
static NSString *const CreatorKey = @"creator";
static NSString *const DraftMessageTextKey = @"draftMessageText";
static NSString *const IsPendingConnectionConversationKey = @"isPendingConnectionConversation";
static NSString *const LastModifiedDateKey = @"lastModifiedDate";
static NSString *const LastReadMessageKey = @"lastReadMessage";
static NSString *const lastEditableMessageKey = @"lastEditableMessage";
static NSString *const NeedsToBeUpdatedFromBackendKey = @"needsToBeUpdatedFromBackend";
static NSString *const RemoteIdentifierKey = @"remoteIdentifier";
static NSString *const TeamRemoteIdentifierKey = @"teamRemoteIdentifier";
static NSString *const TeamRemoteIdentifierDataKey = @"teamRemoteIdentifier_data";
static NSString *const VoiceChannelKey = @"voiceChannel";
static NSString *const VoiceChannelStateKey = @"voiceChannelState";

static NSString *const LocalMessageDestructionTimeoutKey = @"localMessageDestructionTimeout";
static NSString *const SyncedMessageDestructionTimeoutKey = @"syncedMessageDestructionTimeout";


static NSString *const DownloadedMessageIDsDataKey = @"downloadedMessageIDs_data";
static NSString *const LastEventIDDataKey = @"lastEventID_data";
static NSString *const ClearedEventIDDataKey = @"clearedEventID_data";
static NSString *const ArchivedEventIDDataKey = @"archivedEventID_data";
static NSString *const LastReadEventIDDataKey = @"lastReadEventID_data";

static NSString *const TeamKey = @"team";

static NSString *const AccessModeStringsKey = @"accessModeStrings";
static NSString *const AccessRoleStringKey = @"accessRoleString";

NSTimeInterval ZMConversationDefaultLastReadTimestampSaveDelay = 3.0;

const NSUInteger ZMConversationMaxEncodedTextMessageLength = 1500;
const NSUInteger ZMConversationMaxTextMessageLength = ZMConversationMaxEncodedTextMessageLength - 50; // Empirically we verified that the encoding adds 44 bytes

@interface ZMConversation ()

@property (nonatomic) NSString *normalizedUserDefinedName;
@property (nonatomic) ZMConversationType conversationType;
@property (nonatomic, readonly) ZMConversationType internalConversationType;

@property (nonatomic) NSDate *tempMaxLastReadServerTimeStamp;
@property (nonatomic) NSMutableOrderedSet *unreadTimeStamps;

@property (nonatomic) NSTimeInterval lastReadTimestampSaveDelay;
@property (nonatomic) int64_t lastReadTimestampUpdateCounter;
@property (nonatomic) BOOL internalIsArchived;

@property (nonatomic) NSDate *lastReadServerTimeStamp;
@property (nonatomic) NSDate *lastServerTimeStamp;
@property (nonatomic) NSDate *clearedTimeStamp;
@property (nonatomic) NSDate *archivedChangedTimestamp;
@property (nonatomic) NSDate *silencedChangedTimestamp;

@end

/// Declaration of properties implemented (automatically) by Core Data
@interface ZMConversation (CoreDataForward)

@property (nonatomic) NSDate *primitiveLastReadServerTimeStamp;
@property (nonatomic) NSDate *primitiveLastServerTimeStamp;
@property (nonatomic) NSUUID *primitiveRemoteIdentifier;
@property (nonatomic) NSNumber *primitiveConversationType;
@property (nonatomic) NSData *remoteIdentifier_data;

@property (nonatomic) ZMConversationSecurityLevel securityLevel;
@end


@implementation ZMConversation

@dynamic userDefinedName;
@dynamic messages;
@dynamic lastModifiedDate;
@dynamic creator;
@dynamic draftMessageText;
@dynamic normalizedUserDefinedName;
@dynamic conversationType;
@dynamic clearedTimeStamp;
@dynamic lastReadServerTimeStamp;
@dynamic lastServerTimeStamp;
@dynamic isSilenced;
@dynamic isMuted;
@dynamic internalIsArchived;
@dynamic archivedChangedTimestamp;
@dynamic silencedChangedTimestamp;
@dynamic team;

@synthesize tempMaxLastReadServerTimeStamp;
@synthesize lastReadTimestampSaveDelay;
@synthesize lastReadTimestampUpdateCounter;
@synthesize unreadTimeStamps;

- (BOOL)isArchived
{
    return self.internalIsArchived;
}

- (void)setIsArchived:(BOOL)isArchived
{
    self.internalIsArchived = isArchived;
    [self updateArchivedChangedTimeStampIfNeeded:self.lastServerTimeStamp andSync:YES];
}

- (NSUInteger)estimatedUnreadCount
{
    return (unsigned long)self.internalEstimatedUnreadCount;
}

+ (NSSet *)keyPathsForValuesAffectingEstimatedUnreadCount
{
    return [NSSet setWithObjects: ZMConversationInternalEstimatedUnreadCountKey, ZMConversationLastReadServerTimeStampKey, nil];
}

- (void)setIsSilenced:(BOOL)isSilenced
{
    [self willChangeValueForKey:ZMConversationIsSilencedKey];
    [self setPrimitiveValue:@(isSilenced) forKey:ZMConversationIsSilencedKey];
    [self didChangeValueForKey:ZMConversationIsSilencedKey];
    
    if (self.managedObjectContext.zm_isUserInterfaceContext) {
        [self updateSilencedChangedTimeStampIfNeeded:self.lastServerTimeStamp andSync:YES];
    }
}

+ (NSSet *)keyPathsForValuesAffectingIsSilenced
{
    return [NSSet setWithObject:ZMConversationIsSilencedKey];
}

+ (NSFetchRequest *)sortedFetchRequest
{
    NSFetchRequest *request = [super sortedFetchRequest];

    if(request.predicate) {
        request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[request.predicate, self.predicateForFilteringResults]];
    }
    else {
        request.predicate = self.predicateForFilteringResults;
    }
    return request;
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeInsertedUpstream;
{
    NSPredicate *superPredicate = [super predicateForObjectsThatNeedToBeInsertedUpstream];
    NSPredicate *onlyGoupPredicate = [NSPredicate predicateWithFormat:@"%K == %@", ZMConversationConversationTypeKey, @(ZMConversationTypeGroup)];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[superPredicate, onlyGoupPredicate]];
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeUpdatedUpstream;
{
    NSPredicate *superPredicate = [super predicateForObjectsThatNeedToBeUpdatedUpstream];
    NSPredicate *onlyGoupPredicate = [NSPredicate predicateWithFormat:@"(%K != NULL) AND (%K != %@) AND (%K == 0)",
                                      [self remoteIdentifierDataKey],
                                      ZMConversationConversationTypeKey, @(ZMConversationTypeInvalid),
                                      NeedsToBeUpdatedFromBackendKey];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[superPredicate, onlyGoupPredicate]];
}

- (void)awakeFromFetch;
{
    [super awakeFromFetch];
    self.lastReadTimestampSaveDelay = ZMConversationDefaultLastReadTimestampSaveDelay;
    if (self.managedObjectContext.zm_isSyncContext) {
        // From the documentation: The managed object context’s change processing is explicitly disabled around this method so that you can use public setters to establish transient values and other caches without dirtying the object or its context.
        // Therefore we need to do a dispatch async  here in a performGroupedBlock to update the unread properties outside of awakeFromFetch
        ZM_WEAK(self);
        [self.managedObjectContext performGroupedBlock:^{
            ZM_STRONG(self);
            [self didUpdateConversationWhileFetchingUnreadMessages];
        }];
    }
}

- (void)awakeFromInsert;
{
    [super awakeFromInsert];
    self.lastReadTimestampSaveDelay = ZMConversationDefaultLastReadTimestampSaveDelay;
    if (self.managedObjectContext.zm_isSyncContext) {
        // From the documentation: You are typically discouraged from performing fetches within an implementation of awakeFromInsert. Although it is allowed, execution of the fetch request can trigger the sending of internal Core Data notifications which may have unwanted side-effects. Since we fetch the unread messages here, we should do a dispatch async
        [self.managedObjectContext performGroupedBlock:^{
            [self didUpdateConversationWhileFetchingUnreadMessages];
        }];
    }
}


-(NSOrderedSet *)activeParticipants
{
    NSMutableOrderedSet *activeParticipants = [NSMutableOrderedSet orderedSet];
    
    if (self.internalConversationType != ZMConversationTypeGroup) {
        [activeParticipants addObject:[ZMUser selfUserInContext:self.managedObjectContext]];
        if (self.connectedUser != nil) {
            [activeParticipants addObject:self.connectedUser];
        }
    }
    else if(self.isSelfAnActiveMember) {
        [activeParticipants addObject:[ZMUser selfUserInContext:self.managedObjectContext]];
        [activeParticipants unionOrderedSet:self.lastServerSyncedActiveParticipants];
    }
    else
    {
        [activeParticipants unionOrderedSet:self.lastServerSyncedActiveParticipants];
    }
   
    NSArray *sortedParticipants = [self sortedUsers:activeParticipants];
    return [NSOrderedSet orderedSetWithArray:sortedParticipants];
}

- (NSArray *)sortedUsers:(NSOrderedSet *)users
{
    NSSortDescriptor *nameDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"normalizedName" ascending:YES];
    NSArray *sortedUser = [users sortedArrayUsingDescriptors:@[nameDescriptor]];
    
    return sortedUser;
}

+ (NSSet *)keyPathsForValuesAffectingActiveParticipants
{
    return [NSSet setWithObjects:ZMConversationLastServerSyncedActiveParticipantsKey, ZMConversationIsSelfAnActiveMemberKey, nil];
}

- (ZMUser *)connectedUser
{
    ZMConversationType internalConversationType = self.internalConversationType;
    
    if (internalConversationType == ZMConversationTypeOneOnOne || internalConversationType == ZMConversationTypeConnection) {
        return self.connection.to;
    }
    else if (self.conversationType == ZMConversationTypeOneOnOne) {
        return self.lastServerSyncedActiveParticipants.firstObject;
    }
    
    return nil;
}

+ (NSSet *)keyPathsForValuesAffectingConnectedUser
{
    return [NSSet setWithObject:ZMConversationConversationTypeKey];
}


- (ZMConnectionStatus)relatedConnectionState
{
    if(self.connection != nil) {
        return self.connection.status;
    }
    return ZMConnectionStatusInvalid;
}

+ (NSSet *)keyPathsForValuesAffectingRelatedConnectionState
{
    return [NSSet setWithObject:@"connection.status"];
}

- (NSSet *)ignoredKeys;
{
    static NSSet *ignoredKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSSet *keys = [super ignoredKeys];
        NSString * const KeysIgnoredForTrackingModifications[] = {
            ZMConversationConnectionKey,
            ZMConversationConversationTypeKey,
            CreatorKey,
            DraftMessageTextKey,
            LastModifiedDateKey,
            ZMNormalizedUserDefinedNameKey,
            ZMConversationLastServerSyncedActiveParticipantsKey,
            VoiceChannelKey,
            ZMConversationHasUnreadMissedCallKey,
            ZMConversationHasUnreadUnsentMessageKey,
            ZMConversationMessagesKey,
            ZMConversationHiddenMessagesKey,
            ZMConversationLastServerTimeStampKey,
            SecurityLevelKey,
            ZMConversationLastUnreadKnockDateKey,
            ZMConversationLastUnreadMissedCallDateKey,
            ZMConversationLastReadLocalTimestampKey,
            ZMConversationInternalEstimatedUnreadCountKey,
            ZMConversationIsArchivedKey,
            ZMConversationIsSilencedKey,
            LocalMessageDestructionTimeoutKey,
            SyncedMessageDestructionTimeoutKey,
            DownloadedMessageIDsDataKey,
            LastEventIDDataKey,
            ClearedEventIDDataKey,
            ArchivedEventIDDataKey,
            LastReadEventIDDataKey,
            TeamKey,
            TeamRemoteIdentifierKey,
            TeamRemoteIdentifierDataKey,
            AccessModeStringsKey,
            AccessRoleStringKey
        };
        
        NSSet *additionalKeys = [NSSet setWithObjects:KeysIgnoredForTrackingModifications count:(sizeof(KeysIgnoredForTrackingModifications) / sizeof(*KeysIgnoredForTrackingModifications))];
        ignoredKeys = [keys setByAddingObjectsFromSet:additionalKeys];
    });
    return ignoredKeys;
}

- (BOOL)isReadOnly
{
    return
    (self.conversationType == ZMConversationTypeInvalid) ||
    (self.conversationType == ZMConversationTypeSelf) ||
    (self.conversationType == ZMConversationTypeConnection) ||
    (self.conversationType == ZMConversationTypeGroup && !self.isSelfAnActiveMember);
}

+ (NSSet *)keyPathsForValuesAffectingIsReadOnly;
{
    return [NSSet setWithObjects:ZMConversationConversationTypeKey, ZMConversationIsSelfAnActiveMemberKey, nil];
}

+ (NSSet *)keyPathsForValuesAffectingDisplayName;
{
    return [NSSet setWithObjects:ZMConversationConversationTypeKey, ZMConversationLastServerSyncedActiveParticipantsKey, @"lastServerSyncedActiveParticipants.name", @"connection.to.name", @"connection.to.availability", ZMConversationUserDefinedNameKey, nil];
}

+ (nonnull instancetype)insertGroupConversationIntoUserSession:(nonnull id<ZMManagedObjectContextProvider> )session
                                              withParticipants:(nonnull NSArray<ZMUser *> *)participants
                                                        inTeam:(nullable Team *)team;
{

    return [self insertGroupConversationIntoUserSession:session withParticipants:participants name:nil inTeam:team];
}

+ (nonnull instancetype)insertGroupConversationIntoUserSession:(nonnull id<ZMManagedObjectContextProvider> )session
                                              withParticipants:(nonnull NSArray<ZMUser *> *)participants
                                                          name:(nullable NSString*)name
                                                        inTeam:(nullable Team *)team
{
    return [self insertGroupConversationIntoUserSession:session
                                       withParticipants:participants
                                                   name:name
                                                 inTeam:team
                                            allowGuests:YES];
}

+ (nonnull instancetype)insertGroupConversationIntoUserSession:(nonnull id<ZMManagedObjectContextProvider> )session
                                              withParticipants:(nonnull NSArray<ZMUser *> *)participants
                                                          name:(nullable NSString*)name
                                                        inTeam:(nullable Team *)team
                                                   allowGuests:(BOOL)allowGuests
{
    VerifyReturnNil(session != nil);
    return [self insertGroupConversationIntoManagedObjectContext:session.managedObjectContext
                                                withParticipants:participants
                                                            name:name
                                                          inTeam:team
                                                     allowGuests:allowGuests];
}

+ (instancetype)existingOneOnOneConversationWithUser:(ZMUser *)otherUser inUserSession:(id<ZMManagedObjectContextProvider>)session;
{
    NOT_USED(session);
    return otherUser.connection.conversation;
}

- (void)setClearedTimeStamp:(NSDate *)clearedTimeStamp
{
    [self willChangeValueForKey:ZMConversationClearedTimeStampKey];
    [self setPrimitiveValue:clearedTimeStamp forKey:ZMConversationClearedTimeStampKey];
    [self didChangeValueForKey:ZMConversationClearedTimeStampKey];
    if (self.managedObjectContext.zm_isSyncContext) {
        [self deleteOlderMessages];
    }
}

- (void)setLastReadServerTimeStamp:(NSDate *)lastReadServerTimeStamp
{
    [self willChangeValueForKey:ZMConversationLastReadServerTimeStampKey];
    [self setPrimitiveValue:lastReadServerTimeStamp forKey:ZMConversationLastReadServerTimeStampKey];
    [self didChangeValueForKey:ZMConversationLastReadServerTimeStampKey];
    
    if (self.managedObjectContext.zm_isSyncContext) {
        [self updateUnread];
    }
}

- (NSUUID *)remoteIdentifier;
{
    return [self transientUUIDForKey:RemoteIdentifierKey];
}

- (void)setRemoteIdentifier:(NSUUID *)remoteIdentifier;
{
    [self setTransientUUID:remoteIdentifier forKey:RemoteIdentifierKey];
}

- (NSUUID *)teamRemoteIdentifier;
{
    return [self transientUUIDForKey:TeamRemoteIdentifierKey];
}

- (void)setTeamRemoteIdentifier:(NSUUID *)teamRemoteIdentifier;
{
    [self setTransientUUID:teamRemoteIdentifier forKey:TeamRemoteIdentifierKey];
}


+ (NSSet *)keyPathsForValuesAffectingRemoteIdentifier
{
    return [NSSet setWithObject:ZMConversationRemoteIdentifierDataKey];
}

- (void)setUserDefinedName:(NSString *)aName {
    
    [self willChangeValueForKey:ZMConversationUserDefinedNameKey];
    [self setPrimitiveValue:[[aName copy] stringByRemovingExtremeCombiningCharacters] forKey:ZMConversationUserDefinedNameKey];
    [self didChangeValueForKey:ZMConversationUserDefinedNameKey];
    
    self.normalizedUserDefinedName = [self.userDefinedName normalizedString];
}

- (ZMConversationType)conversationType
{
    ZMConversationType conversationType = [self internalConversationType];
    
    // Exception: the group conversation is considered a 1-1 if:
    // 1. Belongs to the team.
    // 2. Has no name given.
    // 3. Conversation has only one other participant.
    // 4. This participant is not a service user (bot).
    if (conversationType == ZMConversationTypeGroup &&
        self.teamRemoteIdentifier != nil &&
        self.lastServerSyncedActiveParticipants.count == 1 &&
        !self.lastServerSyncedActiveParticipants.firstObject.isServiceUser &&
        self.userDefinedName.length == 0) {
        conversationType = ZMConversationTypeOneOnOne;
    }
    
    return conversationType;
}

- (ZMConversationType)internalConversationType
{
    [self willAccessValueForKey:ZMConversationConversationTypeKey];
    ZMConversationType conversationType =  (ZMConversationType)[[self primitiveConversationType] shortValue];
    [self didAccessValueForKey:ZMConversationConversationTypeKey];
    return conversationType;
}


+ (NSArray *)defaultSortDescriptors
{
    return @[[NSSortDescriptor sortDescriptorWithKey:ZMConversationIsArchivedKey ascending:YES],
             [NSSortDescriptor sortDescriptorWithKey:LastModifiedDateKey ascending:NO],
             [NSSortDescriptor sortDescriptorWithKey:ZMConversationRemoteIdentifierDataKey ascending:YES],];
}

- (void)setVisibleWindowFromMessage:(ZMMessage *)oldestMessage toMessage:(ZMMessage *)newestMessage;
{
    NSDate *oldestTimeStamp;
    NSDate *newestTimeStamp;
    
    if(oldestMessage) {
        oldestTimeStamp = oldestMessage.serverTimestamp;
    }
    if(newestMessage) {
        newestTimeStamp = newestMessage.serverTimestamp;
    }
    
    if (newestTimeStamp != nil && oldestTimeStamp != nil && [newestTimeStamp compare:oldestTimeStamp] == NSOrderedAscending) {
        ZMMessage *tempMsg = oldestMessage;
        oldestMessage = newestMessage;
        NOT_USED(oldestMessage);
        newestMessage = tempMsg;
    }

    [self updateLastReadServerTimeStampWithMessage:newestMessage];
    if (self.hasUnreadUnsentMessage) {
        self.hasUnreadUnsentMessage = NO;
    }
}

- (void)savePendingLastRead
{
    [self updateLastReadServerTimeStampIfNeededWithTimeStamp:self.tempMaxLastReadServerTimeStamp andSync:NO];
    self.tempMaxLastReadServerTimeStamp = nil;
    self.lastReadTimestampUpdateCounter = 0;
    [self.managedObjectContext enqueueDelayedSave];
}

- (void)updateLastReadServerTimeStampWithMessage:(ZMMessage *)message
{
    NSDate *timeStamp = message.serverTimestamp;
    if (message.systemMessageData.childMessages.count > 0) {
        timeStamp = [(ZMSystemMessage *)message.systemMessageData lastChildMessageDate];
    }
    BOOL senderIsSelfUser = message.sender.isSelfUser;
    BOOL isSystemMessage = [message isKindOfClass:[ZMSystemMessage class]];

    if( ! self.managedObjectContext.zm_isUserInterfaceContext ) {
        return;
    }
    
    if (timeStamp == nil) {
        return;
    }
    
    if (self.lastReadServerTimeStamp != nil  && [timeStamp compare:self.lastReadServerTimeStamp] == NSOrderedAscending) {
        return;
    }
    
    NSUInteger idx = [self.messages.array indexOfObjectIdenticalTo:message];
    if (idx == NSNotFound) {
        return;
    }
    
    if (idx+1  == self.messages.count) {
        timeStamp = self.lastServerTimeStamp;
    }
    else if (message.deliveryState != ZMDeliveryStateDelivered && message.deliveryState != ZMDeliveryStateSent) {
        if (idx == 0) {
            timeStamp = self.lastServerTimeStamp;
        }
        else {
            __block ZMMessage *lastDeliveredMessage;
            __block NSUInteger newIdx;
            [self.messages.array enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, idx)] options:NSEnumerationReverse usingBlock:^(ZMMessage *aMessage, NSUInteger anIdx, BOOL *stop) {
                if (aMessage.deliveryState == ZMDeliveryStateDelivered || aMessage.deliveryState == ZMDeliveryStateSent) {
                    lastDeliveredMessage = aMessage;
                    newIdx = anIdx;
                    *stop = YES;
                }
            }];
            if (lastDeliveredMessage == nil ||
                [lastDeliveredMessage.serverTimestamp compare:self.lastReadServerTimeStamp] == NSOrderedAscending)
            {
                return;
            }
            timeStamp = lastDeliveredMessage.serverTimestamp;
            senderIsSelfUser = lastDeliveredMessage.sender.isSelfUser;
            isSystemMessage = [lastDeliveredMessage isKindOfClass:[ZMSystemMessage class]];
        }
    }
    [self updateLastReadServerTimeStamp:timeStamp senderIsSelfUser:senderIsSelfUser messageIsSystemMessage:isSystemMessage];
}


- (void)updateLastReadServerTimeStamp:(NSDate *)serverTimeStamp senderIsSelfUser:(BOOL)senderIsSelfUser messageIsSystemMessage:(BOOL)messageIsSystemMessage
{
    if ((self.lastReadServerTimeStamp != nil) && ([serverTimeStamp compare:self.lastReadServerTimeStamp] == NSOrderedAscending)) {
        return;
    }
    
    if (self.tempMaxLastReadServerTimeStamp == nil || [self.tempMaxLastReadServerTimeStamp compare:serverTimeStamp] == NSOrderedAscending) {
        if (!senderIsSelfUser || messageIsSystemMessage) {
            self.tempMaxLastReadServerTimeStamp = serverTimeStamp;
        }
        else {
            // This code only gets executed when we insert a message on this device and immediately set the window before the message was updated from the BE
            // Since the message was created by the selfUser, we don't want to sync the lastRead
            // To stop syncing of previously stored values, we need to reset the tempMaxLastRead to 0
            self.tempMaxLastReadServerTimeStamp = nil;
            self.lastReadTimestampUpdateCounter = 0;
            return;
        }
    }
    
    if (self.managedObjectContext.zm_isUserInterfaceContext) {
        self.lastReadTimestampUpdateCounter++;
        int64_t currentCount = self.lastReadTimestampUpdateCounter;
        
        __block NSArray *groups = [self.managedObjectContext enterAllGroups];
        ZM_WEAK(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.lastReadTimestampSaveDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            ZM_STRONG(self);
            if (self == nil) {
                return;
            }
            if (currentCount != self.lastReadTimestampUpdateCounter) {
                [self.managedObjectContext leaveAllGroups:groups];
                return;
            }
            [self savePendingLastRead];
            [self.managedObjectContext leaveAllGroups:groups];
        });
    }
    else {
        [self updateLastReadServerTimeStampIfNeededWithTimeStamp:self.tempMaxLastReadServerTimeStamp andSync:NO];
    }
}



- (void)insertUnreadTimeStamp:(NSDate *)serverTimeStamp
{
    if (serverTimeStamp == nil) {
        return;
    }
    if ([(NSDate *)self.unreadTimeStamps.firstObject compare:serverTimeStamp] == NSOrderedDescending) {
        [self.unreadTimeStamps addObject:serverTimeStamp];
    }
    else if ([(NSDate *)self.unreadTimeStamps.lastObject compare:serverTimeStamp] == NSOrderedAscending) {
        [self.unreadTimeStamps insertObject:serverTimeStamp atIndex:0];
    }
    else {
        NSUInteger index = [self.unreadTimeStamps indexOfObjectPassingTest:^BOOL(NSDate *stamp, NSUInteger idx, BOOL *stop) {
            NOT_USED(idx);
            if ([stamp compare:serverTimeStamp] == NSOrderedAscending) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        [self.unreadTimeStamps insertObject:serverTimeStamp atIndex:index+1];
    }
}

- (id <ZMConversationMessage>)appendMessageWithText:(NSString *)text;
{
    return [self appendMessageWithText:text fetchLinkPreview:YES];
}

- (nullable id <ZMConversationMessage>)appendMessageWithText:(nullable NSString *)text fetchLinkPreview:(BOOL)fetchPreview;
{    
    VerifyReturnNil(![text zmHasOnlyWhitespaceCharacters]);
    VerifyReturnNil(text != nil);

    NSUUID *nonce = NSUUID.UUID;

    id <ZMConversationMessage> message = [self appendOTRMessageWithText:text nonce:nonce fetchLinkPreview:fetchPreview];

    [[[NotificationInContext alloc] initWithName:ZMConversation.clearTypingNotificationName
                                        context:self.managedObjectContext.notificationContext
                                         object:self
                                       userInfo:nil
     ] post];

    return message;
}

- (id<ZMConversationMessage>)appendMessageWithImageAtURL:(NSURL *)fileURL;
{
    VerifyReturnNil(fileURL != nil);
    if (! fileURL.isFileURL) {
        ZMLogWarn(@"Trying to add an image message, but the URL is not a file URL.");
        return nil;
    }
    NSError *error;
    // We specifically do not want the data to be mapped at this place, because the underlying file might go away before we're done using the data.
    NSData * const originalImageData = [NSData dataWithContentsOfURL:fileURL options:0 error:&error];
    VerifyReturnNil(originalImageData != nil);
    CGSize const originalSize = [ZMImagePreprocessor sizeOfPrerotatedImageAtURL:fileURL];
    VerifyReturnNil(! CGSizeEqualToSize(originalSize, CGSizeZero));
    return [self appendMessageWithOriginalImageData:originalImageData originalSize:originalSize];
}

- (id<ZMConversationMessage>)appendMessageWithImageData:(NSData *)imageData;
{
    imageData = [imageData copy];
    VerifyReturnNil(imageData != nil);
    CGSize const originalSize = [ZMImagePreprocessor sizeOfPrerotatedImageWithData:imageData];
    VerifyReturnNil(! CGSizeEqualToSize(originalSize, CGSizeZero));

    return [self appendMessageWithOriginalImageData:imageData originalSize:originalSize];
}

- (nullable id<ZMConversationMessage>)appendMessageWithFileMetadata:(nonnull ZMFileMetadata *)fileMetadata
{
    return [self appendOTRMessageWithFileMetadata:fileMetadata nonce:NSUUID.UUID];
}

- (nullable id<ZMConversationMessage>)appendMessageWithLocationData:(nonnull ZMLocationData *)locationData
{
    return [self appendOTRMessageWithLocationData:locationData nonce:NSUUID.UUID];
}

- (id<ZMConversationMessage>)appendMessageWithOriginalImageData:(NSData *)originalImageData originalSize:(CGSize __unused)originalSize;
{
    return [self appendOTRMessageWithImageData:originalImageData nonce:NSUUID.UUID];
}

- (id<ZMConversationMessage>)appendKnock;
{
    return [self appendOTRKnockMessageWithNonce:[NSUUID UUID]];
}

- (BOOL)isPendingConnectionConversation;
{
    return self.connection != nil && self.connection.status == ZMConnectionStatusPending;
}

+ (NSSet *)keyPathsForValuesAffectingIsPendingConnectionConversation
{
    return [NSSet setWithObjects:ZMConversationConnectionKey, @"connection.status", nil];
}

- (ZMConversationListIndicator)conversationListIndicator;
{
    if (self.connectedUser.isPendingApprovalByOtherUser) {
        return ZMConversationListIndicatorPending;
    }
    else if (self.isCallDeviceActive) {
        return ZMConversationListIndicatorActiveCall;
    }
    else if (self.isIgnoringCall) {
        return ZMConversationListIndicatorInactiveCall;        
    }
    
    return [self unreadListIndicator];
}

+ (NSSet *)keyPathsForValuesAffectingConversationListIndicator
{
    return [[ZMConversation keyPathsForValuesAffectingUnreadListIndicator] union:[NSSet setWithObject: @"voiceChannelState"]];
}


- (BOOL)hasDraftMessageText
{
    return (0 < self.draftMessageText.length);
}

+ (NSSet *)keyPathsForValuesAffectingHasDraftMessageText
{
    return [NSSet setWithObject:DraftMessageTextKey];
}

- (ZMMessage *)lastReadMessage;
{
    NSDate * const timeStamp = self.lastReadServerTimeStamp;
    if (timeStamp == nil ||
        self.messages.count == 0 ||
        [timeStamp compare:[self.messages.firstObject serverTimestamp]] == NSOrderedAscending
        )
    {
        return nil;
    }
    
    if ([timeStamp compare:[self.messages.lastObject serverTimestamp]] == NSOrderedDescending) {
        return [self lastReadMessageIfChildMessagesForMessage:self.messages.lastObject lastReadTimeStamp:timeStamp];
    }
    
    BOOL reverseSearch = NO;
    ZMMessage *aMessage = self.messages[self.messages.count/2];
    if ([aMessage.serverTimestamp compare:self.lastReadServerTimeStamp] == NSOrderedAscending) {
        reverseSearch = YES;
    }
    
    __block ZMMessage *result;
    __block NSDate *resultTimeStamp;
    [self.messages enumerateObjectsWithOptions:reverseSearch ? NSEnumerationReverse : 0
                                    usingBlock:^(ZMMessage *message, NSUInteger ZM_UNUSED idx, BOOL *stop) {
                                        NSDate *newTimeStamp = [message valueForKey:ZMMessageServerTimestampKey];
                                        
                                        if (newTimeStamp == nil) {
                                            ZMLogWarn(@"Conversation contains message without a timestamp, all messages should have a timestamp.");
                                        } else if ([timeStamp compare:newTimeStamp] == NSOrderedSame) {
                                            result = message;
                                            *stop = YES;
                                        } else if ([timeStamp compare:newTimeStamp] == NSOrderedAscending) {
                                            return;
                                        } else if (resultTimeStamp == nil) {
                                            resultTimeStamp = newTimeStamp;
                                            result = message;
                                        } else if ([resultTimeStamp compare:newTimeStamp] == NSOrderedAscending) {
                                            resultTimeStamp = newTimeStamp;
                                            result = message;
                                        }
                                    }];
    
    result = [self lastReadMessageIfChildMessagesForMessage:result lastReadTimeStamp:timeStamp];
    
    if (result != nil) {
        // Skip ahead if the message after the last read message should
        // not generate an unread dot
        
        NSUInteger nextMessageIndex = [self.messages indexOfObject:result] + 1;
        while (nextMessageIndex < self.messages.count) {
            ZMMessage *nextMessage = [self.messages objectAtIndex:nextMessageIndex];
            
            if (nextMessage.shouldGenerateUnreadCount) {
                break;
            }
            
            result = nextMessage;
            nextMessageIndex += 1;
        }
    }
    
    return result;
}

- (ZMMessage *)lastReadMessageIfChildMessagesForMessage:(ZMMessage *)message lastReadTimeStamp:(NSDate *)timeStamp
{
    if (!message.shouldGenerateUnreadCount) {
        return message;
    }
    
    NSDate *lastChildMessageDate = [(ZMSystemMessage *)message.systemMessageData lastChildMessageDate];
    if (lastChildMessageDate != nil && [lastChildMessageDate compare:timeStamp] == NSOrderedDescending) {
        // If the message has unread childMessages, we should return the previous message as the lastReadMessage
        NSUInteger idx = [self.messages indexOfObject:message];
        if (idx > 0) {
            return self.messages[idx-1];
        }
    }
    return message;
}

- (ZMMessage *)lastEditableMessage;
{
    __block ZMMessage *result;
    [self.messages enumerateObjectsWithOptions:NSEnumerationReverse
                                    usingBlock:^(ZMMessage *message, NSUInteger ZM_UNUSED idx, BOOL *stop) {
                                            if ([message isEditableMessage]) {
                                                result = message;
                                                *stop = YES;
                                            }
                                    }];
    return result;
}

+ (NSSet *)keyPathsForValuesAffectingLastReadMessage
{
    return [NSSet setWithObjects:ZMConversationMessagesKey, ZMConversationLastReadServerTimeStampKey, nil];
}

- (NSSet<NSString *> *)filterUpdatedLocallyModifiedKeys:(NSSet<NSString *> *)updatedKeys
{
    NSMutableSet *newKeys = [super filterUpdatedLocallyModifiedKeys:updatedKeys].mutableCopy;
    
    // Don't sync the conversation name if it was set before inserting the conversation
    // as it will already get synced when inserting the conversation on the backend.
    if (self.isInserted && nil != self.userDefinedName && [newKeys containsObject:ZMConversationUserDefinedNameKey]) {
        [newKeys removeObject:ZMConversationUserDefinedNameKey];
    }
    
    return newKeys;
}

- (NSMutableOrderedSet *)mutableLastServerSyncedActiveParticipants
{
    return [self mutableOrderedSetValueForKey:ZMConversationLastServerSyncedActiveParticipantsKey];
}

- (void)markAsRead
{
    if (self.messages.count == 0) {
        ZMLogError(@"No messages to mark as read in %@", self);
        return;
    }
    
    ZMMessage *lastMessage = self.messages.lastObject;
    if (lastMessage == nil) {
        return;
    }
    
    [self updateLastReadServerTimeStampIfNeededWithTimeStamp:lastMessage.serverTimestamp andSync:YES];
}

- (BOOL)canMarkAsUnread
{
    if (self.messages.count == 0) {
        return NO;
    }
    
    if (self.estimatedUnreadCount > 0) {
        return NO;
    }
    
    if (nil == [self lastMessageCanBeMarkedUnread]) {
        return NO;
    }
    
    return YES;
}

- (ZMMessage *)lastMessageCanBeMarkedUnread
{
    NSUInteger lastMessageIndexCanBeMarkedUnread = [self.messages.reversedOrderedSet indexOfObjectPassingTest:^BOOL(id<ZMConversationMessage> message, NSUInteger idx, BOOL *stop) {
        NOT_USED(idx);
        NOT_USED(stop);
        return message.canBeMarkedUnread;
    }];
    
    if (lastMessageIndexCanBeMarkedUnread != NSNotFound) {
        return self.messages[self.messages.count - lastMessageIndexCanBeMarkedUnread - 1];
    }
    else {
        return nil;
    }
}

- (void)markAsUnread
{
    ZMMessage *lastMessageCanBeMarkedUnread = [self lastMessageCanBeMarkedUnread];
    
    if (lastMessageCanBeMarkedUnread == nil) {
        ZMLogError(@"Cannot mark as read: no message to mark in %@", self);
        return;
    }
    
    [lastMessageCanBeMarkedUnread markAsUnread];
}

@end



@implementation ZMConversation (Internal)

@dynamic connection;
@dynamic creator;
@dynamic lastModifiedDate;
@dynamic normalizedUserDefinedName;
@dynamic hiddenMessages;

+ (NSSet *)keyPathsForValuesAffectingIsArchived
{
    return [NSSet setWithObject:ZMConversationIsArchivedKey];
}

+ (NSString *)entityName;
{
    return @"Conversation";
}

- (NSMutableOrderedSet *)mutableMessages;
{
    return [self mutableOrderedSetValueForKey:ZMConversationMessagesKey];
}

+ (ZMConversationList *)conversationsIncludingArchivedInContext:(NSManagedObjectContext *)moc;
{
    return moc.conversationListDirectory.conversationsIncludingArchived;
}

+ (ZMConversationList *)archivedConversationsInContext:(NSManagedObjectContext *)moc;
{
    return moc.conversationListDirectory.archivedConversations;
}

+ (ZMConversationList *)clearedConversationsInContext:(NSManagedObjectContext *)moc;
{
    return moc.conversationListDirectory.clearedConversations;
}

+ (ZMConversationList *)conversationsExcludingArchivedInContext:(NSManagedObjectContext *)moc;
{
    return moc.conversationListDirectory.unarchivedConversations;
}

+ (ZMConversationList *)pendingConversationsInContext:(NSManagedObjectContext *)moc;
{
    return moc.conversationListDirectory.pendingConnectionConversations;
}

- (void)sortMessages
{
    NSOrderedSet *sorted = [NSOrderedSet orderedSetWithArray:[self.messages sortedArrayUsingDescriptors:[ZMMessage defaultSortDescriptors]]];
    // Be sure not to "dirty" the relationship, unless we need to:
    if (! [self.messages isEqualToOrderedSet:sorted]) {
        [self setValue:sorted forKey:ZMConversationMessagesKey];
    }
    // sortMessages is called when processing downloaded events (e.g. after slow sync) which can be unordered
    // after sorting messages we also need to recalculate the unread properties
    [self didUpdateConversationWhileFetchingUnreadMessages];
}

- (void)resortMessagesWithUpdatedMessage:(ZMMessage *)message
{
    if (message.visibleInConversation == nil) {
        ZMLogWarn(@"Attempt to resort message not visible in conversation");
        return;
    }
    
    [self.mutableMessages removeObject:message];
    [self sortedAppendMessage:message];
    [self updateUnreadCountIfNeededForMessage:message];
}

- (void)updateUnreadCountIfNeededForMessage:(ZMMessage *)message
{
    BOOL senderIsNotSelf = (message.sender != [ZMUser selfUserInContext:self.managedObjectContext]);
    if (senderIsNotSelf && [message shouldGenerateUnreadCount]) {
        [self insertTimeStamp:message.serverTimestamp];
    }
}

- (void)mergeWithExistingConversationWithRemoteID:(NSUUID *)remoteID;
{
    ZMConversation *existingConversation = [ZMConversation conversationWithRemoteID:remoteID createIfNeeded:NO inContext:self.managedObjectContext];
    if ((existingConversation != nil) && ![existingConversation isEqual:self]) {
        Require(self.remoteIdentifier == nil);
        [self.mutableMessages addObjectsFromArray:existingConversation.messages.array];
        [self sortMessages];
        // Just to be on the safe side, force update:
        self.needsToBeUpdatedFromBackend = YES;
        // This is a duplicate. Delete the other one
        [self.managedObjectContext deleteObject:existingConversation];
    }
    self.remoteIdentifier = remoteID;
}

- (void)updateWithMessage:(ZMMessage *)message timeStamp:(NSDate *)timeStamp
{
    [self updateLastServerTimeStampIfNeeded:timeStamp];
    if (message.shouldUpdateLastModifiedDate) {
        [self updateLastModifiedDateIfNeeded:timeStamp];
    }
    [self updateUnreadMessagesWithMessage:message];
}

+ (instancetype)conversationWithRemoteID:(NSUUID *)UUID createIfNeeded:(BOOL)create inContext:(NSManagedObjectContext *)moc
{
    return [self conversationWithRemoteID:UUID createIfNeeded:create inContext:moc created:NULL];
}

+ (instancetype)conversationWithRemoteID:(NSUUID *)UUID createIfNeeded:(BOOL)create inContext:(NSManagedObjectContext *)moc created:(BOOL *)created
{
    VerifyReturnNil(UUID != nil);
    
    // We must only ever call this on the sync context. Otherwise, there's a race condition
    // where the UI and sync contexts could both insert the same conversation (same UUID) and we'd end up
    // having two duplicates of that conversation, and we'd have a really hard time recovering from that.
    //
    RequireString(! create || moc.zm_isSyncContext, "Race condition!");
    
    ZMConversation *result = [self fetchObjectWithRemoteIdentifier:UUID inManagedObjectContext:moc];
    
    if (result != nil) {
        if (nil != created) {
            *created = NO;
        }
        return result;
    } else if (create) {
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:moc];
        conversation.remoteIdentifier = UUID;
        conversation.lastModifiedDate = [NSDate dateWithTimeIntervalSince1970:0];
        conversation.lastServerTimeStamp = [NSDate dateWithTimeIntervalSince1970:0];
        if (nil != created) {
            *created = YES;
        }
        return conversation;
    }
    return nil;
}

+ (instancetype)fetchOrCreateTeamConversationInManagedObjectContext:(NSManagedObjectContext *)moc withParticipant:(ZMUser *)participant team:(Team *)team
{
    VerifyReturnNil(team != nil);
    VerifyReturnNil(!participant.isSelfUser);
    ZMUser *selfUser = [ZMUser selfUserInContext:moc];
    VerifyReturnNil(selfUser.canCreateConversation);

    ZMConversation *conversation = [self existingTeamConversationInManagedObjectContext:moc withParticipant:participant team:team];
    if (nil != conversation) {
        return conversation;
    }

    conversation = (ZMConversation *)[super insertNewObjectInManagedObjectContext:moc];
    conversation.lastModifiedDate = [NSDate date];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.creator = selfUser;
    conversation.team = team;

    [conversation internalAddParticipants:[NSSet setWithObject:participant]];

    // We need to check if we should add a 'secure' system message in case all participants are trusted
    [conversation increaseSecurityLevelIfNeededAfterTrustingClients:participant.clients];
    [conversation appendNewConversationSystemMessageIfNeeded];
    return conversation;
}

+ (instancetype)existingTeamConversationInManagedObjectContext:(NSManagedObjectContext *)moc withParticipant:(ZMUser *)participant team:(Team *)team
{
    // We consider a conversation being an existing 1:1 team conversation in case the following point are true:
    //  1. It is a conversation inside the team
    //  2. The only participants are the current user and the selected user
    //  3. It does not have a custom display name

    NSPredicate *sameTeam = [ZMConversation predicateForConversationsInTeam:team];
    NSPredicate *groupConversation = [NSPredicate predicateWithFormat:@"%K == %d", ZMConversationConversationTypeKey, ZMConversationTypeGroup];
    NSPredicate *noUserDefinedName = [NSPredicate predicateWithFormat:@"%K == NULL", ZMConversationUserDefinedNameKey];
    NSPredicate *sameParticipant = [NSPredicate predicateWithFormat:@"%K.@count == 1 AND %@ IN %K ", ZMConversationLastServerSyncedActiveParticipantsKey, participant, ZMConversationLastServerSyncedActiveParticipantsKey];
    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[sameTeam, groupConversation,noUserDefinedName, sameParticipant]];
    NSFetchRequest *request = [self sortedFetchRequestWithPredicate:compoundPredicate];
    return [moc executeFetchRequestOrAssert:request].firstObject;
}

+ (instancetype)insertGroupConversationIntoManagedObjectContext:(NSManagedObjectContext *)moc withParticipants:(NSArray *)participants
{
    return [self insertGroupConversationIntoManagedObjectContext:moc withParticipants:participants inTeam:nil];
}

+ (instancetype)insertGroupConversationIntoManagedObjectContext:(NSManagedObjectContext *)moc
                                               withParticipants:(NSArray *)participants
                                                         inTeam:(nullable Team *)team
{
    return [self insertGroupConversationIntoManagedObjectContext:moc
                                                withParticipants:participants
                                                            name:nil
                                                          inTeam:team];
}

+ (instancetype)insertGroupConversationIntoManagedObjectContext:(NSManagedObjectContext *)moc
                                               withParticipants:(NSArray *)participants
                                                           name:(NSString *)name
                                                         inTeam:(nullable Team *)team
{
    return [self insertGroupConversationIntoManagedObjectContext:moc
                                                withParticipants:participants
                                                            name:name
                                                          inTeam:team
                                                     allowGuests:YES];
}

+ (nullable instancetype)insertGroupConversationIntoManagedObjectContext:(nonnull NSManagedObjectContext *)moc
                                                        withParticipants:(nonnull NSArray <ZMUser *>*)participants
                                                                    name:(nullable NSString *)name
                                                                  inTeam:(nullable Team *)team
                                                             allowGuests:(BOOL)allowGuests
{
    ZMUser *selfUser = [ZMUser selfUserInContext:moc];

    if (nil != team && !selfUser.canCreateConversation) {
        return nil;
    }

    ZMConversation *conversation = (ZMConversation *)[super insertNewObjectInManagedObjectContext:moc];
    conversation.lastModifiedDate = [NSDate date];
    conversation.conversationType = ZMConversationTypeGroup;
    conversation.creator = selfUser;
    conversation.team = team;
    conversation.userDefinedName = name;
    if (nil != team) {
        conversation.allowGuests = allowGuests;
    }
    
    for (ZMUser *participant in participants) {
        Require([participant isKindOfClass:[ZMUser class]]);
        const BOOL isSelf = (participant == selfUser);
        RequireString(!isSelf, "Can't pass self user as a participant of a group conversation");
        if(!isSelf) {
            [conversation internalAddParticipants:[NSSet setWithObject:participant]];
        }
    }
    
    NSMutableSet *allClients = [NSMutableSet set];
    for (ZMUser *user in conversation.activeParticipants) {
        [allClients unionSet:user.clients];
    }
    
    // We need to check if we should add a 'secure' system message in case all participants are trusted
    [conversation increaseSecurityLevelIfNeededAfterTrustingClients:allClients];
    [conversation appendNewConversationSystemMessageIfNeeded];
    return conversation;
}

+ (NSPredicate *)predicateForSearchQuery:(NSString *)searchQuery team:(Team *)team
{
    NSPredicate *teamPredicate = [NSPredicate predicateWithFormat:@"(%K == %@)", TeamKey, team];
    
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[[self predicateForSearchQuery:searchQuery], teamPredicate]];
}

+ (nonnull NSPredicate *)predicateForSearchQuery:(nonnull NSString *)searchQuery
{
    NSDictionary *formatDict = @{ZMConversationLastServerSyncedActiveParticipantsKey : @"ANY %K.normalizedName MATCHES %@",
                                 ZMNormalizedUserDefinedNameKey: @"%K MATCHES %@"};
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormatDictionary:formatDict
                                                         matchingSearchString:searchQuery];
    NSPredicate *activeMemberPredicate = [NSPredicate predicateWithFormat:@"%K == NULL OR %K == YES",
                                          ZMConversationClearedTimeStampKey,
                                          ZMConversationIsSelfAnActiveMemberKey];
    
    NSPredicate *basePredicate = [NSPredicate predicateWithFormat:@"(%K == %@)",
                                  ZMConversationConversationTypeKey, @(ZMConversationTypeGroup)];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[searchPredicate, activeMemberPredicate, basePredicate]];
}

+ (NSPredicate *)userDefinedNamePredicateForSearchString:(NSString *)searchString;
{
    NSPredicate *predicate = [NSPredicate predicateWithFormatDictionary:@{ZMNormalizedUserDefinedNameKey: @"%K MATCHES %@"}
                                                   matchingSearchString:searchString];
    return predicate;
}


+ (NSUUID *)selfConversationIdentifierInContext:(NSManagedObjectContext *)context;
{
    // remoteID of self-conversation is guaranteed to be the same as remoteID of self-user
    ZMUser *selfUser = [ZMUser selfUserInContext:context];
    return selfUser.remoteIdentifier;
}

+ (ZMConversation *)selfConversationInContext:(NSManagedObjectContext *)managedObjectContext
{
    NSUUID *selfUserID = [ZMConversation selfConversationIdentifierInContext:managedObjectContext];
    return [ZMConversation conversationWithRemoteID:selfUserID createIfNeeded:NO inContext:managedObjectContext];
}

- (ZMClientMessage *)appendClientMessageWithGenericMessage:(ZMGenericMessage *)genericMessage
{
    return [self appendClientMessageWithGenericMessage:genericMessage expires:YES hidden:NO];
}

- (ZMClientMessage *)appendClientMessageWithGenericMessage:(ZMGenericMessage *)genericMessage expires:(BOOL)expires hidden:(BOOL)hidden
{
    VerifyReturnNil(genericMessage != nil);

    ZMClientMessage *message = [[ZMClientMessage alloc] initWithNonce:[NSUUID uuidWithTransportString:genericMessage.messageId]
                                                 managedObjectContext:self.managedObjectContext];
    [message addData:genericMessage.data];
    message.sender = [ZMUser selfUserInContext:self.managedObjectContext];
    
    if (expires) {
        [message setExpirationDate];
    }
    
    if(hidden) {
        message.hiddenInConversation = self;
    } else {
        [self sortedAppendMessage:message];
        [self unarchiveIfNeeded];
        [message updateCategoryCache];
        [message prepareToSend];
    }
    
    return message;
}

- (ZMAssetClientMessage *)appendAssetClientMessageWithNonce:(NSUUID *)nonce imageData:(NSData *)imageData
{
    ZMAssetClientMessage *message =
    [[ZMAssetClientMessage alloc] initWithOriginalImage:imageData
                                                  nonce:nonce
                                   managedObjectContext:self.managedObjectContext
                                           expiresAfter:self.messageDestructionTimeoutValue];

    message.sender = [ZMUser selfUserInContext:self.managedObjectContext];
    
    [self sortedAppendMessage:message];
    [self unarchiveIfNeeded];
    [self.managedObjectContext.zm_fileAssetCache storeAssetData:message format:ZMImageFormatOriginal encrypted:NO data:imageData];
    [message updateCategoryCache];
    [message prepareToSend];
    
    return message;
}

- (ZMAssetClientMessage *)appendOTRMessageWithFileMetadata:(ZMFileMetadata *)fileMetadata nonce:(NSUUID *)nonce
{
    NSData *data = [NSData dataWithContentsOfURL:fileMetadata.fileURL options:NSDataReadingMappedIfSafe error:nil];
    if (data == nil) {
        return nil;
    }
    
    ZMAssetClientMessage *message =
    [[ZMAssetClientMessage alloc] initWith:fileMetadata
                                     nonce:nonce
                      managedObjectContext:self.managedObjectContext
                              expiresAfter:self.messageDestructionTimeoutValue];

    message.sender = [ZMUser selfUserInContext:self.managedObjectContext];
    [self sortedAppendMessage:message];
    [self unarchiveIfNeeded];
    
    [self.managedObjectContext.zm_fileAssetCache storeAssetData:message encrypted:NO data:data];

    if (fileMetadata.thumbnail != nil) {
        [self.managedObjectContext.zm_fileAssetCache storeAssetData:message format:ZMImageFormatOriginal encrypted:NO data:fileMetadata.thumbnail];
    }
    
    [message updateCategoryCache];
    [message prepareToSend];
    
    return message;
}

- (ZMClientMessage *)appendOTRMessageWithLocationData:(ZMLocationData *)locationData nonce:(NSUUID *)nonce
{
    ZMGenericMessage *genericMessage = [ZMGenericMessage genericMessageWithLocation:locationData.zmLocation messageID:nonce expiresAfter:@(self.messageDestructionTimeoutValue)];
    ZMClientMessage *message = [self appendClientMessageWithGenericMessage:genericMessage];
    return message;
}

- (ZMClientMessage *)appendOTRKnockMessageWithNonce:(NSUUID *)nonce
{
    ZMGenericMessage *genericMessage = [ZMGenericMessage knockWithNonce:nonce expiresAfter:@(self.messageDestructionTimeoutValue)];
    ZMClientMessage *message = [self appendClientMessageWithGenericMessage:genericMessage];
    return message;
}

- (ZMClientMessage *)appendOTRMessageWithText:(NSString *)text nonce:(NSUUID *)nonce fetchLinkPreview:(BOOL)fetchPreview
{
    NSArray<ZMMention *> *mentions = [self mentionsInText:text];
    NSString *normalizedText = [self normalizeText:text forMentions:mentions];

    ZMGenericMessage *genericMessage = [ZMGenericMessage messageWithText:normalizedText.stringByRemovingExtremeCombiningCharacters
                                                             linkPreview:nil
                                                                   nonce:nonce
                                                            expiresAfter:@(self.messageDestructionTimeoutValue)
                                                                mentions: mentions];
    ZMClientMessage *message = [self appendClientMessageWithGenericMessage:genericMessage];
    message.linkPreviewState = fetchPreview ? ZMLinkPreviewStateWaitingToBeProcessed : ZMLinkPreviewStateDone;
    return message;
}

- (ZMClientMessage *)appendOTRMessageWithText:(NSString *)text nonce:(NSUUID *)nonce
{
    return [self appendOTRMessageWithText:text nonce:nonce fetchLinkPreview:YES];
}

- (ZMAssetClientMessage *)appendOTRMessageWithImageData:(NSData *)imageData nonce:(NSUUID *)nonce
{
    NSError *metadataError = nil;
    NSData *imageDataWithoutMetadata = [imageData wr_imageDataWithoutMetadataAndReturnError:&metadataError];
    
    if (metadataError != nil) {
        ZMLogError(@"Cannot remove image metadata: %@", metadataError);
    }
    if (imageDataWithoutMetadata == nil) {
        imageDataWithoutMetadata = imageData;
    }
    
    ZMAssetClientMessage *message = [self appendAssetClientMessageWithNonce:nonce imageData:imageDataWithoutMetadata];
    return message;
}

- (void)appendNewConversationSystemMessageIfNeeded;
{
    ZMMessage *firstMessage = self.messages.firstObject;
    if ([firstMessage isKindOfClass:[ZMSystemMessage class]]) {
        ZMSystemMessage *systemMessage = (ZMSystemMessage *)firstMessage;
        if (systemMessage.systemMessageType == ZMSystemMessageTypeNewConversation) {
            return;
        }
    }
    
    ZMSystemMessage *systemMessage = [[ZMSystemMessage alloc] initWithNonce:[NSUUID UUID] managedObjectContext:self.managedObjectContext];
    systemMessage.systemMessageType = ZMSystemMessageTypeNewConversation;
    systemMessage.sender = [ZMUser selfUserInContext:self.managedObjectContext];
    systemMessage.sender = self.creator;
    systemMessage.text = self.userDefinedName;
    systemMessage.users = self.activeParticipants.set;
    // the new conversation message should be displayed first,
    // additionally the use of reference date is to ensure proper transition for older clients so the message is the very
    // first message in conversation
    systemMessage.serverTimestamp = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
    
    [self sortedAppendMessage:systemMessage];
}

- (NSUInteger)sortedAppendMessage:(ZMMessage *)message;
{
    Require(message != nil);
    [message updateNormalizedText];

    // This is more efficient than adding to mutableMessages and re-sorting all of them.
    NSUInteger index = self.messages.count;
    ZMMessage * const currentLastMessage = self.messages.lastObject;
    Require(currentLastMessage != message);
    if (currentLastMessage == nil) {
        [self.mutableMessages addObject:message];
    } else {
        if ([currentLastMessage compare:message] == NSOrderedAscending) {
            [self.mutableMessages addObject:message];
        } else {
            NSUInteger idx = [self.messages.array indexOfObject:message inSortedRange:NSMakeRange(0, self.messages.count) options:NSBinarySearchingInsertionIndex | NSBinarySearchingLastEqual usingComparator:^(ZMMessage *msg1, ZMMessage *msg2) {
                return [msg1 compare:msg2];
            }];
            [self.mutableMessages insertObject:message atIndex:idx];
            index = idx;
        }
    }
    
    NSPredicate *localSystemMessagePredicate = [ZMSystemMessage predicateForSystemMessagesInsertedLocally];
    if ([message.serverTimestamp compare:self.lastModifiedDate] == NSOrderedDescending
       && ![localSystemMessagePredicate evaluateWithObject:message] && message.shouldUpdateLastModifiedDate) {
        self.lastModifiedDate = message.serverTimestamp;
    }
    
    return index;
}

- (void)unarchiveIfNeeded
{
    if (self.isArchived) {
        self.isArchived = NO;
    }
}

- (void)deleteOlderMessages
{
    if ( self.messages.count == 0 || self.clearedTimeStamp == nil) {
        return;
    }
    
    // If messages are not sorted beforehand, we might delete messages we were supposed to keep
    [self sortMessages];
    
    NSMutableArray *messagesToDelete = [NSMutableArray array];
    [self.messages enumerateObjectsUsingBlock:^(ZMSystemMessage *message, NSUInteger __unused idx, BOOL *stop) {
        NOT_USED(stop);
        // cleared event can be an invisible event that is not a message
        // therefore we should stop when we reach a message that is older than the clearedTimestamp
        if ([message.serverTimestamp compare:self.clearedTimeStamp] == NSOrderedDescending) {
            *stop = YES;
            return;
        }
        [messagesToDelete addObject:message];
    }];
    
    for (ZMMessage *message in messagesToDelete) {
        [self.managedObjectContext deleteObject:message];
    }
}

@end




@implementation ZMConversation (SelfConversation)

+ (ZMClientMessage *)appendSelfConversationWithGenericMessage:(ZMGenericMessage * )genericMessage managedObjectContext:(NSManagedObjectContext *)moc;
{
    VerifyReturnNil(genericMessage != nil);

    ZMConversation *selfConversation = [ZMConversation selfConversationInContext:moc];
    VerifyReturnNil(selfConversation != nil);
    
    ZMClientMessage *clientMessage = [selfConversation appendClientMessageWithGenericMessage:genericMessage expires:NO hidden:NO];
    return clientMessage;
}


+ (ZMClientMessage *)appendSelfConversationWithLastReadOfConversation:(ZMConversation *)conversation
{
    NSDate *lastRead = conversation.lastReadServerTimeStamp;
    NSUUID *convID = conversation.remoteIdentifier;
    if (convID == nil || lastRead == nil || [convID isEqual:[ZMConversation selfConversationIdentifierInContext:conversation.managedObjectContext]]) {
        return nil;
    }

    NSUUID *nonce = [NSUUID UUID];
    ZMGenericMessage *message = [ZMGenericMessage messageWithLastRead:lastRead ofConversationWithID:convID nonce:nonce];
    VerifyReturnNil(message != nil);
    
    return [self appendSelfConversationWithGenericMessage:message managedObjectContext:conversation.managedObjectContext];
}

+ (void)updateConversationWithZMLastReadFromSelfConversation:(ZMLastRead *)lastRead inContext:(NSManagedObjectContext *)context
{
    double newTimeStamp = lastRead.lastReadTimestamp;
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:(newTimeStamp/1000)];
    NSUUID *conversationID = [NSUUID uuidWithTransportString:lastRead.conversationId];
    if (conversationID == nil || timestamp == nil) {
        return;
    }
    
    ZMConversation *conversationToUpdate = [ZMConversation conversationWithRemoteID:conversationID createIfNeeded:YES inContext:context];
    [conversationToUpdate updateLastReadServerTimeStampIfNeededWithTimeStamp:timestamp andSync:NO];
}


+ (ZMClientMessage *)appendSelfConversationWithClearedOfConversation:(ZMConversation *)conversation
{
    NSUUID *convID = conversation.remoteIdentifier;
    NSDate *cleared = conversation.clearedTimeStamp;
    if (convID == nil || cleared == nil || [convID isEqual:[ZMConversation selfConversationIdentifierInContext:conversation.managedObjectContext]]) {
        return nil;
    }
    
    NSUUID *nonce = [NSUUID UUID];
    ZMGenericMessage *message = [ZMGenericMessage messageWithClearedTimestamp:cleared ofConversationWithID:convID nonce:nonce];
    VerifyReturnNil(message != nil);
    
    return [self appendSelfConversationWithGenericMessage:message managedObjectContext:conversation.managedObjectContext];
}

+ (void)updateConversationWithZMClearedFromSelfConversation:(ZMCleared *)cleared inContext:(NSManagedObjectContext *)context
{
    double newTimeStamp = cleared.clearedTimestamp;
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:(newTimeStamp/1000)];
    NSUUID *conversationID = [NSUUID uuidWithTransportString:cleared.conversationId];
    if (conversationID == nil || timestamp == nil) {
        return;
    }
    
    ZMConversation *conversationToUpdate = [ZMConversation conversationWithRemoteID:conversationID createIfNeeded:YES inContext:context];
    [conversationToUpdate updateClearedServerTimeStampIfNeeded:timestamp andSync:NO];
}


@end




@implementation ZMConversation (ParticipantsInternal)

+ (NSSet<UserClient *>*)clientsOfUsers:(NSSet<ZMUser *> *)users
{
    NSMutableSet *result = [NSMutableSet set];
    [users enumerateObjectsUsingBlock:^(ZMUser * _Nonnull user, BOOL * _Nonnull stop __unused) {
        [result addObjectsFromArray:user.clients.allObjects];
    }];
    return result;
}

- (void)internalAddParticipants:(NSSet<ZMUser *> *)participants
{
    VerifyReturn(participants != nil);
    
    NSSet<ZMUser *>* selfUserSet = [NSSet setWithObject:[ZMUser selfUserInContext:self.managedObjectContext]];
    
    NSMutableSet<ZMUser *>* otherUsers = [participants mutableCopy];
    [otherUsers minusSet:selfUserSet];
    
    if ([participants intersectsSet:selfUserSet]) {
        self.isSelfAnActiveMember = YES;
        self.needsToBeUpdatedFromBackend = YES;
    }
    
    if (otherUsers.count > 0) {
        NSSet *existingUsers = [self.lastServerSyncedActiveParticipants.set copy];
        [self.mutableLastServerSyncedActiveParticipants addObjectsFromArray:otherUsers.allObjects];
        
        [otherUsers minusSet:existingUsers];
        if (otherUsers.count > 0) {
            [self decreaseSecurityLevelIfNeededAfterDiscoveringClients:[ZMConversation clientsOfUsers:otherUsers] causedByAddedUsers:otherUsers];
        }
    }
}

- (void)internalRemoveParticipants:(NSSet<ZMUser *> *)participants sender:(ZMUser *)sender
{
    VerifyReturn(participants != nil);
    
    NSSet<ZMUser *>* selfUserSet = [NSSet setWithObject:[ZMUser selfUserInContext:self.managedObjectContext]];
    NSMutableSet<ZMUser *>* otherUsers = [participants mutableCopy];
    [otherUsers minusSet:selfUserSet];
    
    if ([participants intersectsSet:selfUserSet]) {
        self.isSelfAnActiveMember = NO;
        self.isArchived = sender.isSelfUser;
    }
    
    [self.mutableLastServerSyncedActiveParticipants removeObjectsInArray:otherUsers.allObjects];
    [self increaseSecurityLevelIfNeededAfterRemovingClientForUsers:otherUsers];
}

@dynamic isSelfAnActiveMember;
@dynamic lastServerSyncedActiveParticipants;

- (void)insertOrUpdateSecurityVerificationMessageAfterParticipantsChange:(ZMSystemMessage *)participantsChange
{
    NSUInteger messageIndex = [self.messages indexOfObject:participantsChange];
    if (messageIndex == 0) {
        return;
    }
    ZMMessage *previousMessage = [self.messages objectAtIndex:messageIndex - 1];
    
    BOOL (^isAppropriateVerificationSystemMessage)(ZMMessage *message) = ^BOOL(ZMMessage *message) {
        if (![previousMessage isKindOfClass:[ZMSystemMessage class]]) {
            return NO;
        }
        
        ZMSystemMessage *systemMessage = (ZMSystemMessage *)message;
        
        if (participantsChange.systemMessageType == ZMSystemMessageTypeParticipantsAdded &&
            systemMessage.systemMessageType == ZMSystemMessageTypeNewClient) {
            return ([systemMessage.addedUsers isEqualToSet:participantsChange.users]);
        }
        else if (participantsChange.systemMessageType == ZMSystemMessageTypeParticipantsRemoved &&
                 systemMessage.systemMessageType == ZMSystemMessageTypeConversationIsSecure) {
            return ([systemMessage.users isEqualToSet:participantsChange.users]);
        }
        
        return NO;
    };
    
    if (participantsChange.systemMessageType == ZMSystemMessageTypeParticipantsAdded) {
        // Check if the previous system message about the conversation degradation must be now moved or inserted
        // The message needs to be moved when the action (adding the participant) was local
        // The message needs to be inserted when the action was remote
        
        if (isAppropriateVerificationSystemMessage(previousMessage)) {
            NSDate *newDate = [participantsChange.serverTimestamp dateByAddingTimeInterval:0.01];
            
            previousMessage.serverTimestamp = newDate;
            [self resortMessagesWithUpdatedMessage:previousMessage];
        }
        else {
            [self decreaseSecurityLevelIfNeededAfterDiscoveringClients:[NSSet set] causedByAddedUsers:participantsChange.users];
        }
    }
    else if (participantsChange.systemMessageType == ZMSystemMessageTypeParticipantsRemoved) {
        // Check if the previous system message about the conversation is secured must be now moved or inserted
        // The message needs to be moved when the action (removing the participant) was local
        // The message needs to be inserted when the action was remote
        
        if (isAppropriateVerificationSystemMessage(previousMessage)) {
            NSDate *newDate = [participantsChange.serverTimestamp dateByAddingTimeInterval:0.01];
            
            previousMessage.serverTimestamp = newDate;
            [self resortMessagesWithUpdatedMessage:previousMessage];
        }
        else {
            [self increaseSecurityLevelIfNeededAfterRemovingClientForUsers:participantsChange.users];
        }
    }
}

@end


@implementation ZMConversation (KeyValueValidation)

- (BOOL)validateUserDefinedName:(NSString **)ioName error:(NSError **)outError
{
    BOOL result = [ExtremeCombiningCharactersValidator validateValue:ioName error:outError];
    if (!result || (outError != nil && *outError != nil)) {
        return NO;
    }
    
    result &= *ioName == nil || [StringLengthValidator validateValue:ioName
                                                 minimumStringLength:1
                                                 maximumStringLength:64
                                                   maximumByteLength:INT_MAX
                                                               error:outError];

    return result;
}

@end


@implementation ZMConversation (Connections)

- (NSString *)connectionMessage;
{
    return self.connection.message.stringByRemovingExtremeCombiningCharacters;
}

@end


@implementation NSUUID (ZMSelfConversation)

- (BOOL)isSelfConversationRemoteIdentifierInContext:(NSManagedObjectContext *)moc;
{
    // The self conversation has the same remote ID as the self user:
    return [self isSelfUserRemoteIdentifierInContext:moc];
}

@end


@implementation ZMConversation (Optimization)

+ (void)refreshObjectsThatAreNotNeededInSyncContext:(NSManagedObjectContext *)managedObjectContext;
{

    NSMutableArray *messagesToKeep = [NSMutableArray array];
    NSMutableArray *conversationsToKeep = [NSMutableArray array];
    NSMutableSet *usersToKeep = [NSMutableSet set];
    
    // make sure that the Set is not mutated while being enumerated
    NSSet *registeredObjects = managedObjectContext.registeredObjects;
    
    // gather messages to keep
    for(NSManagedObject *obj in registeredObjects) {
        if(!obj.isFault && [obj isKindOfClass:ZMConversation.class]) {
            ZMConversation *conversation = (ZMConversation *)obj;
            [messagesToKeep addObjectsFromArray:[conversation messagesNotToRefreshBecauseNeededForSorting].allObjects];
            
            if(conversation.shouldNotBeRefreshed) {
                [conversationsToKeep addObject:conversation];
                [usersToKeep unionSet:conversation.lastServerSyncedActiveParticipants.set];
            }
        }
    }
    [usersToKeep addObject:[ZMUser selfUserInContext:managedObjectContext]];
    
    // turn into a fault
    for(NSManagedObject *obj in registeredObjects) {
        if(!obj.isFault) {
            
            const BOOL isUser = [obj isKindOfClass:ZMUser.class];
            const BOOL isMessage = [obj isKindOfClass:ZMMessage.class];
            const BOOL isConversation = [obj isKindOfClass:ZMConversation.class];
            
            const BOOL isOfTypeToBeRefreshed = isUser || isMessage || isConversation;
            
            if((isMessage && [messagesToKeep indexOfObjectIdenticalTo:obj] != NSNotFound) ||
               (isConversation && [conversationsToKeep indexOfObjectIdenticalTo:obj] != NSNotFound) ||
               (isUser && [usersToKeep.allObjects indexOfObjectIdenticalTo:obj] != NSNotFound) ||
               !isOfTypeToBeRefreshed
            )
            {
                continue;
            }
            [managedObjectContext refreshObject:obj mergeChanges:obj.hasChanges];
        }
    }
}


- (NSSet *)messagesNotToRefreshBecauseNeededForSorting
{
    NSMutableSet *messagesToKeep = [NSMutableSet set];
    
    const static NSUInteger NumberOfMessagesToKeep = 3;
    
    if(![self hasFaultForRelationshipNamed:ZMConversationMessagesKey])
    {
        const NSUInteger length = self.messages.count;
        if(length == 0) {
            return [NSSet set];
        }
        NSUInteger currentIndex = length-1;
        const NSUInteger keepUntilIndex = (length-1 >= NumberOfMessagesToKeep) // avoid overflow
        ? (length-1 - NumberOfMessagesToKeep)
        : length-1;
        
        while(YES) { // not using a for loop because when hitting 0, --i would make it overflow and wrap
            [messagesToKeep addObject:self.messages[currentIndex]];
            if(currentIndex == keepUntilIndex) {
                break;
            }
            --currentIndex;
        };
    }
    
    return messagesToKeep;
}

- (BOOL)shouldNotBeRefreshed
{
    static const int HOUR_IN_SEC = 60 * 60;
    static const NSTimeInterval STALENESS = -36 * HOUR_IN_SEC;
    return (self.isFault) || (self.lastModifiedDate == nil) || (self.lastModifiedDate.timeIntervalSinceNow > STALENESS);
}

@end


@implementation ZMConversation (History)


- (void)clearMessageHistory
{
    self.isArchived = YES;
    self.clearedTimeStamp = self.lastServerTimeStamp; // the setter of this deletes all messages
    self.lastReadServerTimeStamp = self.lastServerTimeStamp;
}

- (void)revealClearedConversation
{
    self.isArchived = NO;
}

@end
