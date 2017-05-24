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

static NSString *const ConversationInfoStatusKey = @"status";
static NSString *const ConversationInfoNameKey = @"name";
static NSString *const ConversationInfoTypeKey = @"type";
static NSString *const ConversationInfoIDKey = @"id";

static NSString *const ConversationInfoOthersKey = @"others";
static NSString *const ConversationInfoMembersKey = @"members";
static NSString *const ConversationInfoCreatorKey = @"creator";
static NSString *const ConversationInfoTeamKey = @"team";
static NSString *const ConversationInfoTeamIdKey = @"teamid";
static NSString *const ConversationInfoManagedTeamKey = @"managed";
static NSString *const ConversationInfoLastEventTimeKey = @"last_event_time";

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

- (void)updateWithTransportData:(NSDictionary *)transportData;
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
    
    NSDate *lastTimeStamp = [transportData dateForKey:ConversationInfoLastEventTimeKey];
    [self updateLastModifiedDateIfNeeded:lastTimeStamp];
    [self updateLastServerTimeStampIfNeeded:lastTimeStamp];
    
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

    NSDictionary *team = [transportData optionalDictionaryForKey:ConversationInfoTeamKey];
    if (nil != team) {
        [self updateTeamWithPayload:team];
    }
}

- (void)updateMembersWithPayload:(NSDictionary *)members
{
    NSArray *users = [members arrayForKey:ConversationInfoOthersKey];
    for(NSDictionary *userDict in [users asDictionaries]) {
        
        NSUUID *userId = [userDict uuidForKey:ConversationInfoIDKey];
        if(userId == nil) {
            continue;
        }
        ZMUser *user = [ZMUser userWithRemoteID:userId createIfNeeded:YES inContext:self.managedObjectContext];
        
        if([[userDict numberForKey:ConversationInfoStatusKey] intValue] == 0) {
            [self internalAddParticipants:[NSSet setWithObject:user] isAuthoritative:YES];
        }
        else {
            [self.mutableOtherActiveParticipants removeObject:user];
            [self.mutableLastServerSyncedActiveParticipants removeObject:user];
        }
    }
}

- (void)updateTeamWithPayload:(NSDictionary *)payload
{
    NSUUID *teamId = [payload optionalUuidForKey:ConversationInfoTeamIdKey];
    if (nil != teamId) {
        BOOL created = NO;
        self.teamRemoteIdentifier = teamId;
        self.team = [Team fetchOrCreateTeamWithRemoteIdentifier:teamId createIfNeeded:YES inContext:self.managedObjectContext created:&created];
        // If we are added to a conversation in a team than we should have gotten the
        // team creation update event and fetched the team before.
        // If not and we just created the team then we need to refetch it.
        self.team.needsToBeUpdatedFromBackend = created;

        NSNumber *managed = [payload optionalNumberForKey:ConversationInfoManagedTeamKey];
        if (nil != managed) {
            self.managed = managed.boolValue;
        }
    }
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
    NSNumber *status = [dictionary optionalNumberForKey:ConversationInfoStatusKey];
    if(status != nil) {
        self.isSelfAnActiveMember = status.integerValue == 0;
    }
    
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
