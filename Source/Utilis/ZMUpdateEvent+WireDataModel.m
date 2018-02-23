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

@import WireProtos;

#import "ZMUpdateEvent+WireDataModel.h"
#import "ZMConversation+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMGenericMessage+UpdateEvent.h"

@implementation ZMUpdateEvent (WireDataModel)

- (BOOL)canUnarchiveConversation:(ZMConversation *)conversation
{
    if ( ! conversation.isArchived || conversation.isSilenced) {
        return NO;
    }
    
    NSUUID *conversationID = self.conversationUUID;
    if(![conversationID isEqual:conversation.remoteIdentifier]) {
        return NO;
    }
    
    BOOL olderClearTimestamp = conversation.clearedTimeStamp != nil && [self.timeStamp compare:conversation.clearedTimeStamp] == NSOrderedAscending;
    
    switch (self.type) {
        case ZMUpdateEventTypeConversationMemberLeave:
        {
            ZMUser *selfUser = [ZMUser selfUserInContext:conversation.managedObjectContext];
            NSArray *usersIDs = [[self.payload dictionaryForKey:@"data"] optionalArrayForKey:@"user_ids"];
            if ([usersIDs containsObject:selfUser.remoteIdentifier.transportString]) {
                return NO;
            }
            
            // N.B.: Fall-through
        }
        case ZMUpdateEventTypeConversationAssetAdd:
        case ZMUpdateEventTypeConversationKnock:
        case ZMUpdateEventTypeConversationMemberJoin:
        case ZMUpdateEventTypeConversationMessageAdd:
        {
            BOOL olderEvent = ((self.timeStamp != nil) &&
                               ([self.timeStamp compare:conversation.archivedChangedTimestamp] == NSOrderedAscending));
            return !olderEvent && !olderClearTimestamp;
        }
            
        case ZMUpdateEventTypeConversationClientMessageAdd:
        case ZMUpdateEventTypeConversationOtrMessageAdd:
        case ZMUpdateEventTypeConversationOtrAssetAdd:
            return !olderClearTimestamp;
            
        case ZMUpdateEventTypeConversationConnectRequest:
        case ZMUpdateEventTypeConversationCreate:
        case ZMUpdateEventTypeConversationMemberUpdate:
        case ZMUpdateEventTypeConversationRename:
        case ZMUpdateEventTypeConversationTyping:
        case ZMUpdateEventTypeUnknown:
        case ZMUpdateEventTypeUserConnection:
        case ZMUpdateEventTypeUserNew:
        case ZMUpdateEventTypeUserUpdate:
        case ZMUpdateEventTypeUserPushRemove:
        case ZMUpdateEventType_LAST:
        default:
            return NO;
    }
}

- (NSDate *)timeStamp
{
    if (self.isTransient || self.type == ZMUpdateEventTypeUserConnection) {
        return nil;
    }
    return [self.payload dateForKey:@"time"];
}

- (NSUUID *)senderUUID
{
    if (self.type == ZMUpdateEventTypeUserConnection) {
        return [[self.payload optionalDictionaryForKey:@"connection"] optionalUuidForKey:@"to"];
    }
    
    if (self.type == ZMUpdateEventTypeUserContactJoin) {
        return [[self.payload optionalDictionaryForKey:@"user"] optionalUuidForKey:@"id"];
    }

    return [self.payload optionalUuidForKey:@"from"];
}

- (NSUUID *)conversationUUID;
{
    if (self.type == ZMUpdateEventTypeUserConnection) {
        return  [[self.payload optionalDictionaryForKey:@"connection"] optionalUuidForKey:@"conversation"];
    }
    return [self.payload optionalUuidForKey:@"conversation"];
}

- (NSString *)senderClientID
{
    if (self.type == ZMUpdateEventTypeConversationOtrMessageAdd || self.type == ZMUpdateEventTypeConversationOtrAssetAdd) {
        return [[self.payload optionalDictionaryForKey:@"data"] optionalStringForKey:@"sender"];
    }
    return nil;
}

- (NSString *)recipientClientID
{
    if (self.type == ZMUpdateEventTypeConversationOtrMessageAdd || self.type == ZMUpdateEventTypeConversationOtrAssetAdd) {
        return [[self.payload optionalDictionaryForKey:@"data"] optionalStringForKey:@"recipient"];
    }
    return nil;
}

- (NSUUID *)messageNonce;
{
    switch (self.type) {
        case ZMUpdateEventTypeConversationMessageAdd:
        case ZMUpdateEventTypeConversationAssetAdd:
        case ZMUpdateEventTypeConversationKnock:
            return [[self.payload optionalDictionaryForKey:@"data"] optionalUuidForKey:@"nonce"];
            
        case ZMUpdateEventTypeConversationClientMessageAdd:
        case ZMUpdateEventTypeConversationOtrMessageAdd:
        case ZMUpdateEventTypeConversationOtrAssetAdd:
        {
            ZMGenericMessage *message = [ZMGenericMessage genericMessageFromUpdateEvent:self];
            return [NSUUID uuidWithTransportString:message.messageId];
        }
        default:
            return nil;
            break;
    }
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


