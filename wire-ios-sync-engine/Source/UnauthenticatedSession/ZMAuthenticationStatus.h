//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
@import CoreData;

#import <WireSyncEngine/NSError+ZMUserSession.h>

@class UserInfo;
@class UserCredentials;
@class UserEmailCredentials;
@class UserPhoneCredentials;
@class ZMPersistentCookieStorage;
@class ZMTransportResponse;
@protocol UserInfoParser;
@protocol NotificationContext;

FOUNDATION_EXPORT NSTimeInterval DebugLoginFailureTimerOverride;

@protocol ZMCredentialProvider <NSObject>

- (void)credentialsMayBeCleared;
- (UserEmailCredentials *)emailCredentials;
@end

/// Invoked when the credentials are changed
@protocol ZMAuthenticationStatusObserver <NSObject>
- (void)didChangeAuthenticationData;
@end

@protocol ZMAuthenticationStatusDelegate <NSObject>
- (void)authenticationDidFail:(NSError *)error;
- (void)authenticationReadyImportingBackup:(BOOL)existingAccount;
- (void)authenticationDidSucceed;
- (void)loginCodeRequestDidFail:(NSError *)error;
- (void)loginCodeRequestDidSucceed;
- (void)companyLoginCodeDidBecomeAvailable:(NSUUID *)uuid;
- (void)authenticationWasRequested;
@end

typedef NS_ENUM(NSUInteger, ZMAuthenticationPhase) {
    ZMAuthenticationPhaseUnauthenticated = 0,
    //ZMAuthenticationPhaseLoginWithPhone = 1 __attribute__((deprecated("Use ZMAuthenticationPhaseRequestPhoneVerificationCodeForLogin instead"))),
    ZMAuthenticationPhaseLoginWithEmail = 2,
    ZMAuthenticationPhaseWaitingToImportBackup = 3,
    //ZMAuthenticationPhaseRequestPhoneVerificationCodeForLogin = 4 __attribute__((deprecated("This phase is deprecated"))),
    ZMAuthenticationPhaseRequestEmailVerificationCodeForLogin = 5,
    //ZMAuthenticationPhaseVerifyPhone = 6 __attribute__((deprecated("Use ZMAuthenticationPhaseLoginWithPhone instead"))),
    ZMAuthenticationPhaseAuthenticated = 7
};

@interface ZMAuthenticationStatus : NSObject

@property (nonatomic, readonly, copy) NSString *loginEmailThatNeedsAValidationCode;


@property (nonatomic, readonly) UserCredentials *loginCredentials;

@property (nonatomic, readonly) BOOL isWaitingForBackupImport;
@property (nonatomic, readonly) BOOL completedRegistration;
@property (nonatomic, readonly) BOOL needsCredentialsToLogin;

@property (nonatomic, readonly) ZMAuthenticationPhase currentPhase;
@property (nonatomic, readonly) NSUUID *authenticatedUserIdentifier;
@property (nonatomic) NSData *profileImageData;

@property (nonatomic) NSData *authenticationCookieData;

- (instancetype)initWithDelegate:(id<ZMAuthenticationStatusDelegate>)delegate
                      groupQueue:(id<ZMSGroupQueue>)groupQueue
                  userInfoParser:(id<UserInfoParser>)userInfoParser;

- (id)addAuthenticationCenterObserver:(id<ZMAuthenticationStatusObserver>)observer;

- (void)prepareForLoginWithCredentials:(UserCredentials *)credentials;
- (void)continueAfterBackupImportStep;
- (void)prepareForRequestingEmailVerificationCodeForLogin:(NSString *)email;

- (void)didCompleteRequestForLoginCodeSuccessfully;
- (void)didFailRequestForLoginCode:(NSError *)error;
- (void)notifyAuthenticationDidFail:(NSError *)error;

- (void)notifyCompanyLoginCodeDidBecomeAvailable:(NSUUID *)uuid;

- (void)startLogin;
- (void)loginSucceededWithResponse:(ZMTransportResponse *)response;
- (void)loginSucceededWithUserInfo:(UserInfo *)userInfo;
- (void)didFailLoginWithEmailBecausePendingValidation;
- (void)didFailLoginWithEmail:(BOOL)invalidCredentials;
- (void)didFailLoginBecauseAccountSuspended;
- (void)didFailLoginWithEmailBecauseVerificationCodeIsRequired;
- (void)didFailLoginWithEmailBecauseVerificationCodeIsInvalid;
- (void)didTimeoutLoginForCredentials:(UserCredentials *)credentials;
- (void)resetLoginAndRegistrationStatus;

@end
