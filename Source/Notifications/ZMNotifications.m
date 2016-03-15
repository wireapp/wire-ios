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
@import ZMTransport;

#import "ZMNotifications+Internal.h"

#import "ZMConversation+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMTracing.h"
#import "ZMSearchUser+Internal.h"
#import "ZMConversationList+Internal.h"
#import "ZMChangedIndexes.h"
#import "ZMOrderedSetState.h"
#import "ZMConnection.h"
#import "ZMConversationList+Internal.h"
#import "ZMUserSession+Internal.h"

#import <zmessaging/zmessaging-Swift.h>

static NSString *const ZMNetworkAvailabilityChangeNotificationName = @"ZMNetworkAvailabilityChangeNotification";
static NSString *const ZMCallEndedNotificationName = @"ZMCallEndedNotification";
static NSString *const ZMTypingChangeNotificationName = @"ZMTypingChangeNotification";
static NSString *const ZMConnectionLimitReachedNotificationName = @"ZMConnectionLimitReachedNotification";
static NSString *const ZMInitialSyncCompletedNotificationName = @"ZMInitialSyncCompletedNotification";
static NSString *const ZMInvitationStatusChangedNotificationName = @"ZMInvitationStatusChangedNotification";
static NSString *const ZMIncomingPersonalInvitationNotificationName = @"ZMIncomingPersonalInvitationNotification";


@interface ZMNotification ()

@property (nonatomic, readonly) id baseObject;
@property (nonatomic, readonly, copy) NSString* baseName;

- (instancetype)initWithName:(NSString *)name object:(id)object;

@end

@interface ZMNetworkAvailabilityChangeNotification ()

@property (nonatomic) ZMNetworkState networkState;
@property (nonatomic, weak) ZMUserSession *userSession;

@end


@implementation ZMNotification

- (instancetype)initWithName:(NSString *)name object:(id)object;
{
    // Don't call [super init], NSNotification can't handle that
    _baseObject = object;
    _baseName = name;
    return self;
}

- (id)object;
{
    return self.baseObject;
}

- (NSString *)name;
{
    return self.baseName;
}

- (NSDictionary *)userInfo;
{
    return nil;
}

@end



@implementation ZMMovedIndex

+ (instancetype)movedIndexFrom:(NSUInteger)from to:(NSUInteger)to
{
    ZMMovedIndex *movedIndex = [[self alloc] init];
    movedIndex->_from = from;
    movedIndex->_to = to;
    return movedIndex;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:ZMMovedIndex.class]) {
        return NO;
    }
    
    ZMMovedIndex *other = (ZMMovedIndex *)object;
    return other.from == self.from && other.to == self.to;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"From %lu to %lu", (unsigned long)self.from, (unsigned long)self.to];
}

- (NSString *)description {
    return self.debugDescription;
}

- (NSUInteger)hash
{
    return (13 * self.from + 541 * self.to);
}
@end


@implementation ZMUserSession (InternalNotifications)

+ (void)notifyInitialSyncCompleted
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ZMInitialSyncCompletedNotificationName object:nil];
    });
}

@end


@implementation ZMUserSession (ZMInitialSyncCompletion)

+ (void)addInitalSyncCompletionObserver:(id<ZMInitialSyncCompletionObserver>)observer
{
    ZM_ALLOW_MISSING_SELECTOR(
                              [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(initialSyncCompleted:) name:ZMInitialSyncCompletedNotificationName object:nil]
                              );
}

+ (void)removeInitalSyncCompletionObserver:(id<ZMInitialSyncCompletionObserver>)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:ZMInitialSyncCompletedNotificationName object:nil];
}

@end

@implementation ZMUserSession (ZMIncomingPersonalInvitation)

