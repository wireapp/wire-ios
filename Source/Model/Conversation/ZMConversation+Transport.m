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


@import WireTransport;

#import "ZMConversation+Transport.h"
#import "ZMConversation+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMUpdateEvent+WireDataModel.h"
#import <WireDataModel/WireDataModel-Swift.h>

static NSString* ZMLogTag ZM_UNUSED = @"Conversations";

static NSString *const ConversationInfoNameKey = @"name";
static NSString *const ConversationInfoTypeKey = @"type";
static NSString *const ConversationInfoIDKey = @"id";

static NSString *const ConversationInfoOthersKey = @"others";
static NSString *const ConversationInfoMembersKey = @"members";
static NSString *const ConversationInfoCreatorKey = @"creator";
static NSString *const ConversationInfoTeamIdKey = @"team";
static NSString *const ConversationInfoAccessModeKey = @"access";
static NSString *const ConversationInfoAccessRoleKey = @"access_role";
static NSString *const ConversationInfoMessageTimer = @"message_timer";
static NSString *const ConversationInfoReceiptMode = @"receipt_mode";

NSString *const ZMConversationInfoOTRMutedValueKey = @"otr_muted";
NSString *const ZMConversationInfoOTRMutedStatusValueKey = @"otr_muted_status";
NSString *const ZMConversationInfoOTRMutedReferenceKey = @"otr_muted_ref";
NSString *const ZMConversationInfoOTRArchivedValueKey = @"otr_archived";
NSString *const ZMConversationInfoOTRArchivedReferenceKey = @"otr_archived_ref";



@implementation ZMConversation (Transport)

- (void)updateClearedFromPostPayloadEvent:(ZMUpdateEvent *)event
{
    if (event.timeStamp != nil) {
        [self updateCleared:event.timeStamp synchronize:YES];
    }
}

- (void)updateWithUpdateEvent:(ZMUpdateEvent *)updateEvent
{
    if (updateEvent.timeStamp != nil) {
        [self updateServerModified:updateEvent.timeStamp];
    }
}

- (void)updateWithTransportData:(NSDictionary *)transportData serverTimeStamp:(NSDate *)serverTimeStamp;
{
    NSUUID *remoteId = [transportData uuidForKey:ConversationInfoIDKey];
    RequireString(remoteId == nil || [remoteId isEqual:self.remoteIdentifier],
                  "Remote IDs not matching for conversation: %s vs. %s",
                  remoteId.transportString.UTF8String,
                  self.remoteIdentifier.transportString.UTF8String);
    
    if (transportData[ConversationInfoNameKey] != [NSNull null]) {
        self.userDefinedName = [transportData stringForKey:ConversationInfoNameKey];
    }
    
    self.conversationType = [self conversationTypeFromTransportData:[transportData numberForKey:ConversationInfoTypeKey]];
    
    if (serverTimeStamp != nil) {
         // If the lastModifiedDate is non-nil, e.g. restore from backup, do not update the lastModifiedDate
        if (self.lastModifiedDate == nil) {
            [self updateLastModified:serverTimeStamp];
        }
        [self updateServerModified:serverTimeStamp];
    }
    
    NSDictionary *selfStatus = [[transportData dictionaryForKey:ConversationInfoMembersKey] dictionaryForKey:@"self"];
    if(selfStatus != nil) {
        [self updateSelfStatusFromDictionary:selfStatus timeStamp:nil previousLastServerTimeStamp:nil];
    }
    else {
        ZMLogError(@"Missing self status in conversation data");
    }
    
    NSUUID *creatorId = [transportData uuidForKey:ConversationInfoCreatorKey];
    if(creatorId != nil) {
        self.creator = [ZMUser userWithRemoteID:creatorId createIfNeeded:YES inContext:self.managedObjectContext];
    }
    
    NSDictionary *members = [transportData dictionaryForKey:ConversationInfoMembersKey];
    if(members != nil) {
        [self updateMembersWithPayload:members];
        [self updatePotentialGapSystemMessagesIfNeededWithUsers:self.activeParticipants];
    }
    else {
        ZMLogError(@"Invalid members in conversation JSON: %@", transportData);
    }

    NSUUID *teamId = [transportData optionalUuidForKey:ConversationInfoTeamIdKey];
    if (nil != teamId) {
        [self updateTeamWithIdentifier:teamId];
    }
    
    NSNumber *receiptMode = [transportData optionalNumberForKey:ConversationInfoReceiptMode];
    if (nil != receiptMode) {
        BOOL enabled = receiptMode.intValue > 0;
        BOOL receiptModeChanged = !self.hasReadReceiptsEnabled && enabled;
        self.hasReadReceiptsEnabled = enabled;
        
        // We only want insert a system message if this is an existing conversation (non empty)
        if (receiptModeChanged && self.lastMessage != nil) {
            [self appendMessageReceiptModeIsOnMessageWithTimestamp:[NSDate date]];
        }
    }
    
    self.accessModeStrings = [transportData optionalArrayForKey:ConversationInfoAccessModeKey];
    self.accessRoleString = [transportData optionalStringForKey:ConversationInfoAccessRoleKey];
    
    NSNumber *messageTimerNumber = [transportData optionalNumberForKey:ConversationInfoMessageTimer];
    
    if (messageTimerNumber != nil) {
        // Backend is sending the miliseconds, we need to convert to seconds.
        self.syncedMessageDestructionTimeout = messageTimerNumber.doubleValue / 1000;
    }
}

