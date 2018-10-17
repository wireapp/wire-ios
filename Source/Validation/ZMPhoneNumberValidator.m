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

#import "ZMPhoneNumberValidator.h"
#import "ZMPropertyValidator.h"

@interface NSString (zm_removeCharacterSet)

@end


@implementation NSString (zm_removeCharacterSet)

- (NSString *)stringByRemovingCharacters:(NSString *)characters
{
    NSMutableString *finalString = [self mutableCopy];
    for(typeof(characters.length) i = 0; i < characters.length; ++i) {
        
        NSString *toRemove = [characters substringWithRange:NSMakeRange(i,1)];
        [finalString replaceOccurrencesOfString:toRemove withString:@"" options:0 range:NSMakeRange(0, [finalString length])];
    }
    return finalString;
}

@end


@implementation ZMPhoneNumberValidator

ZM_EMPTY_ASSERTING_INIT()

+ (BOOL)validateValue:(inout id *)ioPhoneNumber error:(out NSError **)outError
{
    if ([(NSString *)(*ioPhoneNumber) length] < 1) {
        return YES;
    }
    
    NSMutableCharacterSet *validSet = [NSMutableCharacterSet decimalDigitCharacterSet];
    [validSet addCharactersInString:@"+-. ()"];
    NSCharacterSet *invalidSet = [validSet invertedSet];
    if ([*ioPhoneNumber rangeOfCharacterFromSet:invalidSet options:NSLiteralSearch].location != NSNotFound)
    {
        if (outError != NULL) {
            NSString *description = ZMLocalizedString(@"The phone number is invalid.");
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: description};
            NSError *error = [[NSError alloc] initWithDomain:ZMObjectValidationErrorDomain
                                                        code:ZMObjectValidationErrorCodePhoneNumberContainsInvalidCharacters
                                                    userInfo:userInfo];
            *outError = error;
        }
        return NO;
    }
    
    NSString *finalPhoneNumber = [@"+" stringByAppendingString:[*ioPhoneNumber stringByRemovingCharacters:@"+-. ()"]];
    if (![StringLengthValidator validateValue:&finalPhoneNumber
                          minimumStringLength:9
                          maximumStringLength:24
                            maximumByteLength:24
                                        error:outError]) {
        return NO;
    }
    
    if(![finalPhoneNumber isEqualToString:*ioPhoneNumber]) {
        *ioPhoneNumber = finalPhoneNumber;
    }
    return YES;
}

+ (BOOL)isValidPhoneNumber:(NSString *)phoneNumber
{
    NSString* value = [phoneNumber copy];
    return [self validateValue:&value error:nil];
}

@end
