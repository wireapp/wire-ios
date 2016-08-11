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


#import "ZMConversation.h"
#import "ZMConversationSecurityLevel.h"

@class ZMOTRMessage;

@interface ZMConversation (OTR)

/// Contains current security level of conversation.
///Client should check this property to properly annotate conversation.
@property (nonatomic, readonly) ZMConversationSecurityLevel securityLevel;

/// Should be called when client is trusted
- (void)increaseSecurityLevelIfNeededAfterUserClientsWereTrusted:(NSSet<UserClient *> *)trustedClients;

/// Should be called when client is deleted
- (void)increaseSecurityLevelIfNeededAfterRemovingClientForUser:(ZMUser *)user;

/// Should be called when a new client is discovered
- (void)decreaseSecurityLevelIfNeededAfterUserClientsWereDiscovered:(NSSet<UserClient *> *)ignoredClients causedBy:(ZMOTRMessage *)message;

/// Should be called when a client is ignored
- (void)decreaseSecurityLevelIfNeededAfterUserClientsWereIgnored:(NSSet<UserClient *> *)ignoredClients;

/// Creates system message that says that you started using this device, if you was not registered on this device
- (void)appendStartedUsingThisDeviceMessage;
- (void)appendStartedUsingThisDeviceMessageIfNeeded;

/// Creates a system message when a device ahs previously been used before, but was logged out due to invalid cookie and/ or invalidated client
- (void)appendContinuedUsingThisDeviceMessage;

- (void)appendNewPotentialGapSystemMessageWithUsers:(NSSet <ZMUser *> *)users timestamp:(NSDate *)timestamp;

/// Creates the message that warns user about the fact that decryption of incoming message is failed
- (void)appendDecryptionFailedSystemMessageAtTime:(NSDate *)timestamp sender:(ZMUser *)sender client:(UserClient *)client errorCode:(NSInteger)errorCode;

- (void)appendDeletedForEveryoneSystemMessageWithTimestamp:(NSDate *)timestamp sender:(ZMUser *)sender;

@end



@interface ZMConversation (HotFixes)

/// Replaces the first NewClient systemMessage for the selfClient with a UsingNewDevice system message
- (void)replaceNewClientMessageIfNeededWithNewDeviceMesssage;

@end