+ (id<ZMIncomingPersonalInvitationObserverToken>)addIncomingPersonalInvitationObserver:(id<ZMIncomingPersonalInvitationObserver>)observer
{
    return [ZMIncomingPersonalInvitationNotification addObserverWithBlock:^(ZMIncomingPersonalInvitationNotification *note) {
        switch (note.type) {
            case ZMIncomingPersonalInvitationNotificationTypeDidNotFindInvitation:
                [observer didNotFindPersonalInvitation];
                break;
                
            case ZMIncomingPersonalInvitationNotificationTypeWillFetchInvitation:
                [observer willFetchPersonalInvitation];
                break;
                
            case ZMIncomingPersonalInvitationNotificationTypeDidFailToFetchInvitation:
                [observer didFailToFetchPersonalInvitationWithError:note.error];
                break;
                
            case ZMIncomingPersonalInvitationNotificationTypeDidReceiveInvitationToRegisterAsUser:
                [observer didReceiveInvitationToRegisterAsUser:note.user];
                break;
        }
    }];
}

+ (void)removeIncomingPersonalInvitationObserverForToken:(id<ZMIncomingPersonalInvitationObserverToken>)token
{
    [[NSNotificationCenter defaultCenter] removeObserver:token];
}

@end


@implementation ZMConversationMessageWindow (Notifications)


- (id<ZMConversationMessageWindowObserverOpaqueToken>)addConversationWindowObserver:(id<ZMConversationMessageWindowObserver>)observer;
{
    return (id) [self.conversation.managedObjectContext.globalManagedObjectContextObserver addConversationWindowObserver:observer window:self];
}


- (void)removeConversationWindowObserverToken:(id<ZMConversationMessageWindowObserverOpaqueToken>)token
{
    [self.conversation.managedObjectContext.globalManagedObjectContextObserver removeConversationWindowObserverForToken:(id)token];
    [(MessageWindowChangeToken *)token tearDown];
}


@end



@implementation ZMNetworkAvailabilityChangeNotification

+ (instancetype)notificationWithNetworkState:(ZMNetworkState)networkState userSession:(ZMUserSession *)session;
{
    ZMNetworkAvailabilityChangeNotification *note = [[ZMNetworkAvailabilityChangeNotification alloc] initWithName:ZMNetworkAvailabilityChangeNotificationName object:session];
    if(note) {
        note.networkState = networkState;
        note.userSession = session;
    }
    return note;
}

+ (void)addNetworkAvailabilityObserver:(id<ZMNetworkAvailabilityObserver>)delegate userSession:(ZMUserSession *)session
{
    ZM_ALLOW_MISSING_SELECTOR
    ([[NSNotificationCenter defaultCenter] addObserver:delegate selector:@selector(didChangeAvailability:) name:ZMNetworkAvailabilityChangeNotificationName object:session]);
}

+ (void)removeNetworkAvailabilityObserver:(id<ZMNetworkAvailabilityObserver>)delegate
{
    [[NSNotificationCenter defaultCenter] removeObserver:delegate name:ZMNetworkAvailabilityChangeNotificationName object:nil];
}

@end



@implementation ZMTypingChangeNotification : ZMNotification

+ (instancetype)notificationWithConversation:(ZMConversation *)conversation typingUser:(NSSet *)typingUsers;
{
    ZMTypingChangeNotification *note = [[self alloc] initWithName:ZMTypingChangeNotificationName object:conversation];
    note.typingUsers = [typingUsers copy];
    return note;
}

- (ZMConversation *)conversation
{
    return self.object;
}

@end



@implementation ZMConversation (TypingNotification)

- (void)addTypingObserver:(id<ZMTypingChangeObserver>)observer;
{
    ZM_ALLOW_MISSING_SELECTOR
    ([[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(typingDidChange:) name:ZMTypingChangeNotificationName object:self]);
}

+ (void)removeTypingObserver:(id<ZMTypingChangeObserver>)observer;
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:ZMTypingChangeNotificationName object:nil];
}

@end


@implementation ZMConversationList (ListChangeNotification)

