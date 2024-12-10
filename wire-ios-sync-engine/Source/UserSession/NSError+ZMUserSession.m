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

#import "NSError+ZMUserSession.h"
#import "NSError+ZMUserSessionInternal.h"
#import <WireSyncEngine/WireSyncEngine-Swift.h>

NSString * const ZMClientsKey = @"clients";
NSString * const ZMPhoneCredentialKey = @"phone";
NSString * const ZMEmailCredentialKey = @"email";
NSString * const ZMUserHasPasswordKey = @"has-password";
NSString * const ZMUserUsesCompanyLoginCredentialKey = @"uses-company-login";
NSString * const ZMUserLoginCredentialsKey = @"login-credentials";
NSString * const ZMAccountDeletedReasonKey = @"account-deleted-reason";

@implementation NSError (ZMUserSession)

- (ZMUserSessionErrorCode)userSessionErrorCode
{
    if (! [self.domain isEqualToString:NSError.ZMUserSessionErrorDomain]) {
        return ZMUserSessionErrorCodeNoError;
    } else {
        return (ZMUserSessionErrorCode) self.code;
    }
}

@end



@implementation NSError (ZMUserSessionInteral)

+ (instancetype)userSessionErrorWithCode:(ZMUserSessionErrorCode)code userInfo:(NSDictionary *)userInfo
{
    return [[NSError alloc] initWithUserSessionErrorCode:code userInfo:userInfo];
}

+ (instancetype)pendingLoginErrorWithResponse:(ZMTransportResponse *)response
{
    if (response.HTTPStatus == 403 && [[response payloadLabel] isEqualToString:@"pending-login"]) {
        return [NSError userSessionErrorWithCode:ZMUserSessionErrorCodeRequestIsAlreadyPending userInfo:nil];
    }
    return nil;
}

+ (instancetype)unauthorizedEmailErrorWithResponse:(ZMTransportResponse *)response
{
    if (response.HTTPStatus == 403 && [[response payloadLabel] isEqualToString:@"unauthorized"]) {
        return [NSError userSessionErrorWithCode:ZMUserSessionErrorCodeUnauthorizedEmail userInfo:nil];
    }
    return nil;
}

+ (instancetype)invalidEmailVerificationCodeErrorWithResponse:(ZMTransportResponse *)response
{
    if (response.HTTPStatus == 403 && [[response payloadLabel] isEqualToString:@"code-authentication-failed"]) {
        return [NSError userSessionErrorWithCode:ZMUserSessionErrorCodeInvalidEmailVerificationCode userInfo:nil];
    }
    return nil;
}

+ (instancetype)blacklistedEmailWithResponse:(ZMTransportResponse *)response
{
    if (response.HTTPStatus == 403 && [[response payloadLabel] isEqualToString:@"blacklisted-email"]) {
        return [NSError userSessionErrorWithCode:ZMUserSessionErrorCodeBlacklistedEmail userInfo:nil];
    }
    return nil;
}

+ (instancetype)domainBlockedWithResponse:(ZMTransportResponse *)response
{
    if (response.HTTPStatus == 451 && [[response payloadLabel] isEqualToString:@"domain-blocked-for-registration"]) {
        return [NSError userSessionErrorWithCode:ZMUserSessionErrorCodeDomainBlocked userInfo:nil];
    }
    return nil;
}

+ (instancetype)invalidEmailWithResponse:(ZMTransportResponse *)response
{
    if (response.HTTPStatus == 400 && [[response payloadLabel] isEqualToString:@"invalid-email"]) {
        return [NSError userSessionErrorWithCode:ZMUserSessionErrorCodeInvalidEmail userInfo:nil];
    }
    return nil;
}

+ (__nullable instancetype)emailAddressInUseErrorWithResponse:(ZMTransportResponse *)response
{
    if (response.HTTPStatus == 409 && [[response payloadLabel] isEqualToString:@"key-exists"]) {
        return [NSError userSessionErrorWithCode:ZMUserSessionErrorCodeEmailIsAlreadyRegistered userInfo:nil];
    }
    return nil;
}

+ (instancetype)keyExistsErrorWithResponse:(ZMTransportResponse *)response
{
    if (response.HTTPStatus == 409 && [[response payloadLabel] isEqualToString:@"key-exists"]) {
        return [NSError userSessionErrorWithCode:ZMUserSessionErrorCodeEmailIsAlreadyRegistered userInfo:nil];
    }
    return nil;
}

+ (instancetype)handleExistsErrorWithResponse:(ZMTransportResponse *)response
{
    if (response.HTTPStatus == 409 && [[response payloadLabel] isEqualToString:@"handle-exists"]) {
        return [NSError userSessionErrorWithCode:ZMUserSessionErrorCodeEmailIsAlreadyRegistered userInfo:nil];
    }
    return nil;
}

+ (instancetype)invalidInvitationCodeWithResponse:(ZMTransportResponse *)response
{
    if (response.HTTPStatus == 400 && [[response payloadLabel] isEqualToString:@"invalid-invitation-code"]) {
        return [NSError userSessionErrorWithCode:ZMUserSessionErrorCodeInvalidInvitationCode userInfo:nil];
    }
    return nil;
}

+ (instancetype)invalidActivationCodeWithResponse:(ZMTransportResponse *)response
{
    if (response.HTTPStatus == 404 && [[response payloadLabel] isEqualToString:@"invalid-code"]) {
        return [NSError userSessionErrorWithCode:ZMUserSessionErrorCodeInvalidActivationCode userInfo:nil];
    }
    return nil;
}

+ (instancetype)lastUserIdentityCantBeRemovedWithResponse:(ZMTransportResponse *)response
{
    if (response.HTTPStatus == 403 && [[response payloadLabel] isEqualToString:@"last-identity"]) {
        return [NSError userSessionErrorWithCode:ZMUserSessionErrorCodeLastUserIdentityCantBeDeleted userInfo:nil];
    }
    return nil;
}

@end
