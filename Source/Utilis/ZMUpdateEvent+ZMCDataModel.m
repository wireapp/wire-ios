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

@import ZMProtos;

#import "ZMUpdateEvent+ZMCDataModel.h"
#import "ZMConversation+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMGenericMessage+UpdateEvent.h"

@implementation ZMUpdateEvent (ZMCDataModel)

- (BOOL)canUnarchiveConversation:(ZMConversation *)conversation
{
    if ( ! conversation.isArchived ||
        (conversation.isSilenced && self.type != ZMUpdateEventConversationVoiceChannelActivate)) {
        return NO;
    }
    
    NSUUID *conversationID = self.conversationUUID;
    if(![conversationID isEqual:conversation.remoteIdentifier]) {
        return NO;
    }
    
    BOOL olderClearTimestamp = conversation.clearedTimeStamp != nil && [self.timeStamp compare:conversation.clearedTimeStamp] == NSOrderedAscending;
    
    switch (self.type) {
        case ZMUpdateEventConversationMemberLeave:
        {
            ZMUser *selfUser = [ZMUser selfUserInContext:conversation.managedObjectContext];
            NSArray *usersIDs = [[self.payload dictionaryForKey:@"data"] optionalArrayForKey:@"user_ids"];
            if ([usersIDs containsObject:selfUser.remoteIdentifier.transportString]) {
                return NO;
            }
            
            // N.B.: Fall-through
        }
        case ZMUpdateEventConversationAssetAdd:
        case ZMUpdateEventConversationKnock:
        case ZMUpdateEventConversationMemberJoin:
        case ZMUpdateEventConversationMessageAdd:
        case ZMUpdateEventConversationVoiceChannelActivate:
        {
            BOOL olderEvent = ((self.timeStamp != nil) &&
                               ([self.timeStamp compare:conversation.archivedChangedTimestamp] == NSOrderedAscending));
            return !olderEvent && !olderClearTimestamp;
        }
            
        case ZMUpdateEventConversationClientMessageAdd:
        case ZMUpdateEventConversationOtrMessageAdd:
        case ZMUpdateEventConversationOtrAssetAdd:
            return !olderClearTimestamp;
            
        case ZMUpdateEventCallCandidatesAdd:
        case ZMUpdateEventCallCandidatesUpdate:
        case ZMUpdateEventCallDeviceInfo:
        case ZMUpdateEventCallFlowActive:
        case ZMUpdateEventCallFlowAdd:
        case ZMUpdateEventCallFlowDelete:
        case ZMUpdateEventCallParticipants:
        case ZMUpdateEventCallRemoteSDP:
        case ZMUpdateEventCallState:
        case ZMUpdateEventConversationConnectRequest:
        case ZMUpdateEventConversationCreate:
        case ZMUpdateEventConversationMemberUpdate:
        case ZMUpdateEventConversationRename:
        case ZMUpdateEventConversationTyping:
        case ZMUpdateEventConversationVoiceChannel:
        case ZMUpdateEventConversationVoiceChannelDeactivate:
        case ZMUpdateEventUnknown:
        case ZMUpdateEventUserConnection:
        case ZMUpdateEventUserNew:
        case ZMUpdateEventUserUpdate:
        case ZMUpdateEventUserPushRemove:
        case ZMUpdateEvent_LAST:
        default:
            return NO;
    }
}

- (NSDate *)timeStamp
{
    if (self.isTransient || self.type == ZMUpdateEventCallState || self.type == ZMUpdateEventUserConnection) {
        return nil;
    }
    return [self.payload dateForKey:@"time"];
}

- (NSUUID *)senderUUID
{
    if (self.type == ZMUpdateEventUserConnection) {
        return [[self.payload optionalDictionaryForKey:@"connection"] optionalUuidForKey:@"to"];
    }
    if (self.type == ZMUpdateEventUserContactJoin) {
        return [[self.payload optionalDictionaryForKey:@"user"] optionalUuidForKey:@"id"];
    }
    if (self.type == ZMUpdateEventCallState) {
        return [self firstJoinedParticipantIDForCallEvent];
    }
    return [self.payload optionalUuidForKey:@"from"];
}

- (NSUUID *)firstJoinedParticipantIDForCallEvent
{
    if (self.type != ZMUpdateEventCallState) {
        return nil;
    }
    NSDictionary *participantInfo = [self.payload optionalDictionaryForKey:@"participants"];
    if (participantInfo.count == 0) {
        return nil;
    }
    __block NSString *senderUUID;
    [participantInfo enumerateKeysAndObjectsUsingBlock:^(NSString* remoteIDString, NSDictionary *info, BOOL * _Nonnull stop) {
        if ([[info optionalStringForKey:@"state"] isEqualToString:@"joined"]) {
            senderUUID = remoteIDString;
            *stop = YES;
        }
    }];
    return [NSUUID uuidWithTransportString:senderUUID];
}

