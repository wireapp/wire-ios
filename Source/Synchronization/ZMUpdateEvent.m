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


@import ZMTransport;
@import ZMProtos;

#import "ZMUpdateEvent.h"
#import "ZMUser+Internal.h"
#import "ZMConversation+Internal.h"
#import "ZMVoiceChannel+Internal.h"
#import <zmessaging/zmessaging-Swift.h>


@interface NSDictionary (HashExtension)

- (NSUInteger)zm_hash;

@end

@implementation NSDictionary (HashExtension)

- (NSUInteger)zm_hash;
{
    NSUInteger finalHash = 0;
    for (NSObject *values in self.allValues) {
        finalHash += [values hash] * 13;
    }
    return finalHash;
}

@end


@interface ZMUpdateEvent ()

@property (nonatomic) NSDictionary *payload;
@property (nonatomic) ZMUpdateEventType type;
@property (nonatomic) ZMUpdateEventSource source;
@property (nonatomic) NSUUID *uuid;
@property (nonatomic) BOOL isTransient;
@property (nonatomic) BOOL wasDecrypted;
@property (nonatomic) NSMutableArray *debugInformationArray;

@end



@implementation ZMUpdateEvent

- (instancetype)initWithUUID:(NSUUID *)uuid payload:(NSDictionary *)payload transient:(BOOL)transient decrypted:(BOOL)decrypted source:(ZMUpdateEventSource)source
{
    self = [super init];
    if(self) {
        self.uuid = uuid;
        self.source = source;
        self.payload = payload;
        self.isTransient = transient;
        self.wasDecrypted = decrypted;
        self.debugInformationArray = [NSMutableArray array];
        [self appendDebugInformation:[NSString stringWithFormat:@"hash: %lu", (unsigned long)[payload zm_hash]]];
        if(! [self parseEventType:self.payload]) {
            return nil;
        }
    }
    return self;
}

+ (NSArray *)eventsArrayWithUUID:(NSUUID *)uuid payloadArray:(NSArray *)payloadArray transient:(BOOL)transient source:(ZMUpdateEventSource)source
{
    if (payloadArray == nil) {
        ZMLogError(@"Push event payload is invalid");
        return @[];
    }
    
    NSMutableArray *events = [NSMutableArray array];
    for(NSDictionary *payload in [payloadArray asDictionaries]) {
        ZMUpdateEvent *event = [[self alloc] initWithUUID:uuid payload:payload transient:transient decrypted:NO source:source];
        if (event != nil) {
            [events addObject:event];
        }
    }
    
    return events;
}

+ (NSArray *)eventsArrayFromPushChannelData:(id<ZMTransportData>)transportData
{
    return [self eventsArrayFromTransportData:transportData source:ZMUpdateEventSourceWebSocket];
}

+ (NSArray *)eventsArrayFromTransportData:(id<ZMTransportData>)transportData source:(ZMUpdateEventSource)source
{
    NSDictionary *dictionary = [transportData asDictionary];
    
    NSUUID *uuid = [[dictionary stringForKey:@"id"] UUID];
    NSArray *payloadArray = [dictionary optionalArrayForKey:@"payload"];
    BOOL transient = [dictionary optionalNumberForKey:@"transient"].boolValue;

    if(payloadArray == nil) {
        return nil;
    }
    
    if(uuid == nil) {
        ZMLogError(@"Push event id missing");
        return nil;
    }
    
    return [self eventsArrayWithUUID:uuid payloadArray:payloadArray transient:transient source:source];
}

+ (instancetype)eventFromEventStreamPayload:(id<ZMTransportData>)payload uuid:(NSUUID *)uuid
{
    return [[self alloc] initWithUUID:uuid payload:[payload asDictionary] transient:NO decrypted:NO source:ZMUpdateEventSourceDownload];
}

+ (nullable instancetype)decryptedUpdateEventFromEventStreamPayload:(nonnull id<ZMTransportData>)payload uuid:(nullable NSUUID *)uuid source:(ZMUpdateEventSource)source
{
    return [[self alloc] initWithUUID:uuid payload:[payload asDictionary] transient:NO decrypted:YES source:source];
}

- (void)appendDebugInformation:(nonnull NSString *)debugInformation;
{
    [self.debugInformationArray addObject:debugInformation];
}

- (NSDictionary *)payload
{
    return [_payload copy];
}

- (NSString *)debugInformation
{
    return [self.debugInformationArray componentsJoinedByString:@"\n"];
}

