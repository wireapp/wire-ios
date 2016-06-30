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


@import ZMCSystem;
@import ZMUtilities;
@import ZMTransport;
@import ZMCDataModel;

#import "ZMLocalNotification.h"

#import "ZMLocalNotificationLocalization.h"
#import "UILocalNotification+StringProcessing.h"
#import "ZMUserSession+UserNotificationCategories.h"

NSString * const ZMLocalNotificationConversationObjectURLKey = @"conversationObjectURLString";
NSString * const ZMLocalNotificationUserInfoSenderKey = @"senderUUID";
NSString * const ZMLocalNotificationUserInfoNonceKey = @"nonce";

static NSString * const FailedMessageInGroupConversationText = @"failed.message.group";
static NSString * const FailedMessageInOneOnOneConversationText = @"failed.message.oneonone";


// These are the "base" keys for messages. We append to these for the specific case.
//
//
//
// 1 user, 1 conversation, 1 string
// %1$@    %2$@            %3$@
NSString *const ZMPushStringMessageAdd = @"add.message"; // "[senderName] in [conversationName] - [messageText]"
NSString *const ZMPushStringImageAdd = @"add.image"; // "[senderName] shared a picture in [conversationName]"
NSString *const ZMPushStringVideoAdd = @"add.video"; // "[senderName] shared a video in [conversationName]"
NSString *const ZMPushStringAudioAdd = @"add.audio"; // "[senderName] shared an audio message in [conversationName]"
NSString *const ZMPushStringFileAdd = @"add.file"; // "[senderName] shared a file in [conversationName]"
NSString *const ZMPushStringLocationAdd = @"add.location"; // "[senderName] shared a location in [conversationName]"
NSString *const ZMPushStringMessageAddMany = @"add.message.many"; // "x new messages in [conversationName] / from [senderName]"

/// 2 users, 1 conversation
NSString *const ZMPushStringMemberJoin = @"member.join";
// "[senderName] added you / [userName] to [conversationName]"
NSString *const ZMPushStringMemberLeave = @"member.leave";
// "[senderName] removed you / [userName] from [conversationName]"
NSString *const ZMPushStringMemberLeaveSender = @"member.leave.sender";
// "[senderName] left [conversationName]"


NSString *const ZMPushStringMemberJoinMany = @"member.join.many";
// "[senderName] added people to [conversationName]"
NSString *const ZMPushStringMemberLeaveMany = @"member.leave.many";
// "[senderName] removed people from [conversationName]"

NSString *const ZMPushStringKnock = @"knock"; // "[senderName] pinged you x times in [conversationName]" // "x pings in

NSString *const ZMPushStringVideoCallStarts = @"call.started.video"; // "[senderName] wants to talk"
NSString *const ZMPushStringCallStarts = @"call.started"; // "[senderName] wants to talk"
NSString *const ZMPushStringCallMissed = @"call.missed"; // "[senderName] called you x times"
NSString *const ZMPushStringCallMissedMany = @"call.missed.many"; // "You have x missed calls in a conversation"

NSString *const ZMPushStringConversationRename = @"conversation.rename"; // "[senderName] renamed a conversation to [newConversationName]"
NSString *const ZMPushStringConnectionRequest = @"connection.request"; // "[senderName] wants to connect: [messageText]"
NSString *const ZMPushStringConnectionAccepted = @"connection.accepted"; // "[senderName] accepted your connection request"

NSString *const ZMPushStringConversationCreate = @"conversation.create";
NSString *const ZMPushStringNewConnection = @"new_user";

#pragma mark - ZMLocalNotification


@interface ZMLocalNotification ()

@property (nonatomic) ZMLocalNotificationType type;
@property (nonatomic) ZMCallEventType currentCallType;

- (instancetype)initWithType:(ZMLocalNotificationType)notificationType;

@end


@implementation ZMLocalNotification

- (instancetype)initWithType:(ZMLocalNotificationType)notificationType
{
    self = [super init];
    if(self) {
        self.type = notificationType;
    }
    return self;
}

+ (ZMConversation *)conversationForLocalNotification:(UILocalNotification *)notification inManagedObjectContext:(NSManagedObjectContext *)MOC;
{
    NSString *urlString = [notification.userInfo valueForKey:ZMLocalNotificationConversationObjectURLKey];
    NSURL *URL = [NSURL URLWithString:urlString];
    if (URL == nil) {
        return nil;
    }
    
    NSManagedObjectID *conversationID = [MOC.persistentStoreCoordinator managedObjectIDForURIRepresentation:URL];
    if (conversationID == nil) {
        return nil;
    }
    
    return (id)[MOC objectWithID:conversationID];
}


+ (ZMMessage *)messageForLocalNotification:(UILocalNotification *)notification conversation:(ZMConversation *)conversation inManagedObjectContext:(NSManagedObjectContext *)context
{
    if (conversation == nil) {
        return nil;
    }
    NSUUID *nonce = [NSUUID uuidWithTransportString:notification.userInfo[ZMLocalNotificationUserInfoNonceKey]];
    if (nonce == nil) {
        return nil;
    }
    ZMMessage *message = [ZMMessage fetchMessageWithNonce:nonce forConversation:conversation inManagedObjectContext:context];
    return message;
}

+ (NSUUID *)senderRemoteIdentifierForLocalNotification:(UILocalNotification *)notification
{
    NSString *senderUUIDString = notification.userInfo[ZMLocalNotificationUserInfoSenderKey];
    return [NSUUID uuidWithTransportString:senderUUIDString];
}

@end



#pragma mark - ZMLocalNotificationForExpiredMessage

@implementation ZMLocalNotificationForExpiredMessage

- (instancetype)initWithExpiredMessage:(ZMMessage *)message
{
    self = [super initWithType:ZMLocalNotificationTypeExpiredMessage];
    if(self) {
        _message = message;
        _conversation = message.conversation;
        _uiNotification = [[UILocalNotification alloc] init];
        [self createBodyForConversation:message.conversation];
    }
    return self;
}

- (instancetype)initWithConversation:(ZMConversation *)conversation
{
    self = [super init];
    if(self) {
        _conversation = conversation;
        _uiNotification = [[UILocalNotification alloc] init];
        [self createBodyForConversation:conversation];
    }
    return self;
}

- (void)createBodyForConversation:(ZMConversation *)conversation
{
    if(self.message.conversation.conversationType == ZMConversationTypeGroup) {
        self.uiNotification.alertBody = [FailedMessageInGroupConversationText localizedStringWithConversation:conversation count:nil];
    }
    else {
        self.uiNotification.alertBody = [FailedMessageInOneOnOneConversationText localizedStringWithUser:conversation.connectedUser count:nil];
    }
    NSString *conversationID = [conversation objectIDURLString];
    if(conversationID != nil) {
        self.uiNotification.userInfo = @{ ZMLocalNotificationConversationObjectURLKey : conversationID };
    }
    else {
        ZMLogError(@"Conversation not set on message?");
    }
}

@end


