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

NSString *const ZMConversationInfoOTRMutedValueKey = @"otr_muted";
NSString *const ZMConversationInfoOTRMutedReferenceKey = @"otr_muted_ref";
NSString *const ZMConversationInfoOTRArchivedValueKey = @"otr_archived";
NSString *const ZMConversationInfoOTRArchivedReferenceKey = @"otr_archived_ref";



@implementation ZMConversation (Transport)


- (void)updateLastReadFromPostPayloadEvent:(ZMUpdateEvent *)event
{
    NSDate *serverTimeStamp = event.timeStamp;
    
    [self updateLastModifiedDateIfNeeded:serverTimeStamp];
    [self updateLastServerTimeStampIfNeeded:serverTimeStamp];
    [self updateLastReadServerTimeStampIfNeededWithTimeStamp:serverTimeStamp andSync:YES];
}

- (void)updateClearedFromPostPayloadEvent:(ZMUpdateEvent *)event
{
    [self updateClearedServerTimeStampIfNeeded:event.timeStamp andSync:YES];
}

- (void)updateWithTransportData:(NSDictionary *)transportData serverTimeStamp:(NSDate *)serverTimeStamp;
{
    NSUUID *remoteId = [transportData uuidForKey:ConversationInfoIDKey];
    RequireString(remoteId == nil || [remoteId isEqual:self.remoteIdentifier],
                  "Remote IDs not matching for conversation: %s vs. %s",
                  remoteId.transportString.UTF8String,
                  self.remoteIdentifier.transportString.UTF8String);
    
    if(transportData[ConversationInfoNameKey] != [NSNull null]) {
        self.userDefinedName = [transportData stringForKey:ConversationInfoNameKey];
    }
    
    self.conversationType = [self conversationTypeFromTransportData:[transportData numberForKey:ConversationInfoTypeKey]];
    
    [self updateLastModifiedDateIfNeeded:serverTimeStamp];
    [self updateLastServerTimeStampIfNeeded:serverTimeStamp];
    
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
        [self updatePotentialGapSystemMessagesIfNeededWithUsers:self.activeParticipants.set];
    }
    else {
        ZMLogError(@"Invalid members in conversation JSON: %@", transportData);
    }

    NSUUID *teamId = [transportData optionalUuidForKey:ConversationInfoTeamIdKey];
    if (nil != teamId) {
        [self updateTeamWithIdentifier:teamId];
    }
    
    self.accessModeStrings = [transportData optionalArrayForKey:ConversationInfoAccessModeKey];
    self.accessRoleString = [transportData optionalStringForKey:ConversationInfoAccessRoleKey];
    
    NSNumber *messageTimerNumber = [transportData optionalNumberForKey:ConversationInfoMessageTimer];
    
    if (messageTimerNumber != nil) {
        self.syncedMessageDestructionTimeout = messageTimerNumber.doubleValue;
    }
}

- (void)updateMembersWithPayload:(NSDictionary *)members
{
    NSArray *usersInfos = [members arrayForKey:ConversationInfoOthersKey];
    NSMutableOrderedSet<ZMUser *> *users = [NSMutableOrderedSet orderedSet];
    NSMutableOrderedSet<ZMUser *> *lastSyncedUsers = [NSMutableOrderedSet orderedSet];
    
    if (self.mutableLastServerSyncedActiveParticipants != nil) {
        lastSyncedUsers = self.mutableLastServerSyncedActiveParticipants;
    }
    
    for (NSDictionary *userDict in [usersInfos asDictionaries]) {
        
        NSUUID *userId = [userDict uuidForKey:ConversationInfoIDKey];
        if (userId == nil) {
            continue;
        }
        
        [users addObject:[ZMUser userWithRemoteID:userId createIfNeeded:YES inContext:self.managedObjectContext]];
    }
    
    NSMutableOrderedSet<ZMUser *> *addedUsers = [users mutableCopy];
    [addedUsers minusOrderedSet:lastSyncedUsers];
    NSMutableOrderedSet<ZMUser *> *removedUsers = [lastSyncedUsers mutableCopy];
    [removedUsers minusOrderedSet:users];
    
    ZMLogDebug(@"updateMembersWithPayload (%@) added = %lu removed = %lu", self.remoteIdentifier.transportString, (unsigned long)addedUsers.count, (unsigned long)removedUsers.count);
    
    [self internalAddParticipants:addedUsers.set];
    [self internalRemoveParticipants:removedUsers.set sender:[ZMUser selfUserInContext:self.managedObjectContext]];
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

/// Pass timeStamp when the timeStamp equals the time of the lastRead / cleared event, otherwise pass nil
- (void)updateSelfStatusFromDictionary:(NSDictionary *)dictionary timeStamp:(NSDate *)timeStamp previousLastServerTimeStamp:(NSDate *)previousLastServerTimestamp
{
    self.isSelfAnActiveMember = YES;
    
    [self updateIsSilencedWithPayload:dictionary];
    if ([self updateIsArchivedWithPayload:dictionary] && self.isArchived && previousLastServerTimestamp != nil) {
        if (self.clearedTimeStamp != nil && [self.clearedTimeStamp isEqualToDate:previousLastServerTimestamp]) {
            [self updateClearedServerTimeStampIfNeeded:timeStamp andSync:NO];
        }
    }
}

- (BOOL)updateIsArchivedWithPayload:(NSDictionary *)dictionary
{
    if(dictionary[ZMConversationInfoOTRArchivedReferenceKey] != nil && dictionary[ZMConversationInfoOTRArchivedReferenceKey] != [NSNull null]) {
        NSDate *silencedRef = [dictionary dateForKey:ZMConversationInfoOTRArchivedReferenceKey];
        if ([self updateArchivedChangedTimeStampIfNeeded:silencedRef andSync:NO]) {
            NSNumber *archived = [dictionary optionalNumberForKey:ZMConversationInfoOTRArchivedValueKey];
            self.internalIsArchived = [archived isEqual:@1];
            return YES;
        }
    }
    return NO;
}

- (void)updateIsSilencedWithPayload:(NSDictionary *)dictionary
{
    if(dictionary[ZMConversationInfoOTRMutedReferenceKey] != nil && dictionary[ZMConversationInfoOTRMutedReferenceKey] != [NSNull null]) {
        NSDate *silencedRef = [dictionary dateForKey:ZMConversationInfoOTRMutedReferenceKey];
        if ([self updateSilencedChangedTimeStampIfNeeded:silencedRef andSync:NO]) {
            NSNumber *silenced = [dictionary optionalNumberForKey:ZMConversationInfoOTRMutedValueKey];
            self.isSilenced = [silenced isEqual:@1];
        }
    }
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

- (void)unarchiveConversationFromEvent:(ZMUpdateEvent *)event;
{
    if ([event canUnarchiveConversation:self]){
        self.internalIsArchived = NO;
        [self updateArchivedChangedTimeStampIfNeeded:event.timeStamp andSync:NO];
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
