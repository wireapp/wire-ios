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


#import "ZMUpdateEvent.h"
#import "Collections+ZMTSafeTypes.h"
#import "ZMTransportData.h"
#import "NSString+UUID.h"
#import <WireTransport/WireTransport-Swift.h>

@import WireUtilities;


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

+ (NSArray *)eventsArrayWithUUID:(NSUUID *)uuid payloadArray:(NSArray *)payloadArray transient:(BOOL)transient source:(ZMUpdateEventSource)source pushStartingAt:(NSUUID *)sourceThreshold
{
    if (payloadArray == nil) {
        ZMLogError(@"Push event payload is invalid");
        return @[];
    }
    
    NSMutableArray *events = [NSMutableArray array];
    for(NSDictionary *payload in [payloadArray asDictionaries]) {
        ZMUpdateEventSource actualSource = source;

        BOOL type1 = sourceThreshold.isType1UUID && uuid.isType1UUID;
        if (type1 && nil != sourceThreshold && [sourceThreshold compareWithType1UUID:uuid] != NSOrderedDescending) {
            actualSource = ZMUpdateEventSourcePushNotification;
        }
        ZMUpdateEvent *event = [[self alloc] initWithUUID:uuid payload:payload transient:transient decrypted:NO source:actualSource];
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

+ (NSArray *)eventsArrayFromPushChannelData:(id<ZMTransportData>)transportData pushStartingAt:(NSUUID *)threshold
{
    return [self eventsArrayFromTransportData:transportData source:ZMUpdateEventSourceWebSocket pushStartingAt:threshold];
}

+ (NSArray *)eventsArrayFromTransportData:(id<ZMTransportData>)transportData source:(ZMUpdateEventSource)source
{
    return [self eventsArrayFromTransportData:transportData source:source pushStartingAt:nil];
}

+ (NSArray *)eventsArrayFromTransportData:(id<ZMTransportData>)transportData source:(ZMUpdateEventSource)source pushStartingAt:(NSUUID *)threshold
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
    
    return [self eventsArrayWithUUID:uuid payloadArray:payloadArray transient:transient source:source pushStartingAt:threshold];
}

+ (nullable instancetype)eventFromEventStreamPayload:(id<ZMTransportData>)payload uuid:(NSUUID *)uuid
{
    return [[self alloc] initWithUUID:uuid payload:[payload asDictionary] transient:NO decrypted:NO source:ZMUpdateEventSourceDownload];
}

+ (nullable instancetype)decryptedUpdateEventFromEventStreamPayload:(nonnull id<ZMTransportData>)payload uuid:(nullable NSUUID *)uuid transient:(BOOL)transient source:(ZMUpdateEventSource)source
{
    return [[self alloc] initWithUUID:uuid payload:[payload asDictionary] transient:transient decrypted:YES source:source];
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
    { CFSTR("user.client-remove"), ZMUpdateEventUserClientRemove },
    { CFSTR("team.create"), ZMUpdateEventTeamCreate },
    { CFSTR("team.delete"), ZMUpdateEventTeamDelete },
    { CFSTR("team.update"), ZMUpdateEventTeamUpdate },
    { CFSTR("team.member-join"), ZMUpdateEventTeamMemberJoin },
    { CFSTR("team.member-leave"), ZMUpdateEventTeamMemberLeave },
    { CFSTR("team.member-update"), ZMUpdateEventTeamMemberUpdate },
    { CFSTR("team.conversation-create"), ZMUpdateEventTeamConversationCreate },
    { CFSTR("team.conversation-delete"), ZMUpdateEventTeamConversationDelete },
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
        case ZMUpdateEventTeamCreate:
        case ZMUpdateEventTeamDelete:
        case ZMUpdateEventTeamUpdate:
        case ZMUpdateEventTeamMemberJoin:
        case ZMUpdateEventTeamMemberLeave:
        case ZMUpdateEventTeamMemberUpdate:
        case ZMUpdateEventTeamConversationCreate:
        case ZMUpdateEventTeamConversationDelete:
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


@end



