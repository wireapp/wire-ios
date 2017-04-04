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

#import "NSError+ZMConversationInternal.h"

NSString * const ZMConversationErrorDomain = @"ZMConversationErrorDomain";

NSString * const ZMConversationErrorMaxCallParticipantsKey = @"ZMConversationErrorMaxCallParticipants";
NSString * const ZMConversationErrorMaxMembersForGroupCallKey = @"ZMConversationErrorMaxMembersForGroupCall";

@implementation NSError (ZMConversation)

- (ZMConversationErrorCode)conversationErrorCode
{
    if (! [self.domain isEqualToString:ZMConversationErrorDomain]) {
        return ZMConversationNoError;
    }
    else {
        return (ZMConversationErrorCode)self.code;
    }
}

@end


@implementation NSError (ZMConversationInternal)

+ (instancetype)conversationErrorWithErrorCode:(ZMConversationErrorCode)code userInfo:(NSDictionary *)userInfo
{
    return [NSError errorWithDomain:ZMConversationErrorDomain code:code userInfo:userInfo];
}

+ (instancetype)tooManyParticipantsInConversationErrorFromResponse:(ZMTransportResponse *)response
{
    NSError *error;
    if (response.HTTPStatus == 409 && [[response payloadLabel] isEqualToString:@"conv-too-big"]) {
        NSUInteger maxMembersForGroupCall = 0;
        NSNumber *backendMaxMembersBoxed = [response.payload.asDictionary optionalNumberForKey:@"max_members"];
        if (backendMaxMembersBoxed != nil) {
            maxMembersForGroupCall = [backendMaxMembersBoxed unsignedIntegerValue];
        }
        error = [NSError conversationErrorWithErrorCode:ZMConversationTooManyMembersInConversation
                                               userInfo:@{ZMConversationErrorMaxMembersForGroupCallKey: @(maxMembersForGroupCall)}];
    }
    return error;
}

+ (instancetype)fullVoiceChannelErrorFromResponse:(ZMTransportResponse *)response
{
    NSError *error;
    if (response.HTTPStatus == 409 && [[response payloadLabel] isEqualToString:@"voice-channel-full"]) {
        NSUInteger maxCallParticipants = 0;
        NSNumber *backendMaxJoinedBoxed = [response.payload.asDictionary optionalNumberForKey:@"max_joined"];
        if (backendMaxJoinedBoxed != nil) {
            maxCallParticipants = [backendMaxJoinedBoxed unsignedIntegerValue];
        }
        error = [NSError conversationErrorWithErrorCode:ZMConversationTooManyParticipantsInTheCall
                                               userInfo:@{ZMConversationErrorMaxCallParticipantsKey: @(maxCallParticipants)}];
    }
    return error;
}


+ (instancetype)ongoingGSMCallError
{
    return [NSError conversationErrorWithErrorCode:ZMConversationOngoingGSMCall userInfo:nil];
}


@end
