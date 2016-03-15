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



@import Foundation;

typedef NS_ENUM(NSUInteger, ZMConversationErrorCode) {
    ZMConversationNoError = 0,
    ZMConversationUnkownError,
    ZMConversationTooManyMembersInConversation,
    ZMConversationTooManyParticipantsInTheCall,
    ZMConversationOngoingGSMCall,
};

FOUNDATION_EXPORT NSString * const ZMConversationErrorDomain;

/// Backend constraint on maximum participants amount for a conversation where the group call is supported. Value could
/// change after unsuccessful -join call.
FOUNDATION_EXPORT NSString * const ZMConversationErrorMaxMembersForGroupCallKey;
/// Backend constraint on maximum amount of active participants. Value could change after unsuccessful -join call.
FOUNDATION_EXPORT NSString * const ZMConversationErrorMaxCallParticipantsKey;
/// There is an ongoing GSM call which prevents a Wire call from being initiated or accepted.
FOUNDATION_EXPORT NSString * const ZMConversationErrorOngoingGSMCallKey;

@interface NSError (ZMConversation)

/// Will return @c ZMConversationNoError if the receiver is not a conversation error.
@property (nonatomic, readonly) ZMConversationErrorCode conversationErrorCode;

@end
