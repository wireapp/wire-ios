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


@import WireSystem;

#import <WireUtilities/ZMAccentColor.h>
#import "ZMUser.h"

@class ZMEmailCredentials;
@class ZMPhoneCredentials;

@protocol ZMEditableUser <NSObject>

@property (nonatomic, copy) NSString *name;
@property (nonatomic) ZMAccentColor accentColorValue;
@property (nonatomic, copy, readonly) NSString *emailAddress;
@property (nonatomic, copy, readonly) NSString *phoneNumber;

@end


@interface ZMCompleteRegistrationUser : NSObject <ZMEditableUser>

@property (nonatomic, readonly, copy) NSString *emailAddress;
@property (nonatomic, readonly, copy) NSString *password;
@property (nonatomic, readonly, copy) NSString *phoneNumber;
@property (nonatomic, readonly, copy) NSString *phoneVerificationCode;
@property (nonatomic, readonly, copy) NSString *invitationCode;
@property (nonatomic, copy) NSData *profileImageData;

+ (instancetype)registrationUserWithEmail:(NSString *)email password:(NSString *)password;
+ (instancetype)registrationUserWithPhoneNumber:(NSString *)phoneNumber phoneVerificationCode:(NSString *)phoneVerificationCode;
+ (instancetype)registrationUserWithEmail:(NSString *)email password:(NSString *)password invitationCode:(NSString *)invitationCode;
+ (instancetype)registrationUserWithPhoneNumber:(NSString *)phoneNumber invitationCode:(NSString *)invitationCode;

@end



@interface ZMIncompleteRegistrationUser : NSObject <ZMEditableUser>

@property (nonatomic, copy) NSString *emailAddress;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, copy) NSString *phoneVerificationCode;
@property (nonatomic, copy) NSString *invitationCode;
@property (nonatomic, copy) NSData *profileImageData;

/// This will assert if the email - password - phone - phoneVerificationCode is not set up properly.
- (ZMCompleteRegistrationUser *)completeRegistrationUser;

@end

