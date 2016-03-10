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


@import ZMCSystem;

#import <zmessaging/ZMManagedObject.h>
#import <zmessaging/ZMMessage.h>


@class ZMUser;
@class ZMMessage;
@class ZMTextMessage;
@class ZMImageMessage;
@class ZMUserSession;
@class ZMKnockMessage;
@class ZMConversationList;

typedef NS_ENUM(int16_t, ZMConversationType) {
    ZMConversationTypeInvalid = 0,

    ZMConversationTypeSelf,
    ZMConversationTypeOneOnOne,
    ZMConversationTypeGroup,
    ZMConversationTypeConnection, // Incoming & outgoing connection request
};

/// The current indicator to be shown for a conversation in the conversation list.
typedef NS_ENUM(int16_t, ZMConversationListIndicator) {
    ZMConversationListIndicatorInvalid = 0,
    ZMConversationListIndicatorNone,
    ZMConversationListIndicatorUnreadMessages,
    ZMConversationListIndicatorKnock,
    ZMConversationListIndicatorMissedCall,
    ZMConversationListIndicatorExpiredMessage,
    ZMConversationListIndicatorActiveCall, ///< Ringing or talking in call.
    ZMConversationListIndicatorInactiveCall, ///< Other people are having a call but you are not in it.
    ZMConversationListIndicatorPending
};

extern NSString *const ZMIsDimmedKey; ///< Specifies that a range in an attributed string should be displayed dimmed.
extern NSString *const ZMConversationIsVerifiedNotificationName;
extern NSString *const ZMConversationFailedToDecryptMessageNotificationName;


@interface ZMConversation : ZMManagedObject

@property (nonatomic, copy) NSString *userDefinedName;
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSAttributedString *attributedDisplayName; ///< Uses @c ZMIsDimmedKey for parts that should be dimmed.

@property (readonly, nonatomic) ZMConversationType conversationType;
@property (readonly, nonatomic) NSDate *lastModifiedDate;
@property (readonly, nonatomic) NSOrderedSet *messages;
@property (readonly, nonatomic) NSOrderedSet *activeParticipants;
@property (readonly, nonatomic) NSOrderedSet *inactiveParticipants;
// The union of inactive and active participants.
@property (readonly, nonatomic) NSOrderedSet *allParticipants;
@property (readonly, nonatomic) ZMUser *creator;
@property (nonatomic, readonly) BOOL isPendingConnectionConversation;
@property (nonatomic, readonly) NSUInteger estimatedUnreadCount;
@property (nonatomic, readonly) ZMConversationListIndicator conversationListIndicator;
@property (nonatomic, readonly) BOOL hasDraftMessageText;
@property (nonatomic, copy) NSString *draftMessageText;

/// This is read only. Use -setVisibleWindowFromMessage:toMessage: to update this.
/// This will return @c nil if the last read message has not yet been sync'd to this device, or if the conversation has no last read message.
@property (nonatomic, readonly) ZMMessage *lastReadMessage;

@property (nonatomic) BOOL isSilenced;
@property (nonatomic) BOOL isMuted DEPRECATED_ATTRIBUTE;
@property (nonatomic) BOOL isArchived;

/// True only if every active client in this conversation is trusted by self client
@property (nonatomic, getter=trusted) BOOL isTrusted;

/// If true the conversation might still be trusted / ignored
@property (nonatomic, readonly) BOOL hasUntrustedClients;

/// returns whether the user is allowed to write to this conversation
@property (nonatomic, readonly) BOOL isReadOnly;

/// users that are currently typing in the conversation
@property (nonatomic, readonly) NSSet *typingUsers;


/// For group conversation this will be nil, for one to one or connection conversation this will be the other user
@property (nonatomic, readonly) ZMUser *connectedUser;

- (void)addParticipant:(ZMUser *)participant;
- (void)removeParticipant:(ZMUser *)participant;

/// This method loads messages in a window when there are visible messages
- (void)setVisibleWindowFromMessage:(ZMMessage *)oldestMessage toMessage:(ZMMessage *)newestMessage;

- (id<ZMConversationMessage>)appendKnock;

+ (instancetype)insertGroupConversationIntoUserSession:(ZMUserSession *)session withParticipants:(NSArray *)participants;
/// If that conversation exists, it is returned, @c nil otherwise.
+ (instancetype)existingOneOnOneConversationWithUser:(ZMUser *)otherUser inUserSession:(ZMUserSession *)session;

/// It's safe to pass @c nil. Returns an empty array if no message was inserted.
/// Returns an array as the message might have to be split depending on its size
- (NSArray<id <ZMConversationMessage>> *)appendMessagesWithText:(NSString *)text;

/// The given URL must be a file URL. It's safe to pass @c nil. Returns @c nil if no message was inserted.
- (id<ZMConversationMessage>)appendMessageWithImageAtURL:(NSURL *)fileURL;
/// The given data must be compressed image dat, e.g. JPEG data. It's safe to pass @c nil. Returns @c nil if no message was inserted.
- (id<ZMConversationMessage>)appendMessageWithImageData:(NSData *)imageData;

/// This sends the isTyping information to other members of the conversation.
/// @c isTyping should be set to
- (void)setIsTyping:(BOOL)isTyping;

@end



@interface ZMConversation (History)

/// Returns YES if the history has been cleared at least once.
@property (nonatomic, readonly) BOOL hasClearedMessageHistory;

/// Returns YES if all uncleared messages have been downloaded.
@property (nonatomic, readonly) BOOL hasDownloadedMessageHistory;

/// This will reset the message history to the last message in the conversation.
- (void)clearMessageHistory;

/// UI should call this method on opening cleared conversation.
- (void)revealClearedConversation;

@end



@interface ZMConversation (Connections)

/// The message that was sent as part of the connection request.
@property (nonatomic, copy, readonly) NSString *connectionMessage;

@end



