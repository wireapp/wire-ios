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


@class ZMUserSession;
@class ZMConversation;


typedef NS_ENUM(int64_t, ZMInvitationStatus) {
    ZMInvitationStatusNone = 0,
    ZMInvitationStatusPending,  // is being sent by BE
    ZMInvitationStatusConnectionRequestSent,
    ZMInvitationStatusSent,     // is already sent by BE
    ZMInvitationStatusFailed,   // sending failed
};


NS_ASSUME_NONNULL_BEGIN
@interface ZMAddressBookContact : NSObject

@property (nonatomic, readonly) NSString *name;

@property (nonatomic, copy, nullable) NSString *firstName;
@property (nonatomic, copy, nullable) NSString *middleName;
@property (nonatomic, copy, nullable) NSString *lastName;
@property (nonatomic, copy, nullable) NSString *nickname;
@property (nonatomic, copy, nullable) NSString *organization;

@property (nonatomic, copy) NSArray *emailAddresses;
@property (nonatomic, copy) NSArray *phoneNumbers;

/// a list of contact field to send invitation to (currently its both phone numbers and emails)
@property (nonatomic, readonly) NSArray *contactDetails;

/// Returns YES if an invitation has been sent to one of the contact's email addresses or phone numbers.
- (BOOL)hasBeenInvitedInUserSession:(ZMUserSession *)userSession;

/// Returns YES if an invitation has been sent to one of the contact's email addresses or phone numbers,
/// BE discovered that this is a Wire user, and created connection request to him/her/it.
- (BOOL)requestedConnectionInUserSession:(ZMUserSession *)userSession;

/// Sends invite to a contact
/// @param email - email address to send invitation to.
/// @param conversation - (optional) - a group conversation, to which invitee will be added once he/she accepts the invitation
/// @param userSession - a user session
/// @result BOOL - if the invitation was created or not. E.g. if invitation already exists, and it was evaluated to be a connection reques, there is no way to send it again;
- (BOOL)inviteWithEmail:(NSString *)emailAddress
    toGroupConversation:(nullable ZMConversation *)conversation
            userSession:(ZMUserSession *)userSession;

/// Sends invite to a contact
/// @param email - email address to send invitation to.
/// @param conversation - (optional) - a group conversation, to which invitee will be added once he/she accepts the invitation
/// @param userSession - a user session
/// @result BOOL - if the invitation was created or not. E.g. if invitation already exists, and it was evaluated to be a connection reques, there is no way to send it again;
- (BOOL)inviteWithPhoneNumber:(NSString *)phoneNumber
          toGroupConversation:(nullable ZMConversation *)conversation
                  userSession:(ZMUserSession *)userSession;
@end
NS_ASSUME_NONNULL_END
