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

#import <zmessaging/ZMUser.h>
#import <zmessaging/ZMConversationMessageWindow.h>
#import <zmessaging/ZMNetworkState.h>
#import <zmessaging/ZMConversationList.h>
#import <zmessaging/ZMSearchUser.h>
#import <zmessaging/ZMAddressBookContact.h>
#import "ZMVoiceChannel.h"
#import "ZMUserSession.h"

@class ZMMessage;
@class ZMConversation;
@class ZMConnection;
@class ZMUserSession;

@class ZMNewUnreadMessagesNotification;
@class ZMNewUnreadKnocksNotification;
@class ZMCallEndedNotification;
@class ZMTypingChangeNotification;
@class ZMConnectionLimitNotification;
@class ZMInvitationStatusChangedNotification;
@class ZMIncompleteRegistrationUser;

@class MessageWindowChangeInfo;
@class ConversationListChangeInfo;
@class MessageChangeInfo;
@class ConversationChangeInfo;
@class UserChangeInfo;
@class NewUnreadMessagesChangeInfo;
@class NewUnreadKnockMessagesChangeInfo;
@class NewUnreadUnsentMessageChangeInfo;

@protocol ZMInitialSyncCompletionObserver <NSObject>
- (void)initialSyncCompleted:(NSNotification *)notification;
@end

@protocol ZMIncomingPersonalInvitationObserver <NSObject>

- (void)didNotFindPersonalInvitation;
- (void)willFetchPersonalInvitation;
- (void)didFailToFetchPersonalInvitationWithError:(NSError *)error;
- (void)didReceiveInvitationToRegisterAsUser:(ZMIncompleteRegistrationUser *)user;

@end

@protocol ZMMessageObserver <NSObject>
- (void)messageDidChange:(MessageChangeInfo *)changeInfo;
@end


@protocol ZMConversationObserver <NSObject>
- (void)conversationDidChange:(ConversationChangeInfo *)note;
@end

@protocol ZMUserObserver <NSObject>
- (void)userDidChange:(UserChangeInfo *)note;
@end


@protocol ZMConversationListObserver <NSObject>
- (void)conversationListDidChange:(ConversationListChangeInfo *)changeInfo;

@optional
- (void)conversationInsideList:(ZMConversationList*)list didChange:(ConversationChangeInfo *)changeInfo;

@end


@protocol ZMConversationMessageWindowObserver <NSObject>
- (void)conversationWindowDidChange:(MessageWindowChangeInfo *)note;

@optional
- (void)messagesInsideWindowDidChange:(NSArray *)messageChangeInfos;

@end


@protocol ZMNewUnreadMessagesObserver <NSObject>
- (void)didReceiveNewUnreadMessages:(NewUnreadMessagesChangeInfo *)note;
@end


@protocol ZMNewUnreadKnocksObserver <NSObject>
- (void)didReceiveNewUnreadKnockMessages:(NewUnreadKnockMessagesChangeInfo *)note;
@end


@protocol ZMNewUnreadUnsentMessageObserver <NSObject>
- (void)didReceiveNewUnreadUnsentMessages:(NewUnreadUnsentMessageChangeInfo *)note;
@end


@protocol ZMCallEndObserver
- (void)didEndCall:(ZMCallEndedNotification *)note;
@end


@protocol ZMTypingChangeObserver <NSObject>
- (void)typingDidChange:(ZMTypingChangeNotification *)note;
@end


@protocol ZMConnectionLimitObserver <NSObject>
- (void)connectionLimitReached:(ZMConnectionLimitNotification *)note;
@end

@protocol ZMInvitationStatusObserver <NSObject>
- (void)invitationStatusChanged:(ZMInvitationStatusChangedNotification *)note;
@end

@interface ZMNotification : NSNotification
@end

@interface ZMUserSession (ZMInitialSyncCompletion)
+ (void)addInitalSyncCompletionObserver:(id<ZMInitialSyncCompletionObserver>)observer;
+ (void)removeInitalSyncCompletionObserver:(id<ZMInitialSyncCompletionObserver>)observer;
@end

@interface ZMMovedIndex : NSObject

+ (instancetype)movedIndexFrom:(NSUInteger)from to:(NSUInteger)to;

@property (nonatomic, readonly) NSUInteger from;
@property (nonatomic, readonly) NSUInteger to;

@end


@protocol ZMConversationMessageWindowObserverOpaqueToken <NSObject>
@end

@interface ZMConversationMessageWindow (Notifications)

- (id<ZMConversationMessageWindowObserverOpaqueToken>)addConversationWindowObserver:(id<ZMConversationMessageWindowObserver>)observer ZM_MUST_USE_RETURN;
- (void)removeConversationWindowObserverToken:(id<ZMConversationMessageWindowObserverOpaqueToken>)token;

@end



@protocol ZMNetworkAvailabilityObserver;

@interface ZMNetworkAvailabilityChangeNotification : ZMNotification

@property (nonatomic, readonly) ZMNetworkState networkState;
@property (nonatomic, readonly, weak) ZMUserSession *userSession;


+ (void)addNetworkAvailabilityObserver:(id<ZMNetworkAvailabilityObserver>)delegate userSession:(ZMUserSession *)session;
+ (void)removeNetworkAvailabilityObserver:(id<ZMNetworkAvailabilityObserver>)delegate;

@end



@protocol ZMNetworkAvailabilityObserver <NSObject>

