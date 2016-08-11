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


@import Cryptobox;

#import "ZMConversation+OTR.h"
#import "ZMUser.h"
#import "ZMConversation+Internal.h"
#import "ZMMessage+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "ZMOtrMessage.h"
#import <ZMCDataModel/ZMCDataModel-Swift.h>


@interface ZMConversation (OTRInternal)

- (NSDate *)timestampBeforeMessage:(ZMMessage *)message;
- (NSDate *)timestampAfterMessage:(ZMMessage *)message;
- (ZMSystemMessage *)appendSystemMessageOfType:(ZMSystemMessageType)type
                                        sender:(ZMUser *)sender
                                         users:(NSSet*)users
                                       clients:(NSSet*)clients
                                     timestamp:(NSDate *)timestamp
                                 outInsertedAtIndex:(NSUInteger*)index;

@end




@implementation ZMConversation (OTRInternal)

- (NSDate *)timestampBeforeMessage:(ZMMessage *)message
{
    NSDate *timestamp = message.serverTimestamp ?: self.lastModifiedDate;
    return [timestamp dateByAddingTimeInterval:-0.01];
}

- (NSDate *)timestampAfterMessage:(ZMMessage *)message
{
    NSDate *timestamp = message.serverTimestamp ?: self.lastModifiedDate;
    return [timestamp dateByAddingTimeInterval:0.01];
}

- (ZMSystemMessage *)appendSystemMessageOfType:(ZMSystemMessageType)type
                                        sender:(ZMUser *)sender
                                         users:(NSSet*)users
                                       clients:(NSSet*)clients
                                     timestamp:(NSDate *)timestamp
                                 outInsertedAtIndex:(NSUInteger*)index
{
    ZMSystemMessage *systemMessage = [ZMSystemMessage insertNewObjectInManagedObjectContext:self.managedObjectContext];
    systemMessage.systemMessageType = type;
    systemMessage.sender = sender;
    systemMessage.isEncrypted = NO;
    systemMessage.isPlainText = YES;
    systemMessage.users = users;
    systemMessage.clients = clients;
    systemMessage.nonce = [NSUUID new];
    systemMessage.serverTimestamp = timestamp;
    
    NSUInteger insertedIndex = [self sortedAppendMessage:systemMessage];
    if (nil != index) {
        *index = insertedIndex;
    }

    systemMessage.visibleInConversation = self;
    return systemMessage;
    
}

@end




@implementation ZMConversation (OTR)

@dynamic securityLevel;

// trusted conversation have all active users clients trusted
// true corresponds to ZMCovnersationSecurityLevelSecure
// false corresponds to ZMConversationSecurityLevelPartialSecure
- (BOOL)trusted
{
    __block BOOL hasOnlyTrustedUsers = YES;
    [self.activeParticipants.array enumerateObjectsUsingBlock:^(ZMUser *user, NSUInteger idx, BOOL * _Nonnull stop) {
        NOT_USED(idx);
        if (![user trusted]) {
            hasOnlyTrustedUsers = NO;
            *stop = YES;
        }
    }];
    
    return hasOnlyTrustedUsers && !self.containsUnconnectedParticipant;
}

- (BOOL)containsUnconnectedParticipant
{
    for (ZMUser *user in self.otherActiveParticipants) {
        if (!user.isConnected) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)allParticipantsHaveClients
{
    for(ZMUser *user in self.activeParticipants) {
        if(user.clients.count == 0) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)hasUntrustedClients
{
    __block BOOL hasUntrustedClients = NO;
    [self.activeParticipants.array enumerateObjectsUsingBlock:^(ZMUser *user, NSUInteger idx, BOOL * _Nonnull stop) {
        NOT_USED(idx);
        if ([user untrusted]) {
            hasUntrustedClients = YES;
            *stop = YES;
        }
    }];
    
    return hasUntrustedClients;
}

- (void)increaseSecurityLevelIfNeededAfterUserClientsWereTrusted:(NSSet<UserClient *> *)trustedClients;
{
    //if conversation became trusted
    //that will trigger ui notification
    //and add system message that conversation is now trusted
    
    if ([self trusted] && [self allParticipantsHaveClients]) {
        ZMConversationSecurityLevel previousSecurityLevel = self.securityLevel;
        self.securityLevel = ZMConversationSecurityLevelSecure;
        if (previousSecurityLevel != ZMConversationSecurityLevelSecure) {
            [self appendNewIsSecureSystemMessageWithClientsVerified:trustedClients];
            [self.managedObjectContext.zm_userInterfaceContext performGroupedBlock:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:ZMConversationIsVerifiedNotificationName object:self];
            }];
        }
    }
}

- (void)increaseSecurityLevelIfNeededAfterRemovingClientForUser:(ZMUser *)user;
{
    if ([self trusted] && [self allParticipantsHaveClients]) {
        ZMConversationSecurityLevel previousSecurityLevel = self.securityLevel;
        self.securityLevel = ZMConversationSecurityLevelSecure;
        if (previousSecurityLevel != ZMConversationSecurityLevelSecure) {
            [self appendNewIsSecureSystemMessageWithClientsVerified:[NSSet set] forUsers:[NSSet setWithObject:user]];
            [self.managedObjectContext.zm_userInterfaceContext performGroupedBlock:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:ZMConversationIsVerifiedNotificationName object:self];
            }];
        }
    }
}

