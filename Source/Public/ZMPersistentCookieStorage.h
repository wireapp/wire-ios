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
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

/// This overrides the @c NSHTTPCookieStorage and adds convenience to check for the cookies relevant for our backend.
///
/// We will only store cookies relevant to our backend. They'll be persisted in the keychain.
@interface ZMPersistentCookieStorage : NSObject

+ (instancetype)storageForServerName:(NSString *)serverName;
+ (void)setDoNotPersistToKeychain:(BOOL)disabled;

- (void)deleteUserKeychainItems;

@property (nonatomic, nullable) NSData *authenticationCookieData;
@property (nonatomic) NSString *cookieLabel;

@end






@interface ZMPersistentCookieStorage (HTTPCookie)

//If you try tu set it to something different than NSHTTPCookieAcceptPolicyNever it will be set to NSHTTPCookieAcceptPolicyAlways
+ (void)setCookiesPolicy:(NSHTTPCookieAcceptPolicy)policy;
+ (NSHTTPCookieAcceptPolicy)cookiesPolicy;

- (void)setCookieDataFromResponse:(NSHTTPURLResponse *)response forURL:(NSURL *)URL;
- (void)setRequestHeaderFieldsOnRequest:(NSMutableURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