- (id<ZMConversationListObserverOpaqueToken>)addConversationListObserver:(id<ZMConversationListObserver>)observer;
{
    return [self.managedObjectContext.globalManagedObjectContextObserver addConversationListObserver:observer conversationList:self];
}

- (void)removeConversationListObserverForToken:(id<ZMConversationListObserverOpaqueToken>)token;
{
    [self.managedObjectContext.globalManagedObjectContextObserver removeConversationListObserverForToken:token];
}

@end


@implementation ZMConversation (Observer)

- (id<ZMConversationObserverOpaqueToken>)addConversationObserver:(id<ZMConversationObserver>)observer;
{
    return (id)[[ConversationObserverToken alloc] initWithObserver:observer conversation:self];
}

+ (void)removeConversationObserverForToken:(id<ZMConversationObserverOpaqueToken>)token;
{
    [(ConversationObserverToken *)token tearDown];
}

@end



@implementation ZMMessageNotification

+ (id<ZMMessageObserverOpaqueToken>)addMessageObserver:(id<ZMMessageObserver>)observer forMessage:(id<ZMConversationMessage>)conversationMessage;
{
    return (id) [[MessageObserverToken alloc] initWithObserver: observer object:conversationMessage];
}

+ (void)removeMessageObserverForToken:(id<ZMMessageObserverOpaqueToken>)token;
{
    [(MessageObserverToken *)token tearDown];
}

+ (id<ZMNewUnreadMessageObserverOpaqueToken>)addNewMessagesObserver:(id<ZMNewUnreadMessagesObserver>)observer managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    return (id)[managedObjectContext.globalManagedObjectContextObserver addNewUnreadMessagesObserver:observer];

}
+ (void)removeNewMessagesObserverForToken:(id<ZMNewUnreadMessageObserverOpaqueToken>)token managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    [managedObjectContext.globalManagedObjectContextObserver removeMessageObserver:token];
 }

+ (id<ZMNewUnreadKnockMessageObserverOpaqueToken>)addNewKnocksObserver:(id<ZMNewUnreadKnocksObserver>)observer managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    return (id)[managedObjectContext.globalManagedObjectContextObserver addNewUnreadKnocksObserver:observer];
}

+ (void)removeNewKnocksObserverForToken:(id<ZMNewUnreadKnockMessageObserverOpaqueToken>)token managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    [managedObjectContext.globalManagedObjectContextObserver removeMessageObserver:token];
}

+ (id<ZMNewUnreadMessageObserverOpaqueToken>)addNewMessagesObserver:(id<ZMNewUnreadMessagesObserver>)observer inUserSession:(ZMUserSession *)userSession
{
    return (id)[userSession.managedObjectContext.globalManagedObjectContextObserver addNewUnreadMessagesObserver:observer];
    
}
+ (void)removeNewMessagesObserverForToken:(id<ZMNewUnreadMessageObserverOpaqueToken>)token inUserSession:(ZMUserSession *)userSession
{
    [userSession.managedObjectContext.globalManagedObjectContextObserver removeMessageObserver:token];
}

+ (id<ZMNewUnreadKnockMessageObserverOpaqueToken>)addNewKnocksObserver:(id<ZMNewUnreadKnocksObserver>)observer inUserSession:(ZMUserSession *)userSession
{
    return (id)[userSession.managedObjectContext.globalManagedObjectContextObserver addNewUnreadKnocksObserver:observer];
}

+ (void)removeNewKnocksObserverForToken:(id<ZMNewUnreadKnockMessageObserverOpaqueToken>)token inUserSession:(ZMUserSession *)userSession
{
    [userSession.managedObjectContext.globalManagedObjectContextObserver removeMessageObserver:token];
}

