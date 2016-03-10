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


@import Foundation;
@import ZMCSystem;

#import "ZMEditableUser.h"
#import "ZMUserProfileUpdateStatus.h"
#import "ZMUserSession+Internal.h"
#import <zmessaging/NSManagedObjectContext+zmessaging.h>
#import "ZMOperationLoop.h"
#import "ZMUser+Internal.h"
#import "ZMPhoneNumberValidator.h"

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
@synthesize originalProfileImageData = _originalProfileImageData;

- (void)deleteProfileImage
{
    
}

+ (instancetype)registrationUserWithEmail:(NSString *)email password:(NSString *)password
{
    ZMCompleteRegistrationUser *user = [[ZMCompleteRegistrationUser alloc] init];
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
@synthesize originalProfileImageData = _originalProfileImageData;

- (void)deleteProfileImage
{
    
}

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
    user.originalProfileImageData = self.originalProfileImageData;
    user.invitationCode = self.invitationCode;
    return user;
}

@end



@implementation ZMUserSession (EditingVerification)

- (NSString *)currentlyUpdatingEmail
{
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self];
    return (selfUser.emailAddress.length == 0) ? self.userProfileUpdateStatus.emailToUpdate : nil;
}

- (NSString *)currentlyUpdatingPhone
{
    ZMUser *selfUser = [ZMUser selfUserInUserSession:self];
    return (selfUser.phoneNumber == nil) ?
        (self.userProfileUpdateStatus.profilePhoneNumberThatNeedsAValidationCode ?: self.userProfileUpdateStatus.phoneCredentialsToUpdate.phoneNumber)
        : nil;
}

/// Send email verification and set the password when user changes/adds email to the existing profile
- (void)requestVerificationEmailForEmailUpdate:(ZMEmailCredentials *)credentials;
{
    [self.syncManagedObjectContext performGroupedBlock:^{
        [self.userProfileUpdateStatus prepareForEmailAndPasswordChangeWithCredentials:credentials];
        [ZMOperationLoop notifyNewRequestsAvailable:self];
    }];
}

/// Send email verification and set the password when user changes/adds email to the existing profile
- (void)requestVerificationCodeForPhoneNumberUpdate:(NSString *)phoneNumber {
    [self.syncManagedObjectContext performGroupedBlock:^{
        [self.userProfileUpdateStatus prepareForRequestingPhoneVerificationCodeForRegistration:phoneNumber];
        [ZMOperationLoop notifyNewRequestsAvailable:self];
    }];
}

/// Verify phone number for profile
- (void)verifyPhoneNumberForUpdate:(ZMPhoneCredentials *)credentials;
{
    [self.syncManagedObjectContext performGroupedBlock:^{
        [self.userProfileUpdateStatus prepareForPhoneChangeWithCredentials:credentials];
        [ZMOperationLoop notifyNewRequestsAvailable:self];
    }];
}

- (id<ZMUserEditingObserverToken>)addUserEditingObserver:(id<ZMUserEditingObserver>)observer {
    
    return (id)[ZMUserProfileUpdateNotification addObserverWithBlock:^(ZMUserProfileUpdateNotification *note) {
        switch(note.type) {
            case ZMUserProfileNotificationEmailUpdateDidFail:
                [observer emailUpdateDidFail:note.error];
                break;
            case ZMUserProfileNotificationPhoneNumberVerificationCodeRequestDidFail:
                [observer phoneNumberVerificationCodeRequestDidFail:note.error];
                break;
            case ZMUserProfileNotificationPhoneNumberVerificationDidFail:
                [observer phoneNumberVerificationDidFail:note.error];
                break;
            case ZMUserProfileNotificationPasswordUpdateDidFail:
                [observer passwordUpdateRequestDidFail];
                break;
            case ZMUserProfileNotificationPhoneNumberVerificationCodeRequestDidSucceed:
                [observer phoneNumberVerificationCodeRequestDidSucceed];
                break;
            case ZMUserProfileNotificationEmailDidSendVerification:
                [observer didSentVerificationEmail];
                break;
        }
    }];
}

- (void)removeUserEditingObserverForToken:(id<ZMUserEditingObserverToken>)observerToken {
    [ZMUserProfileUpdateNotification removeObserver:(id)observerToken];
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