- (void)decreaseSecurityLevelIfNeededAfterUserClientsWereDiscovered:(NSSet<UserClient *> *)ignoredClients causedBy:(ZMOTRMessage *)message;
{
    if (![self trusted] && self.securityLevel == ZMConversationSecurityLevelSecure) {
        ZMConversationSecurityLevel previousSecurityLevel = self.securityLevel;
        self.securityLevel = ZMConversationSecurityLevelSecureWithIgnored;
        // we need to append system message only the first time some client is being ignored
        if (previousSecurityLevel == ZMConversationSecurityLevelSecure) {
            if (nil != message) {
                [self appendNewAddedClientsSystemMessageWithClients:ignoredClients beforeMessage:message];
                if(message.deliveryState != ZMDeliveryStateDelivered) { // we were trying to send this message
                    [self expireAllPendingMessagesStartingFrom:message]; // then we should display a security warning and block the message
                }
            }
            else {
                [self appendNewAddedClientsSystemMessageWithClients:ignoredClients];
            }
        }
    }
}

- (void)decreaseSecurityLevelIfNeededAfterUserClientsWereIgnored:(NSSet<UserClient *> *)ignoredClients
{
    if (![self trusted] && self.securityLevel == ZMConversationSecurityLevelSecure) {
        ZMConversationSecurityLevel previousSecurityLevel = self.securityLevel;
        self.securityLevel = ZMConversationSecurityLevelSecureWithIgnored;
        // we need to append system message only the first time some client is being ignored
        if (previousSecurityLevel == ZMConversationSecurityLevelSecure) {
            [self appendIgnoredClientsSystemMessageWithClients:ignoredClients];
        }
    }
}

- (void)appendNewAddedClientsSystemMessageWithClients:(NSSet <UserClient*> *)clients
{
    [self appendNewAddedClientsSystemMessageWithClients:clients beforeMessage:nil];
}

- (void)appendNewAddedClientsSystemMessageWithClients:(NSSet <UserClient*> *)clients beforeMessage:(ZMOTRMessage *)beforeMessage
{
    if (clients.count == 0) { return; }
    
    NSSet <ZMUser *>* users = [clients mapWithBlock:^ZMUser *(UserClient* obj) {
        return obj.user;
    }];
    
    NSDate *timeStamp;
    if (beforeMessage == nil || beforeMessage.conversation != self) {
        timeStamp = [self timestampAfterMessage:self.messages.lastObject];
    }
    else {
        //substract 1/10 of a second just to make this message to appear _before_ client message that caused it
        //client message should be already appended at this point
        timeStamp = [self timestampBeforeMessage:beforeMessage];
    }
    NSUInteger index;
    [self appendSystemMessageOfType:ZMSystemMessageTypeNewClient
                             sender:[ZMUser selfUserInContext:self.managedObjectContext]
                              users:users
                            clients:clients
                          timestamp:timeStamp
                      outInsertedAtIndex:&index];
}

- (void)appendNewIsSecureSystemMessageWithClientsVerified:(NSSet <UserClient*> *)clients
{
    NSSet <ZMUser *>* users = [clients mapWithBlock:^ZMUser *(UserClient* obj) {
        return obj.user;
    }];
    [self appendNewIsSecureSystemMessageWithClientsVerified:clients forUsers:users];
}

- (void)appendNewIsSecureSystemMessageWithClientsVerified:(NSSet <UserClient*> *)clients forUsers:(NSSet<ZMUser*> *)users
{
    if (users.count == 0) {return;}
    if (self.securityLevel == ZMConversationSecurityLevelSecureWithIgnored) { return; }
    
    ZMMessage *lastMessage = self.messages.lastObject;
    NSUInteger index;
    [self appendSystemMessageOfType:ZMSystemMessageTypeConversationIsSecure
                             sender:[ZMUser selfUserInContext:self.managedObjectContext]
                              users:users
                            clients:clients
                          timestamp:[self timestampAfterMessage:lastMessage]
                      outInsertedAtIndex:&index];
}

- (void)appendIgnoredClientsSystemMessageWithClients:(NSSet <UserClient *> *)clients;
{
    if (clients.count == 0) { return; }
    
    
    NSSet <ZMUser *>* users = [clients mapWithBlock:^ZMUser *(UserClient* obj) {
        return obj.user;
    }];
    
    ZMMessage *lastMessage = self.messages.lastObject;
    NSUInteger index;
    [self appendSystemMessageOfType:ZMSystemMessageTypeIgnoredClient
                             sender:[ZMUser selfUserInContext:self.managedObjectContext]
                              users:users
                            clients:clients
                          timestamp:[self timestampAfterMessage:lastMessage]
                      outInsertedAtIndex:&index];
}

- (void)expireAllPendingMessagesStartingFrom:(ZMMessage * __unused)message {
    [self.messages enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(ZMMessage *msg, __unused NSUInteger idx, BOOL *stop) {
        if (msg.deliveryState != ZMDeliveryStateDelivered) {
            [msg expire];
        }
        if(msg == message) {
            *stop = YES;
        }
    }];
}

