//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

@objcMembers open class StringLengthValidator: NSObject {
    
    private static let controlSet: CharacterSet = {
        var controlSet = CharacterSet.controlCharacters
        controlSet.remove(Unicode.Scalar(0x200d)!)
        return controlSet
    }()
    
    public class StringLengthError: NSError {
        static let tooShort = StringLengthError(domain: ZMObjectValidationErrorDomain,
                                                code: Int(ZMManagedObjectValidationErrorCode.objectValidationErrorCodeStringTooShort.rawValue),
                                                userInfo: nil)
        
        static let tooLong = StringLengthError(domain: ZMObjectValidationErrorDomain,
                                               code: Int(ZMManagedObjectValidationErrorCode.objectValidationErrorCodeStringTooLong.rawValue),
                                               userInfo: nil)
    }
    
    @objc(validateValue:minimumStringLength:maximumStringLength:maximumByteLength:error:)
    static public func validateValue(_ ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>,
                                     minimumStringLength: UInt32,
                                     maximumStringLength: UInt32,
                                     maximumByteLength: UInt32) throws {
        guard let string = ioValue.pointee as? String else {
            throw StringLengthError.tooShort
        }

        var trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)

        // check the trimmedString contains controlSet characters and replace matchings with spaces

        trimmedString = trimmedString
            .map{ $0.isEmoji || !$0.contains(anyCharacterFrom: controlSet) ? String($0) : " " }
            .joined()

        if trimmedString.count < minimumStringLength {
            throw StringLengthError.tooShort
        }
        
        if trimmedString.count > maximumStringLength {
            throw StringLengthError.tooLong
        }
        
        if trimmedString.utf8.count > maximumByteLength {
            throw StringLengthError.tooLong
        }
        
        if string != trimmedString {
            ioValue.pointee = trimmedString as AnyObject
        }
    }
    
}
