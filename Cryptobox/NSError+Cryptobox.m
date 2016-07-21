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


#import "NSError+Cryptobox.h"
#import "cbox.h"
#import "CBMacros.h"


NSString *const CBErrorDomain = @"CryptoboxErrorDomain";
NSString *const CBCodeIllegalStateException = @"CryptoboxCodeIllegalStateException";

CBErrorCode CBErrorCodeFromCBoxResult(CBoxResult result)
{
    switch (result) {
        case CBOX_STORAGE_ERROR:
            return CBErrorCodeStorageError;
            break;
            
        case CBOX_SESSION_NOT_FOUND:
            return CBErrorCodeNoSession;
            break;
        
        case CBOX_PREKEY_NOT_FOUND:
            return CBErrorCodeNoPreKey;
            break;
            
        case CBOX_DECODE_ERROR:
            return CBErrorCodeDecodeError;
            break;

        case CBOX_REMOTE_IDENTITY_CHANGED:
            return CBErrorCodeRemoteIdentityChanged;
            break;
            
        case CBOX_IDENTITY_ERROR:
            return CBErrorCodeInvalidIdentity;
            break;

        case CBOX_INVALID_SIGNATURE:
            return CBErrorCodeInvalidSignature;
            break;

        case CBOX_INVALID_MESSAGE:
            return CBErrorCodeInvalidMessage;
            break;

        case CBOX_DUPLICATE_MESSAGE:
            return CBErrorCodeDuplicateMessage;
            break;

        case CBOX_TOO_DISTANT_FUTURE:
            return CBErrorCodeTooDistantFuture;
            break;

        case CBOX_OUTDATED_MESSAGE:
            return CBErrorCodeOutdatedMessage;
            break;

        case CBOX_UTF8_ERROR:
            return CBErrorCodeUTF8Error;
            break;

        case CBOX_NUL_ERROR:
            return CBErrorCodeNULError;
            break;

        case CBOX_ENCODE_ERROR:
            return CBErrorCodeEncodeError;
            break;
            
        case CBOX_SUCCESS:
            return CBErrorCodeUndefined;
            break;
            
        case CBOX_PANIC:
            return CBErrorCodePanic;
            break;
    }
    return CBErrorCodeUndefined;
}



@implementation NSError (Cryptobox)

+ (instancetype)cb_errorWithErrorCode:(CBErrorCode)code
{
    return [self cb_errorWithErrorCode:code userInfo:nil];
}

+ (instancetype)cb_errorWithErrorCode:(CBErrorCode)code description:(NSString *)description
{
    if (description.length > 0) {
        return [self cb_errorWithErrorCode:code userInfo:@{NSLocalizedDescriptionKey: description}];
    } else {
        return [self cb_errorWithErrorCode:code userInfo:nil];
    }
}

+ (instancetype)cb_errorWithErrorCode:(CBErrorCode)code userInfo:(NSDictionary *)dict
{
    NSError *error = [NSError errorWithDomain:CBErrorDomain code:code userInfo:dict];
    return error;
}

@end
