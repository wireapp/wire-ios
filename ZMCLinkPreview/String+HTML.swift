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
    func resolvingXMLEntityReferences() -> String? {
    
        guard let _ = self.rangeOfString("&", options:.LiteralSearch) else {
            return self;
        }
        
    
        let result = NSMutableString()
    
        let scanner = NSScanner(string: self)
    
        scanner.charactersToBeSkipped = nil
    
        let boundaryCharacterSet = NSCharacterSet(charactersInString:" \t\n\r;")
    
        repeat {
            
            var nonEntityString: NSString?
            if scanner.scanUpToString("&", intoString:&nonEntityString) {
                result.appendString(nonEntityString! as String)
            }
            
            if scanner.atEnd {
                return result as String
            }
            
            var dummyInout: NSString?
            if scanner.scanString("&amp;", intoString:&dummyInout) {
                result.appendString("&")
            }
            else if scanner.scanString("&apos;", intoString:&dummyInout) {
                result.appendString("'")
            }
            else if scanner.scanString("&quot;", intoString:&dummyInout) {
                result.appendString("\"")
            }
            else if scanner.scanString("&lt;", intoString:&dummyInout) {
                result.appendString("<")
            }
            else if scanner.scanString("&gt;", intoString:&dummyInout) {
                result.appendString(">")
            }
            else if scanner.scanString("&#", intoString:&dummyInout) {
                var gotNumber: Bool
                var charCode: unichar
                var hexStartString: NSString?
            
                if scanner.scanString("x", intoString:&hexStartString) {
                    var charCodeUInt32: UInt32 = 0
                    gotNumber = scanner.scanHexInt(&charCodeUInt32)
                    charCode = unichar(charCodeUInt32)
                }
                else {
                    var charCodeInt32: Int32 = 0
                    gotNumber = scanner.scanInt(&charCodeInt32)
                    charCode = unichar(charCodeInt32)
                }
                
                if (gotNumber) {
                    result.appendFormat("%C", charCode)
                    
                    scanner.scanString(";", intoString:&dummyInout)
                }
                else {
                    var unknownEntity: NSString?
                    scanner.scanUpToCharactersFromSet(boundaryCharacterSet, intoString:&unknownEntity)
                    if let hexStartString = hexStartString, let unknownEntity = unknownEntity {
                        result.appendFormat("&#%@%@", hexStartString, unknownEntity)
                        print("Expected numeric character entity but got &#%@%@;", hexStartString, unknownEntity)
                    }
                }
            }
            else {
                var amp: NSString?
                scanner.scanString("&", intoString:&amp)
                if let amp = amp {
                    result.appendString(amp as String)
                    
                }
            
            }
            
        }
        while !scanner.atEnd
        
        return result as String
    }
    
}
