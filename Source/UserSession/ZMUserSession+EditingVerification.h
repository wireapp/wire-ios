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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


#import "ZMUserSession.h"

@interface ZMUserSession (EditingVerification)

/// If the UI starts and this is set, the UI should go to the "Please check your email we sent at xxxxx (+ resend link)" screen.
/// At any point in time, if the self user email gets updated, the screen should be dismissed
- (NSString *)currentlyUpdatingEmail;

/// If the UI stars and this is set, the UI should go to the "Please enter the phone code for phone xxxx (+ resend link)" screen.
/// At any point in time (even if the user did not enter the code), if the self user phone gets updated, the screen should be dismissed
- (NSString *)currentlyUpdatingPhone;

/// Send email verification and set the password. The "Please check your email" screen should be dismissed when the self user email is updated
- (void)requestVerificationEmailForEmailUpdate:(ZMEmailCredentials *)credentials;

/// Requests a verification code to update the phone in the profile. The screen "Please enter the code" should be dismissed if the self user phone is updated
- (void)requestVerificationCodeForPhoneNumberUpdate:(NSString *)phoneNumber;

/// Verify phone number for profile. The screen "Please enter the code" should be dismissed if the self user phone is updated
- (void)verifyPhoneNumberForUpdate:(ZMPhoneCredentials *)credentials;

- (id<ZMUserEditingObserverToken>)addUserEditingObserver:(id<ZMUserEditingObserver>)observer ZM_MUST_USE_RETURN;
- (void)removeUserEditingObserverForToken:(id<ZMUserEditingObserverToken>)observerToken;

@end
