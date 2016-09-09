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


import Foundation

extension CBoxResult : Error {
}

@objc public enum CryptoboxError : UInt32, Error {
    
    case cryptoboxSuccess                 = 0
    
    case cryptoboxStorageError            = 1
    
    case cryptoboxSessionNotFound         = 2
    
    case cryptoboxDecodeError             = 3
    
    case cryptoboxRemoteIdentityChanged   = 4
    
    case cryptoboxInvalidSignature        = 5
    
    case cryptoboxInvalidMessage          = 6
    
    case cryptoboxDuplicateMessage        = 7
    
    case cryptoboxTooDistantFuture        = 8
    
    case cryptoboxOutdatedMessage         = 9
    
    case cryptoboxUTF8Error               = 10
    
    case cryptoboxNulError                = 11
    
    case cryptoboxEncodeError             = 12
    
    case cryptoboxIdentityError           = 13
    
    case cryptoboxPrekeyNotFound          = 14
    
    case cryptoboxPanic                   = 15
    
    
    public init?(rawValue: UInt32)
    {
        switch rawValue {
        case CBOX_SUCCESS.rawValue:
            self = .cryptoboxSuccess
        case CBOX_STORAGE_ERROR.rawValue:
            self = .cryptoboxStorageError
        case CBOX_SESSION_NOT_FOUND.rawValue:
            self = .cryptoboxSessionNotFound
        case CBOX_DECODE_ERROR.rawValue:
            self = .cryptoboxDecodeError
        case CBOX_REMOTE_IDENTITY_CHANGED.rawValue:
            self = .cryptoboxRemoteIdentityChanged
        case CBOX_INVALID_SIGNATURE.rawValue:
            self = .cryptoboxInvalidSignature
        case CBOX_INVALID_MESSAGE.rawValue:
            self = .cryptoboxInvalidMessage
        case CBOX_DUPLICATE_MESSAGE.rawValue:
            self = .cryptoboxDuplicateMessage
        case CBOX_TOO_DISTANT_FUTURE.rawValue:
            self = .cryptoboxTooDistantFuture
        case CBOX_OUTDATED_MESSAGE.rawValue:
            self = .cryptoboxOutdatedMessage
        case CBOX_UTF8_ERROR.rawValue:
            self = .cryptoboxUTF8Error
        case CBOX_NUL_ERROR.rawValue:
            self = .cryptoboxNulError
        case CBOX_ENCODE_ERROR.rawValue:
            self = .cryptoboxEncodeError
        case CBOX_IDENTITY_ERROR.rawValue:
            self = .cryptoboxIdentityError
        case CBOX_PREKEY_NOT_FOUND.rawValue:
            self = .cryptoboxPrekeyNotFound
        case CBOX_PANIC.rawValue:
            self = .cryptoboxPanic
            
        default:
            return nil
        }
    }
}
