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


final class MetaStreamContainer {
    
    let bytes = NSMutableData()
    
    var stringContent: String? {
        return String(data: bytes, encoding: NSUTF8StringEncoding)
    }
    
    var head: String? {
        guard let content = stringContent else { return nil }
        let startRange = content.rangeOfString(OpenGraphXMLNode.HeadStart.rawValue)
        let endRange = content.rangeOfString(OpenGraphXMLNode.HeadEnd.rawValue)
        
        guard let start = startRange?.startIndex, end = endRange?.endIndex else { return nil }
        let result = content.characters[start..<end].map { String($0) }.joinWithSeparator("")
        return result
    }
    
    var reachedEndOfHead = false
    
    func addData(data: NSData) -> NSData {
        updateReachedEndOfHead(withData: data)
        bytes.appendData(data)
        return bytes
    }

    private func updateReachedEndOfHead(withData data: NSData) {
        guard let string = String(data: data, encoding: NSUTF8StringEncoding)?.lowercaseString else { return }
        if string.containsString(OpenGraphXMLNode.HeadEnd.rawValue) {
            reachedEndOfHead = true
        }
    }

}