- (void)didChangeAvailability:(ZMNetworkAvailabilityChangeNotification *)note;

@end



@interface ZMTypingChangeNotification : ZMNotification

@property (nonatomic, readonly) ZMConversation* conversation;
@property (nonatomic, readonly) NSSet *typingUsers;

@end



@interface ZMConversation (TypingNotification)

- (void)addTypingObserver:(id<ZMTypingChangeObserver>)observer;
+ (void)removeTypingObserver:(id<ZMTypingChangeObserver>)observer;

@end



@protocol ZMConversationObserverOpaqueToken <NSObject>
@end

@interface ZMConversation (Observer)

- (id<ZMConversationObserverOpaqueToken>)addConversationObserver:(id<ZMConversationObserver>)observer;
+ (void)removeConversationObserverForToken:(id<ZMConversationObserverOpaqueToken>)token;

@end



@protocol ZMConversationListObserverOpaqueToken <NSObject>
@end

@interface ZMConversationList (ListChangeNotification)

- (id<ZMConversationListObserverOpaqueToken>)addConversationListObserver:(id<ZMConversationListObserver>)observer;
- (void)removeConversationListObserverForToken:(id<ZMConversationListObserverOpaqueToken>)token;

@end


@protocol ZMMessageObserverOpaqueToken <NSObject>
@end
@protocol ZMNewUnreadMessageObserverOpaqueToken <NSObject>
@end
@protocol ZMNewUnreadKnockMessageObserverOpaqueToken <NSObject>
@end
@protocol ZMNewUnreadUnsentMessageObserverOpaqueToken <NSObject>
@end



@interface ZMMessageNotification : NSObject

+ (id<ZMMessageObserverOpaqueToken>)addMessageObserver:(id<ZMMessageObserver>)observer forMessage:(id<ZMConversationMessage>)conversationMessage;
+ (void)removeMessageObserverForToken:(id<ZMMessageObserverOpaqueToken>)token;

+ (id<ZMNewUnreadMessageObserverOpaqueToken>)addNewMessagesObserver:(id<ZMNewUnreadMessagesObserver>)observer inUserSession:(ZMUserSession *)userSession;
+ (void)removeNewMessagesObserverForToken:(id<ZMNewUnreadMessageObserverOpaqueToken>)token inUserSession:(ZMUserSession *)userSession;

+ (id<ZMNewUnreadKnockMessageObserverOpaqueToken>)addNewKnocksObserver:(id<ZMNewUnreadKnocksObserver>)observer inUserSession:(ZMUserSession *)userSession;
+ (void)removeNewKnocksObserverForToken:(id<ZMNewUnreadKnockMessageObserverOpaqueToken>)token inUserSession:(ZMUserSession *)userSession;

+ (id<ZMNewUnreadUnsentMessageObserverOpaqueToken>)addUnreadUnsentMessageObserver:(id<ZMNewUnreadKnocksObserver>)observer inUserSession:(ZMUserSession *)userSession;
+ (void)removeUnreadUnsentMessageObserverForToken:(id<ZMNewUnreadUnsentMessageObserverOpaqueToken>)token inUserSession:(ZMUserSession *)userSession;

@end


@interface ZMCallEndedNotification : ZMNotification

@property (nonatomic, readonly) ZMConversation *conversation;
@property (nonatomic, readonly) ZMVoiceChannelCallEndReason reason;

+ (void)addCallEndObserver:(id<ZMCallEndObserver>)observer;
+ (void)removeCallEndObserver:(id<ZMCallEndObserver>)observer;

@end


@protocol ZMUserObserverOpaqueToken <NSObject>
@end

@protocol ZMObservableUser

+ (id<ZMUserObserverOpaqueToken>)addUserObserver:(id<ZMUserObserver>)observer forUsers:(NSArray *)users inUserSession:(ZMUserSession *)userSession;
+ (id<ZMUserObserverOpaqueToken>)addUserObserver:(id<ZMUserObserver>)observer forUsers:(NSArray *)users managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (void)removeUserObserverForToken:(id<ZMUserObserverOpaqueToken>)token;

@end


@interface ZMUser (ChangeNotification) <ZMObservableUser>
@end


@interface ZMSearchUser (ChangeNotification) <ZMObservableUser>
@end






@interface ZMConnectionLimitNotification : ZMNotification

+ (void)addConnectionLimitObserver:(id<ZMConnectionLimitObserver>)observer;
+ (void)removeConnectionLimitObserver:(id<ZMConnectionLimitObserver>)observer;

@end




@interface ZMInvitationStatusChangedNotification : ZMNotification

@property (nonatomic, readonly, copy) NSString *email;
@property (nonatomic, readonly, copy) NSString *phone;
@property (nonatomic, readonly) ZMInvitationStatus newStatus;

+ (void)addInvitationStatusObserver:(id<ZMInvitationStatusObserver>)observer;
+ (void)removeInvitationStatusObserver:(id<ZMInvitationStatusObserver>)observer;

@end


@protocol ZMIncomingPersonalInvitationObserverToken <NSObject>
@end


@interface ZMUserSession (ZMIncomingPersonalInvitation)

+ (id<ZMIncomingPersonalInvitationObserverToken>)addIncomingPersonalInvitationObserver:(id<ZMIncomingPersonalInvitationObserver>)observer;
+ (void)removeIncomingPersonalInvitationObserverForToken:(id<ZMIncomingPersonalInvitationObserverToken>)token;

@end