struct TypeMap {
    CFStringRef name;
    ZMUpdateEventType type;
} const TypeMapping[] = {
    { CFSTR("call.device-info"), ZMUpdateEventCallDeviceInfo },
    { CFSTR("call.flow-active"), ZMUpdateEventCallFlowActive },
    { CFSTR("call.flow-add"), ZMUpdateEventCallFlowAdd },
    { CFSTR("call.flow-delete"), ZMUpdateEventCallFlowDelete },
    { CFSTR("call.info"), ZM_ALLOW_DEPRECATED(ZMUpdateEventCallInfo) },
    { CFSTR("call.participants"), ZMUpdateEventCallParticipants },
    { CFSTR("call.remote-candidates-add"), ZMUpdateEventCallCandidatesAdd },
    { CFSTR("call.remote-candidates-update"), ZMUpdateEventCallCandidatesUpdate },
    { CFSTR("call.remote-sdp"), ZMUpdateEventCallRemoteSDP },
    { CFSTR("call.state"), ZMUpdateEventCallState },
    { CFSTR("conversation.asset-add"), ZMUpdateEventConversationAssetAdd },
    { CFSTR("conversation.connect-request"), ZMUpdateEventConversationConnectRequest },
    { CFSTR("conversation.create"), ZMUpdateEventConversationCreate },
    { CFSTR("conversation.knock"), ZMUpdateEventConversationKnock },
    { CFSTR("conversation.member-join"), ZMUpdateEventConversationMemberJoin },
    { CFSTR("conversation.member-leave"), ZMUpdateEventConversationMemberLeave },
    { CFSTR("conversation.member-update"), ZMUpdateEventConversationMemberUpdate },
    { CFSTR("conversation.message-add"), ZMUpdateEventConversationMessageAdd },
    { CFSTR("conversation.client-message-add"), ZMUpdateEventConversationClientMessageAdd },
    { CFSTR("conversation.otr-message-add"), ZMUpdateEventConversationOtrMessageAdd },
    { CFSTR("conversation.otr-asset-add"), ZMUpdateEventConversationOtrAssetAdd },
    { CFSTR("conversation.rename"), ZMUpdateEventConversationRename },
    { CFSTR("conversation.typing"), ZMUpdateEventConversationTyping },
    { CFSTR("conversation.voice-channel"), ZMUpdateEventConversationVoiceChannel },
    { CFSTR("conversation.voice-channel-activate"), ZMUpdateEventConversationVoiceChannelActivate },
    { CFSTR("conversation.voice-channel-deactivate"), ZMUpdateEventConversationVoiceChannelDeactivate },
    { CFSTR("user.connection"), ZMUpdateEventUserConnection },
    { CFSTR("user.new"), ZMUpdateEventUserNew },
    { CFSTR("user.push-remove"), ZMUpdateEventUserPushRemove },
    { CFSTR("user.update"), ZMUpdateEventUserUpdate },
    { CFSTR("user.contact-join"), ZMUpdateEventUserContactJoin },
    { CFSTR("user.client-add"), ZMUpdateEventUserClientAdd },
    { CFSTR("user.client-remove"), ZMUpdateEventUserClientRemove }
};

+ (ZMUpdateEventType)updateEventTypeForEventTypeString:(NSString *)string;
{
    for (size_t i = 0; i < (sizeof(TypeMapping)/sizeof(*TypeMapping)); ++i) {
        if ([string isEqualToString:(__bridge NSString *) TypeMapping[i].name]) {
            return TypeMapping[i].type;
        }
    }
    return ZMUpdateEventUnknown;
}

+ (NSString *)eventTypeStringForUpdateEventType:(ZMUpdateEventType)type;
{
    for (size_t i = 0; i < (sizeof(TypeMapping)/sizeof(*TypeMapping)); ++i) {
        if (TypeMapping[i].type == type) {
            return (__bridge NSString *) TypeMapping[i].name;
        }
    }
    return nil;
}

- (BOOL)parseEventType:(NSDictionary *)transportData
{
    NSString *type = transportData[@"type"];
    self.type = [[self class] updateEventTypeForEventTypeString:type];
    return (self.type != ZMUpdateEventUnknown);
}

