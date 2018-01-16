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


#import <WireUtilities/ZMAccentColor.h>
#import "ZMBareUser.h"

NS_ASSUME_NONNULL_BEGIN

@class ZMUser, ZMAddressBookContact;
@protocol ServiceUser;

@interface ZMSearchUser : NSObject <ZMBareUser>

/// This property might be nil when there is no existing local user. It is set when connecting to the user.
/// It should therefore only be observed after successful connection
@property (nonatomic, readonly, nullable) ZMUser *user;

/// This property might be nil when there's no matching address book contact. It can also bet set without
/// a matching user if we are searching the address book, in which case the `user` property is nil.
@property (nonatomic, readonly, nullable) ZMAddressBookContact *contact;

@end


@interface ZMSearchUser (Connections) <ZMBareUserConnection>
@end

NS_ASSUME_NONNULL_END
