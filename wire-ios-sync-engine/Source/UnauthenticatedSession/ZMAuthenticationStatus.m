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

@import WireTransport;
@import WireUtilities;
@import WireDataModel;
@class UserCredentials;

#import "ZMAuthenticationStatus.h"
#import "NSError+ZMUserSession.h"
#import "NSError+ZMUserSessionInternal.h"
#import "ZMUserSessionRegistrationNotification.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>
#import "ZMAuthenticationStatus_Internal.h"


static NSString *const TimerInfoOriginalCredentialsKey = @"credentials";
static NSString *const AuthenticationCenterDataChangeNotificationName = @"ZMAuthenticationStatusDataChangeNotificationName";
NSTimeInterval DebugLoginFailureTimerOverride = 0;

static NSString* ZMLogTag ZM_UNUSED = @"Authentication";

@interface ZMAuthenticationStatus ()

@property (nonatomic, weak) id<UserInfoParser> userInfoParser;
@property (nonatomic, weak) id<ZMAuthenticationStatusDelegate> delegate;
@property (nonatomic, strong) UserInfo *authenticatedUserInfo;

@end

@implementation ZMAuthenticationStatus

- (instancetype)initWithDelegate:(id<ZMAuthenticationStatusDelegate>)delegate
                      groupQueue:(id<ZMSGroupQueue>)groupQueue
                  userInfoParser:(id<UserInfoParser>)userInfoParser {
    self = [super init];
    if(self) {
        self.delegate = delegate;
        self.groupQueue = groupQueue;
        self.userInfoParser = userInfoParser;
        self.isWaitingForLogin = !self.isLoggedIn;
    }
    return self;
}

- (void)dealloc
{
    [self stopLoginTimer];
}

- (UserCredentials *)loginCredentials
{
    return self.internalLoginCredentials;
}

- (NSUUID *)authenticatedUserIdentifier
{
    if (self.authenticatedUserInfo != nil) {
        return self.authenticatedUserInfo.identifier;
    }
    return nil;
}

- (void)resetLoginAndRegistrationStatus
{
    [self stopLoginTimer];
    
    self.registrationPhoneNumberThatNeedsAValidationCode = nil;
    self.loginPhoneNumberThatNeedsAValidationCode = nil;
    self.loginEmailThatNeedsAValidationCode = nil;

    self.internalLoginCredentials = nil;
    self.registrationPhoneValidationCredentials = nil;

    self.isWaitingForEmailVerification = NO;
    self.isWaitingForBackupImport = NO;
}

- (void)setLoginCredentials:(UserCredentials *)credentials
{
    if(credentials != self.internalLoginCredentials) {
        self.internalLoginCredentials = credentials;
        [ZMPersistentCookieStorage setCookiesPolicy:NSHTTPCookieAcceptPolicyAlways];
        [[[NotificationInContext alloc] initWithName:AuthenticationCenterDataChangeNotificationName
                                             context:self object:nil userInfo:nil] post];
    }
}

- (id)addAuthenticationCenterObserver:(id<ZMAuthenticationStatusObserver>)observer;
{
    ZM_WEAK(observer);
    return [NotificationInContext addObserverWithName:AuthenticationCenterDataChangeNotificationName
                                       context:self
                                        object:nil
                                         queue:nil
                                         using:^(NotificationInContext * notification __unused) {
                                             ZM_STRONG(observer);
                                             [observer didChangeAuthenticationData];
     }];
}

- (ZMAuthenticationPhase)currentPhase
{
    if(self.isLoggedIn) {
        return ZMAuthenticationPhaseAuthenticated;
    }
    if(self.isWaitingForBackupImport) {
        return ZMAuthenticationPhaseWaitingToImportBackup;
    }
    if(self.internalLoginCredentials.credentialWithEmail && self.isWaitingForLogin) {
        return ZMAuthenticationPhaseLoginWithEmail;
    }

    if (self.loginEmailThatNeedsAValidationCode != nil) {
        return ZMAuthenticationPhaseRequestEmailVerificationCodeForLogin;
    }
    
    return ZMAuthenticationPhaseUnauthenticated;
}

- (BOOL)needsCredentialsToLogin
{
    return !self.isLoggedIn && self.loginCredentials == nil;
}

