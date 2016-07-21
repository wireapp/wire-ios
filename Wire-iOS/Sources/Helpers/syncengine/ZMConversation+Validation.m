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


#import "ZMConversation+Validation.h"

#import "ZetaKeyValueValidation.h"

static NSUInteger const ZMConversationValidationNameMinLength = 1;
static NSUInteger const ZMConversationValidationNameMaxLength = 64;



@implementation ZMConversation (Validation)

- (BOOL)validateName:(NSString **)ioValue error:(out NSError *__autoreleasing *)outError
{
    NSString *name = [*ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (! name || [name length] == 0) {
        if (outError != NULL) {
            *outError = [NSError zetaKeyValueValidationErrorWithErrorCode:ZetaKeyValueValidationErrorCodeIllegalArgument];
        }
        return NO;
    }
    if ([name length] < ZMConversationValidationNameMinLength) {
        if (outError != NULL) {
            *outError = [NSError zetaKeyValueValidationErrorWithErrorCode:ZetaKeyValueValidationErrorCodeTooShort];
        }
        return NO;
    }
    if ([name length] > ZMConversationValidationNameMaxLength) {
        if (outError != NULL) {
            *outError = [NSError zetaKeyValueValidationErrorWithErrorCode:ZetaKeyValueValidationErrorCodeTooLong];
        }
        return NO;
    }

    return YES;
}

@end
