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

@import WireUtilities;

#import "ZMCredentials+Internal.h"

@interface ZMCredentials ()

@property (nonatomic, copy, nullable) NSString *email;
@property (nonatomic, copy, nullable) NSString *password;
@property (nonatomic, copy, nullable) NSString *emailVerificationCode;

@end

@implementation ZMEmailCredentials

+ (nonnull ZMEmailCredentials *)credentialsWithEmail:(nonnull NSString *)email password:(nonnull NSString *)password {
    return [ZMEmailCredentials credentialsWithEmail:email password:password emailVerificationCode:nil];
}

+ (nonnull ZMEmailCredentials *)credentialsWithEmail:(nonnull NSString *)email password:(nonnull NSString *)password emailVerificationCode:(nullable NSString *)code
{
    ZMEmailCredentials *credentials = [[ZMEmailCredentials alloc] init];
    credentials.email = email;
    credentials.password = password;
    credentials.emailVerificationCode = code;
    return credentials;
}

@end



@implementation ZMCredentials

#define ZM_EQUAL_STRINGS(a, b) (a == nil && b == nil) || [a isEqualToString:b]

- (BOOL)isEqual:(ZMCredentials *)object
{
    if (object == self) {
        return YES;
    }
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    BOOL emailsEqual = ZM_EQUAL_STRINGS(self.email, object.email);
    BOOL passwordsEqual = ZM_EQUAL_STRINGS(self.password, object.password);
    BOOL twoFactorVerificationCodesEqual = ZM_EQUAL_STRINGS(self.emailVerificationCode, object.emailVerificationCode);
    return emailsEqual && passwordsEqual && twoFactorVerificationCodesEqual;
}

#undef ZM_EQUAL_STRINGS

- (BOOL)credentialWithEmail {
    return self.email != nil;
}

@end
