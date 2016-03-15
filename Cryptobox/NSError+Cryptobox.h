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


#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CBErrorCode) {
    CBErrorCodeUndefined,
    CBErrorCodeStorageError,
    CBErrorCodeNoSession,
    CBErrorCodeNoPreKey,
    CBErrorCodeDecodeError,
    CBErrorCodeRemoteIdentityChanged,
    CBErrorCodeInvalidIdentity,
    CBErrorCodeInvalidSignature,
    CBErrorCodeInvalidMessage,
    CBErrorCodeDuplicateMessage,
    CBErrorCodeTooDistantFuture,
    CBErrorCodeOutdatedMessage,
    CBErrorCodeUTF8Error,
    CBErrorCodeNULError,
    CBErrorCodeEncodeError,
    CBErrorCodePanic
};

FOUNDATION_EXPORT NSString *const CBErrorDomain;
FOUNDATION_EXPORT NSString *const CBCodeIllegalStateException;



@interface NSError (Cryptobox)

+ (instancetype)cb_errorWithErrorCode:(CBErrorCode)code;

+ (instancetype)cb_errorWithErrorCode:(CBErrorCode)code description:(NSString *)description;

+ (instancetype)cb_errorWithErrorCode:(CBErrorCode)code userInfo:(NSDictionary *)dict;

@end
