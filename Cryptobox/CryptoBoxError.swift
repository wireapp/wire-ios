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

extension CBoxResult : ErrorType {
}

@objc public enum CryptoboxError : UInt32, ErrorType {
    
    case CryptoboxSuccess                 = 0
    
    case CryptoboxStorageError            = 1
    
    case CryptoboxSessionNotFound         = 2
    
    case CryptoboxDecodeError             = 3
    
    case CryptoboxRemoteIdentityChanged   = 4
    
    case CryptoboxInvalidSignature        = 5
    
    case CryptoboxInvalidMessage          = 6
    
    case CryptoboxDuplicateMessage        = 7
    
    case CryptoboxTooDistantFuture        = 8
    
    case CryptoboxOutdatedMessage         = 9
    
    case CryptoboxUTF8Error               = 10
    
    case CryptoboxNulError                = 11
    
    case CryptoboxEncodeError             = 12
    
    case CryptoboxIdentityError           = 13
    
    case CryptoboxPrekeyNotFound          = 14
    
    case CryptoboxPanic                   = 15
    
    
    public init?(rawValue: UInt32)
    {
        switch rawValue {
        case CBOX_SUCCESS.rawValue:
            self = .CryptoboxSuccess
        case CBOX_STORAGE_ERROR.rawValue:
            self = .CryptoboxStorageError
        case CBOX_SESSION_NOT_FOUND.rawValue:
            self = .CryptoboxSessionNotFound
        case CBOX_DECODE_ERROR.rawValue:
            self = .CryptoboxDecodeError
        case CBOX_REMOTE_IDENTITY_CHANGED.rawValue:
            self = .CryptoboxRemoteIdentityChanged
        case CBOX_INVALID_SIGNATURE.rawValue:
            self = .CryptoboxInvalidSignature
        case CBOX_INVALID_MESSAGE.rawValue:
            self = .CryptoboxInvalidMessage
        case CBOX_DUPLICATE_MESSAGE.rawValue:
            self = .CryptoboxDuplicateMessage
        case CBOX_TOO_DISTANT_FUTURE.rawValue:
            self = .CryptoboxTooDistantFuture
        case CBOX_OUTDATED_MESSAGE.rawValue:
            self = .CryptoboxOutdatedMessage
        case CBOX_UTF8_ERROR.rawValue:
            self = .CryptoboxUTF8Error
        case CBOX_NUL_ERROR.rawValue:
            self = .CryptoboxNulError
        case CBOX_ENCODE_ERROR.rawValue:
            self = .CryptoboxEncodeError
        case CBOX_IDENTITY_ERROR.rawValue:
            self = .CryptoboxIdentityError
        case CBOX_PREKEY_NOT_FOUND.rawValue:
            self = .CryptoboxPrekeyNotFound
        case CBOX_PANIC.rawValue:
            self = .CryptoboxPanic
            
        default:
            return nil
        }
    }
}
