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


@import Foundation;
@import WireUtilities;
@import WireSystem;

#import "ZMEditableUser.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "ZMUser+Internal.h"

@interface ZMCompleteRegistrationUser ()

@property (nonatomic, copy) NSString *emailAddress;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, copy) NSString *phoneVerificationCode;
@property (nonatomic, copy) NSString *invitationCode;

@end



@implementation ZMCompleteRegistrationUser

@synthesize name = _name;
@synthesize accentColorValue = _accentColorValue;
@synthesize phoneNumber = _phoneNumber;
@synthesize profileImageData = _profileImageData;

+ (instancetype)registrationUserWithEmail:(NSString *)email password:(NSString *)password
{
    ZMCompleteRegistrationUser *user = [[ZMCompleteRegistrationUser alloc] init];
    [ZMEmailAddressValidator validateValue:&email error:nil];
    user.emailAddress = email;
    user.password = password;
    return user;
}

+ (instancetype)registrationUserWithPhoneNumber:(NSString *)phoneNumber phoneVerificationCode:(NSString *)phoneVerificationCode
{
    ZMCompleteRegistrationUser *user = [[ZMCompleteRegistrationUser alloc] init];
    user.phoneVerificationCode = phoneVerificationCode;
    [ZMPhoneNumberValidator validateValue:&phoneNumber error:nil];
    user.phoneNumber = phoneNumber;
    return user;
}

+ (instancetype)registrationUserWithEmail:(NSString *)email password:(NSString *)password invitationCode:(NSString *)invitationCode
{
    ZMCompleteRegistrationUser *user = [[ZMCompleteRegistrationUser alloc] init];
    [ZMEmailAddressValidator validateValue:&email error:nil];
    user.emailAddress = email;
    user.password = password;
    user.invitationCode = invitationCode;
    return user;
}

+ (instancetype)registrationUserWithPhoneNumber:(NSString *)phoneNumber invitationCode:(NSString *)invitationCode
{
    ZMCompleteRegistrationUser *user = [[ZMCompleteRegistrationUser alloc] init];
    user.phoneNumber = phoneNumber;
    user.invitationCode = invitationCode;
    return user;
}

@end


@implementation ZMIncompleteRegistrationUser

@synthesize name = _name;
@synthesize accentColorValue = _accentColorValue;
@synthesize phoneNumber = _phoneNumber;
@synthesize profileImageData = _profileImageData;

/// This will assert if the email - password - phone - phoneVerificationCode is not set up properly.
- (ZMCompleteRegistrationUser *)completeRegistrationUser
{
    RequireString((self.emailAddress != nil && self.password != nil) || (self.phoneNumber != nil && (self.phoneVerificationCode != nil) || self.invitationCode != nil), "Registration user is not complete");
    
    ZMCompleteRegistrationUser *user;
    if(self.emailAddress != nil) {
        user = [ZMCompleteRegistrationUser registrationUserWithEmail:self.emailAddress password:self.password];
    }
    else if(self.phoneNumber != nil) {
        user = [ZMCompleteRegistrationUser registrationUserWithPhoneNumber:self.phoneNumber phoneVerificationCode:self.phoneVerificationCode];
    }
    Require(user);
    
    user.name = self.name;
    user.accentColorValue = self.accentColorValue;
    user.profileImageData = self.profileImageData;
    user.invitationCode = self.invitationCode;
    return user;
}

@end


@implementation ZMIncompleteRegistrationUser (KeyValueValidation)

- (BOOL)validateEmailAddress:(NSString **)ioEmailAddress error:(NSError **)outError
{
    return [ZMUser validateEmailAddress:ioEmailAddress error:outError];
}

- (BOOL)validateName:(NSString **)ioName error:(NSError **)outError
{
    return [ZMUser validateName:ioName error:outError];
}

- (BOOL)validateAccentColorValue:(NSNumber **)ioAccent error:(NSError **)outError
{
    return [ZMUser validateAccentColorValue:ioAccent error:outError];
}

- (BOOL)validatePhoneNumber:(NSString **)ioPhoneNumber error:(NSError **)outError
{
    return [ZMUser validatePhoneNumber:ioPhoneNumber error:outError];
}

- (BOOL)validatePassword:(NSString **)ioPassword error:(NSError **)outError
{
    return [ZMUser validatePassword:ioPassword error:outError];
}

- (BOOL)validatePhoneVerificationCode:(NSString **)ioPhoneVerificationCode error:(NSError **)outError
{
    return [ZMUser validatePhoneVerificationCode:ioPhoneVerificationCode error:outError];
}

@end

