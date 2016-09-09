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
    
    case success                 = 0
    
    case storageError            = 1
    
    case sessionNotFound         = 2
    
    case decodeError             = 3
    
    case remoteIdentityChanged   = 4
    
    case invalidSignature        = 5
    
    case invalidMessage          = 6
    
    case duplicateMessage        = 7
    
    case tooDistantFuture        = 8
    
    case outdatedMessage         = 9
    
    case UTF8Error               = 10
    
    case nulError                = 11
    
    case encodeError             = 12
    
    case identityError           = 13
    
    case prekeyNotFound          = 14
    
    case panic                   = 15
    
    
    public init?(rawValue: UInt32)
    {
        switch rawValue {
        case CBOX_SUCCESS.rawValue:
            self = .success
        case CBOX_STORAGE_ERROR.rawValue:
            self = .storageError
        case CBOX_SESSION_NOT_FOUND.rawValue:
            self = .sessionNotFound
        case CBOX_DECODE_ERROR.rawValue:
            self = .decodeError
        case CBOX_REMOTE_IDENTITY_CHANGED.rawValue:
            self = .remoteIdentityChanged
        case CBOX_INVALID_SIGNATURE.rawValue:
            self = .invalidSignature
        case CBOX_INVALID_MESSAGE.rawValue:
            self = .invalidMessage
        case CBOX_DUPLICATE_MESSAGE.rawValue:
            self = .duplicateMessage
        case CBOX_TOO_DISTANT_FUTURE.rawValue:
            self = .tooDistantFuture
        case CBOX_OUTDATED_MESSAGE.rawValue:
            self = .outdatedMessage
        case CBOX_UTF8_ERROR.rawValue:
            self = .UTF8Error
        case CBOX_NUL_ERROR.rawValue:
            self = .nulError
        case CBOX_ENCODE_ERROR.rawValue:
            self = .encodeError
        case CBOX_IDENTITY_ERROR.rawValue:
            self = .identityError
        case CBOX_PREKEY_NOT_FOUND.rawValue:
            self = .prekeyNotFound
        case CBOX_PANIC.rawValue:
            self = .panic
            
        default:
            return nil
        }
    }
}
