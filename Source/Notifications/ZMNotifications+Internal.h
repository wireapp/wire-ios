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


#import "ZMNotifications.h"
#import "ZMConversationMessageWindow.h"
#import "ZMSearchUser.h"
#import "ZMUserSession.h"
#import "ZMAddressBookContact.h"

@class ZMConversationList;

@interface ZMUserSession (InternalNotifications)

+ (void)notifyInitialSyncCompleted;

@end


@interface ZMNotification (Internal)

- (instancetype)initWithName:(NSString *)name object:(id)object;

@end


@interface ZMNetworkAvailabilityChangeNotification (Internal)

+ (instancetype)notificationWithNetworkState:(ZMNetworkState)networkState userSession:(ZMUserSession *)userSession;

@end


@interface ZMMessageNotification (Internal)

+ (id<ZMNewUnreadMessageObserverOpaqueToken>)addNewMessagesObserver:(id<ZMNewUnreadMessagesObserver>)observer managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (void)removeNewMessagesObserverForToken:(id<ZMNewUnreadMessageObserverOpaqueToken>)token managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

+ (id<ZMNewUnreadKnockMessageObserverOpaqueToken>)addNewKnocksObserver:(id<ZMNewUnreadKnocksObserver>)observer managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (void)removeNewKnocksObserverForToken:(id<ZMNewUnreadKnockMessageObserverOpaqueToken>)token managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end




@interface ZMUser (InternalObservers)

+ (id<ZMUserObserverOpaqueToken>)addUserObserver:(id<ZMUserObserver>)observer forUsers:(NSArray *)users managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end


@interface ZMSearchUser (InternalObservers)

+ (id<ZMUserObserverOpaqueToken>)addUserObserver:(id<ZMUserObserver>)observer forUsers:(NSArray *)users managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end



@interface ZMCallEndedNotification (Internal)

@property (nonatomic) ZMVoiceChannelCallEndReason reason;

+ (instancetype)notificationWithConversation:(ZMConversation *)conversation reason:(ZMVoiceChannelCallEndReason)reason;

@end



@interface ZMTypingChangeNotification ()

+ (instancetype)notificationWithConversation:(ZMConversation *)conversation typingUser:(NSSet *)typingUsers;

@property (nonatomic) NSSet *typingUsers;

@end


@interface ZMConnectionLimitNotification (Internal)

+ (instancetype)connectionLimitNotification;

@end



@interface ZMInvitationStatusChangedNotification ()

@property (nonatomic, readwrite, copy) NSString *emailAddress;
@property (nonatomic, readwrite, copy) NSString *phoneNumber;
@property (nonatomic, readwrite) ZMInvitationStatus newStatus;

+ (instancetype)invitationStatusChangedNotificationForContactEmailAddress:(NSString *)emailAddress status:(ZMInvitationStatus)status;
+ (instancetype)invitationStatusChangedNotificationForContactPhoneNumber:(NSString *)phoneNumber status:(ZMInvitationStatus)status;

@end


typedef NS_ENUM(NSUInteger, ZMIncomingPersonalInvitationNotificationType) {
    ZMIncomingPersonalInvitationNotificationTypeDidNotFindInvitation,
    ZMIncomingPersonalInvitationNotificationTypeWillFetchInvitation,
    ZMIncomingPersonalInvitationNotificationTypeDidFailToFetchInvitation,
    ZMIncomingPersonalInvitationNotificationTypeDidReceiveInvitationToRegisterAsUser
};

@interface ZMIncomingPersonalInvitationNotification : ZMNotification

@property (nonatomic, readonly) ZMIncomingPersonalInvitationNotificationType type;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) ZMIncompleteRegistrationUser *user;

+ (id<ZMIncomingPersonalInvitationObserverToken>)addObserverWithBlock:(void(^)(ZMIncomingPersonalInvitationNotification *note))block;
+ (void)notifyDidNotFindPersonalInvitation;
+ (void)notifyWillFetchPersonalInvitation;
+ (void)notifyDidFailFetchPersonalInvitationWithError:(NSError *)error;
+ (void)notifyDidReceiveInviteToRegisterAsUser:(ZMIncompleteRegistrationUser *)user;

@end
