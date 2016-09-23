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


@import ZMCSystem;
@import ZMTransport;

#import "ZMNotifications+Internal.h"

#import "ZMConversation+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMSearchUser+Internal.h"
#import "ZMConversationList+Internal.h"
#import "ZMChangedIndexes.h"
#import "ZMOrderedSetState.h"
#import "ZMConnection.h"
#import "ZMConversationList+Internal.h"

#import <ZMCDataModel/ZMCDataModel-Swift.h>

static NSString *const ZMCallEndedNotificationName = @"ZMCallEndedNotification";
static NSString *const ZMInvitationStatusChangedNotificationName = @"ZMInvitationStatusChangedNotification";
NSString *const ZMDatabaseCorruptionNotificationName = @"ZMDatabaseCorruptionNotification";


@interface ZMNotification ()

@property (nonatomic, readonly) id baseObject;
@property (nonatomic, readonly, copy) NSString* baseName;

- (instancetype)initWithName:(NSString *)name object:(id)object;

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



@implementation ZMConversationMessageWindow (Notifications)


- (id<ZMConversationMessageWindowObserverOpaqueToken>)addConversationWindowObserver:(id<ZMConversationMessageWindowObserver>)observer;
{
    return (id) [self.conversation.managedObjectContext.globalManagedObjectContextObserver addConversationWindowObserver:observer window:self];
}


- (void)removeConversationWindowObserverToken:(id<ZMConversationMessageWindowObserverOpaqueToken>)token
{
    [self.conversation.managedObjectContext.globalManagedObjectContextObserver removeConversationWindowObserverForToken:(id)token];
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
    return [self.managedObjectContext.globalManagedObjectContextObserver addConversationObserver:observer conversation:self];
}

+ (void)removeConversationObserverForToken:(id<ZMConversationObserverOpaqueToken>)token;
{
    [(ConversationObserverToken *)token tearDown];
}

@end



@implementation ZMMessageNotification

+ (id<ZMMessageObserverOpaqueToken>)addMessageObserver:(id<ZMMessageObserver>)observer forMessage:(id<ZMConversationMessage>)conversationMessage;
{
    if ([conversationMessage isKindOfClass:[ZMMessage class]]) {
        return (id) [[MessageObserverToken alloc] initWithObserver: observer object:(ZMMessage *)conversationMessage];
    }
    return nil;
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

+ (id<ZMNewUnreadMessageObserverOpaqueToken>)addNewMessagesObserver:(id<ZMNewUnreadMessagesObserver>)observer inUserSession:(id<ZMManagedObjectContextProvider>)userSession
{
    return (id)[userSession.managedObjectContext.globalManagedObjectContextObserver addNewUnreadMessagesObserver:observer];
    
}
+ (void)removeNewMessagesObserverForToken:(id<ZMNewUnreadMessageObserverOpaqueToken>)token inUserSession:(id<ZMManagedObjectContextProvider>)userSession
{
    [userSession.managedObjectContext.globalManagedObjectContextObserver removeMessageObserver:token];
}

+ (id<ZMNewUnreadKnockMessageObserverOpaqueToken>)addNewKnocksObserver:(id<ZMNewUnreadKnocksObserver>)observer inUserSession:(id<ZMManagedObjectContextProvider>)userSession
{
    return (id)[userSession.managedObjectContext.globalManagedObjectContextObserver addNewUnreadKnocksObserver:observer];
}

+ (void)removeNewKnocksObserverForToken:(id<ZMNewUnreadKnockMessageObserverOpaqueToken>)token inUserSession:(id<ZMManagedObjectContextProvider>)userSession
{
    [userSession.managedObjectContext.globalManagedObjectContextObserver removeMessageObserver:token];
}

+ (id<ZMNewUnreadUnsentMessageObserverOpaqueToken>)addUnreadUnsentMessageObserver:(id<ZMNewUnreadUnsentMessageObserver>)observer inUserSession:(id<ZMManagedObjectContextProvider>)userSession;
{
    return (id)[userSession.managedObjectContext.globalManagedObjectContextObserver addNewUnreadUnsentMessagesObserver:observer];
}

+ (void)removeUnreadUnsentMessageObserverForToken:(id<ZMNewUnreadUnsentMessageObserverOpaqueToken>)token inUserSession:(id<ZMManagedObjectContextProvider>)userSession;
{
    [userSession.managedObjectContext.globalManagedObjectContextObserver removeMessageObserver:token];
}

@end



@implementation ZMUser (ChangeNotification)


+ (void)removeUserObserverForToken:(id<ZMUserObserverOpaqueToken>)token
{
    [(id)token tearDown];
}

+ (id<ZMUserObserverOpaqueToken>)addUserObserver:(id<ZMUserObserver>)observer forUsers:(NSArray *)users managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    if (users.count == 0) {
        return nil;
    }
    return (id)[[UserCollectionObserverToken alloc] initWithObserver:observer users:users managedObjectContext:managedObjectContext];
}

+ (id<ZMUserObserverOpaqueToken>)addUserObserver:(id<ZMUserObserver>)observer forUsers:(NSArray *)users inUserSession:(id<ZMManagedObjectContextProvider>)userSession;
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


+ (id<ZMUserObserverOpaqueToken>)addUserObserver:(id<ZMUserObserver>)observer forUsers:(NSArray *)users inUserSession:(id<ZMManagedObjectContextProvider>)userSession;
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


