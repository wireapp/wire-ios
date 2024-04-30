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
@import WireSystem;
#import "MockTransportSession+registration.h"
#import <WireMockTransport/WireMockTransport-Swift.h>

@implementation MockTransportSession (Registration)

- (MockUser *)userWithEmail:(NSString *)email {
    NSFetchRequest *fetchRequest = [MockUser sortedFetchRequest];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"email == %@", email];
    NSArray *users = [self.managedObjectContext executeFetchRequestOrAssert:fetchRequest];
    if(users.count > 0u) {
        return users.firstObject;
    }
    return nil;
}

/// Handles "/register"
- (ZMTransportResponse *)processRegistrationRequest:(ZMTransportRequest *)request
{
    if(request.method == ZMTransportRequestMethodPost) {
        
        NSDictionary *userDetails = [request.payload asDictionary];
        
        NSString *name = [userDetails optionalStringForKey:@"name"];
        NSString *email = [userDetails optionalStringForKey:@"email"];
        NSString *password = [userDetails optionalStringForKey:@"password"];
        NSString *invitationCode = [userDetails optionalStringForKey:@"invitation_code"];

        if( name == nil
           || (email == nil)
           || (email != nil && password == nil)
           || (invitationCode == nil))
        {
            return [self errorResponseWithCode:400 reason:@"missing-key" apiVersion:request.apiVersion];
        }
        
        // check if it's already there
        if(email != nil && [self userWithEmail:email] != nil) {
            return [self errorResponseWithCode:409 reason:@"key-exists" apiVersion:request.apiVersion];
        }
        
        // at this point, we validated everything
        MockUser *user = self.selfUser;
        if (user == nil){
            user = [self insertSelfUserWithName:name];
            self.selfUser = user;
        }
        else {
            user.name = name;
        }
        user.password = password;
        user.email = email;
        if(userDetails[@"accent_id"] != nil) {
            user.accentID = (ZMAccentColorRawValue) [[userDetails numberForKey:@"accent_id"] integerValue];
        }
        
        BOOL shouldReturnEmail = YES;
        if(user.email != nil && ![self.whitelistedEmails containsObject:user.email]) {
            user.isEmailValidated = NO;
            shouldReturnEmail = NO;
        }
        
        NSMutableDictionary *payload = [@{@"email": (user.email != nil && shouldReturnEmail) ? user.email : [NSNull null],
                                  @"accent_id": @(user.accentID),
                                  @"name": user.name,
                                  @"id": user.identifier
                                  } mutableCopy];

        NSString *cookiesValue = @"fake cookie";
        
        if ([ZMPersistentCookieStorage cookiesPolicy] != NSHTTPCookieAcceptPolicyNever) {
            self.cookieStorage.authenticationCookieData = [cookiesValue dataUsingEncoding:NSUTF8StringEncoding];
        }

        return [ZMTransportResponse responseWithPayload:payload HTTPStatus:200 transportSessionError:nil headers:@{@"Set-Cookie": [NSString stringWithFormat:@"zuid=%@", cookiesValue]} apiVersion:request.apiVersion];
    }
    
    return [self errorResponseWithCode:404 reason:@"no-endpoint" apiVersion:request.apiVersion];
}

/// Handles "/activate"
- (ZMTransportResponse *)processPhoneActivationRequest:(ZMTransportRequest *)request;
{
    if (request.method == ZMTransportRequestMethodPost) {
        NSDictionary *userDetails = [request.payload asDictionary];
        
        NSString *code = [userDetails optionalStringForKey:@"code"];
        NSString *email = [userDetails optionalStringForKey:@"email"];

        BOOL dryrun = ((NSNumber *)[userDetails optionalNumberForKey:@"dryrun"]).boolValue;
        
        if(code == nil && email == nil) {
            return [self errorResponseWithCode:400 reason:@"missing-key" apiVersion:request.apiVersion];
        }

        if([self.emailsWaitingForVerificationForRegistration containsObject:email]){
            if(![code isEqualToString:self.emailActivationCode]) {
                return [self errorResponseWithCode:404 reason:@"not-found" apiVersion:request.apiVersion];
            }
            else {
                if(!dryrun) {
                    [self.emailsWaitingForVerificationForRegistration removeObject:email];
                }
                return [ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil apiVersion:request.apiVersion];

            }
        }
        else {
            return [self errorResponseWithCode:404 reason:@"not-found" apiVersion:request.apiVersion];
        }
    }
    return [self errorResponseWithCode:404 reason:@"no-endpoint" apiVersion:request.apiVersion];
}


/// Handles "/active/send"
- (ZMTransportResponse *)processVerificationCodeRequest:(ZMTransportRequest *)request
{
    if (request.method == ZMTransportRequestMethodPost) {
        NSDictionary *userDetails = [request.payload asDictionary];
        
        NSString *email = [userDetails optionalStringForKey:@"email"];

        if (email == nil) {
            return [self errorResponseWithCode:400 reason:@"missing-key" apiVersion:request.apiVersion];
        }
        
        if(email != nil) {
            MockUser *existingUser = [self userWithEmail:email];
            if(existingUser != nil
               && (
                   (existingUser == self.selfUser && self.selfUser.isEmailValidated)
                   || existingUser != self.selfUser
                   )
               ) {
                return [self errorResponseWithCode:409 reason:@"key-exists" apiVersion:request.apiVersion];
            }

            [self.emailsWaitingForVerificationForRegistration addObject:email];

        }
        
        return [ZMTransportResponse responseWithPayload:nil HTTPStatus:200 transportSessionError:nil apiVersion:request.apiVersion];
    }
    
    return [self errorResponseWithCode:404 reason:@"no-endpoint" apiVersion:request.apiVersion];
}

@end
