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


#import "ZMPersonalInvitation.h"


@class ZMAddressBookContact;


NS_ASSUME_NONNULL_BEGIN
@interface ZMPersonalInvitation (Internal)

@property (nonatomic, readwrite, nullable) NSString *inviteeEmail;
@property (nonatomic, readwrite, nullable) NSString *inviteePhoneNumber;
@property (nonatomic, readwrite, nullable) NSString *inviteeName;
@property (nonatomic, readwrite, nullable) NSDate *serverTimestamp;
@property (nonatomic) NSUUID *remoteIdentifier;
@property (nonatomic, readwrite) ZMUser *inviter;
@property (nonatomic, readwrite, nullable) ZMConversation *conversation;
@property (nonatomic, readwrite) ZMInvitationStatus status;


/// Creates new invitation for user
/// @param user - Inviter user. Should be self user. user.displayName will be displayed in invitation message.
/// @param contact - An address book contact, to which send the invite
/// @param email - email address to send invitation to.
/// @param conversation - (optional) - a group conversation, to which invitee will be added once he/she accepts the invitation
/// @param context - a managed object context to insert object in
+ (instancetype)invitationFromUser:(ZMUser *)user
                         toContact:(ZMAddressBookContact *)contact
                             email:(NSString *)email
                      conversation:(nullable ZMConversation *)conversation
              managedObjectContext:(NSManagedObjectContext *)context;

/// Creates new invitation for user
/// @param user - Inviter user. Should be self user. user.displayName will be displayed in invitation message.
/// @param contact - An address book contact, to which send the invite
/// @param phoneNumber - phone number to send invitation to.
/// @param conversation - (optional) - a group conversation, to which invitee will be added once he/she accepts the invitation
/// @param context - a managed object context to insert object in
+ (instancetype)invitationFromUser:(ZMUser *)user
                         toContact:(ZMAddressBookContact *)contact
                       phoneNumber:(NSString *)phoneNumber
                      conversation:(nullable ZMConversation *)conversation
              managedObjectContext:(NSManagedObjectContext *)context;

/// Fetches invitations sent from a given user to a give contact
/// @param user - Inviter user. Should be self user.
/// @param contact - An address book contact, who is receiver of an searched invitation
/// @param context - a managed object context
+ (NSArray<ZMPersonalInvitation *> *)fetchInvitationsFromUser:(ZMUser *)user
                                                      contact:(ZMAddressBookContact *)addressBookContact
                                         managedObjectContext:(NSManagedObjectContext *)context;

@end
NS_ASSUME_NONNULL_END
