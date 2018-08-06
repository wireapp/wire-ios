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


@import WireSystem;
#import <WireUtilities/WireUtilities-Swift.h>

#import "ZMEmailAddressValidator.h"
#import "ZMPropertyValidator.h"

@implementation ZMEmailAddressValidator

ZM_EMPTY_ASSERTING_INIT()

+ (BOOL)normalizeEmailAddress:(NSString **)ioEmailAddress
{
    //Things like "Meep Moop <Meep.Moop@exam.ple>" goes to "meep.moop@exam.ple"
    //First need to check if normalization is needed
    NSString *normalizedEmailAddress = [*ioEmailAddress lowercaseString];
    
    //Trim whitespaces, and control characters
    NSMutableCharacterSet *charactersToTrim = [[NSCharacterSet whitespaceCharacterSet] mutableCopy];
    [charactersToTrim formUnionWithCharacterSet:[NSCharacterSet controlCharacterSet]];
    normalizedEmailAddress = [normalizedEmailAddress stringByTrimmingCharactersInSet:charactersToTrim];
    
    NSScanner *bracketsScanner = [NSScanner scannerWithString:normalizedEmailAddress];
    bracketsScanner.charactersToBeSkipped = [[NSCharacterSet alloc] init];
    bracketsScanner.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    
    if ([bracketsScanner scanUpToString:@"<" intoString:NULL] &&
        [bracketsScanner scanString:@"<" intoString:NULL]) {
        [bracketsScanner scanUpToString:@">" intoString:&normalizedEmailAddress];
        if (![bracketsScanner scanString:@">" intoString:NULL]) {
            //if there is no > than it's not valid email, we do not need to change input value
            normalizedEmailAddress = nil;
        }
    }
    
    if (normalizedEmailAddress != nil && ![normalizedEmailAddress isEqualToString:(*ioEmailAddress)]) {
        *ioEmailAddress = [normalizedEmailAddress copy];
        return YES;
    }
    return NO;
}

+ (BOOL)validateValue:(inout id *)ioEmailAddress error:(out NSError * __autoreleasing *)outError
{
    if (*ioEmailAddress == nil) {
        return YES;
    }
    
    if (![StringLengthValidator validateValue:ioEmailAddress
                          minimumStringLength:0
                          maximumStringLength:120
                            maximumByteLength:120
                                          error:outError]) {
        return NO;
    }
    
    dispatch_block_t setInvalid = ^(){
        if (outError != NULL) {
            NSString *description = ZMLocalizedString(@"The email address is invalid.");
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: description};
            NSError *error = [[NSError alloc] initWithDomain:ZMObjectValidationErrorDomain
                                                        code:ZMObjectValidationErrorCodeEmailAddressIsInvalid
                                                    userInfo:userInfo];
            *outError = error;
        }
    };
    
    //
    // N.B.:
    // The point here is not to be too strict, but just catch some obviously "bad" addresses.
    //
    
    NSString *emailAddress = [*ioEmailAddress copy];
    [self normalizeEmailAddress:&emailAddress];
    
    if (([emailAddress rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:NSLiteralSearch].location != NSNotFound) ||
        ([emailAddress rangeOfCharacterFromSet:[NSCharacterSet controlCharacterSet] options:NSLiteralSearch].location != NSNotFound))
    {
        setInvalid();
        return NO;
    }
    
    NSScanner *emailScanner = [NSScanner scannerWithString:emailAddress];
    emailScanner.charactersToBeSkipped = [[NSCharacterSet alloc] init];
    emailScanner.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    NSString *local;
    NSString *domain;
    BOOL validParts = ([emailScanner scanUpToString:@"@" intoString:&local] &&
                       [emailScanner scanString:@"@" intoString:NULL] &&
                       [emailScanner scanUpToString:@"@" intoString:&domain] &&
                       ![emailScanner scanString:@"@" intoString:NULL]);
    if (! validParts) {
        setInvalid();
        return NO;
    }
    
    // domain part:
    {
        // letters, digits, hyphens and dots
        // We're allowing all Unicode letters and numbers:
        NSMutableCharacterSet *validSet = [NSMutableCharacterSet alphanumericCharacterSet];
        [validSet addCharactersInString:@"-"];
        NSCharacterSet *invalidSet = [validSet invertedSet];
        
        NSArray *components = [domain componentsSeparatedByString:@"."];
        if (components.count < 2) {
            setInvalid();
            return NO;
        }
        if ([components.lastObject hasSuffix:@"-"]) {
            setInvalid();
            return NO;
        }
        for (NSString *c in components) {
            if ((c.length < 1) || ([c rangeOfCharacterFromSet:invalidSet options:NSLiteralSearch].location != NSNotFound))
            {
                setInvalid();
                return NO;
            }
        }
    }
    
    // local part:
    {
        NSMutableCharacterSet *validSet = [NSMutableCharacterSet alphanumericCharacterSet];
        [validSet addCharactersInString:@"!#$%&'*+-/=?^_`{|}~"];
        NSCharacterSet *invalidSet = [validSet invertedSet];
        NSMutableCharacterSet *validQuoted = [validSet mutableCopy];
        [validQuoted addCharactersInString:@"(),:;<>@[]"];
        NSCharacterSet *invalidQuotedSet = [validQuoted invertedSet];
        
        NSArray *components = [local componentsSeparatedByString:@"."];
        if (components.count < 1) {
            setInvalid();
            return NO;
        }
        for (NSString *c in components) {
            if ((c.length < 1) || ([c rangeOfCharacterFromSet:invalidSet options:NSLiteralSearch].location != NSNotFound))
            {
                // Check if it's a quoted part:
                if ([c hasPrefix:@"\""] && [c hasSuffix:@"\""]) {
                    // Allow this regardless of what
                    NSString *quoted = [c substringWithRange:NSMakeRange(1, c.length - 2)];
                    if ((quoted.length < 1) || ([quoted rangeOfCharacterFromSet:invalidQuotedSet options:NSLiteralSearch].location != NSNotFound))
                    {
                        setInvalid();
                        return NO;
                    }
                } else {
                    setInvalid();
                    return NO;
                }
            }
        }
    }
    
    if (![emailAddress isEqualToString:*ioEmailAddress]) {
        *ioEmailAddress = emailAddress;
    }

    return YES;
}

+ (BOOL)isValidEmailAddress:(NSString *)emailAddress
{
    NSString* value = [emailAddress copy];
    return [self validateValue:&value error:nil];
}

@end
