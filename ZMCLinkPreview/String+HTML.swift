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


extension String {
    
    /**
     Resolves XML character references contained in the String.
     see http://www.w3.org/TR/2004/REC-xml-20040204/#sec-references
     - returns: The String with resolved XML character references or `nil` if the String can't be converted to data using `UTF8` encoding.
     */
    func resolvedXMLEntityReferences() -> String? {
    
        guard nil != range(of: "&", options:.literal) else { return self }
        
        let result = NSMutableString()
        let scanner = Scanner(string: self)
        scanner.charactersToBeSkipped = nil
        let boundaryCharacterSet = CharacterSet(charactersIn: " \t\n\r;")
    
        repeat {
            
            var nonEntityString: NSString?
            if scanner.scanUpTo("&", into:&nonEntityString) {
                result.append(nonEntityString! as String)
            }
            
            if scanner.isAtEnd {
                return result as String
            }
            
            if scanner.scanString("&amp;", into: nil) {
                result.append("&")
            }
            else if scanner.scanString("&apos;", into: nil) {
                result.append("'")
            }
            else if scanner.scanString("&quot;", into: nil) {
                result.append("\"")
            }
            else if scanner.scanString("&lt;", into: nil) {
                result.append("<")
            }
            else if scanner.scanString("&gt;", into: nil) {
                result.append(">")
            }
            else if scanner.scanString("&#", into: nil) {
                var gotNumber: Bool
                var charCode: unichar
                var hexStartString: NSString?
            
                if scanner.scanString("x", into:&hexStartString) {
                    var charCodeUInt32: UInt32 = 0
                    gotNumber = scanner.scanHexInt32(&charCodeUInt32)
                    charCode = unichar(charCodeUInt32)
                }
                else {
                    var charCodeInt32: Int32 = 0
                    gotNumber = scanner.scanInt32(&charCodeInt32)
                    charCode = unichar(charCodeInt32)
                }

                if (gotNumber) {
                    result.appendFormat("%C", charCode)
                    scanner.scanString(";", into: nil)
                }
                else {
                    var unknownEntity: NSString?
                    scanner.scanUpToCharacters(from: boundaryCharacterSet, into:&unknownEntity)
                    if let hexStartString = hexStartString, let unknownEntity = unknownEntity {
                        result.appendFormat("&#%@%@", hexStartString, unknownEntity)
                        print("Expected numeric character entity but got &#%@%@;", hexStartString, unknownEntity)
                    }
                }
            }
            else {
                var amp: NSString?
                scanner.scanString("&", into:&amp)
                if let amp = amp as? String {
                    result.append(amp)
                }
            }

        } while !scanner.isAtEnd

        return result as String
    }
    
}
