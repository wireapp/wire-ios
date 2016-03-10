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


@import ZMUtilities;

#import "NSURL+LaunchOptions.h"

@implementation NSURL (LaunchOptions)

- (NSString *)invitationToConnectToken
{
    if(!self.isURLForInvitationToConnect) {
        return nil;
    }
    return self.zm_queryComponents[@"code"];
}

- (NSString *)codeForPhoneVerification
{
    if (!self.isURLForPhoneVerification) {
        return nil;
    }
    return [self.path substringFromIndex:1];
}

- (NSString *)codeForPersonalInvitation
{
    if (!self.isURLForPersonalInvitation) {
        return nil;
    }
    
    return self.zm_queryComponents[@"code"];
}

- (BOOL)isURLForInvitationToConnect;
{
    NSString *code = self.zm_queryComponents[@"code"];
    if(code == nil || code.length == 0) {
        return NO;
    }
    
    return
    ([self.scheme isEqualToString:@"wire"] || [self.scheme isEqualToString:@"wire-invite"])
    && [self.host isEqualToString:@"connect"]
    && [self.path isEqualToString:@""];
}

- (BOOL)isURLForPhoneVerification
{
    return
    [self.scheme isEqualToString:@"wire"]
    && [self.host isEqualToString:@"verify-phone"]
    && self.path.length > 1;
}

- (BOOL)isURLForPersonalInvitation
{
    NSString *code = self.zm_queryComponents[@"code"];
    if(code == nil || code.length == 0) {
        return NO;
    }
    
    return
    [self.scheme isEqualToString:@"wire"]
    && [self.host isEqualToString:@"invitation"]
    && [self.path isEqualToString:@""];
}

- (BOOL)isURLForPersonalInvitationError
{
    NSString *error = self.zm_queryComponents[@"error"];
    if(error == nil || ! error.length == 0) {
        return NO;
    }
    
    return
    [self.scheme isEqualToString:@"wire"]
    && [self.host isEqualToString:@"invitation"]
    && [self.path isEqualToString:@""];
}

@end
