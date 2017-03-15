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

public enum ExtremeCombiningCharactersValidationError: Error {
    case containsExtremeCombiningCharacters
}

public class ExtremeCombiningCharactersValidator: NSObject, ZMPropertyValidator {
    public static func validateValue(_ ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>!) throws {
        guard let pointee = ioValue.pointee else {
            return
        }
        
        guard let string = pointee as? String else {
            fatal("Provided value \(ioValue.pointee) is not a string")
        }
        
        let stringByRemovingExtremeCombiningCharacters = string.removingExtremeCombiningCharacters
        
        if string.unicodeScalars.count != stringByRemovingExtremeCombiningCharacters.unicodeScalars.count {
            ioValue.pointee = stringByRemovingExtremeCombiningCharacters as AnyObject?
            throw ExtremeCombiningCharactersValidationError.containsExtremeCombiningCharacters
        }
    }
}