- (void)updateMembersWithPayload:(NSDictionary *)members
{
    NSArray *usersInfos = [members arrayForKey:ConversationInfoOthersKey];
    NSSet<ZMUser *> *lastSyncedUsers = [NSSet set];
    
    if (self.mutableLastServerSyncedActiveParticipants != nil) {
        lastSyncedUsers = self.mutableLastServerSyncedActiveParticipants.set;
    }
    
    NSSet<NSUUID *> *participantUUIDs = [NSSet setWithArray:[usersInfos.asDictionaries mapWithBlock:^id(NSDictionary *userDict) {
        return [userDict uuidForKey:ConversationInfoIDKey];
    }]];
    
    NSMutableSet<ZMUser *> *participants = [[ZMUser usersWithRemoteIDs:participantUUIDs inContext:self.managedObjectContext] mutableCopy];
    
    if (participants.count != participantUUIDs.count) {
        
        // All users didn't exist so we need create the missing users
        
        NSSet<NSUUID *> *fetchedUUIDs = [NSSet setWithArray:[participants.allObjects mapWithBlock:^id(ZMUser *user) { return user.remoteIdentifier; }]];
        NSMutableSet<NSUUID *> *missingUUIDs = [participantUUIDs mutableCopy];
        [missingUUIDs minusSet:fetchedUUIDs];
                
        for (NSUUID *userId in missingUUIDs) {
            [participants addObject:[ZMUser userWithRemoteID:userId createIfNeeded:YES inContext:self.managedObjectContext]];
        }
    }
    
    NSMutableSet<ZMUser *> *addedParticipants = [participants mutableCopy];
    [addedParticipants minusSet:lastSyncedUsers];
    NSMutableSet<ZMUser *> *removedParticipants = [lastSyncedUsers mutableCopy];
    [removedParticipants minusSet:participants];
    
    ZMLogDebug(@"updateMembersWithPayload (%@) added = %lu removed = %lu", self.remoteIdentifier.transportString, (unsigned long)addedParticipants.count, (unsigned long)removedParticipants.count);
    
    [self internalAddParticipants:addedParticipants.allObjects];
    [self internalRemoveParticipants:removedParticipants.allObjects sender:[ZMUser selfUserInContext:self.managedObjectContext]];
}

- (void)updateTeamWithIdentifier:(NSUUID *)teamId
{
    VerifyReturn(nil != teamId);
    self.teamRemoteIdentifier = teamId;
    self.team = [Team fetchOrCreateTeamWithRemoteIdentifier:teamId createIfNeeded:NO inContext:self.managedObjectContext created:nil];
}

- (void)updatePotentialGapSystemMessagesIfNeededWithUsers:(NSSet <ZMUser *>*)users
{
    ZMSystemMessage *latestSystemMessage = [ZMSystemMessage fetchLatestPotentialGapSystemMessageInConversation:self];
    if (nil == latestSystemMessage) {
        return;
    }
    
    NSMutableSet <ZMUser *>* removedUsers = latestSystemMessage.users.mutableCopy;
    [removedUsers minusSet:users];
    
    NSMutableSet <ZMUser *>* addedUsers = users.mutableCopy;
    [addedUsers minusSet:latestSystemMessage.users];
    
    latestSystemMessage.addedUsers = addedUsers;
    latestSystemMessage.removedUsers = removedUsers;
    [latestSystemMessage updateNeedsUpdatingUsersIfNeeded];
}

/// Pass timestamp when the timestamp equals the time of the lastRead / cleared event, otherwise pass nil
- (void)updateSelfStatusFromDictionary:(NSDictionary *)dictionary timeStamp:(NSDate *)timeStamp previousLastServerTimeStamp:(NSDate *)previousLastServerTimestamp
{
    self.isSelfAnActiveMember = YES;
    
    [self updateMutedStatusWithPayload:dictionary];
    if ([self updateIsArchivedWithPayload:dictionary] && self.isArchived && previousLastServerTimestamp != nil) {
        if (timeStamp != nil && self.clearedTimeStamp != nil && [self.clearedTimeStamp isEqualToDate:previousLastServerTimestamp]) {
            [self updateCleared:timeStamp synchronize:NO];
        }
    }
}

- (BOOL)updateIsArchivedWithPayload:(NSDictionary *)dictionary
{
    if (dictionary[ZMConversationInfoOTRArchivedReferenceKey] != nil && dictionary[ZMConversationInfoOTRArchivedReferenceKey] != [NSNull null]) {
        NSDate *silencedRef = [dictionary dateFor:ZMConversationInfoOTRArchivedReferenceKey];
        if (silencedRef != nil && [self updateArchived:silencedRef synchronize:NO]) {
            NSNumber *archived = [dictionary optionalNumberForKey:ZMConversationInfoOTRArchivedValueKey];
            self.internalIsArchived = [archived isEqual:@1];
            return YES;
        }
    }
    return NO;
}

- (ZMConversationType)conversationTypeFromTransportData:(NSNumber *)transportType
{
    return [[self class] conversationTypeFromTransportData:transportType];
}

+ (ZMConversationType)conversationTypeFromTransportData:(NSNumber *)transportType
{
    int const t = [transportType intValue];
    switch (t) {
        case ZMConvTypeGroup:
            return ZMConversationTypeGroup;
        case ZMConvOneToOne:
            return ZMConversationTypeOneOnOne;
        case ZMConvConnection:
            return ZMConversationTypeConnection;
        default:
            NOT_USED(ZMConvTypeSelf);
            return ZMConversationTypeSelf;
    }
}

- (BOOL)shouldAddEvent:(ZMUpdateEvent *)event
{
    NSDate *timeStamp = event.timeStamp;
    if (self.clearedTimeStamp != nil && timeStamp != nil &&
        [self.clearedTimeStamp compare:timeStamp] != NSOrderedAscending)
    {
        return NO;
    }
    if (self.conversationType == ZMConversationTypeSelf){
        return NO;
    }
    return YES;
}

@end
