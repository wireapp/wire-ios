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


@import Security;
@import WireSystem;
@import WireUtilities;

#import "ZMTLogging.h"
#import "ZMPersistentCookieStorage.h"
#import <CommonCrypto/CommonCrypto.h>
#import "ZMKeychain.h"

static NSString * const AccountName = @"User";
static NSString* ZMLogTag ZM_UNUSED = ZMT_LOG_TAG_NETWORK;
static BOOL KeychainDisabled = NO;
static NSMutableDictionary *NonPersistedPassword;
static NSHTTPCookieAcceptPolicy cookiesPolicy = NSHTTPCookieAcceptPolicyAlways;


static dispatch_queue_t isolationQueue()
{
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("ZMPersistentCookieStorage.isolation", 0);
    });
    return queue;
}


@interface ZMPersistentCookieStorage ()

@property (nonatomic, readonly) NSString *serverName;

@end



@interface ZMPersistentCookieStorage (Keychain)

- (BOOL)findItemWithPassword:(NSData **)passwordP;
- (void)setItem:(NSData *)item;

- (void)deleteItem;

@end



@implementation ZMPersistentCookieStorage

#pragma mark - Creation

+ (instancetype)storageForServerName:(NSString *)serverName;
{
    return [[self alloc] initWithServerName:serverName];
}

- (instancetype)init
{
    return nil;
}

- (instancetype)initWithServerName:(NSString *)serverName
{
    self = [super init];
    if (self) {
        _serverName = [serverName copy];
    }
    return self;
}

#pragma mark - Public API

+ (void)setDoNotPersistToKeychain:(BOOL)disabled;
{
    KeychainDisabled = disabled;
}

- (NSData *)authenticationCookieData;
{
    NSData *result = nil;
    if ([self findItemWithPassword:&result]) {
        return result;
    }
    return nil;
}

- (void)setAuthenticationCookieData:(NSData *)data;
{
    if (data == nil) {
        [self deleteItem];
    } else {
        [self setItem:data];
    }
}

+ (void)deleteAllKeychainItems
{
    dispatch_sync(isolationQueue(), ^{
        NonPersistedPassword = nil;

        if (KeychainDisabled) {
            return;
        }
        [ZMKeychain deleteAllKeychainItemsWithAccountName:AccountName];
    });
}

@end



@implementation ZMPersistentCookieStorage (Keychain)

- (BOOL)findItemWithPassword:(NSData **)passwordP
{
    __block BOOL success = NO;
    dispatch_sync(isolationQueue(), ^{
        
        NSData *password = NonPersistedPassword[self.serverName];
        BOOL const fetchFromKeychain = (password == nil);
        *passwordP = (password == (id) [NSNull null]) ? nil : password;
        
        if (KeychainDisabled) {
            success = YES;
            return;
        }
        
        if (fetchFromKeychain) {
            id result = nil;
            if (passwordP == nil) {
                result = [ZMKeychain stringForAccount:AccountName fallbackToDefaultGroup:YES];
            }
            else {
                result = [ZMKeychain dataForAccount:AccountName fallbackToDefaultGroup:YES];
            }
            
            if (result != nil) {
                if (passwordP != nil) {
                    *passwordP = [result isKindOfClass:[NSData class]] ? result : nil;
                }
                [self addNonPersistedPassword:*passwordP];
                success = YES;
            }
        } else {
            success = (*passwordP != nil);
        }
    });
    return success;
}

- (void)addNonPersistedPassword:(NSData *)password
{
    if (NonPersistedPassword == nil) {
        NonPersistedPassword = [NSMutableDictionary dictionary];
    }
    NonPersistedPassword[self.serverName] = password ?: [NSNull null];
}

- (void)setItem:(NSData *)data
{
    if (![self updateItemWithPassword:data]) {
        [self addItemWithPassword:data];
    }
}

- (BOOL)addItemWithPassword:(NSData *)password
{
    Require(password != nil);
    __block BOOL success = NO;
    dispatch_sync(isolationQueue(), ^{
        
        [self addNonPersistedPassword:password];
        
        if (KeychainDisabled) {
            success = YES;
            return;
        }
        success = [ZMKeychain setData:password forAccount:AccountName];
    });
    return success;
}