+ (id<ZMNewUnreadUnsentMessageObserverOpaqueToken>)addUnreadUnsentMessageObserver:(id<ZMNewUnreadUnsentMessageObserver>)observer inUserSession:(ZMUserSession *)userSession;
{
    return (id)[userSession.managedObjectContext.globalManagedObjectContextObserver addNewUnreadUnsentMessagesObserver:observer];
}

+ (void)removeUnreadUnsentMessageObserverForToken:(id<ZMNewUnreadUnsentMessageObserverOpaqueToken>)token inUserSession:(ZMUserSession *)userSession;
{
    [userSession.managedObjectContext.globalManagedObjectContextObserver removeMessageObserver:token];
}

@end



@implementation ZMUser (ChangeNotification)


+ (void)removeUserObserverForToken:(id<ZMUserObserverOpaqueToken>)token
{
    [(UserCollectionObserverToken *)token tearDown];
}

+ (id<ZMUserObserverOpaqueToken>)addUserObserver:(id<ZMUserObserver>)observer forUsers:(NSArray *)users managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    if (users.count == 0) {
        return nil;
    }
    return (id)[[UserCollectionObserverToken alloc] initWithObserver:observer users:users managedObjectContext:managedObjectContext];
}

+ (id<ZMUserObserverOpaqueToken>)addUserObserver:(id<ZMUserObserver>)observer forUsers:(NSArray *)users inUserSession:(ZMUserSession *)userSession;
{
    return [ZMUser addUserObserver:observer forUsers:users managedObjectContext:userSession.managedObjectContext];
}

@end
    



@implementation ZMSearchUser (ChangeNotification)

+ (void)removeUserObserverForToken:(id<ZMUserObserverOpaqueToken>)token
{
    [ZMUser removeUserObserverForToken:token];
}

+ (id<ZMUserObserverOpaqueToken>)addUserObserver:(id<ZMUserObserver>)observer forUsers:(NSArray *)users managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    return [ZMUser addUserObserver:observer forUsers:users managedObjectContext:managedObjectContext];
}


+ (id<ZMUserObserverOpaqueToken>)addUserObserver:(id<ZMUserObserver>)observer forUsers:(NSArray *)users inUserSession:(ZMUserSession *)userSession;
{
    return [ZMUser addUserObserver:observer forUsers:users managedObjectContext:userSession.managedObjectContext];
}

@end



    
@interface ZMCallEndedNotification ()
@property (nonatomic) ZMVoiceChannelCallEndReason reason;
@end

@implementation ZMCallEndedNotification

+ (instancetype)notificationWithConversation:(ZMConversation *)conversation reason:(ZMVoiceChannelCallEndReason)reason;
{
    ZMCallEndedNotification *note = [[ZMCallEndedNotification alloc] initWithName:ZMCallEndedNotificationName object:conversation];
    note.reason = reason;
    return note;
}

- (ZMConversation *)conversation
{
    return self.object;
}

+ (void)addCallEndObserver:(id<ZMCallEndObserver>)observer
{
    ZM_ALLOW_MISSING_SELECTOR
    ([[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(didEndCall:) name:ZMCallEndedNotificationName object:nil]);
}

+ (void)removeCallEndObserver:(id<ZMCallEndObserver>)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:ZMCallEndedNotificationName object:nil];
}

@end




@implementation ZMConnectionLimitNotification : ZMNotification

+ (instancetype)connectionLimitNotification;
{
    ZMConnectionLimitNotification *note = [[self alloc] initWithName:ZMConnectionLimitReachedNotificationName object:nil];
    return note;
}

+ (void)addConnectionLimitObserver:(id<ZMConnectionLimitObserver>)observer
{
    ZM_ALLOW_MISSING_SELECTOR([[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(connectionLimitReached:) name:ZMConnectionLimitReachedNotificationName object:self]);
}

+ (void)removeConnectionLimitObserver:(id<ZMConnectionLimitObserver>)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:ZMConnectionLimitReachedNotificationName object:self];
}

@end



@implementation ZMInvitationStatusChangedNotification : ZMNotification