- (BOOL)isLoggedIn
{
    return nil != self.authenticationCookieData;
}

- (void)startLoginTimer
{
    [self stopLoginTimer];
    self.loginTimer = [ZMTimer timerWithTarget:self];
    self.loginTimer.userInfo = @{ TimerInfoOriginalCredentialsKey : self.loginCredentials };
    [self.loginTimer fireAfterTimeInterval:(DebugLoginFailureTimerOverride > 0 ?: 60 )];
}

- (void)stopLoginTimer
{
    [self.loginTimer cancel];
    self.loginTimer = nil;
}

- (void)timerDidFire:(ZMTimer *)timer
{
    [self.groupQueue performGroupedBlock:^{
        [self didTimeoutLoginForCredentials:timer.userInfo[TimerInfoOriginalCredentialsKey]];
    }];
}

- (void)prepareForLoginWithCredentials:(UserCredentials *)credentials
{
    ZMLogDebug(@"%@", NSStringFromSelector(_cmd));
    self.authenticationCookieData = nil;
    [self resetLoginAndRegistrationStatus];
    self.loginCredentials = credentials;
    self.isWaitingForLogin = YES;
    [self startLoginTimer];
    ZMLogDebug(@"current phase: %lu", (unsigned long)self.currentPhase);
}

- (void)continueAfterBackupImportStep
{
    ZMLogDebug(@"%@", NSStringFromSelector(_cmd));
    
    [self continueAuthenticationWithUserInfo:self.authenticatedUserInfo];
    ZMLogDebug(@"current phase: %lu", (unsigned long)self.currentPhase);
}

- (void)continueAuthenticationWithResponse:(ZMTransportResponse *)response
{
    [self continueAuthenticationWithUserInfo:response.extractUserInfo];
}

- (void)continueAuthenticationWithUserInfo:(UserInfo *)userInfo
{
    self.isWaitingForBackupImport = NO;
    if (self.isWaitingForLogin) {
        self.isWaitingForLogin = NO;
    }
    [self.delegate authenticationDidSucceed];
    [self.userInfoParser upgradeToAuthenticatedSessionWithUserInfo:userInfo];
}

- (void)prepareForRequestingEmailVerificationCodeForLogin:(NSString *)email;
{
    ZMLogDebug(@"%@", NSStringFromSelector(_cmd));
    [self resetLoginAndRegistrationStatus];
    self.loginEmailThatNeedsAValidationCode = email;
    ZMLogDebug(@"current phase: %lu", (unsigned long)self.currentPhase);
}

- (void)didTimeoutLoginForCredentials:(UserCredentials *)credentials
{
    ZMLogDebug(@"%@", NSStringFromSelector(_cmd));
    if (self.currentPhase == ZMAuthenticationPhaseLoginWithEmail && self.loginCredentials == credentials)
    {
        self.loginCredentials = nil;
        [self.delegate authenticationDidFail:[NSError userSessionErrorWithCode:ZMUserSessionErrorCodeNetworkError userInfo:nil]];
    }
    ZMLogDebug(@"current phase: %lu", (unsigned long)self.currentPhase);
}

- (void)loginSucceededWithResponse:(ZMTransportResponse *)response
{
    [self loginSucceededWithUserInfo:response.extractUserInfo];
}

- (void)loginSucceededWithUserInfo:(UserInfo *)userInfo
{
    ZMLogDebug(@"%@", NSStringFromSelector(_cmd));
    if (self.completedRegistration) {
        [self continueAuthenticationWithUserInfo:userInfo];
    } else {
        self.authenticatedUserInfo = userInfo;
        self.isWaitingForBackupImport = YES;
        BOOL existingAccount = [self.userInfoParser accountExistsLocallyFromUserInfo:userInfo];
        [self.delegate authenticationReadyImportingBackup: existingAccount];
    }
    ZMLogDebug(@"current phase: %lu", (unsigned long)self.currentPhase);
}