// MARK : New Device SystemMessages

- (void)appendStartedUsingThisDeviceMessageIfNeeded
{
    ZMMessage *systemMessage = [ZMSystemMessage fetchStartedUsingOnThisDeviceMessageForConversation:self];
    if (systemMessage == nil) {
        [self appendStartedUsingThisDeviceMessage];
    }
}

- (void)appendStartedUsingThisDeviceMessage
{
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    UserClient *selfClient = [ZMUser selfUserInContext:self.managedObjectContext].selfClient;
    if (selfClient != nil) {
        NSUInteger index;
        [self appendSystemMessageOfType:ZMSystemMessageTypeUsingNewDevice
                                 sender:selfUser
                                  users:[NSSet setWithObject:selfUser]
                                clients:[NSSet setWithObject:selfClient]
                              timestamp:[self timestampAfterMessage:self.messages.lastObject]
                          outInsertedAtIndex:&index];
    }
}

- (void)appendContinuedUsingThisDeviceMessage
{
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    UserClient *selfClient = selfUser.selfClient;
    if (selfClient == nil) {
        return;
    }
    NSUInteger index;
    [self appendSystemMessageOfType:ZMSystemMessageTypeReactivatedDevice
                             sender:selfUser
                              users:[NSSet setWithObject:selfUser]
                            clients:[NSSet setWithObject:selfClient]
                          timestamp:[NSDate date]
                      outInsertedAtIndex:&index];
}

- (void)appendNewPotentialGapSystemMessageWithUsers:(NSSet <ZMUser *> *)users timestamp:(NSDate *)timestamp
{
    NSUInteger index = 0;
    ZMSystemMessage *systemMessage = [self appendSystemMessageOfType:ZMSystemMessageTypePotentialGap
                                                              sender: [ZMUser selfUserInContext:self.managedObjectContext]
                                                               users:users
                                                             clients:nil
                                                           timestamp:timestamp
                                                       outInsertedAtIndex:&index];
    systemMessage.needsUpdatingUsers = YES;
    
    
    if (index > 1) {
        ZMSystemMessage *previousMessage = self.messages[index - 1];
        if ([previousMessage isKindOfClass:[ZMSystemMessage class]]) {
            [self updatePotentialGapSystemMessage:systemMessage ifNeededWithMessage:previousMessage];
        }
    }
}

- (void)updatePotentialGapSystemMessage:(ZMSystemMessage *)systemMessage ifNeededWithMessage:(ZMSystemMessage *)message
{
    // In case the message before the new system message was also a system message of
    // the type ZMSystemMessageTypePotentialGap, we delete the old one and update the
    // users property of the new one to use old users and calculate the added / removed users
    // from the time the previous one was added
    
    if (systemMessage.systemMessageType != ZMSystemMessageTypePotentialGap) {
        return;
    }
    
    if (message.systemMessageType == ZMSystemMessageTypePotentialGap) {
        id <ZMSystemMessageData> previousSystemMessage = message.systemMessageData;
        systemMessage.users = previousSystemMessage.users.copy;
        [self.managedObjectContext deleteObject:previousSystemMessage];
    }
}

- (void)appendDecryptionFailedSystemMessageAtTime:(NSDate *)timestamp sender:(ZMUser *)sender client:(UserClient *)client errorCode:(NSInteger)errorCode
{
    ZMSystemMessageType type = (errorCode == CBErrorCodeRemoteIdentityChanged) ? ZMSystemMessageTypeDecryptionFailed_RemoteIdentityChanged : ZMSystemMessageTypeDecryptionFailed;
    NSSet *clients = (client != nil) ? [NSSet setWithObject:client] : [NSSet set];
    NSDate *serverTimestamp = timestamp ?: [self timestampAfterMessage:self.messages.lastObject];

    [self appendSystemMessageOfType:type sender:sender users:nil clients:clients timestamp:serverTimestamp outInsertedAtIndex:nil];
    
}

- (void)appendDeletedForEveryoneSystemMessageWithTimestamp:(NSDate *)timestamp sender:(ZMUser *)sender
{
    [self appendSystemMessageOfType:ZMSystemMessageTypeMessageDeletedForEveryone sender:sender users:nil clients:nil timestamp:timestamp outInsertedAtIndex:nil];
}


@end



@implementation ZMConversation (HotFixes)

- (void)replaceNewClientMessageIfNeededWithNewDeviceMesssage
{
    ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
    if (selfUser.selfClient == nil ) {
        return;
    }
    [self.messages enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(ZMSystemMessage *msg, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx > 2) {
            *stop = YES;
            return;
        }
        if (![msg isKindOfClass:ZMSystemMessage.class] || msg.systemMessageType != ZMSystemMessageTypeNewClient || msg.sender != selfUser) {
            return;
        }
        
        if ([msg.clients containsObject:selfUser.selfClient]) {
            msg.systemMessageType = ZMSystemMessageTypeUsingNewDevice;
            *stop = YES;
        }
    }];
}

@end