- (BOOL)updateItemWithPassword:(NSData *)password
{
    __block BOOL success = NO;
    dispatch_sync(isolationQueue(), ^{
        
        BOOL hasItem = ((NonPersistedPassword[self.serverName] != nil) &&
                        (NonPersistedPassword[self.serverName] != [NSNull null]));
        if (hasItem) {
            NonPersistedPassword[self.serverName] = password ?: [NSNull null];
        }
        
        if (KeychainDisabled) {
            success = hasItem;
            return;
        }
        
        success = [ZMKeychain setData:password forAccount:AccountName];
    });
    
    // now try to read. If we fail to read, it means that the keychain is blocked and it always return success on an update (I guess it's a security feature?)
    NSData *readPassword;
    BOOL read = [self findItemWithPassword:&readPassword];
    
    if(!read || (![readPassword isEqualToData:password])) {
        if(success) {
            //ZMTraceAuthLockedKeychainDetected();
        }
        dispatch_async(isolationQueue(), ^{
            [self addNonPersistedPassword:password];
        });
        
    }
    
    return success;
}

- (void)deleteItem
{
    dispatch_sync(isolationQueue(), ^{
        
        [NonPersistedPassword removeObjectForKey:self.serverName];
        
        if (KeychainDisabled) {
            return;
        }
        
        [ZMKeychain deleteAllKeychainItemsWithAccountName:AccountName];
    });
}

@end


@implementation ZMPersistentCookieStorage (HTTPCookie)

+ (void)setCookiesPolicy:(NSHTTPCookieAcceptPolicy)policy
{
    cookiesPolicy = policy == NSHTTPCookieAcceptPolicyNever ? NSHTTPCookieAcceptPolicyNever : NSHTTPCookieAcceptPolicyAlways;
}

+ (NSHTTPCookieAcceptPolicy)cookiesPolicy;
{
    return cookiesPolicy;
}

- (void)setCookieDataFromResponse:(NSHTTPURLResponse *)response forURL:(NSURL *)URL;
{
    if (cookiesPolicy == NSHTTPCookieAcceptPolicyNever) {
        return;
    }
    
    NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:response.allHeaderFields forURL:URL];
    if  (cookies.count == 0) {
        return;
    }
    ZMLogDebug(@"Cookie received.");
    
    NSArray *properties = [cookies mapWithBlock:^id(NSHTTPCookie *cookie) {
        return cookie.properties;
    }];
    
    if (![[properties.firstObject valueForKey:@"Name"] isEqual:@"zuid"]) {
        return;
    }
    
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    archiver.requiresSecureCoding = YES;
    [archiver encodeObject:properties forKey:@"properties"];
    [archiver finishEncoding];
    
    if (TARGET_OS_IPHONE) {
        NSData *secretKey = [NSUserDefaults cookiesKey];
        data = [[data zmEncryptPrefixingIVWithKey:secretKey] mutableCopy];
    }
    
    self.authenticationCookieData = [data base64EncodedDataWithOptions:0];
}

- (void)setRequestHeaderFieldsOnRequest:(NSMutableURLRequest *)request;
{
    NSData *data = self.authenticationCookieData;
    if (data == nil) {
        return;
    }
    data = [[NSData alloc] initWithBase64EncodedData:data options:0];
    if (data == nil) {
        return;
    }
    if (TARGET_OS_IPHONE) {
        NSData *secretKey = [NSUserDefaults cookiesKey];
        data = [data zmDecryptPrefixedIVWithKey:secretKey];
    }
    NSKeyedUnarchiver *unarchiver;
    @try {
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    } @catch (id) {
    
        ZMLogError(@"Unable to parse stored cookie data.");
        self.authenticationCookieData = nil;
        return;
    }
    if (unarchiver == nil) {
        ZMLogError(@"Unable to parse stored cookie data.");
        self.authenticationCookieData = nil;
        return;
    }
    
    unarchiver.requiresSecureCoding = YES;
    NSArray *properties = [unarchiver decodePropertyListForKey:@"properties"];
    VerifyReturn([properties isKindOfClass:[NSArray class]]);
    NSArray *cookies = [properties mapWithBlock:^id(NSDictionary *p) {
        return [[NSHTTPCookie alloc] initWithProperties:p];
    }];
    [[NSHTTPCookie requestHeaderFieldsWithCookies:cookies] enumerateKeysAndObjectsUsingBlock:^(NSString *field, NSString *value, BOOL *stop) {
        NOT_USED(stop);
        [request addValue:value forHTTPHeaderField:field];
    }];
}

@end
