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

typedef NS_CLOSED_ENUM(NSInteger, ZMUserSessionErrorCode) {
    ZMUserSessionErrorCodeNoError = 0,
    /// ???
    ZMUserSessionErrorCodeUnknownError = 1,
    /// Credentials are needed to authenticate
    ZMUserSessionErrorCodeNeedsCredentials = 2,
    /// The credentials provided are not valid
    ZMUserSessionErrorCodeInvalidCredentials = 3,
    /// The account is still pending validation
    ZMUserSessionErrorCodeAccountIsPendingActivation = 4,
    /// Network error in communicating with the backend
    ZMUserSessionErrorCodeNetworkError = 5,
    /// The email used in the registration is already in use
    ZMUserSessionErrorCodeEmailIsAlreadyRegistered = 6,
    /// The phone number used in the registration is already in use
    // ZMUserSessionErrorCodePhoneNumberIsAlreadyRegistered __attribute__((deprecated)) = 7,
    /// The phone number used in the registration is not a valid phone number
    // ZMUserSessionErrorCodeInvalidPhoneNumber __attribute__((deprecated)) = 8,
    /// The email used in the registration is not a valid email
    ZMUserSessionErrorCodeInvalidEmail = 9,
    /// The phone number verification code inserted is not valid
    // ZMUserSessionErrorCodeInvalidPhoneNumberVerificationCode __attribute__((deprecated)) = 10,
    /// The email verification code inserted is not valid
    ZMUserSessionErrorCodeInvalidEmailVerificationCode = 11,
    /// The registration failed, but we don't know why
    ZMUserSessionErrorCodeRegistrationDidFailWithUnknownError = 12,
    /// There is already a recent request to get the activation code for registration/login
    ZMUserSessionErrorCodeRequestIsAlreadyPending = 13,
    /// The user account does not have a password, and a password
    /// is needed to register a new client.
    ZMUserSessionErrorCodeNeedsPasswordToRegisterClient = 14,
    /// The user account does not have an email, and an email
    /// is needed to register a new client
    /// Not supported by the backend any more. The error is generated locally.
    ZMUserSessionErrorCodeNeedsToRegisterEmailToRegisterClient = 15,
    /// The user needs to enroll into end-to-end identity in order to complete the registration
    /// of a new client.
    ZMUserSessionErrorCodeNeedsToEnrollE2EIToRegisterClient = 16,
    /// The user account does not have a handle, and a handle is needed to register a new client.
    ZMUserSessionErrorCodeNeedsToHandleToRegisterClient = 17,
    /// Too many clients have been registered for this user,
    /// one needs to be deleted before registering a new one
    ZMUserSessionErrorCodeCanNotRegisterMoreClients = 18,
    /// The invitation code provided during registration is invalid
    ZMUserSessionErrorCodeInvalidInvitationCode = 19,
    /// The Activation code provided during email activation is invalid
    ZMUserSessionErrorCodeInvalidActivationCode = 20,
    /// The current usert client was deleted remotely
    ZMUserSessionErrorCodeClientDeletedRemotely = 21,
    /// The last user identity (email or phone number) cannot be removed.
    ZMUserSessionErrorCodeLastUserIdentityCantBeDeleted = 22,
    /// Access token expired and could not be renewed
    ZMUserSessionErrorCodeAccessTokenExpired = 23,
    /// The user requested to add an additional account
    ZMUserSessionErrorCodeAddAccountRequested = 24,
    /// The user account is suspended and may not be logged in
    ZMUserSessionErrorCodeAccountSuspended = 25,
    /// The user account was deleted
    ZMUserSessionErrorCodeAccountDeleted = 26,
    /// The account can't be created because the account limit has been reached
    ZMUserSessionErrorCodeAccountLimitReached = 27,
    /// The email used in the registration is blacklisted
    ZMUserSessionErrorCodeBlacklistedEmail = 28,
    /// Unauthorized e-mail address
    ZMUserSessionErrorCodeUnauthorizedEmail = 29,
    /// The email used in the registration is blocked
    ZMUserSessionErrorCodeDomainBlocked = 30,
    /// User has rebooted the device
    ZMUserSessionErrorCodeNeedsAuthenticationAfterReboot = 31,
    /// User's account pending verification
    ZMUserSessionErrorCodeAccountIsPendingVerification = 32,
    /// Migration has finished and the user should authenticate
    ZMUserSessionErrorCodeNeedsAuthenticationAfterMigration = 33
} NS_SWIFT_NAME(UserSessionErrorCode);

FOUNDATION_EXPORT NSString * const ZMClientsKey;

FOUNDATION_EXPORT NSString * const ZMUserLoginCredentialsKey;
FOUNDATION_EXPORT NSString * const ZMPhoneCredentialKey;
FOUNDATION_EXPORT NSString * const ZMEmailCredentialKey;
FOUNDATION_EXPORT NSString * const ZMUserHasPasswordKey;
FOUNDATION_EXPORT NSString * const ZMUserUsesCompanyLoginCredentialKey;
FOUNDATION_EXPORT NSString * const ZMAccountDeletedReasonKey;

@interface NSError (ZMUserSession)

/// Will return @c ZMUserSessionNoError if the receiver is not a user session error.
@property (nonatomic, readonly) ZMUserSessionErrorCode userSessionErrorCode;

@end