- (BOOL)isFlowEvent;
{
    switch (self.type) {
        case ZMUpdateEventCallCandidatesAdd:
        case ZMUpdateEventCallCandidatesUpdate:
        case ZMUpdateEventCallFlowActive:
        case ZMUpdateEventCallFlowAdd:
        case ZMUpdateEventCallFlowDelete:
        case ZMUpdateEventCallRemoteSDP:
            return YES;
        case ZMUpdateEventUnknown:
        case ZMUpdateEventCallParticipants:
        case ZM_ALLOW_DEPRECATED(ZMUpdateEventCallInfo):
        case ZMUpdateEventCallDeviceInfo:
        case ZMUpdateEventCallState:
        case ZMUpdateEventConversationAssetAdd:
        case ZMUpdateEventConversationConnectRequest:
        case ZMUpdateEventConversationCreate:
        case ZMUpdateEventConversationKnock:
        case ZMUpdateEventConversationMemberJoin:
        case ZMUpdateEventConversationMemberLeave:
        case ZMUpdateEventConversationMemberUpdate:
        case ZMUpdateEventConversationMessageAdd:
        case ZMUpdateEventConversationClientMessageAdd:
        case ZMUpdateEventConversationOtrMessageAdd:
        case ZMUpdateEventConversationOtrAssetAdd:
        case ZMUpdateEventConversationRename:
        case ZMUpdateEventConversationTyping:
        case ZMUpdateEventConversationVoiceChannel:
        case ZMUpdateEventConversationVoiceChannelActivate:
        case ZMUpdateEventConversationVoiceChannelDeactivate:
        case ZMUpdateEventUserConnection:
        case ZMUpdateEventUserNew:
        case ZMUpdateEventUserUpdate:
        case ZMUpdateEventUserPushRemove:
        case ZMUpdateEventUserContactJoin:
        case ZMUpdateEventUserClientAdd:
        case ZMUpdateEventUserClientRemove:
        case ZMUpdateEvent_LAST:
            return NO;
    }
}

- (BOOL)isEncrypted
{
    switch (self.type) {
        case ZMUpdateEventConversationOtrAssetAdd:
        case ZMUpdateEventConversationOtrMessageAdd:
            return YES;
            
        default:
            return NO;
    }
}

- (BOOL)isGenericMessageEvent
{
    switch (self.type) {
        case ZMUpdateEventConversationOtrMessageAdd:
        case ZMUpdateEventConversationOtrAssetAdd:
        case ZMUpdateEventConversationClientMessageAdd:
            return true;
            break;
            
        default:
            return false;
            break;
    }
}

- (BOOL)hasEncryptedAndUnencryptedVersion
{
    switch (self.type) {
        case ZMUpdateEventConversationOtrMessageAdd:
        case ZMUpdateEventConversationOtrAssetAdd:
        case ZMUpdateEventConversationMessageAdd:
        case ZMUpdateEventConversationAssetAdd:
        case ZMUpdateEventConversationKnock:
            return YES;
            break;
            
        default:
            return NO;
            break;
    }
}

- (BOOL)isEqual:(id)object;
{
    if (! [object isKindOfClass:[ZMUpdateEvent class]]) {
        return NO;
    }
    ZMUpdateEvent *other = object;
    return (((other.uuid == self.uuid) || [other.uuid isEqual:self.uuid]) &&
            (other.type == self.type) &&
            ((other.payload == self.payload) || [other.payload isEqual:self.payload]));
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p> %@ %@ \n %@",
            self.class, self,
            self.uuid.UUIDString,
            self.payload,
            self.debugInformation];
}

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
            ZMEventID *eventID = self.eventID;
            BOOL olderEventID = eventID != nil && [eventID compare:conversation.archivedEventID] == NSOrderedAscending;
            return !olderEventID && !olderClearTimestamp;
        }
        
        // these events have no eventID
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

@end




@implementation ZMUpdateEvent (Payload)


- (ZMEventID *)eventID
{
    return [self.payload optionalEventForKey:@"id"];
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
            NSString *base64Content;
            if (self.type == ZMUpdateEventConversationOtrAssetAdd) {
                base64Content = [[self.payload optionalDictionaryForKey:@"data"] optionalStringForKey:@"info"];
            } else {
                id dataPayload = self.payload[@"data"];
                if ([dataPayload isKindOfClass:NSDictionary.class]) {
                    base64Content = [[self.payload dictionaryForKey:@"data"] optionalStringForKey:@"text"];
                } else {
                    base64Content = [self.payload optionalStringForKey:@"data"];
                }
            }
            if(base64Content == nil) {
                return nil;
            }
            ZMGenericMessage *message;
            @try {
                message = [ZMGenericMessage messageWithBase64String:base64Content];
            }
            @catch(NSException *e) {
                ZMLogError(@"Cannot create message from protobuffer: %@ event: %@", e, self);
                return nil;
            }
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


