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


@import ZMTransport;
@import ZMUtilities;
@import ZMCSystem;

#import "MockEvent.h"
#import "MockConversation.h"
#import "MockUser.h"

static ZMLogLevel_t const ZMLogLevel ZM_UNUSED = ZMLogLevelWarn;

@implementation MockEvent

@dynamic from;
@dynamic identifier;
@dynamic time;
@dynamic type;
@dynamic data;
@dynamic conversation;
@dynamic decryptedOTRData;

+ (NSArray *)eventStringToEnumValueTuples
{
    static NSArray *mapping;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mapping =
        @[
          @[@(ZMTUpdateEventCallDeviceInfo),@"call.device-info"],
          @[@(ZMTUpdateEventCallFlowActive),@"call.flow-active"],
          @[@(ZMTUpdateEventCallFlowAdd),@"call.flow-add"],
          @[@(ZMTUpdateEventCallFlowDelete),@"call.flow-delete"],
          @[@(ZMTUpdateEventCallParticipants),@"call.participants"],
          @[@(ZMTUpdateEventCallCandidatesAdd),@"call.remote-candidates-add"],
          @[@(ZMTUpdateEventCallCandidatesUpdate),@"call.remote-candidates-update"],
          @[@(ZMTUpdateEventCallRemoteSDP),@"call.remote-sdp"],
          @[@(ZMTUpdateEventCallState),@"call.state"],
          @[@(ZMTUpdateEventConversationAssetAdd),@"conversation.asset-add"],
          @[@(ZMTUpdateEventConversationConnectRequest),@"conversation.connect-request"],
          @[@(ZMTUpdateEventConversationCreate),@"conversation.create"],
          @[@(ZMTUpdateEventConversationHotKnock),@"conversation.hot-knock"],
          @[@(ZMTUpdateEventConversationKnock),@"conversation.knock"],
          @[@(ZMTUpdateEventConversationMemberJoin),@"conversation.member-join"],
          @[@(ZMTUpdateEventConversationMemberLeave),@"conversation.member-leave"],
          @[@(ZMTUpdateEventConversationMemberUpdate),@"conversation.member-update"],
          @[@(ZMTUpdateEventConversationMessageAdd),@"conversation.message-add"],
          @[@(ZMTUpdateEventConversationClientMessageAdd),@"conversation.client-message-add"],
          @[@(ZMTUpdateEventConversationOTRMessageAdd),@"conversation.otr-message-add"],
          @[@(ZMTUpdateEventConversationOTRAssetAdd),@"conversation.otr-asset-add"],
          @[@(ZMTUpdateEventConversationRename),@"conversation.rename"],
          @[@(ZMTUpdateEventConversationTyping),@"conversation.typing"],
          @[@(ZMTUpdateEventConversationVoiceChannel),@"conversation.voice-channel"],
          @[@(ZMTUpdateEventConversationVoiceChannelActivate),@"conversation.voice-channel-activate"],
          @[@(ZMTUpdateEventConversationVoiceChannelDeactivate),@"conversation.voice-channel-deactivate"],
          @[@(ZMTUpdateEventUserConnection),@"user.connection"],
          @[@(ZMTUpdateEventUserNew),@"user.new"],
          @[@(ZMTUpdateEventUserPushRemove),@"user.push-remove"],
          @[@(ZMTUpdateEventUserUpdate),@"user.update"],
          @[@(ZMTUPdateEventUserClientAdd),@"user.client-add"],
          @[@(ZMTUpdateEventUserClientRemove),@"user.client-remove"]
          ];
    });
    return mapping;
}

+ (NSString *)stringFromType:(ZMTUpdateEventType)type
{
    for(NSArray *tuple in [MockEvent eventStringToEnumValueTuples]) {
        if([tuple[0] isEqualToNumber:@(type)]) {
            return tuple[1];
        }
    }
    RequireString(false, "Failed to parse ZMTUpdateEventType %lu", (unsigned long)type);
}

+ (ZMTUpdateEventType)typeFromString:(NSString *)string
{
    for(NSArray *tuple in [MockEvent eventStringToEnumValueTuples]) {
        if([tuple[1] isEqualToString:string]) {
            return (ZMTUpdateEventType) ((NSNumber *)tuple[0]).intValue;
        }
    }
    RequireString(false, "Failed to parse ZMTConnectionStatus %s", string.UTF8String);
}

+ (NSArray *)persistentEvents;
{
   return @[@(ZMTUpdateEventConversationRename),
            @(ZMTUpdateEventConversationMemberJoin),
            @(ZMTUpdateEventConversationMemberLeave),
            @(ZMTUpdateEventConversationConnectRequest),
            @(ZMTUpdateEventConversationMessageAdd),
            @(ZMTUpdateEventConversationClientMessageAdd),
            @(ZMTUpdateEventConversationAssetAdd),
            @(ZMTUpdateEventConversationKnock),
            @(ZMTUpdateEventConversationHotKnock),
            @(ZMTUpdateEventConversationVoiceChannelActivate),
            @(ZMTUpdateEventConversationVoiceChannelDeactivate),
            @(ZMTUpdateEventConversationOTRMessageAdd),
            @(ZMTUpdateEventConversationOTRAssetAdd)
            ];
}


- (id<ZMTransportData>)transportData;
{
    return @{@"conversation": self.conversation.identifier ?: [NSNull null],
             @"data": self.data ?: [NSNull null],
             @"from": self.from ? self.from.identifier : [NSNull null],
             @"id": self.identifier ?: [NSNull null],
             @"time": self.time.transportString ?: [NSNull null],
             @"type": self.type ?: [NSNull null],
            };
}

- (ZMTUpdateEventType)eventType
{
    return [[self class] typeFromString:self.type];
}

@end
