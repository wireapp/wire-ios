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
        guard let data = dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) else { return nil }
        let options: [String: AnyObject] = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding]
        let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil)
        return attributed?.string ?? self
    }

}