- (void)didFailLoginWithEmail:(BOOL)invalidCredentials
{
    ZMLogDebug(@"%@ invalid credentials: %d", NSStringFromSelector(_cmd), invalidCredentials);
    
    NSError *error = [NSError userSessionErrorWithCode:(invalidCredentials ? ZMUserSessionErrorCodeInvalidCredentials : ZMUserSessionErrorCodeUnknownError) userInfo:nil];
    [self.delegate authenticationDidFail: error];
    [self resetLoginAndRegistrationStatus];
    ZMLogDebug(@"current phase: %lu", (unsigned long)self.currentPhase);
}

- (void)didFailLoginWithEmailBecausePendingValidation
{
    ZMLogDebug(@"%@", NSStringFromSelector(_cmd));
    self.isWaitingForEmailVerification = YES;
    NSError *error = [NSError userSessionErrorWithCode:ZMUserSessionErrorCodeAccountIsPendingActivation userInfo:nil];
    [self.delegate authenticationDidFail: error];
    ZMLogDebug(@"current phase: %lu", (unsigned long)self.currentPhase);
}

- (void)didFailLoginWithEmailBecauseVerificationCodeIsRequired
{
    ZMLogDebug(@"%@", NSStringFromSelector(_cmd));
    NSError *error = [NSError userSessionErrorWithCode:ZMUserSessionErrorCodeAccountIsPendingVerification userInfo:nil];
    [self.delegate authenticationDidFail: error];
    ZMLogDebug(@"current phase: %lu", (unsigned long)self.currentPhase);
}

- (void)didFailLoginWithEmailBecauseVerificationCodeIsInvalid
{
    ZMLogDebug(@"%@", NSStringFromSelector(_cmd));
    // This fixes a loop on /login with the wrong verification loop
    // we break the state of currentPhase ZMAuthenticationPhaseLoginWithEmail
    if (self.isWaitingForLogin) {
        self.isWaitingForLogin = NO;
    }
    NSError *error = [NSError userSessionErrorWithCode:ZMUserSessionErrorCodeInvalidEmailVerificationCode userInfo:nil];
    [self.delegate authenticationDidFail: error];
    ZMLogDebug(@"current phase: %lu", (unsigned long)self.currentPhase);
}

- (void)didFailLoginBecauseAccountSuspended
{
    ZMLogDebug(@"%@", NSStringFromSelector(_cmd));
    NSError *error = [NSError userSessionErrorWithCode:ZMUserSessionErrorCodeAccountSuspended userInfo:nil];
    [self.delegate authenticationDidFail: error];
    [self resetLoginAndRegistrationStatus];
    ZMLogDebug(@"current phase: %lu", (unsigned long)self.currentPhase);
}

- (void)cancelWaitingForEmailVerification
{
    ZMLogDebug(@"%@", NSStringFromSelector(_cmd));
    [self resetLoginAndRegistrationStatus];
    ZMLogDebug(@"current phase: %lu", (unsigned long)self.currentPhase);
}

- (void)setAuthenticationCookieData:(NSData *)data;
{
    ZMLogDebug(@"Setting cookie data: %@", @(data.length));
    _authenticationCookieData = data;
    ZMLogDebug(@"current phase: %lu", (unsigned long)self.currentPhase);
}

- (void)didCompleteRequestForLoginCodeSuccessfully
{
    ZMLogDebug(@"%@", NSStringFromSelector(_cmd));
    [self.delegate loginCodeRequestDidSucceed];
    self.loginPhoneNumberThatNeedsAValidationCode = nil;
    self.loginEmailThatNeedsAValidationCode = nil;
    ZMLogDebug(@"current phase: %lu", (unsigned long)self.currentPhase);
}

- (void)didFailRequestForLoginCode:(NSError *)error;
{
    ZMLogDebug(@"%@", NSStringFromSelector(_cmd));
    self.loginPhoneNumberThatNeedsAValidationCode = nil;
    self.loginEmailThatNeedsAValidationCode = nil;
    [self.delegate loginCodeRequestDidFail: error];
    ZMLogDebug(@"current phase: %lu", (unsigned long)self.currentPhase);
}

- (void)notifyAuthenticationDidFail:(NSError *)error {
    [self.delegate authenticationDidFail:error];
}

- (void)notifyCompanyLoginCodeDidBecomeAvailable:(NSUUID *)uuid {
    [self.delegate companyLoginCodeDidBecomeAvailable:uuid];
}

- (void)startLogin {
    [self.delegate authenticationWasRequested];
}

@end
