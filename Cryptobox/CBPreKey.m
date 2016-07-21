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


#import "CBPreKey.h"
#import "CBTypes.h"

#import "NSError+Cryptobox.h"
#import "CBMacros.h"
#import "CBVector+Internal.h"
#import "CBPreKey+Internal.h"



@implementation CBPreKey

@end



@implementation CBPreKey (Internal)

+ (nullable instancetype)preKeyWithId:(uint16_t)identifier boxRef:(nonnull CBoxRef)boxRef error:(NSError *__nullable * __nullable)error
{
    NSParameterAssert(boxRef);
    
    if (! boxRef) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"boxRef is not set" userInfo:nil];
    }
    
    CBoxVecRef vectorBacking = NULL;
    CBoxResult result = cbox_new_prekey(boxRef, identifier, &vectorBacking);
    //CBAssertResultIsSuccess(result);
    if (result != CBOX_SUCCESS) {
        CBErrorWithCBoxResult(result, error);
        return nil;
    }

    CBPreKey *key = [[CBPreKey alloc] initWithCBoxVecRef:vectorBacking];
    return key;
}

@end