- (NSUUID *)conversationUUID;
{
    if (self.type == ZMUpdateEventUserConnection) {
        return  [[self.payload optionalDictionaryForKey:@"connection"] optionalUuidForKey:@"conversation"];
    }
    return [self.payload optionalUuidForKey:@"conversation"];
}

- (NSString *)senderClientID
{
    if (self.type == ZMUpdateEventConversationOtrMessageAdd || self.type == ZMUpdateEventConversationOtrAssetAdd) {
        return [[self.payload optionalDictionaryForKey:@"data"] optionalStringForKey:@"sender"];
    }
    return nil;
}

- (NSString *)recipientClientID
{
    if (self.type == ZMUpdateEventConversationOtrMessageAdd || self.type == ZMUpdateEventConversationOtrAssetAdd) {
        return [[self.payload optionalDictionaryForKey:@"data"] optionalStringForKey:@"recipient"];
    }
    return nil;
}

- (NSUUID *)messageNonce;
{
    switch (self.type) {
        case ZMUpdateEventConversationMessageAdd:
        case ZMUpdateEventConversationAssetAdd:
        case ZMUpdateEventConversationKnock:
            return [[self.payload optionalDictionaryForKey:@"data"] optionalUuidForKey:@"nonce"];
            
        case ZMUpdateEventConversationClientMessageAdd:
        case ZMUpdateEventConversationOtrMessageAdd:
        case ZMUpdateEventConversationOtrAssetAdd:
        {
            ZMGenericMessage *message = [ZMGenericMessage genericMessageFromUpdateEvent:self];
            return [NSUUID uuidWithTransportString:message.messageId];
        }
        default:
            return nil;
            break;
    }
}


- (ZMCallEventType)callEventTypeOnManagedObjectContext:(NSManagedObjectContext *)context;
{
    if (self.type != ZMUpdateEventCallState) {
        return ZMCallEventTypeNone;
    }
    
    NSDictionary *participantInfo = [self.payload optionalDictionaryForKey:@"participants"];
    
    if (participantInfo == nil) {
        return ZMCallEventTypeUndefined;
    }
    __block BOOL selfUserIsJoined = NO;
    __block BOOL isVideoCall = NO;
    __block BOOL otherUserIsJoined = NO;
    __block NSUInteger otherJoinedUsers = 0;
    
    ZMConversation *conversation = [ZMConversation fetchObjectWithRemoteIdentifier:self.conversationUUID inManagedObjectContext:context];
    if (conversation == nil) {
        return ZMCallEventTypeUndefined;
    }
    
    ZMUser *selfUser = [ZMUser selfUserInContext:context];
    NSString *selfUserIDString = selfUser.remoteIdentifier.transportString;
    
    [participantInfo enumerateKeysAndObjectsUsingBlock:^(NSString* remoteIDString, NSDictionary *info, BOOL * _Nonnull stop) {
        NOT_USED(*stop);
        if ([[info optionalNumberForKey:@"videod"] boolValue]) {
            isVideoCall = YES;
        }
        if ([[info optionalStringForKey:@"state"] isEqualToString:@"joined"]) {
            if ([remoteIDString isEqualToString:selfUserIDString]) {
                selfUserIsJoined = YES;
            } else {
                otherUserIsJoined = YES;
                otherJoinedUsers++;
            }
        }
    }];
    
    if (!selfUserIsJoined && !otherUserIsJoined) {
        return ZMCallEventTypeCallEnded;
    } else if (selfUserIsJoined) {
        return ZMCallEventTypeSelfUserJoined;
    } else if (otherUserIsJoined && otherJoinedUsers == 1) {
        return isVideoCall ? ZMCallEventTypeIncomingVideoCall : ZMCallEventTypeIncomingCall;
    }
    return ZMCallEventTypeUndefined;
}


- (NSMutableSet *)usersFromUserIDsInManagedObjectContext:(NSManagedObjectContext *)context createIfNeeded:(BOOL)createIfNeeded;
{
    NSMutableSet *users = [NSMutableSet set];
    for (NSString *uuidString in [[self.payload optionalDictionaryForKey:@"data"] optionalArrayForKey:@"user_ids"] ) {
        VerifyAction([uuidString isKindOfClass:[NSString class]], return [NSMutableSet set]);
        NSUUID *uuid = uuidString.UUID;
        VerifyAction(uuid != nil, return [NSMutableSet set]);
        ZMUser *user = [ZMUser userWithRemoteID:uuid createIfNeeded:createIfNeeded inContext:context];
        if (user != nil) {
            [users addObject:user];
        }
    }
    return users;
}

@end


