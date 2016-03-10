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

#import "ZMCredentials.h"
#import "ZMNotifications+Internal.h"
#import <zmessaging/ZMClientRegistrationStatus+Internal.h>


typedef NS_ENUM(NSUInteger, ZMUserProfileUpdatePhases) {
    ZMUserProfilePhaseIdle = 0,
    ZMUserProfilePhaseRequestPhoneVerificationCode,
    ZMUserProfilePhaseChangePassword,
    ZMUserProfilePhaseChangeEmail,
    ZMUserProfilePhaseChangePhone
};

@interface ZMUserProfileUpdateStatus : NSObject

@property (nonatomic, readonly) ZMPhoneCredentials *phoneCredentialsToUpdate;
@property (nonatomic, readonly) NSString *emailToUpdate;
@property (nonatomic, readonly) NSString *passwordToUpdate;
@property (nonatomic, readonly) NSString *profilePhoneNumberThatNeedsAValidationCode;
@property (nonatomic, readonly) ZMUserProfileUpdatePhases currentPhase;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (void)prepareForRequestingPhoneVerificationCodeForRegistration:(NSString *)phone;
- (void)prepareForPhoneChangeWithCredentials:(ZMPhoneCredentials *)phoneCredentials;
- (void)prepareForEmailAndPasswordChangeWithCredentials:(ZMEmailCredentials *)emailCredentials;

- (void)didRequestPhoneVerificationCodeSuccessfully;
- (void)didFailPhoneVerificationCodeRequestWithError:(NSError *)error;
- (void)didVerifyPhoneSuccessfully;
- (void)didFailPhoneVerification:(NSError *)error;
- (void)didUpdatePasswordSuccessfully;
- (void)didFailPasswordUpdate;
- (void)didUpdateEmailSuccessfully;
- (void)didFailEmailUpdate:(NSError *)error;

@end


@interface ZMUserProfileUpdateStatus (CredentialProvider) <ZMCredentialProvider>

@property (nonatomic, readonly) ZMEmailCredentials *emailCredentials;

-(void)credentialsMayBeCleared;

@end


#pragma mark - Notifications

@protocol ZMUserProfileUpdateNotificationObserverToken;

typedef NS_ENUM(NSUInteger, ZMUserProfileUpdateNotificationType) {
    ZMUserProfileNotificationPasswordUpdateDidFail,
    ZMUserProfileNotificationEmailUpdateDidFail,
    ZMUserProfileNotificationEmailDidSendVerification,
    ZMUserProfileNotificationPhoneNumberVerificationCodeRequestDidFail,
    ZMUserProfileNotificationPhoneNumberVerificationCodeRequestDidSucceed,
    ZMUserProfileNotificationPhoneNumberVerificationDidFail
};

@interface ZMUserProfileUpdateNotification : ZMNotification

@property (nonatomic, readonly) ZMUserProfileUpdateNotificationType type;
@property (nonatomic, readonly) NSError *error;

+ (void)notifyPasswordUpdateDidFail;
+ (void)notifyEmailUpdateDidFail:(NSError *)error;
+ (void)notifyPhoneNumberVerificationCodeRequestDidFailWithError:(NSError *)error;
+ (void)notifyPhoneNumberVerificationCodeRequestDidSucceed;
+ (void)notifyDidSendEmailVerification;

+ (void)notifyPhoneNumberVerificationDidFail:(NSError *)error;

+ (id<ZMUserProfileUpdateNotificationObserverToken>)addObserverWithBlock:(void(^)(ZMUserProfileUpdateNotification *))block ZM_MUST_USE_RETURN;
+ (void)removeObserver:(id<ZMUserProfileUpdateNotificationObserverToken>)token;

@end

