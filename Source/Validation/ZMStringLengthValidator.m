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

#import "ZMStringLengthValidator.h"
#import "ZMPropertyValidator.h"

@implementation ZMStringLengthValidator

ZM_EMPTY_ASSERTING_INIT()

+ (BOOL)validateValue:(inout __autoreleasing id *)ioString mimimumStringLength:(NSUInteger)minimumLength maximumSringLength:(NSUInteger)maximumLength error:(out NSError *__autoreleasing *)outError
{
    if (*ioString == nil) {
        return YES;
    }
    
    NSString *trimmedName = [*ioString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([trimmedName rangeOfCharacterFromSet:[NSCharacterSet controlCharacterSet] options:NSLiteralSearch].location != NSNotFound) {
        NSMutableString *replaced = [trimmedName mutableCopy];
        do {
            NSRange r = [replaced rangeOfCharacterFromSet:[NSCharacterSet controlCharacterSet] options:NSLiteralSearch];
            if (r.location == NSNotFound) {
                break;
            }
            [replaced replaceCharactersInRange:r withString:@" "];
        } while (YES);
        trimmedName = replaced;
    }
    
    if (maximumLength < trimmedName.length) {
        if (outError != NULL) {
            NSString *description = ZMLocalizedString(@"The entered name is too long.");
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: description};
            NSError *error = [[NSError alloc] initWithDomain:ZMObjectValidationErrorDomain
                                                        code:ZMObjectValidationErrorCodeStringTooLong
                                                    userInfo:userInfo];
            *outError = error;
        }
        return NO;
    } else if (trimmedName.length < minimumLength) {
        if (outError != NULL) {
            NSString *description = ZMLocalizedString(@"The entered name is too short.");
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: description};
            NSError *error = [[NSError alloc] initWithDomain:ZMObjectValidationErrorDomain
                                                        code:ZMObjectValidationErrorCodeStringTooShort
                                                    userInfo:userInfo];
            *outError = error;
        }
        return NO;
    }
    if (! [*ioString isEqualToString:trimmedName]) {
        *ioString = trimmedName;
    }
    return YES;
}

@end
