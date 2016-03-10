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


#import "ZMManagedObject.h"
#import "ZMAddressBookContact.h"

@class ZMManagedObject;
@class ZMUser;
@class ZMConversation;


NS_ASSUME_NONNULL_BEGIN
@interface ZMPersonalInvitation : ZMManagedObject

@property (nonatomic, readonly, nullable) NSString *inviteeEmail;
@property (nonatomic, readonly, nullable) NSString *inviteePhoneNumber;
@property (nonatomic, readonly, nullable) NSString *inviteeName;
@property (nonatomic, readonly, nullable) NSDate *serverTimestamp;
@property (nonatomic, readonly) ZMUser *inviter;
@property (nonatomic, readonly, nullable) ZMConversation *conversation;
@property (nonatomic, readonly) ZMInvitationStatus status;
@property (nonatomic, nullable) NSString *message;

@end
NS_ASSUME_NONNULL_END