+ (instancetype)invitationStatusChangedNotificationForContactEmailAddress:(NSString *)emailAddress status:(ZMInvitationStatus)status
{
    ZMInvitationStatusChangedNotification *note = [self invitationStatusChangedNotificationForStatus:status];
    note.emailAddress = emailAddress;
    return note;
}

+ (instancetype)invitationStatusChangedNotificationForContactPhoneNumber:(NSString *)phoneNumber status:(ZMInvitationStatus)status
{
    ZMInvitationStatusChangedNotification *note = [self invitationStatusChangedNotificationForStatus:status];
    note.phoneNumber = phoneNumber;
    return note;
}

+ (instancetype)invitationStatusChangedNotificationForStatus:(ZMInvitationStatus)status
{
    ZMInvitationStatusChangedNotification *note = [[self alloc] initWithName:ZMInvitationStatusChangedNotificationName object:nil];
    note.newStatus = status;
    return note;
}

+ (void)addInvitationStatusObserver:(id<ZMInvitationStatusObserver>)observer
{
    ZM_ALLOW_MISSING_SELECTOR([[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(invitationStatusChanged:) name:ZMInvitationStatusChangedNotificationName object:nil]);
}

+ (void)removeInvitationStatusObserver:(id<ZMInvitationStatusObserver>)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:ZMInvitationStatusChangedNotificationName object:nil];
}

@end


@interface ZMIncomingPersonalInvitationNotification ()

@property (nonatomic) ZMIncomingPersonalInvitationNotificationType type;
@property (nonatomic) NSError *error;
@property (nonatomic) ZMIncompleteRegistrationUser *user;

@end


@implementation ZMIncomingPersonalInvitationNotification

- (instancetype)init
{
    return [super initWithName:ZMIncomingPersonalInvitationNotificationName object:nil];
}

+ (id<ZMIncomingPersonalInvitationObserverToken>)addObserverWithBlock:(void(^)(ZMIncomingPersonalInvitationNotification *note))block
{
    NSCParameterAssert(block);
    return (id<ZMIncomingPersonalInvitationObserverToken>)[[NSNotificationCenter defaultCenter] addObserverForName:ZMIncomingPersonalInvitationNotificationName object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *note) {
        block((ZMIncomingPersonalInvitationNotification *)note);
    }];
}

+ (void)notifyDidNotFindPersonalInvitation
{
    ZMIncomingPersonalInvitationNotification *note = [[ZMIncomingPersonalInvitationNotification alloc] init];
    note.type = ZMIncomingPersonalInvitationNotificationTypeDidNotFindInvitation;
    [[NSNotificationCenter defaultCenter] postNotification:note];
}

+ (void)notifyWillFetchPersonalInvitation
{
    ZMIncomingPersonalInvitationNotification *note = [[ZMIncomingPersonalInvitationNotification alloc] init];
    note.type = ZMIncomingPersonalInvitationNotificationTypeWillFetchInvitation;
    [[NSNotificationCenter defaultCenter] postNotification:note];
}

+ (void)notifyDidFailFetchPersonalInvitationWithError:(NSError *)error
{
    ZMIncomingPersonalInvitationNotification *note = [[ZMIncomingPersonalInvitationNotification alloc] init];
    note.type = ZMIncomingPersonalInvitationNotificationTypeDidFailToFetchInvitation;
    note.error = error;
    [[NSNotificationCenter defaultCenter] postNotification:note];
}

+ (void)notifyDidReceiveInviteToRegisterAsUser:(ZMIncompleteRegistrationUser *)user
{
    ZMIncomingPersonalInvitationNotification *note = [[ZMIncomingPersonalInvitationNotification alloc] init];
    note.type = ZMIncomingPersonalInvitationNotificationTypeDidReceiveInvitationToRegisterAsUser;
    note.user = user;
    [[NSNotificationCenter defaultCenter] postNotification:note];
}

@end

